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
  base-bytes =  {
    name = "base-bytes";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-bytes/base-bytes.base/opam";
    depends = with self; [ ocaml ocamlfind ];
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
  conf-postgresql =  {
    name = "conf-postgresql";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-postgresql/conf-postgresql.1/opam";
    depends = with self; [ ];
    depexts = [ pkgs.postgresql ];
  };
  csexp =  {
    name = "csexp";
    version = "1.5.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-dune/csexp/releases/download/1.5.1/csexp-1.5.1.tbz";
      sha256 = "d605e4065fa90a58800440ef2f33a2d931398bf2c22061a8acb7df845c0aac02";
    };
    opam = "${opam-repo}/packages/csexp/csexp.1.5.1/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
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
  dune-configurator =  {
    name = "dune-configurator";
    version = "3.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/dune/releases/download/3.2.0/chrome-trace-3.2.0.tbz";
      sha256 = "bd1fbce6ae79ed1eb26fa89bb2e2e23978afceb3f53f5578cf1bdab08a1ad5bc";
    };
    opam = "${opam-repo}/packages/dune-configurator/dune-configurator.3.2.0/opam";
    depends = with self; [ csexp dune ocaml ];
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
  ocamlfind =  {
    name = "ocamlfind";
    version = "1.9.3";
    src = pkgs.fetchurl {
      url = "http://download.camlcity.org/download/findlib-1.9.3.tar.gz";
      sha512 = "27cc4ce141576bf477fb9d61a82ad65f55478740eed59fb43f43edb794140829fd2ff89ad27d8a890cfc336b54c073a06de05b31100fc7c01cacbd7d88e928ea";
    };
    opam = "${opam-repo}/packages/ocamlfind/ocamlfind.1.9.3/opam";
    depends = with self; [ ocaml (self.graphics or null) ];
    depexts = [ ];
  };
  postgresql =  {
    name = "postgresql";
    version = "5.0.0";
    src = pkgs.fetchurl {
      url = "https://github.com/mmottl/postgresql-ocaml/releases/download/5.0.0/postgresql-5.0.0.tbz";
      sha256 = "9ccd405bf2a4811d86995102b0837f07230f30d05ed620b9d05fa66f607ef9d8";
    };
    opam = "${opam-repo}/packages/postgresql/postgresql.5.0.0/opam";
    depends = with self; [ base-bytes conf-postgresql dune dune-configurator
                           ocaml ];
    depexts = [ ];
  };
  with-depexts-postgresql = rec {
    name = "with-depexts-postgresql";
    version = "root";
    src = ./.;
    opam = "${src}/with-depexts-postgresql.opam";
    depends = with self; [ dune ocaml postgresql ];
    depexts = [ ];
  };
}
