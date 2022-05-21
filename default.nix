{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages }:

let onixPackages = import ./nix/onixPackages { inherit pkgs ocamlPackages; };
in onixPackages.onix
