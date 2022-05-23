type t = {
  repo_url : OpamUrl.t;
  packages : Lock_pkg.t list;
}

val make : repo_url:OpamUrl.t -> Lock_pkg.t list -> t
val pp : Format.formatter -> t -> unit
