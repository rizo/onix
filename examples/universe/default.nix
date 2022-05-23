{ pkgs ? import <nixpkgs> { } }:

let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;

  onix = import ./../../default.nix { inherit pkgs ocamlPackages; };

  scope = onix.build {
    ocaml = ocamlPackages.ocaml;
    lock = ./onix-lock.nix;
    overrides = { dune = pkg: ocamlPackages.dune_3; };
  };
in scope.universe
