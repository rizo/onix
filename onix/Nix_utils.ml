open Utils

let get_nix_build_jobs () =
  try Unix.getenv "NIX_BUILD_CORES" with Not_found -> "1"

let eval ?(raw = true) ?(pure = true) expr =
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
    {|
        let result = builtins.fetchGit {
          url = %S;
          rev = %S;
          allRefs = true;
        };
        in
        result.outPath
      |}
    url rev

let fetch url =
  let rev = url.OpamUrl.hash |> Option.or_fail "Missing rev in opam url" in
  let nix_url = OpamUrl.base_url url in
  Logs.debug (fun log ->
      log "Fetching git repository: url=%S rev=%S" nix_url rev);
  nix_url |> fetch_git_expr ~rev |> eval |> OpamFilename.Dir.of_string

let fetch_git_resolve_expr url =
  Fmt.str
    {|
        let result = builtins.fetchGit {
          url = %S;
        };
        in
        "${result.rev},${result.outPath}"
      |}
    url

let fetch_resolve url =
  let nix_url = OpamUrl.base_url url in
  Logs.debug (fun log -> log "Fetching git repository: url=%S rev=None" nix_url);
  let result = nix_url |> fetch_git_resolve_expr |> eval ~pure:false in
  match String.split_on_char ',' result with
  | [path; rev] -> (rev, OpamFilename.Dir.of_string path)
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
  |> OS.Cmd.run_out
  |> OS.Cmd.to_string
  |> Utils.Result.force_with_msg

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
