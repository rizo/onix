open Prelude

let resolve_commands =
  let jobs = "${jobs}" in
  let user = "${user}" in
  let group = "${group}" in
  let build_dir = "." in
  fun pkg_scope ->
    Pkg_scope.resolve_many
      [
        Pkg_scope.resolve_config pkg_scope;
        Pkg_scope.resolve_global ~jobs ?arch:None ?os:None ~user ~group;
        Pkg_scope.resolve_pkg ~build_dir pkg_scope;
      ]

let resolve_depends ?(build = false) ?(test = false) ?(doc = false)
    ?(dev_setup = false) pkg =
  Pkg_scope.resolve_many
    [
      Pkg_scope.resolve_stdenv_host;
      Pkg_scope.resolve_opam_pkg pkg;
      Pkg_scope.resolve_global_host;
      Pkg_scope.resolve_dep ~build ~test ~doc ~dev_setup;
    ]

(* FIXME this shouldn't use hosts' vars! *)
let resolve_subst_and_patch =
  let build_dir = Sys.getcwd () in
  fun ?(local = OpamVariable.Map.empty) pkg_scope ->
    Pkg_scope.resolve_many
      [
        Pkg_scope.resolve_stdenv_host;
        Pkg_scope.resolve_local local;
        Pkg_scope.resolve_config pkg_scope;
        Pkg_scope.resolve_global_host;
        Pkg_scope.resolve_pkg ~build_dir pkg_scope;
      ]

let pkg_scope_for_lock_pkg ~ocaml_version (lock_pkg : Lock_pkg.t) =
  let name = OpamPackage.name lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  let dep_names = Name_set.union lock_pkg.depends lock_pkg.depends_build in
  let deps =
    Name_set.fold
      (fun name acc ->
        let prefix =
          String.concat "" ["${"; OpamPackage.Name.to_string name; "}"]
        in
        let build_pkg =
          {
            Pkg_scope.name;
            version = OpamPackage.Version.of_string "version_todo";
            opamfile =
              Onix_core.Paths.lib ~pkg_name:name ~ocaml_version prefix ^ "/opam";
            prefix;
          }
        in
        Name_map.add name build_pkg acc)
      dep_names Name_map.empty
  in
  let self =
    {
      Pkg_scope.name;
      version;
      opamfile = OpamFilename.to_string lock_pkg.opam_details.path;
      prefix = "$out";
    }
  in
  Pkg_scope.make ~deps ~ocaml_version self

