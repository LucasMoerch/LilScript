open LilScript

let dump_tokens = ref false
let dump_ast = ref false
let input_file = ref None
let output_file = ref None

let options =
  [
    ("--tokens", Arg.Set dump_tokens, "Print token stream and exit");
    ("--ast", Arg.Set dump_ast, "Dump AST after parsing");
    ("--output", Arg.String (fun s -> output_file := Some s), "Output .py path");
  ]

(* prints all tokens until EOF *)
let rec print_tokens lexbuf =
  let tok = Lexer.next_token lexbuf in
  Printf.printf "%s\n%!" (Pretty.string_of_token tok);
  match tok with Parser.EOF -> () | _ -> print_tokens lexbuf

let () =
  Arg.parse options
    (fun f -> input_file := Some f)
    "Usage: lilscriptc [--tokens] <file>";

  let filename =
    match !input_file with
    | Some f -> f
    | None ->
        prerr_endline "No input file provided";
        exit 1
  in
  Printf.eprintf "Running on %s\n%!" filename;

  let src = File_io.read_file filename in
  let lexbuf = Lexing.from_string src in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };

  try
    if !dump_tokens then print_tokens lexbuf
    else begin
      let ast = Parser.program Lexer.next_token lexbuf in
      if !dump_ast then Ast_printer.dump ast;

      Diagnostics.check_duplicates ast.Ast.constants;

      (* generate python output *)
      let python_src = Codegen.generate ast in
      let out_path =
        match !output_file with
        | Some p -> p
        | None ->
            let base = Filename.basename (Filename.remove_extension filename) in
            Filename.concat "pygame" (base ^ ".py")
      in
      let oc = open_out out_path in
      output_string oc python_src;
      close_out oc;

      Printf.printf "Written to %s\n%!" out_path;
      Printf.printf "Parsed %d constants\n%!" (List.length ast.Ast.constants);
      Printf.printf "Parsed %d players\n%!" (List.length ast.Ast.players);
      Printf.printf "Parsed %d statements\n%!" (List.length ast.Ast.stmts);

      List.iter
        (fun p -> print_string (Pretty.string_of_player p))
        ast.Ast.players;

      List.iter
        (fun s -> Printf.printf "%s\n%!" (Pretty.string_of_stmt s))
        ast.Ast.stmts;

      let env = Hashtbl.create 16 in
      List.iter (Eval.add_to_env env) ast.Ast.constants;
      Printf.printf "\nEvaluated:\n%!";
      List.iter (Eval.print_evaluated env) ast.Ast.constants
    end
  with
  | Lexer_utils.Lexing_error (msg, pos) ->
      Printf.eprintf "%s: %s\n%!" (Diagnostics.pos_str pos) msg
  | Parser.Error ->
      Printf.eprintf "%s: Parse error\n%!"
        (Diagnostics.pos_str lexbuf.lex_curr_p)
