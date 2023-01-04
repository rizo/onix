(* Build context defines the build environment for a package.
   This can be seen as a sandboxed opam switch. *)

type package = {
  name : OpamTypes.name;
  version : OpamTypes.version;
  opamfile : string;
  prefix : string;
}

type t = {
  self : package;
  ocaml_version : OpamTypes.version;
  pkgs : package OpamTypes.name_map;
  vars : OpamVariable.variable_contents OpamVariable.Full.Map.t;
}

(** {2 Variable resolvers} *)

val resolve_global :
  ?jobs:string ->
  ?arch:string ->
  ?os:string ->
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

val resolve_stdenv : OpamFilter.env
(** Resolves opam variables from enviroonment variables. *)

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

(* val resolve_all : *)
(*   ?local:OpamVariable.variable_contents option OpamVariable.Map.t -> *)
(*   t -> *)
(*   OpamFilter.env *)

val dependencies_of_onix_path :
  ocaml_version:string -> string -> package OpamPackage.Name.Map.t

val make :
  deps:package OpamPackage.Name.Map.t ->
  ?vars:OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  ocaml_version:string ->
  package ->
  t