type t = {
  lock_pkg : Lock_pkg.t;
  pkg_scope : Pkg_scope.t;
  opam_details : Opam_utils.Opam_details.t;
  inputs : String_set.t;
  check_inputs : String_set.t;
  propagated_build_inputs : String_set.t;
  propagated_native_build_inputs : String_set.t;
  configure_phase : string list list;
  build_phase : string list list;
  build : (string list * OpamTypes.filter option) list;
  install_phase : string list list;
  files_to_copy : OpamFilename.Base.t list;
  patches : OpamFilename.Base.t list;
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

let default_inputs = String_set.singleton "nixpkgs"

let get_inputs (lock_pkg : Lock_pkg.t) =
  List.fold_left
    (fun acc names ->
      Name_set.fold
        (fun name acc -> String_set.add (OpamPackage.Name.to_string name) acc)
        names acc)
    default_inputs
    [
      lock_pkg.depends;
      lock_pkg.depends_build;
      lock_pkg.depends_test;
      lock_pkg.depends_doc;
      lock_pkg.depends_dev_setup;
    ]

let of_lock_pkg ~ocaml_version ~with_test ~with_doc ~with_dev_setup
    (lock_pkg : Lock_pkg.t) =
  let opam = lock_pkg.opam_details.opam in
  let lock_pkg = add_nixpkgs_prefix_to_depexts lock_pkg in

  let inputs = get_inputs lock_pkg in

  let check_inputs = Opam_utils.name_set_to_string_set lock_pkg.depends_test in
  let propagated_build_inputs = get_propagated_build_inputs lock_pkg in
  let propagated_native_build_inputs =
    get_propagated_native_build_inputs lock_pkg
  in

  let pkg_scope = pkg_scope_for_lock_pkg ~ocaml_version lock_pkg in

  let opam_build_commands =
    Opam_actions.build ~with_test ~with_doc ~with_dev_setup pkg_scope
  in
  let opam_install_commands =
    Opam_actions.install ~with_test ~with_doc ~with_dev_setup pkg_scope
  in

  let build =
    let env = resolve_commands pkg_scope in
    Nix_filter.process_commands ~env (OpamFile.OPAM.build opam)
  in

  {
    lock_pkg;
    pkg_scope;
    opam_details = lock_pkg.opam_details;
    inputs;
    check_inputs;
    propagated_build_inputs;
    propagated_native_build_inputs;
    configure_phase = default_configure_commands;
    build_phase = opam_build_commands;
    install_phase = List.append default_install_commands opam_install_commands;
    build;
    files_to_copy = [];
    patches = [];
  }

let get_extra_files (pkg_drv : t) =
  match OpamFile.OPAM.extra_files pkg_drv.opam_details.opam with
  | None -> []
  | Some extra_files ->
    let bad_files, good_files =
      Opam_utils.check_extra_files_hashes ~opamfile:pkg_drv.opam_details.path
        extra_files
    in
    if List.is_not_empty bad_files then
      Logs.warn (fun log ->
          log "@[<v>%a: bad hash for extra files:@,%a@]" Opam_utils.pp_package
            pkg_drv.opam_details.package
            (Fmt.list Opam_utils.pp_filename)
            bad_files);
    let all = List.append bad_files good_files in
    if List.is_not_empty all then
      Logs.debug (fun log ->
          log "@[<v>%a: found extra files:@,%a@]" Opam_utils.pp_package
            pkg_drv.opam_details.package
            (Fmt.list Opam_utils.pp_filename)
            all);
    all

let copy_extra_files ~pkg_lock_dir extra_files =
  List.iter
    (fun src ->
      let base = OpamFilename.basename src in
      let dst = OpamFilename.create pkg_lock_dir base in
      OpamFilename.copy ~src ~dst)
    extra_files

let rm_subst_in_files ~pkg_lock_dir ~opam_pkg subst_files =
  List.iter
    (fun base ->
      let base_in = OpamFilename.Base.add_extension base "in" in
      let full_path = OpamFilename.create pkg_lock_dir base_in in
      Logs.debug (fun log ->
          log "%a: removing subst in file: %a..." Opam_utils.pp_package opam_pkg
            Opam_utils.pp_filename full_path);
      OpamFilename.remove full_path)
    subst_files

let get_files_to_copy ~subst_files ~patches ~extra_files =
  (* TODO: Does not check if the extra file is substs. *)
  List.fold_left
    (fun acc extra_file ->
      let extra_file_base = OpamFilename.basename extra_file in
      if OpamFilename.check_suffix extra_file ".in" then acc
      else if List.mem extra_file_base patches then acc
      else extra_file_base :: acc)
    subst_files extra_files

(* Ex: "cp" "${./ocaml-config.install}" ./ocaml-config.install *)
let mk_copy_files_commands basenames =
  List.map
    (fun basename ->
      [
        "cp";
        String.concat "" ["${./"; OpamFilename.Base.to_string basename; "}"];
        OpamFilename.Base.to_string basename;
      ])
    basenames

let resolve_files ~lock_dir (pkg_drv : t) =
  let name_str = OpamPackage.name_to_string pkg_drv.opam_details.package in
  (* pkg_lock_dir is assumed to exist. *)
  let pkg_lock_dir = lock_dir </> "packages" </> name_str in
  let extra_files = get_extra_files pkg_drv in
  copy_extra_files ~pkg_lock_dir extra_files;

  let subst_files, patches =
    let env = resolve_subst_and_patch pkg_drv.pkg_scope in
    Subst_and_patch.get_subst_and_patches ~env ~pkg_lock_dir
      pkg_drv.opam_details
  in

  rm_subst_in_files ~opam_pkg:pkg_drv.opam_details.package ~pkg_lock_dir
    subst_files;

  let files_to_copy = get_files_to_copy ~subst_files ~patches ~extra_files in
  let copy_files_commands = mk_copy_files_commands files_to_copy in

  {
    pkg_drv with
    configure_phase = List.append pkg_drv.configure_phase copy_files_commands;
    patches;
  }
