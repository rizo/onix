{ lib, fetchgit, buildDunePackage, bos, cmdliner, fpath, uri, yojson, opam-core
, opam-state, opam-0install }:

buildDunePackage rec {
  pname = "onix";
  version = "0.0.1";
  duneVersion = "3";

  src = fetchgit {
    url = "https://github.com/odis-labs/onix.git";
    rev = "96b7f60092ee89e7a9c259f7ebaf3077f8123e12";
    sha256 = "sha256-0jsJj60X1VM6lKBfotPj/zq5aTHlT04Zl1yL3WI4G80=";
  };

  propagatedBuildInputs =
    [ bos cmdliner fpath uri yojson opam-core opam-state opam-0install ];

  meta = with lib; {
    description = "Build OCaml projects with Nix.";
    homepage = "https://github.com/odis-labs/onix";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
