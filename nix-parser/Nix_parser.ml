exception ParseError of string

let parse (chan : in_channel) (file_name : string) =
  let lexbuf = Lexer.set_filename file_name (Lexing.from_channel chan) in
  let q, s = (Queue.create (), ref []) in
  try Parser.main (Lexer.next_token q s) lexbuf with
  | Lexer.Error msg ->
    raise (ParseError (Printf.sprintf "lexing error: %s\n" msg))
  | Parser.Error ->
    let msg =
      Printf.sprintf "parse error at: %s\n" (Lexer.print_position lexbuf)
    in
    raise (ParseError msg)

let print = Print.print