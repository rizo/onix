{ pkgs ? import <nixpkgs> { }, onix, verbosity }:

let
  inherit (pkgs) lib;
  inherit (builtins) isNull isList isAttrs isString isPath isFunction length;

  debug = data: x: builtins.trace "onix: [DEBUG] ${builtins.toJSON data}" x;

  core = import ./core.nix { inherit pkgs onix verbosity; };

  # Errors.
  errInvalidSrc = name:
    "onix: invalid ${name} argument, must be an attribute set with `url` key";
  errInvalidRootPath = "onix: path argument must be a path or a null value";
  errInvalidGitignoreType = "onix: gitignore argument must be a path or a bool";
  errInvalidGitignoreMissing = path:
    "onix: provided gitignore file does not exist: ${path}";
  errInvalidReposType = "onix: repos argument must be a list";
  errInvalidOpamFilePath =
    "onix: invalid opam file path, must be opam or end with `.opam`";
  errInvalidRoots =
    "onix: roots argument must be a list of paths to opam files";
  errInvalidDeps = "onix: deps argument must be an attrset";
  errInvalidDep = name:
    "onix: invalid dep ${name}: must be a constraint, an opam file, a git src or a pacakge";
  errInvalidLock = lock:
    "onix: lock argument must be a path or a null value, found: ${
      builtins.toJSON lock
    }";
  errInvalidVars =
    "onix: vars argument must be an attrset with test, doc or dev-setup keys";
  errInvalidOverlay = "onix: overlay must be a function or a null value";
  errRequiredRootPath =
    "onix: path argument is required when opam files are provided in deps or in roots";

  # Classify deps.

  depIsConstraint = isString;

  checkIsOpamPath = path:
    if isPath path then
      if lib.strings.hasSuffix "opam" path then
        true
      else
        throw errInvalidOpamFilePath
    else
      false;

  depIsSrc = dep:
    if isAttrs dep then
      if builtins.hasAttr "url" dep then true else throw errInvalidSrc "dep"
    else
      false;

  depIsDrv = lib.attrsets.isDerivation;

  checkHasOpamDeps = deps:
    length (lib.attrsets.attrValues
      (lib.attrsets.filterAttrs (_n: checkIsOpamPath) deps)) > 0;

  # Validate arguments.

  validateSrc = name: src:
    if isAttrs src && builtins.hasAttr "url" src then
      src
    else
      throw (errInvalidSrc name);

  validateRootPath = hasOpamDeps: rootPath:
    if (isNull rootPath) && hasOpamDeps then
      throw errRequiredRootPath
    else if isPath rootPath then
      builtins.toString rootPath
    else if isNull rootPath then
      rootPath
    else
      throw errInvalidRootPath;

  validateGitignore = gitignore:
    if isPath gitignore then
      if builtins.pathExists gitignore then
        gitignore
      else
        throw (errInvalidGitignoreMissing gitignore)
    else if builtins.isBool gitignore then
      gitignore
    else
      throw errInvalidGitignoreType;

  validateRoots = roots:
    if isNull roots then
      roots
    else if isList roots then
      builtins.map (root:
        if checkIsOpamPath root then
          builtins.toString root
        else
          throw errInvalidRoots) roots
    else
      throw errInvalidRoots;

  validateRepos = srcList:
    if isList srcList then
      builtins.map (validateSrc "repos") srcList
    else
      throw errInvalidReposType;

  validateDep = name: dep:
    if depIsConstraint dep || depIsDrv dep || checkIsOpamPath dep
    || depIsSrc dep then
      dep
    else
      throw (errInvalidDep name);

  validateDeps = deps:
    if isAttrs deps then
      builtins.mapAttrs validateDep deps
    else
      throw errInvalidDeps;

  validateLock = lock:
    if isString lock || isPath lock || isNull lock then
      lock
    else
      throw (errInvalidLock lock);

  validateVars = vars: if isAttrs vars then vars else throw errInvalidVars;

  validateOverlay = overlay:
    if isFunction overlay || isNull overlay then
      overlay
    else
      throw errInvalidOverlay;

  # Process arguments.

  processRootPath = { gitignore, rootPath }:
    if isPath gitignore then
      pkgs.nix-gitignore.gitignoreSourcePure [ gitignore ]
      (builtins.toString rootPath)
    else if builtins.isBool gitignore && gitignore
    && builtins.pathExists "${builtins.toString rootPath}/.gitignore" then
      pkgs.nix-gitignore.gitignoreSource [ ] rootPath
    else
      builtins.toString rootPath;

  lookupRoots = rootPath:
    lib.attrsets.mapAttrsToList (filename: _type: filename)
    (lib.attrsets.filterAttrs (filename: _type:
      filename != ".opam" && lib.strings.hasSuffix ".opam" filename)
      (builtins.readDir rootPath));

  processRoots = rootPath: roots:
    if isNull rootPath && !(isNull roots) && length roots > 0 then
    # roots requires path
      throw errRequiredRootPath
    else if !(isNull rootPath) && !(isNull roots) && length roots > 0 then
    # Use provided roots if path is set too.
      roots
    else if !(isNull rootPath) && isNull roots then
    # Lookup roots in path if roots is null (default)
      lookupRoots rootPath
    else
    # No roots otherwise.
      [ ];

  processLock = rootPath: lock:
    if isNull lock then
      null
    else if isPath lock then
      builtins.toString lock
    else if isString lock then
      rootPath + "/" + lock
    else
      lock;

  processVars = vars:
    {
      test = false;
      doc = false;
      dev-setup = false;
    } // vars;

  # Extract opam path deps. The extracted opam file path is relative to the root dir.
  extractOpamDeps = rootPath: deps:
    lib.attrsets.mapAttrsToList (_name: dep:
      lib.strings.removePrefix (rootPath + "/") (builtins.toString dep))
    (lib.attrsets.filterAttrs (name: dep: checkIsOpamPath dep) deps);

  extractConstraintDeps = deps:
    (lib.attrsets.filterAttrs (name: dep: depIsConstraint dep) deps);

