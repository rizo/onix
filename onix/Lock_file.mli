type t = {
  repos : OpamUrl.t list;
  packages : Lock_pkg.t list;
}

val make : repos:OpamUrl.t list -> Lock_pkg.t list -> t
