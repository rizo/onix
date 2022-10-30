type t = {
  repo : OpamUrl.t;
  packages : Lock_pkg.t list;
}

val make : repo_url:OpamUrl.t -> Lock_pkg.t list -> t
