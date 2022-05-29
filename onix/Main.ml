let setup_logs style_renderer log_level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ())

open Cmdliner

let ocaml_version_arg =
  let doc = "The version of OCaml to be used." in
  let docv = "VERSION" in
  Arg.(info ["ocaml-version"] ~docv ~doc |> opt (some string) None |> required)

let path_arg =
  let doc = "Nix store path of the package (i.e. the out directory)." in
  let docv = "PATH" in
  Arg.(info ["path"] ~docv ~doc |> opt (some string) None |> required)

let opam_package_arg =
  let doc = "The package information in the format `name.version'." in
  let docv = "PATH" in
  Arg.(info [] ~docv ~doc |> pos 0 (some string) None |> required)

let ignore_file_arg =
  let doc =
    "The path to the project ignore file (by default .gitignore). Pass \
     --ignore-file=none if you would like to avoid filtering the root sources."
  in
  let docv = "FILE" in
  Arg.(info ["ignore-file"] ~docv ~doc |> opt string ".gitignore" |> value)

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

let with_tools_arg ~absent =
  let doc =
    "Include {with-tools} constrained packages. Applies to the root packages \
     only if passed without value. The possible values are: `true', `deps', \
     `all' or `false'"
  in
  Arg.info ["with-tools"] ~doc ~docv:"VAL"
  |> Arg.opt ~vopt:`root (Arg.enum flag_scopes) absent
  |> Arg.value

let repo_url_arg =
  let doc =
    "The URL of the OPAM repository to be used when solving the dependencies. \
     Use the following format: \
     https://github.com/ocaml/opam-repository.git[#HASH]"
  in
  let docv = "URL" in
  Arg.(
    info ["repo-url"] ~env:(Cmd.Env.info "ONIX_REPO_URL") ~docv ~doc
    |> opt string "https://github.com/ocaml/opam-repository.git"
    |> value)

module Opam_patch = struct
  let run style_renderer log_level ocaml_version opam path opam_pkg =
    setup_logs style_renderer log_level;
    Logs.info (fun log ->
        log "opam-patch: Running... pkg=%S ocaml=%S path=%S opam=%S" opam_pkg
          ocaml_version path opam);
    Onix.Opam_actions.patch ~ocaml_version ~opam ~path opam_pkg;
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
        $ path_arg
        $ opam_package_arg)
end

module Opam_build = struct
  let run style_renderer log_level ocaml_version opam with_test with_doc
      with_tools path opam_pkg =
    setup_logs style_renderer log_level;
    Logs.info (fun log ->
        log "opam-build: Running... pkg=%S ocaml=%S path=%S opam=%S" opam_pkg
          ocaml_version path opam);
    Onix.Opam_actions.build ~ocaml_version ~opam ~with_test ~with_doc
      ~with_tools ~path opam_pkg;
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
        $ with_tools_arg ~absent:`none
        $ path_arg
        $ opam_package_arg)
end

module Opam_install = struct
  let run ocaml_version opam with_test with_doc with_tools path opam_pkg =
    Logs.info (fun log ->
        log "opam-install: Running... pkg=%S ocaml=%S path=%S opam=%S" opam_pkg
          ocaml_version path opam);
    Onix.Opam_actions.install ~ocaml_version ~opam ~with_test ~with_doc
      ~with_tools ~path opam_pkg;
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
        $ with_tools_arg ~absent:`none
        $ path_arg
        $ opam_package_arg)
end

let onix_lock_file_name = "./onix-lock.nix"

module Lock = struct
  let input_opam_files_arg =
    Arg.(value & pos_all file [] & info [] ~docv:"OPAM_FILE")

  let run style_renderer log_level ignore_file repo_url with_test with_doc
      with_tools input_opam_files =
    setup_logs style_renderer log_level;
    Logs.info (fun log -> log "lock: Running... repo_url=%S" repo_url);
    let ignore_file =
      if String.equal ignore_file "none" then None
      else if Sys.file_exists ignore_file then (
        Logs.debug (fun log ->
            log "Using %S ignore file to filter root sources." ignore_file);
        Some ignore_file)
      else (
        Logs.warn (fun log ->
            log
              "The ignore file %S does not exist, will not filter root sources."
              ignore_file);
        None)
    in
    let lock_file =
      Onix.Solver.solve ~repo_url ~with_test ~with_doc ~with_tools
        input_opam_files
    in
    Onix.Utils.Out_channel.with_open_text onix_lock_file_name (fun chan ->
        let out = Format.formatter_of_out_channel chan in
        Fmt.pf out "%a" (Onix.Lock_file.pp ~ignore_file) lock_file);
    Logs.info (fun log -> log "Created a lock file at %S." onix_lock_file_name)

  let info = Cmd.info "lock" ~doc:"Solve dependencies and create a lock file."

  let cmd =
    Cmd.v info
      Term.(
        const run
        $ Fmt_cli.style_renderer ()
        $ Logs_cli.level ~env:(Cmd.Env.info "ONIX_LOG_LEVEL") ()
        $ ignore_file_arg
        $ repo_url_arg
        $ with_test_arg ~absent:`root
        $ with_doc_arg ~absent:`root
        $ with_tools_arg ~absent:`root
        $ input_opam_files_arg)
end

module Build = struct
  let run () = Logs.info (fun log -> log "build: Running...")
  let info = Cmd.info "build" ~doc:"Build the project from a lock file."
  let cmd = Cmd.v info Term.(const run $ const ())
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
