{ lib, fetchurl, buildDunePackage }:

buildDunePackage rec {
  pname = "spdx_licenses";
  version = "1.2.0";
  useDune2 = true;

  src = fetchurl {
    url =
      "https://github.com/kit-ty-kate/spdx_licenses/releases/download/v1.2.0/spdx_licenses-1.2.0.tar.gz";
    sha256 = "sha256-9ViB7PRDz70w3RJczapgn2tJx9wTWgAbdzos6r3J2r4=";
  };

  meta = with lib; {
    description = "spdx_licenses";
    homepage = "https://github.com/kit-ty-kate/spdx_licenses";
    license = licenses.mit;
    maintainers = [ ];
  };
}
