nixpkgs: self: super:

let
  common = {
    ocamlfind = super.ocamlfind.overrideAttrs (_oldAttrs: {
      patches = [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
    });

    ocb-stubblr = super.ocb-stubblr.overrideAttrs
      (_oldAttrs: { patches = [ ./ocb-stubblr/disable-opam.patch ]; });

    # https://github.com/ocsigen/lwt/pull/946
    lwt_react = super.lwt_react.overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
        ++ [ self.cppo or null ];
    });

    # https://github.com/pqwy/ocb-stubblr/blob/34dcbede6b51327172a0a3d83ebba02843aca249/src/ocb_stubblr.ml#L42
    core_unix = super.core_unix.overrideAttrs (oldAttrs: {
      prePatch = oldAttrs.prePatch + ''
        patchShebangs unix_pseudo_terminal/src/discover.sh
      '';
    });

    # For versions < 1.12
    zarith = super.zarith.overrideAttrs (oldAttrs: {
      prePatch = oldAttrs.prePatch + ''
        if test -e ./z_pp.pl; then
          patchShebangs ./z_pp.pl
        fi
      '';
    });
  };

  darwin = {
    dune = super.dune.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs or [ ] ++ [
        nixpkgs.darwin.apple_sdk.frameworks.Foundation
        nixpkgs.darwin.apple_sdk.frameworks.CoreServices
      ];
    });
  };
in common
// nixpkgs.lib.optionalAttrs nixpkgs.stdenv.hostPlatform.isDarwin darwin
