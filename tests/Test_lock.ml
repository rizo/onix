let complex_opam =
  {|
opam-version: "2.0"
depends: [
  "ocaml" {>= "4.08" & < "5.0.0"}
  "dune" {>= "2.0"}
  "odoc" {with-doc}
  "bos"
  "cmdliner"
  "logs"
  "fmt"
  "fpath"
  "opam-0install"
  "yojson"
  "easy-format" {="1.3.2"}
]
depexts: [
  ["libogg-dev"] {os-distribution = "alpine"}
  ["libogg"] {os-distribution = "arch"}
  ["libogg-dev"] {os-family = "debian"}
  ["libogg-devel"] {os-distribution = "centos"}
  ["libogg-devel"] {os-distribution = "fedora"}
  ["libogg-devel"] {os-family = "suse"}
  ["libogg"] {os-distribution = "nixos"}
  ["libogg"] {os = "macos" & os-distribution = "homebrew"}
]
|}

let dev_opam =
  {|
opam-version: "2.0"
url {
  src: "git+https://github.com/odis-labs/options.git#5b1165d99aba112d550ddc3133a8eb1d174441ec"
}
|}

let zip_src_opam =
  {|
opam-version: "2.0"
url {
  src: "https://github.com/xavierleroy/camlzip/archive/rel110.zip"
  checksum: "sha256=a5541cbc38c14467a8abcbdcb54c1d2ed12515c1c4c6da0eb3bdafb44aff7996"
}
|}

let other_deps_opam =
  {|
opam-version: "2.0"
depends: [
  "dep1"
  "dep2"
  "dep-build-1" {build}
  "dep-build-2" {build}
  "dep-test-1" {with-test}
  "dep-test-2" {with-test}
  "dep-doc-1" {with-doc}
  "dep-doc-2" {with-doc}
  "dep-tool-1" {with-tools}
  "dep-tool-2" {with-tools}
  "dep-test-o-doc-1" {with-test | with-doc}
  "dep-test-n-doc-1" {with-test & with-doc}
]
depopts: [
  "opt1"
  "opt2"
  "opt-build-1" {build}
  "opt-build-2" {build}
  "opt-test-1" {with-test}
  "opt-test-2" {with-test}
  "opt-doc-1" {with-doc}
  "opt-doc-2" {with-doc}
  "opt-tool-1" {with-tools}
  "opt-tool-2" {with-tools}
  "opt-test-o-doc-1" {with-test | with-doc}
  "opt-test-n-doc-1" {with-test & with-doc}
]
depexts: [
  ["opt-ext-1" "opt-ext-2" "opt-ext-3"] {os-distribution = "alpine"}
]
|}

let eq ~actual ~expected =
  if not (String.equal actual expected) then (
    Fmt.pr "--- EXPECTED ---\n%s\n\n--- ACTUAL ---\n%s@." expected actual;
    raise Exit)

let mk_lock ?with_build ?with_test ?with_doc ~name str =
  let pkg = OpamPackage.of_string name in
  str
  |> OpamFile.OPAM.read_from_string
  |> Onix.Lock_pkg.of_opam ?with_build ?with_test ?with_doc pkg
  |> Option.get

let test_complex_opam () =
  let lock_pkg = mk_lock ~name:"complex.root" complex_opam in
  let actual = Fmt.str "%a@." (Onix.Lock_pkg.pp ~gitignore:true) lock_pkg in
  let expected =
    {|name = "complex"; version = "root"; src = ./.; opam = "${src}/complex.opam";
depends = with self; [ bos cmdliner dune easy-format fmt fpath logs ocaml
                       opam-0install yojson ];
buildDepends = with self; [ dune ocaml ]; docDepends = with self; [ odoc ];
depexts = with pkgs; [ libogg ];
|}
  in
  eq ~actual ~expected

let test_dev_opam () =
  let lock_pkg = mk_lock ~name:"dev.dev" dev_opam in
  let actual = Fmt.str "%a@." (Onix.Lock_pkg.pp ~gitignore:false) lock_pkg in
  let expected =
    {|name = "dev"; version = "dev";
src = builtins.fetchGit {
  url = "https://github.com/odis-labs/options.git";
  rev = "5b1165d99aba112d550ddc3133a8eb1d174441ec";
  allRefs = true; };
opam = "${src}/dev.opam";
|}
  in
  eq ~actual ~expected

let test_zip_src_opam () =
  let lock_pkg = mk_lock ~name:"zip.1.0.2" zip_src_opam in
  let actual = Fmt.str "%a@." (Onix.Lock_pkg.pp ~gitignore:false) lock_pkg in
  let expected =
    {|name = "zip"; version = "1.0.2";
src = pkgs.fetchurl {
  url = "https://github.com/xavierleroy/camlzip/archive/rel110.zip";
  sha256 = "a5541cbc38c14467a8abcbdcb54c1d2ed12515c1c4c6da0eb3bdafb44aff7996";
}; opam = "${opam-repo}/packages/zip/zip.1.0.2/opam";
depexts = with pkgs; [ unzip ];
|}
  in
  eq ~actual ~expected

let test_other_deps_opam () =
  let lock_pkg =
    mk_lock ~name:"other-deps.1.0.1" ~with_test:true ~with_doc:true
      other_deps_opam
  in
  let actual = Fmt.str "%a@." (Onix.Lock_pkg.pp ~gitignore:false) lock_pkg in
  let expected =
    {|name = "zip"; version = "1.0.2";
  src = pkgs.fetchurl {
    url = "https://github.com/xavierleroy/camlzip/archive/rel110.zip";
    sha256 = "a5541cbc38c14467a8abcbdcb54c1d2ed12515c1c4c6da0eb3bdafb44aff7996";
  }; opam = "${opam-repo}/packages/zip/zip.1.0.2/opam";
  depends = with self; [ ];
  depexts = [ pkgs.unzip ];
  |}
  in
  eq ~actual ~expected

let () =
  test_complex_opam ();
  test_dev_opam ();
  test_zip_src_opam ();
  test_other_deps_opam ()
