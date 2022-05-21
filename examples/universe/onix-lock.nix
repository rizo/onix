{ pkgs, self, opam-repo ? builtins.fetchGit {
  url = "https://github.com/ocaml/opam-repository.git";
  rev = "52c72e08d7782967837955f1c50c330a6131721f";
  allRefs = true;
} }:
{
  alcotest =  {
    name = "alcotest";
    version = "1.5.0";
    src = pkgs.fetchurl {
      url = "https://github.com/mirage/alcotest/releases/download/1.5.0/alcotest-js-1.5.0.tbz";
      sha256 = "54281907e02d78995df246dc2e10ed182828294ad2059347a1e3a13354848f6c";
    };
    opam = "${opam-repo}/packages/alcotest/alcotest.1.5.0/opam";
    depends = with self; [ astring cmdliner dune fmt ocaml ocaml-syntax-shims
                           re stdlib-shims uutf ];
    depexts = [ ];
  };
  astring =  {
    name = "astring";
    version = "0.8.5";
    src = builtins.fetchurl {
      url = "https://erratique.ch/software/astring/releases/astring-0.8.5.tbz";
    };
    opam = "${opam-repo}/packages/astring/astring.0.8.5/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg ];
    depexts = [ ];
  };
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
  cmdliner =  {
    name = "cmdliner";
    version = "1.1.1";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/cmdliner/releases/cmdliner-1.1.1.tbz";
      sha512 = "5478ad833da254b5587b3746e3a8493e66e867a081ac0f653a901cc8a7d944f66e4387592215ce25d939be76f281c4785702f54d4a74b1700bc8838a62255c9e";
    };
    opam = "${opam-repo}/packages/cmdliner/cmdliner.1.1.1/opam";
    depends = with self; [ ocaml ];
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
  fmt =  {
    name = "fmt";
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/fmt/releases/fmt-0.9.0.tbz";
      sha512 = "66cf4b8bb92232a091dfda5e94d1c178486a358cdc34b1eec516d48ea5acb6209c0dfcb416f0c516c50ddbddb3c94549a45e4a6d5c5fd1c81d3374dec823a83b";
    };
    opam = "${opam-repo}/packages/fmt/fmt.0.9.0/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg
                           (self.base-unix or null) (self.cmdliner or null) ];
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
  ocaml-compiler-libs =  {
    name = "ocaml-compiler-libs";
    version = "v0.12.4";
    src = pkgs.fetchurl {
      url = "https://github.com/janestreet/ocaml-compiler-libs/releases/download/v0.12.4/ocaml-compiler-libs-v0.12.4.tbz";
      sha256 = "4ec9c9ec35cc45c18c7a143761154ef1d7663036a29297f80381f47981a07760";
    };
    opam = "${opam-repo}/packages/ocaml-compiler-libs/ocaml-compiler-libs.v0.12.4/opam";
    depends = with self; [ dune ocaml ];
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
  ocaml-syntax-shims =  {
    name = "ocaml-syntax-shims";
    version = "1.0.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-ppx/ocaml-syntax-shims/releases/download/1.0.0/ocaml-syntax-shims-1.0.0.tbz";
      sha256 = "89b2e193e90a0c168b6ec5ddf6fef09033681bdcb64e11913c97440a2722e8c8";
    };
    opam = "${opam-repo}/packages/ocaml-syntax-shims/ocaml-syntax-shims.1.0.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ocamlbuild =  {
    name = "ocamlbuild";
    version = "0.14.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocamlbuild/archive/refs/tags/0.14.1.tar.gz";
      sha512 = "1f5b43215b1d3dc427b9c64e005add9d423ed4bca9686d52c55912df8955647cb2d7d86622d44b41b14c4f0d657b770c27967c541c868eeb7c78e3bd35b827ad";
    };
    opam = "${opam-repo}/packages/ocamlbuild/ocamlbuild.0.14.1/opam";
    depends = with self; [ ocaml ];
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
  ppx_derivers =  {
    name = "ppx_derivers";
    version = "1.2.1";
    src = builtins.fetchurl {
      url = "https://github.com/ocaml-ppx/ppx_derivers/archive/1.2.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_derivers/ppx_derivers.1.2.1/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ppxlib =  {
    name = "ppxlib";
    version = "0.26.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-ppx/ppxlib/releases/download/0.26.0/ppxlib-0.26.0.tbz";
      sha256 = "63117b67ea5863935455fe921f88fe333c0530f0483f730313303a93af817efd";
    };
    opam = "${opam-repo}/packages/ppxlib/ppxlib.0.26.0/opam";
    depends = with self; [ dune ocaml ocaml-compiler-libs ppx_derivers
                           sexplib0 stdlib-shims ];
    depexts = [ ];
  };
  ptime =  {
    name = "ptime";
    version = "1.0.0";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/ptime/releases/ptime-1.0.0.tbz";
      sha512 = "df2410d9cc25a33083fe968a584b8fb4d68ad5c077f3356da0a20427e6cd8756a5b946b921e5cf8ed4097f2c506e93345d9dca63b113be644d5a7cc0753d1534";
    };
    opam = "${opam-repo}/packages/ptime/ptime.1.0.0/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg ];
    depexts = [ ];
  };
  re =  {
    name = "re";
    version = "1.10.4";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocaml-re/releases/download/1.10.4/re-1.10.4.tbz";
      sha256 = "83eb3e4300aa9b1dc7820749010f4362ea83524742130524d78c20ce99ca747c";
    };
    opam = "${opam-repo}/packages/re/re.1.10.4/opam";
    depends = with self; [ dune ocaml seq ];
    depexts = [ ];
  };
  seq =  {
    name = "seq";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/seq/seq.base/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  sexplib0 =  {
    name = "sexplib0";
    version = "v0.15.0";
    src = pkgs.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.15/files/sexplib0-v0.15.0.tar.gz";
      sha256 = "94462c00416403d2778493ac01ced5439bc388a68ac4097208159d62434aefba";
    };
    opam = "${opam-repo}/packages/sexplib0/sexplib0.v0.15.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  stdlib-shims =  {
    name = "stdlib-shims";
    version = "0.3.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/stdlib-shims/releases/download/0.3.0/stdlib-shims-0.3.0.tbz";
      sha256 = "babf72d3917b86f707885f0c5528e36c63fccb698f4b46cf2bab5c7ccdd6d84a";
    };
    opam = "${opam-repo}/packages/stdlib-shims/stdlib-shims.0.3.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  topkg =  {
    name = "topkg";
    version = "1.0.5";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/topkg/releases/topkg-1.0.5.tbz";
      sha512 = "9450e9139209aacd8ddb4ba18e4225770837e526a52a56d94fd5c9c4c9941e83e0e7102e2292b440104f4c338fabab47cdd6bb51d69b41cc92cc7a551e6fefab";
    };
    opam = "${opam-repo}/packages/topkg/topkg.1.0.5/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind ];
    depexts = [ ];
  };
  universe = rec {
    name = "universe";
    version = "root";
    src = ./.;
    opam = "${src}/universe.opam";
    depends = with self; [ alcotest dune fmt ocaml ppxlib ptime ];
    depexts = [ ];
  };
  uutf =  {
    name = "uutf";
    version = "1.0.3";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/uutf/releases/uutf-1.0.3.tbz";
      sha512 = "50cc4486021da46fb08156e9daec0d57b4ca469b07309c508d5a9a41e9dbcf1f32dec2ed7be027326544453dcaf9c2534919395fd826dc7768efc6cc4bfcc9f8";
    };
    opam = "${opam-repo}/packages/uutf/uutf.1.0.3/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg
                           (self.cmdliner or null) ];
    depexts = [ ];
  };
}
