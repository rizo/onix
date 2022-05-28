type t = {
  repo_url : OpamUrl.t;
  packages : Lock_pkg.t list;
}

val make : repo_url:OpamUrl.t -> Lock_pkg.t list -> t

val pp : ignore_file:string option -> Format.formatter -> t -> unit
(** Pretty-printer for the nix lock file.

    [~ignore_file] is the optional file path to be used to filter root sources. *)
