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

let fetch_git ~rev url =
  url |> fetch_git_expr ~rev |> eval |> OpamFilename.Dir.of_string

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

let fetch_git_resolve url =
  let result = url |> fetch_git_resolve_expr |> eval ~pure:false in
  match String.split_on_char ',' result with
  | [path; rev] -> (rev, OpamFilename.Dir.of_string path)
  | _ -> Fmt.failwith "Could not fetch: %S, output=%S" url result

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
