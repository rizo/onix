type token =
  (* Tokens with data *)
  | INT of string
  | FLOAT of string
  (* a path *)
  | PATH of string
  (* search path, enclosed in <> *)
  | SPATH of string
  (* home path, starts with ~ *)
  | HPATH of string
  | URI of string
  | BOOL of string
  | STR_START of string
  | STR_MID of string
  | STR_END
  | ISTR_START of string
  | ISTR_MID of string
  | ISTR_END of int
  | ID of string
  (* |  <string> SCOMMENT *)
  (* |  <string> MCOMMENT *)
  (* Tokens that stand for themselves *)
  | SELECT
  | QMARK
  | CONCAT
  | NOT
  | MERGE
  | ASSIGN
  | LT
  | LTE
  | GT
  | GTE
  | EQ
  | NEQ
  | AND
  | OR
  | IMPL
  | AQUOTE_OPEN
  | AQUOTE_CLOSE
  | LBRACE
  | RBRACE
  | LBRACK
  | RBRACK
  | PLUS
  | MINUS
  | TIMES
  | SLASH
  | LPAREN
  | RPAREN
  | COLON
  | SEMICOLON
  | COMMA
  | ELLIPSIS
  | AS
  (* Keywords *)
  | WITH
  | REC
  | LET
  | IN
  | INHERIT
  | NULL
  | IF
  | THEN
  | ELSE
  | ASSERT
  | ORDEF
  (* A special token to denote {} *)
  | EMPTY_CURLY
  (* end of input *)
  | EOF
