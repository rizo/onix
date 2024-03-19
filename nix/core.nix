{ pkgs ? import <nixpkgs> { }, verbosity ? "debug", onix }:

let
  debug = data: x: builtins.trace "onix: [DEBUG] ${builtins.toJSON data}" x;
  defaultOverlay = import ./overlay/default.nix pkgs;

  inherit (builtins)
    trace hasAttr getAttr setAttr attrNames attrValues concatMap pathExists
    foldl';
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

  # We require that the version does NOT contain any '-' or '~' characters.
  # - Note that nix will replace '~' to '-' automatically.
  # The version is parsed with Nix_utils.parse_store_path by splitting bytes
  # '- ' to obtain the Pkg_ctx.package information.
  # This is fine because the version in the lock file is mostly informative.
  normalizeVersion = version:
    builtins.replaceStrings [ "-" "~" ] [ "+" "+" ] version;

  fetchSrc = { rootPath, name, src }:
    let urlLen = builtins.stringLength src.url;
    in if lib.strings.hasPrefix "file://" src.url then
    # local url
      let
        path = builtins.substring 7 (urlLen - 7) src.url;
        projectPath = if path == "." || path == "./." || path == "./" then
          rootPath
        else
          "${rootPath}/${path}";
      in (if pathExists "${projectPath}/.gitignore" then
        pkgs.nix-gitignore.gitignoreSource [ ] projectPath
      else
        projectPath)
    else if lib.strings.hasPrefix "git+" src.url then
    # git url
      builtins.fetchGit {
        url = builtins.substring 4 (urlLen - 4) src.url;
        inherit (src) rev;
        allRefs = true;
        submodules = true;
      }
    else if lib.strings.hasPrefix "http" src.url then
    # http url
      pkgs.fetchurl src
    else
      throw "invalid src for package ${name}: ${builtins.toJSON src}";

  getOpamFile = { repoPath, src, name, version }:
    if version == "dev" then
      if pathExists "${src}/${name}.opam" then
        "${src}/${name}.opam"
      else if pathExists "${src}/opam" then
        "${src}/opam"
      else
        throw "could not find opam file for package ${name} in ${src}"
    else
      let
        # Copy the path into nix store to avoid depending on repoPath.
        nixPath = builtins.path {
          name = "${name}-${normalizeVersion version}-opam";
          path = "${repoPath}/packages/${name}/${name}.${version}";
        };
      in "${nixPath}/opam";

  # Build a package from a lock dependency.
  buildPkg = { rootPath, repoPath, scope }:
    name: dep:
    let
      ocaml = scope.ocaml;

      vars = {
        "with-test" = false;
        "with-doc" = false;
        "with-dev-setup" = false;
      } // (if dep ? "vars" then dep.vars else { });

      dependsPkgs = map (dep': scope.${dep'}) (dep.depends or [ ]);
      buildPkgs = map (dep': scope.${dep'}) (dep.build-depends or [ ]);
      testPkgs = map (dep': scope.${dep'}) (dep.test-depends or [ ]);
      docPkgs = map (dep': scope.${dep'}) (dep.doc-depends or [ ]);
      devSetupPkgs = map (dep': scope.${dep'}) (dep.dev-setup-depends or [ ]);

      # Ex: "ocaml-ng.ocamlPackages_4_14.ocaml" -> pkgs.ocaml-ng.ocamlPackages_4_14.ocaml
      depexts = concatMap (pkgKey:
        let pkgPath = (lib.strings.splitString "." pkgKey);
        in lib.lists.toList (lib.attrsets.attrByPath pkgPath [ ] pkgs))
        (dep.depexts or [ ]);

      src = if dep ? src then
        fetchSrc {
          inherit rootPath name;
          inherit (dep) src;
        }
      else
        null;

      opam = getOpamFile {
        inherit repoPath src name;
        inherit (dep) version;
      };

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
      pname = name;
      version = normalizeVersion dep.version;
      dontUnpack = isNull src;
      strictDeps = true;
      dontStrip = false;

      checkInputs = testPkgs;
      nativeBuildInputs = [ onixPathHook ] ++ testPkgs ++ docPkgs
        ++ devSetupPkgs;

      propagatedBuildInputs = dependsAndBuildPkgs ++ depexts;
      propagatedNativeBuildInputs = buildPkgs ++ depexts;

      ONIX_LOG_LEVEL = verbosity;
      ONIXPATH = lib.strings.concatStringsSep ":" dependsAndBuildPkgs;

      prePatch = ''
        ${onix}/bin/onix opam-patch \
          --ocaml-version=${ocaml.version} \
          --opam=${opam} \
          --path=$out \
          --verbosity=${verbosity} \
          ${name}.${dep.version}
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
          --opam=${opam} \
          --with-test=${builtins.toJSON vars.with-test} \
          --with-doc=${builtins.toJSON vars.with-doc} \
          --with-dev-setup=${builtins.toJSON vars.with-dev-setup} \
          --path=$out \
          --verbosity=${verbosity} \
          ${name}.${dep.version}

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
        if [[ -e "./${name}.config" ]]; then
          mkdir -p "$out/etc"
          cp "./${name}.config" "$out/etc/${name}.config"
        fi

        mkdir -p "$OCAMLFIND_DESTDIR/${name}"

        ${onix}/bin/onix opam-install \
          --ocaml-version=${ocaml.version} \
          --opam=${opam} \
          --with-test=${builtins.toJSON vars.with-test} \
          --with-doc=${builtins.toJSON vars.with-doc} \
          --with-dev-setup=${builtins.toJSON vars.with-dev-setup} \
          --path=$out \
          ${name}.${dep.version}

        if [[ -e "$out/lib/${name}/META" ]] && [[ ! -e "$OCAMLFIND_DESTDIR/${name}" ]]; then
          mv "$out/lib/${name}" "$OCAMLFIND_DESTDIR"
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

  # Apply default and user-provided overlay to the scope.
  applyOverrides = scope: overlay:
    let
      overlay' = if isNull overlay then
        defaultOverlay
      else
        self: super: defaultOverlay self super // overlay self super;
    in scope.overrideScope' overlay';

  joinRepositories = repositories:
    if builtins.length repositories == 1 then
      builtins.fetchGit (builtins.head repositories)
    else if repositories == [ ] then
      throw "No opam repositories found!"
    else
      pkgs.symlinkJoin {
        name = "onix-opam-repository";
        paths = map builtins.fetchGit repositories;
      };

