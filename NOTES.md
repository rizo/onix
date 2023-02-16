# Notes

## DUNE_INSTALL_PREFIX

`export DUNE_INSTALL_PREFIX="$out"` is required for dune to know about the installation directory. Compiling dune with the standard commands from the opam file, but without this results in:

```
dune> ./dune.exe install    dune
dune> Error: The mandir installation directory is unknown.
dune> Hint: It could be specified with --mandir
dune> make: *** [Makefile:62: install] Error 1
```

This no longer seems to be the case? See onix#3a0dd9c221a62a0000c5e83c6cb557de51270780.


## Cache sharing with files

When copying files use `${./path}` instead of `${builtins.toString ./path}` to avoid having different paths hardcoded in the commands (like a `buildPhase`). This ensures that there are no project-specific inputs for nix.


## OCAMLFIND_DESTDIR

Packages that use ocamlfind for installation, require that `OCAMLFIND_DESTDIR` is set. For example zarith.


## `sys-ocaml-version`

Is only used in ocaml-system.3.07 and is not documented.


## opam vars

Opam variables can occur in multiple places:

- `build` field
- `depends` field
- `available` field
- other opam filed fields
- `.in` files as defined by the `substs` field in opam file (including patches);

This means that all of these places need their variables expanded with an appropriate scope. We cannot replace all of the variables during lock context generation because the system generating the lock file might be different from the system building the locked packages.

It is possible to partially evaluate some fixed variables, that are common between the host and build systems, and delay the evaluation of other variables to the build system. This means that our lock context needs to preserve some variables such as `os`, `arch` and potentially dep vars like `with-test`.

Performing this for opam file fields is relatively straightforward. See the expansion example below for an example:

```example.opam
build: [
 ["dune" "subst"] {pinned}

  [
    "dune"
    "build"
    "-p"
    name
    "-j"
    jobs
    "@install"
    "@runtest" {with-test}
    "@doc" {with-doc}
  ]

  ["./configure"] {os != "openbsd" & os != "freebsd" & os != "macos"}

  [
    "sh"
    "-exc"
    "LDFLAGS=\"$LDFLAGS -L/usr/local/lib\" CFLAGS=\"$CFLAGS -I/usr/local/include\" ./configure"
  ] {os = "openbsd" | os = "freebsd"}

  [
    "sh"
    "-exc"
    "LDFLAGS=\"$LDFLAGS -L/opt/local/lib -L/usr/local/lib\" CFLAGS=\"$CFLAGS -I/opt/local/include -I/usr/local/include\" ./configure"
  ] {os = "macos" & os-distribution != "homebrew"}

  [
    "sh"
    "-exc"
    "LDFLAGS=\"$LDFLAGS -L/opt/local/lib -L/usr/local/lib\" CFLAGS=\"$CFLAGS -I/opt/local/include -I/usr/local/include\" ./configure"
  ] {os = "macos" & os-distribution = "homebrew" & arch = "x86_64" }

  [
    "sh"
    "-exc"
    "LDFLAGS=\"$LDFLAGS -L/opt/homebrew/lib\" CFLAGS=\"$CFLAGS -I/opt/homebrew/include\" ./configure"
  ] {os = "macos" & os-distribution = "homebrew" & arch = "arm64" }

  [make]
]
```

This would translate to:

```example.nix
build = with onix.vars; [
  (on (os != "openbsd" && os != "freebsd" && os != "macos")
    [ "./configure" ])
  (on (os == "openbsd" || os == "freebsd") [
    "sh"
    "-exc"
    ''
      LDFLAGS="$LDFLAGS -L/usr/local/lib" CFLAGS="$CFLAGS -I/usr/local/include" ./configure''
  ])
  (on (os == "macos" && arch == "x86_64") [
    "sh"
    "-exc"
    ''
      LDFLAGS="$LDFLAGS -L/opt/local/lib -L/usr/local/lib" CFLAGS="$CFLAGS -I/opt/local/include -I/usr/local/include" ./configure''
  ])
  (on (os == "macos" && arch == "arm64") [
    "sh"
    "-exc"
    ''
      LDFLAGS="$LDFLAGS -L/opt/homebrew/lib" CFLAGS="$CFLAGS -I/opt/homebrew/include" ./configure''
  ])
  [ "make" ]
];
```

