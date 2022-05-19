{ pkgs ? import <nixpkgs> { }, lib, stdenv }:

# TODO: handle empty lock file
# TODO: handle lock file without ocaml
let
  # ocaml = null;
  ocaml = pkgs.ocaml-ng.ocamlPackages_4_14.ocaml;
  onix = import ./default.nix { inherit pkgs; };

  onix-lock = import ./onix-lock.nix {
    inherit pkgs;
    self = onix-lock;
  };

  emptyPkg = stdenv.mkDerivation {
    name = "empty";
    phases = [ ];
    dontUnpack = true;
    configurePhase = "true";
    buildPhase = "true";
    installPhase = "mkdir -p $out";
  };

  overrides = {
    ocaml = pkg:
      if isNull ocaml then
        pkg
      else if onix-lock.ocaml.version != ocaml.version then
        throw
        "Lock file uses ocaml ${onix-lock.ocaml.version} but ${ocaml.version} was provided."
      else
        ocaml;

    # When a custom ocaml pkg is provided, these are not needed.
    ocaml-base-compiler = pkg: if isNull ocaml then pkg else emptyPkg;
    ocaml-config = pkg: if isNull ocaml then pkg else emptyPkg;

    ocamlfind = pkg:
      pkg.overrideAttrs
      (old: { patches = [ ./ldconf.patch ./install_topfind.patch ]; });
  };

  # The scope with packages built from the lock file.
  scope = builtins.mapAttrs buildPkg onix-lock;

  # Same as scope, but with overrides applied.
  scope' = builtins.mapAttrs (name: pkg:
    if builtins.hasAttr name overrides then
      (builtins.getAttr name overrides) pkg
    else
      pkg) scope;

  ocamlVersion = onix-lock.ocaml.version;

  collectDeps = lockDeps:
    lib.lists.foldr (lockDep: acc:
      if isNull lockDep then
        acc
      else
        let pkg = builtins.getAttr lockDep.name scope';
        in acc // { ${lockDep.name} = pkg; } // collectDeps lockDep.depends) { }
    lockDeps;

  collectPaths = pkgDeps:
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
    in lib.lists.foldl updatePath empty (builtins.attrValues pkgDeps);

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

  buildPkg = name: lockPkg:
    let
      buildCtx = makeBuildCtx lockPkg;
      buildCtxFile = pkgs.writeText (name + ".json") (builtins.toJSON buildCtx);
      depPaths = collectPaths (collectDeps lockPkg.depends);

    in stdenv.mkDerivation {
      pname = name;
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
        echo + prePatch ${name} $out
        ${onix}/bin/onix opam-patch --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile} | bash
      '';

      configurePhase = ''
        echo + configurePhase
      '';

      buildPhase = ''
        echo + buildPhase ${name} $out
        ${onix}/bin/onix opam-build  --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile} | bash
      '';

      installPhase = ''
        echo + installPhase ${name} $out
        ${onix}/bin/onix opam-install --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile} | bash
        mkdir -p $out # In case nothing was installed.
      '';
    };
in scope'.onix-example

