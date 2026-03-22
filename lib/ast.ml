type location = Lexing.position * Lexing.position
and ident = { loc : location; id : string; pos : Lexing.position }
and binop = Badd | Bmin | Bmul | Bdiv

(* Simple const for expressions (no name) *)
type simple_const =
  | SCint of int
  | SCfloat of float
  | SCbool of bool
  | SCstring of string

and expr =
  | Econst of simple_const
  | Evar of ident
  | Ebinop of binop * expr * expr

and const_value =
  | Cint of int
  | Cstring of string
  | Cbool of bool
  | Cfloat of float
  | Cexpr of expr
  | Cempty

and const_decl = { name : string; value : const_value; pos : Lexing.position }

type program = { constants : const_decl list }
