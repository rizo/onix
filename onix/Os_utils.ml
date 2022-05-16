let with_dir path fn =
  let ch = Unix.opendir path in
  Fun.protect ~finally:(fun () -> Unix.closedir ch) (fun () -> fn ch)

let list_dir path =
  let rec aux acc ch =
    match Unix.readdir ch with
    | name -> aux (name :: acc) ch
    | exception End_of_file -> acc
  in
  with_dir path (aux [])