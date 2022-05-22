module Option = struct
  include Option

  let map_default ~f ~default = function
    | None -> default
    | Some x -> f x

  let or_fail msg t =
    match t with
    | Some x -> x
    | None -> failwith msg

  let if_some f t =
    match t with
    | Some x -> f x
    | None -> ()
end

module List = struct
  include List

  let is_empty = function
    | [] -> true
    | _ -> false

  let is_not_empty = function
    | [] -> false
    | _ -> true
end

module String = struct
  include String

  let starts_with_number t =
    match String.get t 0 with
    | '0' .. '9' -> true
    | (exception Invalid_argument _) | _ -> false
end

module String_set = Set.Make (String)

(* Since 4.14.0 *)
module Out_channel = struct
  let with_open openfun s f =
    let oc = openfun s in
    Fun.protect ~finally:(fun () -> Stdlib.close_out_noerr oc) (fun () -> f oc)

  let with_open_text s f = with_open Stdlib.open_out s f
end

module Filesystem = struct
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
end

module Result = struct
  include Result

  let force_with_msg t =
    match t with
    | Ok x -> x
    | Error (`Msg err) -> failwith err
end