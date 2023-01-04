let ( </> ) = OpamFilename.Op.( / )
let ( <//> ) = OpamFilename.Op.( // )

open Utils

type pkg_drv = {
  lock_pkg : Lock_pkg.t;
  pkg_scope : Pkg_scope.t;
  opam_details : Opam_utils.Opam_details.t;
  inputs : String_set.t;
  check_inputs : String_set.t;
  propagated_build_inputs : String_set.t;
  propagated_native_build_inputs : String_set.t;
  configure_phase : string list list;
  build_phase : string list list;
  install_phase : string list list;
  files_to_copy : OpamFilename.Base.t list;
  patches : OpamFilename.Base.t list;
}

let resolve_actions =
  let jobs = Nix_utils.get_nix_build_jobs () in
  let arch = OpamSysPoll.arch () in
  let os = OpamSysPoll.os () in
  let user = Unix.getlogin () in
  let group = Utils.Os.get_group () in
  let build_dir = Sys.getcwd () in
  fun ?(local = OpamVariable.Map.empty) pkg_scope ->
    Pkg_scope.resolve_many
      [
        Pkg_scope.resolve_stdenv;
        Pkg_scope.resolve_local local;
        Pkg_scope.resolve_config pkg_scope;
        Pkg_scope.resolve_global ~jobs ?arch ?os ~user ?group;
        Pkg_scope.resolve_pkg ~build_dir pkg_scope;
      ]

let pkg_scope_for_lock_pkg (lock_pkg : Lock_pkg.t) =
  let name = OpamPackage.name lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  let dependencies_names =
    Name_set.union lock_pkg.depends lock_pkg.depends_build
  in
  let deps =
    Name_set.fold
      (fun name acc ->
        let build_pkg =
          {
            Pkg_scope.name;
            version = OpamPackage.Version.of_string "version_todo";
            opamfile = "FIXME_OPAMFILE";
            prefix =
              String.concat "" ["${"; OpamPackage.Name.to_string name; "}"];
          }
        in
        Name_map.add name build_pkg acc)
      dependencies_names Name_map.empty
  in
  let self =
    {
      Pkg_scope.name;
      version;
      opamfile = OpamFilename.to_string lock_pkg.opam_details.path;
      prefix = "$out";
    }
  in
  Pkg_scope.make ~deps ~ocaml_version:"4.14.0" self

module Subst_and_patch = struct
  let print_subst ~nv basename =
    let file = OpamFilename.Base.to_string basename in
    let file_in = file ^ ".in" in
    Logs.debug (fun log ->
        log "%s: expanding opam variables in %s, generating %s..."
          (OpamPackage.name_to_string nv)
          file_in file)

  let run_substs ~pkg_lock_dir ~env ~nv substs =
    OpamFilename.in_dir pkg_lock_dir @@ fun () ->
    List.fold_left
      (fun (errs, oks) f ->
        try
          print_subst ~nv f;
          OpamFilter.expand_interpolations_in_file env f;
          (errs, f :: oks)
        with e -> ((f, e) :: errs, oks))
      ([], []) substs

  let get_subst_and_patches ~env ~pkg_lock_dir
      (opam_details : Opam_utils.opam_details) =
    let nv = opam_details.package in

    let patches = OpamFile.OPAM.patches opam_details.opam in
    (* FIXME: Resolve patches formula! *)
    let resolved_patches = List.map fst patches in
    let substs = OpamFile.OPAM.substs opam_details.opam in
    let subst_patches, subst_other =
      List.partition (fun f -> List.mem_assoc f patches) substs
    in

    List.iter
      (fun base -> Fmt.epr "*** patch: %s@." (OpamFilename.Base.to_string base))
      resolved_patches;

    List.iter
      (fun base -> Fmt.epr "*** subst: %s@." (OpamFilename.Base.to_string base))
      substs;

    List.iter
      (fun base ->
        Fmt.epr "*** subst_patch: %s@." (OpamFilename.Base.to_string base))
      subst_patches;

    List.iter
      (fun base ->
        Fmt.epr "*** subst_other: %s@." (OpamFilename.Base.to_string base))
      subst_other;

    (* Expand opam variables in subst_patches. *)
    let subst_errs, _subst_oks = run_substs ~pkg_lock_dir ~env ~nv substs in

    (* Report subst errors. *)
    if subst_errs <> [] then begin
      Logs.err (fun log ->
          log "%s: variable expansion failed for files:@.%s"
            (OpamPackage.to_string opam_details.package)
            (OpamStd.Format.itemize
               (fun (b, err) ->
                 Printf.sprintf "%s.in: %s"
                   (OpamFilename.Base.to_string b)
                   (Printexc.to_string err))
               subst_errs));
      exit 1
    end;

    (subst_other, resolved_patches)
end

module Pkg_drv = struct
  type t = pkg_drv

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

  let of_lock_pkg ~with_test ~with_doc ~with_dev_setup (lock_pkg : Lock_pkg.t) =
    let lock_pkg = add_nixpkgs_prefix_to_depexts lock_pkg in

    let inputs = get_inputs lock_pkg in

    let check_inputs =
      Opam_utils.name_set_to_string_set lock_pkg.depends_test
    in
    let propagated_build_inputs = get_propagated_build_inputs lock_pkg in
    let propagated_native_build_inputs =
      get_propagated_native_build_inputs lock_pkg
    in

    let pkg_scope = pkg_scope_for_lock_pkg lock_pkg in

    let opam_build_commands =
      Opam_actions.build ~with_test ~with_doc ~with_dev_setup pkg_scope
    in
    let opam_install_commands =
      Opam_actions.install ~with_test ~with_doc ~with_dev_setup pkg_scope
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
            log "%a: removing subst in file: %a..." Opam_utils.pp_package
              opam_pkg Opam_utils.pp_filename full_path);
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
      let env = resolve_actions pkg_drv.pkg_scope in
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
end

