{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages }:
ocamlPackages.overrideScope (self: super: {
  cmdliner = self.callPackage ./cmdliner.nix { };
  zero-install-solver = self.callPackage ./0install-solver.nix { };
  opam-0install = self.callPackage ./opam-0install.nix { };
  alcotest = super.alcotest.overrideAttrs (_: { doCheck = false; });
  yojson = super.yojson.overrideAttrs (_: { doCheck = false; });
  uri = super.uri.overrideAttrs (_: { doCheck = false; });
  angstrom = super.angstrom.overrideAttrs (_: { doCheck = false; });
  opam-repository = super.opam-repository.overrideAttrs (_: {
    configureFlags = [
      "--disable-checks"
    ];
    doCheck = false;
  });
  logs = super.logs.override { jsooSupport = false; };
  opam-core = super.opam-core.overrideAttrs (attrs: {
    propagatedBuildInputs = attrs.propagatedBuildInputs ++ [
      ocamlPackages.uutf
      ocamlPackages.jsonm
      ocamlPackages.sha
      self.swhid_core
      self.spdx_licenses
    ];
  });
  swhid_core = self.callPackage ./swhid_core.nix {};
  spdx_licenses = self.callPackage ./spdx_licenses.nix {};
})
