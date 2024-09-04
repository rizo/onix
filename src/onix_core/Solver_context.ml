(* Based on https://github.com/ocaml-opam/opam-0install-solver/blob/master/lib/dir_context.ml *)

module Resolvers = struct
  let resolve_available_current_system = Scope.resolve_global_host

  let resolve_filter_deps_current_system ~test ~doc ~dev_setup opam_pkg =
    Scope.resolve_many
      [
        Scope.resolve_opam_pkg opam_pkg;
        Scope.resolve_global_host;
        Scope.resolve_dep ~post:true ~test ~doc ~dev_setup;
      ]
end

type t = {
  repo : Repo.t;
  package_dep_vars : Opam_utils.package_dep_vars;
  fixed_opam_details : Opam_utils.opam_details OpamPackage.Name.Map.t;
  constraints : OpamFormula.version_constraint OpamTypes.name_map;
  prefer_oldest : bool;
}

type rejection =
  | UserConstraint of OpamFormula.atom
  | Unavailable

let pp_rejection f = function
  | UserConstraint x ->
    Fmt.pf f "Rejected by user-specified constraint %s"
      (OpamFormula.string_of_atom x)
  | Unavailable -> Fmt.string f "Availability condition not satisfied"

open struct
  (* Availability only seems to require os, ocaml-version, opam-version. *)
  let check_available ~pkg available =
    let n = OpamPackage.name pkg in
    let v = OpamPackage.version pkg in
    if OpamPackage.Name.equal Opam_utils.ocaml_system_name n then
      Nix_utils.check_ocaml_packages_version v
    else
      let env = Resolvers.resolve_available_current_system in
      OpamFilter.eval_to_bool ~default:false env available

  let check_user_restrictions ~version name constraints =
    match OpamPackage.Name.Map.find_opt name constraints with
    | Some test
      when not
             (OpamFormula.check_version_formula (OpamFormula.Atom test) version)
      -> Some (UserConstraint (name, Some test))
    | _ -> None

  let select_versions { repo; constraints; _ } name v =
    match check_user_restrictions ~version:v name constraints with
    | Some rejection -> (v, Error rejection)
    | None ->
      let pkg = OpamPackage.create name v in
      let opam = Repo.read_opam repo pkg in
      let available = OpamFile.OPAM.available opam in
      if check_available ~pkg available then (v, Ok opam)
      else (v, Error Unavailable)
end

let make ?(prefer_oldest = false)
    ?(fixed_opam_details = OpamPackage.Name.Map.empty) ~constraints
    ~package_dep_vars ~repo () =
  { repo; package_dep_vars; fixed_opam_details; constraints; prefer_oldest }

let version_compare t v1 v2 =
  if t.prefer_oldest then OpamPackage.Version.compare v1 v2
  else OpamPackage.Version.compare v2 v1

let user_restrictions t name = OpamPackage.Name.Map.find_opt name t.constraints

let candidates t name =
  match OpamPackage.Name.Map.find_opt name t.fixed_opam_details with
  (* It's a fixed user-provided package. *)
  | Some { Opam_utils.package; opam; _ } ->
    [(OpamPackage.version package, Ok opam)]
  (* Lookup in the repository. *)
  | None -> (
    match Repo.read_package_versions t.repo name with
    | None ->
      Logs.warn (fun log ->
          log "Could not find package %a in repository"
            Opam_utils.pp_package_name name);
      []
    | Some versions ->
      versions
      |> List.sort (version_compare t)
      |> List.map (select_versions t name))

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
     12  with-dev-setup *)
let filter_deps t pkg depends_formula =
  let name = OpamPackage.name pkg in
  let { Opam_utils.test; doc; dev_setup } =
    Opam_utils.eval_package_dep_vars name t.package_dep_vars
  in
  let env var =
    let contents =
      Resolvers.resolve_filter_deps_current_system pkg ~test ~doc ~dev_setup var
    in
    (* let nv = OpamPackage.to_string pkg in
       Opam_utils.debug_var ~scope:("filter_deps/" ^ nv) var contents; *)
    contents
  in
  OpamFilter.filter_formula ~default:false env depends_formula
