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
        };
      in acc // transitive // { ${dep.name} = dep'; });

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
      src = dep.src or null;

      # Adds an env hook for "targetOffset", i.e., all runtime deps to add OCaml paths.
      onixPathHook = pkgs.makeSetupHook { name = "onix-path-hook"; }
        (pkgs.writeText "onix-path-hook" ''
          [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0

          addOCamlPath () {
            local libdir="$1/lib/ocaml/${ocaml.version}/site-lib"

            if [[ -d "$libdir" ]]; then
              true
            else
              return 0
            fi

            addToSearchPath "OCAMLPATH" "$libdir"
            addToSearchPath "CAML_LD_LIBRARY_PATH" "$libdir/stublibs"
            addToSearchPath "OCAMLTOP_INCLUDE_PATH" "$libdir/toplevel"
          }

          addEnvHooks "$targetOffset" addOCamlPath
        '');

    in stdenv.mkDerivation {
      inherit src;
      pname = name;
      version = dep.version;
      dontUnpack = isNull src;
      strictDeps = true;
      dontStrip = true;

      checkInputs = optionals (evalDepFlag dep.version withTest) testPkgs;

      propagatedBuildInputs = dependsPkgs ++ buildPkgs ++ dep.depexts
        ++ [ onixPathHook ];
      propagatedNativeBuildInputs = [ pkgs.opam-installer ] ++ dependsPkgs
        ++ dep.depexts ++ buildPkgs
        ++ optionals (evalDepFlag dep.version withDoc) docPkgs
        ++ optionals (evalDepFlag dep.version withDevSetup) devSetupPkgs;

      ONIX_LOG_LEVEL = defaultLogLevel;
      ONIXPATH = lib.strings.concatStringsSep ":" (dependsPkgs ++ buildPkgs);

      prePatch = ''
        echo "+ prePatch: ${dep.name}-${dep.version}"

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
        echo "+ configurePhase: ${dep.name}-${dep.version}"

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
        echo "+ buildPhase: ${dep.name}-${dep.version}"
        runHook preBuild

        echo "+ OCAMLPATH=$OCAMLPATH"
        echo "+ CAML_LD_LIBRARY_PATH=$CAML_LD_LIBRARY_PATH"
        echo "+ OCAMLTOP_INCLUDE_PATH=$OCAMLTOP_INCLUDE_PATH"

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
      # - attempt to remove OCAMLFIND_DESTDIR/pkg if empty.
      # - postInstall.
      # Notes:
      # - Do we need to rm libdir? At least opam should be always installed?
      installPhase = ''
        echo "+ installPhase: ${dep.name}-${dep.version}"
        runHook preInstall

        echo "+ installPhase: Creating $OCAMLFIND_DESTDIR/${dep.name}"
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
          echo "+ installPhase: Moving $out/lib/${dep.name} to $OCAMLFIND_DESTDIR"
          mv "$out/lib/${dep.name}" "$OCAMLFIND_DESTDIR"
        fi

        # Remove OCAMLFIND_DESTDIR/pkg tree if empty.
        echo "+ installPhase: Removing empty $OCAMLFIND_DESTDIR/${dep.name} tree..."
        rmdir -v "$out/lib/ocaml/${ocaml.version}/site-lib/${dep.name}" \
          && rmdir -v "$out/lib/ocaml/${ocaml.version}/site-lib" \
          && rmdir -v "$out/lib/ocaml/${ocaml.version}" \
          && rmdir -v "$out/lib/ocaml" \
          && rmdir -v "$out/lib" \
          || true

        runHook postInstall
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

  shell = pkg:
    pkgs.mkShell {
      OCAMLPATH = pkg.OCAMLPATH;
      inputsFrom = [ pkg ];
    };
}
