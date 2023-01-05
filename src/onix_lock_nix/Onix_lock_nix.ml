open Prelude

let gen_pkg ~lock_dir ~ocaml_version ~gitignore ~with_test ~with_doc
    ~with_dev_setup (lock_pkg : Lock_pkg.t) =
  let pkg_default_nix =
    let pkg_name = OpamPackage.name_to_string lock_pkg.opam_details.package in
    let pkg_lock_dir = lock_dir </> "packages" </> pkg_name in
    OpamFilename.mkdir pkg_lock_dir;
    OpamFilename.to_string (pkg_lock_dir <//> "default.nix")
  in
  Out_channel.with_open_text pkg_default_nix @@ fun chan ->
  let nix_pkg =
    Nix_pkg.of_lock_pkg ~ocaml_version ~with_test ~with_doc ~with_dev_setup
      lock_pkg
  in
  let nix_pkg = Nix_pkg.resolve_files ~lock_dir nix_pkg in
  let out = Format.formatter_of_out_channel chan in
  Fmt.pf out "%a" (Pp.pp_pkg ~gitignore) nix_pkg

let gen_overlay ~lock_dir =
  let overlay_dir = lock_dir </> "overlay" in
  List.iter
    (fun relpath ->
      let file = OpamFilename.(create overlay_dir (Base.of_string relpath)) in
      let dir = OpamFilename.dirname file in
      OpamFilename.mkdir dir;
      match Overlay_files.read relpath with
      | None ->
        Fmt.failwith "internal error: could not read embedded overlay file: %a"
          Opam_utils.pp_filename file
      | Some file_content -> OpamFilename.write file file_content)
    Overlay_files.file_list

let gen_index ~lock_dir lock_pkgs =
  let index_file =
    OpamFilename.Op.(lock_dir // "default.nix") |> OpamFilename.to_string
  in
  Out_channel.with_open_text index_file @@ fun chan ->
  let f = Format.formatter_of_out_channel chan in
  Pp.pp_index f lock_pkgs

let gen ~gitignore ~lock_dir ~with_test ~with_doc ~with_dev_setup
    (lock_file : Lock_file.t) =
  let ocaml_version = OpamPackage.version lock_file.compiler in
  let lock_dir = OpamFilename.Dir.of_string lock_dir in
  OpamFilename.rmdir lock_dir;
  OpamFilename.mkdir lock_dir;
  gen_overlay ~lock_dir;
  gen_index ~lock_dir lock_file.packages;
  List.iter
    (gen_pkg ~lock_dir ~ocaml_version ~gitignore ~with_test ~with_doc
       ~with_dev_setup)
    lock_file.packages

module Nix_pkg = Nix_pkg
module Nix_filter = Nix_filter
module Pp = Pp
