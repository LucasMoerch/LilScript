open LilScript.Ast

(* formats a position as fname:line:col *)
let pos_str pos =
  let line = pos.Lexing.pos_lnum in
  let col = pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1 in
  Printf.sprintf "%s:%d:%d" pos.Lexing.pos_fname line col

(* checks for duplicate constant names, exits on first duplicate *)
let check_duplicates (constants : const_decl list) =
  let seen = Hashtbl.create 16 in
  List.iter
    (fun (c : const_decl) ->
      if Hashtbl.mem seen c.name then (
        Printf.eprintf "%s: Duplicate constant '%s'\n%!" (pos_str c.pos) c.name;
        exit 1)
      else Hashtbl.add seen c.name c)
    constants
