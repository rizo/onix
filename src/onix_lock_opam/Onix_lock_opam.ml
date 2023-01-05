let gen ~opam_lock_file_path lock_file =
  Onix_core.Utils.Out_channel.with_open_text opam_lock_file_path (fun chan ->
      let out = Format.formatter_of_out_channel chan in
      Fmt.pf out "%a" Pp.pp lock_file);
  Logs.info (fun log ->
      log "Created an opam lock file at %S." opam_lock_file_path)
