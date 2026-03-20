open Ast

let indent n = String.make (2 * n) ' '

let rec print_expr level expr =
  match expr with
  | Econst sc -> (
      match sc with
      | SCint i -> Printf.printf "%sSCint %d\n" (indent level) i
      | SCfloat f -> Printf.printf "%sSCfloat %f\n" (indent level) f
      | SCbool b -> Printf.printf "%sSCbool %b\n" (indent level) b
      | SCstring s -> Printf.printf "%sSCstring \"%s\"\n" (indent level) s)
  | Evar id -> Printf.printf "%sEvar %s\n" (indent level) id.id
  | Ebinop (op, left, right) ->
      let op_str =
        match op with
        | Badd -> "Badd (+)"
        | Bmin -> "Bmin (-)"
        | Bmul -> "Bmul (*)"
        | Bdiv -> "Bdiv (/)"
      in
      Printf.printf "%sEbinop %s\n" (indent level) op_str;
      print_expr (level + 1) left;
      print_expr (level + 1) right

let print_const level c =
  Printf.printf "%sConstant %s\n" (indent level) c.name;
  match c.value with
  | Cint i -> Printf.printf "%sCint %d\n" (indent (level + 1)) i
  | Cfloat f -> Printf.printf "%sCfloat %f\n" (indent (level + 1)) f
  | Cstring s -> Printf.printf "%sCstring \"%s\"\n" (indent (level + 1)) s
  | Cbool b -> Printf.printf "%sCbool %b\n" (indent (level + 1)) b
  | Cexpr e ->
      Printf.printf "%sCexpr\n" (indent (level + 1));
      print_expr (level + 2) e

let dump program =
  Printf.printf "Program\n";
  List.iter (print_const 1) program.constants
