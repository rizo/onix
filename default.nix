{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocaml-ng.ocamlPackages_5_3
, verbosity ? "warning" }:

let
  onixPackages = import ./nix/onixPackages { inherit pkgs ocamlPackages; };
  api = import ./nix/api.nix { inherit pkgs onix verbosity; };
  onix = ocamlPackages.buildDunePackage {
    pname = "onix";
    version = "0.0.6";
    duneVersion = "3";

    passthru = { inherit (api) env; };

    src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;

    nativeBuildInputs = [ pkgs.git onixPackages.crunch ];
    propagatedBuildInputs = with onixPackages; [
      bos
      cmdliner
      fpath
      yojson
      _0install-solver
      opam-0install
      opam-core
      opam-client
      opam-state
    ];

    meta = {
      description = "Build OCaml projects with Nix.";
      homepage = "https://github.com/odis-labs/onix";
      license = pkgs.lib.licenses.isc;
      maintainers = [ ];
    };
  };
in onix
