(* Read an entire file into a single string *)
let read_file path =
  let ic = open_in path in                 (* Open file for reading *)
  let n = in_channel_length ic in          (* Byte length *)
  let s = really_input_string ic n in      (* Read exactly n bytes into a string *)
  close_in ic;                             (* Always close the channel *)
  s

let () =
  (* Check if no CLI arg has been given *)
  if Array.length Sys.argv < 2 then (
    prerr_endline "Usage: ourlangc <file>";
    exit 1
  );

  (* Debug message confirm it runs *)
  Printf.eprintf "Running on %s\n%!" Sys.argv.(1);

  (* Load the whole source file into memory and build a lexing buffer over it *)
  let src = read_file Sys.argv.(1) in
  let lexbuf = Lexing.from_string src in  (* Create lexbuf that reads from a string *)

  try
    (* Parse using Menhir entrypoint program and the token supplier next_token *)
    let ast = Ourlang.Parser.program Ourlang.Lexer.next_token lexbuf in

    (* Print a tiny summary + each constant as "name=value" *)
    Printf.printf "Parsed %d constants\n%!"
      (List.length ast.Ourlang.Ast.constants);

    List.iter
      (fun c ->
        Printf.printf "%s=%d\n%!" c.Ourlang.Ast.name c.Ourlang.Ast.value)
      ast.Ourlang.Ast.constants

  with
  (* Lexer raises a custom exception when it sees illegal characters / malformed tokens *)
  | Ourlang.Lexer.Lexing_error msg ->
      Printf.eprintf "Lexing error: %s\n%!" msg

  (* Menhir-generated parsers raise Parser.Error on syntax errors by default *)
  | Ourlang.Parser.Error ->
      Printf.eprintf "Parse error\n%!"
