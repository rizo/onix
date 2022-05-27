type t

val make :
  ?prefer_oldest:bool ->
  ?fixed_packages:(OpamTypes.version * OpamFile.OPAM.t) OpamTypes.name_map ->
  constraints:OpamFormula.version_constraint OpamTypes.name_map ->
  with_test:bool->
  with_doc:bool->
  with_tools:bool->
  OpamTypes.dirname ->
  t

(* Input solver context for Opam_0install.Solver.Make. *)
include Opam_0install.S.CONTEXT with type t := t

val get_opam_file : t -> OpamPackage.t -> OpamFile.OPAM.t
