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
  vars : Opam_utils.dep_vars;
  flags : string list;
}

val src_is_git : src -> bool
val src_is_http : src -> bool
val name : t -> OpamTypes.name

val of_opam :
  installed:(OpamPackage.Name.t -> bool) ->
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Opam_utils.opam_details ->
  t option
(** Create a lock package from an opam representation.

    [installed] is used to filter out optional dependencies not installed in the scope. *)
