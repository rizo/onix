open Utils

let local_vars ~with_test ~with_doc ~with_dev_setup =
  let open OpamVariable in
  Map.of_list
    [
      (of_string "with-test", Some (B with_test));
      (of_string "with-doc", Some (B with_doc));
      (of_string "with-dev-setup", Some (B with_dev_setup));
    ]

module Patch = struct
  (* https://github.com/ocaml/opam/blob/e36650b3007e013cfb5b6bb7ed769a349af3ee97/src/client/opamAction.ml#L343 *)
  let prepare_package_build env opam nv dir =
    let open OpamFilename.Op in
    let open OpamProcess.Job.Op in
    let patches = OpamFile.OPAM.patches opam in

    let print_apply basename =
      Logs.debug (fun log ->
          log "%s: applying %s."
            (OpamPackage.name_to_string nv)
            (OpamFilename.Base.to_string basename));
      if OpamConsole.verbose () then
        OpamConsole.msg "[%s: patch] applying %s@."
          (OpamConsole.colorise `green (OpamPackage.name_to_string nv))
          (OpamFilename.Base.to_string basename)
    in
    let print_subst basename =
      let file = OpamFilename.Base.to_string basename in
      let file_in = file ^ ".in" in
      Logs.debug (fun log ->
          log "%s: expanding opam variables in %s, generating %s."
            (OpamPackage.name_to_string nv)
            file_in file)
    in

    let apply_patches () =
      Logs.debug (fun log ->
          log "Applying patches total=%d..." (List.length patches));
      let patch base =
        OpamFilename.patch (dir // OpamFilename.Base.to_string base) dir
      in
      let rec aux = function
        | [] -> Done []
        | (patchname, filter) :: rest ->
          if OpamFilter.opt_eval_to_bool env filter then (
            print_apply patchname;
            patch patchname @@+ function
            | None -> aux rest
            | Some err -> aux rest @@| fun e -> (patchname, err) :: e)
          else aux rest
      in
      aux patches
    in
    let substs = OpamFile.OPAM.substs opam in
    let subst_patches, subst_others =
      List.partition (fun f -> List.mem_assoc f patches) substs
    in
    Logs.debug (fun log ->
        log "Found %d substs; patches=%d others=%d..." (List.length substs)
          (List.length subst_patches)
          (List.length subst_others));
    let subst_errs =
      OpamFilename.in_dir dir @@ fun () ->
      List.fold_left
        (fun errs f ->
          try
            print_subst f;
            OpamFilter.expand_interpolations_in_file env f;
            errs
          with e -> (f, e) :: errs)
        [] subst_patches
    in

    (* Apply the patches *)
    let text =
      OpamProcess.make_command_text (OpamPackage.Name.to_string nv.name) "patch"
    in
    OpamProcess.Job.with_text text (apply_patches ()) @@+ fun patching_errors ->
    (* Substitute the configuration files. We should be in the right
       directory to get the correct absolute path for the
       substitution files (see [OpamFilter.expand_interpolations_in_file] and
       [OpamFilename.of_basename]. *)
    let subst_errs =
      OpamFilename.in_dir dir @@ fun () ->
      List.fold_left
        (fun errs f ->
          try
            print_subst f;
            OpamFilter.expand_interpolations_in_file env f;
            errs
          with e -> (f, e) :: errs)
        subst_errs subst_others
    in
    if patching_errors <> [] || subst_errs <> [] then
      let msg =
        (if patching_errors <> [] then
         Printf.sprintf "These patches didn't apply at %s:@.%s"
           (OpamFilename.Dir.to_string dir)
           (OpamStd.Format.itemize
              (fun (f, err) ->
                Printf.sprintf "%s: %s"
                  (OpamFilename.Base.to_string f)
                  (Printexc.to_string err))
              patching_errors)
        else "")
        ^
        if subst_errs <> [] then
          Printf.sprintf "String expansion failed for these files:@.%s"
            (OpamStd.Format.itemize
               (fun (b, err) ->
                 Printf.sprintf "%s.in: %s"
                   (OpamFilename.Base.to_string b)
                   (Printexc.to_string err))
               subst_errs)
        else ""
      in
      Done (Some (Failure msg))
    else Done None

  let copy_extra_files ~opamfile ~build_dir extra_files =
    let bad_hash =
      OpamStd.List.filter_map
        (fun (basename, hash) ->
          let src = Opam_utils.make_opam_files_path ~opamfile basename in
          if OpamHash.check_file (OpamFilename.to_string src) hash then (
            let dst = OpamFilename.create build_dir basename in
            Logs.debug (fun log ->
                log "Opam_actions.copy_extra_files: %a -> %a"
                  Opam_utils.pp_filename src Opam_utils.pp_filename dst);
            OpamFilename.copy ~src ~dst;
            None)
          else Some src)
        extra_files
    in
    if List.is_not_empty bad_hash then
      Fmt.failwith "Bad hash for %s"
        (OpamStd.Format.itemize OpamFilename.to_string bad_hash)

  let copy_undeclared_files ~opamfile ~build_dir () =
    let ( </> ) = OpamFilename.Op.( / ) in
    let files_dir = OpamFilename.dirname opamfile </> "files" in
    List.iter
      (fun src ->
        let base = OpamFilename.basename src in
        let dst = OpamFilename.create build_dir base in
        Logs.debug (fun log ->
            log "Opam_actions.copy_undeclared_files: %a -> %a"
              Opam_utils.pp_filename src Opam_utils.pp_filename dst);
        OpamFilename.copy ~src ~dst)
      (OpamFilename.files files_dir)

  (* TODO: implement extra file fetching via lock-file?:
     - https://github.com/ocaml/opam/blob/e36650b3007e013cfb5b6bb7ed769a349af3ee97/src/client/opamAction.ml#L455 *)
  let run (ctx : Build_context.t) =
    let opamfile = OpamFilename.of_string ctx.self.opamfile in
    let opam = Opam_utils.read_opam opamfile in
    let () =
      let build_dir = OpamFilename.Dir.of_string (Sys.getcwd ()) in
      match OpamFile.OPAM.extra_files opam with
      | None ->
        Logs.debug (fun log ->
            log "No extra files in opam file, checking for undeclared files...");
        copy_undeclared_files ~opamfile ~build_dir ()
      | Some extra_files -> copy_extra_files ~opamfile ~build_dir extra_files
    in
    let lookup_env = Build_context.resolve ctx in
    let cwd = OpamFilename.Dir.of_string (Sys.getcwd ()) in
    let pkg = OpamPackage.create ctx.self.name ctx.self.version in
    prepare_package_build lookup_env opam pkg cwd
    |> OpamProcess.Job.run
    |> Option.if_some raise
end

let patch = Patch.run

let build ~with_test ~with_doc ~with_dev_setup (ctx : Build_context.t) =
  let version = ctx.self.version in
  let with_test = Opam_utils.eval_dep_flag ~version with_test in
  let with_doc = Opam_utils.eval_dep_flag ~version with_doc in
  let with_dev_setup = Opam_utils.eval_dep_flag ~version with_dev_setup in
  let opam = Opam_utils.read_opam (OpamFilename.of_string ctx.self.opamfile) in
  let commands =
    (OpamFilter.commands
       (Build_context.resolve ctx
          ~local:(local_vars ~with_test ~with_doc ~with_dev_setup))
       (OpamFile.OPAM.build opam)
    @ (if with_test then
       OpamFilter.commands
         (Build_context.resolve ctx)
         (OpamFile.OPAM.run_test opam)
      else [])
    @
    if with_doc then
      OpamFilter.commands
        (Build_context.resolve ctx)
        (OpamFile.OPAM.deprecated_build_doc opam)
    else [])
    |> List.filter List.is_not_empty
  in
  commands

module Install = struct
  let make_path_lib ~ocaml_version (pkg : Build_context.package) =
    String.concat "/"
      [
        pkg.prefix;
        "lib/ocaml";
        OpamPackage.Version.to_string ocaml_version;
        "site-lib";
      ]

  let run ~with_test ~with_doc ~with_dev_setup (ctx : Build_context.t) =
    let version = ctx.self.version in
    let with_test = Opam_utils.eval_dep_flag ~version with_test in
    let with_doc = Opam_utils.eval_dep_flag ~version with_doc in
    let with_dev_setup = Opam_utils.eval_dep_flag ~version with_dev_setup in
    let opam =
      Opam_utils.read_opam (OpamFilename.of_string ctx.self.opamfile)
    in
    OpamFilter.commands
      (Build_context.resolve ctx
         ~local:(local_vars ~with_test ~with_doc ~with_dev_setup))
      (OpamFile.OPAM.install opam)
    |> List.filter List.is_not_empty
end

let install = Install.run
