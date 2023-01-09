open Prelude

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

(* https://opam.ocaml.org/doc/Manual.html#opamfield-patches *)
let get_patches ~env opam =
  let filtered_patches = OpamFile.OPAM.patches opam in
  (* FIXME: Resolve patches formula! *)
  List.map fst filtered_patches

let get_extra_files (opam_details : Opam_utils.opam_details) =
  (* FIXME: Check for undeclared in ./files! *)
  match OpamFile.OPAM.extra_files opam_details.opam with
  | None -> []
  | Some extra_files ->
    let bad_files, good_files =
      Opam_utils.check_extra_files_hashes ~opamfile:opam_details.path
        extra_files
    in
    if List.is_not_empty bad_files then
      Logs.warn (fun log ->
          log "@[<v>%a: bad hash for extra files:@,%a@]" Opam_utils.pp_package
            opam_details.package
            (Fmt.list Opam_utils.pp_filename)
            bad_files);
    let all = List.append bad_files good_files in
    if List.is_not_empty all then
      Logs.debug (fun log ->
          log "@[<v>%a: found extra files:@,%a@]" Opam_utils.pp_package
            opam_details.package
            (Fmt.list Opam_utils.pp_filename)
            all);
    all

let get_subst_and_patches ~env ~pkg_lock_dir
    (opam_details : Opam_utils.opam_details) =
  let nv = opam_details.package in

  let patches = get_patches ~env opam_details.opam in
  let substs = OpamFile.OPAM.substs opam_details.opam in
  let extra_files = get_extra_files opam_details in

  let subst_patches, subst_other =
    List.partition (fun subst_file -> List.mem subst_file patches) substs
  in

  List.iter
    (fun base -> Fmt.epr "*** extra_files: %s@." (OpamFilename.to_string base))
    extra_files;

  List.iter
    (fun base -> Fmt.epr "*** patch: %s@." (OpamFilename.Base.to_string base))
    patches;

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

  (subst_other, patches)
