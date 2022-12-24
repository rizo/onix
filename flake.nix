{
  description = "Build OCaml projects with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let
        pkgs = nixpkgs.legacyPackages.${system};
        mkOnix = ocamlPackages:
          import ./default.nix { inherit pkgs ocamlPackages; };

      in rec {
        packages = {
          "4_12" = mkOnix pkgs.ocaml-ng.ocamlPackages_4_12;
          "4_13" = mkOnix pkgs.ocaml-ng.ocamlPackages_4_13;
          "4_14" = mkOnix pkgs.ocaml-ng.ocamlPackages_4_14;
          latest = mkOnix pkgs.ocaml-ng.ocamlPackages_latest;
        };

        defaultPackage = packages.latest;
      });
}
