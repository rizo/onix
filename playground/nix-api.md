# Nix API

```
let env = onix.env : {
  # The repo to use for resolution.
  repo : { url : String; },

  # List of additional or alternative repos.
  repos : List { url : String },

  # The root of the project where opam files are looked up.
  root : Path?,

  # List of additional or alternative deps.
  # A deps value can be:
  #   - a version constraint string;
  #   - a local opam file path;
  #   - a git source (an attrset with "url" name).
  deps : { String : String | Path | { url : String } },

  # The path of the onix lock file.
  lock : Path ? ./onix-lock.json,

  # The path of the opam "locked" file to be generated.
  opam-lock : Path?,

  # A nix overlay to be applied to the built scope.
  overlay : Scope -> Scope -> Scope
} -> {
  lock : Derivation,
  pkgs : Scope,
  shell : Derivation
}
```


```
onix.env
onix.project
onix.workspace
onix.scope

onix.build
onix.init
onix.mk

onix.env.init
onix.env.mk
onix.mkEnv

{
  deps,
  lock,
  opam-lock,
  shell
}
```
