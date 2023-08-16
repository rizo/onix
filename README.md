# onix

Build OCaml projects with Nix.

> Note: this project is experimental. The core functionality is stable but the API may break before the official release.

Onix provides a [Nix](https://nixos.org/download.html) powered workflow for working with opam projects.

## Features

- Fully hermetic and deterministic builds based on a precise lock file.
- Robust cross-project cache powered by Nix store.
- Support for `pin-depends` to add packages outside of the opam repository.
- Supoort for automated `depexts` installation from nixpkgs.
- Conditional compilation of `with-test`, `with-doc` and `with-dev-setup` dependencies.
- Support for compiler variants similar to opam (for example, the flambda compiler can be used).
- Compilation of vendored packages.
- Generation of opam-compatible "locked" files.

See onix usage examples at https://github.com/rizo/onix-examples.


## Usage

Create `default.nix` in your OCaml project where opam files are located:

```nix
let
  # Obtain the latest onix package.
  onix = import (builtins.fetchGit {
    url = "https://github.com/odis-labs/onix.git";
    rev = "caccd787b2c494545d0e4fcee130ed60bfba29d0";
  }) { verbosity = "info"; };

# Create your project environment.
in onix.env {
  # The path where opam files are looked up.
  path = ./.;

  # Optional: dependency variables to be used during lock generation.
  vars = {
    "with-test" = true;
    "with-doc" = true;
    "with-dev-setup" = true;
  };
}
```

Generate a lock file:
```shell
$ nix develop -f default.nix lock
# This generates ./onix-lock.json
```

Start a development shell:
```shell
$ nix develop -f default.nix -j auto -i -v shell
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
onix.env {
  vars = {
    "with-dev-setup" = true;
  };
}
```

Regenreate the lock file. This will add the development setup packages to your
shell environment.


## OCaml compilers

The following compiler packages are supported:
- `ocaml-system` - Use the compiler provided by nixpkgs. This is the default compiler used by onix. Using this option avoids building the compiler from scratch.
- `ocaml-variants` - Build a custom opam compiler. Can be used to build [variations of the compiler](https://discuss.ocaml.org/t/experimental-new-layout-for-the-ocaml-variants-packages-in-opam-repository/6779).
- `ocaml-base-compiler` - Build an opam compiler with vanilla options. This is the compiler normally used by opam.

Add the compiler package to the `deps` field in your `default.nix` file with
any additional compiler options packages:

```nix
onix.env {
  deps = {
    "ocaml-variants" = "<5.0";
    "ocaml-option-flambda" = "*";
  };
}
```

This will build the compiler with flambda support. You can find the list of all supported options packages [here](https://ocaml.org/p/ocaml-variants/latest#used-by).


## Vendoring packages

Create a `./vendor` folder and clone or copy the projects you want to vendor there.

Update the `deps` field in your `default.nix` file to point to the vendored opam files:

```nix
onix.env {
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
# Create an onix environtment for your opam project.
onix.env {
  # List opam repositories.
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
  repos = [{ url = "https://github.com/ocaml/opam-repository.git";}];

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
  # By default, the ocaml-system package (i.e. from nixpkgs) is used in deps.
  # Example: `deps = { "dune" = ">3.6"; };`
  deps = { "ocaml-system" = "*"; };

  # The path to the onix lock file.
  # Example: `lock = ./my-custm-lock.json;`
  lock = "onix-lock.json";

  # The path for generation of the opam "locked" file.
  # Example: `opam-lock = ./my-project.opam.locked;`
  opam-lock = null;

  # Package variables.
  vars = {
    "with-test" = false;
    "with-doc" = false;
    "with-dev-setup" = false;
  };

  # Generate an .env file with the $PATH variable when the shell is invoked. Disabled by default.
  # Note that this file should be added to .gitignore as it's system-specific.
  # Example: `env-file = ./.onix.env;`
  env-file = null;

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

# The env itself is a target that builds all root packages.
env
```


## OCaml Platform integration

### Terminal-based editors

You can start your editor from the nix shell to make sure it has all the tools for OCaml LSP to work.

```shell
[onix]$ vim .
```

### VS Code

You can open VS Code from the nix shell environment:

```shell
[onix]$ code .
```

Alternatively you can pass the `env-file` parameter to `onix.env` to generate a static file containing the `PATH` of the development setup packages.

```nix
onix.env {
  # ...
  env-file = ./.onix.env;
}
```

This file is regenerated everytime you open your nix shell, so make sure to open the nix shell at least once before opening VS Code.

Set up the OCaml Platform extension to source this file before executing any
commands:

> Note: Remember to replace `YOUR_PROJECT_FOLDER` by your project folder name.

```json
{
  "ocaml.sandbox": {
    "kind": "custom",
    "template": "source ${workspaceFolder:YOUR_PROJECT_FOLDER}/.onix.env; $prog $args"
  }
}
```

