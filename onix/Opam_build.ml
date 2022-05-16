open Utils

let local_vars ~test ~doc =
  OpamVariable.Map.of_list
    [
      (OpamVariable.of_string "with-test", Some (OpamVariable.B test));
      (OpamVariable.of_string "with-doc", Some (OpamVariable.B doc));
    ]

let run ?(test = true) ?(doc = true) build_ctx_file =
  let ctx : Build_context.t = Build_context.read_file build_ctx_file in
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
  List.iter (fun cmd -> Fmt.pr "%S@." (String.concat " " cmd)) commands
