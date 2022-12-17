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
  let doc = "The path to the lock file (by default ./onix-lock.nix)." in
  let docv = "FILE" in
  Arg.(info ["lock-file"] ~docv ~doc |> opt string "./onix-lock.nix" |> value)

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

let flag_scopes =
  [("true", `root); ("deps", `deps); ("all", `all); ("false", `none)]

let with_test_arg ~absent =
  let doc =
    "Include {with-test} constrained packages. Applies to the root packages \
     only if passed without value. The possible values are: `true', `deps', \
     `all' or `false'"
  in
  Arg.info ["with-test"] ~doc ~docv:"VAL"
  |> Arg.opt ~vopt:`root (Arg.enum flag_scopes) absent
  |> Arg.value

let with_doc_arg ~absent =
  let doc =
    "Include {with-doc} constrained packages. Applies to the root packages \
     only if passed without value. The possible values are: `true', `deps', \
     `all' or `false'"
  in
  Arg.info ["with-doc"] ~doc ~docv:"VAL"
  |> Arg.opt ~vopt:`root (Arg.enum flag_scopes) absent
  |> Arg.value

let with_dev_setup_arg ~absent =
  let doc =
    "Include {with-dev-setup} constrained packages. Applies to the root \
     packages only if passed without value. The possible values are: `true', \
     `deps', `all' or `false'"
  in
  Arg.info ["with-dev-setup"] ~doc ~docv:"VAL"
  |> Arg.opt ~vopt:`root (Arg.enum flag_scopes) absent
  |> Arg.value

let mk_pkg_ctx ~ocaml_version ~opamfile ~prefix ~opam_pkg () =
  let onix_path = Sys.getenv_opt "ONIXPATH" or "" in
  let dependencies =
    Onix.Pkg_ctx.dependencies_of_onix_path ~ocaml_version onix_path
  in
  let opam_pkg = OpamPackage.of_string opam_pkg in
  let self =
    {
      Onix.Pkg_ctx.name = opam_pkg.name;
      version = opam_pkg.version;
      prefix;
      opamfile;
    }
  in
  Onix.Pkg_ctx.make ~dependencies ~ocaml_version self

module Opam_patch = struct
  let run style_renderer log_level ocaml_version opamfile prefix opam_pkg =
    setup_logs style_renderer log_level;
    Logs.info (fun log ->
        log "opam-patch: Running... pkg=%S ocaml=%S prefix=%S opam=%S" opam_pkg
          ocaml_version prefix opamfile);
    let ctx = mk_pkg_ctx ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix.Opam_actions.patch ctx;
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
    let ctx = mk_pkg_ctx ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix.Opam_actions.build ~with_test ~with_doc ~with_dev_setup ctx
    |> List.iter Onix.Utils.Os.run_command;
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
        $ with_test_arg ~absent:`none
        $ with_doc_arg ~absent:`none
        $ with_dev_setup_arg ~absent:`none
        $ package_prefix_arg
        $ opam_package_arg)
end

module Opam_install = struct
  let run ocaml_version opamfile with_test with_doc with_dev_setup prefix
      opam_pkg =
    Logs.info (fun log ->
        log "opam-install: Running... pkg=%S ocaml=%S prefix=%S opam=%S"
          opam_pkg ocaml_version prefix opamfile);
    let ctx = mk_pkg_ctx ~ocaml_version ~opamfile ~prefix ~opam_pkg () in
    Onix.Opam_actions.install ~with_test ~with_doc ~with_dev_setup ctx
    |> List.iter Onix.Utils.Os.run_command;
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
        $ with_test_arg ~absent:`none
        $ with_doc_arg ~absent:`none
        $ with_dev_setup_arg ~absent:`none
        $ package_prefix_arg
        $ opam_package_arg)
end

module Lock = struct
  let input_opam_paths_arg =
    let doc = "Input opam paths to be used during package resolution." in
    Arg.(value & pos_all file [] & info [] ~docv:"PATH" ~doc)

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
      (Onix.Resolutions.parse_resolution, Onix.Resolutions.pp_resolution)
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
      input_opam_paths =
    setup_logs style_renderer log_level;
    Logs.info (fun log -> log "lock: Running...");

    let repository_urls = List.map OpamUrl.of_string repository_urls in

    let input_opam_paths =
      List.map
        (fun path ->
          if not (is_opam_filename path) then
            Fmt.failwith "Provided input path is not an opam file name.";
          (* IMPORTANT: Do not resolve to absolute path. *)
          OpamFilename.raw path)
        input_opam_paths
    in

    let lock_file =
      Onix.Solver.solve ~repository_urls ~resolutions ~with_test ~with_doc
        ~with_dev_setup input_opam_paths
    in

    (* Generate onix lock file. *)
    Onix.Utils.Out_channel.with_open_text lock_file_path (fun chan ->
        let out = Format.formatter_of_out_channel chan in
        Fmt.pf out "%a" Onix.Pp_lock.pp lock_file);
    Logs.info (fun log -> log "Created a lock file at %S." lock_file_path);

    (* Generate opam lock file. *)
    Option.iter
      (fun opam_lock_file_path ->
        Onix.Utils.Out_channel.with_open_text opam_lock_file_path (fun chan ->
            let out = Format.formatter_of_out_channel chan in
            Fmt.pf out "%a" Onix.Pp_opam_lock.pp lock_file);
        Logs.info (fun log ->
            log "Created an opam lock file at %S." opam_lock_file_path))
      opam_lock_file_path

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
        $ with_test_arg ~absent:`root
        $ with_doc_arg ~absent:`root
        $ with_dev_setup_arg ~absent:`root
        $ input_opam_paths_arg)
end

let () =
  Printexc.record_backtrace true;
  let doc = "Manage OCaml projects with Nix" in
  let sdocs = Manpage.s_common_options in

  let info = Cmd.info "onix" ~version:"0.0.2" ~doc ~sdocs in

  let default =
    let run () = `Help (`Pager, None) in
    Term.(ret (const run $ const ()))
  in
  [Lock.cmd; Opam_build.cmd; Opam_install.cmd; Opam_patch.cmd]
  |> Cmdliner.Cmd.group info ~default
  |> Cmdliner.Cmd.eval
  |> Stdlib.exit
