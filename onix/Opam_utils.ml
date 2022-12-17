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

type dep_flags = {
  with_test : bool;
  with_doc : bool;
  with_dev_setup : bool;
}

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
let root_version = OpamPackage.Version.of_string "root"
let is_pinned_version version = OpamPackage.Version.equal version dev_version
let is_root_version version = OpamPackage.Version.equal version root_version
let is_pinned package = is_pinned_version (OpamPackage.version package)
let is_root package = is_root_version (OpamPackage.version package)

let opam_package_of_filename filename =
  let base_str = OpamFilename.Base.to_string (OpamFilename.basename filename) in
  if String.equal base_str "opam" then
    let dir_str = OpamFilename.Dir.to_string (OpamFilename.dirname filename) in
    match List.rev (String.split_on_char '/' dir_str) with
    | pkg_dir :: _ ->
      OpamPackage.create (OpamPackage.Name.of_string pkg_dir) root_version
    | _ ->
      invalid_arg
        ("Could not extract package name from path (must be pkg/opam): "
        ^ OpamFilename.to_string filename)
  else
    let opamname = Filename.remove_extension base_str in
    try OpamPackage.of_string opamname
    with Failure _ ->
      OpamPackage.create (OpamPackage.Name.of_string opamname) root_version

type dep_flag_scope =
  [ `root
  | `deps
  | `none
  | `all ]

let pp_dep_flag formatter dep_flag =
  let str =
    match dep_flag with
    | `root -> "root"
    | `deps -> "deps"
    | `none -> "none"
    | `all -> "all"
  in
  Fmt.pf formatter "%s" str

let eval_dep_flag ~version scope =
  let is_root = is_root_version version in
  match scope with
  | `root -> is_root
  | `deps -> not is_root
  | `all -> true
  | `none -> false

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
