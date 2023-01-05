module Name = OpamPackage.Name
module Version = OpamPackage.Version
module Var = OpamVariable

let is_pinned_version = Opam_utils.is_pinned_version

open Utils

type pkg = {
  name : Name.t;
  version : Version.t;
  opamfile : string;
  opam : OpamFile.OPAM.t Lazy.t;
  prefix : string;
}

type t = {
  self : pkg;
  ocaml_version : Version.t;
  pkgs : pkg Name_map.t;
  vars : OpamTypes.variable_contents Var.Full.Map.t;
}

let make_pkg ~name ~version ~opamfile ~prefix =
  let opam =
    lazy OpamFile.(OPAM.(read (make (OpamFilename.of_string opamfile))))
  in
  { name; version; opamfile; opam; prefix }

let make ~deps ?(vars = Var.Full.Map.empty) ~ocaml_version self =
  let pkgs = Name_map.add self.name self deps in
  { self; ocaml_version; pkgs; vars }

let deps_of_onix_path ~ocaml_version onix_path =
  if String.length onix_path = 0 then Name_map.empty
  else
    let onix_pkg_dirs = String.split_on_char ':' onix_path in
    List.fold_left
      (fun acc onix_pkg_dir ->
        let { Nix_utils.pkg_name; pkg_version; prefix; _ } =
          Nix_utils.parse_store_path onix_pkg_dir
        in
        let name = Name.of_string pkg_name in
        let version = Version.of_string pkg_version in
        (* This is the installed opam file and not the one from repo. *)
        let opamfile =
          Paths.lib ~pkg_name:name ~ocaml_version onix_pkg_dir ^ "/opam"
        in
        let pkg = make_pkg ~name ~version ~opamfile ~prefix in
        Name_map.add name pkg acc)
      Name_map.empty onix_pkg_dirs

let with_onix_path ~onix_path ?vars ~ocaml_version self =
  let deps = deps_of_onix_path ~ocaml_version onix_path in
  make ~deps ?vars ~ocaml_version self

(* let get_opam name scope =
   match Name_map.find_opt name scope.pkgs with
   | None -> None
   | Some pkg -> Some (Lazy.force pkg.opam) *)

(* Variable resolvers *)

open struct
  let string = Var.string
  let bool = Var.bool
  let string' x = Some (Var.string x)
  let bool' x = Some (Var.bool x)
end

