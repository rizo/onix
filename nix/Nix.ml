let fetch_expr ~rev url =
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

let eval expr =
  let open Bos in
  Cmd.(v "nix" % "eval" % "--raw" % "--expr" % expr)
  |> OS.Cmd.run_out
  |> OS.Cmd.to_string
  |> Result.get_ok

let fetch_git ~rev url = fetch_expr ~rev url |> eval |> Fpath.v
let build x = x
