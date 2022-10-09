type src
type t

val name : t -> OpamTypes.name
val is_pinned : t -> bool
val is_root : t -> bool
val pp : ignore_file:string option -> Format.formatter -> t -> unit
val pp_name : Format.formatter -> OpamTypes.name -> unit

val of_opam :
  installed:(OpamPackage.Name.t -> bool) ->
  with_test:Opam_utils.dep_flag ->
  with_doc:Opam_utils.dep_flag ->
  with_tools:Opam_utils.dep_flag ->
  OpamPackage.t ->
  OpamFile.OPAM.t ->
  t option
(** Create a lock package from an opam representation.

    [installed] is used to filter out optional dependencies not installed in the scope. *)

