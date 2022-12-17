val solve :
  ?resolutions:OpamFormula.atom list ->
  repository_urls:OpamUrl.t list ->
  with_test:Opam_utils.dep_flag_scope ->
  with_doc:Opam_utils.dep_flag_scope ->
  with_dev_setup:Opam_utils.dep_flag_scope ->
  OpamFilename.t list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
