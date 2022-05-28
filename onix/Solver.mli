val solve :
  repo_url:string ->
  with_test:Opam_utils.flag_scope ->
  with_doc:Opam_utils.flag_scope ->
  with_tools:Opam_utils.flag_scope ->
  string list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
