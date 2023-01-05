type t = {
  repository_urls : OpamUrl.t list;
  packages : Lock_pkg.t list;
  compiler : OpamPackage.t;
}

val make :
  repository_urls:OpamUrl.t list ->
  compiler:OpamPackage.t ->
  Lock_pkg.t list ->
  t
