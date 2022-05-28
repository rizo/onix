# onix

Build OCaml projects with Nix.


## Creating a lock file

Create a lock file for all opam packages in the current directory:

```
$ onix lock
```

Create a lock file using a specific opam repository URL:

```
$ onix lock --repo-url=https://github.com/ocaml/opam-repository.git#52c72e08d7782967837955f1c50c330a6131721f
```

Create a lock file for specified opam packages only:

```
$ onix lock pkg-1.opam pkg-2.opam
```

Create a lock file including test, doc and development tools dependencies of a
root package:

```
$ onix lock pkg.opam --with-test --with-doc --with-tools
```

Create a lock file including:
* all test packages;
* doc packages of the dependencies; and
* development tools packages of the root package.

```
$ onix lock pkg.opam --with-test=all --with-doc=deps --with-tools=root
```


## Building packages

Build the root package and the required build and runtime dependencies:

```
$ onix build
```

Build only the dependencies of the root packages:

```
$ onix build --deps-only
```

Build a root package with the test, doc and development tools dependencies:

```
$ onix build pkg.opam --with-test --with-doc --with-tools
```

Build the specified opam packages only:

```
$ onix build pkg-1.opam pkg-2.opam
```


## Using the Nix API

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;

  # Create the scope with all of the packages.
  scope = onix.build {
    # Replace the locked ocaml compiler with the ocaml from nixpkgs.
    # This can avoid building the ocaml compiler in the lock file from source.
    ocaml = ocamlPackages.ocaml;

    # The path to the lock file.
    lock = ./onix-lock.nix;

    # Build the development tools of the root packages.
    withTools = true;

    # Run the tests for all the packages in the scope.
    withTest = "all";

    # Build the docs for all dependencies.
    withDoc = "deps";

    # Override some scope packages.
    overrides = {
      # Replace a locked package with a package from nixpkgs.
      dune = pkg: pkgs.dune_3;

      # Override derivation attributes.
      lwt_react = pkg:
        pkg.overrideAttrs (super: {
          nativeBuildInputs = super.nativeBuildInputs ++ [ scope.cppo or null ];
        });
    };

    # Change the log level during the build.
    logLevel = "debug";
  };
in

# Build a root package.
scope.my-pkg
```

