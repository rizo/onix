{ pkgs, ocaml, scope }: {

  ocamlfind = pkg:
    pkg.overrideAttrs (super: {
      patches = [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
    });

  # Is this still needed?
  conf-binutils = pkg:
    pkg.overrideAttrs (super: {
      OBJDUMP_PATH = "${pkgs.binutils-unwrapped}/bin/objdump";
      CXXFILT_PATH = "${pkgs.binutils-unwrapped}/bin/c++filt";
      READELF_PATH = "${pkgs.binutils-unwrapped}/bin/readelf";
    });

  # https://github.com/ocsigen/lwt/pull/946
  lwt_react = pkg:
    pkg.overrideAttrs (super: {
      nativeBuildInputs = super.nativeBuildInputs ++ [ scope.cppo or null ];
    });

  core_unix = pkg:
    pkg.overrideAttrs (super: {
      prePatch = super.prePatch + ''
        patchShebangs unix_pseudo_terminal/src/discover.sh
      '';
    });
}
