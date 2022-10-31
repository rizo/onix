open Utils

(* Lock pkg printers *)

let opam_path_for_locked_package (t : Lock_pkg.t) =
  let pkg = t.opam_details.package in
  let ( </> ) = Filename.concat in
  let name = OpamPackage.name_to_string pkg in
  if Lock_pkg.is_pinned t || Lock_pkg.is_root t then
    match t.opam_details.path with
    | path when OpamFilename.ends_with ".opam" path ->
      Fmt.str "${%s.src}" name </> name ^ ".opam"
    | _ -> Fmt.str "${%s.src}" name </> "opam"
  else
    let name_with_version = OpamPackage.to_string pkg in
    "${repo}/packages/" </> name </> name_with_version </> "opam"

let pp_name_escape_with_enderscore formatter name =
  let name = OpamPackage.Name.to_string name in
  if Utils.String.starts_with_number name then Fmt.string formatter ("_" ^ name)
  else Fmt.string formatter name

let pp_string_escape_quotted formatter str =
  if Utils.String.starts_with_number str then Fmt.Dump.string formatter str
  else Fmt.string formatter str

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
      if String.equal path "." then "./." else path
    in
    match ignore_file with
    | Some ".gitignore" ->
      Fmt.pf f "@ src = pkgs.nix-gitignore.gitignoreSource [] %s;" path
    | Some custom ->
      Fmt.pf f "@ src = nix-gitignore.gitignoreSourcePure [ %s ] %s;" custom
        path
    | None -> Fmt.pf f "@ src = ./.;"
  else
    match t.src with
    | None -> ()
    | Some (Git { url; rev }) ->
      Fmt.pf f
        "@ src = @[<v-4>builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = \
         true;@]@ };"
        url rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash.
       This normally would not happen as we try to prefetch_src_if_md5. *)
    | Some (Http { url; hash = `MD5, _ }) ->
      Logs.warn (fun log ->
          log "Ignoring hash for %a. MD5 hashes are not supported by nix."
            Opam_utils.pp_package t.opam_details.package);
      Fmt.pf f "@ src = @[<v-4>builtins.fetchurl {@ url = %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url
    | Some (Http { url; hash }) ->
      Fmt.pf f "@ src = @[<v-4>pkgs.fetchurl {@ url = %a;@ %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash

let pp_depends_sets name f req =
  let pp_req f =
    Name_set.iter (fun dep ->
        Fmt.pf f "@ %a" pp_name_escape_with_enderscore dep)
  in
  if Name_set.is_empty req then ()
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

let pp_pkg ~ignore_file f (t : Lock_pkg.t) =
  let name = OpamPackage.name_to_string t.opam_details.package in
  let version = OpamPackage.version t.opam_details.package in
  Format.fprintf f "name = %S;@ version = %a;%a@ opam = %S;%a%a%a%a%a%a" name
    pp_version version (pp_src ~ignore_file) t
    (opam_path_for_locked_package t)
    (pp_depends_sets "depends")
    t.depends
    (pp_depends_sets "buildDepends")
    t.depends_build
    (pp_depends_sets "testDepends")
    t.depends_test
    (pp_depends_sets "docDepends")
    t.depends_doc
    (pp_depends_sets "devSetupDepends")
    t.depends_dev_setup
    (pp_depexts_sets "depexts")
    (t.depexts_nix, t.depexts_unknown)

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

let pp_scope ~ignore_file f deps =
  let pp_pkg fmt pkg =
    Fmt.pf fmt "@[<v2>%a = {@ %a@]@,}" pp_name_escape_with_enderscore
      (Lock_pkg.name pkg) (pp_pkg ~ignore_file) pkg
  in
  let pp_list = Fmt.iter ~sep:(Fmt.any ";@,") List.iter pp_pkg in
  Fmt.pf f "@[<v2>scope = rec {@,%a;@]@,};@]" (Fmt.hvbox pp_list) deps

let pp ~ignore_file fmt (t : Lock_file.t) =
  Fmt.pf fmt {|{ pkgs ? import <nixpkgs> {} }:@.@[<v2>rec {@,%a@,%a@,%a@,}@.|}
    pp_version Lib.version pp_repo_uri t.repo (pp_scope ~ignore_file) t.packages
