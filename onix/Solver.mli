val solve :
  repo_url:string ->
  with_test:bool ->
  with_doc:bool ->
  with_tools:bool ->
  string list ->
  Lock_file.t
(** Find a package solution for provided root opam files given repo URL. *)
