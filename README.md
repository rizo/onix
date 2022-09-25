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


## Using development tools

Development tools can be added to your opam files using the [`{with-tools}`](https://opam.ocaml.org/doc/Manual.html#pkgvar-with-tools) flag.

### 1. Add your tools packages:

```opam
depends: [
  ...
  "ocaml-lsp-server" {with-tools}
  "ocamlformat" {with-tools}
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


### OCaml compilers


- `ocaml-system` - use the compiler provided by nixpkgs;
- `ocaml-variants` - build a custom opam compiler;
- `ocaml-base-compiler` - build an opam compiler with vanilla options.

