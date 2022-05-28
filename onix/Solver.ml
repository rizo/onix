let constraints = OpamPackage.Name.Map.empty

module Solver = Opam_0install.Solver.Make (Solver_context)

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

let solve ~repo_url ~with_test ~with_doc ~with_tools input_opam_files =
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
    Opam_utils.base_ocaml_compiler_name
    :: OpamPackage.Name.Map.keys root_packages
  in

  let repo_path, repo_url = resolve_repo repo_url in

  let context =
    Solver_context.make
      OpamFilename.Op.(repo_path / "packages")
      ~fixed_packages ~constraints ~with_test ~with_doc ~with_tools
  in
  Logs.info (fun log ->
      log "Solving dependencies... with-test=%a with-doc=%a with-tools=%a"
        Opam_utils.pp_dep_flag with_test Opam_utils.pp_dep_flag with_doc
        Opam_utils.pp_dep_flag with_tools);
  match Solver.solve context target_packages with
  | Ok selections ->
    let packages = Solver.packages_of_result selections in
    Fmt.pr "Resolved %d packages:@." (List.length packages);
    List.iter (Fmt.pr "- %a@." Opam_utils.pp_package) packages;
    packages
    |> List.filter_map (fun pkg ->
           let opam = Solver_context.get_opam_file context pkg in
           match Lock_pkg.of_opam ~with_test ~with_doc ~with_tools pkg opam with
           | None ->
             Logs.warn (fun log ->
                 log "Missing url for %a, ignoring..." Opam_utils.pp_package pkg);
             None
           | some -> some)
    |> Lock_file.make ~repo_url
  | Error err ->
    prerr_endline (Solver.diagnostics err);
    exit 2
