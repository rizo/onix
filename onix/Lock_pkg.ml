open Utils

type src =
  | Git of {
      url : string;
      rev : string;
    }
  | Http of {
      url : OpamUrl.t;
      hash : OpamHash.kind * string;
    }

type t = {
  package : OpamPackage.t;
  src : src option;
  opam_details : Opam_utils.opam_details;
  depends : Name_set.t;
  depends_build : Name_set.t;
  depends_test : Name_set.t;
  depends_doc : Name_set.t;
  depends_dev_setup : Name_set.t;
  depexts_nix : String_set.t;
  depexts_unknown : String_set.t;
}

let check_is_zip_src src =
  match src with
  | Git _ -> false
  | Http { url; _ } ->
    let basename = OpamUrl.basename url in
    Filename.extension basename = ".zip"

let name t = OpamPackage.name t.package
let is_pinned t = Opam_utils.is_pinned t.package
let is_root t = Opam_utils.is_root t.package

let prefetch_src_if_md5 ~package src =
  match src with
  | Http { url; hash = `MD5, _ } ->
    Logs.debug (fun log ->
        log "Package %a uses an md5 hash, prefetching to compute a sha256 hash."
          Opam_utils.pp_package package);
    let hash =
      Nix_utils.prefetch_url ~hash_type:`sha256 (OpamUrl.to_string url)
    in
    Http { url; hash = (`SHA256, hash) }
  | _ -> src

let select_opam_hash hashes =
  let md5, sha256, sha512 =
    let rec loop ?md5 ?sha256 ?sha512 hashes =
      match hashes with
      | [] -> (md5, sha256, sha512)
      | hash :: hashes' -> (
        match OpamHash.kind hash with
        | `MD5 -> loop ~md5:hash ?sha256 ?sha512 hashes'
        | `SHA256 -> loop ?md5 ~sha256:hash ?sha512 hashes'
        | `SHA512 -> loop ?md5 ?sha256 ~sha512:hash hashes')
    in
    loop hashes
  in
  match (md5, sha256, sha512) with
  | _, Some hash, _ -> Some (`SHA256, OpamHash.contents hash)
  | _, _, Some hash -> Some (`SHA512, OpamHash.contents hash)
  | Some hash, _, _ -> Some (`MD5, OpamHash.contents hash)
  | _ -> None

let src_of_opam_url opam_url =
  let url = OpamFile.URL.url opam_url in
  match url.OpamUrl.backend with
  | `git -> (
    match url.OpamUrl.hash with
    | Some rev -> Ok (Git { url = OpamUrl.base_url url; rev })
    | _ -> Error (`Msg ("Missing rev in git url: " ^ OpamUrl.to_string url)))
  | `http ->
    let hashes = OpamFile.URL.checksum opam_url in
    let hash =
      match select_opam_hash hashes with
      | Some hash -> hash
      | None ->
        Logs.warn (fun log ->
            log "Prefetching url without hash: %a" Opam_utils.pp_url url);
        ( `SHA256,
          Nix_utils.prefetch_url ~hash_type:`sha256 (OpamUrl.to_string url) )
    in
    Ok (Http { url; hash })
  | _ -> Error (`Msg ("Unsupported url: " ^ OpamUrl.to_string url))

let get_src ~package opam_url_opt =
  match opam_url_opt with
  | None -> None
  | Some opam_url -> (
    match src_of_opam_url opam_url with
    | Error (`Msg err) ->
      Logs.warn (fun log ->
          log "Could not get url for package %a: %s`" Opam_utils.pp_package
            package err);
      None
    | Ok src -> Some src)

let filter_deps ?(opt = Name_set.empty) ~required ~env depends_formula =
  let rec collect ~req ~opt ~required (formula : OpamFormula.t) =
    match formula with
    | Empty -> (req, opt)
    | Atom (name, _version_formula) ->
      if required then (Name_set.add name req, opt)
      else (req, Name_set.add name opt)
    | Block x -> collect ~req ~opt ~required x
    | And (x, y) ->
      let req, opt = collect ~req ~opt ~required x in
      collect ~req ~opt ~required y
    | Or (x, y) ->
      let req, opt = collect ~req ~opt ~required:false x in
      collect ~req ~opt ~required:false y
  in
  depends_formula
  |> OpamFilter.filter_formula ~default:false env
  |> collect ~req:Name_set.empty ~opt ~required

let get_opam_depexts ~env depexts =
  let is_nix = OpamFilter.eval_to_bool ~default:false env in
  (* We either have {os-distribution = "nixos"} or we don't and add all of the
     packages as unknown/optional. *)
  let rec loop unknown_deps depexts =
    match depexts with
    (* Good. Explicit filter for the nix system. *)
    | (deps, sys) :: _ when is_nix sys ->
      let deps =
        deps
        |> OpamSysPkg.Set.to_seq
        |> Seq.map OpamSysPkg.to_string
        |> String_set.of_seq
      in
      `Nix deps
    (* Out of luck, add all packages as unknown. *)
    | (deps, _) :: depexts' ->
      let deps =
        deps |> OpamSysPkg.Set.to_seq |> Seq.map OpamSysPkg.to_string
      in
      let unknown_deps' = String_set.add_seq deps unknown_deps in
      loop unknown_deps' depexts'
    | [] -> `Unknown unknown_deps
  in
  loop String_set.empty depexts

(* Try to: get nixos depexts, lookup [Depexts] and optionally add unzip for
   zip src unpacking. *)
let get_depexts ~package ~is_zip_src ~env depexts =
  let package_name = OpamPackage.name package in
  let package_version = OpamPackage.version package in
  let opam_depexts = get_opam_depexts ~env depexts in
  let nix_depexts, unknown_depexts =
    match opam_depexts with
    | `Nix nix_depexts -> (nix_depexts, String_set.empty)
    | `Unknown unknown_depexts -> (
      (* Lookup our depexts mappings before giving up. *)
      match Overrides.depexts_for_opam_name package_name with
      | Some nix_depexts -> (String_set.of_list nix_depexts, String_set.empty)
      | None -> (String_set.empty, unknown_depexts))
  in
  (* Add unzip *)
  let nix_depexts =
    if is_zip_src then String_set.add "unzip" nix_depexts else nix_depexts
  in
  (* Add ocaml from nixpkgs. *)
  let nix_depexts =
    if OpamPackage.Name.equal package_name Opam_utils.ocaml_system_name then
      let nix_ocaml_compiler =
        Nix_utils.make_ocaml_packages_path package_version
      in
      String_set.add nix_ocaml_compiler nix_depexts
    else nix_depexts
  in
  (nix_depexts, unknown_depexts)

let resolve ?(build = false) ?(test = false) ?(doc = false) ?(dev_setup = false)
    pkg v =
  let contents =
    Build_context.Vars.try_resolvers
      [
        Build_context.Vars.resolve_package pkg;
        Build_context.Vars.resolve_from_base;
        Build_context.Vars.resolve_dep_flags ~build ~test ~doc ~dev_setup;
      ]
      v
  in
  (* Opam_utils.debug_var *)
  (*   ~scope:("lock.resolve/" ^ OpamPackage.to_string pkg) *)
  (*   v contents; *)
  contents

(* Given required and optional deps, compute a union of all installed deps. *)
let only_installed ~installed req opt =
  (* All req deps MUST be installed. *)
  Name_set.iter (fun dep -> assert (installed dep)) req;
  let opt_installed = Name_set.filter installed opt in
  Name_set.union req opt_installed

let of_opam ~installed ~with_test ~with_doc ~with_dev_setup opam_details =
  let package = opam_details.Opam_utils.package in
  let opam = opam_details.Opam_utils.opam in

  let version = OpamPackage.version package in
  let src = get_src ~package (OpamFile.OPAM.url opam) in
  let src = Option.map (prefetch_src_if_md5 ~package) src in

  let opam_depends = OpamFile.OPAM.depends opam in
  let opam_depopts = OpamFile.OPAM.depopts opam in

  (* Precise extraction of dependencies using dep flags.
     The flag selection is too general so [~depends] and [~depopts] are used to
     select deps exclusively from a particular group. *)
  let get_deps ?build ?test ?doc ?dev_setup ?(depends = Name_set.empty)
      ?(depopts = Name_set.empty) () =
    let env = resolve ?build ?test ?doc ?dev_setup package in
    let _req, opt = filter_deps ~env ~required:false opam_depopts in
    assert (Name_set.is_empty _req);
    let req, opt = filter_deps ~env ~required:true ~opt opam_depends in
    (Name_set.diff req depends, Name_set.diff opt depopts)
  in

  let test = Opam_utils.eval_dep_flag ~version with_test in
  let doc = Opam_utils.eval_dep_flag ~version with_doc in
  let dev_setup = Opam_utils.eval_dep_flag ~version with_dev_setup in

  let depends, depopts = get_deps () in
  let depends_build, depopts_build =
    get_deps ~build:true ~depends ~depopts ()
  in
  let depends_test, depopts_test =
    if test then get_deps ~test ~depends ~depopts ()
    else (Name_set.empty, Name_set.empty)
  in
  let depends_doc, depopts_doc =
    if doc then get_deps ~doc ~depends ~depopts ()
    else (Name_set.empty, Name_set.empty)
  in
  let depends_dev_setup, depopts_dev_setup =
    if dev_setup then get_deps ~dev_setup ~depends ~depopts ()
    else (Name_set.empty, Name_set.empty)
  in

  let depends_build =
    List.fold_left
      (fun acc name ->
        if Name_set.mem name depends then Name_set.add name acc else acc)
      depends_build Overrides.build_depends_names
  in

  let depopts_build =
    List.fold_left
      (fun acc name ->
        if Name_set.mem name depopts then Name_set.add name acc else acc)
      depopts_build Overrides.build_depends_names
  in

  (* Collect depexts. *)
  let opam_depexts = OpamFile.OPAM.depexts opam in
  let depexts_nix, depexts_unknown =
    let is_zip_src = Option.map_default false check_is_zip_src src in
    get_depexts ~is_zip_src ~package ~env:Build_context.Vars.resolve_from_base
      opam_depexts
  in

  Some
    {
      package;
      src;
      opam_details;
      depends = only_installed ~installed depends depopts;
      depends_build = only_installed ~installed depends_build depopts_build;
      depends_test = only_installed ~installed depends_test depopts_test;
      depends_doc = only_installed ~installed depends_doc depopts_doc;
      depends_dev_setup =
        only_installed ~installed depends_dev_setup depopts_dev_setup;
      depexts_nix;
      depexts_unknown;
    }
