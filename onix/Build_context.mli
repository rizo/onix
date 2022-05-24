type package = {
  name : OpamTypes.name;
  version : OpamTypes.version;
  opam : OpamFilename.t;
  path : OpamTypes.dirname;
}

type t = {
  self : package;
  ocaml_version : OpamTypes.version;
  scope : package OpamTypes.name_map;
  vars : OpamVariable.variable_contents OpamVariable.Full.Map.t;
}

val pp_package : Format.formatter -> package -> unit

module Vars : sig
  val default : OpamVariable.variable_contents OpamVariable.Full.Map.t
  val nixos : OpamVariable.variable_contents OpamVariable.Full.Map.t

  val resolve_from_env :
    OpamTypes.full_variable -> OpamVariable.variable_contents option

  val resolve_from_static :
    'a OpamVariable.Full.Map.t -> OpamTypes.full_variable -> 'a option

  val try_resolvers : ('a -> 'b option) list -> 'a -> 'b option
end

val resolve :
  t ->
  ?local:OpamVariable.variable_contents option OpamVariable.Map.t ->
  OpamTypes.full_variable ->
  OpamVariable.variable_contents option

val make :
  ?ocamlpath:string ->
  ?vars:OpamVariable.variable_contents OpamVariable.Full.Map.t ->
  ocaml_version:string ->
  opam:string ->
  string ->
  t
(* [make ?vars ~ocaml_version path] creates a build context for a package
   located at a nix store path [path] with opam file located at [opam]. *)
