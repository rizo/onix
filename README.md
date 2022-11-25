# onix

Build OCaml projects with Nix.

> Note: this project is experimental. The core functionality is stable but the API may break before the official release.


See onix usage examples at https://github.com/odis-labs/onix-examples.


## Development setup dependencies

Development setup dependencies can be added to your opam files using the [`{with-dev-setup}`](https://opam.ocaml.org/doc/Manual.html#pkgvar-with-dev-setup) flag.

### 1. Add your development setup packages:

```opam
depends: [
  ...
  "ocaml-lsp-server" {with-dev-setup}
  "ocamlformat" {with-dev-setup}
]
```


## OCaml compilers

- `ocaml-system` - use the compiler provided by nixpkgs;
- `ocaml-variants` - build a custom opam compiler;
- `ocaml-base-compiler` - build an opam compiler with vanilla options.


## Nix API Reference

### `onix.project`

```nix
let project = onix.project ./. {
  # The paths of the root opam files.
  # Will lookup all at the project root dir by default.
  roots ? [ ],

  # The path of the lock file. Must be in the root dir of the project.
  lock ? "onix-lock.json",

  # The URLs of OPAM package repositories.
  repositories ? [ "https://github.com/ocaml/opam-repository.git" ],

  # Additional dependency resolutions.
  resolutions ? { },

  # Package overrides.
  overrides ? null,

  # Verbosity of the onix tool.
  verbosity ? "warning",

  # Flags for dependency resolution.
  flags ? {
    with-test = false;
    with-doc = false;
    with-dev-setup = false;
  };

  # Apply gitignore filter to project directory.
  # Possible values: true, false, path to gitignore file.
  gitignore ? true
};
```

The return type of `onix.project` is a set with the following attributes:

```nix
# Resolve dependencies and generate a lock file.
project.lock

# A package set with all project packages.
project.pkgs

# Build all root pacakges.
project.all

# Start a shell for root packages.
project.shell
```
