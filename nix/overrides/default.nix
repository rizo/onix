{ pkgs, ocaml }: {

  ocamlfind = pkg:
    pkg.overrideAttrs (super: {
      patches = [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
    });

    core_unix = pkg: pkg.overrideAttrs (super: {
      prePatch =
        super.prePatch + ''
          patchShebangs unix_pseudo_terminal/src/discover.sh
        '';
    });
}
