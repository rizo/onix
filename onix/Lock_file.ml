type t = {
  repo : OpamUrl.t;
  scope : Lock_pkg.t list;
}

let pp_version f version = Fmt.pf f "version = %S;" version

let pp_repo_uri f repo_url =
  match repo_url.OpamUrl.hash with
  | Some rev ->
    Fmt.pf f "@[<v2>repo = builtins.fetchGit {@ url = %a;@ rev = %S;@]@,};"
      (Fmt.quote Opam_utils.pp_url)
      { repo_url with OpamUrl.hash = None }
      rev
  | None ->
    Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url

let pp_scope ~ignore_file f deps =
  let pp_pkg fmt pkg =
    Fmt.pf fmt "@[<v2>%a = {@ %a@]@,}" Lock_pkg.pp_name_escape_with_enderscore
      (Lock_pkg.name pkg) (Lock_pkg.pp ~ignore_file) pkg
  in
  let pp_list = Fmt.iter ~sep:(Fmt.any ";@,") List.iter pp_pkg in
  Fmt.pf f "@[<v2>scope = rec {@,%a;@]@,};@]" (Fmt.hvbox pp_list) deps

let pp ~ignore_file fmt t =
  Fmt.pf fmt {|{ pkgs ? import <nixpkgs> {} }:@.@[<v2>rec {@,%a@,%a@,%a@,}@.|}
    pp_version Lib.version pp_repo_uri t.repo (pp_scope ~ignore_file) t.scope

let make ~repo_url scope =
  if Option.is_none repo_url.OpamUrl.hash then
    Fmt.failwith "Repo URI without rev when creating a lock file: %a"
      Opam_utils.pp_url repo_url;
  { repo = repo_url; scope }
