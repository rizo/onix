type t = {
  repository_urls : OpamUrl.t list;
  packages : Lock_pkg.t list;
}

val make : repository_urls:OpamUrl.t list -> Lock_pkg.t list -> t
