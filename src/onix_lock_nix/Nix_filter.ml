let relop_kind_to_nix_string (relop_kind : OpamParserTypes.relop) =
  match relop_kind with
  | `Eq -> "=="
  | `Neq -> "!="
  | `Geq -> ">="
  | `Gt -> ">"
  | `Leq -> "<="
  | `Lt -> "<"

let opam_filter_to_nix_string ?custom (t : OpamTypes.filter) =
  let custom ~context ~paren t =
    match custom with
    | None -> None
    | Some f -> f ~context ~paren t
  in
  let rec aux ?(context = `Or) (t : OpamTypes.filter) =
    let paren ?(cond = false) f =
      if cond || OpamFormatConfig.(!r.all_parens) then Printf.sprintf "(%s)" f
      else f
    in
    match custom ~context ~paren t with
    | Some str -> str
    | None -> (
      match t with
      | FBool b -> string_of_bool b
      | FString s -> Printf.sprintf "%S" s
      | FIdent (pkgs, var, converter) -> (
        OpamStd.List.concat_map "+"
          (function
            | None -> "_"
            | Some p -> OpamPackage.Name.to_string p)
          pkgs
        ^ (if pkgs <> [] then ":" else "")
        ^ OpamVariable.to_string var
        ^
        match converter with
        | Some (it, ifu) -> "?" ^ it ^ ":" ^ ifu
        | None -> "")
      | FOp (e, s, f) ->
        paren
          ~cond:(context <> `Or && context <> `And)
          (Printf.sprintf "%s %s %s" (aux ~context:`Relop e)
             (relop_kind_to_nix_string s)
             (aux ~context:`Relop f))
      | FAnd (e, f) ->
        paren
          ~cond:(context <> `Or && context <> `And)
          (Printf.sprintf "%s && %s" (aux ~context:`And e) (aux ~context:`And f))
      | FOr (e, f) ->
        paren ~cond:(context <> `Or) (Printf.sprintf "%s || %s" (aux e) (aux f))
      | FNot e ->
        paren ~cond:(context = `Relop)
          (Printf.sprintf "!%s" (aux ~context:`Not e))
      | FDefined e ->
        paren ~cond:(context = `Relop)
          (Printf.sprintf "?%s" (aux ~context:`Defined e))
      | FUndef f -> Printf.sprintf "#undefined(%s)" (aux f))
  in
  aux t

let opam_filter_is bool = function
  | OpamTypes.FBool x when x = bool -> true
  | _ -> false

let rec simplify_conjunction (filter : OpamTypes.filter) : OpamTypes.filter =
  match filter with
  | FOp (f1, relop, f2) ->
    FOp (simplify_conjunction f1, relop, simplify_conjunction f2)
  | FOr (f1, f2) -> FOr (simplify_conjunction f1, simplify_conjunction f2)
  | FNot f1 -> simplify_conjunction f1
  | FAnd (FBool true, f) | FAnd (f, FBool true) -> simplify_conjunction f
  | FAnd (f1, f2) -> FAnd (simplify_conjunction f1, simplify_conjunction f2)
  | _ -> filter

let partial_eval_filter ~env filter =
  let filter' = OpamFilter.partial_eval env filter in
  simplify_conjunction filter'

let process_command ~env (cmd : OpamTypes.command) =
  match cmd with
  | args, Some filter -> (
    let filter' = partial_eval_filter ~env filter in
    (* let args' = OpamFilter.single_command dummy_env args in *)
    (* Fmt.pr "%a: %S --> %S |- %b@."
       Fmt.Dump.(list string)
       args'
       (OpamFilter.to_string filter)
       (OpamFilter.to_string filter')
       (opam_filter_is_false filter'); *)
    let args' = OpamFilter.single_command env args in
    match filter' with
    | OpamTypes.FBool true -> Some (args', None)
    | OpamTypes.FBool false -> None
    | _ -> Some (args', Some filter'))
  | args, None ->
    let args' = OpamFilter.single_command env args in
    Some (args', None)

let process_commands ~env commands =
  List.filter_map (process_command ~env) commands
