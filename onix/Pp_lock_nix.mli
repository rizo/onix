val pp_pkg : ignore_file:string option -> Format.formatter -> Lock_pkg.t -> unit

val pp : ignore_file:string option -> Format.formatter -> Lock_file.t -> unit
(** Pretty-printer for the nix lock file.

    [~ignore_file] is the optional file path to be used to filter root sources. *)
