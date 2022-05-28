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

let pp_package formatter package =
  let field = Fmt.Dump.field in
  Fmt.pf formatter "%a"
    (Fmt.Dump.record
       [
         field "name" (fun r -> r.name) Opam_utils.pp_package_name;
         field "version" (fun r -> r.version) Opam_utils.pp_package_version;
         field "opam" (fun r -> r.opam) Opam_utils.pp_filename;
         field "path" (fun r -> r.path) Opam_utils.pp_filename_dir;
       ])
    package

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

  let base =
    OpamVariable.Full.Map.empty
    |> add_native_system_vars
    |> add_global_vars
    |> add_nixos_vars

  let resolve_dep_flags ?(build = true) ?(post = false) ?(test = false)
      ?(doc = false) ?(tools = false) var =
    let bool x = Some (OpamVariable.bool x) in
    match OpamVariable.Full.to_string var with
    | "build" -> bool build
    | "post" -> bool post
    | "with-test" -> bool test
    | "with-doc" -> bool doc
    | "with-tools" -> bool tools
    | _ -> None

  let resolve_package pkg v =
    let string x = Some (OpamVariable.string x) in
    let bool x = Some (OpamVariable.bool x) in
    match OpamVariable.Full.to_string v with
    | "name" -> string (OpamPackage.name_to_string pkg)
    | "version" -> string (OpamPackage.version_to_string pkg)
    | "dev" -> bool (Opam_utils.is_pinned pkg)
    | _ -> None

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
      | Self -> `Installed t.self
      | Package pkg_name -> (
        match OpamPackage.Name.Map.find_opt pkg_name t.scope with
        | Some pkg -> `Installed pkg
        | None -> `Missing pkg_name)
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
    | "installed", `Installed _ -> bool true
    | "installed", `Missing _ -> bool false
    | "pinned", `Global -> bool (Opam_utils.is_pinned_version t.self.version)
    | "pinned", `Installed pkg ->
      bool (Opam_utils.is_pinned_version pkg.version)
    | "pinned", `Missing _ -> bool false
    | "name", `Global -> string (OpamPackage.Name.to_string t.self.name)
    | "name", `Installed pkg -> string (OpamPackage.Name.to_string pkg.name)
    | "name", `Missing pkg_name -> string (OpamPackage.Name.to_string pkg_name)
    | "build", `Global -> string (Sys.getcwd ())
    | "dev", _ -> bool false
    | "version", `Global ->
      string (OpamPackage.Version.to_string t.self.version)
    | "version", `Installed pkg ->
      string (OpamPackage.Version.to_string pkg.version)
    | "build-id", `Global -> string (OpamFilename.Dir.to_string t.self.path)
    | "build-id", `Installed pkg -> string (OpamFilename.Dir.to_string pkg.path)
    | "opamfile", `Global -> string (OpamFilename.to_string t.self.opam)
    | "opamfile", `Installed pkg -> string (OpamFilename.to_string pkg.opam)
    | "depends", _ | "hash", _ -> string ("ONIX_NOT_IMPLEMENTED_" ^ v)
    (* site-lib paths *)
    | "lib", `Global -> lib None
    | "lib", `Installed pkg -> lib (Some pkg)
    | "stublibs", `Global -> lib ~suffix:v None
    | "stublibs", `Installed pkg -> lib ~suffix:v (Some pkg)
    | "toplevel", `Global -> lib ~suffix:v None
    | "toplevel", `Installed pkg -> lib ~suffix:v (Some pkg)
    (* base paths *)
    | "bin", `Global
    | "bin", `Installed _
    | "sbin", `Global
    | "sbin", `Installed _ -> out ~suffix:v None ~scoped:false
    | "man", `Global -> out ~suffix:v None ~scoped:false
    | "man", `Installed pkg -> out ~suffix:v (Some pkg) ~scoped:false
    | "doc", `Global -> out ~suffix:v None ~scoped:false
    | "doc", `Installed pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | "share", `Global -> out ~suffix:v None ~scoped:false
    | "share", `Installed pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | "etc", `Global -> out ~suffix:v None ~scoped:true
    | "etc", `Installed pkg -> out ~suffix:v (Some pkg) ~scoped:true
    | _ -> None

  let resolve_from_stdenv full_var = OpamVariable.Full.read_from_env full_var

  let resolve_from_config_env t full_var =
    let ( </> ) = OpamFilename.Op.( / ) in
    let resolve_for_package pkg var =
      let base =
        OpamFilename.Base.of_string
          (OpamPackage.Name.to_string pkg.name ^ ".config")
      in
      let config_filename = OpamFilename.create (pkg.path </> "etc") base in
      if OpamFilename.exists config_filename then (
        Logs.debug (fun log ->
            log "Build_context.resolve_from_etc_env: loading %a..."
              Opam_utils.pp_filename config_filename);
        let config_file = OpamFile.make config_filename in
        let config = OpamFile.Dot_config.read config_file in
        OpamFile.Dot_config.variable config var)
      else None
    in
    match OpamVariable.Full.(scope full_var, variable full_var) with
    | Global, _var -> None
    | Self, var -> resolve_for_package t.self var
    | Package pkg_name, var -> (
      match OpamPackage.Name.Map.find_opt pkg_name t.scope with
      | Some pkg -> resolve_for_package pkg var
      | None -> None)

  let resolve_from_static vars full_var =
    OpamVariable.Full.Map.find_opt full_var vars

  let resolve_from_base = resolve_from_static base

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

