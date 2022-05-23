open Utils

type package = {
  name : OpamPackage.Name.t;
  version : OpamPackage.Version.t;
  opam : OpamFilename.t;
  path : OpamFilename.Dir.t;
}

type t = {
  self : package;
  ocaml_version : OpamPackage.Version.t;
  scope : package OpamPackage.Name.Map.t;
  vars : OpamTypes.variable_contents OpamVariable.Full.Map.t;
}

module Vars = struct
  let add_native_system_vars vars =
    let system_variables = OpamSysPoll.variables in
    List.fold_left
      (fun vars ((name : OpamVariable.t), value) ->
        match value with
        | (lazy None) -> vars
        | (lazy (Some contents)) ->
          let var = OpamVariable.Full.global name in
          OpamVariable.Full.Map.add var contents vars)
      vars system_variables

  let add_global_vars vars =
    let string = OpamVariable.string in
    let bool = OpamVariable.bool in
    let add var =
      OpamVariable.Full.Map.add
        (OpamVariable.Full.global (OpamVariable.of_string var))
    in
    let add_pkg name var =
      OpamVariable.Full.Map.add
        ((OpamVariable.Full.create (OpamPackage.Name.of_string name))
           (OpamVariable.of_string var))
    in
    vars
    |> add "opam-version" (string (OpamVersion.to_string OpamVersion.current))
    |> add "jobs" (string (Nix_utils.get_nix_build_jobs ()))
    |> add "make" (string "make")
    |> add "os-version" (string "unknown")
    |> add_pkg "ocaml" "preinstalled" (bool true)
    |> add_pkg "ocaml" "native" (bool true)
    |> add_pkg "ocaml" "native-tools" (bool true)
    |> add_pkg "ocaml" "native-dynlink" (bool true)

  let add_nixos_vars vars =
    let string = OpamVariable.string in
    let add var =
      OpamVariable.Full.Map.add
        (OpamVariable.Full.global (OpamVariable.of_string var))
    in
    vars
    |> add "os-distribution" (string "nixos")
    |> add "os-family" (string "nixos")
    |> add "os-version" (string "unknown")

  let default =
    OpamVariable.Full.Map.empty |> add_native_system_vars |> add_global_vars

  let nixos = default |> add_nixos_vars

  let make_path_ ?suffix ~prefix pkg_name =
    match (pkg_name, suffix) with
    | Some pkg_name, Some suffix ->
      String.concat "/" [prefix; suffix; OpamPackage.Name.to_string pkg_name]
    | Some package_name, None ->
      String.concat "/" [prefix; OpamPackage.Name.to_string package_name]
    | None, Some suffix -> String.concat "/" [prefix; suffix]
    | None, None -> prefix

  let make_path ?suffix ~prefix pkg_name =
    match (pkg_name, suffix) with
    | Some pkg_name, Some suffix ->
      String.concat "/" [prefix; suffix; OpamPackage.Name.to_string pkg_name]
    | Some package_name, None ->
      String.concat "/" [prefix; OpamPackage.Name.to_string package_name]
    | None, Some suffix -> String.concat "/" [prefix; suffix]
    | None, None -> prefix

  let resolve_from_scope t v =
    let scope =
      match OpamVariable.Full.scope v with
      | Self -> `Package t.self
      | Package pkg_name -> (
        match OpamPackage.Name.Map.find_opt pkg_name t.scope with
        | Some pkg -> `Package pkg
        | None -> `Missing)
      | Global -> `Global
    in
    let bool x = Some (OpamVariable.bool x) in
    let string x = Some (OpamVariable.string x) in
    let lib ?suffix pkg =
      let ocaml_version = OpamPackage.Version.to_string t.ocaml_version in
      let prefix, pkg_name =
        match pkg with
        | Some pkg -> (pkg.path, Some pkg.name)
        | None -> (t.self.path, None)
      in
      let prefix = OpamFilename.Dir.to_string prefix in
      let prefix =
        String.concat "/" [prefix; "lib/ocaml"; ocaml_version; "site-lib"]
      in
      string (make_path ~prefix ?suffix pkg_name)
    in
    let out ?suffix ~scoped pkg =
      let prefix, pkg_name =
        match pkg with
        | Some pkg when scoped -> (pkg.path, Some pkg.name)
        | Some pkg -> (pkg.path, None)
        | None -> (t.self.path, None)
      in
      let prefix = OpamFilename.Dir.to_string prefix in
      string (make_path ~prefix ?suffix pkg_name)
    in
    let v = OpamVariable.to_string (OpamVariable.Full.variable v) in
    match (v, scope) with
    (* metadata vars *)
    | "installed", `Global -> bool false (* not yet? *)
    | "installed", `Package _ -> bool true
    | "installed", `Missing -> bool false
    | "pinned", `Global -> bool (Opam_utils.is_pinned_version t.self.version)
    | "pinned", `Package pkg -> bool (Opam_utils.is_pinned_version pkg.version)
    | "pinned", `Missing -> bool false
    | "name", `Global -> string (OpamPackage.Name.to_string t.self.name)
    | "name", `Package pkg -> string (OpamPackage.Name.to_string pkg.name)
    (* Should this be allowed? *)
    (* | "name", `Missing -> string (OpamPackage.Name.to_string OpamVariable.Full.scope) *)
    | "build", _ -> string "ONIX_NOT_IMPLEMENTED_build"
    | "dev", _ -> bool false
    | "version", `Global ->
      string (OpamPackage.Version.to_string t.self.version)
    | "version", `Package pkg ->
      string (OpamPackage.Version.to_string pkg.version)
    | "build-id", `Global -> string (OpamFilename.Dir.to_string t.self.path)
    | "build-id", `Package pkg -> string (OpamFilename.Dir.to_string pkg.path)
    | "opamfile", `Global -> string (OpamFilename.to_string t.self.opam)
    | "opamfile", `Package pkg -> string (OpamFilename.to_string pkg.opam)
    | "depends", _ | "hash", _ -> string ("ONIX_NOT_IMPLEMENTED_" ^ v)
    (* site-lib paths *)
    | "lib", `Global -> lib None
    | "lib", `Package pkg -> lib (Some pkg)
    | "stublibs", `Global -> lib ~suffix:v None
    | "stublibs", `Package pkg -> lib ~suffix:v (Some pkg)
    | "toplevel", `Global -> lib ~suffix:v None
    | "toplevel", `Package pkg -> lib ~suffix:v (Some pkg)
    (* base paths *)
    | "bin", `Global | "bin", `Package _ | "sbin", `Global | "sbin", `Package _
      -> out ~suffix:v None ~scoped:false
    | "man", `Global -> out ~suffix:v None ~scoped:false
    | "man", `Package pkg -> out ~suffix:v (Some pkg) ~scoped:false
    | "doc", `Global -> out ~suffix:v None ~scoped:false
    | "doc", `Package pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | "share", `Global -> out ~suffix:v None ~scoped:false
    | "share", `Package pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | "etc", `Global -> out ~suffix:v None ~scoped:true
    | "etc", `Package pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | _ -> None

  let resolve_from_env full_var = OpamVariable.Full.read_from_env full_var

  let resolve_from_static vars full_var =
    OpamVariable.Full.Map.find_opt full_var vars

  let resolve_from_local local_vars var =
    match OpamVariable.Full.package var with
    | Some _ -> None
    | None -> (
      let var = OpamVariable.Full.variable var in
      try
        match OpamVariable.Map.find var local_vars with
        | None -> raise Exit (* Variable explicitly undefined *)
        | some -> some
      with Not_found -> None)

  let get_package_path () = None

  let resolve_from_global_scope t full_var =
    let string x = Some (OpamVariable.string x) in
    let var_str = OpamVariable.Full.to_string full_var in
    match (var_str, OpamPackage.Name.Map.find_opt t.self.name t.scope) with
    | "prefix", Some { path; _ }
    | "switch", Some { path; _ }
    | "root", Some { path; _ } -> string (OpamFilename.Dir.to_string path)
    | "user", _ -> Some (OpamVariable.string (Unix.getlogin ()))
    | "group", _ -> (
      try
        let gid = Unix.getgid () in
        let gname = (Unix.getgrgid gid).gr_name in
        Some (OpamVariable.string gname)
      with Not_found -> None)
    | "sys-ocaml-version", _ ->
      string (OpamPackage.Version.to_string t.ocaml_version)
    | _ -> None

  let try_resolvers resolvers full_var =
    let rec loop resolvers =
      match resolvers with
      | [] -> None
      | resolver :: resolvers' ->
        let contents = resolver full_var in
        if Option.is_some contents then contents else loop resolvers'
    in
    try loop resolvers with Exit -> None
end

let debug_var var contents =
  Fmt.pr "Variable lookup: %S = %a@."
    (OpamVariable.Full.to_string var)
    (Fmt.Dump.option
       (Fmt.using OpamVariable.string_of_variable_contents Fmt.Dump.string))
    contents

let resolve t ?(local = OpamVariable.Map.empty) full_var =
  let contents =
    Vars.try_resolvers
      [
        Vars.resolve_from_local local;
        Vars.resolve_from_env;
        Vars.resolve_from_static t.vars;
        Vars.resolve_from_global_scope t;
        Vars.resolve_from_scope t;
      ]
      full_var
  in
  contents

let make ~self ~ocaml_version ?(vars = Vars.default) scope =
  (* TODO: check ocaml versions. *)
  let ocaml_version = OpamPackage.Version.of_string ocaml_version in
  { self; ocaml_version; vars; scope }

let decode_depend json =
  match json with
  | `Assoc bindings ->
    let name = ref None in
    let version = ref None in
    let path = ref None in
    let opam = ref None in
    let decode_binding (key, json) =
      match (key, json) with
      | "name", `String x -> name := Some x
      | "name", _ -> invalid_arg "could not decode JSON: name must be a string"
      | "version", `String x -> version := Some x
      | "version", _ ->
        invalid_arg "could not decode JSON: version must be a string"
      | "path", `String x -> path := Some x
      | "path", _ -> invalid_arg "could not decode JSON: path must be a string"
      | "opam", `String x -> opam := Some x
      | "opam", _ -> invalid_arg "could not decode JSON: opam must be a string"
      | _, _ -> invalid_arg ("could not decode JSON: unknown key: " ^ key)
    in
    List.iter decode_binding bindings;
    let name =
      !name
      |> Option.or_fail "could not decode JSON: missing name key"
      |> OpamPackage.Name.of_string
    in
    let version =
      !version
      |> Option.or_fail "could not decode JSON: missing version key"
      |> OpamPackage.Version.of_string
    in
    let path =
      !path
      |> Option.or_fail "could not decode JSON: missing path key"
      |> OpamFilename.Dir.of_string
    in
    let opam =
      !opam
      |> Option.or_fail "could not decode JSON: missing opam key"
      |> OpamFilename.of_string
    in
    { name; version; opam; path }
  | _ -> invalid_arg "depends entry must be an object"

let read_json ~ocaml_version ~path json =
  match json with
  | `Assoc bindings ->
    let name = ref None in
    let version = ref None in
    let opam = ref None in
    let depends = ref [] in
    let decode_binding (key, json) =
      match (key, json) with
      | "name", `String x -> name := Some x
      | "name", _ -> invalid_arg "could not decode JSON: name must be a string"
      | "version", `String x -> version := Some x
      | "version", _ ->
        invalid_arg "could not decode JSON: version must be a string"
      | "opam", `String x -> opam := Some x
      | "opam", _ -> invalid_arg "could not decode JSON: opam must be a string"
      | "depends", `List xs -> depends := List.map decode_depend xs
      | "depends", _ ->
        invalid_arg "could not decode JSON: depends must be an array"
      | _, _ -> invalid_arg ("could not decode JSON: unknown key: " ^ key)
    in
    List.iter decode_binding bindings;
    let name =
      !name
      |> Option.or_fail "could not decode JSON: missing name key"
      |> OpamPackage.Name.of_string
    in
    let version =
      !version
      |> Option.or_fail "could not decode JSON: missing version key"
      |> OpamPackage.Version.of_string
    in
    let opam =
      !opam
      |> Option.or_fail "could not decode JSON: missing opam key"
      |> OpamFilename.of_string
    in
    let path = path |> OpamFilename.Dir.of_string in
    let self = { name; version; opam; path } in
    let depends =
      List.fold_left
        (fun acc pkg -> OpamPackage.Name.Map.add pkg.name pkg acc)
        OpamPackage.Name.Map.empty !depends
    in
    let scope = OpamPackage.Name.Map.add self.name self depends in
    make ~self ~ocaml_version scope
  | _ -> invalid_arg "build context must be an object"

let read_file ~ocaml_version ~path file =
  let json = Yojson.Basic.from_file file in
  read_json ~ocaml_version ~path json
