open Utils

type src =
  | Git of {
      url : string;
      rev : string;
    }
  | Http of {
      url : OpamUrl.t;
      hash : OpamHash.t;
    }

type t = {
  package : OpamPackage.t;
  src : src option;
  depends : Name_set.t;
  depopts : Name_set.t;
  depends_build : Name_set.t;
  depopts_build : Name_set.t;
  depends_test : Name_set.t;
  depopts_test : Name_set.t;
  depends_doc : Name_set.t;
  depopts_doc : Name_set.t;
  depends_tools : Name_set.t;
  depopts_tools : Name_set.t;
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

let opam_path_for_locked_package t =
  let pkg = t.package in
  let ( </> ) = Filename.concat in
  let name = OpamPackage.name_to_string pkg in
  (* FIXME: might be just "./opam" for pinned? *)
  if is_pinned t || is_root t then "${src}" </> name ^ ".opam"
  else
    let name_with_version = OpamPackage.to_string pkg in
    "${repo}/packages/" </> name </> name_with_version </> "opam"

let pp_name_string f name =
  if Utils.String.starts_with_number name then Fmt.Dump.string f name
  else Fmt.string f name

let pp_name f name =
  let name = OpamPackage.Name.to_string name in
  if Utils.String.starts_with_number name then Fmt.Dump.string f name
  else Fmt.string f name

let pp_version f version =
  let version = OpamPackage.Version.to_string version in
  (* We require that the version does NOT contain any '-' or '~' characters.
     - Note that nix will replace '~' to '-' automatically.
     The version is parsed with Nix_utils.parse_store_path by splitting bytes
     '- ' to obtain the Build_context.package information.
     This is fine because the version in the lock file is mostly informative. *)
  let set_valid_char i =
    match String.get version i with
    | '-' | '~' -> '+'
    | valid -> valid
  in
  let version = String.init (String.length version) set_valid_char in
  Fmt.pf f "%S" version

let pp_hash f hash =
  let kind = OpamHash.kind hash in
  match kind with
  | `SHA256 -> Fmt.pf f "sha256 = %S" (OpamHash.contents hash)
  | `SHA512 -> Fmt.pf f "sha512 = %S" (OpamHash.contents hash)
  | `MD5 -> Fmt.pf f "md5 = %S" (OpamHash.contents hash)

let pp_src ~ignore_file f t =
  if is_root t then
    match ignore_file with
    | Some ".gitignore" ->
      Fmt.pf f "@ src = pkgs.nix-gitignore.gitignoreSource [] ./.;"
    | Some custom ->
      Fmt.pf f "@ src = nix-gitignore.gitignoreSourcePure [ %s ] ./.;" custom
    | None -> Fmt.pf f "@ src = ./.;"
  else
    match t.src with
    | None -> ()
    | Some (Git { url; rev }) ->
      Fmt.pf f
        "@ src = @[<v-4>builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = \
         true;@]@ };"
        url rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash. *)
    | Some (Http { url; hash }) when OpamHash.kind hash = `MD5 ->
      Logs.warn (fun log ->
          log "Ignoring hash for %a. MD5 hashes are not supported by nix."
            Opam_utils.pp_package t.package);
      Fmt.pf f "@ src = @[<v-4>builtins.fetchurl {@ url = %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url
    | Some (Http { url; hash }) ->
      Fmt.pf f "@ src = @[<v-4>pkgs.fetchurl {@ url = %a;@ %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash

let pp_depends_sets name f (req, opt) =
  let pp_req f =
    Name_set.iter (fun dep ->
        if Utils.String.starts_with_number (OpamPackage.Name.to_string dep) then
          Fmt.pf f "@ self.%a" pp_name dep
        else Fmt.pf f "@ %a" pp_name dep)
  in
  let pp_opt f =
    Name_set.iter (fun dep -> Fmt.pf f "@ (self.%a or null)" pp_name dep)
  in
  if Name_set.is_empty req && Name_set.is_empty opt then ()
  else
    Fmt.pf f "@ %s = with self; [@[<hov1>%a%a@ @]];" name pp_req req pp_opt opt

let pp_depexts_sets name f (req, opt) =
  let pp_req f =
    String_set.iter (fun dep ->
        if Utils.String.starts_with_number dep then
          Fmt.pf f "@ pkgs.%a" pp_name_string dep
        else Fmt.pf f "@ %a" pp_name_string dep)
  in
  let pp_opt f =
    String_set.iter (fun dep ->
        Fmt.pf f "@ (pkgs.%a or null)" pp_name_string dep)
  in
  if String_set.is_empty req && String_set.is_empty opt then ()
  else
    Fmt.pf f "@ %s = with pkgs; [@[<hov1>%a%a@ @]];" name pp_req req pp_opt opt

let pp ~ignore_file f t =
  let name = OpamPackage.name_to_string t.package in
  let version = OpamPackage.version t.package in
  Format.fprintf f "name = %S;@ version = %a;%a@ opam = %S;%a%a%a%a%a%a" name
    pp_version version (pp_src ~ignore_file) t
    (opam_path_for_locked_package t)
    (pp_depends_sets "depends")
    (t.depends, t.depopts)
    (pp_depends_sets "buildDepends")
    (t.depends_build, t.depopts_build)
    (pp_depends_sets "testDepends")
    (t.depends_test, t.depopts_test)
    (pp_depends_sets "docDepends")
    (t.depends_doc, t.depopts_doc)
    (pp_depends_sets "toolsDepends")
    (t.depends_tools, t.depopts_tools)
    (pp_depexts_sets "depexts")
    (t.depexts_nix, t.depexts_unknown)

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
  | _, Some hash, _ -> Ok hash
  | _, _, Some hash -> Ok hash
  | Some hash, _, _ -> Ok hash
  | _ -> Error (`Msg "No md5/sha256/sha512 hashes found")

let src_of_opam_url opam_url =
  let url = OpamFile.URL.url opam_url in
  match url.OpamUrl.backend with
  | `git -> (
    match url.OpamUrl.hash with
    | Some rev -> Ok (Git { url = OpamUrl.base_url url; rev })
    | _ -> Error (`Msg ("Missing rev in git url: " ^ OpamUrl.to_string url)))
  | `http -> (
    let hashes = OpamFile.URL.checksum opam_url in
    match select_opam_hash hashes with
    | Ok hash -> Ok (Http { url; hash })
    | Error err -> Error err)
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

let collect_deps ?(opt = Name_set.empty) ~required ~env depends_formula =
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
let get_depexts ~package_name ~is_zip_src ~env depexts =
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
  let nix_depexts =
    if is_zip_src then String_set.add "unzip" nix_depexts else nix_depexts
  in
  (nix_depexts, unknown_depexts)

let resolve ?(build = false) ?(with_test = false) ?(with_doc = false)
    ?(with_tools = false) pkg v =
  let contents =
    Build_context.Vars.try_resolvers
      [
        Build_context.Vars.resolve_package pkg;
        Build_context.Vars.resolve_from_base;
        Build_context.Vars.resolve_dep_flags ~build ~with_test ~with_doc
          ~with_tools;
      ]
      v
  in
  Opam_utils.debug_var
    ~scope:("lock.resolve/" ^ OpamPackage.to_string pkg)
    v contents;
  contents

let get_deps  ~opam_depends ~opam_depopts pkg =
  let env = resolve pkg in
  let _depends, depopts = get_deps ~env ~required:false opam_depopts in
  assert (Name_set.is_empty _depends);
  get_deps ~env ~required:true ~opt:depopts opam_depends

let get_depends_build' ~opam_depends ~opam_depopts pkg =
  let env = resolve ~build:true pkg in
  let _depends, depopts = get_deps ~env ~required:false opam_depopts in
  assert (Name_set.is_empty _depends);
  get_deps ~env ~required:true ~opt:depopts opam_depends

let of_opam ?(with_build = true) ?with_test ?with_doc package opam =
  let src = get_src ~package (OpamFile.OPAM.url opam) in
  let opam_depends = OpamFile.OPAM.depends opam in
  let opam_depopts = OpamFile.OPAM.depopts opam in
  let opam_depexts = OpamFile.OPAM.depexts opam in

  let env = Build_context.basic_resolve Build_context.Vars.default in

  let get_req ?(env = env) = get_deps ~env ~required:true in
  let get_opt ?(env = env) = get_deps ~env ~required:false in

  (* We start a cerimonial dependency extraction here. The intent is to
     precisely split the dependencies in the buckets based on filters. *)

  (* Collect just depopts, and then depends and remaining depopts. *)
  let _depends, depopts = get_opt opam_depopts in
  assert (Name_set.is_empty _depends);
  let depends, depopts = get_req ~opt:depopts opam_depends in

  (* Collect depopts+build, and then depends+build and remaining depopts+build. *)
  let _depends_build', depopts_build' = get_opt ~with_build:true opam_depopts in
  assert (Name_set.is_empty _depends_build');
  let depends_build', depopts_build' =
    get_req ~opt:depopts_build' ~with_build:true opam_depends
  in

  (* Collect depopts+test, and then depends+test and remaining depopts+test. *)
  let _depends_test', depopts_test' = get_opt ~with_test:true opam_depopts in
  assert (Name_set.is_empty _depends_test');
  let depends_test', depopts_test' =
    get_req ~opt:depopts_test' ~with_test:true opam_depends
  in

  (* Collect depopts+doc, and then depends+doc and remaining depopts+doc. *)
  let _depends_doc', depopts_doc' = get_opt ~with_doc:true opam_depopts in
  assert (Name_set.is_empty _depends_doc');
  let depends_doc', depopts_doc' =
    get_req ~opt:depopts_doc' ~with_doc:true opam_depends
  in

  (* As far as we can tell there is no way to filter out the normal deps with
     OpamPackageVar.filter_depends_formula. Might need to go lower-level. *)
  let depends_build = Name_set.diff depends_build' depends in
  let depopts_build = Name_set.diff depopts_build' depopts in
  let depends_test = Name_set.diff depends_test' depends in
  let depopts_test = Name_set.diff depopts_test' depopts in
  let depends_doc = Name_set.diff depends_doc' depends in
  let depopts_doc = Name_set.diff depopts_doc' depopts in

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
  let depexts_nix, depexts_unknown =
    let is_zip_src = Option.map_default false check_is_zip_src src in
    get_depexts ~is_zip_src ~package_name:(OpamPackage.name package) ~env
      opam_depexts
  in

  (* Collect tools. *)
  (* let env = resolve (Build_context.Vars.make_default ~with_tools:true ()) in *)

  (* Collect depopts+test, and then depends+test and remaining depopts+test. *)
  let _depends_tools', depopts_tools' = get_opt ~env opam_depopts in
  assert (Name_set.is_empty _depends_tools');
  let depends_tools', depopts_tools' =
    get_req ~env ~opt:depopts_tools' opam_depends
  in
  let depends_tools = Name_set.diff depends_tools' depends in
  let depopts_tools = Name_set.diff depopts_tools' depopts in

  Some
    {
      package;
      src;
      depends;
      depopts;
      depends_build;
      depopts_build;
      depends_test;
      depopts_test;
      depends_doc;
      depopts_doc;
      depends_tools;
      depopts_tools;
      depexts_nix;
      depexts_unknown;
    }
