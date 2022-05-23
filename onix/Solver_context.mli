type t

val std_env :
  ?ocaml_native:bool ->
  ?sys_ocaml_version:string ->
  ?opam_version:string ->
  arch:string ->
  os:string ->
  os_distribution:string ->
  os_family:string ->
  os_version:string ->
  unit ->
  string ->
  OpamVariable.variable_contents option

val make :
  ?prefer_oldest:bool ->
  ?test:OpamTypes.name_set ->
  ?fixed_packages:(OpamTypes.version * OpamFile.OPAM.t) OpamTypes.name_map ->
  constraints:OpamFormula.version_constraint OpamTypes.name_map ->
  env:(string -> OpamVariable.variable_contents option) ->
  OpamTypes.dirname ->
  t

(* Input solver context for Opam_0install.Solver.Make. *)
include Opam_0install.S.CONTEXT with type t := t

val get_opam_file : t -> OpamPackage.t -> OpamFile.OPAM.t
