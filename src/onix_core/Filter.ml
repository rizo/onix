open Utils

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

let resolve_build ?system ?(with_test = false) ?(with_doc = false)
    ?(with_dev_setup = false) pkg_scope =
  Scope.resolve_many
    [
      Scope.resolve_stdenv_host;
      Scope.resolve_dep ~test:with_test ~doc:with_doc ~dev_setup:with_dev_setup;
      Scope.resolve_config pkg_scope;
      Scope.resolve_global ?system ~jobs:Nix_utils.nix_build_jobs_var;
      Scope.resolve_pkg ~build_dir:"." pkg_scope;
    ]

let pp_command f (args_str, system_filter) =
  match system_filter with
  | None -> Fmt.pf f "%S" (String.concat " " args_str)
  | Some (`arch arch) ->
    Fmt.pf f {|@[<v2>[%S, {"arch": %S}]@]|} (String.concat " " args_str) arch
  | Some (`os os) ->
    Fmt.pf f {|@[<v2>[%S, {"os": "%s"}]@]|} (String.concat " " args_str) os
  | Some (`system (system : System.t)) ->
    Fmt.pf f {|@[<v2>[%S, {"arch": %S, "os": %S}]@]|}
      (String.concat " " args_str)
      system.arch system.os

let pp_commands f
    (commands :
      (string list
      * [`system of System.t | `arch of string | `os of string] option)
      list) =
  if List.is_empty commands then ()
  else
    Fmt.pf f {|@[<v2>"build": [@,%a@]@,]|}
      (Fmt.list ~sep:Fmt.comma pp_command)
      commands

let rec simplify_conjunction (filter : OpamTypes.filter) : OpamTypes.filter =
  match filter with
  | FOp (f1, relop, f2) ->
    FOp (simplify_conjunction f1, relop, simplify_conjunction f2)
  | FOr (f1, f2) -> FOr (simplify_conjunction f1, simplify_conjunction f2)
  | FNot f1 -> simplify_conjunction f1
  | FAnd (FBool true, f) | FAnd (f, FBool true) -> simplify_conjunction f
  | FAnd (f1, f2) -> FAnd (simplify_conjunction f1, simplify_conjunction f2)
  | _ -> filter

let partial_eval ~env filter =
  let filter' = OpamFilter.partial_eval env filter in
  simplify_conjunction filter'

let system_resolver_for_vars full_vars =
  let has_arch, has_os =
    List.fold_left
      (fun (has_arch, has_os) fv ->
        let var = OpamVariable.(to_string (Full.variable fv)) in
        match var with
        | "arch" -> (true, has_os)
        | "os" -> (has_arch, true)
        | _ -> (has_arch, has_os))
      (false, false) full_vars
  in
  match (has_arch, has_os) with
  | true, true ->
    List.map
      (fun (system : System.t) ->
        (`system system, Scope.resolve_system ~os:system.os ~arch:system.arch))
      System.all
  | true, false ->
    List.map
      (fun arch -> (`arch arch, Scope.resolve_system ~arch ?os:None))
      System.arch_list
  | false, true ->
    List.map
      (fun os -> (`os os, Scope.resolve_system ?arch:None ~os))
      System.os_list
  | false, false -> []

let eval_filter_for_systems ~static_env filter =
  (* Partially eval the cmd args filter with the static env. *)
  let filter_static = partial_eval ~env:static_env filter in
  match filter_static with
  | FBool false -> []
  | FBool true ->
    (* This is a non-system specific filter. *)
    [None]
  | _ ->
    let remaining_vars = OpamFilter.variables filter_static in
    let resolvers_by_system = system_resolver_for_vars remaining_vars in
    List.fold_left
      (fun acc (kind, env) ->
        (* Attempt to eval for each system env. *)
        let bool = OpamFilter.eval_to_bool ~default:false env filter_static in
        if bool then Some kind :: acc else acc)
      [] resolvers_by_system

let process_command ~with_test ~with_doc ~with_dev_setup scope
    ((args, filter_opt) : OpamTypes.command) =
  let static_env = resolve_build ~with_test ~with_doc ~with_dev_setup scope in
  let args' = OpamFilter.single_command static_env args in
  match filter_opt with
  | Some filter ->
    let target_systems = eval_filter_for_systems ~static_env filter in
    List.map (fun sys -> (args', sys)) target_systems
  | None -> [(args', None)]

let process_commands ~with_test ~with_doc ~with_dev_setup scope commands =
  List.concat_map
    (process_command ~with_test ~with_doc ~with_dev_setup scope)
    commands
