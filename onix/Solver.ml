let env =
  Solver_context.std_env ~arch:"x86_64" ~os:"linux" ~os_family:"debian"
    ~os_distribution:"debian" ~os_version:"10" ()

let make_context ~repo_path fixed_packages =
  Solver_context.make
    Fpath.(repo_path / "packages")
    ~fixed_packages ~constraints:OpamPackage.Name.Map.empty ~env

module Solver = Opam_0install.Solver.Make (Solver_context.Required)

let solve ~repo_url ~root_packages ~pins package_names =
  let repo_path, repo_url =
    let url = OpamUrl.of_string repo_url in
    if Option.is_some url.hash then (Opam_utils.fetch url, url)
    else
      let path, rev = Opam_utils.fetch_resolve url in
      (path, { url with hash = Some rev })
  in
  Fmt.epr "Using OPAM repository: %a@." Opam_utils.pp_url repo_url;
  let fixed_packages = Opam_utils.make_fixed_packages ~root_packages ~pins in
  let context = make_context ~repo_path fixed_packages in
  match
    Solver.solve context (List.map OpamPackage.Name.of_string package_names)
  with
  | Ok selections ->
    let packages = Solver.packages_of_result selections in
    List.iter (Fmt.pr ">>> dep: %a@." Opam_utils.pp_package) packages;
    packages
    |> List.filter_map (fun pkg ->
           let opam = Solver_context.get_opam_file context pkg in
           match Lock_pkg.of_opam pkg opam with
           | None ->
             Fmt.epr "Missing url for package: %a@." Opam_utils.pp_package pkg;
             None
           | some -> some)
    |> Lock_file.make ~repo_url
  | Error err ->
    prerr_endline (Solver.diagnostics err);
    exit 2