in {
  env = {
    # The repo to use for resolution.
    repo ? {
      url = "https://github.com/ocaml/opam-repository.git";
    }

    # List of additional or alternative repos.
    , repos ? [ ]

      # The path of the project where opam files are looked up.
    , path ? null

      # The path to project's root opam files. Will be looked up if null.
    , roots ? null

      # Apply gitignore to root directory: true|false|path.
    , gitignore ? true

      # List of additional or alternative deps.
      # A deps value can be:
      #   - a version constraint string;
      #   - a local opam file path;
      #   - a git source (an attrset with "url" name).
    , deps ? { }

      # The path to the onix lock file.
    , lock ? "onix-lock.json"

      # The path to the opam lock file.
    , opam-lock ? null

      # Package variables.
    , vars ? { }

      # A nix overlay to be applied to the built scope.
    , overlay ? null }:

    let
      validatedArgs = {
        repo = validateSrc "repo" repo;
        repos = validateRepos repos;
        rootPath = validateRootPath (checkHasOpamDeps validatedArgs.deps) path;
        roots = validateRoots roots;
        gitignore = validateGitignore gitignore;
        deps = validateDeps deps;
        lock = validateLock lock;
        vars = validateVars vars;
        opam-lock = validateLock opam-lock;
        overlay = validateOverlay overlay;
      };

      config = {
        repos = [ validatedArgs.repo ] ++ validatedArgs.repos;
        rootPath = validatedArgs.rootPath;
        rootPathWithGitignore =
          processRootPath { inherit (validatedArgs) gitignore rootPath; };
        opamFiles = (processRoots validatedArgs.rootPath validatedArgs.roots) ++ extractOpamDeps validatedArgs.rootPath validatedArgs.deps;
        constraints = extractConstraintDeps validatedArgs.deps;
        lockPath = processLock validatedArgs.rootPath validatedArgs.lock;
        opam-lock = processLock validatedArgs.rootPath validatedArgs.opam-lock;
        vars = processVars validatedArgs.vars;
        overlay = validatedArgs.overlay;
      };

      allPkgs = core.build {
        rootPath = config.rootPathWithGitignore;
        lockPath = config.lockPath;
        overlay = config.overlay;
      };

      targetPkgs =
        lib.attrsets.mapAttrs (name: _: allPkgs.${name}) validatedArgs.deps;

      # The default build target for the env: all root packages.
      links = pkgs.linkFarm (builtins.baseNameOf "onix-links") (map (r: {
        name = r.name;
        path = r;
      }) (lib.attrsets.attrValues targetPkgs));

    in {
      # Shell for generating a lock file.
      lock = core.lock {
        lockPath = config.lockPath;
        opamLockPath = config.opam-lock;
        repositoryUrls = config.repos;
        constraints = config.constraints;
        vars = config.vars;
        opamFiles = config.opamFiles;
      };

      pkgs = allPkgs;

      targets = targetPkgs;
    };
}
