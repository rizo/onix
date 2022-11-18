nixpkgs: self: super:

let
  inherit (nixpkgs) lib;

  common = {
    ocamlfind = super.ocamlfind.overrideAttrs (oldAttrs: {
      patches = lib.optional (lib.versionOlder oldAttrs.version "1.9.3")
        ./ocamlfind/onix_install_topfind_192.patch
        ++ lib.optional (oldAttrs.version == "1.9.3")
        ./ocamlfind/onix_install_topfind_193.patch
        ++ lib.optional (oldAttrs.version == "1.9.4")
        ./ocamlfind/onix_install_topfind_194.patch
        ++ lib.optional (lib.versionAtLeast oldAttrs.version "1.9.5")
        ./ocamlfind/onix_install_topfind_195.patch;

      setupHook = nixpkgs.writeText "ocamlfind-setup-hook.sh" ''
        export OCAMLTOP_INCLUDE_PATH="$1/lib/ocaml/${self.ocaml.version}/site-lib/toplevel"
      '';
    });

    ocb-stubblr = super.ocb-stubblr.overrideAttrs
      (_oldAttrs: { patches = [ ./ocb-stubblr/onix_disable_opam.patch ]; });

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

    # With propagated inputs this is not necessary.
    # https://github.com/ocaml/opam-repository/blob/e470f5f4ad3083618a4e144668faaa81b726b912/packages/either/either.1.0.0/opam#L14
    # either = super.either.overrideAttrs
    #   (oldAttrs: { buildInputs = oldAttrs.buildInputs ++ [ self.ocaml ]; });
    #
    # ctypes = super.ctypes.overrideAttrs (selfAttrs: superAttrs: {
    #   postInstall = ''
    #     mkdir -p "$out/lib/ocaml/4.14.0/site-lib/stublibs"
    #     mv $out/lib/ocaml/4.14.0/site-lib/ctypes/*.so "$out/lib/ocaml/4.14.0/site-lib/stublibs"
    #   '';
    # });

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
