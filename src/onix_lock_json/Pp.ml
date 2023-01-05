open Onix_core
open Onix_core.Utils

(* Lock pkg printers *)

let pp_name_quoted formatter name =
  let name = OpamPackage.Name.to_string name in
  Fmt.Dump.string formatter name

let pp_hash f (kind, hash) =
  match kind with
  | `SHA256 -> Fmt.pf f "\"sha256\": %S" hash
  | `SHA512 -> Fmt.pf f "\"sha512\": %S" hash
  | `MD5 -> Fmt.pf f "\"md5\": %S" hash

let pp_src f (t : Lock_pkg.t) =
  if Opam_utils.Opam_details.check_has_absolute_path t.opam_details then
    (* Absolute path: use src. *)
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
  else
    (* Relative path: use file scheme. *)
    let path =
      let opam_path = t.opam_details.Opam_utils.path in
      let path = OpamFilename.(Dir.to_string (dirname opam_path)) in
      if String.equal path "./." || String.equal path "./" then "." else path
    in
    Fmt.pf f ",@,\"src\": { \"url\": \"file://%s\" }" path

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

let pp_pkg_vars f vars =
  match vars with
  | { Opam_utils.test = false; doc = false; dev_setup = false } -> ()
  | { Opam_utils.test; doc; dev_setup } ->
    let vars_str =
      String.concat ", "
        (List.filter
           (fun str -> String.length str > 0)
           [
             (if test then "\"with-test\": true" else "");
             (if doc then "\"with-doc\": true" else "");
             (if dev_setup then "\"with-dev-setup\": true" else "");
           ])
    in
    Fmt.pf f ",@,@[<v2>\"vars\": { %s }@]" vars_str

let pp_pkg ppf (t : Lock_pkg.t) =
  Fmt.pf ppf "\"version\": %S%a%a%a%a%a%a%a%a"
    (OpamPackage.version_to_string t.opam_details.package)
    pp_src t (pp_depends "depends") t.depends
    (pp_depends "build-depends")
    t.depends_build
    (pp_depends "test-depends")
    t.depends_test (pp_depends "doc-depends") t.depends_doc
    (pp_depends "dev-setup-depends")
    t.depends_dev_setup pp_depexts
    (String_set.union t.depexts_unknown t.depexts_nix)
    pp_pkg_vars t.vars

(* Lock file printers *)

let pp_version f version = Fmt.pf f "\"version\": %S" version

let pp_repos =
  let pp_repo_url ppf repo_url =
    match repo_url.OpamUrl.hash with
    | None ->
      Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url
    | Some rev ->
      Fmt.pf ppf "@[<v2>{@ \"url\": %a,@ \"rev\": %S@]@,}"
        (Fmt.quote Opam_utils.pp_url)
        { repo_url with OpamUrl.hash = None }
        rev
  in
  fun f repos ->
    Fmt.pf f "@[<v2>\"repositories\": [@,%a@]@,]"
      (Fmt.list ~sep:Fmt.comma pp_repo_url)
      repos

let pp_packages f deps =
  let pp_pkg fmt pkg =
    Fmt.pf fmt "@[<v2>%a: {@ %a@]@,}" pp_name_quoted (Lock_pkg.name pkg) pp_pkg
      pkg
  in
  let pp_list = Fmt.iter ~sep:Fmt.comma List.iter pp_pkg in
  Fmt.pf f "@[<v2>\"packages\" : {@,%a@]@,}" (Fmt.hvbox pp_list) deps

let pp fmt (t : Lock_file.t) =
  Fmt.pf fmt "{@[<v2>@,%a,@,%a,@,%a@]@,}@." pp_version Lib.version pp_repos
    t.repository_urls pp_packages t.packages
