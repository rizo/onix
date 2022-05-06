{
open Tokens

exception Error of string

(* Types of curly braces.
   AQUOTE corresponds to the braces for antiquotation, i.e. '${...}'
   and SET to an attribute set '{...}'.
 *)
type braces =
  | AQUOTE
  | SET

let print_stack s =
  let b = Buffer.create 100 in
  Buffer.add_string b "[ ";
  List.iter (function
      | AQUOTE -> Buffer.add_string b "AQUOTE; "
      | SET -> Buffer.add_string b "SET; "
    ) s;
  Buffer.add_string b "]";
  Buffer.contents b

let token_of_str state buf =
  match state with
        | `Start -> STR_START (Buffer.contents buf)
        | `Mid -> STR_MID (Buffer.contents buf)

let token_of_istr state buf =
  match state with
        | `Start -> ISTR_START (Buffer.contents buf)
        | `Mid -> ISTR_MID (Buffer.contents buf)

(* lookup table for one-character tokens *)
let char_table = Array.make 93 EOF
let _ =
  List.iter (fun (k, v) -> Array.set char_table ((int_of_char k) - 1) v)
    [
      '.', SELECT;
      '?', QMARK;
      '!', NOT;
      '=', ASSIGN;
      '<', LT;
      '>', GT;
      '[', LBRACK;
      ']', RBRACK;
      '+', PLUS;
      '-', MINUS;
      '*', TIMES;
      '/', SLASH;
      '(', LPAREN;
      ')', RPAREN;
      ':', COLON;
      ';', SEMICOLON;
      ',', COMMA;
      '@', AS
    ]

(* lookup table for two- and three-character tokens *)
let str_table = Hashtbl.create 10
let _ =
  List.iter (fun (kwd, tok) -> Hashtbl.add str_table kwd tok)
    [
      "//", MERGE;
      "++", CONCAT;
      "<=", LTE;
      ">=", GTE;
      "==", EQ;
      "!=", NEQ;
      "&&", AND;
      "||", OR;
      "->", IMPL;
      "...", ELLIPSIS
    ]

(* lookup table for keywords *)
let keyword_table = Hashtbl.create 10
let _ =
  List.iter (fun (kwd, tok) -> Hashtbl.add keyword_table kwd tok)
    [ "with", WITH;
      "rec", REC;
      "let", LET;
      "in", IN;
      "inherit", INHERIT;
      "null", NULL;
      "if" , IF;
      "then", THEN;
      "else", ELSE;
      "assert", ASSERT;
      "or", ORDEF ]

(* replace an escape sequence by the corresponding character(s) *)
let unescape = function
  | "\\n" -> "\n"
  | "\\r" -> "\r"
  | "\\t" -> "\t"
  | "\\\\" -> "\\"
  | "\\${" -> "${"
  | "''$" -> "$"
  | "$$" -> "$"
  | "'''" -> "''"
  | "''\\t" -> "\t"
  | "''\\r" -> "\r"
  | x ->
    failwith (Printf.sprintf "unescape unexpected arg %s" x)

let collect_tokens lexer q lexbuf =
  let stack = ref [] in
  let queue = Queue.create () in
  let rec go () =
    match (try Some (Queue.take queue) with Queue.Empty -> None) with
    | Some token ->
      (
        match token, !stack with
        | AQUOTE_CLOSE, [] ->
          Queue.add AQUOTE_CLOSE q
        | EOF, _ ->
          Queue.add EOF q;
        | _, _ ->
          Queue.add token q;
          go ()
      )
    | None ->
      lexer queue stack lexbuf;
      go ()
  in
  Queue.add AQUOTE_OPEN q;
  stack := [AQUOTE];
  lexer queue stack lexbuf;
  go ()

(* utility functions *)
let print_position lexbuf =
  let pos = Lexing.lexeme_start_p lexbuf in
  Printf.sprintf "%s:%d:%d" pos.pos_fname
    pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)


let set_filename fname (lexbuf: Lexing.lexbuf)  =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with pos_fname = fname }; lexbuf

}

let digit = ['0'-'9']
let float = digit* '.' digit+ ('e' '-'? digit+)?
let alpha = ['a'-'z' 'A'-'Z']
let alpha_digit = alpha | digit
let path_chr = alpha_digit | ['.' '_' '-' '+']
let path = path_chr* ('/' path_chr+)+
let spath = alpha_digit path_chr* ('/' path_chr+)*
let uri_chr = ['%' '/' '?' ':' '@' '&' '=' '+' '$' ',' '-' '_' '.' '!' '~' '*' '\'']
let scheme = "http" 's'? | "ftp" | "ssh" | "git" | "mirror" | "svn"
let uri = scheme ':' (alpha_digit | uri_chr)+
(* let uri = alpha (alpha_digit | ['+' '-' '.'])* ':' (alpha_digit | uri_chr)+ *)
let char_tokens = ['.' '?' '!' '=' '<' '>' '[' ']' '+' '-' '*' '/' '(' ')' ':' ';' ',' '@']

rule get_tokens q s = parse
(* skip whitespeces *)
| [' ' '\t' '\r']
    { get_tokens q s lexbuf }
(* increase line count for new lines *)
| '\n'
    { Lexing.new_line lexbuf; get_tokens q s lexbuf }
| char_tokens as c
    { Queue.add (Array.get char_table ((int_of_char c) - 1)) q }
