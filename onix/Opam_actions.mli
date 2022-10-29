val patch : ocaml_version:string -> opam:string -> path:string -> string -> unit

val build :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_dev_setup:Opam_utils.dep_flag ->
  path:string ->
  string ->
  unit

val install :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_dev_setup:Opam_utils.dep_flag ->
  path:string ->
  string ->
  unit
