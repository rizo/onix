type t = {
  repo_url : OpamUrl.t;
  packages : Lock_pkg.t list;
}

let pp_repo_uri f repo_url =
  match repo_url.OpamUrl.hash with
  | Some rev ->
    Fmt.pf f "repo ? builtins.fetchGit {@ url = %a;@ rev = %S;@]@ }"
      (Fmt.quote Opam_utils.pp_url)
      { repo_url with OpamUrl.hash = None }
      rev
  | None ->
    Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url

let pp ~ignore_file fmt t =
  let pp_pkg fmt pkg =
    Fmt.pf fmt "@[<v2>%a = %s{@ %a@]@,}" Lock_pkg.pp_name (Lock_pkg.name pkg)
      (if Lock_pkg.is_pinned pkg || Lock_pkg.is_root pkg then "rec " else "")
      (Lock_pkg.pp ~ignore_file) pkg
  in
  let pp_list = Fmt.iter ~sep:(Fmt.any ";@,") List.iter pp_pkg in
  Fmt.pf fmt {|@[<v2>{ pkgs, self, %a@] }:@.@[<v2>{@,%a;@]@,}@.|} pp_repo_uri
    t.repo_url (Fmt.hvbox pp_list) t.packages

let make ~repo_url packages =
  if Option.is_none repo_url.OpamUrl.hash then
    Fmt.failwith "Repo URI without rev when creating a lock file: %a"
      Opam_utils.pp_url repo_url;
  { repo_url; packages }
