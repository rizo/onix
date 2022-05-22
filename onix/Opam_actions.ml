open Utils

let local_vars ~test ~doc =
  OpamVariable.Map.of_list
    [
      (OpamVariable.of_string "with-test", Some (OpamVariable.B test));
      (OpamVariable.of_string "with-doc", Some (OpamVariable.B doc));
    ]

module Patch = struct
  let make_opam_path ~opamfile file =
    let opam_dir = OpamFilename.dirname opamfile in
    let file = OpamFilename.Base.to_string file in
    let base = OpamFilename.Base.of_string ("files/" ^ file) in
    OpamFilename.create opam_dir base

  (* https://github.com/ocaml/opam/blob/e36650b3007e013cfb5b6bb7ed769a349af3ee97/src/client/opamAction.ml#L343 *)
  let prepare_package_build env opam nv dir =
    let open OpamFilename.Op in
    let open OpamProcess.Job.Op in
    let patches = OpamFile.OPAM.patches opam in

    let print_apply basename =
      Fmt.epr "%s: applying %s.@."
        (OpamPackage.name_to_string nv)
        (OpamFilename.Base.to_string basename);
      if OpamConsole.verbose () then
        OpamConsole.msg "[%s: patch] applying %s@."
          (OpamConsole.colorise `green (OpamPackage.name_to_string nv))
          (OpamFilename.Base.to_string basename)
    in
    let print_subst basename =
      let file = OpamFilename.Base.to_string basename in
      let file_in = file ^ ".in" in
      Fmt.epr "%s: expanding opam variables in %s, generating %s.@."
        (OpamPackage.name_to_string nv)
        file_in file
    in

    let apply_patches () =
      Fmt.epr "Applying patches total=%d...@." (List.length patches);
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
    Fmt.epr "Found %d substs; patches=%d others=%d...@." (List.length substs)
      (List.length subst_patches)
      (List.length subst_others);
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
        (fun (base, hash) ->
          let src = make_opam_path ~opamfile base in
          if OpamHash.check_file (OpamFilename.to_string src) hash then (
            let dst = OpamFilename.create build_dir base in
            Fmt.epr ">>> Copying extra file: %a -> %a@." Opam_utils.pp_filename
              src Opam_utils.pp_filename dst;
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
        Fmt.epr ">>> Copying undeclared file: %a -> %a@." Opam_utils.pp_filename
          src Opam_utils.pp_filename dst;
        OpamFilename.copy ~src ~dst)
      (OpamFilename.files files_dir)

  (* TODO: implement extra file fetching via lock-file?:
     - https://github.com/ocaml/opam/blob/e36650b3007e013cfb5b6bb7ed769a349af3ee97/src/client/opamAction.ml#L455 *)
  let run ~ocaml_version ~path build_ctx_file =
    let ctx : Build_context.t =
      Build_context.read_file ~ocaml_version ~path build_ctx_file
    in
    let opam = Opam_utils.read_opam ctx.self.opam in
    let opamfile = OpamFilename.of_string (Fpath.to_string ctx.self.opam) in
    Fmt.epr "Decoded build context for: %S@."
      (OpamPackage.Name.to_string ctx.self.name);
    let () =
      let build_dir = OpamFilename.Dir.of_string (Sys.getcwd ()) in
      match OpamFile.OPAM.extra_files opam with
      | None ->
        Fmt.epr
          "No extra files in opam file, checking for undeclared files...@.";
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

let run_commands commands =
  let open Bos in
  List.iter
    (fun cmd ->
      let cmd = Cmd.of_list cmd in
      match OS.Cmd.run_status cmd with
      | Ok (`Exited 0) -> ()
      | Ok (`Exited n) ->
        Fmt.failwith "Command terminated with a non-zero code: %d@." n
      | Ok (`Signaled n) -> Fmt.failwith "Command terminated by signal: %d@." n
      | Error (`Msg err) -> Fmt.failwith "Could not run command: %s" err)
    commands

let build ?(test = false) ?(doc = false) ~ocaml_version ~path build_ctx_file =
  let ctx : Build_context.t =
    Build_context.read_file ~ocaml_version ~path build_ctx_file
  in
  let opam = Opam_utils.read_opam ctx.self.opam in
  Fmt.epr "Decoded build context for: %S@."
    (OpamPackage.Name.to_string ctx.self.name);
  let commands =
    (OpamFilter.commands
       (Build_context.resolve ctx ~local:(local_vars ~test ~doc))
       (OpamFile.OPAM.build opam)
    @ (if test then
       OpamFilter.commands
         (Build_context.resolve ctx)
         (OpamFile.OPAM.run_test opam)
      else [])
    @
    if doc then
      OpamFilter.commands
        (Build_context.resolve ctx)
        (OpamFile.OPAM.deprecated_build_doc opam)
    else [])
    |> List.filter List.is_not_empty
  in
  List.iter (fun cmd -> Fmt.epr ">>> %s@." (String.concat " " cmd)) commands;
  run_commands commands

let make_path_lib ~ocaml_version (pkg : Build_context.package) =
  let prefix = OpamFilename.Dir.to_string pkg.path in
  String.concat "/"
    [
      prefix;
      "lib/ocaml";
      OpamPackage.Version.to_string ocaml_version;
      "site-lib";
    ]

let make_opam_install_commands ~path (ctx : Build_context.t) =
  let install_file = OpamPackage.Name.to_string ctx.self.name ^ ".install" in
  let libdir = make_path_lib ~ocaml_version:ctx.ocaml_version ctx.self in
  if Sys.file_exists install_file then
    ["opam-installer"; "--prefix=" ^ path; "--libdir=" ^ libdir; install_file]
  else (
    Fmt.epr "Warning: no %S file: cwd=%S@." install_file (Sys.getcwd ());
    [])

let install ?(test = false) ?(doc = false) ~ocaml_version ~path build_ctx_file =
  let ctx : Build_context.t =
    Build_context.read_file ~ocaml_version ~path build_ctx_file
  in
  let opam = Opam_utils.read_opam ctx.self.opam in
  Fmt.epr "Decoded build context for: %S@."
    (OpamPackage.Name.to_string ctx.self.name);
  let commands =
    OpamFilter.commands
      (Build_context.resolve ctx ~local:(local_vars ~test ~doc))
      (OpamFile.OPAM.install opam)
    @ [make_opam_install_commands ~path ctx]
    |> List.filter List.is_not_empty
  in
  List.iter (fun cmd -> Fmt.epr ">>> %s@." (String.concat " " cmd)) commands;
  run_commands commands
