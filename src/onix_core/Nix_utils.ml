open Utils

let get_nix_build_jobs () =
  try Unix.getenv "NIX_BUILD_CORES" with Not_found -> "1"

let nix_build_jobs_var = "$NIX_BUILD_CORES"

let eval expr =
  let open Bos in
  let output =
    Cmd.(v "nix-instantiate" % "--eval" % "--expr" % expr)
    |> OS.Cmd.run_out
    |> OS.Cmd.to_string
    |> Utils.Result.force_with_msg
  in
  String.sub output 1 (String.length output - 2)

let _eval ?(raw = true) ?(pure = true) expr =
  let open Bos in
  Cmd.(
    v "nix"
    % "eval"
    %% Cmd.on raw (v "--raw")
    %% Cmd.on (not pure) (v "--impure")
    % "--expr"
    % expr)
  |> OS.Cmd.run_out
  |> OS.Cmd.to_string
  |> Utils.Result.force_with_msg

let fetch_git_expr ~rev url =
  Fmt.str
    {|let result = builtins.fetchGit {
  url = %S;
  rev = %S;
  allRefs = true;
}; in result.outPath|}
    url rev

let fetch_git url =
  let rev = url.OpamUrl.hash |> Option.or_fail "Missing rev in opam url" in
  let nix_url = OpamUrl.base_url url in
  Logs.debug (fun log ->
      log "Fetching git repository: url=%S rev=%S" nix_url rev);
  nix_url |> fetch_git_expr ~rev |> eval |> OpamFilename.Dir.of_string

let fetch_git_resolve_expr url =
  Fmt.str
    {|let result = builtins.fetchGit { url = %S; }; in
"${result.rev},${result.outPath}"|}
    url

let fetch_git_resolve url =
  let nix_url = OpamUrl.base_url url in
  Logs.debug (fun log -> log "Fetching git repository: url=%S rev=None" nix_url);
  let result = nix_url |> fetch_git_resolve_expr |> eval in
  match String.split_on_char ',' result with
  | [rev; path] -> (rev, OpamFilename.Dir.of_string path)
  | _ -> Fmt.failwith "Could not fetch: %S, output=%S" nix_url result

let maybe opt =
  match opt with
  | Some x -> Bos.Cmd.v x
  | None -> Bos.Cmd.empty

