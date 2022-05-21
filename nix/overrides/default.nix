{ pkgs, ocaml }: {

  ocamlfind = pkg:
    pkg.overrideAttrs (super: {
      patches = [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
    });

}
