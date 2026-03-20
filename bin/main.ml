(* Read an entire file into a single string *)
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

(* Check for duplicate constants and report position *)
let check_duplicates constants =
  let seen = Hashtbl.create 16 in
  List.iter
    (fun c ->
      if Hashtbl.mem seen c.LilScript.Ast.name then (
        let pos = c.pos in
        let line = pos.pos_lnum in
        let col = pos.pos_cnum - pos.pos_bol + 1 in
        Printf.eprintf "%s:%d:%d: Duplicate constant '%s'\n%!" pos.pos_fname
          line col c.name;
        exit 1)
      else Hashtbl.add seen c.LilScript.Ast.name c)
    constants

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

(* Pretty-print constant values from the AST *)
let string_of_const_value = function
  | LilScript.Ast.Cint i -> string_of_int i
  | LilScript.Ast.Cstring s -> Printf.sprintf "\"%s\"" s
  | LilScript.Ast.Cbool b -> string_of_bool b
  | LilScript.Ast.Cfloat f -> string_of_float f
  | LilScript.Ast.Cexpr e -> string_of_expr e

(* Simple evaluator for expressions *)
let rec eval_expr env = function
  | LilScript.Ast.Econst (LilScript.Ast.SCint i) -> float_of_int i
  | LilScript.Ast.Econst (LilScript.Ast.SCfloat f) -> f
  | LilScript.Ast.Econst (LilScript.Ast.SCbool _) ->
      failwith "Boolean values cannot be used in arithmetic expressions"
  | LilScript.Ast.Econst (LilScript.Ast.SCstring _) ->
      failwith "String values cannot be used in arithmetic expressions"
  | LilScript.Ast.Evar id ->
      if Hashtbl.mem env id.LilScript.Ast.id then
        Hashtbl.find env id.LilScript.Ast.id
      else failwith ("Unknown constant: " ^ id.LilScript.Ast.id)
  | LilScript.Ast.Ebinop (op, e1, e2) -> (
      let v1 = eval_expr env e1 in
      let v2 = eval_expr env e2 in
      match op with
      | LilScript.Ast.Badd -> v1 +. v2
      | LilScript.Ast.Bmin -> v1 -. v2
      | LilScript.Ast.Bmul -> v1 *. v2
      | LilScript.Ast.Bdiv -> v1 /. v2)

(* Flag for token dumping *)
let dump_tokens = ref false
let dump_ast = ref false
let input_file = ref None

let options : (string * Arg.spec * string) list =
  [
    ("--tokens", Arg.Set dump_tokens, "Print the token stream and exit");
    ("--ast", Arg.Set dump_ast, "Dump AST after parsing");
  ]

let set_file f = input_file := Some f

let string_of_token = function
  | LilScript.Parser.CONSTANTS -> "CONSTANTS"
  | LilScript.Parser.COLON -> "COLON"
  | LilScript.Parser.NEWLINE -> "NEWLINE"
  | LilScript.Parser.INDENT -> "INDENT"
  | LilScript.Parser.DEDENT -> "DEDENT"
  | LilScript.Parser.EOF -> "EOF"
  | LilScript.Parser.IDENT s -> "IDENT(" ^ s ^ ")"
  | LilScript.Parser.INT i -> "INT(" ^ string_of_int i ^ ")"
  | LilScript.Parser.PLUS -> "PLUS"
  | LilScript.Parser.MINUS -> "MINUS"
  | LilScript.Parser.MULTIPLY -> "MULTIPLY"
  | LilScript.Parser.DIVIDE -> "DIVIDE"

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
    if !dump_tokens then print_tokens lexbuf
    else
      (* Parse using Menhir entrypoint program and the token supplier next_token *)
      let ast = LilScript.Parser.program LilScript.Lexer.next_token lexbuf in

      (* Dump AST for the debugging *)
      if !dump_ast then LilScript.Ast_printer.dump ast;

      (*Check for duplicate constants*)
      check_duplicates ast.LilScript.Ast.constants;

      Printf.printf "Parsed %d constants\n%!"
        (List.length ast.LilScript.Ast.constants);

      (* Print parsed AST *)
      List.iter
        (fun c ->
          Printf.printf "%s = %s\n%!" c.LilScript.Ast.name
            (string_of_const_value c.LilScript.Ast.value))
        ast.LilScript.Ast.constants;

      (* Build environment for evaluation *)
      let env = Hashtbl.create 16 in
      List.iter
        (fun c ->
          match c.LilScript.Ast.value with
          | LilScript.Ast.Cint i ->
              Hashtbl.add env c.LilScript.Ast.name (float_of_int i)
          | LilScript.Ast.Cfloat f -> Hashtbl.add env c.LilScript.Ast.name f
          | _ -> ())
        ast.LilScript.Ast.constants;

      (* Evaluate expressions *)
      Printf.printf "\nEvaluated:\n%!";
      List.iter
        (fun c ->
          match c.LilScript.Ast.value with
          | LilScript.Ast.Cexpr e ->
              Printf.printf "%s = %.0f\n%!" c.LilScript.Ast.name
                (eval_expr env e)
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
