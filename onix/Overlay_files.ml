(* Generated by: ocaml-crunch
   Creation date: Thu, 1 Jan 1970 00:00:00 GMT *)

module Internal = struct
  let d_0641bfb2c8c4b528e4c7a134e3fff076 = "Install topfind into OCAML_SITELIB instead of OCAML_CORE_STDLIB.\n--- a/src/findlib/Makefile\n+++ b/src/findlib/Makefile\n@@ -123,7 +123,7 @@ clean:\n install: all\n \tmkdir -p \"$(prefix)$(OCAML_SITELIB)/$(NAME)\"\n \tmkdir -p \"$(prefix)$(OCAMLFIND_BIN)\"\n-\ttest $(INSTALL_TOPFIND) -eq 0 || cp topfind \"$(prefix)$(OCAML_CORE_STDLIB)\"\n+\ttest $(INSTALL_TOPFIND) -eq 0 || cp topfind \"$(prefix)$(OCAML_SITELIB)\"\n\tfiles=`$(SH) $(TOP)/tools/collect_files $(TOP)/Makefile.config findlib.cmi findlib.mli findlib.cma findlib.cmxa findlib$(LIB_SUFFIX) findlib.cmxs topfind.cmi topfind.mli fl_package_base.mli fl_package_base.cmi fl_metascanner.mli fl_metascanner.cmi fl_metatoken.cmi findlib_top.cma findlib_top.cmxa findlib_top$(LIB_SUFFIX) findlib_top.cmxs findlib_dynload.cma findlib_dynload.cmxa findlib_dynload$(LIB_SUFFIX) findlib_dynload.cmxs fl_dynload.mli fl_dynload.cmi META` && \\\n\tcp $$files \"$(prefix)$(OCAML_SITELIB)/$(NAME)\"\n\tf=\"ocamlfind$(EXEC_SUFFIX)\"; { test -f ocamlfind_opt$(EXEC_SUFFIX) && f=\"ocamlfind_opt$(EXEC_SUFFIX)\"; }; \\"

  let d_28ed70306af9fa34a47e21cb046ada4e = "Install topfind into OCAML_SITELIB instead of OCAML_CORE_STDLIB.\ndiff --git a/findlib.conf.in b/findlib.conf.in\nindex 261d2c8..461bafc 100644\n--- a/findlib.conf.in\n+++ b/findlib.conf.in\n@@ -1,2 +1,3 @@\n destdir=\"@SITELIB@\"\n path=\"@SITELIB@\"\n+ldconf=\"ignore\"\n\\ No newline at end of file\ndiff --git a/src/findlib/Makefile b/src/findlib/Makefile\nindex 4fd3f81..5b9a81e 100644\n--- a/src/findlib/Makefile\n+++ b/src/findlib/Makefile\n@@ -123,7 +123,7 @@ clean:\n install: all\n \tmkdir -p \"$(prefix)$(OCAML_SITELIB)/$(NAME)\"\n \tmkdir -p \"$(prefix)$(OCAMLFIND_BIN)\"\n-\ttest $(INSTALL_TOPFIND) -eq 0 || cp topfind \"$(prefix)$(OCAML_CORE_STDLIB)\"\n+\ttest $(INSTALL_TOPFIND) -eq 0 || cp topfind \"$(prefix)$(OCAML_SITELIB)\"\n \tfiles=`$(SH) $(TOP)/tools/collect_files $(TOP)/Makefile.config \\\n \tfindlib.cmi findlib.mli findlib.cma findlib.cmxa findlib$(LIB_SUFFIX) findlib.cmxs \\\n \tfindlib_config.cmi findlib_config.ml topfind.cmi topfind.mli \\\n"

  let d_98a2b2b10256c3398b2416084918c00f = "nixpkgs: self: super:\n\nlet\n  inherit (nixpkgs) lib;\n\n  common = {\n    ocamlfind = super.ocamlfind.overrideAttrs (oldAttrs: {\n      patches = oldAttrs.patches or [ ]\n        ++ lib.optional (lib.versionOlder oldAttrs.version \"1.9.3\")\n        ./ocamlfind/onix_install_topfind_192.patch\n        ++ lib.optional (oldAttrs.version == \"1.9.3\")\n        ./ocamlfind/onix_install_topfind_193.patch\n        ++ lib.optional (oldAttrs.version == \"1.9.4\")\n        ./ocamlfind/onix_install_topfind_194.patch\n        ++ lib.optional (lib.versionAtLeast oldAttrs.version \"1.9.5\")\n        ./ocamlfind/onix_install_topfind_195.patch;\n\n      setupHook = nixpkgs.writeText \"ocamlfind-setup-hook.sh\" ''\n        [[ -z ''${strictDeps-} ]] || (( \"$hostOffset\" < 0 )) || return 0\n\n        addTargetOCamlPath () {\n          local libdir=\"$1/lib/ocaml/${super.ocaml.version}/site-lib\"\n\n          if [[ ! -d \"$libdir\" ]]; then\n            return 0\n          fi\n\n          echo \"+ onix-ocamlfind-setup-hook.sh/addTargetOCamlPath: $*\"\n\n          addToSearchPath \"OCAMLPATH\" \"$libdir\"\n          addToSearchPath \"CAML_LD_LIBRARY_PATH\" \"$libdir/stublibs\"\n        }\n\n        addEnvHooks \"$targetOffset\" addTargetOCamlPath\n\n        export OCAMLTOP_INCLUDE_PATH=\"$1/lib/ocaml/${super.ocaml.version}/site-lib/toplevel\"\n      '';\n    });\n\n    # topkg = super.topkg.overrideAttrs (oldAttrs: {\n    #   setupHook = nixpkgs.writeText \"topkg-setup-hook.sh\" ''\n    #     echo \">>> topkg-setup-hook: $1\"\n    #     addToSearchPath \"OCAMLPATH\" \"$1/lib/ocaml/${self.ocaml.version}/site-lib\"\n    #   '';\n    # });\n\n    ocb-stubblr = super.ocb-stubblr.overrideAttrs (oldAttrs: {\n      patches = oldAttrs.patches or [ ]\n        ++ [ ./ocb-stubblr/onix_disable_opam.patch ];\n    });\n\n    # https://github.com/ocsigen/lwt/pull/946\n    lwt_react = super.lwt_react.overrideAttrs (oldAttrs: {\n      nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]\n        ++ [ self.cppo or null ];\n    });\n\n    # https://github.com/pqwy/ocb-stubblr/blob/34dcbede6b51327172a0a3d83ebba02843aca249/src/ocb_stubblr.ml#L42\n    core_unix = super.core_unix.overrideAttrs (oldAttrs: {\n      prePatch = (oldAttrs.prePatch or \"\") + ''\n        patchShebangs unix_pseudo_terminal/src/discover.sh\n      '';\n    });\n\n    # For versions < 1.12\n    zarith = super.zarith.overrideAttrs (oldAttrs: {\n      prePatch = (oldAttrs.prePatch or \"\") + ''\n        if test -e ./z_pp.pl; then\n          patchShebangs ./z_pp.pl\n        fi\n      '';\n    });\n\n    # With propagated inputs this is not necessary.\n    # https://github.com/ocaml/opam-repository/blob/e470f5f4ad3083618a4e144668faaa81b726b912/packages/either/either.1.0.0/opam#L14\n    # either = super.either.overrideAttrs\n    #   (oldAttrs: { buildInputs = oldAttrs.buildInputs ++ [ self.ocaml ]; });\n    #\n    # ctypes = super.ctypes.overrideAttrs (selfAttrs: superAttrs: {\n    #   postInstall = ''\n    #     mkdir -p \"$out/lib/ocaml/4.14.0/site-lib/stublibs\"\n    #     mv $out/lib/ocaml/4.14.0/site-lib/ctypes/*.so \"$out/lib/ocaml/4.14.0/site-lib/stublibs\"\n    #   '';\n    # });\n\n    num = super.num.overrideAttrs (selfAttrs: superAttrs: {\n      postInstall = ''\n        mkdir -p \"$out/lib/ocaml/4.14.0/site-lib/stublibs\"\n        mv $out/lib/ocaml/4.14.0/site-lib/num/*.so \"$out/lib/ocaml/4.14.0/site-lib/stublibs\"\n      '';\n    });\n\n  };\n\n  darwin = {\n    dune = super.dune.overrideAttrs (oldAttrs: {\n      buildInputs = oldAttrs.buildInputs or [ ] ++ [\n        nixpkgs.darwin.apple_sdk.frameworks.Foundation\n        nixpkgs.darwin.apple_sdk.frameworks.CoreServices\n      ];\n    });\n  };\n\n  all = common\n    // nixpkgs.lib.optionalAttrs nixpkgs.stdenv.hostPlatform.isDarwin darwin;\n\n  # Remove overrides for packages not present in scope.\nin lib.attrsets.filterAttrs (name: _: builtins.hasAttr name super) all\n"

  let d_c1e35d8dd1f4dda676d93748749b7f3f = "diff --git a/src/ocb_stubblr.ml b/src/ocb_stubblr.ml\nindex b68c37a..ba716fe 100644\n--- a/src/ocb_stubblr.ml\n+++ b/src/ocb_stubblr.ml\n@@ -39,9 +39,8 @@ module Pkg_config = struct\n   let var = \"PKG_CONFIG_PATH\"\n \n   let path () =\n-    let opam = Lazy.force opam_prefix\n-    and rest = try [Sys.getenv var] with Not_found -> [] in\n-    opam/\"lib\"/\"pkgconfig\" :: opam/\"share\"/\"pkgconfig\" :: rest\n+    let rest = try [Sys.getenv var] with Not_found -> [] in\n+    rest\n       |> String.concat ~sep:\":\"\n \n   let run ~flags package =\n"

  let d_ea9e454a50fea8db98702fb3e7b26571 = "Install topfind into OCAML_SITELIB instead of OCAML_CORE_STDLIB.\ndiff --git a/src/findlib/Makefile b/src/findlib/Makefile\nindex 84514b6..12e4ef6 100644\n--- a/src/findlib/Makefile\n+++ b/src/findlib/Makefile\n@@ -123,8 +123,7 @@ clean:\n install: all\n \t$(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAML_SITELIB)/$(NAME)\"\n \t$(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAMLFIND_BIN)\"\n-\t$(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAML_CORE_STDLIB)\"\n-\ttest $(INSTALL_TOPFIND) -eq 0 || $(INSTALLFILE) topfind \"$(DESTDIR)$(prefix)$(OCAML_CORE_STDLIB)/\"\n+\ttest $(INSTALL_TOPFIND) -eq 0 || $(INSTALLFILE) topfind \"$(DESTDIR)$(prefix)$(OCAML_SITELIB)/\"\n \tfiles=`$(SH) $(TOP)/tools/collect_files $(TOP)/Makefile.config \\\n \tfindlib.cmi findlib.mli findlib.cma findlib.cmxa findlib$(LIB_SUFFIX) findlib.cmxs \\\n \tfindlib_config.cmi findlib_config.ml topfind.cmi topfind.mli \\\n"

  let d_fe137f390d6e7f6739ca9407651efb43 = "Install topfind into OCAML_SITELIB instead of OCAML_CORE_STDLIB.\nSee also: https://github.com/ocaml/opam-repository/blob/master/packages/ocamlfind/ocamlfind.1.9.5/files/0001-Fix-bug-when-installing-with-a-system-compiler.patch\ndiff --git a/findlib.conf.in b/findlib.conf.in\nindex 261d2c8..461bafc 100644\n--- a/findlib.conf.in\n+++ b/findlib.conf.in\n@@ -1,2 +1,3 @@\n destdir=\"@SITELIB@\"\n path=\"@SITELIB@\"\n+ldconf=\"ignore\"\n\\ No newline at end of file\ndiff --git a/src/findlib/Makefile b/src/findlib/Makefile\nindex 84514b6..12e4ef6 100644\n--- a/src/findlib/Makefile\n+++ b/src/findlib/Makefile\n@@ -123,8 +123,7 @@ clean:\n install: all\n \t$(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAML_SITELIB)/$(NAME)\"\n \t$(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAMLFIND_BIN)\"\n-\ttest $(INSTALL_TOPFIND) -eq 0 || $(INSTALLDIR) \"$(DESTDIR)$(prefix)$(OCAML_CORE_STDLIB)\"\n-\ttest $(INSTALL_TOPFIND) -eq 0 || $(INSTALLFILE) topfind \"$(DESTDIR)$(prefix)$(OCAML_CORE_STDLIB)/\"\n+\ttest $(INSTALL_TOPFIND) -eq 0 || $(INSTALLFILE) topfind \"$(DESTDIR)$(prefix)$(OCAML_SITELIB)/\"\n \tfiles=`$(SH) $(TOP)/tools/collect_files $(TOP)/Makefile.config \\\n \tfindlib.cmi findlib.mli findlib.cma findlib.cmxa findlib$(LIB_SUFFIX) findlib.cmxs \\\n \tfindlib_config.cmi findlib_config.ml topfind.cmi topfind.mli \\\n"

  let file_chunks = function
    | "default.nix" | "/default.nix" -> Some [ d_98a2b2b10256c3398b2416084918c00f; ]
    | "ocamlfind/onix_install_topfind_192.patch" | "/ocamlfind/onix_install_topfind_192.patch" -> Some [ d_0641bfb2c8c4b528e4c7a134e3fff076; ]
    | "ocamlfind/onix_install_topfind_193.patch" | "/ocamlfind/onix_install_topfind_193.patch" -> Some [ d_28ed70306af9fa34a47e21cb046ada4e; ]
    | "ocamlfind/onix_install_topfind_194.patch" | "/ocamlfind/onix_install_topfind_194.patch" -> Some [ d_ea9e454a50fea8db98702fb3e7b26571; ]
    | "ocamlfind/onix_install_topfind_195.patch" | "/ocamlfind/onix_install_topfind_195.patch" -> Some [ d_fe137f390d6e7f6739ca9407651efb43; ]
    | "ocb-stubblr/onix_disable_opam.patch" | "/ocb-stubblr/onix_disable_opam.patch" -> Some [ d_c1e35d8dd1f4dda676d93748749b7f3f; ]
    | _ -> None

  let file_list = [ "default.nix"; "ocamlfind/onix_install_topfind_192.patch"; "ocamlfind/onix_install_topfind_193.patch"; "ocamlfind/onix_install_topfind_194.patch"; "ocamlfind/onix_install_topfind_195.patch"; "ocb-stubblr/onix_disable_opam.patch"; ]
