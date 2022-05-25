
let () =
  let defaults = Postgresql.conndefaults () in
  Array.iter (fun opt ->
    Printf.printf "keyword=%s label=%s\n" opt.Postgresql.cio_keyword opt.cio_label) defaults
