open Utils

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
let ocamlfind_name = OpamPackage.Name.of_string "ocamlfind"
let dune_name = OpamPackage.Name.of_string "dune"
let ocamlbuild_name = OpamPackage.Name.of_string "ocamlbuild"
let topkg_name = OpamPackage.Name.of_string "ocamlfind"
let cppo_name = OpamPackage.Name.of_string "cppo"
let base_ocaml_compiler_name = OpamPackage.Name.of_string "ocaml-base-compiler"
let dune_configurator_name = OpamPackage.Name.of_string "dune-configurator"
let menhir_name = OpamPackage.Name.of_string "menhir"

let is_opam_filename filename =
  String.equal (Filename.extension filename) ".opam"

let dev_version = OpamPackage.Version.of_string "dev"
let root_version = OpamPackage.Version.of_string "root"
let is_pinned_version version = OpamPackage.Version.equal version dev_version
let is_root_version version = OpamPackage.Version.equal version root_version
let is_pinned package = is_pinned_version (OpamPackage.version package)
let is_root package = is_root_version (OpamPackage.version package)

let opam_package_of_filename filename =
  let basename = Filename.basename filename in
  let opamname = Filename.remove_extension basename in
  try OpamPackage.of_string opamname
  with Failure _ ->
    OpamPackage.create (OpamPackage.Name.of_string opamname) root_version

type dep_flag =
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

let find_root_packages input_opams =
  let opams =
    match input_opams with
    | [] ->
      let contents = Utils.Filesystem.list_dir "." in
      contents |> List.to_seq |> Seq.filter is_opam_filename
    | _ -> input_opams |> List.to_seq
  in
  opams
  |> Seq.map (fun filename ->
         let pkg = opam_package_of_filename filename in
         Logs.info (fun log -> log "Reading packages from %S..." filename);
         let opam = read_opam (OpamFilename.of_string filename) in
         (OpamPackage.name pkg, (OpamPackage.version pkg, opam)))
  |> OpamPackage.Name.Map.of_seq