let basic_resolve ?(local = OpamVariable.Map.empty) vars full_var =
  let contents =
    Vars.try_resolvers
      [
        Vars.resolve_from_local local;
        Vars.resolve_from_stdenv;
        Vars.resolve_from_static vars;
      ]
      full_var
  in
  Opam_utils.debug_var ~scope:"basic_resovle" full_var contents;
  contents

let resolve ?(local = OpamVariable.Map.empty) t full_var =
  let contents =
    Vars.try_resolvers
      [
        Vars.resolve_from_local local;
        Vars.resolve_from_stdenv;
        Vars.resolve_from_config_env t;
        Vars.resolve_from_static t.vars;
        Vars.resolve_from_global_scope t;
        Vars.resolve_from_scope t;
      ]
      full_var
  in
  Opam_utils.debug_var ~scope:"resolve" full_var contents;
  contents

let package_of_nix_store_path ~libdir (store_path : Nix_utils.store_path) =
  let package_name = OpamPackage.Name.to_string store_path.package_name in
  {
    name = store_path.package_name;
    version = store_path.package_version;
    path = store_path.prefix;
    (* FIXME: This is not the opam file from the repo. *)
    opam = OpamFilename.Op.(libdir / package_name // "opam");
  }

let make ?(ocamlpath = Sys.getenv_opt "OCAMLPATH" or "") ?(vars = Vars.base)
    ~ocaml_version ~opam path =
  Logs.debug (fun log -> log "Build_context.make: OCAMLPATH=%s" ocamlpath);
  let deps =
    if String.length ocamlpath = 0 then OpamPackage.Name.Map.empty
    else
      let ocaml_libdirs = String.split_on_char ':' ocamlpath in
      List.fold_left
        (fun acc libdir ->
          let libdir = OpamFilename.Dir.of_string libdir in
          let store_path = Nix_utils.parse_store_path libdir in
          let pkg = package_of_nix_store_path ~libdir store_path in
          OpamPackage.Name.Map.add store_path.package_name pkg acc)
        OpamPackage.Name.Map.empty ocaml_libdirs
  in
  let self =
    let path = OpamFilename.Dir.of_string path in
    let opam = OpamFilename.of_string opam in
    let store_path = Nix_utils.parse_store_path path in
    {
      name = store_path.package_name;
      version = store_path.package_version;
      path;
      opam;
    }
  in
  let scope = OpamPackage.Name.Map.add self.name self deps in
  let ocaml_version = OpamPackage.Version.of_string ocaml_version in
  { self; ocaml_version; vars; scope }
