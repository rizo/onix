{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages }:

import (builtins.fetchTarball
  "https://github.com/odis-labs/onix/archive/refs/heads/master.zip") {
    inherit pkgs ocamlPackages;
  }
