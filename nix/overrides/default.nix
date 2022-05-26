{ pkgs, ocaml, scope }:

let
  common = {
    ocamlfind = pkg:
      pkg.overrideAttrs (super: {
        patches =
          [ ./ocamlfind/ldconf.patch ./ocamlfind/install_topfind.patch ];
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
  };

  darwin = {
    dune = pkg:
      pkg.overrideAttrs (super: {
        buildInputs = super.buildInputs or [ ] ++ [
          pkgs.darwin.apple_sdk.frameworks.Foundation
          pkgs.darwin.apple_sdk.frameworks.CoreServices
        ];
      });
  };

in common // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin darwin
