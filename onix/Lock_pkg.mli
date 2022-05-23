type src
type t

val name : t -> OpamTypes.name
val is_pinned : t -> bool
val is_root : t -> bool
val pp : Format.formatter -> t -> unit
val pp_name : Format.formatter -> OpamTypes.name -> unit

val of_opam :
  ?test:bool -> ?doc:bool -> OpamPackage.t -> OpamFile.OPAM.t -> t option
