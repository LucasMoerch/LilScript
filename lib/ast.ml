type location = Lexing.position * Lexing.position
and ident = { loc: location; id: string; }
type const_decl = { name : string; value : const_value }
and const_value = 
  | Cint of int
  | Cstring of string
  | Cbool of bool
  | Cfloat of float

type program = { constants : const_decl list }

and binop = 
  | Badd 
  | Bmin 
  | Bmul 
  | Bdiv


and expr = 
  | Econst of const_decl
  | Evar of ident
  | Ebinop of binop * expr * expr

and stmt = 
  | Sassign of ident * expr
 
