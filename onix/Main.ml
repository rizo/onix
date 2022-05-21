open Cmdliner

let build_ctx_file_arg =
  let doc = "Path to the build context of the package to be built." in
  let docv = "FILE" in
  Arg.(info [] ~docv ~doc |> pos 0 (some file) None |> required)

let ocaml_version_arg =
  let doc = "The version of OCaml to be used." in
  let docv = "VERSION" in
  Arg.(info ["ocaml-version"] ~docv ~doc |> opt (some string) None |> required)

let path_arg =
  let doc = "Path to the built package." in
  let docv = "PATH" in
  Arg.(info ["path"] ~docv ~doc |> opt (some string) None |> required)

let repo_arg =
  let doc =
    "The URL of the OPAM repository to be used when solving the dependencies.\n\
    \     Examples:\n\
    \     - https://github.com/ocaml/opam-repository.git\n\
    \     - \
     https://github.com/ocaml/opam-repository.git#16ff1304f8ccdd5a8c9fa3ebe906c32ecdd576ee"
  in
  let docv = "REPO" in
  Arg.(
    info ["repo"] ~docv ~doc
    |> opt (some string) (Some "https://github.com/ocaml/opam-repository.git")
    |> required)

module Opam_build = struct
  let run ocaml_version path build_ctx =
    Fmt.epr "onix: Building ocaml_version=%S path=%S@." ocaml_version path;
    Onix.Opam_actions.build ~ocaml_version ~path build_ctx

  let info =
    Cmd.info "opam-build" ~doc:"Build a package from a package closure file."

  let cmd =
    Cmd.v info
      Term.(const run $ ocaml_version_arg $ path_arg $ build_ctx_file_arg)
end

module Opam_install = struct
  let run ocaml_version path build_ctx =
    Fmt.epr "onix: Installing ocaml_version=%S path=%S@." ocaml_version path;
    Onix.Opam_actions.install ~ocaml_version ~path build_ctx

  let info =
    Cmd.info "opam-install"
      ~doc:"Install a package from a package closure file."

  let cmd =
    Cmd.v info
      Term.(const run $ ocaml_version_arg $ path_arg $ build_ctx_file_arg)
end

module Opam_patch = struct
  let run ocaml_version path build_ctx =
    Fmt.epr "onix: Patching ocaml_version=%S path=%S ctx=%S@." ocaml_version
      path build_ctx;
    Onix.Opam_actions.patch ~ocaml_version ~path build_ctx

  let info = Cmd.info "opam-patch" ~doc:"Apply opam package patches."

  let cmd =
    Cmd.v info
      Term.(const run $ ocaml_version_arg $ path_arg $ build_ctx_file_arg)
end

let onix_lock_file_name = "./onix-lock.nix"

module Lock = struct
  let input_opam_files_arg =
    Arg.(value & pos_all file [] & info [] ~docv:"OPAM_FILE")

  let run repo_uri input_opam_files =
    let root_packages = Onix.Opam_utils.find_root_packages input_opam_files in
    let root_package_names =
      Onix.Opam_utils.get_root_package_names root_packages
    in
    let pins = Onix.Opam_utils.Pins.collect_from_opam_files root_packages in
    let lock_file =
      Onix.Solver.solve ~repo_uri ~root_packages ~pins
        ("ocaml-base-compiler" :: root_package_names)
    in
    Onix.Utils.Out_channel.with_open_text onix_lock_file_name (fun chan ->
        let out = Format.formatter_of_out_channel chan in
        Fmt.pf out "%a" Onix.Lock_file.pp lock_file);
    Fmt.epr "Created a lock file at %S.@." onix_lock_file_name

  let info = Cmd.info "lock" ~doc:"Solve dependencies and create a lock file."
  let cmd = Cmd.v info Term.(const run $ repo_arg $ input_opam_files_arg)
end

module Build = struct
  let run () =
    Fmt.epr "Building..."
  let info = Cmd.info "build" ~doc:"Build the project from a lock file."
  let cmd = Cmd.v info Term.(const run $ const ())
end

let () =
  Printexc.record_backtrace true;
  let doc = "Manage OCaml projects with Nix" in
  let sdocs = Manpage.s_common_options in

  let info = Cmd.info "onix" ~version:"0.0.1" ~doc ~sdocs in

  let default =
    let run () = `Help (`Pager, None) in
    Term.(ret (const run $ const ()))
  in
  [Lock.cmd; Opam_build.cmd; Opam_install.cmd; Opam_patch.cmd]
  |> Cmdliner.Cmd.group info ~default
  |> Cmdliner.Cmd.eval
  |> Stdlib.exit
