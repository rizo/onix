let ( </> ) = Filename.concat

type error =
  [ `Unsupported_archive of string
  | `Unavailable of string ]

type 'a result = ('a, error) Stdlib.result

type universe = {
  env : string -> OpamVariable.variable_contents option;
  repo_packages_dir : string;
  fixed_packages :
    (OpamPackage.Version.t * OpamFile.OPAM.t) OpamPackage.Name.Map.t;
  constraints : OpamFormula.version_constraint OpamTypes.name_map;
  test : OpamPackage.Name.Set.t;
  prefer_oldest : bool;
}

let dev = OpamPackage.Version.of_string "dev"

let std_env ?(ocaml_native = true) ?sys_ocaml_version ?opam_version ~arch ~os
    ~os_distribution ~os_family ~os_version () = function
  | "arch" -> Some (OpamTypes.S arch)
  | "os" -> Some (OpamTypes.S os)
  | "os-distribution" -> Some (OpamTypes.S os_distribution)
  | "os-version" -> Some (OpamTypes.S os_version)
  | "os-family" -> Some (OpamTypes.S os_family)
  | "opam-version" ->
    Some
      (OpamVariable.S
         (Option.value ~default:OpamVersion.(to_string current) opam_version))
  | "sys-ocaml-version" ->
    sys_ocaml_version |> Option.map (fun v -> OpamTypes.S v)
  | "ocaml:native" -> Some (OpamTypes.B ocaml_native)
  | "enable-ocaml-beta-repository" -> None (* Fake variable? *)
  | v ->
    OpamConsole.warning "Unknown variable %S" v;
    None

let load_opam ~fixed_packages ~repo_packages_dir pkg =
  let { OpamPackage.name; version = _ } = pkg in
  match OpamPackage.Name.Map.find_opt name fixed_packages with
  | Some (_, opam) -> opam
  | None ->
    let opam_path =
      repo_packages_dir
      </> OpamPackage.Name.to_string name
      </> OpamPackage.to_string pkg
      </> "opam"
    in
    OpamFile.OPAM.read (OpamFile.make (OpamFilename.raw opam_path))

let env t pkg v =
  if List.mem v OpamPackageVar.predefined_depends_variables then None
  else
    match OpamVariable.Full.to_string v with
    | "version" ->
      Some
        (OpamTypes.S (OpamPackage.Version.to_string (OpamPackage.version pkg)))
    | x -> t.env x

let make ?(prefer_oldest = false) ?(test = OpamPackage.Name.Set.empty)
    ?(fixed_packages = OpamPackage.Name.Map.empty) ~constraints ~env
    repo_packages_dir =
  { env; repo_packages_dir; fixed_packages; constraints; test; prefer_oldest }

let version_compare t v1 v2 =
  if t.prefer_oldest then OpamPackage.Version.compare v1 v2
  else OpamPackage.Version.compare v2 v1

module Required = struct
  type t = universe

  type rejection =
    | UserConstraint of OpamFormula.atom
    | Unavailable

  let pp_rejection f = function
    | UserConstraint x ->
      Fmt.pf f "Rejected by user-specified constraint %s"
        (OpamFormula.string_of_atom x)
    | Unavailable -> Fmt.string f "Availability condition not satisfied"

  let user_restrictions t name =
    OpamPackage.Name.Map.find_opt name t.constraints

  let candidates t name =
    match OpamPackage.Name.Map.find_opt name t.fixed_packages with
    | Some (version, opam) -> [(version, Ok opam)]
    | None -> (
      let versions_dir =
        t.repo_packages_dir </> OpamPackage.Name.to_string name
      in
      match Os_utils.list_dir versions_dir with
      | versions ->
        let user_constraints = user_restrictions t name in
        versions
        |> List.filter_map (fun dir ->
               match OpamPackage.of_string_opt dir with
               | Some pkg when Sys.file_exists (versions_dir </> dir </> "opam")
                 -> Some (OpamPackage.version pkg)
               | _ -> None)
        |> List.sort (version_compare t)
        |> List.map (fun v ->
               match user_constraints with
               | Some test
                 when not
                        (OpamFormula.check_version_formula
                           (OpamFormula.Atom test) v) ->
                 (v, Error (UserConstraint (name, Some test)))
               | _ -> (
                 let pkg = OpamPackage.create name v in
                 let opam =
                   load_opam ~fixed_packages:t.fixed_packages
                     ~repo_packages_dir:t.repo_packages_dir pkg
                 in
                 let available = OpamFile.OPAM.available opam in
                 match
                   OpamFilter.eval ~default:(B false) (env t pkg) available
                 with
                 | B true -> (v, Ok opam)
                 | B false -> (v, Error Unavailable)
                 | _ ->
                   OpamConsole.error "Available expression not a boolean: %s"
                     (OpamFilter.to_string available);
                   (v, Error Unavailable)))
      | exception Unix.Unix_error (Unix.ENOENT, _, _) ->
        OpamConsole.log "opam-0install" "Package %S not found!"
          (OpamPackage.Name.to_string name);
        [])

  let filter_deps t pkg f =
    let dev = OpamPackage.Version.compare (OpamPackage.version pkg) dev = 0 in
    let test = OpamPackage.Name.Set.mem (OpamPackage.name pkg) t.test in
    f
    |> OpamFilter.partial_filter_formula (env t pkg)
    |> OpamFilter.filter_deps ~build:true ~post:true ~test ~doc:false ~dev
         ~default:false
end

let get_opam_file t pkg =
  let name = OpamPackage.name pkg in
  let candidates = Required.candidates t name in
  let version = OpamPackage.version pkg in
  let res =
    List.find_map
      (fun (v, opam_file) ->
        if OpamPackage.Version.equal v version then Some opam_file else None)
      candidates
  in
  match res with
  | None -> Fmt.failwith "No such package %a" Opam_utils.pp_package pkg
  | Some (Ok opam_file) -> opam_file
  | Some (Error rejection) ->
    Fmt.failwith "Package %a rejected: %a" Opam_utils.pp_package pkg
      Required.pp_rejection rejection