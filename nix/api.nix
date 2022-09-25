{ pkgs ? import <nixpkgs> { }, onix }:

let
  inherit (builtins)
    filter trace hasAttr getAttr setAttr attrNames attrValues mapAttrs concatMap
    pathExists foldl';
  inherit (pkgs) lib stdenv;
  inherit (lib) optionalString;
  inherit (pkgs.lib.lists) optional optionals;

  defaultRepoUrl = "https://github.com/ocaml/opam-repository.git";
  defaultLockFile = "./onix-lock.nix";
  defaultLogLevel = "debug";

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

  # Collect a recursive depends package set from a list of locked packages.
  collectTransitivePkgs = init: scope: lockPkgs:
    foldl' (acc: lockPkg:
      if isNull lockPkg || builtins.hasAttr lockPkg.name acc then
        acc
      else
        let
          pkg = getAttr lockPkg.name scope;
          deps = lockPkg.depends or [ ] ++ lockPkg.buildDepends or [ ];
          acc' = acc // { ${lockPkg.name} = pkg; };
        in collectTransitivePkgs acc' scope deps) init lockPkgs;

  collectTransitiveDeps = foldl' (acc: dep:
    if isNull dep || hasAttr dep.name acc then
      acc
    else
      let
        deps = dep.depends or [ ] ++ dep.buildDepends or [ ];
        depAcc = collectTransitiveDeps { } deps;
      in acc // depAcc // { ${dep.name} = attrNames depAcc; });

  getDeps = depType: dep:
    if hasAttr depType dep then
      filter (dep': (!isNull dep')) (getAttr depType dep)
    else
      [ ];

  # pass dep flags?
  processDeps = foldl' (acc: dep:
    if hasAttr dep.name acc then
      acc
    else
      let
        depends = getDeps "depends" dep;
        buildDepends = getDeps "buildDepends" dep;
        testDepends = getDeps "testDepends" dep;
        docDepends = getDeps "docDepends" dep;
        toolsDepends = getDeps "toolsDepends" dep;
        transitive = processDeps { } (depends ++ buildDepends);
        depexts = dep.depexts or [ ];
        dep' = dep // {
          inherit depends buildDepends testDepends docDepends toolsDepends
            depexts;
          transitiveDepends = attrValues transitive;
        };
      in acc // transitive // { ${dep.name} = dep'; });

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

  # apply overrides here to avoid computing pkgs if null in override.
  resolveDeps = scope: overrides:
    concatMap (dep:
      let pkg = getAttr dep.name scope;
      in if hasAttr dep.name overrides then
        let ovr = getAttr (trace "ovr: ${dep.name}" dep.name) overrides;
        in if isNull ovr then
          [ ]
        else if builtins.isFunction ovr then
          [ (ovr pkg) ]
        else # todo: check if isDerivation
          [ ovr ]
      else
        [ pkg ]);

  buildDep = { scope, overrides, logLevel, withTest, withDoc, withTools }:
    name: dep:
    let
      ocaml = scope.ocaml;

      dependsPkgs = resolveDeps scope overrides dep.depends;
      buildPkgs = resolveDeps scope overrides dep.buildDepends;
      testPkgs = resolveDeps scope overrides dep.testDepends;
      docPkgs = resolveDeps scope overrides dep.docDepends;
      toolsPkgs = resolveDeps scope overrides dep.toolsDepends;
      transitivePkgs = resolveDeps scope overrides dep.transitiveDepends;
      transitivePaths = collectPaths ocaml.version transitivePkgs;

      src = dep.src or null;

    in stdenv.mkDerivation {
      pname = name;
      version = dep.version;

      inherit src;
      dontUnpack = isNull src;

      # Unfortunately many packages misclassify their dependencies so this
      # should be false for most packages.
      # inherit strictDeps;
      strictDeps = true;

      dontStrip = true;

      checkInputs = optionals (evalDepFlag dep.version withTest) testPkgs;

      propagatedBuildInputs = dependsPkgs ++ buildPkgs ++ dep.depexts;

      propagatedNativeBuildInputs = [ pkgs.opam-installer ] ++ dependsPkgs
        ++ dep.depexts ++ buildPkgs
        ++ optionals (evalDepFlag dep.version withDoc) docPkgs
        ++ optionals (evalDepFlag dep.version withTools) toolsPkgs;

      # Set environment variables for OCaml library lookup. This needs to use
      # transitive dependencies as dune requires the full dependency tree.
      OCAMLPATH = lib.strings.concatStringsSep ":" transitivePaths.libdir;
      CAML_LD_LIBRARY_PATH =
        lib.strings.concatStringsSep ":" transitivePaths.stublibs;
      OCAMLTOP_INCLUDE_PATH =
        lib.strings.concatStringsSep ":" transitivePaths.toplevel;

      ONIX_LOG_LEVEL = logLevel;

      prePatch = ''
        echo "+ prePatch ${dep.name}-${dep.version}"
        ${onix}/bin/onix opam-patch \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --path=$out \
          ${dep.name}.${dep.version}
      '';

      # OCAMLFIND_DESTDIR: for ocamlfind install.
      # dune install is not flexible enough to provide libdir via env.
      # Do we need export OPAM_SWITCH_PREFIX="$out"
      configurePhase = ''
        echo "+ configurePhase ${dep.name}-${dep.version}"
        runHook preConfigure
        ${optionalString pkgs.stdenv.cc.isClang ''
          export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE-} -Wno-error=unused-command-line-argument"''}
        export DUNE_INSTALL_PREFIX=$out
        export OCAMLFIND_DESTDIR="$out/lib/ocaml/${ocaml.version}/site-lib"
        runHook postConfigure
      '';

      buildPhase = ''
        echo "+ buildPhase ${dep.name}-${dep.version}"
        runHook preBuild
        ${onix}/bin/onix opam-build \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-tools=${builtins.toJSON withTools} \
          --path=$out \
          ${dep.name}.${dep.version}
        runHook postBuild
      '';

      # ocamlfind install requires the liddir to exist.
      # move packages installed with dune.
      installPhase = ''
        echo "+ installPhase ${dep.name}-${dep.version}"
        runHook preInstall
        mkdir -p $out/lib/ocaml/${ocaml.version}/site-lib/${dep.name}

        ${onix}/bin/onix opam-install \
          --ocaml-version=${ocaml.version} \
          --opam=${dep.opam} \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-tools=${builtins.toJSON withTools} \
          --path=$out \
          ${dep.name}.${dep.version}

        if [[ -e "$out/lib/${dep.name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${dep.name}" ]]; then
          echo "Moving $out/lib/${dep.name} to $OCAMLFIND_DESTDIR"
          mv "$out/lib/${dep.name}" "$OCAMLFIND_DESTDIR"
        fi
        runHook postInstall
      '';
    };

  buildPkg = { scope, logLevel, withTest, withDoc, withTools }:
    name: lockPkg:
    let
      ocaml = scope.ocaml;

      dependsPkgs = getLockPkgs "depends" lockPkg scope;
      buildPkgs = getLockPkgs "buildDepends" lockPkg scope;
      testPkgs = getLockPkgs "testDepends" lockPkg scope;
      docPkgs = getLockPkgs "docDepends" lockPkg scope;
      toolsPkgs = getLockPkgs "toolsDepends" lockPkg scope;
      depextsPkgs = lockPkg.depexts or [ ];

      transitivePkgs = builtins.attrValues (collectTransitivePkgs { } scope
        (lockPkg.depends or [ ] ++ lockPkg.buildDepends or [ ]));
      transitivePaths = collectPaths ocaml.version (transitivePkgs);

      src = lockPkg.src or null;

    in stdenv.mkDerivation {
      pname = name;
      version = lockPkg.version;

      inherit src;
      dontUnpack = isNull src;

      # Unfortunately many packages misclassify their dependencies so this
      # should be false for most packages.
      # inherit strictDeps;
      strictDeps = true;

      dontStrip = true;

      checkInputs = optionals (evalDepFlag lockPkg.version withTest) testPkgs;

      propagatedBuildInputs = dependsPkgs ++ depextsPkgs ++ buildPkgs;

      propagatedNativeBuildInputs = [ pkgs.opam-installer ] ++ dependsPkgs
        ++ depextsPkgs ++ buildPkgs
        ++ optionals (evalDepFlag lockPkg.version withDoc) docPkgs
        ++ optionals (evalDepFlag lockPkg.version withTools) toolsPkgs;

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
          --path=$out \
          ${lockPkg.name}.${lockPkg.version}
      '';

      # OCAMLFIND_DESTDIR: for ocamlfind install.
      # dune install is not flexible enough to provide libdir via env.
      # Do we need export OPAM_SWITCH_PREFIX="$out"
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
          --path=$out \
          ${lockPkg.name}.${lockPkg.version}
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
          --path=$out \
          ${lockPkg.name}.${lockPkg.version}

        if [[ -e "$out/lib/${name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${name}" ]]; then
          echo "Moving $out/lib/${name} to $OCAMLFIND_DESTDIR"
          mv "$out/lib/${name}" "$OCAMLFIND_DESTDIR"
        fi
        runHook postInstall
      '';
    };

  # Convert an attrset with resolutions to a cmdline argument.
  mkResolutionsArg = resolutions:
    lib.strings.concatStringsSep "," (lib.attrsets.mapAttrsToList (name: value:
      # pkg = "*"
      if value == "*" then
        name
        # pkg = ">X"
      else if builtins.elem (builtins.substring 0 1 value) [
        ">"
        "<"
        "="
        "!"
      ] then
        name + value
        # pkg = "X"
      else
        name + "=" + value) resolutions);

