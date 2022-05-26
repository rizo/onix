type src
type t

val name : t -> OpamTypes.name
val is_pinned : t -> bool
val is_root : t -> bool
val pp : gitignore:bool -> Format.formatter -> t -> unit
val pp_name : Format.formatter -> OpamTypes.name -> unit

val of_opam :
  ?with_build:bool ->
  ?with_test:bool ->
  ?with_doc:bool ->
  OpamPackage.t ->
  OpamFile.OPAM.t ->
  t option
