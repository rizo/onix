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
  "dep-tool-1" {with-dev-setup}
  "dep-tool-2" {with-dev-setup}
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
  "opt-tool-1" {with-dev-setup}
  "opt-tool-2" {with-dev-setup}
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

let installed _ = true

let mk_lock ~name str =
  let package = OpamPackage.of_string name in
  let opam = OpamFile.OPAM.read_from_string str in
  let opam_details = { Onix.Opam_utils.package; opam; path = None } in
  Onix.Lock_pkg.of_opam ~installed ~with_dev_setup:`all ~with_test:`all
    ~with_doc:`all opam_details
  |> Option.get

let test_complex_opam () =
  let lock_pkg = mk_lock ~name:"complex.root" complex_opam in
  let actual =
    Fmt.str "%a@." (Onix.Lock_pkg.pp_nix ~ignore_file:None) lock_pkg
  in
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
  let actual =
    Fmt.str "%a@." (Onix.Lock_pkg.pp_nix ~ignore_file:None) lock_pkg
  in
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
  let actual =
    Fmt.str "%a@." (Onix.Lock_pkg.pp_nix ~ignore_file:None) lock_pkg
  in
  let expected =
    {|name = "zip"; version = "1.0.2";
src = pkgs.fetchurl {
  url = "https://github.com/xavierleroy/camlzip/archive/rel110.zip";
  sha256 = "a5541cbc38c14467a8abcbdcb54c1d2ed12515c1c4c6da0eb3bdafb44aff7996";
}; opam = "${repo}/packages/zip/zip.1.0.2/opam";
depexts = with pkgs; [ unzip ];
|}
  in
  eq ~actual ~expected

let test_other_deps_opam () =
  let lock_pkg = mk_lock ~name:"other-deps.1.0.1" other_deps_opam in
  let actual =
    Fmt.str "%a@." (Onix.Lock_pkg.pp_nix ~ignore_file:None) lock_pkg
  in
  let expected =
    {|name = "other-deps"; version = "1.0.1";
opam = "${repo}/packages/other-deps/other-deps.1.0.1/opam";
depends = with self; [ dep1 dep2 (self.opt1 or null) (self.opt2 or null) ];
buildDepends = with self; [ dep-build-1 dep-build-2
                            (self.opt-build-1 or null)
                            (self.opt-build-2 or null) ];
testDepends = with self; [ dep-test-1 dep-test-2 dep-test-o-doc-1
                           (self.opt-test-1 or null)
                           (self.opt-test-2 or null)
                           (self.opt-test-o-doc-1 or null) ];
docDepends = with self; [ dep-doc-1 dep-doc-2 dep-test-o-doc-1
                          (self.opt-doc-1 or null) (self.opt-doc-2 or null)
                          (self.opt-test-o-doc-1 or null) ];
devSetupDepends = with self; [ dep-tool-1 dep-tool-2 (self.opt-tool-1 or null)
                            (self.opt-tool-2 or null) ];
depexts = with pkgs; [ (pkgs.opt-ext-1 or null) (pkgs.opt-ext-2 or null)
                       (pkgs.opt-ext-3 or null) ];
|}
  in
  eq ~actual ~expected

let () =
  test_complex_opam ();
  test_dev_opam ();
  test_zip_src_opam ();
  test_other_deps_opam ()
