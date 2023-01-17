{ ocaml-version }:
let
  lib = { pkg-name ? null, subdir ? null, prefix }:
    let
      segments =
        [ prefix "lib/ocaml" ocaml-version "site-lib" subdir pkg-name ];
      segments' = builtins.filter (seg: !(isNull seg)) segments;
    in builtins.concatStringsSep "/" segments';

  out = { pkg-name ? null, subdir ? null, prefix }:
    let
      segments = [ prefix subdir pkg-name ];
      segments' = builtins.filter (seg: !(isNull seg)) segments;
    in builtins.concatStringsSep "/" segments';

in {
  inherit lib;

  stublibs = args: lib (args // { subdir = "stublibs"; });
  toplevel = args: lib (args // { subdir = "toplevel"; });

  bin = args: out (args // { subdir = "bin"; });
  sbin = args: out (args // { subdir = "sbin"; });
  share = args: out (args // { subdir = "share"; });
  etc = args: out (args // { subdir = "etc"; });
  doc = args: out (args // { subdir = "doc"; });

  man = args:
    out (args // {
      pkg-name = null;
      subdir = "man";
    });
}
