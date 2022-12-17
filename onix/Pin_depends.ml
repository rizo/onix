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

(* FIXME: validate pin-depends urls/format *)
let collect_urls_from_opam_files project_opam_files =
  OpamPackage.Name.Map.fold
    (fun _pkg { Opam_utils.opam; _ } acc ->
      OpamFile.OPAM.pin_depends opam @ acc)
    project_opam_files []
  |> sort_uniq

(* Returns the opam path and opam representation.  *)
let load_opam package src =
  let name = OpamPackage.name_to_string package in
  let opam_path =
    let without_pkg_name = OpamFilename.Op.(src // "opam") in
    if OpamFilename.exists without_pkg_name then without_pkg_name
    else
      let with_pkg_name =
        OpamFilename.add_extension OpamFilename.Op.(src // name) "opam"
      in
      if OpamFilename.exists with_pkg_name then with_pkg_name
      else
        Fmt.invalid_arg "Could not find opam file for package %s in %s" name
          (OpamFilename.Dir.to_string src)
  in
  (opam_path, Opam_utils.read_opam opam_path)

(* Better error for missing files/paths. *)
let collect_from_opam_files project_opam_files =
  let pin_urls = collect_urls_from_opam_files project_opam_files in
  OpamPackage.Name.Map.map
    (fun (pkg, url) ->
      let name_str = OpamPackage.name_to_string pkg in
      (* If the pinned url uses the file transport, we considered it a local "root". *)
      if String.equal url.OpamUrl.transport "file" then (
        (* FIXME: Dir.of_string resolves to absolute path. *)
        let src = OpamFilename.Dir.of_string url.OpamUrl.path in
        Logs.debug (fun log ->
            log "Reading opam file for vendored pin: name=%S url=%a src=%a"
              name_str Opam_utils.pp_url url Opam_utils.pp_filename_dir src);
        let path, opam = load_opam pkg src in
        (* Ensure the opam file does not have a remote url field. *)
        let opam = OpamFile.OPAM.with_url_opt None opam in
        let package =
          OpamPackage.create (OpamPackage.name pkg) Opam_utils.root_version
        in
        { Opam_utils.package; opam; path })
      else
        (* Read original opam file for pin and use a fixed [url]. *)
        let src = Nix_utils.fetch_git url in
        Logs.debug (fun log ->
            log "Reading opam file for remote pin: name=%S url=%a src=%a"
              name_str Opam_utils.pp_url url Opam_utils.pp_filename_dir src);
        let path, opam = load_opam pkg src in
        let file_url = OpamFile.URL.create url in
        let opam = OpamFile.OPAM.with_url file_url opam in
        let package =
          OpamPackage.create (OpamPackage.name pkg) Opam_utils.dev_version
        in
        { package; opam; path })
    pin_urls
