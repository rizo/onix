{ pkgs ? import <nixpkgs> { }, stdenv, makeSetupHook, breakpointHook }:

let
  onix = import ./default.nix { inherit pkgs; };

  overrides = {
    ocaml = pkgs.ocaml;
    ocamlfind = super: {
      patches = [ ./ldconf.patch ./install_topfind.patch ];
    };
  };

  onix-lock = import ./onix-lock.nix {
    inherit pkgs;
    scope = scope';
  };
  scope = builtins.mapAttrs buildPkg onix-lock;
  ocamlVersion = scope'.ocaml.version;

  getLibDir = dep:
    if isNull (builtins.trace ">>> ${builtins.toJSON dep}" dep) then
      [ ]
    else
      let dir = "${dep.path}/lib/ocaml/${ocamlVersion}/site-lib";
      in (if builtins.pathExists dir then [ dir ] else [ ]);
  # ++ builtins.map getLibDir
  # (pkgs.lib.attrsets.getAttrFromPath [ dep.name "depends" ] onix-lock);

  getStubLibsDir = dep:
    if isNull dep then
      [ ]
    else
      let dir = "${dep.path}/lib/ocaml/${ocamlVersion}/site-lib/stublibs";
      in if builtins.pathExists dir then [ dir ] else [ ];

  getTopIncludeDir = dep:
    if isNull dep then
      [ ]
    else
      let dir = "${dep.path}/lib/ocaml/${ocamlVersion}/site-lib/toplevel";
      in if builtins.pathExists dir then [ dir ] else [ ];

  buildPkg = name: lockedPkg:
    let
      buildCtx = {
        inherit (lockedPkg) name version opam;
        depends = builtins.concatMap (dep:
          if isNull dep then
            [ ]
          else [{
            inherit (dep) name version path opam;
          }]) lockedPkg.depends;
      };
      buildCtxFile = pkgs.writeText (name + ".json") (builtins.toJSON buildCtx);

    in {
      inherit (lockedPkg) name version opam;
      path = stdenv.mkDerivation {

        pname = lockedPkg.name;
        version = lockedPkg.version;
        src = lockedPkg.src;
        dontUnpack = isNull lockedPkg.src;
        # setupHooks = [onixSetupOcamlEnv];

        buildInputs = [ pkgs.pkgconfig pkgs.opam-installer ];
        propagatedBuildInputs = [ ]
          ++ builtins.concatMap (dep: if isNull dep then [ ] else [ dep.path ])
          lockedPkg.depends;

        nativeBuildInputs = [ ];

        OCAMLPATH = pkgs.lib.strings.concatStringsSep ":"
          (builtins.concatMap (getLibDir) lockedPkg.depends);
        CAML_LD_LIBRARY_PATH = pkgs.lib.strings.concatStringsSep ":"
          (builtins.concatMap (getStubLibsDir) lockedPkg.depends);
        OCAMLTOP_INCLUDE_PATH = pkgs.lib.strings.concatStringsSep ":"
          (builtins.concatMap (getTopIncludeDir) lockedPkg.depends);

        # strictDeps = false;

        prePatch = ''
          echo + prePatch ${lockedPkg.name} $out
          ${onix}/bin/onix opam-patch --path=$out ${buildCtxFile} | bash
        '';

        configurePhase = ''
          echo + configurePhase
        '';

        buildPhase = ''
          echo + buildPhase ${lockedPkg.name} $out
          ${onix}/bin/onix opam-build --path=$out ${buildCtxFile} | bash
        '';

        installPhase = ''
          echo + installPhase ${lockedPkg.name} $out
          ${onix}/bin/onix opam-install --path=$out ${buildCtxFile} | tee /dev/stderr | bash

          mkdir -p $out/bin
          echo date > $out/bin/my_date
          chmod +x $out/bin/my_date
          mkdir -p $out/etc
          cp ${buildCtxFile} $out/etc/${name}.json
        '';
      };
    };

  scope' = builtins.mapAttrs (name: pkg: {
    inherit (pkg) name version opam;
    path = if builtins.hasAttr pkg.name overrides then
      let overrider = builtins.getAttr pkg.name overrides;
      in if builtins.isFunction overrider then
        pkg.path.overrideAttrs (overrider)
      else if pkgs.lib.attrsets.isDerivation overrider then
        overrider
      else
        throw
        "Error: override value must be either a function or a package derivation."
    else
      pkg.path;
  }) scope;
in scope'.bos