let prefetch_url_cmd ?(print_path = true) ?(hash_type = `sha256) ?hash url =
  let open Bos in
  let hash_type =
    match hash_type with
    | `sha256 -> "sha256"
    | `sha512 -> "sha512"
  in
  Cmd.(
    v "nix-prefetch-url"
    %% on print_path (v "--print-path")
    % "--type"
    % hash_type
    % url
    %% maybe hash)

let prefetch_url_with_path ?hash_type ?hash url =
  let open Bos in
  let lines =
    prefetch_url_cmd ~print_path:true ?hash_type ?hash url
    |> OS.Cmd.run_out
    |> OS.Cmd.to_lines
    |> Utils.Result.force_with_msg
  in
  match lines with
  | [hash; path] -> (hash, OpamFilename.Dir.of_string path)
  | _ ->
    Fmt.invalid_arg "Invalid output from nix-prefetch-url: %a"
      Fmt.Dump.(list string)
      lines

let prefetch_url ?hash_type ?hash uri =
  let open Bos in
  prefetch_url_cmd ~print_path:false ?hash_type ?hash uri
  |> OS.Cmd.run_out ~err:OS.Cmd.err_null
  |> OS.Cmd.to_string
  |> Utils.Result.force_with_msg

let guess_git_rev rev =
  match rev with
  | Some "master" -> Bos.Cmd.(v "--rev" % "refs/heads/master")
  | Some "main" -> Bos.Cmd.(v "--rev" % "refs/heads/master")
  | Some tag_or_commit -> Bos.Cmd.(v "--rev" % tag_or_commit)
  | None -> Bos.Cmd.empty

let prefetch_git_cmd ?rev url =
  let open Bos in
  let rev_opt = guess_git_rev rev in
  Cmd.(v "nix-prefetch-git" %% rev_opt % url)

let prefetch_git_with_path url =
  let url, rev =
    match url with
    | { OpamUrl.backend = `git; hash = rev; _ } -> (OpamUrl.base_url url, rev)
    | { OpamUrl.backend = `http; hash = rev; _ } -> (OpamUrl.base_url url, rev)
    | { OpamUrl.backend; _ } ->
      Fmt.failwith "Unsupported backend in url: %s"
        (OpamUrl.string_of_backend backend)
  in
  let open Bos in
  let json =
    prefetch_git_cmd ?rev url
    |> OS.Cmd.run_out ~err:OS.Cmd.err_null
    |> OS.Cmd.to_string
    |> Utils.Result.force_with_msg
    |> Yojson.Basic.from_string
  in
  let rev =
    Yojson.Basic.Util.member "rev" json |> Yojson.Basic.Util.to_string
  in
  let path =
    Yojson.Basic.Util.member "path" json
    |> Yojson.Basic.Util.to_string
    |> OpamFilename.Dir.of_string
  in
  (rev, path)

let fetch_resolve_many_expr urls =
  let url_to_nix (url : OpamUrl.t) =
    match url.hash with
    | Some hash ->
      let url' = { url with OpamUrl.hash = None } in
      Fmt.str "{ url = \"%a\"; rev = \"%s\"; }" Opam_utils.pp_url url' hash
    | None -> Fmt.str "{ url = \"%a\"; }" Opam_utils.pp_url url
  in
  let urls = urls |> List.map url_to_nix |> String.concat " " in
  Fmt.str
    {|
let
  urls = [ %s ];
  fetched = map (x: (builtins.fetchGit x) // { inherit (x) url; }) urls;
  resolved = map (x: "${x.url}#${x.rev},${x.outPath}") fetched;
in
  builtins.concatStringsSep ";" resolved
|}
    urls

let fetch_resolve_many urls =
  let result = urls |> fetch_resolve_many_expr |> eval in
  let lines = String.split_on_char ';' result in
  List.map
    (fun line ->
      match String.split_on_char ',' line with
      | [url; path] -> (OpamUrl.of_string url, OpamFilename.Dir.of_string path)
      | _ -> Fmt.failwith "Invalid repo format: %s" line)
    lines

let symlink_join_expr ~name paths =
  Fmt.str
    {|
let pkgs = import <nixpkgs> {};
in pkgs.symlinkJoin {
  name = %S;
  paths = [ %a ];
}
|}
    name
    Fmt.(list ~sep:Fmt.sp Opam_utils.pp_filename_dir)
    paths

let symlink_join ~name paths =
  let open Bos in
  let expr = symlink_join_expr ~name paths in
  let cmd = Cmd.(v "nix-build" % "--no-out-link" % "-E" % expr) in
  let result =
    cmd
    |> OS.Cmd.run_out ~err:OS.Cmd.err_null
    |> OS.Cmd.to_string
    |> Utils.Result.force_with_msg
  in
  OpamFilename.Dir.of_string result

let resolve_repos repos =
  let resolved_with_path = fetch_resolve_many repos in
  let joint_path =
    match resolved_with_path with
    | [(_repo_url, path)] -> path
    | _ -> symlink_join ~name:"onix-opam-repo" (List.map snd resolved_with_path)
  in
  let resolved_urls = List.map fst resolved_with_path in
  Fmt.epr "@[<v>Repositories:@,%a@,%a@]@."
    Fmt.(list ~sep:cut (any "- url: " ++ Opam_utils.pp_url))
    resolved_urls
    Fmt.(any "- dir: " ++ Opam_utils.pp_filename_dir)
    joint_path;
  (joint_path, resolved_urls)

type store_path = {
  hash : string;
  pkg_name : string;
  pkg_version : string;
  prefix : string;
  suffix : string;
}

let pp_store_path formatter store_path =
  let field = Fmt.Dump.field in
  Fmt.pf formatter "%a"
    (Fmt.Dump.record
       [
         field "hash" (fun r -> r.hash) Fmt.Dump.string;
         field "pkg_name" (fun r -> r.pkg_name) Fmt.Dump.string;
         field "pkg_version" (fun r -> r.pkg_version) Fmt.Dump.string;
         field "prefix" (fun r -> r.prefix) Fmt.Dump.string;
         field "suffix" (fun r -> r.suffix) Fmt.Dump.string;
       ])
    store_path

let parse_store_path path =
  match String.split_on_char '/' path with
  | "" :: "nix" :: "store" :: hash_name_v :: base_path_parts -> (
    let hash_name_v_parts = String.split_on_char '-' hash_name_v in
    match (List.hd hash_name_v_parts, List.rev (List.tl hash_name_v_parts)) with
    | hash, pkg_version :: name_rev ->
      let pkg_name = String.concat "-" (List.rev name_rev) in
      let prefix = String.concat "/" [""; "nix"; "store"; hash_name_v] in
      let suffix = String.concat "/" base_path_parts in
      { hash; pkg_name; pkg_version; prefix; suffix }
    | (exception _) | _ ->
      Fmt.invalid_arg "Invalid hash and package name in path: %S" path)
  | _ -> Fmt.invalid_arg "Invalid nix store path: %S" path

let make_ocaml_packages_path version =
  (* See: pkgs.ocaml-ng.ocamlPackages_X_XX.ocaml.version *)
  match OpamPackage.Version.to_string version with
  | "4.08.1" -> "ocaml-ng.ocamlPackages_4_08.ocaml"
  | "4.09.1" -> "ocaml-ng.ocamlPackages_4_09.ocaml"
  | "4.10.2" -> "ocaml-ng.ocamlPackages_4_10.ocaml"
  | "4.11.2" -> "ocaml-ng.ocamlPackages_4_11.ocaml"
  | "4.12.1" -> "ocaml-ng.ocamlPackages_4_12.ocaml"
  | "4.13.1" -> "ocaml-ng.ocamlPackages_4_13.ocaml"
  | "4.14.1" -> "ocaml-ng.ocamlPackages_4_14.ocaml"
  | "5.0.0" -> "ocaml-ng.ocamlPackages_5_0.ocaml"
  | "5.1.1" -> "ocaml-ng.ocamlPackages_5_1.ocaml"
  | "5.2.0" -> "ocaml-ng.ocamlPackages_5_2.ocaml"
  | unsupported ->
    Fmt.failwith "Unsupported nixpkgs ocaml version: %s" unsupported

let check_ocaml_packages_version version =
  try
    let _ = make_ocaml_packages_path version in
    true
  with Failure _ -> false
