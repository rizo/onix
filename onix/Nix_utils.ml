let get_nix_build_jobs () =
  try Unix.getenv "NIX_BUILD_CORES" with Not_found -> "1"
