open OUnit2
open LilScript

(* helper: collect all tokens from a string until EOF *)
let tokens_of_string src =
  let lexbuf = Lexing.from_string src in
  let rec loop acc =
    let tok = Lexer.next_token lexbuf in
    match tok with Parser.EOF -> List.rev (tok :: acc) | _ -> loop (tok :: acc)
  in
  loop []

let test_int_literal _ =
  let toks = tokens_of_string "42" in
  match toks with
  | [ Parser.INT 42; Parser.EOF ] -> ()
  | _ -> assert_failure "expected INT(42) EOF"

let test_float_literal _ =
  let toks = tokens_of_string "1.5" in
  match toks with
  | [ Parser.FLOAT 1.5; Parser.EOF ] -> ()
  | _ -> assert_failure "expected FLOAT(1.5) EOF"

let test_bool_true _ =
  let toks = tokens_of_string "true" in
  match toks with
  | [ Parser.BOOL true; Parser.EOF ] -> ()
  | _ -> assert_failure "expected BOOL(true) EOF"

let test_bool_false _ =
  let toks = tokens_of_string "false" in
  match toks with
  | [ Parser.BOOL false; Parser.EOF ] -> ()
  | _ -> assert_failure "expected BOOL(false) EOF"

let test_string_literal _ =
  let toks = tokens_of_string "\"hello\"" in
  match toks with
  | [ Parser.STRING "hello"; Parser.EOF ] -> ()
  | _ -> assert_failure "expected STRING(hello) EOF"

let test_keyword_constants _ =
  let toks = tokens_of_string "constants" in
  match toks with
  | [ Parser.CONSTANTS; Parser.EOF ] -> ()
  | _ -> assert_failure "expected CONSTANTS EOF"

let test_identifier_lowercased _ =
  (* lexer lowercases identifiers, so MYVAR becomes myvar *)
  let toks = tokens_of_string "MYVAR" in
  match toks with
  | [ Parser.IDENT "myvar"; Parser.EOF ] -> ()
  | _ -> assert_failure "expected IDENT(myvar) EOF"

let suite =
  "lexer"
  >::: [
         "int_literal" >:: test_int_literal;
         "float_literal" >:: test_float_literal;
         "bool_true" >:: test_bool_true;
         "bool_false" >:: test_bool_false;
         "string_literal" >:: test_string_literal;
         "keyword_constants" >:: test_keyword_constants;
         "identifier_lowercased" >:: test_identifier_lowercased;
       ]