module Pp = struct
  let install_phase_str_for_install_files ~ocaml_version =
    Fmt.str
      {|

    ${nixpkgs.opaline}/bin/opaline \
      -prefix="$out" \
      -libdir="$out/lib/ocaml/%s/site-lib"|}
      (OpamPackage.Version.to_string ocaml_version)

  let install_phase_str_for_config_files ~package_name =
    Fmt.str
      {|
    if [[ -e "./%s.config" ]]; then
      mkdir -p "$out/etc"
      cp "./%s.config" "$out/etc/%s.config"
    fi|}
      (OpamPackage.Name.to_string package_name)
      (OpamPackage.Name.to_string package_name)
      (OpamPackage.Name.to_string package_name)

  let pp_string_escape_with_enderscore formatter str =
    if Utils.String.starts_with_number str then Fmt.string formatter ("_" ^ str)
    else Fmt.string formatter str

  let pp_name_escape_with_enderscore formatter name =
    let name = OpamPackage.Name.to_string name in
    pp_string_escape_with_enderscore formatter name

  let pp_string_escape_quotted formatter str =
    if Utils.String.starts_with_number str then Fmt.Dump.string formatter str
    else Fmt.string formatter str

  let pp_version f version =
    let version = OpamPackage.Version.to_string version in
    (* We require that the version does NOT contain any '-' or '~' characters.
       - Note that nix will replace '~' to '-' automatically.
       The version is parsed with Nix_utils.parse_store_path by splitting bytes
       '- ' to obtain the Pkg_scope.package information.
       This is fine because the version in the lock file is mostly informative. *)
    let set_valid_char i =
      match String.get version i with
      | '-' | '~' -> '+'
      | valid -> valid
    in
    let version = String.init (String.length version) set_valid_char in
    Fmt.pf f "%S" version

  let pp_hash f (kind, hash) =
    match kind with
    | `SHA256 -> Fmt.pf f "sha256 = %S" hash
    | `SHA512 -> Fmt.pf f "sha512 = %S" hash
    | `MD5 -> Fmt.pf f "md5 = %S" hash

  let pp_src ~gitignore f (t : Lock_pkg.t) =
    if Opam_utils.Opam_details.check_has_absolute_path t.opam_details then
      match t.src with
      | None -> Fmt.pf f "@,src = null;@,dontUnpack = true;"
      | Some (Git { url; rev }) ->
        Fmt.pf f
          "@,\
           src = @[<v-4>builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = \
           true;@]@ };"
          url rev
      (* MD5 hashes are not supported by Nix fetchers. Fetch without hash.
         This normally would not happen as we try to prefetch_src_if_md5. *)
      | Some (Http { url; hash = `MD5, _ }) ->
        Logs.warn (fun log ->
            log "Ignoring hash for %a. MD5 hashes are not supported by nix."
              Opam_utils.pp_package t.opam_details.package);
        Fmt.pf f "@,src = @[<v-4>fetchurl {@ url = %a;@]@ };"
          (Fmt.quote Opam_utils.pp_url)
          url
      | Some (Http { url; hash }) ->
        Fmt.pf f "@,src = @[<v-4>nixpkgs.fetchurl {@ url = %a;@ %a;@]@ };"
          (Fmt.quote Opam_utils.pp_url)
          url pp_hash hash
    else
      let path =
        let opam_path = t.opam_details.Opam_utils.path in
        let path = OpamFilename.(Dir.to_string (dirname opam_path)) in
        if String.equal path "." then "./../../.." else path
      in
      if gitignore then
        Fmt.pf f "@,src = nixpkgs.nix-gitignore.gitignoreSource [] %s;" path
      else Fmt.pf f "@,src = ./../../..;"

  let pp_depends_sets name f req =
    let pp_req f =
      String_set.iter (fun dep ->
          Fmt.pf f "@ %a" pp_string_escape_with_enderscore dep)
    in
    if String_set.is_empty req then ()
    else Fmt.pf f "@ %s = [@[<hov1>%a@ @]];" name pp_req req

  let pp_commands =
    Fmt.list ~sep:Fmt.cut (Fmt.using Utils.command_to_string Fmt.string)

  let pp_phase name f commands =
    if List.is_empty commands then Fmt.pf f "@,%s = \"true\";" name
    else Fmt.pf f "@,@[<v2>%s = ''@,%a@]@,'';" name pp_commands commands

  let pp_install_phase ~package_name ~ocaml_version f commands =
    if List.is_empty commands then ()
    else
      Fmt.pf f "@,@[<v2>installPhase = ''@,%a%s@,%s@]@,'';" pp_commands commands
        (install_phase_str_for_install_files ~ocaml_version)
        (install_phase_str_for_config_files ~package_name)

  let pp_file_inputs f inputs =
    let pp_inputs =
      Fmt.iter ~sep:Fmt.comma String_set.iter pp_string_escape_with_enderscore
    in
    Fmt.pf f "@[<hov2>{ %a@] }" pp_inputs inputs

  let pp_ocamlfind_setup_hook f setup_hook =
    match setup_hook with
    | None -> ()
    | Some setup_hook ->
      Fmt.pf f {|@,setupHook = writeText "setup-hook.sh" ''%s  '';|} setup_hook

  let pp_patches f patches =
    if List.is_empty patches then ()
    else
      let paths =
        List.map (fun base -> "./" ^ OpamFilename.Base.to_string base) patches
      in
      Fmt.pf f {|@,@[<v2>patches = [@,%a@]@,];|} (Fmt.list Fmt.string) paths

  let pp_pkg ~gitignore f (pkg_drv : Pkg_drv.t) =
    let lock_pkg = pkg_drv.lock_pkg in
    let name = OpamPackage.name_to_string lock_pkg.opam_details.package in
    let version = OpamPackage.version lock_pkg.opam_details.package in
    Format.fprintf f
      "%a:@.@.@[<v2>nixpkgs.stdenv.mkDerivation {@ pname = %S;@ version = \
       %a;%a%a@,\
       %a%a%a@,\
       %a%a%a@]@ }@." (* inputs *) pp_file_inputs pkg_drv.inputs
      (* name and version *) name pp_version version
      (* src *)
      (pp_src ~gitignore)
      lock_pkg (* patches *)
      pp_patches pkg_drv.patches
      (* propagatedBuildInputs *)
      (pp_depends_sets "propagatedBuildInputs")
      pkg_drv.propagated_build_inputs
      (* propagatedNativeBuildInputs *)
      (pp_depends_sets "propagatedNativeBuildInputs")
      pkg_drv.propagated_native_build_inputs
      (* checkInputs *)
      (pp_depends_sets "checkInputs")
      pkg_drv.check_inputs
      (* configurePhase *)
      (pp_phase "configurePhase")
      pkg_drv.configure_phase
      (* buildPhase *)
      (pp_phase "buildPhase")
      pkg_drv.build_phase
      (* installPhase *)
      (pp_install_phase
         ~package_name:(OpamPackage.name lock_pkg.opam_details.package)
         ~ocaml_version:(OpamPackage.Version.of_string "4.14.0"))
      pkg_drv.install_phase

  (* Lock file printers *)

  let pp_version f version = Fmt.pf f "version = %S;" version

  let pp_repo_uri f repo_url =
    match repo_url.OpamUrl.hash with
    | Some rev ->
      Fmt.pf f "@[<v2>repo = builtins.fetchGit {@ url = %a;@ rev = %S;@]@,};"
        (Fmt.quote Opam_utils.pp_url)
        { repo_url with OpamUrl.hash = None }
        rev
    | None ->
      Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url

  let pp_index_pkg formatter (lock_pkg : Lock_pkg.t) =
    let name_str = OpamPackage.name_to_string lock_pkg.opam_details.package in
    let version = OpamPackage.version lock_pkg.opam_details.package in
    match name_str with
    | "ocaml-system" ->
      let nixpkgs_ocaml = Nix_utils.make_ocaml_packages_path version in
      Fmt.pf formatter "\"ocaml-system\" = nixpkgs.%s;" nixpkgs_ocaml
    | _ ->
      Fmt.pf formatter "%S = self.callPackage ./packages/%s { };" name_str
        name_str

  let pp_index f lock_pkgs =
    Fmt.pf f
      {|{ nixpkgs ? import <nixpkgs> { }, overlay ? import ./overlay nixpkgs }:

let
  newScope = onixpkgs:
    nixpkgs.lib.callPackageWith ({ inherit nixpkgs; } // onixpkgs);

  packages = nixpkgs.lib.makeScope newScope (self: {@[<v4>    %a@]@,});

in packages.overrideScope' overlay@.|}
      Fmt.(list ~sep:cut pp_index_pkg)
      lock_pkgs
end

let gen_pkg ~lock_dir ~gitignore ~with_test ~with_doc ~with_dev_setup
    (lock_pkg : Lock_pkg.t) =
  let pkg_default_nix =
    let pkg_name = OpamPackage.name_to_string lock_pkg.opam_details.package in
    let pkg_lock_dir = lock_dir </> "packages" </> pkg_name in
    OpamFilename.mkdir pkg_lock_dir;
    OpamFilename.to_string (pkg_lock_dir <//> "default.nix")
  in
  Out_channel.with_open_text pkg_default_nix @@ fun chan ->
  let pkg_drv =
    Pkg_drv.of_lock_pkg ~with_test ~with_doc ~with_dev_setup lock_pkg
  in
  let pkg_drv = Pkg_drv.resolve_files ~lock_dir pkg_drv in
  let out = Format.formatter_of_out_channel chan in
  Fmt.pf out "%a" (Pp.pp_pkg ~gitignore) pkg_drv

let gen_overlay ~lock_dir =
  let overlay_dir = lock_dir </> "overlay" in
  List.iter
    (fun relpath ->
      let file = OpamFilename.(create overlay_dir (Base.of_string relpath)) in
      let dir = OpamFilename.dirname file in
      OpamFilename.mkdir dir;
      match Overlay_files.read relpath with
      | None ->
        Fmt.failwith "internal error: could not read embedded overlay file: %a"
          Opam_utils.pp_filename file
      | Some file_content -> OpamFilename.write file file_content)
    Overlay_files.file_list

let gen_index ~lock_dir lock_pkgs =
  let index_file =
    OpamFilename.Op.(lock_dir // "default.nix") |> OpamFilename.to_string
  in
  Out_channel.with_open_text index_file @@ fun chan ->
  let f = Format.formatter_of_out_channel chan in
  Pp.pp_index f lock_pkgs

let gen ~gitignore ~lock_dir ~with_test ~with_doc ~with_dev_setup
    (lock_file : Lock_file.t) =
  let lock_dir = OpamFilename.Dir.of_string lock_dir in
  OpamFilename.rmdir lock_dir;
  OpamFilename.mkdir lock_dir;
  gen_overlay ~lock_dir;
  gen_index ~lock_dir lock_file.packages;
  List.iter
    (gen_pkg ~lock_dir ~gitignore ~with_test ~with_doc ~with_dev_setup)
    lock_file.packages
