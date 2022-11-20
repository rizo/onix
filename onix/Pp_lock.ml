open Utils

(* Lock pkg printers *)

let pp_name_quoted formatter name =
  let name = OpamPackage.Name.to_string name in
  Fmt.Dump.string formatter name

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
  | `SHA256 -> Fmt.pf f "\"sha256\": %S" hash
  | `SHA512 -> Fmt.pf f "\"sha512\": %S" hash
  | `MD5 -> Fmt.pf f "\"md5\": %S" hash

let pp_src f (t : Lock_pkg.t) =
  if Lock_pkg.is_root t then
    let path =
      let opam_path = t.opam_details.Opam_utils.path in
      let path = OpamFilename.(Dir.to_string (dirname opam_path)) in
      if String.equal path "./." || String.equal path "./" then "." else path
    in
    Fmt.pf f ",@,\"src\": { \"url\": \"file://%s\" }" path
  else
    match t.src with
    | None -> ()
    | Some (Git { url; rev }) ->
      Fmt.pf f ",@,@[<v2>\"src\": {@,\"url\": \"git+%s\",@,\"rev\": %S@]@,}" url
        rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash.
       This normally would not happen as we try to prefetch_src_if_md5. *)
    | Some (Http { url; hash = `MD5, _ }) ->
      Fmt.invalid_arg "Unexpected md5 hash: package=%a url=%a"
        Opam_utils.pp_package t.opam_details.package Opam_utils.pp_url url
    | Some (Http { url; hash }) ->
      Fmt.pf f ",@,@[<v2>\"src\": {@,\"url\": %a,@,%a@]@,}"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash

let pp_depends =
  let pp_deps = Fmt.iter ~sep:Fmt.comma Name_set.iter pp_name_quoted in
  fun key f deps ->
    if Name_set.is_empty deps then ()
    else Fmt.pf f ",@,@[<v2>%S: [@ %a@]@ ]" key pp_deps deps

let pp_depexts =
  let pp_deps = Fmt.iter ~sep:Fmt.comma String_set.iter Fmt.Dump.string in
  fun f deps ->
    if String_set.is_empty deps then ()
    else Fmt.pf f ",@,@[<v2>\"depexts\": [@ %a@]@ ]" pp_deps deps

let pp_pkg ppf (t : Lock_pkg.t) =
  Fmt.pf ppf "\"version\": %S%a%a%a%a%a%a%a"
    (OpamPackage.version_to_string t.opam_details.package)
    pp_src t (pp_depends "depends") t.depends
    (pp_depends "buildDepends")
    t.depends_build (pp_depends "testDepends") t.depends_test
    (pp_depends "docDepends") t.depends_doc
    (pp_depends "devSetupDepends")
    t.depends_dev_setup pp_depexts
    (String_set.union t.depexts_unknown t.depexts_nix)

(* Lock file printers *)

let pp_version f version = Fmt.pf f "\"version\": %S" version

let pp_repo_uri f repo_url =
  match repo_url.OpamUrl.hash with
  | Some rev ->
    Fmt.pf f "@[<v2>\"repository\": {@ \"url\": %a,@ \"rev\": %S@]@,}"
      (Fmt.quote Opam_utils.pp_url)
      { repo_url with OpamUrl.hash = None }
      rev
  | None ->
    Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url

let pp_packages f deps =
  let pp_pkg fmt pkg =
    Fmt.pf fmt "@[<v2>%a: {@ %a@]@,}" pp_name_quoted (Lock_pkg.name pkg) pp_pkg
      pkg
  in
  let pp_list = Fmt.iter ~sep:Fmt.comma List.iter pp_pkg in
  Fmt.pf f "@[<v2>\"packages\" : {@,%a@]@,}" (Fmt.hvbox pp_list) deps

let pp fmt (t : Lock_file.t) =
  Fmt.pf fmt {|{@[<v2>@,%a,@,%a,@,%a@]@,}@.|} pp_version Lib.version pp_repo_uri
    t.repo pp_packages t.packages
