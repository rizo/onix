val resolve_repo : string -> OpamFilename.Dir.t * OpamUrl.t

val solve :
  repo_url:string ->
  compiler:Opam_utils.compiler_type ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_tools:Opam_utils.dep_flag ->
  string list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
