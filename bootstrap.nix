{ pkgs ? import <nixpkgs> { } }:

let
  onix = import ./default.nix {
    inherit pkgs;
    ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;
  };
in onix.env {
  repo = {
    url = "https://github.com/ocaml/opam-repository.git";
    rev = "f3dcd527e82e83facb92cd2727651938cb9fecf9";
  };
  path = ./.;
  deps = { "ocaml-system" = "*"; };
  vars = { dev-setup = true; };
}