| ("//" | "++" | "<=" | ">=" | "==" | "!=" | "&&" | "||" | "->" | "...") as s
    { Queue.add (Hashtbl.find str_table s) q}
| digit+ as i
    { Queue.add (INT i) q }
| float
    { Queue.add (FLOAT (Lexing.lexeme lexbuf)) q }
| path
    { Queue.add (PATH (Lexing.lexeme lexbuf)) q }
| '<' (spath as p) '>'
    { Queue.add (SPATH  p) q }
| '~' path as p
    { Queue.add (HPATH  p) q }
| uri
    { Queue.add(URI (Lexing.lexeme lexbuf)) q }
| ("true" | "false") as b
    { Queue.add (BOOL b) q }
(* keywords or identifies *)
| ((alpha | '_')+ (alpha_digit | ['_' '\'' '-'])*) as id
    { Queue.add (try Hashtbl.find keyword_table id with Not_found -> ID id) q}
(* comments *)
| '#' ([^ '\n']* as c)
    { (* Queue.add (SCOMMENT c) q *) ignore c; get_tokens q s lexbuf}
| "/*"
    { (* Queue.add (comment (Buffer.create 64) lexbuf) q *)
      comment (Buffer.create 64) lexbuf;
      get_tokens q s lexbuf
    }
(* the following three tokens change the braces stack *)
| "${"
    { Queue.add AQUOTE_OPEN q; s := AQUOTE :: !s }
| '{'
    { Queue.add LBRACE q; s := SET :: !s }
| '}'
    {
      match !s with
      | AQUOTE :: rest ->
        Queue.add AQUOTE_CLOSE q; s := rest
      | SET :: rest ->
        Queue.add RBRACE q; s := rest
      | _ ->
        let pos = print_position lexbuf in
        let err = Printf.sprintf "Unbalanced '}' at %s\n" pos in
        raise (Error err)
    }
(* a special token to avoid parser conflicts on param sets and attr sets *)
| '{' [' ' '\r' '\t' '\n']* as ws '}'
  {
    (* change the line number *)
    String.iter (fun c ->
        if c == '\n' then Lexing.new_line lexbuf else ()
      ) ws;
    Queue.add EMPTY_CURLY q
  }
(* a double-quoted string *)
| '"'
    { string `Start (Buffer.create 64) q lexbuf }
(* an indented string *)
| "''"
    { istring `Start None (Buffer.create 64) q lexbuf }
(* End of input *)
| eof
    { Queue.add EOF q }
(* any other character raises an exception *)
| _
    {
      let pos = print_position lexbuf in
      let tok = Lexing.lexeme lexbuf in
      let err = Printf.sprintf "Unexpected character '%s' at %s\n" tok pos in
      raise (Error err)
    }

(* Nix does not allow nested comments, but it is still handy to lex it
   separately because we can properly increase line count. *)
and comment buf = parse
  | '\n'
    {Lexing.new_line lexbuf; Buffer.add_char buf '\n'; comment buf lexbuf}
  | "*/"
    { (* MCOMMENT (Buffer.contents buf) *) ()}
  | _ as c
    { Buffer.add_char buf c; comment buf lexbuf }

and string state buf q = parse
  | '"'                         (* terminate when we hit '"' *)
    { Queue.add (token_of_str state buf) q; Queue.add STR_END q }
  | '\n'
    { Lexing.new_line lexbuf; Buffer.add_char buf '\n'; string state buf q lexbuf }
  | ("\\n" | "\\r" | "\\t" | "\\\\" | "\\${") as s
      { Buffer.add_string buf (unescape s); string state buf q lexbuf }
  | "\\" (_ as c)               (* add the character verbatim *)
      { Buffer.add_char buf c; string state buf q lexbuf }
  | "${"               (* collect all the tokens till we hit the matching '}' *)
    {
      Queue.add (token_of_str state buf) q;
      collect_tokens get_tokens q lexbuf;
      string `Mid (Buffer.create 64) q lexbuf
    }
  | _ as c                  (* otherwise just add the character to the buffer *)
    { Buffer.add_char buf c; string state buf q lexbuf }

and istring state imin buf q = parse
  | "''"
      {
        let indent = match imin with | None -> 0 | Some i -> i in
        Queue.add (token_of_istr state buf) q;
        Queue.add (ISTR_END indent) q
      }
  | ('\n' (' '* as ws)) as s
    {
      Lexing.new_line lexbuf;
      Buffer.add_string buf s;
      let ws_count = String.length ws in
      match imin with
      | None ->
        istring state (Some ws_count) buf q lexbuf
      | Some i ->
        istring state (Some (min i ws_count)) buf q lexbuf
    }
  | ("''$" | "'''" | "''\\t" | "''\\r") as s
      { Buffer.add_string buf (unescape s); istring state imin buf q lexbuf }
  | "''\\" (_ as c)
      { Buffer.add_char buf c; istring state imin buf q lexbuf }
  | "${"
    {
      Queue.add (token_of_istr state buf) q;
      collect_tokens get_tokens q lexbuf;
      istring `Mid imin (Buffer.create 64) q lexbuf
    }
  | _ as c
    { Buffer.add_char buf c; istring state imin buf q lexbuf }
{

let rec next_token
    (q: token Queue.t)
    (s: braces list ref)
    (lexbuf: Lexing.lexbuf)
  : token =
  match (try Some (Queue.take q) with | Queue.Empty -> None) with
  | Some token ->
    token
  | None ->
    get_tokens q s lexbuf;
    next_token q s lexbuf
}
