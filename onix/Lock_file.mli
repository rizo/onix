type t = {
  repo_url : OpamUrl.t;
  packages : Lock_pkg.t list;
  gitignore : bool;
}

val make : ?gitignore:bool -> repo_url:OpamUrl.t -> Lock_pkg.t list -> t
val pp : Format.formatter -> t -> unit
