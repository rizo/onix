type pkg = {
  name : OpamTypes.name;
  version : OpamTypes.version;
  opamfile : string;
  opam : OpamFile.OPAM.t Lazy.t;
  prefix : string;
}

type t = {
  self : pkg;
  ocaml_version : OpamTypes.version;
  pkgs : pkg OpamTypes.name_map;
  vars : OpamVariable.variable_contents OpamVariable.Full.Map.t;
}

val make_pkg :
  name:OpamTypes.name ->
  version:OpamTypes.version ->
  opamfile:string ->
  prefix:string ->
  pkg

val make :
  deps:pkg OpamPackage.Name.Map.t ->
  ?vars:OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  ocaml_version:OpamPackage.Version.t ->
  pkg ->
  t

val with_onix_path :
  onix_path:string ->
  ?vars:OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  ocaml_version:OpamPackage.Version.t ->
  pkg ->
  t

(* val get_opam : OpamPackage.Name.t -> t -> OpamFile.OPAM.t option *)

(** {2 Variable resolvers} *)

val resolve_global :
  ?system:System.t ->
  ?jobs:string ->
  ?user:string ->
  ?group:string ->
  OpamFilter.env
(** Resolve global generic system variables. *)

val resolve_global_host : OpamFilter.env
(** Resolve global host system variables. *)

val resolve_pkg : build_dir:string -> t -> OpamFilter.env
(** Resolves [name], [version] and [dev] vars. *)

val resolve_opam_pkg : OpamPackage.t -> OpamFilter.env
(** Resolves [name], [version] and [dev] vars. *)

val resolve_stdenv_host : OpamFilter.env
(** Resolves opam variables from host's enviroonment variables. *)

val resolve_config : t -> OpamFilter.env
(** Resolves the variables from config file. *)

val resolve_local :
  OpamVariable.variable_contents option OpamVariable.Map.t -> OpamFilter.env
(** Resolves from a local variable map.. *)

val resolve_dep :
  ?build:bool ->
  ?post:bool ->
  ?test:bool ->
  ?doc:bool ->
  ?dev_setup:bool ->
  OpamFilter.env
(** Resolve dependency variables. *)

val resolve_many : OpamFilter.env list -> OpamFilter.env
(* Resolves using a provided list of resolvers. *)
