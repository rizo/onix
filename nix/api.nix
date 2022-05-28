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

  collectTransitiveDeps = init: scope: lockDeps:
    foldl' (acc: lockDep:
      if isNull lockDep || builtins.hasAttr lockDep.name acc then
        acc
      else
        let pkg = getAttr lockDep.name scope;
        in acc // {
          ${lockDep.name} = pkg;
        } // collectTransitiveDeps acc scope (lockDep.depends or [ ])) init
    lockDeps;

  collectDepsPaths = ocamlVersion: pkgDeps:
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
    in foldl' updatePath empty (builtins.attrValues pkgDeps);

  buildPkg = { scope, strictDeps, logLevel, withTest, withDoc, withTools }:
    name: lockPkg:
    let
      ocaml = scope.ocaml;

      # Transitive dependencies and their OCaml paths.
      transitiveDeps = collectTransitiveDeps { } scope
        (lockPkg.depends or [ ] ++ lockPkg.buildDepends or [ ]);
      transitiveDepsPaths = collectDepsPaths ocaml.version transitiveDeps;

      # Direct dependencies of the package.
      directDeps = concatMap
        (lockDep: optional (!isNull lockDep) (getAttr lockDep.name scope))
        (lockPkg.depends or [ ]);

      # Build dependencies of the package.
      directBuildDeps = concatMap
        (lockDep: optional (!isNull lockDep) (getAttr lockDep.name scope))
        (lockPkg.buildDepends or [ ]);

      # All but one package in opam follow this convention:
      # $ opam list --all --has-flag=conf
      isConfigPkg = lib.strings.hasPrefix "conf-" lockPkg.name;

      src = lockPkg.src or null;

    in stdenv.mkDerivation {
      pname = name;
      version = lockPkg.version;
      inherit src;
      dontUnpack = isNull src;

      # Unfortunately many packages misclassify their dependencies so this
      # should be false for most packages.
      inherit strictDeps;

      # Propage direct dependencies and but not depexts for config packages.
      propagatedBuildInputs = directDeps ++ (lockPkg.depexts or [ ]);

      # Onix calls opam-installer to install packages. Add direct build deps 
      nativeBuildInputs = [ pkgs.opam-installer ] ++ directBuildDeps
        ++ optionals isConfigPkg (lockPkg.depexts or [ ])
        # Test depends
        ++ optionals (flagForScope lockPkg.version withTest)
        (lockPkg.testDepends or [ ])
        # Doc depends
        ++ optionals (flagForScope lockPkg.version withDoc)
        (lockPkg.docDepends or [ ])
        # Tools depends
        ++ optionals (flagForScope lockPkg.version withTools)
        (lockPkg.toolsDepends or [ ]);

      # Set environment variables for OCaml library lookup. This needs to use
      # transitive dependencies as dune requires the full dependency tree.
      OCAMLPATH = lib.strings.concatStringsSep ":" transitiveDepsPaths.libdir;
      CAML_LD_LIBRARY_PATH =
        lib.strings.concatStringsSep ":" transitiveDepsPaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" transitiveDepsPaths.toplevel;

      ONIX_LOG_LEVEL = logLevel;

      prePatch = ''
        echo + prePatch ${name} $out
        ${onix}/bin/onix opam-patch \
          --ocaml-version=${ocaml.version} \
          --opam=${lockPkg.opam} \
          $out
      '';

      # Not sure if OCAMLFIND_DESTDIR is needed.
      # dune install is not flexible enough to provide libdir via env.
      # Do we need export OPAM_SWITCH_PREFIX="$out"
      # Do we need export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocaml.version}/site-lib"
      configurePhase = ''
        runHook preConfigure
        ${optionalString pkgs.stdenv.cc.isClang ''
          export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE-} -Wno-error=unused-command-line-argument"''}
        export DUNE_INSTALL_PREFIX=$out
        runHook postConfigure
      '';

      buildPhase = ''
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
