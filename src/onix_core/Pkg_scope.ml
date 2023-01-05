open Utils

open struct
  let string = OpamVariable.string
  let bool = OpamVariable.bool
  let string' x = Some (OpamVariable.string x)
  let bool' x = Some (OpamVariable.bool x)
end

type package = {
  name : OpamPackage.Name.t;
  version : OpamPackage.Version.t;
  opamfile : string;
  prefix : string;
}

type t = {
  self : package;
  ocaml_version : OpamPackage.Version.t;
  pkgs : package OpamPackage.Name.Map.t;
  vars : OpamTypes.variable_contents OpamVariable.Full.Map.t;
}

(* FIXME: Use Paths *)
let package_of_nix_store_path ~ocaml_version ~onix_pkg_dir
    (store_path : Nix_utils.store_path) =
  let package_name = OpamPackage.Name.to_string store_path.package_name in
  {
    name = store_path.package_name;
    version = store_path.package_version;
    prefix = OpamFilename.Dir.to_string store_path.prefix;
    (* FIXME: This is not the opam file from the repo. *)
    opamfile =
      OpamFilename.Op.(
        onix_pkg_dir
        / "lib"
        / "ocaml"
        / OpamPackage.Version.to_string ocaml_version
        / "site-lib"
        / package_name
        // "opam")
      |> OpamFilename.to_string;
  }

let dependencies_of_onix_path ~ocaml_version onix_path =
  if String.length onix_path = 0 then OpamPackage.Name.Map.empty
  else
    let onix_pkg_dirs = String.split_on_char ':' onix_path in
    List.fold_left
      (fun acc onix_pkg_dir ->
        let onix_pkg_dir = OpamFilename.Dir.of_string onix_pkg_dir in
        let store_path = Nix_utils.parse_store_path onix_pkg_dir in
        let pkg =
          package_of_nix_store_path ~ocaml_version ~onix_pkg_dir store_path
        in
        OpamPackage.Name.Map.add store_path.package_name pkg acc)
      OpamPackage.Name.Map.empty onix_pkg_dirs

let resolve_global ?jobs ?arch ?os ?user ?group full_var =
  if OpamVariable.Full.(scope full_var <> Global) then None
  else
    let var = OpamVariable.Full.variable full_var in
    match OpamVariable.to_string var with
    (* Static *)
    | "opam-version" -> string' OpamVersion.(to_string current)
    | "root" -> string' "/tmp/onix-opam-root"
    | "make" -> string' "make"
    | "os-distribution" -> string' "homebrew"
    | "os-family" -> string' "nixos"
    | "os-version" -> string' "unknown"
    (* Dynamic *)
    | "jobs" -> Option.map string jobs
    | "arch" -> Option.map string arch
    | "os" -> Option.map string os
    | "user" -> Option.map string user
    | "group" -> Option.map string group
    | _ -> None

let resolve_global_host =
  let jobs = Nix_utils.get_nix_build_jobs () in
  let arch = OpamSysPoll.arch () in
  let os = OpamSysPoll.os () in
  let user = Unix.getlogin () in
  let group = Utils.Os.get_group () in
  resolve_global ~jobs ?arch ?os ~user ?group

let resolve_pkg ~build_dir { self; pkgs; ocaml_version; _ } full_var =
  let var = OpamVariable.to_string (OpamVariable.Full.variable full_var) in
  let scope =
    match OpamVariable.Full.scope full_var with
    | Global -> `Global
    | Self -> `Installed self
    | Package name -> (
      match OpamPackage.Name.Map.find_opt name pkgs with
      | Some pkg -> `Installed pkg
      | None -> `Missing name)
  in
  match (scope, var) with
  | `Global, "name" -> string' (OpamPackage.Name.to_string self.name)
  | `Installed pkg, "name" -> string' (OpamPackage.Name.to_string pkg.name)
  | `Missing name, "name" -> string' (OpamPackage.Name.to_string name)
  | `Global, "version" -> string' (OpamPackage.Version.to_string self.version)
  | `Installed pkg, "version" ->
    string' (OpamPackage.Version.to_string pkg.version)
  | _, "depends" -> None
  | `Global, "installed" -> bool' false (* not yet *)
  | `Installed _pkg, "installed" -> bool' true
  | `Missing _name, "installed" -> bool' false
  | `Installed _pkg, "enable" -> string' "enable"
  | `Missing _name, "enable" -> string' "disable"
  | `Global, ("pinned" | "dev") ->
    bool' (Opam_utils.is_pinned_version self.version)
  | `Installed pkg, ("pinned" | "dev") ->
    bool' (Opam_utils.is_pinned_version pkg.version)
  (* FIXME: Does not work for drv generator. *)
  (* | "build", `Global -> string' (Sys.getcwd ()) *)
  | `Global, "build" -> string' build_dir
  (* | "<pkgname>:hash" -> None *)
  | `Global, "build-id" -> string' self.prefix
  | `Global, "opamfile" -> string' self.opamfile
  | `Installed pkg, "opamfile" -> string' pkg.opamfile (* OCaml package *)
  (* Paths *)
  | `Global, "switch" | `Global, "prefix" -> string' self.prefix
  | `Global, "lib" -> string' (Paths.lib ~ocaml_version self.prefix)
  | `Installed pkg, "lib" ->
    string' (Paths.lib ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `Global, "toplevel" -> string' (Paths.toplevel ~ocaml_version self.prefix)
  | `Installed pkg, "toplevel" ->
    string' (Paths.toplevel ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `Global, "stublibs" -> string' (Paths.stublibs ~ocaml_version self.prefix)
  | `Installed pkg, "stublibs" ->
    string' (Paths.stublibs ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `Global, "bin" -> string' (Paths.bin self.prefix)
  | `Installed pkg, "bin" -> string' (Paths.bin ~pkg_name:pkg.name pkg.prefix)
  | `Global, "sbin" -> string' (Paths.sbin self.prefix)
  | `Installed pkg, "sbin" -> string' (Paths.sbin ~pkg_name:pkg.name pkg.prefix)
  | `Global, "share" -> string' (Paths.share self.prefix)
  | `Installed pkg, "share" ->
    string' (Paths.share ~pkg_name:pkg.name pkg.prefix)
  | `Global, "doc" -> string' (Paths.doc self.prefix)
  | `Installed pkg, "doc" -> string' (Paths.doc ~pkg_name:pkg.name pkg.prefix)
  | `Global, "etc" -> string' (Paths.etc self.prefix)
  | `Installed pkg, "etc" -> string' (Paths.etc ~pkg_name:pkg.name pkg.prefix)
  | `Global, "man" -> string' (Paths.man self.prefix)
  | `Installed pkg, "man" -> string' (Paths.man pkg.prefix)
  (* OCaml variables *)
  | ( `Installed pkg,
      ("preinstalled" | "native" | "native-tools" | "native-dynlink") )
    when Opam_utils.is_ocaml_compiler_name pkg.name -> bool' true
  | `Global, "sys-ocaml-version" ->
    string' (OpamPackage.Version.to_string ocaml_version)
  | _ -> None

let resolve_opam_pkg pkg full_var =
  match OpamVariable.Full.to_string full_var with
  | "name" -> string' (OpamPackage.name_to_string pkg)
  | "version" -> string' (OpamPackage.version_to_string pkg)
  | "dev" | "pinned" -> bool' (Opam_utils.is_pinned pkg)
  | _ -> None

let resolve_dep ?(build = true) ?post ?(test = false) ?(doc = false)
    ?(dev_setup = false) var =
  match OpamVariable.Full.to_string var with
  | "build" -> bool' build
  | "post" -> Option.map bool post
  | "with-test" -> bool' test
  | "with-doc" -> bool' doc
  | "with-dev-setup" -> bool' dev_setup
  | _ -> None

let resolve_stdenv_host = OpamVariable.Full.read_from_env

let resolve_config { self; pkgs; _ } full_var =
  let ( </> ) = OpamFilename.Op.( / ) in
  let resolve_for_package pkg var =
    let base =
      OpamFilename.Base.of_string
        (OpamPackage.Name.to_string pkg.name ^ ".config")
    in
    let config_filename =
      OpamFilename.create (OpamFilename.Dir.of_string pkg.prefix </> "etc") base
    in
    if OpamFilename.exists config_filename then (
      Logs.debug (fun log ->
          log "Pkg_ctx.resolve_from_config: loading %a..."
            Opam_utils.pp_filename config_filename);
      let config_file = OpamFile.make config_filename in
      let config = OpamFile.Dot_config.read config_file in
      OpamFile.Dot_config.variable config var)
    else None
  in
  match OpamVariable.Full.(scope full_var, variable full_var) with
  | Global, _var -> None
  | Self, var -> resolve_for_package self var
  | Package pkg_name, var -> (
    match OpamPackage.Name.Map.find_opt pkg_name pkgs with
    | Some pkg -> resolve_for_package pkg var
    | None -> None)

let resolve_local local_vars full_var =
  match OpamVariable.Full.package full_var with
  | Some _ -> None
  | None -> (
    let var = OpamVariable.Full.variable full_var in
    try
      match OpamVariable.Map.find var local_vars with
      | None -> raise Exit (* Variable explicitly undefined *)
      | some -> some
    with Not_found -> None)

let resolve_many resolvers full_var =
  let rec loop resolvers =
    match resolvers with
    | [] -> None
    | resolver :: resolvers' ->
      let contents = resolver full_var in
      if Option.is_some contents then contents else loop resolvers'
  in
  try loop resolvers with Exit -> None

let make ~deps ?(vars = OpamVariable.Full.Map.empty) ~ocaml_version self =
  let pkgs = OpamPackage.Name.Map.add self.name self deps in
  { self; ocaml_version; pkgs; vars }
