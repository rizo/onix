type t = {
  repo_uri : Uri.t;
  packages : Lock_pkg.t list;
}

let pp_repo_uri f repo_uri =
  match Uri.fragment repo_uri with
  | Some rev ->
    Fmt.pf f
      "opam-repo ? builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = \
       true;@]@ }"
      (Uri.to_string repo_uri) rev
  | None -> Fmt.invalid_arg "Repo URI without fragment: %a" Uri.pp repo_uri

let pp fmt t =
  let pp_nix_attr fmt t =
    Fmt.pf fmt "@[<v2>%a = %s{%a@]@,}" Lock_pkg.pp_name (Lock_pkg.name t)
      (if Lock_pkg.is_pinned t || Lock_pkg.is_root t then "rec " else " ")
      Lock_pkg.pp t
  in
  let pp_list = Fmt.iter ~sep:(Fmt.any ";@,") List.iter pp_nix_attr in
  Fmt.pf fmt {|{ pkgs, self, %a }:@.@[<v2>{@,%a;@]@,}@.|} pp_repo_uri t.repo_uri
    (Fmt.hvbox pp_list) t.packages

let make ~repo_uri packages =
  if Option.is_none (Uri.fragment repo_uri) then
    Fmt.failwith "Repo URI without rev when creating a lock file: %a" Uri.pp
      repo_uri;
  { repo_uri; packages }
