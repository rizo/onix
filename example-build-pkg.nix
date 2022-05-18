{ pkgs ? import <nixpkgs> { }, lib, stdenv, makeSetupHook, breakpointHook }:

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

  collectDeps = lockDeps:
    lib.lists.foldr (lockDep: acc:
      if isNull lockDep then
        acc
      else
        let pkg = builtins.getAttr lockDep.name scope';
        in acc // { ${lockDep.name} = pkg; } // collectDeps lockDep.depends) { }
    lockDeps;

  collectPaths = deps:
    let
      path = dir: if builtins.pathExists dir then [ dir ] else [ ];
      empty = {
        libdir = [ ];
        stublibs = [ ];
        toplevel = [ ];
      };
      updatePath = acc: pkg:
        let
          libdir = path "${pkg}/lib/ocaml/${ocamlVersion}/site-lib";
          stublibs = path "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/stublibs";
          toplevel = path "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/toplevel";
        in {
          libdir = acc.libdir ++ libdir;
          stublibs = acc.stublibs ++ stublibs;
          toplevel = acc.toplevel ++ toplevel;
        };
    in lib.lists.foldl updatePath empty (builtins.attrValues deps);

  makeBuildCtx = lockPkg: {
    inherit (lockPkg) name version opam;
    depends = builtins.concatMap (lockPkgDep:
      if isNull lockPkgDep then
        [ ]
      else [{
        inherit (lockPkgDep) name version opam;
        path = builtins.getAttr lockPkgDep.name scope';
      }]) lockPkg.depends;
  };

  buildPkg = _name: lockPkg:
    let
      buildCtx = makeBuildCtx lockPkg;
      buildCtxFile =
        pkgs.writeText (lockPkg.name + ".json") (builtins.toJSON buildCtx);
      depPaths = collectPaths (collectDeps lockPkg.depends);

    in stdenv.mkDerivation {
      pname = lockPkg.name;
      version = lockPkg.version;
      src = lockPkg.src;
      dontUnpack = isNull lockPkg.src;

      buildInputs = [ pkgs.pkgconfig pkgs.opam-installer ];
      propagatedBuildInputs = builtins.map (dep: dep.path) buildCtx.depends;

      nativeBuildInputs = [ ];

      OCAMLPATH = lib.strings.concatStringsSep ":" depPaths.libdir;
      CAML_LD_LIBRARY_PATH = lib.strings.concatStringsSep ":" depPaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" depPaths.toplevel;

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
        ${onix}/bin/onix opam-install --path=$out ${buildCtxFile} | bash
        mkdir -p $out # In case nothing was installed.
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

