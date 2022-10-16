val collect_from_opam_files :
  (_ * _ * OpamFile.OPAM.t) OpamTypes.name_map ->
  (OpamTypes.version * Opam_utils.opam_file_type * OpamFile.OPAM.t)
  OpamTypes.name_map
