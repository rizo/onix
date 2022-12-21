val solve :
  ?resolutions:OpamFormula.atom list ->
  repository_urls:OpamUrl.t list ->
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  OpamFilename.t list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
