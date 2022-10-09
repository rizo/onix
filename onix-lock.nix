{ pkgs ? import <nixpkgs> {} }:
rec {
  version = "0.0.5";
  repo = builtins.fetchGit {
    url = "https://github.com/ocaml/opam-repository.git";
    rev = "57f1b681ce75766a17f15588c2088174edbb89c9";
  };
  scope = rec {
    _0install-solver = {
      name = "0install-solver";
      version = "2.18";
      src = pkgs.fetchurl {
        url = "https://github.com/0install/0install/releases/download/v2.18/0install-2.18.tbz";
        sha256 = "648c4b318c1a26dfcb44065c226ab8ca723795924ad80a3bf39ae1ce0e9920c3";
      };
      opam = "${repo}/packages/0install-solver/0install-solver.2.18/opam";
      depends = [ dune ocaml ];
      buildDepends = [ dune ocaml ];
    };
    astring = {
      name = "astring";
      version = "0.8.5";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/astring/releases/astring-0.8.5.tbz";
        sha256 = "1ykhg9gd3iy7zsgyiy2p9b1wkpqg9irw5pvcqs3sphq71iir4ml6";
      };
      opam = "${repo}/packages/astring/astring.0.8.5/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    base-bigarray = {
      name = "base-bigarray";
      version = "base";
      opam = "${repo}/packages/base-bigarray/base-bigarray.base/opam";
    };
    base-threads = {
      name = "base-threads";
      version = "base";
      opam = "${repo}/packages/base-threads/base-threads.base/opam";
    };
    base-unix = {
      name = "base-unix";
      version = "base";
      opam = "${repo}/packages/base-unix/base-unix.base/opam";
    };
    bos = {
      name = "bos";
      version = "0.2.1";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/bos/releases/bos-0.2.1.tbz";
        sha512 = "8daeb8a4c2dd1f2460f6274ada19f4f1b6ebe875ff83a938c93418ce0e6bdb74b8afc5c9a7d410c1c9df2dad030e4fa276b6ed2da580639484e8b5bc92610b1d";
      };
      opam = "${repo}/packages/bos/bos.0.2.1/opam";
      depends = [ astring base-unix fmt fpath logs ocaml rresult ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    cmdliner = {
      name = "cmdliner";
      version = "1.1.1";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/cmdliner/releases/cmdliner-1.1.1.tbz";
        sha512 = "5478ad833da254b5587b3746e3a8493e66e867a081ac0f653a901cc8a7d944f66e4387592215ce25d939be76f281c4785702f54d4a74b1700bc8838a62255c9e";
      };
      opam = "${repo}/packages/cmdliner/cmdliner.1.1.1/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ];
    };
    cppo = {
      name = "cppo";
      version = "1.6.9";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml-community/cppo/archive/v1.6.9.tar.gz";
        sha512 = "26ff5a7b7f38c460661974b23ca190f0feae3a99f1974e0fd12ccf08745bd7d91b7bc168c70a5385b837bfff9530e0e4e41cf269f23dd8cf16ca658008244b44";
      };
      opam = "${repo}/packages/cppo/cppo.1.6.9/opam";
      depends = [ base-unix dune ocaml ];
      buildDepends = [ dune ocaml ];
    };
    dune = {
      name = "dune";
      version = "3.4.1";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/dune/releases/download/3.4.1/dune-3.4.1.tbz";
        sha256 = "299fa33cffc108cc26ff59d5fc9d09f6cb0ab3ac280bf23a0114cfdc0b40c6c5";
      };
      opam = "${repo}/packages/dune/dune.3.4.1/opam";
      depends = [ base-threads base-unix ocaml ];
      buildDepends = [ ocaml ];
    };
    easy-format = {
      name = "easy-format";
      version = "1.3.2";
      src = pkgs.fetchurl {
        url = "https://github.com/mjambon/easy-format/releases/download/1.3.2/easy-format-1.3.2.tbz";
        sha256 = "3440c2b882d537ae5e9011eb06abb53f5667e651ea4bb3b460ea8230fa8c1926";
      };
      opam = "${repo}/packages/easy-format/easy-format.1.3.2/opam";
      depends = [ dune ocaml ];
      buildDepends = [ dune ocaml ];
    };
    fmt = {
      name = "fmt";
      version = "0.9.0";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/fmt/releases/fmt-0.9.0.tbz";
        sha512 = "66cf4b8bb92232a091dfda5e94d1c178486a358cdc34b1eec516d48ea5acb6209c0dfcb416f0c516c50ddbddb3c94549a45e4a6d5c5fd1c81d3374dec823a83b";
      };
      opam = "${repo}/packages/fmt/fmt.0.9.0/opam";
      depends = [ base-unix cmdliner ocaml ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    fpath = {
      name = "fpath";
      version = "0.7.3";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/fpath/releases/fpath-0.7.3.tbz";
        sha256 = "03z7mj0sqdz465rc4drj1gr88l9q3nfs374yssvdjdyhjbqqzc0j";
      };
      opam = "${repo}/packages/fpath/fpath.0.7.3/opam";
      depends = [ astring ocaml ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    logs = {
      name = "logs";
      version = "0.7.0";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/logs/releases/logs-0.7.0.tbz";
        sha256 = "1jnmd675wmsmdwyb5mx5b0ac66g4c6gpv5s4mrx2j6pb0wla1x46";
      };
      opam = "${repo}/packages/logs/logs.0.7.0/opam";
      depends = [ base-threads cmdliner fmt ocaml ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    ocaml = {
      name = "ocaml";
      version = "4.14.0";
      opam = "${repo}/packages/ocaml/ocaml.4.14.0/opam";
      depends = [ ocaml-base-compiler ocaml-config ];
    };
    ocaml-base-compiler = {
      name = "ocaml-base-compiler";
      version = "4.14.0";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/ocaml/archive/4.14.0.tar.gz";
        sha256 = "39f44260382f28d1054c5f9d8bf4753cb7ad64027da792f7938344544da155e8";
      };
      opam = "${repo}/packages/ocaml-base-compiler/ocaml-base-compiler.4.14.0/opam";
    };
    ocaml-config = {
      name = "ocaml-config";
      version = "2";
      opam = "${repo}/packages/ocaml-config/ocaml-config.2/opam";
      depends = [ ocaml-base-compiler ];
    };
    ocamlbuild = {
      name = "ocamlbuild";
      version = "0.14.2";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/ocamlbuild/archive/refs/tags/0.14.2.tar.gz";
        sha512 = "f568bf10431a1f701e8bd7554dc662400a0d978411038bbad93d44dceab02874490a8a5886a9b44e017347e7949997f13f5c3752f74e1eb5e273d2beb19a75fd";
      };
      opam = "${repo}/packages/ocamlbuild/ocamlbuild.0.14.2/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ];
    };
    ocamlfind = {
      name = "ocamlfind";
      version = "1.9.5";
      src = pkgs.fetchurl {
        url = "http://download.camlcity.org/download/findlib-1.9.5.tar.gz";
        sha512 = "03514c618a16b02889db997c6c4789b3436b3ad7d974348d2c6dea53eb78898ab285ce5f10297c074bab4fd2c82931a8b7c5c113b994447a44abb30fca74c715";
      };
      opam = "${repo}/packages/ocamlfind/ocamlfind.1.9.5/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ];
    };
    ocamlgraph = {
      name = "ocamlgraph";
      version = "2.0.0";
      src = pkgs.fetchurl {
        url = "https://github.com/backtracking/ocamlgraph/releases/download/2.0.0/ocamlgraph-2.0.0.tbz";
        sha256 = "20fe267797de5322088a4dfb52389b2ea051787952a8a4f6ed70fcb697482609";
      };
      opam = "${repo}/packages/ocamlgraph/ocamlgraph.2.0.0/opam";
      depends = [ dune ocaml stdlib-shims ];
      buildDepends = [ dune ocaml ];
    };
    onix = {
      name = "onix";
      version = "root";
      src = pkgs.nix-gitignore.gitignoreSource [] ./.;
      opam = "${onix.src}/onix.opam";
      depends = [ bos cmdliner easy-format fmt fpath logs ocaml opam-0install
                  yojson ];
      buildDepends = [ dune ocaml ];
    };
    opam-0install = {
      name = "opam-0install";
      version = "0.4.3";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml-opam/opam-0install-solver/releases/download/v0.4.3/opam-0install-cudf-0.4.3.tbz";
        sha256 = "d59e0ebddda58f798ff50ebe213c83893b5a7c340c38c20950574d67e6145b8a";
      };
      opam = "${repo}/packages/opam-0install/opam-0install.0.4.3/opam";
      depends = [ _0install-solver cmdliner dune fmt ocaml opam-file-format
                  opam-state ];
      buildDepends = [ dune ocaml ];
    };
    opam-core = {
      name = "opam-core";
      version = "2.1.3";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/opam/archive/refs/tags/2.1.3.tar.gz";
        sha512 = "040e4f58f93e962ff422617ce0d35ed45dd86921a9aac3505914c33dd942d0e5e5771e7e1774046504f9aa84f32bc4fbd6ac7720fbea862d48bf1ca29e02cefc";
      };
      opam = "${repo}/packages/opam-core/opam-core.2.1.3/opam";
      depends = [ base-bigarray base-unix dune ocaml ocamlgraph re ];
      buildDepends = [ cppo dune ocaml ];
    };
    opam-file-format = {
      name = "opam-file-format";
      version = "2.1.4";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/opam-file-format/archive/refs/tags/2.1.4.tar.gz";
        sha512 = "fb5e584080d65c5b5d04c7d2ac397b69a3fd077af3f51eb22967131be22583fea507390eb0d7e6f5c92035372a9e753adbfbc8bfd056d8fd4697c6f95dd8e0ad";
      };
      opam = "${repo}/packages/opam-file-format/opam-file-format.2.1.4/opam";
      depends = [ dune ocaml ];
      buildDepends = [ dune ocaml ];
    };
    opam-format = {
      name = "opam-format";
      version = "2.1.3";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/opam/archive/refs/tags/2.1.3.tar.gz";
        sha512 = "040e4f58f93e962ff422617ce0d35ed45dd86921a9aac3505914c33dd942d0e5e5771e7e1774046504f9aa84f32bc4fbd6ac7720fbea862d48bf1ca29e02cefc";
      };
      opam = "${repo}/packages/opam-format/opam-format.2.1.3/opam";
      depends = [ dune ocaml opam-core opam-file-format re ];
      buildDepends = [ dune ocaml ];
    };
    opam-repository = {
      name = "opam-repository";
      version = "2.1.3";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/opam/archive/refs/tags/2.1.3.tar.gz";
        sha512 = "040e4f58f93e962ff422617ce0d35ed45dd86921a9aac3505914c33dd942d0e5e5771e7e1774046504f9aa84f32bc4fbd6ac7720fbea862d48bf1ca29e02cefc";
      };
      opam = "${repo}/packages/opam-repository/opam-repository.2.1.3/opam";
      depends = [ dune ocaml opam-format ];
      buildDepends = [ dune ocaml ];
    };
    opam-state = {
      name = "opam-state";
      version = "2.1.3";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/opam/archive/refs/tags/2.1.3.tar.gz";
        sha512 = "040e4f58f93e962ff422617ce0d35ed45dd86921a9aac3505914c33dd942d0e5e5771e7e1774046504f9aa84f32bc4fbd6ac7720fbea862d48bf1ca29e02cefc";
      };
      opam = "${repo}/packages/opam-state/opam-state.2.1.3/opam";
      depends = [ dune ocaml opam-repository ];
      buildDepends = [ dune ocaml ];
    };
    re = {
      name = "re";
      version = "1.10.4";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/ocaml-re/releases/download/1.10.4/re-1.10.4.tbz";
        sha256 = "83eb3e4300aa9b1dc7820749010f4362ea83524742130524d78c20ce99ca747c";
      };
      opam = "${repo}/packages/re/re.1.10.4/opam";
      depends = [ dune ocaml seq ];
      buildDepends = [ dune ocaml ];
    };
    rresult = {
      name = "rresult";
      version = "0.7.0";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/rresult/releases/rresult-0.7.0.tbz";
        sha512 = "f1bb631c986996388e9686d49d5ae4d8aaf14034f6865c62a88fb58c48ce19ad2eb785327d69ca27c032f835984e0bd2efd969b415438628a31f3e84ec4551d3";
      };
      opam = "${repo}/packages/rresult/rresult.0.7.0/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ocamlbuild ocamlfind topkg ];
    };
    seq = {
      name = "seq";
      version = "base";
      opam = "${repo}/packages/seq/seq.base/opam";
      depends = [ ocaml ];
      buildDepends = [ ocaml ];
    };
    stdlib-shims = {
      name = "stdlib-shims";
      version = "0.3.0";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml/stdlib-shims/releases/download/0.3.0/stdlib-shims-0.3.0.tbz";
        sha256 = "babf72d3917b86f707885f0c5528e36c63fccb698f4b46cf2bab5c7ccdd6d84a";
      };
      opam = "${repo}/packages/stdlib-shims/stdlib-shims.0.3.0/opam";
      depends = [ dune ocaml ];
      buildDepends = [ dune ocaml ];
    };
    topkg = {
      name = "topkg";
      version = "1.0.5";
      src = pkgs.fetchurl {
        url = "https://erratique.ch/software/topkg/releases/topkg-1.0.5.tbz";
        sha512 = "9450e9139209aacd8ddb4ba18e4225770837e526a52a56d94fd5c9c4c9941e83e0e7102e2292b440104f4c338fabab47cdd6bb51d69b41cc92cc7a551e6fefab";
      };
      opam = "${repo}/packages/topkg/topkg.1.0.5/opam";
      depends = [ ocaml ocamlbuild ];
      buildDepends = [ ocaml ocamlbuild ocamlfind ];
    };
    yojson = {
      name = "yojson";
      version = "2.0.2";
      src = pkgs.fetchurl {
        url = "https://github.com/ocaml-community/yojson/releases/download/2.0.2/yojson-2.0.2.tbz";
        sha256 = "876bb6f38af73a84a29438a3da35e4857c60a14556a606525b148c6fdbe5461b";
      };
      opam = "${repo}/packages/yojson/yojson.2.0.2/opam";
      depends = [ dune ocaml seq ];
      buildDepends = [ cppo dune ocaml ];
    };
  };
}
