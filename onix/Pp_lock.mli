val pp_pkg : Format.formatter -> Lock_pkg.t -> unit

val pp : Format.formatter -> Lock_file.t -> unit
(** Pretty-printer for the nix lock file.

    [~ignore_file] is the optional file path to be used to filter root sources. *)
