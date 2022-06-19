(* Based on https://github.com/ocaml-opam/opam-0install-solver/blob/master/lib/dir_context.ml *)

let ( </> ) = Filename.concat

type t = {
  with_test : Opam_utils.dep_flag;
  with_doc : Opam_utils.dep_flag;
  with_tools : Opam_utils.dep_flag;
  repo_packages_dir : string;
  fixed_packages :
    (OpamPackage.Version.t * OpamFile.OPAM.t) OpamPackage.Name.Map.t;
  constraints : OpamFormula.version_constraint OpamTypes.name_map;
  prefer_oldest : bool;
}

module Private = struct
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

  (* Availability only seems to require os, ocaml-version, opam-version. *)
  let resolve_available available =
    let env = Build_context.Vars.resolve_from_base in
    OpamFilter.eval_to_bool ~default:false env available
end

let make ?(prefer_oldest = false) ?(fixed_packages = OpamPackage.Name.Map.empty)
    ~constraints ~with_test ~with_doc ~with_tools repo_packages_dir =
  let repo_packages_dir = OpamFilename.Dir.to_string repo_packages_dir in
  {
    with_test;
    with_doc;
    with_tools;
    repo_packages_dir;
    fixed_packages;
    constraints;
    prefer_oldest;
  }

let version_compare t v1 v2 =
  if t.prefer_oldest then OpamPackage.Version.compare v1 v2
  else OpamPackage.Version.compare v2 v1

type rejection =
  | UserConstraint of OpamFormula.atom
  | Unavailable

let pp_rejection f = function
  | UserConstraint x ->
    Fmt.pf f "Rejected by user-specified constraint %s"
      (OpamFormula.string_of_atom x)
  | Unavailable -> Fmt.string f "Availability condition not satisfied"

let user_restrictions t name = OpamPackage.Name.Map.find_opt name t.constraints

let candidates t name =
  match OpamPackage.Name.Map.find_opt name t.fixed_packages with
  | Some (version, opam) -> [(version, Ok opam)]
  | None -> (
    let versions_dir =
      t.repo_packages_dir </> OpamPackage.Name.to_string name
    in
    match Utils.Filesystem.list_dir versions_dir with
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
                      (OpamFormula.check_version_formula (OpamFormula.Atom test)
                         v) -> (v, Error (UserConstraint (name, Some test)))
             | _ ->
               let pkg = OpamPackage.create name v in
               let opam =
                 Private.load_opam ~fixed_packages:t.fixed_packages
                   ~repo_packages_dir:t.repo_packages_dir pkg
               in
               let available = OpamFile.OPAM.available opam in
               if Private.resolve_available available then (v, Ok opam)
               else (v, Error Unavailable))
    | exception Unix.Unix_error (Unix.ENOENT, _, _) ->
      OpamConsole.log "opam-0install" "Package %S not found!"
        (OpamPackage.Name.to_string name);
      [])

(*
  Variable lookup frequency for a small sample project:

      1  arch
   4139  build
    137  dev
     80  opam-version
     41  os
      1  os-distribution
   2572  post
    672  version
    224  with-doc
   2339  with-test
     12  with-tools *)
let filter_deps t pkg depends_formula =
  let version = OpamPackage.version pkg in
  let test = Opam_utils.eval_dep_flag ~version t.with_test in
  let doc = Opam_utils.eval_dep_flag ~version t.with_doc in
  let tools = Opam_utils.eval_dep_flag ~version t.with_tools in
  let env var =
    let contents =
      Build_context.Vars.try_resolvers
        [
          Build_context.Vars.resolve_package pkg;
          Build_context.Vars.resolve_from_base;
          Build_context.Vars.resolve_dep_flags ~test ~doc ~tools;
        ]
        var
    in
    (* let nv = OpamPackage.to_string pkg in *)
    (* Opam_utils.debug_var ~scope:("filter_deps/" ^ nv) var contents; *)
    contents
  in
  OpamFilter.filter_formula ~default:false env depends_formula

let get_opam_file t pkg =
  let name = OpamPackage.name pkg in
  let candidates = candidates t name in
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
      pp_rejection rejection
