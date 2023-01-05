open Onix_core

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