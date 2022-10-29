module Opam_0install_solver = Opam_0install.Solver.Make (Solver_context)

let resolve_repo repo_url =
  let path, url =
    let url = OpamUrl.of_string repo_url in
    if Option.is_some url.hash then (Nix_utils.fetch url, url)
    else
      let rev, path = Nix_utils.fetch_resolve url in
      (path, { url with hash = Some rev })
  in
  Logs.info (fun log -> log "Using OPAM repository: %a" Opam_utils.pp_url url);
  (path, url)

let solve ?(resolutions = []) ~repo_url ~with_test ~with_doc ~with_dev_setup
    input_opam_files =
  let resolutions = Resolutions.make resolutions in
  Resolutions.debug resolutions;

  (* Packages with .opam files at the root of the project. *)
  let root_packages = Opam_utils.find_root_packages input_opam_files in

  (* Pin-depends packages found in root_packages. *)
  let pins = Pin_depends.collect_from_opam_files root_packages in

  (* Packages provided by the project (roots + pins). *)
  let fixed_packages =
    OpamPackage.Name.Map.union
      (fun _local _pin ->
        failwith "Locally defined packages are not allowed in pin-depends")
      root_packages pins
  in

  (* Packages to start solve with (roots + ocaml compiler). *)
  let target_packages =
    List.append
      (Resolutions.all resolutions)
      (OpamPackage.Name.Map.keys root_packages)
  in

  let repo_path, repo_url = resolve_repo repo_url in

  let constraints = Resolutions.constraints resolutions in

  let context =
    Solver_context.make
      OpamFilename.Op.(repo_path / "packages")
      ~fixed_packages ~constraints ~with_test ~with_doc ~with_dev_setup
  in

  let get_opam_details package =
    let name = OpamPackage.name package in
    try OpamPackage.Name.Map.find name fixed_packages
    with Not_found ->
      let opam = Solver_context.get_opam_file context package in
      { package; path = None; opam }
  in

  Logs.info (fun log ->
      log "Solving dependencies... with-test=%a with-doc=%a with-dev-setup=%a"
        Opam_utils.pp_dep_flag with_test Opam_utils.pp_dep_flag with_doc
        Opam_utils.pp_dep_flag with_dev_setup);
  Logs.info (fun log ->
      log "Target packages: %a"
        Fmt.(list ~sep:Fmt.sp Opam_utils.pp_package_name)
        target_packages);
  match Opam_0install_solver.solve context target_packages with
  | Ok selections ->
    let packages =
      selections
      |> Opam_0install_solver.packages_of_result
      |> List.fold_left
           (fun acc pkg ->
             OpamPackage.Name.Map.add (OpamPackage.name pkg) pkg acc)
           OpamPackage.Name.Map.empty
    in
    Fmt.pr "Resolved %d packages:@." (OpamPackage.Name.Map.cardinal packages);
    OpamPackage.Name.Map.iter
      (fun _ -> Fmt.pr "- %a@." Opam_utils.pp_package)
      packages;
    let installed name = OpamPackage.Name.Map.mem name packages in
    packages
    |> OpamPackage.Name.Map.filter_map (fun _ pkg ->
           match
             let opam_details = get_opam_details pkg in
             Lock_pkg.of_opam ~installed ~with_test ~with_doc ~with_dev_setup
               opam_details
           with
           | None ->
             Logs.warn (fun log ->
                 log "Missing url for %a, ignoring..." Opam_utils.pp_package pkg);
             None
           | some -> some)
    |> OpamPackage.Name.Map.values
    |> Lock_file.make ~repo_url
  | Error err ->
    prerr_endline (Opam_0install_solver.diagnostics err);
    exit 2
