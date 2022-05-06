(* Binary operators *)
type binary_op =
  | Plus
  | Minus
  | Mult
  | Div
  | Gt
  | Lt
  | Lte
  | Gte
  | Eq
  | Neq
  | Or
  | And
  | Impl
  | Merge
  | Concat

(* Unary operators *)
type unary_op =
  | Negate
  | Not

(* The top-level expression type *)
type expr =
  | BinaryOp of binary_op * expr * expr
  | UnaryOp of unary_op * expr
  | Cond of expr * expr * expr
  | With of expr * expr
  | Assert of expr * expr
  | Test of expr * expr list
  | Let of binding list * expr
  | Val of value
  | Id of id
  | Select of expr * expr list * expr option
  | Apply of expr * expr
  | Aquote of expr

(* Possible values *)
and value =
  (* Str is a string start, followed by arbitrary number of antiquotations and
     strings that separate them *)
  | Str of string * (expr * string) list
  (* IStr is an indented string, so it has the extra integer component which
     indicates the indentation *)
  | IStr of int * string * (expr * string) list
  | Int of string
  | Float of string
  | Path of string
  | SPath of string
  | HPath of string
  | Uri of string
  | Bool of string
  | Lambda of pattern * expr
  | List of expr list
  | AttSet of binding list
  | RecAttSet of binding list
  | Null

(* Patterns in lambdas definitions *)
and pattern =
  | Alias of id
  | ParamSet of param_set
  | AliasedSet of id * param_set

and param_set = param list * unit option
and param = id * expr option

(* Bindings in attribute sets and let expressions *)
and binding =
  (* The first expr should be attrpath, which is the same as in Select *)
  | AttrPath of expr list * expr
  | Inherit of expr option * id list

(* Identifiers *)
and id = string

(* precedence levels of binary operators *)
let prec_of_bop = function
  | Concat -> 5
  | Mult | Div -> 6
  | Plus | Minus -> 7
  | Merge -> 9
  | Gt | Lt | Lte | Gte -> 10
  | Eq | Neq -> 11
  | And -> 12
  | Or -> 13
  | Impl -> 14

(* precedence levels of unary operatots *)
let prec_of_uop = function
  | Negate -> 3
  | Not -> 8

(* precedence level of expressions
   (assuming that the constituents have higher levels)
*)
let prec_of_expr = function
  | Val (Lambda _) -> 15
  | Val _ | Id _ | Aquote _ -> 0
  | BinaryOp (op, _, _) -> prec_of_bop op
  | UnaryOp (op, _) -> prec_of_uop op
  | Cond _ | With _ | Assert _ | Let _ -> 15
  | Test _ -> 4
  | Select _ -> 1
  | Apply _ -> 2
