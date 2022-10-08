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
      setupHook = nixpkgs.writeText "onix-ocamlfind-setup-hook.sh" ''
        [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0

        addOCamlPath () {
          addToSearchPath "OCAMLPATH" "$1/lib/ocaml/${super.ocaml.version}/site-lib"
          addToSearchPath "CAML_LD_LIBRARY_PATH" "$1/lib/ocaml/${super.ocaml.version}/site-lib/stublibs"
          addToSearchPath "OCAMLTOP_INCLUDE_PATH" "$1/lib/ocaml/${super.ocaml.version}/site-lib/toplevel"
        }

        # run for every buildInput to update paths
        addEnvHooks "$targetOffset" addOCamlPath
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
