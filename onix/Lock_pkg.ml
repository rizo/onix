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

let resolve ?(build = false) ?(test = false) ?(doc = false) ?(tools = false) pkg
    v =
  let contents =
    Build_context.Vars.try_resolvers
      [
        Build_context.Vars.resolve_package pkg;
        Build_context.Vars.resolve_from_base;
        Build_context.Vars.resolve_dep_flags ~build ~test ~doc ~tools;
      ]
      v
  in
  (* Opam_utils.debug_var *)
  (*   ~scope:("lock.resolve/" ^ OpamPackage.to_string pkg) *)
  (*   v contents; *)
  contents

let print_dep n deps =
  Fmt.epr "%s: @." n;
  Name_set.iter (fun n -> Fmt.epr "-%a@.@." Opam_utils.pp_package_name n) deps

let of_opam ~with_test ~with_doc ~with_tools package opam =
  let is_root = Opam_utils.is_root package in
  let src = get_src ~package (OpamFile.OPAM.url opam) in

  let opam_depends = OpamFile.OPAM.depends opam in
  let opam_depopts = OpamFile.OPAM.depopts opam in

  let get_deps ?build ?test ?doc ?tools ?(depends = Name_set.empty)
      ?(depopts = Name_set.empty) () =
    let env = resolve ?build ?test ?doc ?tools package in
    let _req, opt = filter_deps ~env ~required:false opam_depopts in
    assert (Name_set.is_empty _req);
    let req, opt = filter_deps ~env ~required:true ~opt opam_depends in
    (Name_set.diff req depends, Name_set.diff opt depopts)
  in

  let test = Opam_utils.flag_for_scope ~is_root with_test in
  let doc = Opam_utils.flag_for_scope ~is_root with_doc in
  let tools = Opam_utils.flag_for_scope ~is_root with_tools in

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
  let depends_tools, depopts_tools =
    if tools then get_deps ~tools ~depends ~depopts ()
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
    get_depexts ~is_zip_src ~package_name:(OpamPackage.name package)
      ~env:Build_context.Vars.resolve_from_base opam_depexts
  in

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
