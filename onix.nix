{
  opam-version = "2.0";
  synopsis = "OCaml project manager based on Nix";
  maintainer = [ "Rizo I. <rizo@odis.io>" ];
  license = "ISC";
  homepage = "https://github.com/odis-labs/onix";
  bug-reports = "https://github.com/odis-labs/onix/issues";
  depends = {
    "ocaml" = ">= 4.08";
    "dune" = ">= 2.0";
    "cmdliner" = "*";
  };
  doc-depends = { "odoc" = "*"; };
}
