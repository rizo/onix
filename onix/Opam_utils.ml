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

let is_opam_filename filename =
  String.equal (Filename.extension filename) ".opam"

let opam_name_of_filename filename =
  let basename = Filename.remove_extension filename in
  OpamPackage.Name.of_string basename

let dev_version = OpamPackage.Version.of_string "dev"
let root_version = OpamPackage.Version.of_string "root"
let is_pinned_version version = OpamPackage.Version.equal version dev_version
let is_root_version version = OpamPackage.Version.equal version root_version
let is_pinned package = is_pinned_version (OpamPackage.version package)
let is_root package = is_root_version (OpamPackage.version package)

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
         let opam_name = opam_name_of_filename filename in
         Logs.info (fun log -> log "Reading packages from %S..." filename);
         let opam = read_opam (OpamFilename.of_string filename) in
         let version = root_version in
         (opam_name, (version, opam)))
  |> OpamPackage.Name.Map.of_seq
