open Prelude

let resolve_commands =
  let jobs = "%{jobs}%" in
  let user = "%{user}%" in
  let group = "%{group}%" in
  let build_dir = "." in
  fun scope ->
    Scope.resolve_many
      [
        Scope.resolve_config scope;
        Scope.resolve_global ~jobs ~user ~group;
        Scope.resolve_pkg ~build_dir scope;
      ]

let resolve_depends ?(build = false) ?(test = false) ?(doc = false)
    ?(dev_setup = false) pkg =
  Scope.resolve_many
    [
      Scope.resolve_stdenv_host;
      Scope.resolve_opam_pkg pkg;
      Scope.resolve_global_host;
      Scope.resolve_dep ~build ~test ~doc ~dev_setup;
    ]

(* FIXME this shouldn't use hosts' vars! *)
let resolve_subst_and_patch =
  let build_dir = Sys.getcwd () in
  fun ?(local = OpamVariable.Map.empty) scope ->
    Scope.resolve_many
      [
        Scope.resolve_stdenv_host;
        Scope.resolve_local local;
        Scope.resolve_config scope;
        Scope.resolve_global_host;
        Scope.resolve_pkg ~build_dir scope;
      ]

let scope_for_lock_pkg ~ocaml_version (lock_pkg : Lock_pkg.t) =
  let name = OpamPackage.name lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  let dep_names = Name_set.union lock_pkg.depends lock_pkg.depends_build in
  let deps =
    Name_set.fold
      (fun name acc ->
        let prefix =
          String.concat "" ["%{"; OpamPackage.Name.to_string name; "}%"]
        in
        let pkg =
          Scope.make_pkg ~name
            ~version:(OpamPackage.Version.of_string "version_todo")
            ~opamfile:
              (Onix_core.Paths.lib ~pkg_name:name ~ocaml_version prefix
              ^ "/opam")
            ~prefix
        in
        Name_map.add name pkg acc)
      dep_names Name_map.empty
  in
  let self =
    Scope.make_pkg ~name ~version
      ~opamfile:(OpamFilename.to_string lock_pkg.opam_details.path)
      ~prefix:"%{prefix}%"
  in

  Scope.make ~deps ~ocaml_version self

type t = {
  lock_pkg : Lock_pkg.t;
  scope : Scope.t;
  opam_details : Opam_utils.Opam_details.t;
  inputs : String_set.t;
  build : (string list * OpamTypes.filter option) list;
  install : (string list * OpamTypes.filter option) list;
  extra_files : OpamFilename.t list;
  patches : OpamFilename.Base.t list;
  substs : OpamFilename.Base.t list;
}

let add_nixpkgs_prefix_to_depexts (lock_pkg : Lock_pkg.t) =
  let depexts_nix =
    String_set.map (fun name -> "nixpkgs." ^ name) lock_pkg.depexts_nix
  in
  { lock_pkg with depexts_nix }

let get_propagated_build_inputs (lock_pkg : Lock_pkg.t) =
  List.fold_left
    (fun acc names ->
      Name_set.fold
        (fun name acc -> String_set.add (OpamPackage.Name.to_string name) acc)
        names acc)
    lock_pkg.depexts_nix
    [lock_pkg.depends; lock_pkg.depends_build]

let get_propagated_native_build_inputs (lock_pkg : Lock_pkg.t) =
  List.fold_left
    (fun acc names ->
      Name_set.fold
        (fun name acc -> String_set.add (OpamPackage.Name.to_string name) acc)
        names acc)
    lock_pkg.depexts_nix
    [
      lock_pkg.depends;
      lock_pkg.depends_build;
      lock_pkg.depends_test;
      lock_pkg.depends_doc;
      lock_pkg.depends_dev_setup;
    ]

let default_install_commands =
  [["mkdir"; "-p"; "$out/lib/ocaml/4.14.0/site-lib"]]

let default_configure_commands =
  [["export"; (* FIXME *) "OCAMLFIND_DESTDIR=$out/lib/ocaml/4.14.0/site-lib"]]

let default_inputs = String_set.of_list ["nixpkgs"; "onixpkgs"; "onix"]

(* Ex: "cp" "${./ocaml-config.install}" ./ocaml-config.install *)
let mk_copy_files_commands filenames =
  List.map
    (fun filename ->
      let basename = OpamFilename.(Base.to_string (basename filename)) in
      ["cp"; String.concat "" ["${./"; basename; "}"]; basename])
    filenames

(* TODO: check ~with_x args *)
let of_lock_pkg ~ocaml_version ~with_test:_ ~with_doc:_ ~with_dev_setup:_
    (lock_pkg : Lock_pkg.t) =
  let opam = lock_pkg.opam_details.opam in
  let lock_pkg = add_nixpkgs_prefix_to_depexts lock_pkg in

  let scope = scope_for_lock_pkg ~ocaml_version lock_pkg in
  let env = resolve_subst_and_patch scope in

  let extra_files = Subst_and_patch.get_extra_files lock_pkg.opam_details in
  let patches = Subst_and_patch.get_patches ~env lock_pkg.opam_details.opam in
  let substs = OpamFile.OPAM.substs lock_pkg.opam_details.opam in

  let env = resolve_commands scope in
  let build = Nix_filter.process_commands ~env (OpamFile.OPAM.build opam) in

  let install = Nix_filter.process_commands ~env (OpamFile.OPAM.install opam) in

  {
    lock_pkg;
    scope;
    opam_details = lock_pkg.opam_details;
    inputs = default_inputs;
    build;
    install;
    extra_files;
    patches;
    substs;
  }

let copy_extra_files ~pkg_lock_dir extra_files =
  (* pkg_lock_dir is assumed to exist. *)
  List.iter
    (fun src ->
      let base = OpamFilename.basename src in
      let dst = OpamFilename.create pkg_lock_dir base in
      OpamFilename.copy ~src ~dst)
    extra_files
