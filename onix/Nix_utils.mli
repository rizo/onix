val get_nix_build_jobs : unit -> string
val fetch_git : rev:string -> string -> OpamFilename.Dir.t
val fetch_git_resolve : string -> string * OpamFilename.Dir.t

val prefetch_url_with_path :
  ?hash_type:[< `sha256 | `sha512 > `sha256] ->
  ?hash:string ->
  string ->
  string * OpamFilename.Dir.t

val prefetch_url :
  ?hash_type:[< `sha256 | `sha512 > `sha256] -> ?hash:string -> string -> string
