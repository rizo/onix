let env =
  Solver_context.std_env ~arch:"x86_64" ~os:"linux" ~os_family:"debian"
    ~os_distribution:"debian" ~os_version:"10" ()

let context =
  Solver_context.make "/home/rizo/Code/opam-repository/packages"
    ~constraints:OpamPackage.Name.Map.empty ~env

include Opam_0install.Solver.Make (Solver_context.Required)

let solve package_names =
  solve context (List.map OpamPackage.Name.of_string package_names)

let print_selections selections =
  packages_of_result selections
  |> List.iter (fun pkg -> Printf.printf "- %s\n" (OpamPackage.to_string pkg))
