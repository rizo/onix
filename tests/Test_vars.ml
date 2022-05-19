let input =
  {|
{
  "name": "onix-example",
  "version": "root",
  "opam": "/nix/store/93l01ab4xqjn6q4n0nf25yasp8jf2jhv-onix-example.opam",
  "depends": [
    {
      "name": "ocaml-config",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/ocaml-config/ocaml-config.2/opam",
      "path": "/nix/store/j49d3wydfm41n5mb4hlhkx3iv2fy92zd-ocaml-config-2",
      "version": "2"
    },
    {
      "name": "ocaml-base-compiler",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/ocaml-base-compiler/ocaml-base-compiler.4.14.0/opam",
      "path": "/nix/store/ad91sfjyk923k4z67b0sl3s5wl9xf18f-ocaml-base-compiler-4.14.0",
      "version": "4.14.0"
    },
    {
      "name": "bos",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/bos/bos.0.2.1/opam",
      "path": "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1",
      "version": "0.2.1"
    },
    {
      "name": "cmdliner",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/cmdliner/cmdliner.1.1.1/opam",
      "path": "/nix/store/0f8xjcgi3611n74hxp7sd0bpn4zl4vcl-cmdliner-1.1.1",
      "version": "1.1.1"
    },
    {
      "name": "dune",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/dune/dune.3.1.1/opam",
      "path": "/nix/store/i26f26cqb43wb0kvk7syv8sknai0cp54-dune-3.1.1",
      "version": "3.1.1"
    },
    {
      "name": "easy-format",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/easy-format/easy-format.1.3.2/opam",
      "path": "/nix/store/76l042jhbmp4pavfj91fc3q5835zd1s2-easy-format-1.3.2",
      "version": "1.3.2"
    },
    {
      "name": "fpath",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/fpath/fpath.0.7.3/opam",
      "path": "/nix/store/rvfm6288jihfm78z4gpcdgxqkidl41f8-fpath-0.7.3",
      "version": "0.7.3"
    },
    {
      "name": "ocaml",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/ocaml/ocaml.4.14.0/opam",
      "path": "/nix/store/graxs35pqmmmli4jf65jzc0drnwdz5kv-ocaml-4.14.0",
      "version": "4.14.0"
    },
    {
      "name": "opam-0install",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/opam-0install/opam-0install.0.4.3/opam",
      "path": "/nix/store/f91m283sqzh3g0hzcxh3fw7yc7piadlc-opam-0install-0.4.3",
      "version": "0.4.3"
    },
    {
      "name": "options",
      "opam": "/nix/store/shq4mwcvamqj9pw2jbs1b28bdpr4p50y-source/options.opam",
      "path": "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev",
      "version": "dev"
    },
    {
      "name": "uri",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/uri/uri.4.2.0/opam",
      "path": "/nix/store/vwaav64li06cmrgjvrg0w8r6xmbrv8hx-uri-4.2.0",
      "version": "4.2.0"
    },
    {
      "name": "yojson",
      "opam": "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/yojson/yojson.1.7.0/opam",
      "path": "/nix/store/i7hmg44cvnfq0xa0f9dm1hx2262j9vyf-yojson-1.7.0",
      "version": "1.7.0"
    }
  ]
}
|}

let build_context =
  Onix.Build_context.read_json ~ocaml_version:"4.14.0"
    ~path:"/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix"
    (Yojson.Basic.from_string input)

let eq_pkg_name n1 n2 =
  let eq = OpamPackage.Name.equal n1 n2 in
  if not eq then
    Fmt.epr "Package names not equal: %S and %S@."
      (OpamPackage.Name.to_string n1)
      (OpamPackage.Name.to_string n2);
  eq

let eq_pkg_v v1 v2 =
  let eq = OpamPackage.Version.equal v1 v2 in
  if not eq then
    Fmt.epr "Package versions not equal: %S and %S@."
      (OpamPackage.Version.to_string v1)
      (OpamPackage.Version.to_string v2);
  eq

let mk_pkg_name = OpamPackage.Name.of_string
let mk_pkg_v = OpamPackage.Version.of_string

let check_scope () =
  let check_pkg pkg_name =
    let mem =
      OpamPackage.Name.Map.mem
        (OpamPackage.Name.of_string pkg_name)
        build_context.scope
    in
    if not mem then (
      Fmt.epr "Missing package in scope: %S@." pkg_name;
      raise Exit)
  in
  List.iter check_pkg
    [
      "onix-example";
      "bos";
      "cmdliner";
      "dune";
      "easy-format";
      "fpath";
      "ocaml";
      "opam-0install";
      "options";
      "uri";
      "yojson";
    ]

let check_self () =
  let self = build_context.self in
  assert (eq_pkg_name (mk_pkg_name "onix-example") self.name);
  assert (eq_pkg_v (mk_pkg_v "root") self.version)

