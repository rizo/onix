{ nixpkgs, onixpkgs, onix, self }:

onix.package {
  name = "zarith";
  version = "1.12";
  src = {
    url = "https://github.com/ocaml/Zarith/archive/release-1.12.tar.gz";
    sha512 =
      "8075573ae65579a2606b37dd1b213032a07d220d28c733f9288ae80d36f8a2cc4d91632806df2503c130ea9658dc207ee3a64347c21aa53969050a208f5b2bb4";
  };

  build = [
    [ [ "cmd3" ] { system = "aarch64_darwin"; } ]

    (on (os != "openbsd" && os != "freebsd" && os != "macos") [ "./configure" ])
    (on (os == "openbsd" || os == "freebsd") [
      "sh"
      "-exc"
      ''
        LDFLAGS="$LDFLAGS -L/usr/local/lib" CFLAGS="$CFLAGS -I/usr/local/include" ./configure''
    ])
    (on (os == "macos" && arch == "x86_64") [
      "sh"
      "-exc"
      ''
        LDFLAGS="$LDFLAGS -L/opt/local/lib -L/usr/local/lib" CFLAGS="$CFLAGS -I/opt/local/include -I/usr/local/include" ./configure''
    ])
    (on (os == "macos" && arch == "arm64") [
      "sh"
      "-exc"
      ''
        LDFLAGS="$LDFLAGS -L/opt/homebrew/lib" CFLAGS="$CFLAGS -I/opt/homebrew/include" ./configure''
    ])
    [ "make" ]

    [
      "ocaml"
      "pkg/build.ml"
      "native=${var ocaml "native"}"
      "native-dynlink=${ocaml "native-dynlink"}"
    ]
  ];

  install = with onix.vars; [
    [ make "install" ]
    (on (ocaml.var "preinstalled") [
      "install"
      "-m"
      "0755"
      "ocaml-stub"
      "${self "bin"}/ocaml"
    ])
  ];

  install' = with onix.vars; [
    [ vars.make "install" ]
    (on (var "ocaml" "preinstalled") [
      "install"
      "-m"
      "0755"
      "ocaml-stub"
      "${self "bin"}/ocaml"
    ])
  ];

  installPhase = ''
      "mkdir" "-p" "$out/lib/ocaml/4.14.0/site-lib"
      "make" "install"

    ${nixpkgs.opaline}/bin/opaline \
      -prefix="$out" \
      -libdir="$out/lib/ocaml/4.14.0/site-lib"
      
    if [[ -e "./zarith.config" ]]; then
      mkdir -p "$out/etc"
      cp "./zarith.config" "$out/etc/zarith.config"
    fi
  '';

  depends = [
    "ocaml"
    "ocamlfind"
    "conf-gmp"
    (on with-dev-setup "ocaml-lsp-server")
    (on (with-dev-setup || with-test) "utop")
    (on with-test "foo")
  ];
}
