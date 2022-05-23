
# TODO

- [x] Proper support for opam repo management.
- [x] Implement depexts.
- [x] Warn on md5 hashes.
- [x] Refactor builder.nix.
- [x] Refactor overrides.
- [x] Better depexts mapping:
  - https://github.com/tweag/opam-nix/blob/8062dfe742f6636191017232ff504f6765a7f2d1/src/overlays/external/debian.nix#L35
- [x] Filter invalid depexts names.
- [ ] Fix ocaml env vars propagation for shell.
- [ ] Use nix-prefetch-url.
- [x] Apply "with-test" var when extracting install.
- [ ] Implement onix shell.
- [ ] Implement onix build.
- [ ] Add --with-dev flag and support for dev dependencies.
- [ ] Run opam actions natively.
- [ ] Use native nix packages to build onix itself.
- [ ] Use the same compiler for onix and project build.
- [ ] Add --lock-file argument to actions.
- [ ] Improve logging.
- [ ] Improve error-handling.
- [ ] Make depends/depexts optional.
- [ ] Handle empty lock file.
- [ ] Handle lock file without ocaml.
- [ ] Drop fpath, use OpamFilename.