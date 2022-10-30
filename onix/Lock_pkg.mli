open Utils

type src =
  | Git of {
      url : string;
      rev : string;
    }
  | Http of {
      url : OpamUrl.t;
      hash : OpamHash.kind * string;
    }

type t = {
  src : src option;
  opam_details : Opam_utils.opam_details;
  depends : Name_set.t;
  depends_build : Name_set.t;
  depends_test : Name_set.t;
  depends_doc : Name_set.t;
  depends_dev_setup : Name_set.t;
  depexts_nix : String_set.t;
  depexts_unknown : String_set.t;
}

val name : t -> OpamTypes.name
val is_pinned : t -> bool
val is_root : t -> bool

val of_opam :
  installed:(OpamPackage.Name.t -> bool) ->
  with_test:Opam_utils.dep_flag_scope ->
  with_doc:Opam_utils.dep_flag_scope ->
  with_dev_setup:Opam_utils.dep_flag_scope ->
  Opam_utils.opam_details ->
  t option
(** Create a lock package from an opam representation.

    [installed] is used to filter out optional dependencies not installed in the scope. *)
