{ pkgs ? import <nixpkgs> { } }:

let
  ocamlPackages = pkgs.ocamlPackages;

  onix = import ./onix.nix {
    inherit pkgs ocamlPackages;
    useLocal = true;
  };

  scope = onix.build {
    ocaml = ocamlPackages.ocaml;
    lock = ./onix-lock.nix;
    overrides = { };
  };
in scope.hello
