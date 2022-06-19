{ pkgs ? import <nixpkgs> { } }:
let onix = import ./. { inherit pkgs; };
in pkgs.mkShell {
  inputsFrom = [ onix ];
  buildInputs = [
    pkgs.nixfmt
    pkgs.ocaml-ng.ocamlPackages_4_14.ocaml-lsp
    pkgs.ocamlformat
  ];
}
