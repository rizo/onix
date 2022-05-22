{ pkgs ? import <nixpkgs> { } }:

let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;
  onix = import ./default.nix { };

  scope = onix.build {
    ocaml = ocamlPackages.ocaml;
    lock = ./onix-lock.nix;
    overrides = { };
  };
in scope.onix
