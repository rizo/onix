module Option = struct
  include Option

  let map_default default f = function
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

  let ( or ) t default =
    match t with
    | Some x -> x
    | None -> default

  let or_else default t =
    match t with
    | Some x -> x
    | None -> default ()
end

let ( or ) = Option.( or )

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

module In_channel = struct
  let with_open openfun s f =
    let ic = openfun s in
    Fun.protect ~finally:(fun () -> Stdlib.close_in_noerr ic) (fun () -> f ic)

  let with_open_bin s f = with_open Stdlib.open_in_bin s f
  let with_open_text s f = with_open Stdlib.open_in s f
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

module Os = struct
  let run_command cmd =
    let open Bos in
    let cmd = Cmd.of_list cmd in
    match OS.Cmd.run_status cmd with
    | Ok (`Exited 0) -> ()
    | Ok (`Exited n) ->
      Fmt.failwith "Command terminated with a non-zero code: %d@." n
    | Ok (`Signaled n) -> Fmt.failwith "Command terminated by signal: %d@." n
    | Error (`Msg err) -> Fmt.failwith "Could not run command: %s" err
end
