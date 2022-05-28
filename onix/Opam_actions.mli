val patch : ocaml_version:string -> opam:string -> string -> unit

val build :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.flag_scope ->
  with_doc:Opam_utils.flag_scope ->
  with_tools:Opam_utils.flag_scope ->
  string ->
  unit

val install :
  ocaml_version:string ->
  opam:string ->
  with_test:Opam_utils.flag_scope ->
  with_doc:Opam_utils.flag_scope ->
  with_tools:Opam_utils.flag_scope ->
  string ->
  unit