in {
  lock =
    { lockPath, opamLockPath, opamFiles, repositoryUrls, constraints, vars }:
    let
      repositoryUrlsArg = lib.strings.concatStringsSep "," (map (repositoryUrl:
        if repositoryUrl ? "rev" then
          lib.strings.concatStringsSep "#" [
            repositoryUrl.url
            repositoryUrl.rev
          ]
        else
          repositoryUrl.url

      ) repositoryUrls);

      # Opam files argument.
      opamFilesArg = if builtins.length opamFiles > 0 then
        " " + lib.strings.concatStringsSep " " opamFiles
      else
        "";

      lockPathOpt = if isNull lockPath then
        " --lock-file=/dev/null"
      else
        " --lock-file=${lockPath}";
      opamLockPathOpt =
        if isNull opamLockPath then "" else " --opam-lock-file=${opamLockPath}";

    in pkgs.mkShell {
      buildInputs = [ onix ];
      shellHook = ''
        onix lock${lockPathOpt}${opamLockPathOpt} \
          --repository-urls='${repositoryUrlsArg}' \
          --resolutions='${mkResolutionsArg constraints}' \
          --with-test=${builtins.toJSON vars.with-test} \
          --with-doc=${builtins.toJSON vars.with-doc} \
          --with-dev-setup=${builtins.toJSON vars.with-dev-setup} \
          --verbosity='${verbosity}'${opamFilesArg}
        exit $?
      '';
    };

  build = { rootPath, lockPath, overlay }:
    let
      lock = lib.importJSON lockPath;
      repositories = lock.repositories;
      repoPath = joinRepositories repositories;
      deps = lock.packages;

      # Build a package scope from the locked deps.
      scope = pkgs.lib.makeScope pkgs.newScope (self:
        (mapAttrs' (name: dep: {
          inherit name;
          value = buildPkg {
            inherit rootPath repoPath;
            scope = self;
          } name dep;
        }) deps));
    in applyOverrides scope overlay;
}