let check_vars () =
  let check_var var_str expected =
    let full_var = OpamVariable.Full.of_string var_str in
    let actual =
      match Onix.Build_context.resolve build_context full_var with
      | Some var_contents ->
        OpamVariable.string_of_variable_contents var_contents
      | None -> ""
    in
    let eq = String.equal expected actual in
    if not eq then (
      Fmt.epr "Variable %S has incorrect value: expected=%S actual=%S@." var_str
        expected actual;
      raise Exit)
  in
  (* Global vars *)
  check_var "name" "onix-example";
  check_var "version" "root";
  check_var "make" "make";
  check_var "prefix" "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix";
  check_var "switch" "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix";
  check_var "root" "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix";
  check_var "sys-ocaml-version" "4.14.0";
  check_var "user" (Sys.getenv "USER");

  (* Self package *)
  check_var "installed" "true";
  check_var "pinned" "false";
  check_var "dev" "false";
  check_var "opamfile"
    "/nix/store/93l01ab4xqjn6q4n0nf25yasp8jf2jhv-onix-example.opam";
  check_var "lib"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/onix-example";
  check_var "stublibs"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/stublibs/onix-example";
  check_var "toplevel"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/toplevel/onix-example";
  check_var "man" "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/man";
  check_var "doc"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/doc/onix-example";
  check_var "share"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/share/onix-example";
  check_var "etc"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/etc/onix-example";

  check_var "_:installed" "true";
  check_var "_:pinned" "false";
  check_var "_:dev" "false";
  check_var "_:opamfile"
    "/nix/store/93l01ab4xqjn6q4n0nf25yasp8jf2jhv-onix-example.opam";
  check_var "_:lib"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/onix-example";
  check_var "_:stublibs"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/stublibs/onix-example";
  check_var "_:toplevel"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/lib/ocaml/4.14.0/site-lib/toplevel/onix-example";
  check_var "_:man" "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/man";
  check_var "_:doc"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/doc/onix-example";
  check_var "_:share"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/share/onix-example";
  check_var "_:etc"
    "/nix/store/yzy5ip0v895v7s2ld4i1dcv00cl8b7zf-onix/etc/onix-example";

  (* Pinned package *)
  check_var "options:name" "options";
  check_var "options:version" "dev";
  check_var "options:installed" "true";
  check_var "options:pinned" "true";
  check_var "options:dev" "false";
  check_var "options:opamfile"
    "/nix/store/shq4mwcvamqj9pw2jbs1b28bdpr4p50y-source/options.opam";
  check_var "options:lib"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/lib/ocaml/4.14.0/site-lib/options";
  check_var "options:stublibs"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/lib/ocaml/4.14.0/site-lib/stublibs/options";
  check_var "options:toplevel"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/lib/ocaml/4.14.0/site-lib/toplevel/options";
  check_var "options:man"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/man";
  check_var "options:doc"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/doc/options";
  check_var "options:share"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/share/options";
  check_var "options:etc"
    "/nix/store/qvnnk93pgl184021bbysp7036rzx30rh-options-dev/etc/options";

  (* Not installed package *)
  check_var "_not_a_package:name" "_not_a_package";
  check_var "_not_a_package:version" "";
  check_var "_not_a_package:installed" "false";
  check_var "_not_a_package:pinned" "false";
  check_var "_not_a_package:dev" "false";
  check_var "_not_a_package:opamfile" "";
  check_var "_not_a_package:build-id" "";
  check_var "_not_a_package:lib" "";
  check_var "_not_a_package:stublibs" "";
  check_var "_not_a_package:toplevel" "";
  check_var "_not_a_package:man" "";
  check_var "_not_a_package:doc" "";
  check_var "_not_a_package:share" "";
  check_var "_not_a_package:etc" "";

  (* Installed package *)
  check_var "bos:name" "bos";
  check_var "bos:version" "0.2.1";
  check_var "bos:installed" "true";
  check_var "bos:pinned" "false";
  check_var "bos:dev" "false";
  check_var "bos:opamfile"
    "/nix/store/b2i0qi80j88y0ajc658wf9gisidvmv5z-source/packages/bos/bos.0.2.1/opam";
  check_var "bos:build-id"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1";
  check_var "bos:lib"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/lib/ocaml/4.14.0/site-lib/bos";
  check_var "bos:stublibs"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/lib/ocaml/4.14.0/site-lib/stublibs/bos";
  check_var "bos:toplevel"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/lib/ocaml/4.14.0/site-lib/toplevel/bos";
  check_var "bos:man"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/man";
  check_var "bos:doc"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/doc/bos";
  check_var "bos:share"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/share/bos";
  check_var "bos:etc"
    "/nix/store/xfmk9f2ykalizkgfg620gbya67fa09si-bos-0.2.1/etc/bos";

  check_var "ocaml-config:share"
    "/nix/store/j49d3wydfm41n5mb4hlhkx3iv2fy92zd-ocaml-config-2/share/ocaml-config"

let () =
  check_scope ();
  check_self ();
  check_vars ()
