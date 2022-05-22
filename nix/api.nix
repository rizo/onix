{ pkgs ? import <nixpkgs> { }, onix }:

let
  inherit (pkgs) lib stdenv;

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

  collectDeps = scope: lockDeps:
    lib.lists.foldr (lockDep: acc:
      if isNull lockDep then
        acc
      else
        let pkg = builtins.getAttr lockDep.name scope;
        in acc // {
          ${lockDep.name} = pkg;
        } // collectDeps scope lockDep.depends) { } lockDeps;

  collectPaths = ocamlVersion: pkgDeps:
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

  makeBuildCtx = scope: lockPkg: {
    inherit (lockPkg) name version opam;
    depends = builtins.concatMap (lockPkgDep:
      if isNull lockPkgDep then
        [ ]
      else [{
        inherit (lockPkgDep) name version opam;
        path = builtins.getAttr lockPkgDep.name scope;
      }]) lockPkg.depends;
  };

  buildPkg = ocamlVersion: scope: name: lockPkg:
    let
      buildCtx = makeBuildCtx scope lockPkg;
      buildCtxFile = pkgs.writeText (name + ".json") (builtins.toJSON buildCtx);
      depPaths = collectPaths ocamlVersion (collectDeps scope lockPkg.depends);

    in stdenv.mkDerivation {
      pname = name;
      version = lockPkg.version;
      src = lockPkg.src;
      dontUnpack = isNull lockPkg.src;

      propagatedBuildInputs = lockPkg.depexts
        ++ builtins.map (dep: dep.path) buildCtx.depends;

      nativeBuildInputs = [ pkgs.opam-installer ];

      OCAMLPATH = lib.strings.concatStringsSep ":" depPaths.libdir;
      CAML_LD_LIBRARY_PATH = lib.strings.concatStringsSep ":" depPaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" depPaths.toplevel;

      # strictDeps = false;

      prePatch = ''
        echo + prePatch ${name} $out
        ${onix}/bin/onix opam-patch --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile}
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
        ${onix}/bin/onix opam-build  --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile}
      '';

      # ocamlfind install requires the liddir to exist.
      installPhase = ''
        echo + installPhase ${name} $out
        mkdir -p $out/lib/ocaml/${ocamlVersion}/site-lib/${name}
        ${onix}/bin/onix opam-install --ocaml-version=${ocamlVersion} --path=$out ${buildCtxFile}

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
      baseScope =
        builtins.mapAttrs (buildPkg onix-lock.ocaml.version scope) onix-lock;

      # The final scope with all packages and applied overrides.
      scope = builtins.mapAttrs (name: pkg:
        if builtins.hasAttr name allOverrides then
          (builtins.getAttr name allOverrides) pkg
        else
          pkg) baseScope;
    in scope;

  lock = { repo ? null }:
    pkgs.runCommand "onix-lock" { } ''
      ${onix}/bin/onix lock --repo=${repo}
    '';
}
