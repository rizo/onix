open Utils

let opam_name = OpamFile.OPAM.name
let pp_package = Fmt.using OpamPackage.to_string Fmt.string
let pp_package_version = Fmt.using OpamPackage.Version.to_string Fmt.string
let pp_package_name = Fmt.using OpamPackage.Name.to_string Fmt.string
let pp_url = Fmt.using OpamUrl.to_string Fmt.string
let pp_filename = Fmt.using OpamFilename.to_string Fmt.string
let pp_filename_dir = Fmt.using OpamFilename.Dir.to_string Fmt.string
let pp_hash = Fmt.using OpamHash.to_string Fmt.string

let read_opam path =
  let filename = OpamFile.make path in
  Utils.In_channel.with_open_text (OpamFilename.to_string path) (fun ic ->
      OpamFile.OPAM.read_from_channel ~filename ic)

let ocaml_name = OpamPackage.Name.of_string "ocaml"
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
         Fmt.epr "Reading packages from %S...@." filename;
         let opam = read_opam (OpamFilename.of_string filename) in
         let version = root_version in
         (opam_name, (version, opam)))
  |> OpamPackage.Name.Map.of_seq

let fetch url =
  let rev = url.OpamUrl.hash |> Option.or_fail "Missing rev in opam url" in
  let nix_url = OpamUrl.base_url url in
  Fmt.epr "[DEBUG] Fetching git repository: url=%S rev=%S@." nix_url rev;
  Nix_utils.fetch_git ~rev nix_url

let fetch_resolve url =
  let nix_url = OpamUrl.base_url url in
  Fmt.epr "[DEBUG] Fetching git repository: url=%S rev=None@." nix_url;
  Nix_utils.fetch_git_resolve nix_url

module Pins = struct
  type t = OpamPackage.t * OpamUrl.t

  let equal (pkg, url) (pkg', url') = OpamPackage.equal pkg pkg' && url = url'

  let pp fmt (pkg, url) =
    Format.fprintf fmt "(%a, %a)" pp_package pkg pp_url url

  let sort_uniq pin_depends =
    let add acc ((pkg, url) as t) =
      let name = OpamPackage.name pkg in
      match OpamPackage.Name.Map.find_opt name acc with
      | None -> OpamPackage.Name.Map.add name (pkg, url) acc
      | Some t' when equal t t' -> acc
      | Some (pkg', url') ->
        Fmt.failwith
          "Package %a is pinned to different versions/url:\n\
          \  - %a: %a\n\
          \  - %a: %a" pp_package_name name pp_package pkg pp_url url pp_package
          pkg' pp_url url'
    in
    List.fold_left add OpamPackage.Name.Map.empty pin_depends

  let collect_urls_from_opam_files project_opam_files =
    OpamPackage.Name.Map.fold
      (fun _pkg (_version, opam_file) acc ->
        OpamFile.OPAM.pin_depends opam_file @ acc)
      project_opam_files []
    |> sort_uniq

  let load_opam package url =
    let name = OpamPackage.name_to_string package in
    let src = fetch url in
    Fmt.epr "Reading opam file for pin: name=%S url=%a src=%a@." name pp_url url
      pp_filename_dir src;
    (* FIXME: Could be just ./opam *)
    let opam_path =
      OpamFilename.add_extension OpamFilename.Op.(src // name) "opam"
    in
    (dev_version, read_opam opam_path)

  let collect_from_opam_files project_opam_files =
    let pin_urls = collect_urls_from_opam_files project_opam_files in
    OpamPackage.Name.Map.map
      (fun (pkg, url) ->
        (* Read original opam file for pin and add use a fixed [url]. *)
        let version, opam = load_opam pkg url in
        let file_url = OpamFile.URL.create url in
        let opam' = OpamFile.OPAM.with_url file_url opam in
        (version, opam'))
      pin_urls
end
