type t = { packages : Lock_pkg.t list }

let pp fmt t =
  let pp_nix_attr fmt t =
    Fmt.pf fmt "@[<v2>%a = %s{%a@]@,}" Lock_pkg.pp_name (Lock_pkg.name t)
      (if Lock_pkg.is_pinned t || Lock_pkg.is_root t then "rec " else " ")
      Lock_pkg.pp t
  in
  let pp_list = Fmt.iter ~sep:(Fmt.any ";@,") List.iter pp_nix_attr in
  Fmt.pf fmt
    {|{ pkgs, self, opam-repo ? builtins.fetchGit {
  url = "https://github.com/ocaml/opam-repository.git";
  rev = "16ff1304f8ccdd5a8c9fa3ebe906c32ecdd576ee";
} }:@.@[<v2>{@,%a;@]@,}@.|}
    (Fmt.hvbox pp_list) t.packages

let make packages = { packages }
