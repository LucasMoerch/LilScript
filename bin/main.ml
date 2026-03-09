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

  let check_duplicates constants =
  let seen = Hashtbl.create 16 in
  List.iter (fun c ->
    if Hashtbl.mem seen c.Lilscript.Ast.name then
      failwith ("Duplicate constant: " ^ c.Lilscript.Ast.name)
    else
      Hashtbl.add seen c.Lilscript.Ast.name ()
  ) constants

let () =
  (* Check if no CLI arg has been given *)
  if Array.length Sys.argv < 2 then (
    prerr_endline "Usage: lilscriptc <file>";
    exit 1
  );

  (* Debug message confirm it runs *)
  Printf.eprintf "Running on %s\n%!" Sys.argv.(1);

  (* Load the whole source file into memory and build a lexing buffer over it *)
  let src = read_file Sys.argv.(1) in
let lexbuf = Lexing.from_string src in  (* Create lexbuf that reads from a string *)

(
try
  (* Parse using Menhir entrypoint program and the token supplier next_token *)
  let ast = Lilscript.Parser.program Lilscript.Lexer.next_token lexbuf in

check_duplicates ast.Lilscript.Ast.constants;

  (* Print a tiny summary + each constant as "name=value" *)
  Printf.printf "Parsed %d constants\n%!"
    (List.length ast.Lilscript.Ast.constants);

  List.iter
    (fun c ->
      Printf.printf "%s=%d\n%!" c.Lilscript.Ast.name c.Lilscript.Ast.value)
    ast.Lilscript.Ast.constants

with
(* Lexer raises a custom exception when it sees illegal characters / malformed tokens *)
| Lilscript.Lexer.Lexing_error msg ->
    Printf.eprintf "Lexing error: %s\n%!" msg
(* Menhir-generated parsers raise Parser.Error on syntax errors by default *)
| Lilscript.Parser.Error ->
    Printf.eprintf "Parse error\n%!"
)
