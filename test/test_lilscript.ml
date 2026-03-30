open OUnit2
open LilScript.Parser

(* Existing tests *)
let test_keyword_or_ident_constants _ =
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "constants")

let test_keyword_or_ident_other _ =
  assert_equal (IDENT "foo") (LilScript.Lexer.keyword_or_ident "foo")

(* New test for case insensitivity *)
let test_keyword_or_ident_uppercase _ =
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "CONSTANTS");
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "Constants");
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "cOnStAnTs")

(* Test 1: n > current → should add INDENT *)
let test_emit_indent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  LilScript.Lexer.emit_indent_tokens 4 lexbuf;
  assert_equal INDENT (Queue.take LilScript.Lexer.pending)

(* Test 2: n < current → should add DEDENT *)
let test_emit_dedent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Stack.push 4 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  LilScript.Lexer.emit_indent_tokens 0 lexbuf;
  assert_equal DEDENT (Queue.take LilScript.Lexer.pending)

(* Test 3: bad indentation → should raise Lexing_error *)
let test_emit_bad_indent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Stack.push 4 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  assert_raises
    (LilScript.Lexer.Lexing_error
       ("Indentation error", Lexing.lexeme_start_p lexbuf))
    (fun () -> LilScript.Lexer.emit_indent_tokens 2 lexbuf)

let test_int _ =
  let lexbuf = Lexing.from_string "42" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal (INT 42) tok

let test_PLUS _ =
  let lexbuf = Lexing.from_string "+" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal PLUS tok

let test_MINUS _ =
  let lexbuf = Lexing.from_string "-" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal MINUS tok

let test_MULTIPLY _ =
  let lexbuf = Lexing.from_string "*" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal MULTIPLY tok

let test_DIVIDE _ =
  let lexbuf = Lexing.from_string "/" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal DIVIDE tok

let test_COLON _ =
  let lexbuf = Lexing.from_string ":" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal COLON tok

let test_FLOAT _ =
  let lexbuf = Lexing.from_string "3.14" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal (FLOAT 3.14) tok


let test_NEWLINE_rn _ =
  LilScript.Lexer.reset();
  let lexbuf = Lexing.from_string "\r\n" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

let test_NEWLINE_r _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "\r" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

let test_NEWLINE_n _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "\n" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

let test_COMMENT _ =
  let lexbuf = Lexing.from_string "//hello world" in 
  let tok = LilScript.Lexer.next_token lexbuf in 
  assert_equal EOF tok

let test_EMPTYSTRING _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "" in 
  let tok = LilScript.Lexer.next_token lexbuf in 
  assert_equal EOF tok


let test_EOF_dedent _ =
  LilScript.Lexer.reset ();
  Stack.push 4 LilScript.Lexer.indent_stack;
  let lexbuf = Lexing.from_string "" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal DEDENT tok

let test_Lexingerror _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "@" in
  assert_raises 
  (LilScript.Lexer.Lexing_error ("Unexpected character: @", Lexing.lexeme_start_p lexbuf))
    (fun () -> LilScript.Lexer.next_token lexbuf)

  (* Test suite *)
let suite =
  "Lexer tests"
  >::: [
         "constants keyword" >:: test_keyword_or_ident_constants;
         "other identifiers" >:: test_keyword_or_ident_other;
         "constants case-insensitive" >:: test_keyword_or_ident_uppercase;
         "emit indent" >:: test_emit_indent;
         "emit dedent" >:: test_emit_dedent;
         "emit bad indent" >:: test_emit_bad_indent;
         "INT" >:: test_int;
         "PLUS" >:: test_PLUS;
         "MINUS" >:: test_MINUS;
         "MULTIPLY" >:: test_MULTIPLY;
         "DIVIDE" >:: test_DIVIDE;
         "COLON" >:: test_COLON;
         "FLOAT" >:: test_FLOAT;
         "NEWLINE" >:: test_NEWLINE_rn;
         "NEWLINE" >:: test_NEWLINE_r;
         "NEWLINE" >:: test_NEWLINE_n;
         "EOF" >:: test_COMMENT;
         "EOF" >:: test_EMPTYSTRING;
         "EOF" >:: test_EOF_dedent;
         "fun" >:: test_Lexingerror;

       ]

(* Run the suite *)
let () = run_test_tt_main suite
