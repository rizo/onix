# onix

Build OCaml projects with Nix.

> Note: this project is experimental. The core functionality is stable but the API may break before the official release.

Onix provides a [Nix](https://nixos.org/download.html) powered workflow for working with opam projects.

## Features

- Fully hermetic and deterministic builds based on a precise lock file.
- Robust cross-project cache powered by Nix store.
- Support for `pin-depends` add add packages not published to the opam repository.
- Conditional compilation of `with-test`, `with-doc` and `with-dev-setup` dependencies.
- Support for compiler variants similar to opam (for example, the flambda compiler can be used).
- Compilation of vendored packages.
- Generation of opam-compatible "locked" files.

See onix usage examples at https://github.com/odis-labs/onix-examples.


## Usage

Create `default.nix` in your OCaml project where opam files are located:

```nix
{ pkgs ? import <nixpkgs> { } }:

let
  # Specify the "system" compiler (see below). This will be used to build your
  # project and onix itself.
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;

  # Obtain the latest onix version.
  onix = import (builtins.fetchGit {
    url = "https://github.com/odis-labs/onix.git";
    rev = "4453bd3e0398cc8b62161a3856634f64565119b5";
  }) {
    inherit pkgs ocamlPackages;
    verbosity = "warning";
  };

# Create your project environment.
in onix.env {
  # Optional: the path where opam files are looked up.
  path = ./.;

  # Optional: provide the opam repository URL.
  repo = {
    url = "https://github.com/ocaml/opam-repository.git";
    # Optional: specify the git commit to be used.
    rev = "ff615534bda0fbb06447f8cbb6ba2d3f3343c57e";
  };

  # Optional: additional dependencies. Here we add ocaml-system which is the
  # ocaml package from ocamlPackages mentioned above.
  deps = { "ocaml-system" = "*"; };
}
```

Generate a lock file:
```shell
$ nix develop -f default.nix lock
# This generates ./onix-lock.json
```

Start a development shell:
```shell
$ nix develop -f default.nix -j auto -i -k TERM -k PATH -k HOME -v shell
# Here you can start working on your project by calling `dune build` for example.
```

Build your root opam packages:
```shell
$ nix build -f default.nix -j auto -v
# This creates a ./result symlink with all your built packages.
```

Build a single package from your project scope:
```shell
$ nix build -f default.nix -j auto -v pkgs.dune
# This create a ./result symlik to the built package.
```

Some of these actions are included in the `Makefile.template` you can copy into
your project.


## Development setup dependencies

Development setup dependencies can be added to your opam files using the
[`{with-dev-setup}`](https://opam.ocaml.org/doc/Manual.html#pkgvar-with-dev-setup)
flag.

### 1. Add your development setup packages:

```opam
depends: [
  ...
  "ocaml-lsp-server" {with-dev-setup}
  "ocamlformat" {with-dev-setup}
]
```

Enable the `with-dev-setup` variable in your `default.nix` file:

```nix
{
  vars = {
    "with-dev-setup" = true;
  };
}
```

Regenreate the lock file. This will add the development setup packages to your
shell environment.


## OCaml compilers

- `ocaml-system` - use the compiler provided by nixpkgs;
- `ocaml-variants` - build a custom opam compiler;
- `ocaml-base-compiler` - build an opam compiler with vanilla options.

Add the compiler package to the `deps` field in your `default.nix` file with
any additional compiler options packages:

```nix
{
  deps = {
    "ocaml-variants" = "<5.0";
    "ocaml-option-flambda" = "*";
  };
}
```


## Vendoring packages

Create a `./vendor` folder and clone or copy the projects you want to vendor there.

Update the `deps` field in your `default.nix` file to point to the vendored opam files:

```nix
{
  deps = {
    "pkg-foo" = ./vendor/pkg-foo/foo.poam;
    "bar" = ./vendor/pkg-bar/opam;
  };
}
```

Regenreate the lock file. This will add the vendored packages to your build scope.


## Nix API Reference

### `onix.env`

```nix
onix.env {
  # The repo to use for resolution.
  repo = {
    url = "https://github.com/ocaml/opam-repository.git";
  };

  # List of additional or alternative repos.
  # Example:
  # ```
  # repos = [
  #   {
  #     url = "https://github.com/ocaml/opam-repository.git";
  #   }
  #   {
  #     url = "https://github.com/kit-ty-kate/opam-alpha-repository";
  #     rev = "0a81964b3d1e27a6aaf699e3a2153059b77435e2";
  #   }
  #   {
  #     url = "https://github.com/ocaml/ocaml-beta-repository.git";
  #     rev = "79aeeadd813bdae424ab53f882f08bee0a4e0b89";
  #   }
  # ];
  # ```
  repos = [ ];

  # The path of the project where opam files are looked up.
  # Example: `path = ./;`
  path = null;

  # The path to project's root opam files. Will be looked up if null.
  # Example: `roots = [ ./my-package.opam ./another.opam ];`
  roots = null;

  # Apply gitignore to root directory: true|false|path.
  # Example: `gitignore = ./.my-custom-ignore;`
  gitignore = true;

  # List of additional or alternative deps.
  # A deps value can be:
  #   - a version constraint string: "pkg" = ">2.0";
  #   - a local opam file path: "pkg" = ./vendor/pkg/opam;
  #   - a git source: "pkg" = { url = "https://github.com/user/repo.git" }.
  # Example: `deps = { "dune" = ">3.6"; };`
  deps = { };

  # The path to the onix lock file.
  # Example: `lock = ./my-custm-lock.json;`
  lock = "onix-lock.json";

  # The path to the opam lock file.
  # Example: `opam-lock = ./my-project.opam.locked;`
  opam-lock = null;

  # Package variables.
  vars = {
    "with-test" = false;
    "with-doc" = false;
    "with-dev-setup" = false;
  };

  # A nix overlay to be applied to the built scope.
  # Example:
  # ```
  # overlay = self: super: {
  #   "some-pkg" = super.some-pkg.overrideAttrs (superAttrs: {
  #     patches = oldAttrs.patches or [ ] ++ [ ./patches/some-pkg.patch ];
  #     buildInputs = superAttrs.buildInputs or [] ++ [ pkgs.foo ];
  #     postInstall = "...";
  #   });
  # };
  # ```
  overlay = null;
}
```

The return type of `onix.env` is a set with the following attributes:

```nix
# Resolve dependencies and generate a lock file.
env.lock

# A package set with all locked packages.
env.pkgs

# Start a shell for root packages.
env.shell
```

The `env` itself is a target that builds all root packages.


## OCaml Platform integration

### Terminal-based editors

You can start your editor from the nix shell to make sure it has all the tools for OCaml LSP to work.

### VS Code

Create a settings file to instruct OCaml Platform to use the nix environment:

> Note: Remember to replace `YOUR_PROJECT_FOLDER` by your project folder name.

```json
{
  "ocaml.sandbox": {
    "kind": "custom",
      "template": "nix develop -f ${workspaceFolder:YOUR_PROJECT_FOLDER}/default.nix -j auto -i shell -c $prog $args"
  }
}
```

