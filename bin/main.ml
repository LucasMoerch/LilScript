(* Read an entire file into a single string *)
let read_file path =
  let ic = open_in path in                 (* Open file for reading *)
  let n = in_channel_length ic in          (* Byte length *)
  let s = really_input_string ic n in      (* Read exactly n bytes into a string *)
  close_in ic;                             (* Always close the channel *)
  s

(* Flag for token dumping *)
let dump_tokens = ref false
let input_file = ref None

let options = [
  ("--tokens", Arg.Set dump_tokens, "Print the token stream and exit")
]

let set_file f =
input_file := Some f

let string_of_token = function
  | LilScript.Parser.CONSTANTS -> "CONSTANTS"
  | LilScript.Parser.COLON -> "COLON"
  | LilScript.Parser.NEWLINE -> "NEWLINE"
  | LilScript.Parser.INDENT -> "INDENT"
  | LilScript.Parser.DEDENT -> "DEDENT"
  | LilScript.Parser.EOF -> "EOF"
  | LilScript.Parser.IDENT s -> "IDENT(" ^ s ^ ")"
  | LilScript.Parser.INT i -> "INT(" ^ string_of_int i ^ ")"

(* Print tokens until EOF *)
let rec print_tokens lexbuf =
let tok = LilScript.Lexer.next_token lexbuf in
  Printf.printf "%s\n%!" (string_of_token tok);
match tok with
| LilScript.Parser.EOF -> ()
| _ -> print_tokens lexbuf

(* Parse CLI arguments *)
let () =
  Arg.parse options set_file "Usage: lilscriptc [--tokens] <file>";

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
  let lexbuf = Lexing.from_string src in  (* Create lexbuf that reads from a string *)
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = Sys.argv.(1) };

  try
    (* Parse using Menhir entrypoint program and the token supplier next_token *)
    if !dump_tokens then
      print_tokens lexbuf
    else (
      let ast = LilScript.Parser.program LilScript.Lexer.next_token lexbuf in
    
      Printf.printf "Parsed %d constants\n%!"
        (List.length ast.LilScript.Ast.constants);
    
      List.iter
        (fun c ->
          Printf.printf "%s=%d\n%!"
            c.LilScript.Ast.name
            c.LilScript.Ast.value)
        ast.LilScript.Ast.constants
    )
    
  with
  (* Lexer raises a custom exception when it sees illegal characters / malformed tokens *)
  | LilScript.Lexer.Lexing_error (msg, pos) ->
    let line = pos.pos_lnum in
    let col = pos.pos_cnum - pos.pos_bol + 1 in
    Printf.eprintf "%s:%d:%d: %s\n%!" pos.pos_fname line col msg

  (* Menhir-generated parsers raise Parser.Error on syntax errors by default *)
  | LilScript.Parser.Error ->
      Printf.eprintf "Parse error\n%!"