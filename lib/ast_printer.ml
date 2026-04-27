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
  | Elist exprs ->
      Printf.printf "%sElist\n" (indent level);
      List.iter (print_expr (level + 1)) exprs

let print_const level (c : const_decl) =
  Printf.printf "%sConstant %s\n" (indent level) c.name;
  match c.value with
  | Cint i -> Printf.printf "%sCint %d\n" (indent (level + 1)) i
  | Cfloat f -> Printf.printf "%sCfloat %f\n" (indent (level + 1)) f
  | Cstring s -> Printf.printf "%sCstring \"%s\"\n" (indent (level + 1)) s
  | Cbool b -> Printf.printf "%sCbool %b\n" (indent (level + 1)) b
  | Cexpr e ->
      Printf.printf "%sCexpr\n" (indent (level + 1));
      print_expr (level + 2) e
  | Cempty -> Printf.printf "%sCempty\n" (indent (level + 1))

let print_keybind level { action; key } =
  let action_str =
    match action with
    | Jump -> "Jump"
    | MoveLeft -> "MoveLeft"
    | MoveRight -> "MoveRight"
  in
  Printf.printf "%sKeybind %s -> %s\n" (indent level) action_str key

(* color and spawn are now expressions, so print them as expr trees *)
let print_player level (p : player) =
  Printf.printf "%sPlayer %s\n" (indent level) p.name;
  Printf.printf "%sColor\n" (indent (level + 1));
  Printf.printf "%sred:\n" (indent (level + 2));
  print_expr (level + 3) p.color.red;
  Printf.printf "%sgreen:\n" (indent (level + 2));
  print_expr (level + 3) p.color.green;
  Printf.printf "%sblue:\n" (indent (level + 2));
  print_expr (level + 3) p.color.blue;
  Printf.printf "%sSpawn\n" (indent (level + 1));
  Printf.printf "%sx:\n" (indent (level + 2));
  print_expr (level + 3) p.spawn.x;
  Printf.printf "%sy:\n" (indent (level + 2));
  print_expr (level + 3) p.spawn.y;
  List.iter (print_keybind (level + 1)) p.keybinds

let string_of_tile_kind = function
  | Tsolid -> "Tsolid"
  | Twin -> "Twin"
  | Tlose -> "Tlose"
  | Tempty -> "Tempty"

let print_arena level arena =
  Printf.printf "%sArena %dx%d\n" (indent level) arena.width arena.height;
  Array.iter
    (fun row ->
      Printf.printf "%s[%s]\n"
        (indent (level + 1))
        (String.concat "; " (Array.to_list (Array.map string_of_tile_kind row))))
    arena.tiles

let dump program =
  Printf.printf "Program\n";
  List.iter (print_const 1) program.constants;
  List.iter (print_player 1) program.players;
  match program.arena with Some arena -> print_arena 1 arena | None -> ()
