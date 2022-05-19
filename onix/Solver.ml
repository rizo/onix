let env =
  Solver_context.std_env ~arch:"x86_64" ~os:"linux" ~os_family:"debian"
    ~os_distribution:"debian" ~os_version:"10" ()

let make_context fixed_packages =
  Solver_context.make "/home/rizo/Code/opam-repository/packages" ~fixed_packages
    ~constraints:OpamPackage.Name.Map.empty ~env

module Solver = Opam_0install.Solver.Make (Solver_context.Required)

let solve ~root_packages ~pins package_names =
  let fixed_packages = Opam_utils.make_fixed_packages ~root_packages ~pins in
  let context = make_context fixed_packages in
  match
    Solver.solve context (List.map OpamPackage.Name.of_string package_names)
  with
  | Ok selections ->
    let packages = Solver.packages_of_result selections in
    List.iter (Fmt.pr ">>> dep: %a@." Opam_utils.pp_package) packages;
    List.filter_map
      (fun pkg ->
        let opam = Solver_context.get_opam_file context pkg in
        match Lock_pkg.of_opam pkg opam with
        | None ->
          Fmt.epr "Missing url for package: %a@." Opam_utils.pp_package pkg;
          None
        | some -> some)
      packages
  | Error err -> failwith (Solver.diagnostics err)
