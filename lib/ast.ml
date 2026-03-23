type location = Lexing.position * Lexing.position
and ident = { loc : location; id : string; pos : Lexing.position }
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
  | Cempty

and stmt=
  | Keybinds of keybind list

and const_decl = { name : string; value : const_value; pos : Lexing.position }


type tile_kind =
  | Tsolid
  | Twin
  | Tlose
  | Tempty

type position = {
  x : int;
  y : int;
}

type arena = {
  width : int;
  height : int;
  tiles : tile_kind array array;
}

type action =
  | Jump
  | MoveLeft
  | MoveRight

type keybind = {
  key : string;
  action : action;
}

type rgb_color = {
  red : int;
  green : int;
  blue : int;
}

type player = {
  color : rgb_color;
  spawn : position;
  keybinds : keybind list;
}

type program = {
  constants : const_decl list;
  arena : arena;
  players : player list;
  stmts : stmt list
}
