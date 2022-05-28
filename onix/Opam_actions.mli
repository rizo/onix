val patch : ocaml_version:string -> opam:string -> string -> unit

val build :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_tools:Opam_utils.dep_flag ->
  string ->
  unit

val install :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_tools:Opam_utils.dep_flag ->
  string ->
  unit
