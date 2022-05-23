{ pkgs, ocaml }: {

  ocamlfind = pkg:
    pkg.overrideAttrs (super: {
      patches = [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
    });

  conf-binutils = pkg:
    pkg.overrideAttrs (super: {
      OBJDUMP_PATH = "${pkgs.binutils-unwrapped}/bin/objdump";
      CXXFILT_PATH = "${pkgs.binutils-unwrapped}/bin/c++filt";
      READELF_PATH = "${pkgs.binutils-unwrapped}/bin/readelf";
    });

  core_unix = pkg:
    pkg.overrideAttrs (super: {
      prePatch = super.prePatch + ''
        patchShebangs unix_pseudo_terminal/src/discover.sh
      '';
    });
}
