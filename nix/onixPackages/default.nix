{ pkgs ? import <nixpkgs> { }, ocamlPackages ? pkgs.ocamlPackages }:
ocamlPackages.overrideScope (self: super: {
  cmdliner = self.callPackage ./cmdliner.nix { };
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
})
