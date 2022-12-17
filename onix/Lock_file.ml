type t = {
  repository_urls : OpamUrl.t list;
  packages : Lock_pkg.t list;
}

let make ~repository_urls packages =
  (* TODO: Move validation up. *)
  List.iter
    (fun url ->
      if Option.is_none url.OpamUrl.hash then
        Fmt.failwith "Repo URI without rev when creating a lock file: %a"
          Opam_utils.pp_url url)
    repository_urls;
  { repository_urls; packages }