in rec {
  private = { inherit processDeps; };

  build = { lockFile, overrides ? { }, logLevel ? defaultLogLevel
    , withTest ? true, withDoc ? true, withTools ? true }:

    let
      onixLock = import lockFile {
        inherit pkgs;
        self = onixLock;
      };

      allOverrides = import ./overrides { inherit pkgs scope; } // overrides;

      deps = processDeps { } (attrValues onixLock);

      # The scope without overrides.
      baseScope = mapAttrs (buildDep {
        inherit scope logLevel withTest withDoc withTools;
        overrides = import ./overrides { inherit pkgs scope; } // overrides;
      }) deps;

      # The final scope with all packages and applied overrides.
      # scope = mapAttrs (name: pkg:
      #   if hasAttr name allOverrides then
      #     (getAttr name allOverrides) pkg
      #   else
      #     pkg) baseScope;
      scope = baseScope;

    in scope;

  lock = { repoUrl ? defaultRepoUrl, resolutions ? null
    , lockFile ? defaultLockFile, logLevel ? defaultLogLevel }:
    pkgs.mkShell {
      buildInputs = [ onix ];
      shellHook = if isNull resolutions then ''
        onix lock \
          --repo-url='${repoUrl}' \
          --lock-file='${lockFile}' \
          --verbosity='${logLevel}'
        exit $?
      '' else ''
        onix lock \
          --repo-url='${repoUrl}' \
          --resolutions='${mkResolutionsArg resolutions}' \
          --lock-file='${lockFile}' \
          --verbosity='${logLevel}'
        exit $?
      '';
    };

  shell = args:
    let scope = build args;
    in pkgs.mkShell { inputsFrom = builtins.attrValues scope; };
}
