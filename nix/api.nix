{ pkgs ? import <nixpkgs> { }, onix }:

let
  defaultRepoUrl = "https://github.com/ocaml/opam-repository.git";
  defaultLockFile = "./onix-lock.nix";
  defaultLogLevel = "debug";
  defaultOverlay = import ./overlays/default.nix pkgs;

  inherit (builtins)
    filter trace hasAttr getAttr setAttr attrNames attrValues mapAttrs concatMap
    pathExists foldl';
  inherit (pkgs) lib stdenv;
  inherit (lib) optionalString;
  inherit (pkgs.lib.lists) optional optionals;

  evalDepFlag = version: depFlag:
    let isRoot = version == "root";
    in if depFlag == true then
      isRoot
    else if depFlag == "deps" then
      !isRoot
    else if depFlag == "all" then
      true
    else if depFlag == false then
      false
    else
      throw "invalid dependency flag value: ${depFlag}";

  pkgsUnion = l1: l2:
    let
      l1Attrs = foldl'
        (acc: x: if hasAttr x.name acc then acc else acc // { ${x.name} = x; })
        { } l1;
      unionAttrs = foldl'
        (acc: x: if hasAttr x.name acc then acc else acc // { ${x.name} = x; })
        l1Attrs l2;
    in attrValues unionAttrs;

  getDeps = depType: dep:
    if hasAttr depType dep then
      filter (dep': (!isNull dep')) (getAttr depType dep)
    else
      [ ];

  # Process the lock deps to obtain a the full dependency tree.
  # TODO: pass dep flags.
  processDeps = foldl' (acc: dep:
    if hasAttr dep.name acc then
      acc
    else
      let
        depends = getDeps "depends" dep;
        buildDepends = getDeps "buildDepends" dep;
        testDepends = getDeps "testDepends" dep;
        docDepends = getDeps "docDepends" dep;
        devSetupDepends = getDeps "devSetupDepends" dep;
        transitive = processDeps { } (depends ++ buildDepends);
        depexts = dep.depexts or [ ];
        dep' = dep // {
          inherit depends buildDepends testDepends docDepends devSetupDepends
            depexts;
          transitiveDepends = attrValues transitive;
        };
      in acc // transitive // { ${dep.name} = dep'; });

  # Collect OCaml paths from a set of pkgs.
  collectPaths = ocamlVersion: pkgs:
    let
      check = dir: if pathExists dir then dir else null;
      add = acc: path:
        if isNull path then
          acc
        else if acc == "" then
          path
        else
          acc + ":" + path;
      empty = {
        libdir = "";
        stublibs = "";
        toplevel = "";
      };
      updatePath = acc: pkg:
        let
          libdir = check "${pkg}/lib/ocaml/${ocamlVersion}/site-lib";
          stublibs = check "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/stublibs";
          toplevel = check "${pkg}/lib/ocaml/${ocamlVersion}/site-lib/toplevel";
        in {
          libdir = add acc.libdir libdir;
          stublibs = add acc.stublibs stublibs;
          toplevel = add acc.toplevel toplevel;
        };
    in foldl' updatePath empty pkgs;

  # Build a package from a lock dependency.
  buildPkg = { scope, withTest, withDoc, withDevSetup }:
    name: dep:
    let
      ocaml = scope.ocaml;
      dependsPkgs = map (dep: getAttr dep.name scope) dep.depends;
      buildPkgs = map (dep: getAttr dep.name scope) dep.buildDepends;
      testPkgs = map (dep: getAttr dep.name scope) dep.testDepends;
      docPkgs = map (dep: getAttr dep.name scope) dep.docDepends;
      devSetupPkgs = map (dep: getAttr dep.name scope) dep.devSetupDepends;
      transitivePkgs = map (dep: getAttr dep.name scope) dep.transitiveDepends;

      transitivePaths = collectPaths ocaml.version transitivePkgs;

      src = dep.src or null;

      isConfPkg = let flags = dep.flags or [ ];
      in builtins.elem "conf" flags || builtins.elem "compiler" flags;

    in stdenv.mkDerivation {
      inherit src;
      pname = name;
      version = dep.version;
      dontUnpack = isNull src;
      strictDeps = true;
      dontStrip = true;

      checkInputs = optionals (evalDepFlag dep.version withTest) testPkgs;
      buildInputs = transitivePkgs ++ optionals (!isConfPkg) dep.depexts;
      nativeBuildInputs = buildPkgs
        ++ optionals (evalDepFlag dep.version withTest) testPkgs
        ++ optionals (evalDepFlag dep.version withDoc) docPkgs
        ++ optionals (evalDepFlag dep.version withDevSetup) devSetupPkgs;

      propagatedBuildInputs = optionals isConfPkg dep.depexts;
      propagatedNativeBuildInputs = optionals isConfPkg dep.depexts;

      ONIX_LOG_LEVEL = defaultLogLevel;
      ONIXPATH =
        lib.strings.concatStringsSep ":" (pkgsUnion dependsPkgs buildPkgs);

      # Set environment variables for OCaml library lookup. This needs to use
      # transitive dependencies as dune requires the full dependency tree.
      OCAMLPATH = transitivePaths.libdir;
      CAML_LD_LIBRARY_PATH = transitivePaths.stublibs;
      OCAMLTOP_INCLUDE_PATH = transitivePaths.toplevel;

      prePatch = ''
        ${onix}/bin/onix opam-patch \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --path=$out \
          ${dep.name}.${dep.version}
      '';

      # Steps:
      # - preConfigure;
      # - update NIX_CFLAGS_COMPILE;
      # - export OCAMLFIND_DESTDIR: for ocamlfind install (FIXME: is this needed?);
      # - export DUNE_INSTALL_PREFIX: dune does not allow overriding libdir via env.
      # Notes:
      # - Do we need export OPAM_SWITCH_PREFIX="$out"?
      configurePhase = ''
        runHook preConfigure

        ${optionalString pkgs.stdenv.cc.isClang ''
          export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE-} -Wno-error=unused-command-line-argument"''}
        export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocaml.version}/site-lib"
        export DUNE_INSTALL_PREFIX=$out

        runHook postConfigure
      '';

      # Steps:
      # - preBuild;
      # - onix opam-build;
      # - postBuild.
      buildPhase = ''
        runHook preBuild

        ${onix}/bin/onix opam-build \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --path=$out \
          ${dep.name}.${dep.version}

        runHook postBuild
      '';

      # Steps:
      # - preInstall;
      # - create $OCAMLFIND_DESTDIR/pkg: `ocamlfind install` requires the liddir to exist;
      # - onix opam-install;
      # - move $out/lib to $OCAMLFIND_DESTDIR (because of dune, see DUNE_INSTALL_PREFIX);
      # - ~~attempt to remove OCAMLFIND_DESTDIR/pkg if empty.~~
      #   - should at least contain opam?
      # - postInstall.
      # Notes:
      # - Do we need to rm libdir? At least opam should be always installed?
      installPhase = ''
        runHook preInstall

        # .install files
        ${pkgs.opaline}/bin/opaline \
          -prefix="$out" \
          -libdir="$out/lib/ocaml/${ocaml.version}/site-lib"

        # .config files
        if [[ -e "./${dep.name}.config" ]]; then
          mkdir -p "$out/etc"
          cp "./${dep.name}.config" "$out/etc/${dep.name}.config"
        fi

        mkdir -p "$OCAMLFIND_DESTDIR/${dep.name}"

        ${onix}/bin/onix opam-install \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --path=$out \
          ${dep.name}.${dep.version}

        if [[ -e "$out/lib/${dep.name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${dep.name}" ]]; then
          mv "$out/lib/${dep.name}" "$OCAMLFIND_DESTDIR"
        fi

        runHook postInstall
      '';

      shellHook = ''
        export OCAMLPATH=${transitivePaths.libdir}
        export CAML_LD_LIBRARY_PATH=${transitivePaths.stublibs}
        export OCAMLTOP_INCLUDE_PATH=${transitivePaths.toplevel}
      '';
    };

  # Convert an attrset with resolutions to a cmdline argument.
  mkResolutionsArg = resolutions:
    lib.strings.concatStringsSep "," (lib.attrsets.mapAttrsToList (name: value:
      if value == "*" then
      # pkg = "*"
        name
      else if builtins.elem (builtins.substring 0 1 value) [
        ">"
        "<"
        "="
        "!"
      ] then
      # pkg = ">X", pkg = ">=X", pkg = "<X", pkg = "<=X", pkg = "=X", pkg = "!=X"
        name + value
      else
      # pkg = "X"
        name + "=" + value) resolutions);

  # Build a package scope from the locked deps.
  buildScope = { withTest, withDoc, withDevSetup }:
    deps:
    pkgs.lib.makeScope pkgs.newScope (self:
      (mapAttrs (buildPkg {
        inherit withTest withDoc withDevSetup;
        scope = self;
      }) deps));

  # Apply default and user-provided overrides to the scope.
  applyOverrides = scope: overrides:
    let
      overlay = if isNull overrides then
        defaultOverlay
      else
        self: super: defaultOverlay self super // overrides self super;
    in scope.overrideScope' overlay;

