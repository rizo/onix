{ pkgs, self, opam-repo ? builtins.fetchGit {
  url = "https://github.com/ocaml/opam-repository.git";
  rev = "52c72e08d7782967837955f1c50c330a6131721f";
  allRefs = true;
} }:
{
  base-bigarray =  {
    name = "base-bigarray";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-bigarray/base-bigarray.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  base-threads =  {
    name = "base-threads";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-threads/base-threads.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  base-unix =  {
    name = "base-unix";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-unix/base-unix.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  conf-binutils =  {
    name = "conf-binutils";
    version = "0.3";
    src = null;
    opam = "${opam-repo}/packages/conf-binutils/conf-binutils.0.3/opam";
    depends = with self; [ base-unix ocaml ];
    depexts = [ pkgs.binutils ];
  };
  dune =  {
    name = "dune";
    version = "3.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/dune/releases/download/3.2.0/chrome-trace-3.2.0.tbz";
      sha256 = "bd1fbce6ae79ed1eb26fa89bb2e2e23978afceb3f53f5578cf1bdab08a1ad5bc";
    };
    opam = "${opam-repo}/packages/dune/dune.3.2.0/opam";
    depends = with self; [ base-threads base-unix (self.ocaml or null)
                           (self.ocamlfind-secondary or null) ];
    depexts = [ ];
  };
  ocaml =  {
    name = "ocaml";
    version = "4.14.0";
    src = null;
    opam = "${opam-repo}/packages/ocaml/ocaml.4.14.0/opam";
    depends = with self; [ ocaml-config (self.ocaml-base-compiler or null)
                           (self.ocaml-system or null)
                           (self.ocaml-variants or null) ];
    depexts = [ ];
  };
  ocaml-base-compiler =  {
    name = "ocaml-base-compiler";
    version = "4.14.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocaml/archive/4.14.0.tar.gz";
      sha256 = "39f44260382f28d1054c5f9d8bf4753cb7ad64027da792f7938344544da155e8";
    };
    opam = "${opam-repo}/packages/ocaml-base-compiler/ocaml-base-compiler.4.14.0/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  ocaml-config =  {
    name = "ocaml-config";
    version = "2";
    src = null;
    opam = "${opam-repo}/packages/ocaml-config/ocaml-config.2/opam";
    depends = with self; [ (self.ocaml-base-compiler or null)
                           (self.ocaml-system or null)
                           (self.ocaml-variants or null) ];
    depexts = [ ];
  };
  ocaml-options-vanilla =  {
    name = "ocaml-options-vanilla";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/ocaml-options-vanilla/ocaml-options-vanilla.1/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  universe = rec {
    name = "universe";
    version = "root";
    src = ./.;
    opam = "${src}/universe.opam";
    depends = with self; [ conf-binutils dune ocaml ];
    depexts = [ ];
  };
}
