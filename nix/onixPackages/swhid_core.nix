{ lib, fetchurl, buildDunePackage }:

buildDunePackage rec {
  pname = "swhid_core";
  version = "0.1";
  useDune2 = true;

  src = fetchurl {
    url =
      "https://github.com/OCamlPro/swhid_core/archive/refs/tags/0.1.tar.gz";
    sha256 = "sha256-hxi065fJ8KzW2RYqnvovavgkdKC9GG9iL9oylPdzvM8=";
  };

  meta = with lib; {
    description = "swhid_core";
    homepage = "https://github.com/OCamlPro/swhid_core";
    license = licenses.isc;
    maintainers = [ ];
  };
}
