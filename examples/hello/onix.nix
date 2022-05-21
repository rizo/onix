{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages
, useLocal ? true }:

if useLocal then
  import ../../default.nix { inherit pkgs ocamlPackages; }
else
  import (builtins.fetchTarball
    "https://github.com/odis-labs/onix/archive/refs/heads/master.zip") {
      inherit pkgs ocamlPackages;
    }
