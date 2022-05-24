{ pkgs ? import <nixpkgs> { }, onix }:

let
  inherit (builtins)
    trace hasAttr getAttr setAttr mapAttrs concatMap pathExists foldl';
  inherit (pkgs) lib stdenv;
  inherit (pkgs.lib.lists) optional;

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

  collectTransitiveDeps = init: scope: lockDeps:
    foldl' (acc: lockDep:
      if isNull lockDep || builtins.hasAttr lockDep.name acc then
        acc
      else
        let pkg = getAttr lockDep.name scope;
        in acc // {
          ${lockDep.name} = pkg;
        } // collectTransitiveDeps acc scope lockDep.depends) init lockDeps;

  collectPaths = ocamlVersion: pkgDeps:
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

  buildPkg = ocamlVersion: scope: name: lockPkg:
    let
      transitiveDeps = collectTransitiveDeps { } scope lockPkg.depends;
      transitiveDepsPaths = collectPaths ocamlVersion transitiveDeps;
      directDeps = concatMap (lockDep:
        optional (!isNull lockDep) (getAttr lockDep.name transitiveDeps))
        lockPkg.depends;

    in stdenv.mkDerivation {
      pname = name;
      version = lockPkg.version;
      src = lockPkg.src;
      dontUnpack = isNull lockPkg.src;

      propagatedBuildInputs = lockPkg.depexts ++ directDeps;

      # strictDeps = true;
      # nativeBuildInputs = [ scope.ocaml scope.dune pkgs.opam-installer ];
      nativeBuildInputs = [ pkgs.opam-installer ];

      OCAMLPATH = lib.strings.concatStringsSep ":" transitiveDepsPaths.libdir;
      CAML_LD_LIBRARY_PATH =
        lib.strings.concatStringsSep ":" transitiveDepsPaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" transitiveDepsPaths.toplevel;

      ONIX_LOG_LEVEL = "debug";

      prePatch = ''
        echo + prePatch ${name} $out
        echo ${onix}/bin/onix opam-patch --ocaml-version=${ocamlVersion} --opam=${lockPkg.opam} $out
        ${onix}/bin/onix opam-patch --ocaml-version=${ocamlVersion} --opam=${lockPkg.opam} $out
      '';

      # Not sure if OCAMLFIND_DESTDIR is needed.
      # dune install is not flexible enough to provide libdir via env.
      # some packages call dune install from build.
      configurePhase = ''
        echo + configurePhase
        export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocamlVersion}/site-lib"
        export DUNE_INSTALL_PREFIX=$out
      '';

      buildPhase = ''
        echo + buildPhase ${name} $out
        ${onix}/bin/onix opam-build  --ocaml-version=${ocamlVersion} --opam=${lockPkg.opam} $out
      '';

      # ocamlfind install requires the liddir to exist.
      # move packages installed with dune.
      installPhase = ''
        echo + installPhase ${name} $out
        mkdir -p $out/lib/ocaml/${ocamlVersion}/site-lib/${name}
        ${onix}/bin/onix opam-install --ocaml-version=${ocamlVersion} --opam=${lockPkg.opam} $out

        if [[ -e "$out/lib/${name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${name}" ]]; then
          echo "Moving $out/lib/${name} to $OCAMLFIND_DESTDIR"
          mv "$out/lib/${name}" "$OCAMLFIND_DESTDIR"
        fi
      '';
    };

in {
  build = { ocaml ? defaultOCaml, lock, overrides ? { } }:

    let
      onix-lock = import lock {
        inherit pkgs;
        self = onix-lock;
      };

      allOverrides = import ./overrides { inherit pkgs ocaml; } // {
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
      baseScope = mapAttrs (buildPkg onix-lock.ocaml.version scope) onix-lock;

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