in rec {
  private = { inherit processDeps; };

  build = { lockFile, overrides ? null, logLevel ? defaultLogLevel
    , withTest ? false, withDoc ? false, withDevSetup ? false }:
    let
      onixLock = import lockFile { inherit pkgs; };
      deps = processDeps { } (attrValues onixLock.scope);
      scope = buildScope { inherit withTest withDoc withDevSetup; } deps;
    in applyOverrides scope overrides;

  lock = { repoUrl ? defaultRepoUrl, resolutions ? null
    , lockFile ? defaultLockFile, logLevel ? defaultLogLevel, withTest ? false
    , withDoc ? false, withDevSetup ? false, opamFiles ? [ ] }:
    let opamFilesStr = lib.strings.concatStrings (map (f: " " + f) opamFiles);
    in pkgs.mkShell {
      buildInputs = [ onix ];
      shellHook = if isNull resolutions then ''
        onix lock \
          --repo-url='${repoUrl}' \
          --lock-file='${lockFile}' \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --verbosity='${logLevel}'${opamFilesStr}
        exit $?
      '' else ''
        onix lock \
          --repo-url='${repoUrl}' \
          --resolutions='${mkResolutionsArg resolutions}' \
          --lock-file='${lockFile}' \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --verbosity='${logLevel}'${opamFilesStr}
        exit $?
      '';
    };
}
