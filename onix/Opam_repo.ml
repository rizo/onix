type spec = {
  github_owner : string;
  github_name : string;
  spec_commit : string option;
}

type t = {
  repo_key : string;
  spec : spec;
  (* TODO: OpamFilename.Dir.t? *)
  repo_path : string;
  repo_commit : string;
  repo_digest : [`sha256 of string];
}
