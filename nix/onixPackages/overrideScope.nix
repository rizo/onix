{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages }:

let
  extra = self: {
    cmdliner = self.callPackage ./cmdliner.nix { };
    zero-install-solver = self.callPackage ./0install-solver.nix { };
    opam-0install = self.callPackage ./opam-0install.nix { };
  };

  newScope = extra: pkgs.lib.callPackageWith (pkgs // ocamlPackages // extra);

  self = pkgs.lib.makeScope newScope extra;
in self.opam-0install
