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
  depends : OpamPackage.Name.Set.t;
  depopts : OpamPackage.Name.Set.t;
  depexts : [`Nix of String_set.t | `Other of String_set.t];
}

let is_zip_src src =
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
    "${opam-repo}/packages/" </> name </> name_with_version </> "opam"

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

let pp_src f t =
  if is_root t then Fmt.pf f "./."
  else
    match t.src with
    | None -> Fmt.pf f "null"
    | Some (Git { url; rev }) ->
      Fmt.pf f
        "@[<v-4>builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = true;@]@ }"
        url rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash. *)
    | Some (Http { url; hash }) when OpamHash.kind hash = `MD5 ->
      Logs.warn (fun log ->
          log "Ignoring hash for %a. MD5 hashes are not supported by nix."
            Opam_utils.pp_package t.package);
      Fmt.pf f "@[<v-4>builtins.fetchurl {@ url = %a;@]@ }"
        (Fmt.quote Opam_utils.pp_url)
        url
    | Some (Http { url; hash }) ->
      Fmt.pf f "@[<v-4>pkgs.fetchurl {@ url = %a;@ %a;@]@ }"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash

let pp f t =
  let name = OpamPackage.name_to_string t.package in
  let version = OpamPackage.version t.package in
  let pp_depends f depopts =
    OpamPackage.Name.Set.iter
      (fun dep ->
        if Utils.String.starts_with_number (OpamPackage.Name.to_string dep) then
          Fmt.pf f "@ self.%a" pp_name dep
        else Fmt.pf f "@ %a" pp_name dep)
      depopts
  in
  let pp_depopts f depopts =
    OpamPackage.Name.Set.iter
      (fun dep -> Fmt.pf f "@ (self.%a or null)" pp_name dep)
      depopts
  in
  let pp_depexts f depexts =
    match depexts with
    | `Nix deps ->
      String_set.iter (fun dep -> Fmt.pf f "@ pkgs.%a" pp_name_string dep) deps
    | `Other deps ->
      String_set.iter
        (fun dep -> Fmt.pf f "@ (pkgs.%a or null)" pp_name_string dep)
        deps
  in
  Format.fprintf f
    "@ name = %S;@ version = %a;@ src = %a;@ opam = %S;@ depends = with self; \
     @[<hov2>[%a%a@ @]];@ depexts = @[<hov2>[%a@ @]];"
    name pp_version version pp_src t
    (opam_path_for_locked_package t)
    pp_depends t.depends pp_depopts t.depopts pp_depexts t.depexts

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

let get_src opam_url =
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

let get_deps ?(depopts = OpamPackage.Name.Set.empty) ~required ~test ~doc
    filtered_formula =
  let rec collect ~depends ~depopts ~required formula =
    let open OpamFormula in
    match formula with
    | Empty -> (depends, depopts)
    | Atom (name, _version_formula) ->
      if required then (OpamPackage.Name.Set.add name depends, depopts)
      else (depends, OpamPackage.Name.Set.add name depopts)
    | Block x -> collect ~depends ~depopts ~required x
    | And (x, y) ->
      let depends, depopts = collect ~depends ~depopts ~required x in
      collect ~depends ~depopts ~required y
    | Or (x, y) ->
      let depends, depopts = collect ~depends ~depopts ~required:false x in
      collect ~depends ~depopts ~required:false y
  in
  let vars = Build_context.Vars.default in
  let env =
    Build_context.Vars.try_resolvers
      [
        Build_context.Vars.resolve_from_env;
        Build_context.Vars.resolve_from_static vars;
      ]
  in
  filtered_formula
  |> OpamPackageVar.filter_depends_formula ~build:true ~post:false ~test ~doc
       ~default:false ~env
  |> collect ~depends:OpamPackage.Name.Set.empty ~depopts ~required

let get_depexts ~package_name depexts =
  let vars = Build_context.Vars.nixos in
  let env =
    Build_context.Vars.try_resolvers
      [
        Build_context.Vars.resolve_from_env;
        Build_context.Vars.resolve_from_static vars;
      ]
  in
  let is_nix = OpamFilter.eval_to_bool ~default:false env in
  let rec loop other_deps depexts =
    match depexts with
    (* Explicit filter for the nix system. *)
    | (deps, sys) :: _ when is_nix sys ->
      let deps =
        deps
        |> OpamSysPkg.Set.to_seq
        |> Seq.map OpamSysPkg.to_string
        |> String_set.of_seq
      in
      `Nix deps
    (* Out of luck, add all packages as optional. *)
    | (deps, _) :: depexts' ->
      let deps =
        deps |> OpamSysPkg.Set.to_seq |> Seq.map OpamSysPkg.to_string
      in
      let other_deps' = String_set.add_seq deps other_deps in
      loop other_deps' depexts'
    | [] -> `Other other_deps
  in
  match loop String_set.empty depexts with
  | `Nix deps -> `Nix deps
  | `Other deps -> (
    (* Lookup our depexts mappings before giving up. *)
    match Depexts.from_opam_name package_name with
    | Some deps -> `Nix (String_set.of_list deps)
    | None -> `Other deps)

let add_depext name depexts =
  match depexts with
  | `Nix deps -> `Nix (String_set.add name deps)
  | `Other deps -> `Other (String_set.add name deps)

let of_opam ?(test = false) ?(doc = false) package opam =
  let src =
    match OpamFile.OPAM.url opam with
    | None -> None
    | Some opam_url -> (
      match get_src opam_url with
      | Error (`Msg err) ->
        Logs.warn (fun log ->
            log "Could not get url for package %a: %s`" Opam_utils.pp_package
              package err);
        None
      | Ok src -> Some src)
  in
  (* First collect all depopts, then collect depends with some depopts. *)
  let _depends, depopts =
    get_deps ~required:false ~test ~doc (OpamFile.OPAM.depopts opam)
  in
  assert (OpamPackage.Name.Set.is_empty _depends);
  let depends, depopts =
    get_deps ~required:true ~depopts ~test ~doc (OpamFile.OPAM.depends opam)
  in
  let depexts =
    get_depexts ~package_name:(OpamPackage.name package)
      (OpamFile.OPAM.depexts opam)
  in
  let depexts =
    if Option.map_default false is_zip_src src then add_depext "unzip" depexts
    else depexts
  in
  Some { package; src; depends; depexts; depopts }
