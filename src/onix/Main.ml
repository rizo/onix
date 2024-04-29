let ( or ) opt default =
  match opt with
  | Some x -> x
  | None -> default

let setup_logs style_renderer log_level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ())

open Cmdliner

let ocaml_version_arg =
  let doc = "The version of OCaml to be used." in
  let docv = "VERSION" in
  Arg.(info ["ocaml-version"] ~docv ~doc |> opt (some string) None |> required)

let package_prefix_arg =
  let doc = "Nix store prefix path of the package (i.e. the $out directory)." in
  let docv = "PATH" in
  Arg.(info ["path"] ~docv ~doc |> opt (some string) None |> required)

let opam_package_arg =
  let doc = "The package information in the format `name.version'." in
  let docv = "PATH" in
  Arg.(info [] ~docv ~doc |> pos 0 (some string) None |> required)

let lock_file_arg =
  let doc = "The path to the lock file (by default ./onix-lock.json)." in
  let docv = "FILE" in
  Arg.(info ["lock-file"] ~docv ~doc |> opt string "./onix-lock.json" |> value)

let opam_lock_file_arg =
  let doc =
    "The path to the \".opam.locked\" file. The opam lock file will not be \
     generated if this option is not passed."
  in
  let docv = "FILE" in
  Arg.(info ["opam-lock-file"] ~docv ~doc |> opt (some string) None |> value)

let opam_arg =
  let doc = "Path to the opam file of the package to be built." in
  let docv = "OPAM" in
  Arg.(info ["opam"] ~docv ~doc |> opt (some string) None |> required)

let with_test_arg =
  let doc =
    "Include {with-test} constrained packages. Applies to the root packages \
     only."
  in
  Arg.(info ["with-test"] ~doc |> opt bool false |> value)

let with_doc_arg =
  let doc =
    "Include {with-doc} constrained packages. Applies to the root packages \
     only."
  in
  Arg.(info ["with-doc"] ~doc |> opt bool false |> value)

let with_dev_setup_arg =
  let doc =
    "Include {with-dev-setup} constrained packages. Applies to the root \
     packages only."
  in
  Arg.(info ["with-dev-setup"] ~doc |> opt bool false |> value)

let make_scope ~ocaml_version ~opamfile ~prefix ~opam_pkg () =
  let onix_path = Sys.getenv_opt "ONIXPATH" or "" in
  let ocaml_version = OpamPackage.Version.of_string ocaml_version in
  let opam_pkg = OpamPackage.of_string opam_pkg in
  let self =
    Onix_core.Scope.make_pkg ~name:opam_pkg.name ~version:opam_pkg.version
      ~opamfile ~prefix
  in
  Onix_core.Scope.with_onix_path ~onix_path ~ocaml_version self

module Opam_patch = struct
  let run style_renderer log_level ocaml_version opamfile prefix opam_pkg =
    setup_logs style_renderer log_level;
    Logs.info (fun log ->
        log "opam-patch: Running... pkg=%S ocaml=%S prefix=%S opam=%S" opam_pkg
          ocaml_version prefix opamfile);
    let scope = make_scope ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix_core.Opam_actions.patch scope;
    Logs.info (fun log -> log "opam-patch: Done.")

  let info = Cmd.info "opam-patch" ~doc:"Apply opam package patches."

  let cmd =
    Cmd.v info
      Term.(
        const run
        $ Fmt_cli.style_renderer ()
        $ Logs_cli.level ~env:(Cmd.Env.info "ONIX_LOG_LEVEL") ()
        $ ocaml_version_arg
        $ opam_arg
        $ package_prefix_arg
        $ opam_package_arg)
end

module Opam_build = struct
  let run style_renderer log_level ocaml_version opamfile with_test with_doc
      with_dev_setup prefix opam_pkg =
    setup_logs style_renderer log_level;
    Logs.info (fun log ->
        log "opam-build: Running... pkg=%S ocaml=%S prefix=%S opam=%S" opam_pkg
          ocaml_version prefix opamfile);
    let scope = make_scope ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix_core.Opam_actions.build ~with_test ~with_doc ~with_dev_setup scope
    |> List.iter Onix_core.Utils.Os.run_command;
    Logs.info (fun log -> log "opam-build: Done.")

  let info =
    Cmd.info "opam-build" ~doc:"Build a package from a package closure file."

  let cmd =
    Cmd.v info
      Term.(
        const run
        $ Fmt_cli.style_renderer ()
        $ Logs_cli.level ~env:(Cmd.Env.info "ONIX_LOG_LEVEL") ()
        $ ocaml_version_arg
        $ opam_arg
        $ with_test_arg
        $ with_doc_arg
        $ with_dev_setup_arg
        $ package_prefix_arg
        $ opam_package_arg)
end

