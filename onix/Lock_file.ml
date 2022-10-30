type t = {
  repo : OpamUrl.t;
  scope : Lock_pkg.t list;
}

let make ~repo_url scope =
  if Option.is_none repo_url.OpamUrl.hash then
    Fmt.failwith "Repo URI without rev when creating a lock file: %a"
      Opam_utils.pp_url repo_url;
  { repo = repo_url; scope }
