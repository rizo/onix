module Result = struct
  module List = struct
    let map f l =
      let rec aux acc = function
        | [] -> Ok (List.rev acc)
        | hd :: tl -> (
          match f hd with
          | Ok hd' -> aux (hd' :: acc) tl
          | Error err -> Error err)
      in
      aux [] l
  end

  let force_with_msg t =
    match t with
    | Ok x -> x
    | Error (`Msg err) -> failwith err
end

module String = struct
  include String

  let lsplit2 s ~on =
    match index_opt s on with
    | None -> None
    | Some i ->
      Some
        ( StringLabels.sub s ~pos:0 ~len:i,
          StringLabels.sub s ~pos:(i + 1) ~len:(length s - i - 1) )
end

module Option = struct
  let map_default ~f ~default = function
    | None -> default
    | Some x -> f x
end