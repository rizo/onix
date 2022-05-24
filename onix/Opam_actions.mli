val patch : ocaml_version:string -> opam:string -> string -> unit

val build :
  ?test:bool ->
  ?doc:bool ->
  ?tools:bool ->
  ocaml_version:string ->
  opam:string ->
  string ->
  unit

val install :
  ?test:bool ->
  ?doc:bool ->
  ?tools:bool ->
  ocaml_version:string ->
  opam:string ->
  string ->
  unit
