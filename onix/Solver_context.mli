type t

val make :
  ?prefer_oldest:bool ->
  ?fixed_opam_details:Opam_utils.opam_details OpamTypes.name_map ->
  constraints:OpamFormula.version_constraint OpamTypes.name_map ->
  with_test:Opam_utils.dep_flag_scope ->
  with_doc:Opam_utils.dep_flag_scope ->
  with_dev_setup:Opam_utils.dep_flag_scope ->
  OpamTypes.dirname ->
  t

(* Input solver context for Opam_0install.Solver.Make. *)
include Opam_0install.S.CONTEXT with type t := t

val get_opam_file : t -> OpamPackage.t -> OpamFile.OPAM.t
