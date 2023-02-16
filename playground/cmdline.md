# Commandline Interface


Build a single package:
```
$ onix build utop
$ ls ./result/bin/utop
```

Build a single package, provide a repo URL:
```
$ onix build --repo=https://github.com/ocaml/opam-repository.git#52c72e08d7782967837955f1c50c330a6131721f utop
$ ls ./result/bin/utop
```

Build multiple packages with specific version constraints:
```
$ onix build bos.0.2.1 utop
$ ls ./result/bin/utop
```

Build a local package from opam file:
```
$ onix build ./pkg.opam
$ ls ./result/bin/utop
```

Build a remtoe package:
```
$ onix build git+https://github.com/odis-labs/streaming.git
$ ls ./result/bin/utop
```

Run a package:
```
$ onix run utop
# Runs ./bin/utop
```

Start a shell for a package:
```
$ onix shell utop
```