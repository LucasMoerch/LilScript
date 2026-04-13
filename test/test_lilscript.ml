open OUnit2
open LilScript.Parser

(* ── keyword_or_ident tests ──────────────────────────────────────────────── *)

let test_keyword_constants _ =
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "constants")

let test_keyword_ident _ =
  assert_equal (IDENT "foo") (LilScript.Lexer.keyword_or_ident "foo")

let test_keyword_case_insensitive _ =
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "CONSTANTS");
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "Constants");
  assert_equal CONSTANTS (LilScript.Lexer.keyword_or_ident "cOnStAnTs")

(* ── emit_indent_tokens tests ────────────────────────────────────────────── *)

let test_emit_indent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  LilScript.Lexer.emit_indent_tokens 4 lexbuf;
  assert_equal INDENT (Queue.take LilScript.Lexer.pending)

let test_emit_dedent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Stack.push 4 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  LilScript.Lexer.emit_indent_tokens 0 lexbuf;
  assert_equal DEDENT (Queue.take LilScript.Lexer.pending)

let test_emit_bad_indent _ =
  Stack.clear LilScript.Lexer.indent_stack;
  Stack.push 0 LilScript.Lexer.indent_stack;
  Stack.push 4 LilScript.Lexer.indent_stack;
  Queue.clear LilScript.Lexer.pending;
  let lexbuf = Lexing.from_string "" in
  assert_raises
    (LilScript.Lexer.Lexing_error ("Indentation error", Lexing.lexeme_start_p lexbuf))
    (fun () -> LilScript.Lexer.emit_indent_tokens 2 lexbuf)

(* ── next_token: basic tokens ────────────────────────────────────────────── *)

let test_int _ =
  let lexbuf = Lexing.from_string "42" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal (INT 42) tok

let test_float _ =
  let lexbuf = Lexing.from_string "3.14" in
  let tok = LilScript.Lexer.next_token lexbuf in
  match tok with
  | FLOAT f -> assert_bool "FLOAT value mismatch" (abs_float (f -. 3.14) < 0.0001)
  | _ -> assert_failure "Expected FLOAT token"

let test_plus _ =
  let lexbuf = Lexing.from_string "+" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal PLUS tok

let test_minus _ =
  let lexbuf = Lexing.from_string "-" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal MINUS tok

let test_multiply _ =
  let lexbuf = Lexing.from_string "*" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal MULTIPLY tok

let test_divide _ =
  let lexbuf = Lexing.from_string "/" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal DIVIDE tok

let test_colon _ =
  let lexbuf = Lexing.from_string ":" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal COLON tok

(* ── next_token: newlines ────────────────────────────────────────────────── *)

let test_newline_unix _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "\n" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

let test_newline_windows _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "\r\n" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

let test_newline_mac _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "\r" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal NEWLINE tok

(* ── next_token: comments ────────────────────────────────────────────────── *)

let test_comment_skipped _ =
  let lexbuf = Lexing.from_string "// hello world" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal EOF tok

(* ── next_token: EOF ─────────────────────────────────────────────────────── *)

let test_eof _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal EOF tok

let test_eof_flushes_dedent _ =
  LilScript.Lexer.reset ();
  Stack.push 4 LilScript.Lexer.indent_stack;
  let lexbuf = Lexing.from_string "" in
  let tok = LilScript.Lexer.next_token lexbuf in
  assert_equal DEDENT tok

(* ── next_token: error handling ─────────────────────────────────────────── *)

let test_lexing_error _ =
  LilScript.Lexer.reset ();
  let lexbuf = Lexing.from_string "@" in
  assert_raises
    (LilScript.Lexer.Lexing_error ("Unexpected character: @", Lexing.lexeme_start_p lexbuf))
    (fun () -> LilScript.Lexer.next_token lexbuf)

(* ── test suite ──────────────────────────────────────────────────────────── *)

let suite =
  "Lexer tests" >::: [
    (* keyword_or_ident *)
    "constants keyword"          >:: test_keyword_constants;
    "plain identifier"           >:: test_keyword_ident;
    "case insensitive"           >:: test_keyword_case_insensitive;
    (* emit_indent_tokens *)
    "emit indent"                >:: test_emit_indent;
    "emit dedent"                >:: test_emit_dedent;
    "emit bad indent"            >:: test_emit_bad_indent;
    (* next_token: basic tokens *)
    "int"                        >:: test_int;
    "float"                      >:: test_float;
    "plus"                       >:: test_plus;
    "minus"                      >:: test_minus;
    "multiply"                   >:: test_multiply;
    "divide"                     >:: test_divide;
    "colon"                      >:: test_colon;
    (* next_token: newlines *)
    "newline unix"               >:: test_newline_unix;
    "newline windows"            >:: test_newline_windows;
    "newline mac"                >:: test_newline_mac;
    (* next_token: comments *)
    "comment skipped"            >:: test_comment_skipped;
    (* next_token: EOF *)
    "eof"                        >:: test_eof;
    "eof flushes dedent"         >:: test_eof_flushes_dedent;
    (* next_token: errors *)
    "lexing error"               >:: test_lexing_error;
  ]

let () = run_test_tt_main suite