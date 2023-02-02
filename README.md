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

### `onix.env`

```nix
onix.env {
  # The repo to use for resolution.
  repo = {
    url = "https://github.com/ocaml/opam-repository.git";
  };

  # List of additional or alternative repos.
  repos = [ ];

  # The path of the project where opam files are looked up.
  path = null;

  # The path to project's root opam files. Will be looked up if null.
  roots = null;

  # Apply gitignore to root directory: true|false|path.
  gitignore = true;

  # List of additional or alternative deps.
  # A deps value can be:
  #   - a version constraint string: "pkg": ">2.0";
  #   - a local opam file path: "pkg": ./vendor/pkg/opam;
  #   - a git source: "pkg": { url = "https://github.com/user/repo.git" }.
  deps = { };

  # The path to the onix lock file.
  lock = "onix-lock.json";

  # The path to the opam lock file.
  opam-lock = null;

  # Package variables.
  vars = {
    "with-test" = false;
    "with-doc" = false;
    "with-dev-setup" = false;
  };

  # A nix overlay to be applied to the built scope.
  overlay = null;
}
```

The return type of `onix.env` is a set with the following attributes:

```nix
# Resolve dependencies and generate a lock file.
env.lock

# A package set with all project packages.
env.pkgs

# Start a shell for root packages.
env.shell
```

The `env` itself is a target that builds all root packages.
