open Utils

let get_nix_build_jobs () =
  try Unix.getenv "NIX_BUILD_CORES" with Not_found -> "1"

let eval expr =
  let open Bos in
  let output =
    Cmd.(v "nix-instantiate" % "--eval" % "--expr" % expr)
    |> OS.Cmd.run_out
    |> OS.Cmd.to_string
    |> Utils.Result.force_with_msg
  in
  String.sub output 1 (String.length output - 2)

let eval' ?(raw = true) ?(pure = true) expr =
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

let fetch url =
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

let fetch_resolve url =
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

type store_path = {
  hash : string;
  package_name : OpamPackage.Name.t;
  package_version : OpamPackage.Version.t;
  prefix : OpamFilename.Dir.t;
  suffix : OpamFilename.Base.t;
}

let pp_store_path formatter store_path =
  let field = Fmt.Dump.field in
  Fmt.pf formatter "%a"
    (Fmt.Dump.record
       [
         field "hash" (fun r -> r.hash) Fmt.Dump.string;
         field "package_name"
           (fun r -> r.package_name)
           Opam_utils.pp_package_name;
         field "package_version"
           (fun r -> r.package_version)
           Opam_utils.pp_package_version;
         field "prefix" (fun r -> r.prefix) Opam_utils.pp_filename_dir;
         field "suffix" (fun r -> r.suffix) Opam_utils.pp_filename_base;
       ])
    store_path

let parse_store_path path =
  let path = OpamFilename.Dir.to_string path in
  match String.split_on_char '/' path with
  | "" :: "nix" :: "store" :: hash_name_v :: base_path_parts -> (
    let hash_name_v_parts = String.split_on_char '-' hash_name_v in
    match (List.hd hash_name_v_parts, List.rev (List.tl hash_name_v_parts)) with
    | hash, package_version :: name_rev ->
      let package_name =
        OpamPackage.Name.of_string (String.concat "-" (List.rev name_rev))
      in
      let package_version = OpamPackage.Version.of_string package_version in
      let prefix =
        OpamFilename.Dir.of_string
          (String.concat "/" [""; "nix"; "store"; hash_name_v])
      in
      let suffix =
        OpamFilename.Base.of_string (String.concat "/" base_path_parts)
      in
      { hash; package_name; package_version; prefix; suffix }
    | (exception _) | _ ->
      Fmt.invalid_arg "Invalid hash and package name in path: %S" path)
  | _ -> Fmt.invalid_arg "Invalid nix store path: %S" path

(* See: pkgs.ocaml-ng.ocamlPackages_4_XX.ocaml.version *)
let available_ocaml_versions =
  OpamPackage.Version.Set.of_list
    [
      OpamPackage.Version.of_string "4.08.1";
      OpamPackage.Version.of_string "4.09.1";
      OpamPackage.Version.of_string "4.10.2";
      OpamPackage.Version.of_string "4.11.2";
      OpamPackage.Version.of_string "4.12.1";
      OpamPackage.Version.of_string "4.13.1";
      OpamPackage.Version.of_string "4.14.0";
    ]

let make_ocaml_packages_path version =
  let version = OpamPackage.Version.to_string version in
  (* 4.XX.Y -> 4.XX *)
  let version =
    String.sub version 0 4 |> String.mapi (fun i x -> if i = 1 then '_' else x)
  in
  String.concat "" ["ocaml-ng.ocamlPackages_"; version; ".ocaml"]
