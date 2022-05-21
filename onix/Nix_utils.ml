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

let fetch_git ~rev url = url |> fetch_git_expr ~rev |> eval |> Fpath.v

let fetch_git_resolve_expr url =
  Fmt.str
    {|
        let result = builtins.fetchGit {
          url = %S;
        };
        in
        "${result.outPath},${result.rev}"
      |}
    url

let fetch_git_resolve url =
  let result = url |> fetch_git_resolve_expr |> eval ~pure:false in
  match String.split_on_char ',' result with
  | [path; rev] -> (Fpath.v path, rev)
  | _ -> Fmt.failwith "Could not fetch: %S, output=%S" url result
