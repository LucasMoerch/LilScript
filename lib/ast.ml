type location = Lexing.position * Lexing.position
and ident = { loc : location; id : string }
type binop = Badd | Bmin | Bmul | Bdiv

(* Simple const for expressions (no name) *)
type simple_const =
  | SCint of int
  | SCfloat of float
  | SCbool of bool
  | SCstring of string

type key_name = 
  | Jump
  | Left
  | Right
type key = string

type keybind = key_name * key

and expr =
  | Econst of simple_const
  | Evar of ident
  | Ebinop of binop * expr * expr
  | Elist of expr list

and const_value =
  | Cint of int
  | Cstring of string
  | Cbool of bool
  | Cfloat of float
  | Cexpr of expr

and stmt=
  | Keybinds of keybind list

and const_decl = { name : string; value : const_value }

type program = { constants : const_decl list }