We delay the evaluation of `os` and `arch` variables.

A bigger challenge is (partially?) evaluating variables in `.in` files. These files aren't always included in the opam repository, for example the `gmp` package applies substs to a file from the source archive.

Fetching all source archives just for variable substitution during lock context genreation is not acceptable.

Even if we could fetch all sources, some variables would still need to be evaluated during build time.

The only viable solution is to completely delay variable evaluation to build time for most fields/files. This can be done by introducing a builder powered by opam libraries, like the `onix opam-build` command or by implementing a small build-time Nix module.


# Var resolution for package intalls

Why does opam allow looking custom local stateful switch vars when installing packages?

- https://github.com/ocaml/opam/blob/601e244409c93c1f4b1cc509a82221484f77537d/src/state/opamPackageVar.ml#L217
- https://github.com/ocaml/opam/blob/601e244409c93c1f4b1cc509a82221484f77537d/src/client/opamAction.ml#L519

This even applies to .in files.


# Solver errors and `post` var

If post is set to `true` in filter_deps env, opam-0install does not show the full error when an unknown package is detected.

With post=true:

```
Main.exe: [DEBUG] Target packages: ocaml-system example
Can't find all required versions.
Selected: base-bigarray.base base-threads.base base-unix.base ocaml.5.1.0
          ocaml-config.3 ocaml-system&example ocaml-base-compiler
          ocaml-base-compiler
- example -> (problem)
    Rejected candidates:
      example.dev: Requires ocaml >= 4.08 & < 5.0
- ocaml-base-compiler -> (problem)
    Rejected candidates:
      ocaml-base-compiler.5.0.0~alpha1: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.5.0.0~alpha0: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0~rc2: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0~rc1: In same conflict class (ocaml-core-compiler) as ocaml-system
      ...
- ocaml-system -> ocaml-system.4.14.0
    User requested = 4.14.0
```

With post=false:

```
Main.exe: [DEBUG] Target packages: ocaml-system example
Can't find all required versions.
Selected: example.dev ocaml-config.3 ocaml-system&example ocaml-base-compiler
          ocaml-base-compiler
- ocaml -> ocaml.4.14.1
    example dev requires >= 4.08 & < 5.0
- ocaml-base-compiler -> (problem)
    Rejected candidates:
      ocaml-base-compiler.5.0.0~alpha1: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.5.0.0~alpha0: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0~rc2: In same conflict class (ocaml-core-compiler) as ocaml-system
      ocaml-base-compiler.4.14.0~rc1: In same conflict class (ocaml-core-compiler) as ocaml-system
      ...
- ocaml-system -> ocaml-system.4.14.0
    User requested = 4.14.0
- xxx -> (problem)
    No known implementations at all
```

Why is ocaml-base-compiler added in the first place?


# IFD

With the onix driven build process, the package derivation could be fully generated by onix.

```
onix gen-nix-drv <pkg-info>
stdenv.mkDerivation {
  ...
}
```

- This can be now used to import and evaluate the final package build.
- This reduces the multiple calls to onix opam actions (patch, build, install).

## onix-less build is not an option...

Ok, we can:

- generate pure nix representation of opam files;
- include platform-specific conditions for opam fields by using partial evaluation of formulas;
- recreate the varible resolution scope in nix;
- apply substs to files using pure nix by matching vars in files with regex;


But ultimately we still need to parse opam files to complete the variable subst from .config files.
See: https://opam.ocaml.org/doc/Manual.html#lt-pkgname-gt-config

This seems too much just to avoid having onix available as a build runtime during build time...

On the other hand, we could read .config files from the opam repo and include them in the lock context,
but I think they can be part of the source code and thus would require fetching ALL sources to generate
the lock to lookup the .config files. Even that would not be enough because they could be generated by
the build actioon.

Conclusion: it is impossible to avoid parsing opam format during build time.

Is it worth implementing a basic opam parser in nix or a small language like awk? Bringing in
something like opam2json (in OCaml) defeats the purpose of not requiring heavy tooling during build.

We could implement an opam2json in awk, but... no.
