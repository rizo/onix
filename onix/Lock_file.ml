type t = {
  repos : OpamUrl.t list;
  packages : Lock_pkg.t list;
}

let make ~repos packages =
  List.iter
    (fun url ->
      if Option.is_none url.OpamUrl.hash then
        Fmt.failwith "Repo URI without rev when creating a lock file: %a"
          Opam_utils.pp_url url)
    repos;
  { repos; packages }
