{ pkgs ? import <nixpkgs> { }, onix }:

let
  defaultRepoUrl = "https://github.com/ocaml/opam-repository.git";
  defaultLockFile = "./onix-lock.nix";
  defaultLogLevel = "debug";
  defaultOverlay = import ./overlays/default.nix pkgs;

  inherit (builtins)
    filter trace hasAttr getAttr setAttr attrNames attrValues concatMap
    pathExists foldl';
  inherit (pkgs) lib stdenv;
  inherit (pkgs.lib) optionalString;
  inherit (pkgs.lib.attrsets) mapAttrs';
  inherit (pkgs.lib.lists) optional optionals;

  pkgsUnion = l1: l2:
    let
      l1Attrs =
        foldl' (acc: x: if acc ? x.name then acc else acc // { ${x.name} = x; })
        { } l1;
      unionAttrs =
        foldl' (acc: x: if acc ? x.name then acc else acc // { ${x.name} = x; })
        l1Attrs l2;
    in attrValues unionAttrs;

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

  fetchSrc = { projectRoot, gitignore ? null }:
    name: src:
    let urlLen = builtins.stringLength src.url;
    in if lib.strings.hasPrefix "file://" src.url then
    # local url
      let
        path = builtins.substring 7 (urlLen - 7) src.url;
        projectPath = if path == "." || path == "./." || path == "./" then
          projectRoot
        else
          "${projectRoot}/path";
      in (if isNull gitignore then
        projectPath
      else if gitignore == ".gitignore" then
        pkgs.nix-gitignore.gitignoreSource [ ] projectPath
      else
        pkgs.nix-gitignore.gitignoreSourcePure [ gitignore ] projectPath)
    else if lib.strings.hasPrefix "git+" src.url then
    # git url
      builtins.fetchGit {
        url = builtins.substring 4 (urlLen - 4) src.url;
        inherit (src) rev;
        allRefs = true;
      }
    else if lib.strings.hasPrefix "http" src.url then
    # http url
      pkgs.fetchurl src
    else
      throw "invalid src for package ${name}: ${builtins.toJSON src}";

  # Build a package from a lock dependency.
  buildPkg = { projectRoot, scope, withTest, withDoc, withDevSetup }:
    dep:
    let
      ocaml = scope.ocaml;

      dependsPkgs = map (dep': scope.${dep'}) (dep.depends or [ ]);
      buildPkgs = map (dep': scope.${dep'}) (dep.buildDepends or [ ]);
      testPkgs = map (dep': scope.${dep'}) (dep.testDepends or [ ]);
      docPkgs = map (dep': scope.${dep'}) (dep.docDepends or [ ]);
      devSetupPkgs = map (dep': scope.${dep'}) (dep.devSetupDepends or [ ]);

      # Ex: "ocaml-ng.ocamlPackages_4_14.ocaml" -> pkgs.ocaml-ng.ocamlPackages_4_14.ocaml
      depexts = concatMap (pkgKey:
        let pkgPath = (lib.strings.splitString "." pkgKey);
        in lib.lists.toList (lib.attrsets.attrByPath pkgPath [ ] pkgs))
        (dep.depexts or [ ]);

      src = if dep ? src then
        fetchSrc { inherit projectRoot; } dep.name dep.src
      else
        null;

      flags = dep.flags or [ ];

      onixPathHook = pkgs.makeSetupHook { name = "onix-path-hook"; }
        (pkgs.writeText "onix-path-hook.sh" ''
          [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0

          addTargetOCamlPath () {
            local libdir="$1/lib/ocaml/${ocaml.version}/site-lib"

            if [[ ! -d "$libdir" ]]; then
              return 0
            fi

            addToSearchPath "OCAMLPATH" "$libdir"
            addToSearchPath "CAML_LD_LIBRARY_PATH" "$libdir/stublibs"
          }

          addEnvHooks "$targetOffset" addTargetOCamlPath
        '');

      dependsAndBuildPkgs = pkgsUnion dependsPkgs buildPkgs;

    in stdenv.mkDerivation {
      inherit src;
      pname = dep.name;
      version = dep.version;
      dontUnpack = isNull src;
      strictDeps = true;
      dontStrip = false;

      checkInputs = optionals (evalDepFlag dep.version withTest) testPkgs;
      nativeBuildInputs = [ onixPathHook ]
        ++ optionals (evalDepFlag dep.version withTest) testPkgs
        ++ optionals (evalDepFlag dep.version withDoc) docPkgs
        ++ optionals (evalDepFlag dep.version withDevSetup) devSetupPkgs;

      propagatedBuildInputs = dependsAndBuildPkgs ++ depexts;
      propagatedNativeBuildInputs = buildPkgs ++ depexts;

      ONIX_LOG_LEVEL = defaultLogLevel;
      ONIXPATH = lib.strings.concatStringsSep ":" dependsAndBuildPkgs;

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
  buildScope = { projectRoot, withTest, withDoc, withDevSetup }:
    deps:
    pkgs.lib.makeScope pkgs.newScope (self:
      (mapAttrs' (_name: dep: {
        name = dep.name;
        value = buildPkg {
          inherit projectRoot withTest withDoc withDevSetup;
          scope = self;
        } dep;
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
  private = { };

  build = { projectRoot, lockFile ? projectRoot ++ "/onix-lock.nix"
    , overrides ? null, logLevel ? defaultLogLevel, withTest ? false
    , withDoc ? false, withDevSetup ? false }:
    let
      deps = import lockFile { inherit pkgs; };
      scope =
        buildScope { inherit projectRoot withTest withDoc withDevSetup; } deps;
    in applyOverrides scope overrides;

  lock = { repoUrl ? defaultRepoUrl, resolutions ? null
    , lockFile ? defaultLockFile, logLevel ? defaultLogLevel, withTest ? false
    , withDoc ? false, withDevSetup ? false, opamFiles ? [ ] }:
    let
      opamFilesStr = lib.strings.concatStrings
        (map (f: " " + builtins.toString f) opamFiles);
    in pkgs.mkShell {
      buildInputs = [ onix ];
      shellHook = if isNull resolutions then ''
        onix lock \
          --repo-url='${repoUrl}' \
          --lock-file='${builtins.toString lockFile}' \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --verbosity='${logLevel}'${opamFilesStr}
        exit $?
      '' else ''
        onix lock \
          --repo-url='${repoUrl}' \
          --resolutions='${mkResolutionsArg resolutions}' \
          --lock-file='${builtins.toString lockFile}' \
          --with-test=${builtins.toJSON withTest} \
          --with-doc=${builtins.toJSON withDoc} \
          --with-dev-setup=${builtins.toJSON withDevSetup} \
          --verbosity='${logLevel}'${opamFilesStr}
        exit $?
      '';
    };
}
