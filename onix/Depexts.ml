let from_opam_name pkg_name =
  match OpamPackage.Name.to_string pkg_name with
  | "conf-bap-llvm" -> Some ["llvm.dev"]
  | "bap-llvm" -> Some ["libxml2"; "ncurses"]
  | "conf-binutils" -> Some ["binutils"]
  | "bap-std" -> Some ["binutils"; "zlib"]
  | "bitvec-sexp" -> Some ["which"]
  | _ -> None