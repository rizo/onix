val solve :
  ?resolutions:OpamFormula.atom list ->
  repos:string list ->
  with_test:Opam_utils.dep_flag_scope ->
  with_doc:Opam_utils.dep_flag_scope ->
  with_dev_setup:Opam_utils.dep_flag_scope ->
  string list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
