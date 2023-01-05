val pp_pkg : Format.formatter -> Onix_core.Lock_pkg.t -> unit

val pp : Format.formatter -> Onix_core.Lock_file.t -> unit
(** Pretty-printer for the nix lock file.

    [~ignore_file] is the optional file path to be used to filter root sources. *)
