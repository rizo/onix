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
  scope : package OpamTypes.name_map;
  vars : OpamVariable.variable_contents OpamVariable.Full.Map.t;
}

val pp_package : Format.formatter -> package -> unit
val pp : Format.formatter -> t -> unit

module Vars : sig
  val base : OpamVariable.variable_contents OpamVariable.Full.Map.t
  (** Base variables consist of native system variables, global variables
      and nixos-specific variables. *)

  val resolve_dep_vars :
    ?build:bool ->
    ?post:bool ->
    ?test:bool ->
    ?doc:bool ->
    ?dev_setup:bool ->
    OpamFilter.env
  (** The opam filter env for resolving dependencies based on vars. *)

  val resolve_package : OpamPackage.t -> OpamFilter.env
  val resolve_from_stdenv : OpamFilter.env

  val resolve_from_static :
    OpamVariable.variable_contents OpamVariable.Full.Map.t -> OpamFilter.env

  val resolve_from_base : OpamFilter.env
  val try_resolvers : ('a -> 'b option) list -> 'a -> 'b option
end

val resolve :
  ?local:OpamVariable.variable_contents option OpamVariable.Map.t ->
  t ->
  OpamFilter.env

val basic_resolve :
  ?local:OpamVariable.variable_contents option OpamVariable.Map.t ->
  OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  OpamFilter.env
(** Resolve without build context for local, env and static vars. *)

val dependencies_of_onix_path :
  ocaml_version:string -> string -> package OpamPackage.Name.Map.t

val make :
  dependencies:package OpamPackage.Name.Map.t ->
  ?vars:OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  ocaml_version:string ->
  package ->
  t
