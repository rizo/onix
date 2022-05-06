open Cmdliner

module Args = struct
  let target =
    Arg.(
      info ["target"] ~doc:"The target to build."
      |> opt (some string) None
      |> required)
end

let build =
  let run _target = print_endline "build" in
  let info = Cmd.info "build" ~doc:"Build a target" in
  Cmd.v info Term.(const run $ Args.target)

let onix_file_name = "onix.nix"

let solve =
  let run =
    let chan = open_in onix_file_name in
    print_endline "solve";
    let nix = Nix_parser.parse chan onix_file_name in
    Nix_parser.print stdout nix;
    close_in chan;

    match Onix.Solver.solve ["fmt"; "streaming"; "lwt"] with
    | Error e -> print_endline (Onix.Solver.diagnostics e)
    | Ok selections -> Onix.Solver.print_selections selections
  in

  let info =
    Cmd.info "solve" ~doc:"Solve dependencies and create a lock file."
  in
  Cmd.v info Term.(const run)

let () =
  let doc = "Manage OCaml projects with Nix" in
  let sdocs = Manpage.s_common_options in

  let info = Cmd.info "onix" ~version:"0.0.1" ~doc ~sdocs in

  let default =
    let run () = `Help (`Pager, None) in
    Term.(ret (const run $ const ()))
  in
  [build; solve]
  |> Cmdliner.Cmd.group info ~default
  |> Cmdliner.Cmd.eval
  |> Stdlib.exit
