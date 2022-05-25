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
      ocaml_name;
      ocamlfind_name;
      dune_name;
      ocamlbuild_name;
      topkg_name;
      cppo_name;
    ]