end

let file_list = Internal.file_list

let read name =
  match Internal.file_chunks name with
  | None -> None
  | Some c -> Some (String.concat "" c)

let hash = function
  | "default.nix" | "/default.nix" -> Some "98a2b2b10256c3398b2416084918c00f"
  | "ocamlfind/onix_install_topfind_192.patch" | "/ocamlfind/onix_install_topfind_192.patch" -> Some "0641bfb2c8c4b528e4c7a134e3fff076"
  | "ocamlfind/onix_install_topfind_193.patch" | "/ocamlfind/onix_install_topfind_193.patch" -> Some "28ed70306af9fa34a47e21cb046ada4e"
  | "ocamlfind/onix_install_topfind_194.patch" | "/ocamlfind/onix_install_topfind_194.patch" -> Some "ea9e454a50fea8db98702fb3e7b26571"
  | "ocamlfind/onix_install_topfind_195.patch" | "/ocamlfind/onix_install_topfind_195.patch" -> Some "fe137f390d6e7f6739ca9407651efb43"
  | "ocb-stubblr/onix_disable_opam.patch" | "/ocb-stubblr/onix_disable_opam.patch" -> Some "c1e35d8dd1f4dda676d93748749b7f3f"
  | _ -> None

let size = function
  | "default.nix" | "/default.nix" -> Some 3778
  | "ocamlfind/onix_install_topfind_192.patch" | "/ocamlfind/onix_install_topfind_192.patch" -> Some 1027
  | "ocamlfind/onix_install_topfind_193.patch" | "/ocamlfind/onix_install_topfind_193.patch" -> Some 925
  | "ocamlfind/onix_install_topfind_194.patch" | "/ocamlfind/onix_install_topfind_194.patch" -> Some 838
  | "ocamlfind/onix_install_topfind_195.patch" | "/ocamlfind/onix_install_topfind_195.patch" -> Some 1254
  | "ocb-stubblr/onix_disable_opam.patch" | "/ocb-stubblr/onix_disable_opam.patch" -> Some 526
  | _ -> None
