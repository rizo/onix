{ pkgs ? import <nixpkgs> { } }:
let onix = import ./. { inherit pkgs; };
in pkgs.mkShell {
  inputsFrom = [ onix ];
  buildInputs = [ pkgs.nixfmt pkgs.ocamlPackages.ocaml-lsp pkgs.ocamlformat ];
}
