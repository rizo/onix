{ pkgs ? import <nixpkgs> { }, onix }:

let
  inherit (builtins)
    trace hasAttr getAttr setAttr mapAttrs concatMap pathExists foldl';
  inherit (pkgs) lib stdenv;
  inherit (lib) optionalString;
  inherit (pkgs.lib.lists) optional optionals;

  # Build the compiler from lock file from source by default.
  defaultOCaml = null;

  emptyPkg = stdenv.mkDerivation {
    name = "empty";
    phases = [ ];
    dontUnpack = true;
    configurePhase = "true";
    buildPhase = "true";
    installPhase = "${pkgs.coreutils}/bin/touch $out";
  };

  flagForScope = version: scope:
    let isRoot = version == "root";
    in if scope == true then
      isRoot
    else if scope == "deps" then
      !isRoot
    else if scope == "all" then
      true
    else if scope == false then
      false
    else
      throw "invalid flag scope value: ${scope}";

  # Collect a recursive depends package set from a list of locked packages.
  collectTransitivePkgs = init: scope: lockPkgs:
    foldl' (acc: lockPkg:
      if isNull lockPkg || builtins.hasAttr lockPkg.name acc then
        acc
      else
        let pkg = getAttr lockPkg.name scope;
        in acc // {
          ${lockPkg.name} = pkg;
        } // collectTransitivePkgs acc scope (lockPkg.depends or [ ])) init
    lockPkgs;

  # Get scope packages from a locked package.
  getLockPkgs = dependsName: lockPkg: scope:
    if hasAttr dependsName lockPkg then
      concatMap
      (lockDep: optional (!isNull lockDep) (getAttr lockDep.name scope))
      (getAttr dependsName lockPkg)
    else
      [ ];

  # Collect OCaml paths from a set of pkgs.
  collectPaths = ocamlVersion: pkgs:
    let
      path = dir: optional (pathExists dir) dir;
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
    in foldl' updatePath empty pkgs;

  buildPkg = { scope, strictDeps, logLevel, withTest, withDoc, withTools }:
    name: lockPkg:
    let
      ocaml = scope.ocaml;

      dependsPkgs = getLockPkgs "depends" lockPkg scope;
      buildPkgs = getLockPkgs "buildDepends" lockPkg scope;
      testPkgs = getLockPkgs "testDepends" lockPkg scope;
      docPkgs = getLockPkgs "docDepends" lockPkg scope;
      toolsPkgs = getLockPkgs "toolsDepends" lockPkg scope;
      depextsPkgs = lockPkg.depexts or [ ];

      transitivePkgs = builtins.attrValues
        (collectTransitivePkgs { } scope (lockPkg.depends or [ ]));
      transitivePaths =
        collectPaths ocaml.version (transitivePkgs ++ buildPkgs);

      # All but one package in opam follow this convention:
      # $ opam list --all --has-flag=conf
      isConfPkg = lib.strings.hasPrefix "conf-" lockPkg.name;

      src = lockPkg.src or null;

    in stdenv.mkDerivation {
      pname = name;
      version = lockPkg.version;

      inherit src;
      dontUnpack = isNull src;

      # Unfortunately many packages misclassify their dependencies so this
      # should be false for most packages.
      inherit strictDeps;

      dontStrip = true;

      # Propage direct dependencies and but not depexts for config packages.
      propagatedBuildInputs = dependsPkgs ++ optionals (!isConfPkg) depextsPkgs;

      # Onix calls opam-installer to install packages. Add direct build deps 
      nativeBuildInputs = [ pkgs.opam-installer ] ++ buildPkgs
        # Depexts
        ++ optionals isConfPkg depextsPkgs
        # Test depends
        ++ optionals (flagForScope lockPkg.version withTest) testPkgs
        # Doc depends
        ++ optionals (flagForScope lockPkg.version withDoc) docPkgs
        # Tools depends
        ++ optionals (flagForScope lockPkg.version withTools) toolsPkgs;

      # Set environment variables for OCaml library lookup. This needs to use
      # transitive dependencies as dune requires the full dependency tree.
      OCAMLPATH = lib.strings.concatStringsSep ":" transitivePaths.libdir;
      CAML_LD_LIBRARY_PATH =
        lib.strings.concatStringsSep ":" transitivePaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" transitivePaths.toplevel;

      ONIX_LOG_LEVEL = logLevel;

      prePatch = ''
        echo "+ prePatch ${lockPkg.name}-${lockPkg.version}"
        ${onix}/bin/onix opam-patch \
          --ocaml-version=${ocaml.version} \
          --opam=${lockPkg.opam} \
          $out
      '';

      # OCAMLFIND_DESTDIR: for ocamlfind install.
      # dune install is not flexible enough to provide libdir via env.
      # Do we need export OPAM_SWITCH_PREFIX="$out"
      # Do we need export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocaml.version}/site-lib"
      configurePhase = ''
        echo "+ configurePhase ${lockPkg.name}-${lockPkg.version}"
        runHook preConfigure
        ${optionalString pkgs.stdenv.cc.isClang ''
          export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE-} -Wno-error=unused-command-line-argument"''}
        export DUNE_INSTALL_PREFIX=$out
        export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocaml.version}/site-lib"
        runHook postConfigure
      '';

      buildPhase = ''
        echo "+ buildPhase ${lockPkg.name}-${lockPkg.version}"
        runHook preBuild
        ${onix}/bin/onix opam-build \
          --ocaml-version=${ocaml.version} \
          --opam=${lockPkg.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-tools=${builtins.toJSON withTools} \
          $out
        runHook postBuild
      '';

      # ocamlfind install requires the liddir to exist.
      # move packages installed with dune.
      installPhase = ''
        echo "+ installPhase ${lockPkg.name}-${lockPkg.version}"
        runHook preInstall
        mkdir -p $out/lib/ocaml/${ocaml.version}/site-lib/${name}

        ${onix}/bin/onix opam-install \
          --ocaml-version=${ocaml.version} \
          --opam=${lockPkg.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-tools=${builtins.toJSON withTools} \
          $out

        if [[ -e "$out/lib/${name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${name}" ]]; then
          echo "Moving $out/lib/${name} to $OCAMLFIND_DESTDIR"
          mv "$out/lib/${name}" "$OCAMLFIND_DESTDIR"
        fi
        runHook postInstall
      '';
    };

in {
  build = { ocaml ? defaultOCaml, lock, overrides ? { }, strictDeps ? false
    , logLevel ? "debug", withTest ? false, withDoc ? false, withTools ? false
    }:

    let
      onix-lock = import lock {
        inherit pkgs;
        self = onix-lock;
      };

      allOverrides = import ./overrides { inherit pkgs ocaml scope; } // {
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
      } // overrides;

      # The scope without overrides.
      baseScope = mapAttrs (buildPkg {
        inherit strictDeps scope logLevel withTest withDoc withTools;
      }) onix-lock;

      # The final scope with all packages and applied overrides.
      scope = mapAttrs (name: pkg:
        if hasAttr name allOverrides then
          (getAttr name allOverrides) pkg
        else
          pkg) baseScope;
    in scope;

  lock = { repo ? null }:
    pkgs.runCommand "onix-lock" { } ''
      ${onix}/bin/onix lock --repo=${repo}
    '';
}
