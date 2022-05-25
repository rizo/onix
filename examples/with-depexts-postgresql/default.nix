{ pkgs ? import <nixpkgs> { } }:

let
  # Use the compiler from nixpkgs.
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;

  onix = import (builtins.fetchTarball
    "https://github.com/odis-labs/onix/archive/refs/tags/0.0.2.tar.gz") {
      inherit pkgs ocamlPackages;
    };

  scope = onix.build {
    ocaml = ocamlPackages.ocaml;
    lock = ./onix-lock.nix;
  };
in scope.with-depexts-postgresql
