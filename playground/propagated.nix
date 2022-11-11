let pkgs = import <nixpkgs> { };
in rec {
  conf-pkg-config = pkgs.stdenv.mkDerivation {
    pname = "my-conf-pkg-config";
    version = "0.0.1";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      echo "echo conf-pkg-config" > $out/bin/exe
      chmod +x $out/bin/exe
    '';
    propagatedNativeBuildInputs = [ pkgs.pkg-config ];
  };

  ctypes-foreign = pkgs.stdenv.mkDerivation {
    pname = "my-ctypes-foreign";
    version = "0.0.1";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      echo "echo ctypes-foreign" > $out/bin/exe
      chmod +x $out/bin/exe
    '';
    buildInputs = [ conf-pkg-config ];
  };

  ctypes = pkgs.stdenv.mkDerivation {
    pname = "my-ctypes";
    version = "0.0.1";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      echo "echo ctypes" > $out/bin/exe
      chmod +x $out/bin/exe
    '';
    buildInputs = [ ctypes-foreign ];
  };
}
