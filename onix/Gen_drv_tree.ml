let ( </> ) = OpamFilename.Op.( / )
let ( <//> ) = OpamFilename.Op.( // )

open Utils

type extra_file_status =
  | Undeclared
  | Ok_hash
  | Bad_hash

type drv_pkg = {
  lock_pkg : Lock_pkg.t;
  check_inputs : String_set.t;
  propagated_build_inputs : String_set.t;
  propagated_native_build_inputs : String_set.t;
  build_commands : string list list;
  install_commands : string list list;
  files_to_copy : OpamFilename.Base.t list;
}

let all_depends_inputs (lock_pkg : Lock_pkg.t) =
  let names =
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
  in
  match lock_pkg.src with
  | Some (Git _) -> String_set.add "fetchGit" names
  | Some (Http _) -> String_set.add "fetchurl" names
  | _ -> names

let get_gitignore_input_name ~ignore_file lock_pkg =
  match ignore_file with
  | Some _ when Lock_pkg.is_root lock_pkg -> Some "nix-gitignore"
  | _ -> None

let default_inputs =
  String_set.empty |> String_set.add "stdenv" |> String_set.add "opam-installer"

let install_commands_str_for_install_files ~package_name ~ocaml_version =
  Fmt.str
    {|
    if [[ -e "./%s.install" ]]; then
      ${opam-installer}/bin/opam-installer \
        --prefix="$out" \
        --libdir="$out/lib/ocaml/%s/site-lib" \
        ./%s.install
    fi|}
    (OpamPackage.Name.to_string package_name)
    (OpamPackage.Version.to_string ocaml_version)
    (OpamPackage.Name.to_string package_name)

let install_commands_for_basenames basenames =
  List.map
    (fun basename ->
      [
        "cp";
        String.concat "" ["${./"; OpamFilename.Base.to_string basename; "}"];
        "$out";
      ])
    basenames

(* Lock pkg printers *)

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
     '- ' to obtain the Pkg_ctx.package information.
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

let pp_src ~ignore_file f (t : Lock_pkg.t) =
  if Lock_pkg.is_root t then
    let path =
      let opam_path = t.opam_details.Opam_utils.path in
      let path = OpamFilename.(Dir.to_string (dirname opam_path)) in
      if String.equal path "." then "./../.." else path
    in
    match ignore_file with
    | Some ".gitignore" ->
      Fmt.pf f "@ src = nix-gitignore.gitignoreSource [] %s;" path
    | Some custom ->
      Fmt.pf f "@ src = nix-gitignore.gitignoreSourcePure [ %s ] %s;" custom
        path
    | None -> Fmt.pf f "@ src = ./../..;"
  else
    match t.src with
    | None -> ()
    | Some (Git { url; rev }) ->
      Fmt.pf f
        "@ src = @[<v-4>fetchGit {@ url = %S;@ rev = %S;@ allRefs = true;@]@ };"
        url rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash.
       This normally would not happen as we try to prefetch_src_if_md5. *)
    | Some (Http { url; hash = `MD5, _ }) ->
      Logs.warn (fun log ->
          log "Ignoring hash for %a. MD5 hashes are not supported by nix."
            Opam_utils.pp_package t.opam_details.package);
      Fmt.pf f "@ src = @[<v-4>fetchurl {@ url = %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url
    | Some (Http { url; hash }) ->
      Fmt.pf f "@ src = @[<v-4>fetchurl {@ url = %a;@ %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash

let pp_depends_sets name f req =
  let pp_req f =
    String_set.iter (fun dep ->
        Fmt.pf f "@ %a" pp_string_escape_with_enderscore dep)
  in
  if String_set.is_empty req then ()
  else Fmt.pf f "@ %s = [@[<hov1>%a@ @]];" name pp_req req

let pp_depexts_sets name f (req, opt) =
  let pp_req f =
    String_set.iter (fun dep ->
        Fmt.pf f "@ pkgs.%a" pp_string_escape_quotted dep)
  in
  let pp_opt f =
    String_set.iter (fun dep ->
        Fmt.pf f "@ (pkgs.%a or null)" pp_string_escape_quotted dep)
  in
  if String_set.is_empty req && String_set.is_empty opt then ()
  else Fmt.pf f "@ %s = [@[<hov1>%a%a@ @]];" name pp_req req pp_opt opt

let pp_nix_list pp_elt = Fmt.brackets (Fmt.list ~sep:Fmt.sp (Fmt.box pp_elt))

let command_to_line cmd =
  cmd
  |> List.map (fun x -> String.concat "" ["\""; x; "\""])
  |> String.concat " "

let pp_commands = Fmt.list ~sep:Fmt.cut (Fmt.using command_to_line Fmt.string)

let pp_phase name f commands =
  if List.is_empty commands then ()
  else Fmt.pf f "@,@[<v2>%s = ''@,%a@]@,'';" name pp_commands commands

let pp_install_phase ~package_name ~ocaml_version f commands =
  if List.is_empty commands then ()
  else
    Fmt.pf f "@,@[<v2>installPhase = ''@,%a%s@]@,'';" pp_commands commands
      (install_commands_str_for_install_files ~package_name ~ocaml_version)

let pp_extra_files f files =
  if List.is_empty files then ()
  else
    let p =
      pp_nix_list
        (Fmt.using
           (fun (file, _) -> OpamFilename.to_string file)
           Fmt.Dump.string)
    in
    Fmt.pf f "@ extraFiles = %a;" p files

let pp_file_inputs f inputs =
  let pp_inputs =
    Fmt.iter ~sep:Fmt.comma String_set.iter pp_string_escape_with_enderscore
  in
  Fmt.pf f "@[<hov2>{ %a@] }" pp_inputs inputs

let pp_pkg ~ignore_file f (drv_pkg : drv_pkg) =
  let lock_pkg = drv_pkg.lock_pkg in
  let inputs = all_depends_inputs lock_pkg |> String_set.union default_inputs in
  let inputs =
    match get_gitignore_input_name ~ignore_file lock_pkg with
    | Some gitignore_dep -> String_set.add gitignore_dep inputs
    | None -> inputs
  in
  let name = OpamPackage.name_to_string lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  Format.fprintf f
    "%a:@.@.@[<v2>stdenv.mkDerivation {@ pname = %S;@ version = %a;%a@ \
     %a%a%a%a%a@]@ }@."
    pp_file_inputs inputs name pp_version version (pp_src ~ignore_file) lock_pkg
    (pp_depends_sets "propagatedBuildInputs")
    drv_pkg.propagated_build_inputs
    (pp_depends_sets "propagatedNativeBuildInputs")
    drv_pkg.propagated_native_build_inputs
    (pp_depends_sets "checkInputs")
    drv_pkg.check_inputs (pp_phase "buildPhase") drv_pkg.build_commands
    (pp_install_phase
       ~package_name:(OpamPackage.name lock_pkg.opam_details.package)
       ~ocaml_version:(OpamPackage.Version.of_string "4.14.0"))
    drv_pkg.install_commands

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

module Opam_helpers = struct
  let get_extra_files (opam_details : Opam_utils.opam_details) =
    (* We only want this for repo packages. *)
    if
      Opam_utils.is_pinned opam_details.package
      || Opam_utils.is_root opam_details.package
    then []
    else
      let opamfile = opam_details.path in
      match OpamFile.OPAM.extra_files opam_details.opam with
      | Some extra_files ->
        List.map
          (fun (basename, hash) ->
            let file = Opam_utils.make_opam_files_path ~opamfile basename in
            if OpamHash.check_file (OpamFilename.to_string file) hash then
              (file, Ok_hash)
            else (
              Logs.warn (fun log ->
                  log "Bad hash for extra file: %a" Opam_utils.pp_filename file);
              (file, Bad_hash)))
          extra_files
      | None ->
        let ( </> ) = OpamFilename.Op.( / ) in
        let files_dir = OpamFilename.(dirname opamfile </> "files") in
        List.map
          (fun file ->
            Logs.warn (fun log ->
                log "Found undeclared extra file: %a" Opam_utils.pp_filename
                  file);
            (file, Undeclared))
          (OpamFilename.files files_dir)

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

    let run ~env ~pkg_lock_dir (opam_details : Opam_utils.opam_details) =
      let nv = opam_details.package in
      let patches = OpamFile.OPAM.patches opam_details.opam in
      let substs = OpamFile.OPAM.substs opam_details.opam in
      let subst_patches, subst_other =
        List.partition (fun f -> List.mem_assoc f patches) substs
      in
      Logs.debug (fun log ->
          log "%s: found %d substs: patches=%d other=%d."
            (OpamPackage.to_string opam_details.package)
            (List.length substs)
            (List.length subst_patches)
            (List.length subst_other));

      (* Expand opam variables in subst_patches. *)
      let subst_errs, subst_oks = run_substs ~pkg_lock_dir ~env ~nv substs in

      (* Report subst errors. *)
      if subst_errs <> [] then
        Logs.err (fun log ->
            log "%s: variable expansion failed for files:@.%s"
              (OpamPackage.to_string opam_details.package)
              (OpamStd.Format.itemize
                 (fun (b, err) ->
                   Printf.sprintf "%s.in: %s"
                     (OpamFilename.Base.to_string b)
                     (Printexc.to_string err))
                 subst_errs));
      subst_oks
  end
end

let mk_pkg_lock_dir ~lock_dir (lock_pkg : Lock_pkg.t) =
  let pkg_name = OpamPackage.name_to_string lock_pkg.opam_details.package in
  let pkg_lock_dir = lock_dir </> pkg_name in
  OpamFilename.mkdir pkg_lock_dir;
  pkg_lock_dir

let get_pkgs_in_dir ~lock_dir =
  let dirs = OpamFilename.dirs lock_dir in
  List.fold_left
    (fun acc dir ->
      let pkg_name = OpamFilename.(Base.to_string (basename_dir dir)) in
      String_set.add pkg_name acc)
    String_set.empty dirs

let pkg_ctx_for_lock_pkg (lock_pkg : Lock_pkg.t) =
  let name = OpamPackage.name lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  let dependencies_names =
    Name_set.union lock_pkg.depends lock_pkg.depends_build
  in
  let dependencies =
    Name_set.fold
      (fun name acc ->
        let build_pkg =
          {
            Pkg_ctx.name;
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
      Pkg_ctx.name;
      version;
      opamfile = OpamFilename.to_string lock_pkg.opam_details.path;
      prefix = "$out";
    }
  in
  Pkg_ctx.make ~dependencies ~ocaml_version:"4.14.0" self

let name_set_to_string_set name_set =
  Name_set.fold
    (fun name acc -> String_set.add (OpamPackage.Name.to_string name) acc)
    name_set String_set.empty

let drv_pkg_of_lock_pkg ~ctx ~with_test ~with_doc ~with_dev_setup
    (lock_pkg : Lock_pkg.t) =
  let check_inputs = name_set_to_string_set lock_pkg.depends_test in
  let propagated_build_inputs =
    List.fold_left
      (fun acc names ->
        Name_set.fold
          (fun name acc -> String_set.add (OpamPackage.Name.to_string name) acc)
          names acc)
      lock_pkg.depexts_nix
      [lock_pkg.depends; lock_pkg.depends_build]
  in

  let propagated_native_build_inputs =
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
  in
  let build_commands =
    Opam_actions.build ~with_test ~with_doc ~with_dev_setup ctx
  in
  let install_commands =
    Opam_actions.install ~with_test ~with_doc ~with_dev_setup ctx
  in
  {
    lock_pkg;
    check_inputs;
    propagated_build_inputs;
    propagated_native_build_inputs;
    build_commands;
    install_commands;
    files_to_copy = [];
  }

let copy_extra_files ~pkg_lock_dir extra_files =
  List.iter
    (fun (f, _) ->
      let base = OpamFilename.basename f in
      OpamFilename.copy ~src:f ~dst:(OpamFilename.create pkg_lock_dir base))
    extra_files

let rm_subst_in_files ~pkg_lock_dir ~nv subst_files =
  List.iter
    (fun base ->
      let base_in = OpamFilename.Base.add_extension base "in" in
      let full_path = OpamFilename.create pkg_lock_dir base_in in
      Logs.debug (fun log ->
          log "%a Rremoving subst in file: %a..." Opam_utils.pp_package nv
            Opam_utils.pp_filename full_path);

      OpamFilename.remove full_path)
    subst_files

let get_files_to_copy_after_substs ~subst_files ~extra_files =
  (* TODO: Does not check if the extra file is substs. *)
  List.fold_left
    (fun acc (extra_file, _) ->
      if OpamFilename.check_suffix extra_file ".in" then acc
      else OpamFilename.basename extra_file :: acc)
    subst_files extra_files

let write_drv ~ignore_file oc drv_pkg =
  let out = Format.formatter_of_out_channel oc in
  Fmt.pf out "%a" (pp_pkg ~ignore_file) drv_pkg

let gen_pkg ~lock_dir ~ignore_file ~with_test ~with_doc ~with_dev_setup
    (lock_pkg : Lock_pkg.t) =
  let pkg_lock_dir = mk_pkg_lock_dir ~lock_dir lock_pkg in
  let pkg_file = OpamFilename.to_string (pkg_lock_dir <//> "default.nix") in
  Out_channel.with_open_text pkg_file @@ fun chan ->
  let ctx = pkg_ctx_for_lock_pkg lock_pkg in
  let env = Pkg_ctx.resolve ctx in
  let drv_pkg =
    drv_pkg_of_lock_pkg ~with_test ~with_doc ~with_dev_setup ~ctx lock_pkg
  in
  let extra_files = Opam_helpers.get_extra_files lock_pkg.opam_details in
  copy_extra_files ~pkg_lock_dir extra_files;
  let subst_files =
    Opam_helpers.Subst_and_patch.run ~env ~pkg_lock_dir lock_pkg.opam_details
  in
  rm_subst_in_files ~nv:lock_pkg.opam_details.package ~pkg_lock_dir subst_files;
  let files_to_copy =
    get_files_to_copy_after_substs ~subst_files ~extra_files
  in
  let drv_pkg =
    {
      drv_pkg with
      install_commands =
        List.append
          (install_commands_for_basenames files_to_copy)
          drv_pkg.install_commands;
    }
  in
  write_drv ~ignore_file chan drv_pkg

let gen ~ignore_file ~lock_dir ~with_test ~with_doc ~with_dev_setup
    (lock_file : Lock_file.t) =
  let lock_dir = OpamFilename.Dir.of_string lock_dir in
  OpamFilename.rmdir lock_dir;
  List.iter
    (gen_pkg ~lock_dir ~ignore_file ~with_test ~with_doc ~with_dev_setup)
    lock_file.packages
