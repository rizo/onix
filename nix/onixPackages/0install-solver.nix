{ lib, fetchurl, buildDunePackage }:

buildDunePackage rec {
  pname = "0install-solver";
  version = "2.17";
  useDune2 = true;

  src = fetchurl {
    url =
      "https://github.com/0install/0install/releases/download/v2.17/0install-v2.17.tbz";
    sha256 = "1704e5d852bad79ef9f5b5b31146846420270411c5396434f6fe26577f2d0923";
  };

  meta = with lib; {
    description = "Package dependency solver";
    homepage = "https://github.com/0install/0install";
    license = licenses.lgpl2;
    maintainers = [ ];
  };
}
