{ pkgs ? import <nixpkgs> { }, stdenv, makeSetupHook, breakpointHook }:

let
  onix = import ./default.nix { inherit pkgs; };

  overrides = {
    ocamlfind = super: {
      patches = [ ./ldconf.patch ./install_topfind.patch ];
    };
  };

  onix-lock = import ./onix-lock.nix {
    inherit pkgs;
    self = onix-lock;
  };

  scope = builtins.mapAttrs buildPkg onix-lock;

  ocaml = pkgs.ocaml-ng.ocamlPackages_4_14.ocaml;

  ocamlVersion = onix-lock.ocaml.version;

  getLibDir = lockPkg:
    if isNull lockPkg then
      [ ]
    else
      let pkg = builtins.getAttr lockPkg.name scope';
          dir = "${pkg}/lib/ocaml/${ocamlVersion}/site-lib";
      in
        (if builtins.pathExists dir then [ dir ] else [ ])
        ++ builtins.concatMap getLibDir lockPkg.depends;

  getStubLibsDir = lockPkg:
    if isNull lockPkg then
      [ ]
    else
      let pkg = builtins.getAttr lockPkg.name scope';
      dir = "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/stublibs";
      in (if builtins.pathExists dir then [ dir ] else [ ])
        ++ builtins.concatMap getStubLibsDir lockPkg.depends;

  getTopIncludeDir = lockPkg:
    if isNull lockPkg then
      [ ]
    else
      let pkg = builtins.getAttr lockPkg.name scope';
      dir = "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/toplevel";
      in (if builtins.pathExists dir then [ dir ] else [ ])
        ++ builtins.concatMap getTopIncludeDir lockPkg.depends;

  buildPkg = _name: lockPkg:
    let

      # The build context for the current lock package with depends from the built scope.
      buildCtx = {
        inherit (lockPkg) name version opam;
        depends = builtins.concatMap (lockPkgDep:
          if isNull lockPkgDep then
            [ ]
          else [{
            inherit (lockPkgDep) name version opam;
            path = builtins.getAttr lockPkgDep.name scope';
          }]) lockPkg.depends;
      };

      buildCtxFile =
        pkgs.writeText (lockPkg.name + ".json") (builtins.toJSON buildCtx);

    in stdenv.mkDerivation {
      passthru = { inherit (lockPkg) name version opam; };

      pname = lockPkg.name;
      version = lockPkg.version;
      src = lockPkg.src;
      dontUnpack = isNull lockPkg.src;
      # setupHooks = [onixSetupOcamlEnv];

      buildInputs = [ pkgs.pkgconfig pkgs.opam-installer ];
      propagatedBuildInputs =
        builtins.map (ctxPkg: ctxPkg.path) buildCtx.depends;

      nativeBuildInputs = [ ];

      OCAMLPATH = pkgs.lib.strings.concatStringsSep ":"
        (builtins.concatMap (getLibDir) lockPkg.depends);
      CAML_LD_LIBRARY_PATH = pkgs.lib.strings.concatStringsSep ":"
        (builtins.concatMap (getStubLibsDir) lockPkg.depends);
      OCAMLTOP_INCLUDE_PATH = pkgs.lib.strings.concatStringsSep ":"
        (builtins.concatMap (getTopIncludeDir) lockPkg.depends);

      # strictDeps = false;

      prePatch = ''
        echo + prePatch ${lockPkg.name} $out
        ${onix}/bin/onix opam-patch --path=$out ${buildCtxFile} | bash
      '';

      configurePhase = ''
        echo + configurePhase
      '';

      buildPhase = ''
        echo + buildPhase ${lockPkg.name} $out
        ${onix}/bin/onix opam-build --path=$out ${buildCtxFile} | bash
      '';

      installPhase = ''
        echo + installPhase ${lockPkg.name} $out
        ${onix}/bin/onix opam-install --path=$out ${buildCtxFile} | tee /dev/stderr | bash

        mkdir -p $out/bin
        echo date > $out/bin/my_date
        chmod +x $out/bin/my_date
        mkdir -p $out/etc
        cp ${buildCtxFile} $out/etc/${lockPkg.name}.json
      '';
    };

  scope' = builtins.mapAttrs (name: pkg:
    if name == "ocaml-base-compiler" || name == "ocaml" then
      if onix-lock.ocaml.version != ocaml.version then
        throw
        "Lock file uses ocaml ${onix-lock.ocaml.version} but ${ocaml.version} was provided."
      else
        ocaml
    else if builtins.hasAttr name overrides then
      pkg.overrideAttrs (builtins.getAttr name overrides)
    else
      pkg) scope;
in scope'.onix-example

