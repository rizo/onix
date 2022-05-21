{ lib, fetchurl, buildDunePackage, fmt, cmdliner, opam-state, opam-file-format
, zero-install-solver }:

buildDunePackage rec {
  pname = "opam-0install";
  version = "0.4.3";
  useDune2 = true;

  src = fetchurl {
    url =
      "https://github.com/ocaml-opam/opam-0install-solver/releases/download/v0.4.3/opam-0install-cudf-0.4.3.tbz";
    sha256 = "d59e0ebddda58f798ff50ebe213c83893b5a7c340c38c20950574d67e6145b8a";
  };

  propagatedBuildInputs =
    [ fmt cmdliner opam-state opam-file-format zero-install-solver ];

  meta = with lib; {
    description = "Opam solver using 0install backend";
    homepage = "https://github.com/ocaml-opam/opam-0install-solver";
    license = licenses.isc;
    maintainers = [ ];
  };
}
