let depexts_for_opam_name pkg_name =
  match OpamPackage.Name.to_string pkg_name with
  | "conf-bap-llvm" -> Some ["pkgsStatic.llvm.dev"]
  | "bap-llvm" -> Some ["libxml2"; "ncurses"]
  | "conf-binutils" -> Some ["binutils"]
  | "bap-std" -> Some ["binutils"; "zlib"]
  | "bitvec-sexp" -> Some ["which"]
  | "conf-gmp" -> Some ["gmp.dev"]
  | _ -> None

(* Always include these packages in buildDepends in the lock-file, if they
   are present in depends. *)
let build_depends_names =
  Opam_utils.
    [
      ocaml_base_compiler_name;
      ocaml_system_name;
      ocaml_variants_name;
      ocamlfind_name;
      dune_name;
      dune_configurator_name;
      ocamlbuild_name;
      topkg_name;
      cppo_name;
      menhir_name;
    ]

let ocamlfind_setup_hook =
  {|
    [[ -z ''${strictDeps-} ]] || (( "$hostOffset" < 0 )) || return 0

    addTargetOCamlPath () {
      local libdir="$1/lib/ocaml/${ocaml.version}/site-lib"

      if [[ ! -d "$libdir" ]]; then
        return 0
      fi

      echo "+ onix-ocamlfind-setup-hook.sh/addTargetOCamlPath: $*"

      addToSearchPath "OCAMLPATH" "$libdir"
      addToSearchPath "CAML_LD_LIBRARY_PATH" "$libdir/stublibs"
    }

    addEnvHooks "$targetOffset" addTargetOCamlPath

    export OCAMLTOP_INCLUDE_PATH="$1/lib/ocaml/${ocaml.version}/site-lib/toplevel"
|}
