{ pkgs ? import <nixpkgs> { } }:

let
  onix = import ./onix.nix { inherit pkgs; };
  scope = onix.build {
    ocaml = pkgs.ocaml-ng.ocamlPackages_4_14.ocaml;
    lock = ./onix-lock.nix;
    overrides = { };
  };
in scope.onix
