{ pkgs, ocaml }: {

  ocamlfind = pkg:
    pkg.overrideAttrs (old: {
      patches = [
        ./ocamlfind/ldconf.patch
        ./ocamlfind/install_topfind.patch
      ];
    });
}
