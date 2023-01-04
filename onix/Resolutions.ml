type t = {
  with_constraint : OpamFormula.version_constraint OpamPackage.Name.Map.t;
  without_constraint : OpamPackage.Name.Set.t;
  compiler : OpamPackage.Name.t;
}

let default =
  {
    with_constraint = OpamPackage.Name.Map.empty;
    without_constraint =
      OpamPackage.Name.Set.singleton Opam_utils.ocamlfind_name;
    compiler = Opam_utils.ocaml_base_compiler_name;
  }

let constraints t = t.with_constraint

let make t =
  List.fold_left
    (fun acc (name, constraint_opt) ->
      let acc =
        if Opam_utils.is_ocaml_compiler_name name then
          { acc with compiler = name }
        else acc
      in
      match constraint_opt with
      | Some constr ->
        {
          acc with
          with_constraint =
            OpamPackage.Name.Map.add name constr acc.with_constraint;
        }
      | None ->
        {
          acc with
          without_constraint =
            OpamPackage.Name.Set.add name acc.without_constraint;
        })
    default t

let all t =
  OpamPackage.Name.Map.fold
    (fun name _ acc -> OpamPackage.Name.Set.add name acc)
    t.with_constraint t.without_constraint
  |> OpamPackage.Name.Set.add t.compiler
  |> OpamPackage.Name.Set.to_seq
  |> List.of_seq

let debug t =
  if OpamPackage.Name.Map.cardinal t.with_constraint > 0 then
    Fmt.epr "Resolutions:@.";
  OpamPackage.Name.Map.iter
    (fun n vc ->
      Fmt.epr "- %s@." (OpamFormula.short_string_of_atom (n, Some vc)))
    t.with_constraint;
  OpamPackage.Name.Set.iter
    (fun n -> Fmt.epr "- %a@." Opam_utils.pp_package_name n)
    t.without_constraint

let resolution_re =
  Re.
    [
      bos;
      group (rep1 (diff any (set ">=<.!")));
      group (alt [seq [set "<>"; opt (char '=')]; set "=."; str "!="]);
      group (rep1 any);
      eos;
    ]
  |> Re.seq
  |> Re.compile

let parse_resolution str =
  try
    let sub = Re.exec resolution_re str in
    let name = OpamPackage.Name.of_string (Re.Group.get sub 1) in
    let op = Re.Group.get sub 2 in
    let op = if op = "." then "=" else op in
    let op = OpamLexer.FullPos.relop op in
    let version = Re.Group.get sub 3 in
    let version = OpamPackage.Version.of_string version in
    `Ok (name, Some (op, version))
  with Not_found | Failure _ | OpamLexer.Error _ -> (
    try `Ok (OpamPackage.Name.of_string str, None)
    with Failure msg -> `Error msg)

let pp_resolution ppf x = Fmt.string ppf (OpamFormula.short_string_of_atom x)
