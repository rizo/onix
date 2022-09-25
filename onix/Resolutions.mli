type t

val make : OpamFormula.atom list -> t
val constraints : t -> OpamFormula.version_constraint OpamTypes.name_map
val all : t -> OpamTypes.name list
val debug : t -> unit
val parse_resolution : string -> [`Ok of OpamFormula.atom | `Error of string]
val pp_resolution : Format.formatter -> OpamFormula.atom -> unit
