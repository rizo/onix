{ pkgs ? import <nixpkgs> { } }:

let
  # Use the compiler from nixpkgs.
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;

  onix = import ./../../default.nix { inherit pkgs ocamlPackages; };

  scope = onix.build {
    ocaml = ocamlPackages.ocaml;
    lock = ./onix-lock.nix;
  };
in scope.hello
