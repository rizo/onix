open Utils

type opam_file_type =
  [ `opam
  | `pkg_opam ]

(* path:
   - pkg.opam
   - vendor/pkg/pkg.opam
   - vendor/pkg/opam
   - $repo/packages/pkg/pkg.version/opam *)
type opam_details = {
  package : OpamTypes.package;
  path : OpamFilename.t;
  opam : OpamFile.OPAM.t;
}

let root_dir = OpamFilename.Dir.of_string "/"

module Opam_details = struct
  type t = opam_details

  let check_has_absolute_path t = OpamFilename.starts_with root_dir t.path
end

let opam_name = OpamFile.OPAM.name
let pp_package = Fmt.using OpamPackage.to_string Fmt.string
let pp_package_version = Fmt.using OpamPackage.Version.to_string Fmt.string
let pp_package_name = Fmt.using OpamPackage.Name.to_string Fmt.string
let pp_url = Fmt.using OpamUrl.to_string Fmt.string
let pp_filename = Fmt.using OpamFilename.to_string Fmt.string
let pp_filename_dir = Fmt.using OpamFilename.Dir.to_string Fmt.string
let pp_filename_base = Fmt.using OpamFilename.Base.to_string Fmt.string
let pp_hash = Fmt.using OpamHash.to_string Fmt.string

let read_opam path =
  let filename = OpamFile.make path in
  Utils.In_channel.with_open_text (OpamFilename.to_string path) (fun ic ->
      OpamFile.OPAM.read_from_channel ~filename ic)

let ocaml_name = OpamPackage.Name.of_string "ocaml"
let ocaml_config_name = OpamPackage.Name.of_string "ocaml-config"
let ocamlfind_name = OpamPackage.Name.of_string "ocamlfind"
let dune_name = OpamPackage.Name.of_string "dune"
let ocamlbuild_name = OpamPackage.Name.of_string "ocamlbuild"
let topkg_name = OpamPackage.Name.of_string "ocamlfind"
let cppo_name = OpamPackage.Name.of_string "cppo"
let ocaml_base_compiler_name = OpamPackage.Name.of_string "ocaml-base-compiler"
let ocaml_system_name = OpamPackage.Name.of_string "ocaml-system"
let ocaml_variants_name = OpamPackage.Name.of_string "ocaml-variants"
let dune_configurator_name = OpamPackage.Name.of_string "dune-configurator"
let menhir_name = OpamPackage.Name.of_string "menhir"

let is_ocaml_compiler_name name =
  OpamPackage.Name.equal name ocaml_base_compiler_name
  || OpamPackage.Name.equal name ocaml_system_name
  || OpamPackage.Name.equal name ocaml_variants_name

let dev_version = OpamPackage.Version.of_string "dev"
let is_pinned_version version = OpamPackage.Version.equal version dev_version
let is_pinned package = is_pinned_version (OpamPackage.version package)

let opam_package_of_filename filename =
  let base_str = OpamFilename.Base.to_string (OpamFilename.basename filename) in
  if String.equal base_str "opam" then
    let dir_str = OpamFilename.Dir.to_string (OpamFilename.dirname filename) in
    match List.rev (String.split_on_char '/' dir_str) with
    | pkg_dir :: _ ->
      OpamPackage.create (OpamPackage.Name.of_string pkg_dir) dev_version
    | _ ->
      invalid_arg
        ("Could not extract package name from path (must be pkg/opam): "
        ^ OpamFilename.to_string filename)
  else
    let opamname = Filename.remove_extension base_str in
    try OpamPackage.of_string opamname
    with Failure _ ->
      OpamPackage.create (OpamPackage.Name.of_string opamname) dev_version

type dep_vars = {
  test : bool;
  doc : bool;
  dev_setup : bool;
}

type package_dep_vars = dep_vars OpamPackage.Name.Map.t

let eval_package_dep_vars name package_dep_vars =
  try OpamPackage.Name.Map.find name package_dep_vars
  with Not_found -> { test = false; doc = false; dev_setup = false }

let debug_var ?(scope = "unknown") var contents =
  Logs.debug (fun log ->
      log "Variable lookup: %s=%a scope=%s"
        (OpamVariable.Full.to_string var)
        (Fmt.Dump.option
           (Fmt.using OpamVariable.string_of_variable_contents Fmt.Dump.string))
        contents scope)

let find_root_packages input_paths =
  input_paths
  |> List.to_seq
  |> Seq.map (fun path ->
         let package = opam_package_of_filename path in
         Logs.info (fun log ->
             log "Reading packages from %a..." pp_filename path);
         let opam = read_opam path in
         let details = { opam; package; path } in
         (OpamPackage.name package, details))
  |> OpamPackage.Name.Map.of_seq

let mk_repo_opamfile ~(repository_dir : OpamFilename.Dir.t) opam_package =
  let name = OpamPackage.name_to_string opam_package in
  let name_with_version = OpamPackage.to_string opam_package in
  OpamFilename.Op.(
    repository_dir / "packages" / name / name_with_version // "opam")

let make_opam_files_path ~opamfile file =
  let opam_dir = OpamFilename.dirname opamfile in
  let file = OpamFilename.Base.to_string file in
  let base = OpamFilename.Base.of_string ("files/" ^ file) in
  OpamFilename.create opam_dir base

type extra_file_status =
  | Undeclared
  | Ok_hash
  | Bad_hash

(* Undeclared extra-files are looked up in ./files in the opam file directory. *)
let lookup_undeclared_opam_extra_files ~opamfile =
  let ( </> ) = OpamFilename.Op.( / ) in
  let files_dir = OpamFilename.(dirname opamfile </> "files") in
  OpamFilename.files files_dir

(* Check hashes for opam's extra files.
   Returns a tuple (files_with_bad_hashes, files_with_good_hashes). *)
let check_extra_files_hashes ~opamfile extra_files =
  List.partition_map
    (fun (basename, hash) ->
      let file = make_opam_files_path ~opamfile basename in
      if OpamHash.check_file (OpamFilename.to_string file) hash then Right file
      else Left file)
    extra_files
