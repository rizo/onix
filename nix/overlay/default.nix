nixpkgs: self: super:

let
  inherit (nixpkgs) lib;

  common = {
    ocaml-version = super.ocaml-version.overrideAttrs (oldAttrs:
      if (oldAttrs.version == "3.7.1") then {
        unpackCmd = ''
          tar xf "$curSrc"
        '';
      } else {}
    );

    ocamlfind = super.ocamlfind.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ]
        ++ lib.optional (oldAttrs.version == "1.9.2") ./ocamlfind/onix_install_topfind_192.patch
        ++ lib.optional (oldAttrs.version == "1.9.3") ./ocamlfind/onix_install_topfind_193.patch
        ++ lib.optional (oldAttrs.version == "1.9.4") ./ocamlfind/onix_install_topfind_194.patch
        ++ lib.optional (oldAttrs.version == "1.9.5") ./ocamlfind/onix_install_topfind_195.patch
        ++ lib.optional (oldAttrs.version == "1.9.8") ./ocamlfind/onix_install_topfind_198.patch;
      setupHook = nixpkgs.writeText "ocamlfind-setup-hook.sh" ''
        [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0
        export OCAMLTOP_INCLUDE_PATH="$1/lib/ocaml/${super.ocaml.version}/site-lib/toplevel"
      '';
      # setupHook = nixpkgs.writeText "ocamlfind-setup-hook.sh" ''
      #   [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0

      #   addTargetOCamlPath () {
      #     local libdir="$1/lib/ocaml/${super.ocaml.version}/site-lib"

      #     if [[ ! -d "$libdir" ]]; then
      #       return 0
      #     fi

      #     echo "+ onix-ocamlfind-setup-hook.sh/addTargetOCamlPath: $*"

      #     addToSearchPath "OCAMLPATH" "$libdir"
      #     addToSearchPath "CAML_LD_LIBRARY_PATH" "$libdir/stublibs"
      #   }

      #   addEnvHooks "$targetOffset" addTargetOCamlPath

      #   export OCAMLTOP_INCLUDE_PATH="$1/lib/ocaml/${super.ocaml.version}/site-lib/toplevel"
      # '';
    });

    # topkg = super.topkg.overrideAttrs (oldAttrs: {
    #   setupHook = nixpkgs.writeText "topkg-setup-hook.sh" ''
    #     echo ">>> topkg-setup-hook: $1"
    #     addToSearchPath "OCAMLPATH" "$1/lib/ocaml/${self.ocaml.version}/site-lib"
    #   '';
    # });

    ocb-stubblr = super.ocb-stubblr.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ]
        ++ [ ./ocb-stubblr/onix_disable_opam.patch ];
    });

    # https://github.com/ocsigen/lwt/pull/946
    lwt_react = super.lwt_react.overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
        ++ [ self.cppo or null ];
    });

    # https://github.com/pqwy/ocb-stubblr/blob/34dcbede6b51327172a0a3d83ebba02843aca249/src/ocb_stubblr.ml#L42
    core_unix = super.core_unix.overrideAttrs (oldAttrs: {
      prePatch = (oldAttrs.prePatch or "") + ''
        patchShebangs unix_pseudo_terminal/src/discover.sh
      '';
    });

    # For versions < 1.12
    zarith = super.zarith.overrideAttrs (oldAttrs: {
      prePatch = (oldAttrs.prePatch or "") + ''
        if test -e ./z_pp.pl; then
          patchShebangs ./z_pp.pl
        fi
      '';
    });

    # https://nixos.org/manual/nixpkgs/stable/#var-stdenv-sourceRoot
    timedesc-tzdb =
      super.timedesc-tzdb.overrideAttrs (attrs: { sourceRoot = "."; });

    timedesc-tzlocal =
      super.timedesc-tzlocal.overrideAttrs (attrs: { sourceRoot = "."; });
      
    timedesc =
      super.timedesc.overrideAttrs (attrs: { sourceRoot = "."; });      

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

    num = super.num.overrideAttrs (selfAttrs: superAttrs: {
      installPhase = ''
          # opaline does not support lib_root
          substituteInPlace num.install --replace lib_root lib
          ${nixpkgs.opaline}/bin/opaline -prefix $out -libdir $OCAMLFIND_DESTDIR num.install
        '';
    });

    odoc = super.odoc.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ self.crunch ];
    });

    # nix 23.11 renamed `pkgconfig` to `pkg-config`
    conf-pkg-config = super.conf-pkg-config.overrideAttrs (oldAttrs: {
      propagatedBuildInputs = [ nixpkgs.pkg-config ];
      propagatedNativeBuildInputs = [ nixpkgs.pkg-config ];
    });
  };

  darwin = {
    dune = super.dune.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs or [ ] ++ [
        nixpkgs.darwin.apple_sdk.frameworks.Foundation
        nixpkgs.darwin.apple_sdk.frameworks.CoreServices
      ];

      # See https://github.com/ocaml/dune/pull/6260
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ nixpkgs.makeWrapper ];
      postFixup =
        if nixpkgs.stdenv.isDarwin then ''
            wrapProgram $out/bin/dune \
              --suffix PATH : "${nixpkgs.darwin.sigtool}/bin"
          ''
        else "";
    });
  };

  all = common
    // nixpkgs.lib.optionalAttrs nixpkgs.stdenv.hostPlatform.isDarwin darwin;

  # Remove overrides for packages not present in scope.
in lib.attrsets.filterAttrs (name: _: builtins.hasAttr name super) all