let resolve_global ?jobs ?arch ?os ?user ?group full_var =
  if Var.Full.(scope full_var <> Global) then None
  else
    let var = Var.Full.variable full_var in
    match Var.to_string var with
    (* Static *)
    | "opam-version" -> string' OpamVersion.(to_string current)
    | "root" -> string' "/tmp/onix-opam-root"
    | "make" -> string' "make"
    | "os-distribution" -> string' "nixos"
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
  let var = Var.to_string (Var.Full.variable full_var) in
  let scope =
    (* G=Global, I=Installed, M=Missing*)
    match Var.Full.scope full_var with
    | Global -> `G
    | Self -> `I self
    | Package name -> (
      match Name_map.find_opt name pkgs with
      | Some pkg -> `I pkg
      | None -> `M name)
  in
  let open Paths in
  match (scope, var) with
  (* Package metadata *)
  | `G, "name" -> string' (Name.to_string self.name)
  | `I pkg, "name" -> string' (Name.to_string pkg.name)
  | `M name, "name" -> string' (Name.to_string name)
  | `G, "version" -> string' (Version.to_string self.version)
  | `I pkg, "version" -> string' (Version.to_string pkg.version)
  | `G, ("pinned" | "dev") -> bool' (is_pinned_version self.version)
  | `I pkg, ("pinned" | "dev") -> bool' (is_pinned_version pkg.version)
  | `G, "opamfile" -> string' self.opamfile
  | `I pkg, "opamfile" -> string' pkg.opamfile
  (* Installed/enable *)
  | `G, "installed" -> bool' false (* not yet *)
  | `I _pkg, "installed" -> bool' true
  | `M _name, "installed" -> bool' false
  | `I _pkg, "enable" -> string' "enable"
  | `M _name, "enable" -> string' "disable"
  (* Build info *)
  | `G, "build" -> string' build_dir
  | `G, "build-id" -> string' self.prefix
  | _, "depends" -> None
  (* | "<pkgname>:hash" -> None *)
  (* Paths *)
  | `G, "switch" | `G, "prefix" -> string' self.prefix
  | `G, "lib" -> string' (lib ~ocaml_version self.prefix)
  | `I pkg, "lib" -> string' (lib ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `G, "toplevel" -> string' (toplevel ~ocaml_version self.prefix)
  | `I pkg, "toplevel" ->
    string' (toplevel ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `G, "stublibs" -> string' (stublibs ~ocaml_version self.prefix)
  | `I pkg, "stublibs" ->
    string' (stublibs ~pkg_name:pkg.name ~ocaml_version pkg.prefix)
  | `G, "bin" -> string' (bin self.prefix)
  | `I pkg, "bin" -> string' (bin ~pkg_name:pkg.name pkg.prefix)
  | `G, "sbin" -> string' (sbin self.prefix)
  | `I pkg, "sbin" -> string' (sbin ~pkg_name:pkg.name pkg.prefix)
  | `G, "share" -> string' (share self.prefix)
  | `I pkg, "share" -> string' (share ~pkg_name:pkg.name pkg.prefix)
  | `G, "doc" -> string' (doc self.prefix)
  | `I pkg, "doc" -> string' (doc ~pkg_name:pkg.name pkg.prefix)
  | `G, "etc" -> string' (etc self.prefix)
  | `I pkg, "etc" -> string' (etc ~pkg_name:pkg.name pkg.prefix)
  | `G, "man" -> string' (man self.prefix)
  | `I pkg, "man" -> string' (man pkg.prefix)
  (* OCaml package variables *)
  | ( (`I { name; _ } | `M name),
      ("preinstalled" | "native" | "native-tools" | "native-dynlink") )
    when Opam_utils.is_ocaml_name name -> bool' true
  | `G, "sys-ocaml-version" -> string' (Version.to_string ocaml_version)
  | _ -> None

let resolve_opam_pkg pkg full_var =
  match Var.Full.to_string full_var with
  | "name" -> string' (OpamPackage.name_to_string pkg)
  | "version" -> string' (OpamPackage.version_to_string pkg)
  | "dev" | "pinned" -> bool' (Opam_utils.is_pinned pkg)
  | _ -> None

let resolve_dep ?(build = true) ?(post = false) ?(test = false) ?(doc = false)
    ?(dev_setup = false) var =
  match Var.Full.to_string var with
  | "build" -> bool' build
  | "post" -> bool' post
  | "with-test" -> bool' test
  | "with-doc" -> bool' doc
  | "with-dev-setup" -> bool' dev_setup
  | _ -> None

let resolve_stdenv_host = Var.Full.read_from_env

let resolve_config { self; pkgs; _ } full_var =
  let ( </> ) = OpamFilename.Op.( / ) in
  let resolve_for_package pkg var =
    let base =
      OpamFilename.Base.of_string (Name.to_string pkg.name ^ ".config")
    in
    let config_filename =
      OpamFilename.create (OpamFilename.Dir.of_string pkg.prefix </> "etc") base
    in
    if OpamFilename.exists config_filename then (
      Logs.debug (fun log ->
          log "Scope.resolve_from_config: loading %a..." Opam_utils.pp_filename
            config_filename);
      let config_file = OpamFile.make config_filename in
      let config = OpamFile.Dot_config.read config_file in
      OpamFile.Dot_config.variable config var)
    else None
  in
  match Var.Full.(scope full_var, variable full_var) with
  | Global, _var -> None
  | Self, var -> resolve_for_package self var
  | Package pkg_name, var -> (
    match Name_map.find_opt pkg_name pkgs with
    | Some pkg -> resolve_for_package pkg var
    | None -> None)

let resolve_local local_vars full_var =
  match Var.Full.package full_var with
  | Some _ -> None
  | None -> (
    let var = Var.Full.variable full_var in
    try
      match Var.Map.find var local_vars with
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
