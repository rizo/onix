val collect_from_opam_files :
  Opam_utils.opam_details OpamTypes.name_map ->
  Opam_utils.opam_details OpamTypes.name_map
(** Given all root packages find their pins. *)
