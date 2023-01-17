let
  nixpkgs = import <nixpkgs> { };
  ocaml-version = "4.14.0";
  vars = import ./vars.nix {
    platform = nixpkgs.hostPlatform;
    inherit ocaml-version;
  };

  subst = import ./subst.nix;

  pkgs = {
    "ocaml-config-2" = {
      name = "ocaml-config";
      version = "2";
      opamfile = "/packages/ocaml-config/opam";
      prefix = "/packages/ocaml-config";
    };
    "ocaml-base-compiler" = {
      name = "ocaml-base-compiler";
      version = "4.14.0";
      opamfile = "/packages/ocaml-base-compiler/opam";
      prefix = "/packages/ocaml-base-compiler";
    };
    "bos" = {
      name = "bos";
      version = "0.2.1";
      opamfile = "/packages/bos/opam";
      prefix = "/packages/bos";
    };
    "cmdliner" = {
      name = "cmdliner";
      version = "1.1.1";
      opamfile = "/packages/cmdliner/opam";
      prefix = "/packages/cmdliner";
    };
    "dune" = {
      name = "dune";
      version = "3.1.1";
      opamfile = "/packages/dune/opam";
      prefix = "/packages/dune";
    };
    "easy-format" = {
      name = "easy-format-1";
      version = "1.3.2";
      opamfile = "/packages/easy-format-1/opam";
      prefix = "/packages/easy-format-1";
    };
    "fpath" = {
      name = "fpath";
      version = "0.7.3";
      opamfile = "/packages/fpath/opam";
      prefix = "/packages/fpath";
    };
    "ocaml" = {
      name = "ocaml";
      version = "4.14.0";
      opamfile = "/packages/ocaml/opam";
      prefix = "/packages/ocaml";
    };
    "opam-0install" = {
      name = "opam-0install";
      version = "0.4.3";
      opamfile = "/packages/opam-0install/opam";
      prefix = "/packages/opam-0install";
    };
    "options" = {
      name = "options";
      version = "dev";
      opamfile = "/packages/options/opam";
      prefix = "/packages/options";
    };
    "uri" = {
      name = "uri";
      version = "4.2.0";
      opamfile = "/packages/uri/opam";
      prefix = "/packages/uri";
    };
    "yojson" = {
      name = "yojson";
      version = "1.7.0";
      opamfile = "/packages/yojson/opam";
      prefix = "/packages/yojson";
    };
  };

  self = {
    name = "onix-example";
    version = "dev";
    opamfile = "/packages/onix-exmple/opam";
    prefix = "/packages/onix-example";
  };

  build-dir = "/build";

  resolveStr = var-str:
    vars.resolve { inherit build-dir self pkgs ocaml-version; }
    (subst.process-var (subst.split-full-var-cond var-str));

  resolve = full-var:
    vars.resolve { inherit build-dir self pkgs ocaml-version; } full-var;

  test-vars = {
    # global
    "name" = resolve "name";
    "os" = resolve "os";
    "make" = resolve "make";

    # not-installed
    "foo:name" = resolve "foo:name";
    "foo:installed" = resolve "foo:installed";
    "foo:enable" = resolve "foo:enable";

    # self
    "_:opamfile" = resolve "_:opamfile";
    "opamfile" = resolve "opamfile";
    "lib" = resolve "lib";

    # pkg scope
    "uri:enable" = resolve "uri:enable";
    "yojson:installed" = resolve "yojson:installed";
    "yojson:lib" = resolve "yojson:lib";
  };

  test-content = ''
    description = "OCaml Secondary Compiler"
    version = "%{ocaml:version}%"
    yojson-bin = "%{yojson:prefix}%/bin"
    os = "%{os}%"
    lib = "%{lib}%"
    self-opamfile = "%{_:opamfile}%"
    cond-with-true = "%{yojson:installed?with-json}%"
    cond-with-false = "%{foo:installed?with-foo:without-foo}%"
  '';
in {
  inherit test-content resolve;
  inherit (subst) subst-file-content;
}
