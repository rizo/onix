# onix

Build OCaml projects with Nix.

> Note: this project is experimental. The core functionality is stable but the API may break before the official release.

## Quickstart

### 1. Create the `./nix/onix.nix` file:

```nix
import (builtins.fetchTarball "https://github.com/odis-labs/onix/archive/master.tar.gz")
```

### 2. Generate a lock file for your project:

```bash
$ nix-shell -A lock ./nix/onix.nix
...
onix: [INFO] Created a lock file at "./onix-lock.nix".
```

### 3. Create the `./default.nix` file:

```nix
let onix = import ./nix/onix.nix { }; in
onix.build { lockFile = ./onix-lock.nix; }
```

### 4. Build your project:

```bash
$ nix-build -A my-project-name
$ ls ./result
```

For more examples of usage see the https://github.com/odis-labs/onix-examples repository.


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

### 2. Update your lock file:

```
$ nix-shell -A lock ./nix/onix.nix
```

### 3. Start a develpoment shell:

```bash
$ nix-shell -A shell
```


## OCaml compilers


- `ocaml-system` - use the compiler provided by nixpkgs;
- `ocaml-variants` - build a custom opam compiler;
- `ocaml-base-compiler` - build an opam compiler with vanilla options.


## Nix API Reference

### `onix.project`

```nix
let project = onix.project {
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

  # Dependency flags for resolution.
  flags ? {
    with-test = false;
    with-doc = false;
    with-dev-setup = false;
  }
};
```

The return type of `onix.project` is a set with the following attributes:

```nix
# Resolve dependencies and generate a lock file.
project.lock

# A package set with all project packages.
project.pkgs

# A package set with all root pacakges.
project.roots

# A package set with all root pacakges.
project.build {
  with-test = true;
  with-doc = true;
  with-dev-setup = true;
}

# Start a development shell for root packages.
project.shell
```
