open Onix_core

let gen ~lock_file_path (lock_file : Lock_file.t) =
  Onix_core.Utils.Out_channel.with_open_text lock_file_path (fun chan ->
      let out = Format.formatter_of_out_channel chan in
      Fmt.pf out "%a" Pp.pp lock_file);

  Logs.info (fun log -> log "Created a lock file at %S." lock_file_path)

module Pp = Pp