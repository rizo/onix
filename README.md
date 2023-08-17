# onix

Build OCaml projects with Nix.

> **NOTE**
> This project is experimental. The core functionality is stable but the API may break before the official release.

Onix provides a [Nix](https://nixos.org/download.html) powered workflow for working with opam projects.

## Features

- Fully hermetic and deterministic builds based on a precise lock file.
- Robust cross-project cache powered by Nix store.
- Support for `pin-depends` to add packages outside of the opam repository.
- Support for automated `depexts` installation from nixpkgs.
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
    url = "https://github.com/rizo/onix.git";
    rev = "2ba70cf1b11826fd4bd920269dc9613ed427febd";
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

  # Optional: specify the compiler version for the build environment.
  deps = { "ocaml-base-compiler" = "*"; };
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

Some of these actions are included in the [`Makefile.template`](https://github.com/rizo/onix/blob/master/Makefile.template) you can copy into
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


## Specifying an OCaml compiler package

The list of stable OCaml package versions can be consulted at https://ocaml.org/p/ocaml.

To pick a compiler version for the build environment, add the `ocaml` package to the `deps` field:

```nix
onix.env {
  deps = {
    "ocaml" = "5.2.0";
  };
}
```

This will build the specified ocaml compiler from source.

> **NOTE**
> The specified version must be compatible with the constraints found in the project's opam files. Generally it is a good idea to have loose constraints for the ocaml package in opam files.


### Other compiler packages

Alternatively, if you wish to have more freedom over the selection of the compiler,
the following compiler packages are supported:
- [`ocaml-system`](https://ocaml.org/p/ocaml-system/latest) - Use the compiler provided by nixpkgs. This might avoid building the compiler from source since it's normally included in the official Nix build cache. Note that the nixpkgs repository isn't always in sync with opam repository so recent compiler versions will not be available in nixpkgs.
- [`ocaml-variants`](https://ocaml.org/p/ocaml-variants/latest) - Build a custom opam compiler. Can be used to build [variations of the compiler](https://discuss.ocaml.org/t/experimental-new-layout-for-the-ocaml-variants-packages-in-opam-repository/6779).
- [`ocaml-base-compiler`](https://ocaml.org/p/ocaml-base-compiler/latest) - Build an opam compiler with vanilla options. This is the compiler normally used by opam.

To specify the compiler package, add an entry to the `deps` field in your `default.nix` file with any additional compiler options packages:

```nix
onix.env {
  deps = {
    "ocaml-variants" = "<5.0";
    "ocaml-option-flambda" = "*";
  };
}
```

This will build the compiler with flambda support. You can find the list of all supported options packages [here](https://ocaml.org/p/ocaml-variants/latest#used-by).


## External dependencies

External dependencies of the opam packages are looked up in [`nixpkgs`](https://search.nixos.org/packages).

If the opam file of a dependency has a dedicated entry under [`depexts`](https://opam.ocaml.org/doc/Manual.html#opamfield-depexts) for NixOS (specified as `os-distribution = "nixos"`), onix will include that dependency in the lock file and in the build environment.

Alternatively, onix will use packages specified for other os distributions as optional dependencies. The hope here is that the name of the depext might match the name of the package in `nixpkgs`.

Finally, if you wish to precisely control the external dependencies, you can provide an overlay that specifies the exact packages to be used. For example:

```nix
onix.env {
  # ...
  overlay = self: super: {
    my_dep = super.my_dep.overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
        ++ [ pkgs.my_depext ];
    });
  };
}
```

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


## Overriding packages

Any package in the onix build scope can be overridden using overlays.

In the following example, a pre-patch action is added to the `zarith` package.

```nix
onix.env {
  # ...
  overlay = self: super: {
    zarith = super.zarith.overrideAttrs (oldAttrs: {
      prePatch = (oldAttrs.prePatch or "") + ''
        if test -e ./z_pp.pl; then
          patchShebangs ./z_pp.pl
        fi
      '';
    });
  };
}
```

Onix comes with a small number of default overrides that fix issues for popular packages. If an opam dependency you are building fails to compile, it might need to be patched or made compatible with nix.

The default overlay can be found at https://github.com/rizo/onix/blob/master/nix/overlay/default.nix. PRs with fixes for other opam packages are welcome!


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
  # Example: `deps = { "ocaml-system" = "*"; "dune" = ">3.6"; };`
  deps = { };

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

> **Note**
> The `.onix.env` file contains host-specific paths of the onix environment. Do not commit this file and add it to your `.gitignore`.

Set up the OCaml Platform extension to source this file before executing any
commands:

> **Note**
> Remember to replace `YOUR_PROJECT_FOLDER` by your project folder name.

```json
{
  "ocaml.sandbox": {
    "kind": "custom",
    "template": "source ${workspaceFolder:YOUR_PROJECT_FOLDER}/.onix.env; $prog $args"
  }
}
```

