
.PHONY: build
build:
	dune build

.PHONY: watch
watch:
	dune build -w

.PHONY: nix-build
nix-build:
	nix-build

.PHONY: nix-shell
nix-shell:
	nix-shell

.PHONY: nix-bootstrap
nix-bootstrap:
	nix-build ./nix/bootstrap.nix

.PHONY: test
test:
	dune runtest
