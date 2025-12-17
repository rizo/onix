open Utils

let mk_dep_vars ~with_test ~with_doc ~with_dev_setup =
  let open OpamVariable in
  Map.of_list
    [
      (of_string "with-test", Some (B with_test));
      (of_string "with-doc", Some (B with_doc));
      (of_string "with-dev-setup", Some (B with_dev_setup));
    ]

let resolve_actions =
  let build_dir = Sys.getcwd () in
  fun ?(local = OpamVariable.Map.empty) pkg_scope ->
    Scope.resolve_many
      [
        Scope.resolve_stdenv_host;
        Scope.resolve_local local;
        Scope.resolve_config pkg_scope;
        Scope.resolve_global_host;
        Scope.resolve_pkg ~build_dir pkg_scope;
      ]

module Patch = struct
  let copy_extra_files ~opamfile ~build_dir extra_files =
    let bad_hash =
      Stdlib.List.filter_map
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
  let run (pkg_scope : Scope.t) =
    let opamfile = OpamFilename.of_string pkg_scope.self.opamfile in
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
    let resolve = resolve_actions pkg_scope in
    let cwd = OpamFilename.Dir.of_string (Sys.getcwd ()) in
    let pkg = OpamPackage.create pkg_scope.self.name pkg_scope.self.version in
    OpamAction.prepare_package_build resolve opam pkg cwd
    |> Option.if_some raise
end

let patch = Patch.run

let build ~with_test ~with_doc ~with_dev_setup (pkg_scope : Scope.t) =
  let opam =
    Opam_utils.read_opam (OpamFilename.of_string pkg_scope.self.opamfile)
  in
  let resolve_with_dep_vars =
    resolve_actions
      ~local:(mk_dep_vars ~with_test ~with_doc ~with_dev_setup)
      pkg_scope
  in
  let resolve =
    resolve_actions
      ~local:(mk_dep_vars ~with_test ~with_doc ~with_dev_setup)
      pkg_scope
  in
  let commands =
    (OpamFilter.commands resolve_with_dep_vars (OpamFile.OPAM.build opam)
    @ (if with_test then
         OpamFilter.commands resolve (OpamFile.OPAM.run_test opam)
       else [])
    @
    if with_doc then
      OpamFilter.commands resolve (OpamFile.OPAM.deprecated_build_doc opam)
    else [])
    |> List.filter List.is_not_empty
  in
  commands

module Install = struct
  let run ~with_test ~with_doc ~with_dev_setup (pkg_scope : Scope.t) =
    let opam =
      Opam_utils.read_opam (OpamFilename.of_string pkg_scope.self.opamfile)
    in
    let resolve_with_dep_vars =
      resolve_actions
        ~local:(mk_dep_vars ~with_test ~with_doc ~with_dev_setup)
        pkg_scope
    in
    OpamFilter.commands resolve_with_dep_vars (OpamFile.OPAM.install opam)
    |> List.filter List.is_not_empty
end

let install = Install.run
let all ~with_test ~with_doc ~with_dev_setup (pkg_scope : Scope.t) = ()
