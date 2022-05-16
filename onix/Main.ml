open Cmdliner

module Opam_build = struct
  let pkg_file_arg =
    let doc = "Path to the package file to be built." in
    let docv = "PKG" in
    Arg.(info [] ~docv ~doc |> pos 0 (some file) None |> required)

  let run pkg_closure =
    print_endline
      ("opam-build: building package from closure file: " ^ pkg_closure);
    Onix.Opam_build.run pkg_closure

  let info =
    Cmd.info "opam-build" ~doc:"Build a package from a package closure file."

  let cmd = Cmd.v info Term.(const run $ pkg_file_arg)
end

let onix_lock_file_name = "onix-lock.nix"

module Solve = struct
  let input_opam_files_arg =
    Arg.(value & pos_all file [] & info [] ~docv:"OPAM_FILE")

  let run input_opam_files =
    let project_packages =
      Onix.Opam_utils.read_project_opams input_opam_files
    in
    let pins = Onix.Opam_utils.Pins.collect_from_opam_files project_packages in
    let locked_packages =
      Onix.Solver.solve ~project_packages ~pins
        ["onix-example"; "ocaml-base-compiler"]
    in
    let lock_file = Onix.Lock_file.make locked_packages in
    Onix.Utils.Out_channel.with_open_text onix_lock_file_name (fun chan ->
        let out = Format.formatter_of_out_channel chan in
        Fmt.pf out "%a" Onix.Lock_file.pp lock_file);
    Fmt.epr "Done.@."

  let info = Cmd.info "solve" ~doc:"Solve dependencies and create a lock file."
  let cmd = Cmd.v info Term.(const run $ input_opam_files_arg)
end

let () =
  let doc = "Manage OCaml projects with Nix" in
  let sdocs = Manpage.s_common_options in

  let info = Cmd.info "onix" ~version:"0.0.1" ~doc ~sdocs in

  let default =
    let run () = `Help (`Pager, None) in
    Term.(ret (const run $ const ()))
  in
  [Solve.cmd; Opam_build.cmd]
  |> Cmdliner.Cmd.group info ~default
  |> Cmdliner.Cmd.eval
  |> Stdlib.exit