module Opam_install = struct
  let run ocaml_version opamfile with_test with_doc with_dev_setup prefix
      opam_pkg =
    Logs.info (fun log ->
        log "opam-install: Running... pkg=%S ocaml=%S prefix=%S opam=%S"
          opam_pkg ocaml_version prefix opamfile);
    let scope = make_scope ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix_core.Opam_actions.install ~with_test ~with_doc ~with_dev_setup scope
    |> List.iter Onix_core.Utils.Os.run_command;
    Logs.info (fun log -> log "opam-install: Done.")

  let info =
    Cmd.info "opam-install"
      ~doc:"Install a package from a package closure file."

  let cmd =
    Cmd.v info
      Term.(
        const run
        $ ocaml_version_arg
        $ opam_arg
        $ with_test_arg
        $ with_doc_arg
        $ with_dev_setup_arg
        $ package_prefix_arg
        $ opam_package_arg)
end

module Lock = struct
  let opam_file_paths_arg =
    let doc = "Input opam paths to be used during package resolution." in
    Arg.(value & pos_all file [] & info [] ~docv:"PATH" ~doc)

  let graphviz_file_path_arg =
    let doc = "Generate a dependency graph and save it at this path." in
    let docv = "FILE" in
    Arg.(info ["graphviz-file"] ~docv ~doc |> opt (some string) None |> value)

  let repository_urls_arg =
    let doc =
      "Comma-separated URLs of the OPAM repositories to be used when solving \
       the dependencies. Use the following format: \
       https://github.com/ocaml/opam-repository.git[#HASH]"
    in
    let docv = "LIST" in
    Arg.(
      info ["repository-urls"] ~docv ~doc
      |> opt (list string) ["https://github.com/ocaml/opam-repository.git"]
      |> value)

  let resolutions_arg =
    let conv =
      ( Onix_core.Resolutions.parse_resolution,
        Onix_core.Resolutions.pp_resolution )
    in
    let doc =
      "Additional packages and version constraints to be used during \
       dependency resolution."
    in
    Arg.info ["resolutions"] ~doc |> Arg.opt (Arg.list conv) [] |> Arg.value

  (* let repository_dir_arg = *)
  (*   let doc = *)
  (* "Local path to the OPAm repository that will be used for package lookup \ *)
     (*      resolution." *)
  (*   in *)
  (*   let docv = "LIST" in *)
  (*   Arg.( *)
  (*     info ["repository-dir"] ~docv ~doc |> opt (some string) None |> required) *)

  let is_opam_filename filename =
    String.equal (Filename.extension filename) ".opam"
    || String.equal (Filename.basename filename) "opam"

  let run style_renderer log_level lock_file_path opam_lock_file_path
      repository_urls resolutions with_test with_doc with_dev_setup
      opam_file_paths graphviz_file_path =
    setup_logs style_renderer log_level;
    Logs.info (fun log -> log "lock: Running...");

    let repository_urls = List.map OpamUrl.of_string repository_urls in

    let opam_file_paths =
      List.map
        (fun path ->
          if not (is_opam_filename path) then
            Fmt.failwith "Provided input path is not an opam file path.";
          (* IMPORTANT: Do not resolve to absolute path. *)
          OpamFilename.raw path)
        opam_file_paths
    in

    let lock_file =
      Onix_core.Solver.solve ~repository_urls ~resolutions ~with_test ~with_doc
        ~with_dev_setup opam_file_paths
    in
    Onix_lock_json.gen ~lock_file_path lock_file;

    let () =
      match opam_lock_file_path with
      | Some opam_lock_file_path ->
        Onix_lock_opam.gen ~opam_lock_file_path lock_file
      | None -> ()
    in

    let () =
      match graphviz_file_path with
      | Some graphviz_file_path ->
        Onix_lock_graphviz.gen ~graphviz_file_path lock_file
      | None -> ()
    in
    Logs.info (fun log -> log "Done.")

  let info = Cmd.info "lock" ~doc:"Solve dependencies and create a lock file."

  let cmd =
    Cmd.v info
      Term.(
        const run
        $ Fmt_cli.style_renderer ()
        $ Logs_cli.level ~env:(Cmd.Env.info "ONIX_LOG_LEVEL") ()
        $ lock_file_arg
        $ opam_lock_file_arg
        $ repository_urls_arg
        $ resolutions_arg
        $ with_test_arg
        $ with_doc_arg
        $ with_dev_setup_arg
        $ opam_file_paths_arg
        $ graphviz_file_path_arg)
end

let () =
  Printexc.record_backtrace true;
  let doc = "Manage OCaml projects with Nix" in
  let sdocs = Manpage.s_common_options in

  let info = Cmd.info "onix" ~version:Onix_core.Lib.version ~doc ~sdocs in

  let default =
    let run () = `Help (`Pager, None) in
    Term.(ret (const run $ const ()))
  in
  [Lock.cmd; Opam_build.cmd; Opam_install.cmd; Opam_patch.cmd]
  |> Cmdliner.Cmd.group info ~default
  |> Cmdliner.Cmd.eval
  |> Stdlib.exit
