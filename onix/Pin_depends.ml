open Utils

let equal (pkg, url) (pkg', url') = OpamPackage.equal pkg pkg' && url = url'

let _pp fmt (pkg, url) =
  Format.fprintf fmt "(%a, %a)" Opam_utils.pp_package pkg Opam_utils.pp_url url

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
        \  - %a: %a" Opam_utils.pp_package_name name Opam_utils.pp_package pkg
        Opam_utils.pp_url url Opam_utils.pp_package pkg' Opam_utils.pp_url url'
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
  let src = Nix_utils.fetch url in
  Logs.debug (fun log ->
      log "Reading opam file for pin: name=%S url=%a src=%a" name
        Opam_utils.pp_url url Opam_utils.pp_filename_dir src);
  (* FIXME: Could be just ./opam *)
  let opam_path =
    OpamFilename.add_extension OpamFilename.Op.(src // name) "opam"
  in
  (Opam_utils.dev_version, Opam_utils.read_opam opam_path)

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