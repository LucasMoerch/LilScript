let read_file path =
  let ic = open_in path in
  let buf = Buffer.create 1024 in
  (try
     while true do
       Buffer.add_string buf (input_line ic);
       Buffer.add_char buf '\n'
     done
   with End_of_file -> ());
  close_in ic;
  Buffer.contents buf

(* Pretty-print expressions *)
let rec string_of_expr = function
  | LilScript.Ast.Econst sc -> (
      match sc with
      | LilScript.Ast.SCint i -> string_of_int i
      | LilScript.Ast.SCfloat f -> string_of_float f
      | LilScript.Ast.SCbool b -> string_of_bool b
      | LilScript.Ast.SCstring s -> "\"" ^ s ^ "\"")
  | LilScript.Ast.Evar id -> id.LilScript.Ast.id
  | LilScript.Ast.Ebinop (op, e1, e2) ->
      let op_str =
        match op with
        | LilScript.Ast.Badd -> "+"
        | LilScript.Ast.Bmin -> "-"
        | LilScript.Ast.Bmul -> "*"
        | LilScript.Ast.Bdiv -> "/"
      in
      Printf.sprintf "%s %s %s" (string_of_expr e1) op_str (string_of_expr e2)
  | LilScript.Ast.Elist es ->
      "[" ^ String.concat ", " (List.map string_of_expr es) ^ "]"

(* Pretty-print constant values from the AST *)
let string_of_const_value = function
  | LilScript.Ast.Cint i -> string_of_int i
  | LilScript.Ast.Cstring s -> Printf.sprintf "\"%s\"" s
  | LilScript.Ast.Cbool b -> string_of_bool b
  | LilScript.Ast.Cfloat f -> string_of_float f
  | LilScript.Ast.Cexpr e ->
      string_of_expr e

let string_of_key_name = function
  | LilScript.Ast.Jump -> "JUMP"
  | LilScript.Ast.Left -> "LEFT"
  | LilScript.Ast.Right -> "RIGHT"

let string_of_stmt = function
  | LilScript.Ast.Keybinds kbs ->
      "KEYS:\n" ^ String.concat "\n" (List.map (fun (kn, k) -> "  " ^ string_of_key_name kn ^ ": " ^ k) kbs)

(* Simple evaluator for expressions *)
let rec eval_expr = function
  | LilScript.Ast.Econst (LilScript.Ast.SCint i) -> float_of_int i
  | LilScript.Ast.Econst (LilScript.Ast.SCfloat f) -> f
  | LilScript.Ast.Ebinop (op, e1, e2) -> (
      let v1 = eval_expr e1 in
      let v2 = eval_expr e2 in
      match op with
      | LilScript.Ast.Badd -> v1 +. v2
      | LilScript.Ast.Bmin -> v1 -. v2
      | LilScript.Ast.Bmul -> v1 *. v2
      | LilScript.Ast.Bdiv -> v1 /. v2)
  | _ -> 0.0 (* Fallback *)

(* Flag for token dumping *)
let dump_tokens = ref false
let input_file = ref None

let options =
  [ ("--tokens", Arg.Set dump_tokens, "Print the token stream and exit") ]

let set_file f = input_file := Some f

let string_of_token = function
  | LilScript.Parser.CONSTANTS -> "CONSTANTS"
  | LilScript.Parser.COLON -> "COLON"
  | LilScript.Parser.COMMA -> "COMMA"
  | LilScript.Parser.LBRACKET -> "LBRACKET"
  | LilScript.Parser.RBRACKET -> "RBRACKET"
  | LilScript.Parser.NEWLINE -> "NEWLINE"
  | LilScript.Parser.INDENT -> "INDENT"
  | LilScript.Parser.DEDENT -> "DEDENT"
  | LilScript.Parser.EOF -> "EOF"
  | LilScript.Parser.IDENT s -> "IDENT(" ^ s ^ ")"
  | LilScript.Parser.INT i -> "INT(" ^ string_of_int i ^ ")"
  | LilScript.Parser.STRING s -> "STRING(" ^ s ^ ")"
  | LilScript.Parser.PLUS -> "PLUS"
  | LilScript.Parser.MINUS -> "MINUS"
  | LilScript.Parser.MULTIPLY -> "MULTIPLY"
  | LilScript.Parser.DIVIDE -> "DIVIDE"
  | LilScript.Parser.ARENA -> "ARENA"
  | LilScript.Parser.WIN -> "WIN"
  | LilScript.Parser.LOSE -> "LOSE"
  | LilScript.Parser.SPAWN -> "SPAWN"
  | LilScript.Parser.PLAYERS -> "PLAYERS"
  | LilScript.Parser.KEYS -> "KEYS"
  | LilScript.Parser.JUMP -> "JUMP"
  | LilScript.Parser.LEFT -> "LEFT"
  | LilScript.Parser.RIGHT -> "RIGHT"

(* Print tokens until EOF *)
let rec print_tokens lexbuf =
  let tok = LilScript.Lexer.next_token lexbuf in
  Printf.printf "%s\n%!" (string_of_token tok);
  match tok with LilScript.Parser.EOF -> () | _ -> print_tokens lexbuf

(* Parse CLI arguments *)
let () =
  Arg.parse options set_file "Usage: lilscriptc [--tokens] <file>";

  (* Check if no CLI arg has been given *)
  let filename =
    match !input_file with
    | Some f -> f
    | None ->
        prerr_endline "No input file provided";
        exit 1
  in
  Printf.eprintf "Running on %s\n%!" filename;

  (* Load the whole source file into memory and build a lexing buffer over it *)
  let src = read_file filename in
  let lexbuf = Lexing.from_string src in
  (* Create lexbuf that reads from a string *)
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };

  try
    (* Parse using Menhir entrypoint program and the token supplier next_token *)
    if !dump_tokens then print_tokens lexbuf
    else
      let ast = LilScript.Parser.program LilScript.Lexer.next_token lexbuf in

      Printf.printf "Parsed %d constants\n%!"
        (List.length ast.LilScript.Ast.constants);

      (* Print parsed AST *)
      List.iter
        (fun c ->
          Printf.printf "%s = %s\n%!" c.LilScript.Ast.name
            (string_of_const_value c.LilScript.Ast.value))
        ast.LilScript.Ast.constants;

      Printf.printf "Parsed %d statements\n%!"
        (List.length ast.LilScript.Ast.stmts);

      List.iter
        (fun s -> Printf.printf "%s\n%!" (string_of_stmt s))
        ast.LilScript.Ast.stmts;

      (* Evaluate expressions *)
      Printf.printf "\nEvaluated:\n%!";
      List.iter
        (fun c ->
          match c.LilScript.Ast.value with
          | LilScript.Ast.Cexpr e ->
              Printf.printf "%s = %.0f\n%!" c.LilScript.Ast.name (eval_expr e)
          | LilScript.Ast.Cint i ->
              Printf.printf "%s = %d\n%!" c.LilScript.Ast.name i
          | _ -> ())
        ast.LilScript.Ast.constants
  with
  | LilScript.Lexer.Lexing_error (msg, pos) ->
      let line = pos.pos_lnum in
      let col = pos.pos_cnum - pos.pos_bol + 1 in
      Printf.eprintf "%s:%d:%d: %s\n%!" pos.pos_fname line col msg
  | LilScript.Parser.Error -> Printf.eprintf "Parse error\n%!"
