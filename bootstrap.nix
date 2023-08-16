{ pkgs ? import <nixpkgs> { } }:

let
  onix = import ./default.nix {
    inherit pkgs;
    ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;
    verbosity = "debug";
  };
in onix.env {
  repos = [{
    url = "https://github.com/ocaml/opam-repository.git";
    rev = "f3dcd527e82e83facb92cd2727651938cb9fecf9";
  }];
  path = ./.;
  deps = { "ocaml-system" = "*"; };
  vars = { "with-dev-setup" = true; };
}
