module Option = struct
  include Option

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

(* Since 4.14.0 *)
module Out_channel = struct
  let with_open openfun s f =
    let oc = openfun s in
    Fun.protect ~finally:(fun () -> Stdlib.close_out_noerr oc) (fun () -> f oc)

  let with_open_text s f = with_open Stdlib.open_out s f
end
