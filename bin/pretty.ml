open LilScript.Ast
open LilScript.Parser
open LilScript

(* expr to string, used for printing and debug *)
let rec string_of_expr = function
  | Econst sc -> (
      match sc with
      | SCint i -> string_of_int i
      | SCfloat f -> string_of_float f
      | SCbool b -> string_of_bool b
      | SCstring s -> "\"" ^ s ^ "\"")
  | Evar id -> id.id
  | Ebinop (op, e1, e2) ->
      let op_str =
        match op with Badd -> "+" | Bmin -> "-" | Bmul -> "*" | Bdiv -> "/"
      in
      Printf.sprintf "%s %s %s" (string_of_expr e1) op_str (string_of_expr e2)
  | Elist es -> "[" ^ String.concat ", " (List.map string_of_expr es) ^ "]"

let string_of_const_value = function
  | Cint i -> string_of_int i
  | Cstring s -> Printf.sprintf "\"%s\"" s
  | Cbool b -> string_of_bool b
  | Cfloat f -> string_of_float f
  | Cexpr e -> string_of_expr e
  | Cempty -> "<no value>"

let string_of_key_name = function
  | Jump -> "JUMP"
  | MoveLeft -> "LEFT"
  | MoveRight -> "RIGHT"

let string_of_stmt = function
  | Keybinds kbs ->
      "KEYS:\n"
      ^ String.concat "\n"
          (List.map
             (fun { action; key } ->
               "  " ^ string_of_key_name action ^ ": " ^ key)
             kbs)

(* token to string for --tokens mode *)
let string_of_token = function
  | CONSTANTS -> "CONSTANTS"
  | COLON -> "COLON"
  | COMMA -> "COMMA"
  | LBRACKET -> "LBRACKET"
  | RBRACKET -> "RBRACKET"
  | NEWLINE -> "NEWLINE"
  | INDENT -> "INDENT"
  | DEDENT -> "DEDENT"
  | EOF -> "EOF"
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | MULTIPLY -> "MULTIPLY"
  | DIVIDE -> "DIVIDE"
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | ARENA -> "ARENA"
  | SPAWN -> "SPAWN"
  | PLAYERS -> "PLAYERS"
  | KEYS -> "KEYS"
  | COLOR -> "COLOR"
  | JUMP -> "JUMP"
  | LEFT -> "LEFT"
  | RIGHT -> "RIGHT"
  | IDENT s -> "IDENT(" ^ s ^ ")"
  | INT i -> "INT(" ^ string_of_int i ^ ")"
  | STRING s -> "STRING(" ^ s ^ ")"
  | FLOAT f -> "FLOAT(" ^ string_of_float f ^ ")"

let string_of_player p = Printf.sprintf "player %s \n" p.Ast.name
