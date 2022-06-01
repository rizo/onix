# onix

Build OCaml projects with Nix.

## Quickstart

1. Create the `./nix/onix.nix` file:

```nix
import (builtins.fetchTarball "https://github.com/odis-labs/onix/archive/master.tar.gz")
```

2. Generate a lock file for your project:

```bash
$ nix-shell -A lock ./nix/onix.nix
...
onix: [INFO] Created a lock file at "./onix-lock.nix".
```

3. Create the `./default.nix` file:

```nix
let onix = import ./nix/onix.nix { }; in
onix.build { lockFile = ./onix-lock.nix; }
```

4. Build your project:

```bash
$ nix-build -A my-project-name
$ ls ./result
```


## Using development tools

Development tools can be added to your opam files using the [`{with-tools}`](https://opam.ocaml.org/doc/Manual.html#pkgvar-with-tools) flag.

1. In the `depends` section of your opam file add your development packages:

```opam
depends: [
  ...
  "ocaml-lsp-server" {with-tools}
  "ocamlformat" {with-tools}
]
```

2. Update your lock file.

3. Start a develpoment shell:

```bash
$ nix-shell -A shell
```
