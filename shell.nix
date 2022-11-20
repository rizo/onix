{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocaml-ng.ocamlPackages_4_14
}:
let onix = import ./. { inherit pkgs ocamlPackages; };
in pkgs.mkShell {
  inputsFrom = [ onix ];
  buildInputs = [ pkgs.nixfmt ocamlPackages.ocaml-lsp pkgs.ocamlformat ];
}
