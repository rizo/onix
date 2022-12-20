module Opam_0install_solver = Opam_0install.Solver.Make (Solver_context)

let solve ?(resolutions = []) ~repository_urls ~with_test ~with_doc
    ~with_dev_setup opam_file_paths =
  let resolutions = Resolutions.make resolutions in
  Resolutions.debug resolutions;

  (* Packages with .opam files at the root of the project. *)
  let root_opam_details = Opam_utils.find_root_packages opam_file_paths in

  (* Pin-depends packages found in root_packages. *)
  let pin_opam_details =
    Pin_depends.collect_from_opam_files root_opam_details
  in

  (* Packages provided by the project (roots + pins). *)
  let fixed_opam_details =
    OpamPackage.Name.Map.union
      (fun _local _pin ->
        failwith "Locally defined packages are not allowed in pin-depends")
      root_opam_details pin_opam_details
  in

  (* Packages to start solve with (roots + user-provided resolutions). *)
  let target_package_names =
    List.append
      (Resolutions.all resolutions)
      (OpamPackage.Name.Map.keys root_opam_details)
  in

  let repository_dir, resolved_repository_urls =
    Nix_utils.resolve_repos repository_urls
  in
  let constraints = Resolutions.constraints resolutions in

  let context =
    Solver_context.make
      OpamFilename.Op.(repository_dir / "packages")
      ~fixed_opam_details ~constraints ~with_test ~with_doc ~with_dev_setup
  in

  let get_opam_details package =
    let name = OpamPackage.name package in
    try OpamPackage.Name.Map.find name fixed_opam_details
    with Not_found ->
      let opam = Solver_context.get_opam_file context package in
      let path = Opam_utils.mk_repo_opamfile ~repository_dir package in
      { package; path; opam }
  in

  Logs.info (fun log ->
      log "Solving dependencies... with-test=%a with-doc=%a with-dev-setup=%a"
        Opam_utils.pp_dep_flag with_test Opam_utils.pp_dep_flag with_doc
        Opam_utils.pp_dep_flag with_dev_setup);
  Logs.info (fun log ->
      log "Target packages: %a"
        Fmt.(list ~sep:Fmt.sp Opam_utils.pp_package_name)
        target_package_names);
  match Opam_0install_solver.solve context target_package_names with
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
    |> Lock_file.make ~repository_urls:resolved_repository_urls
  | Error err ->
    prerr_endline (Opam_0install_solver.diagnostics err);
    exit 2
