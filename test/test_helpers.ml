open LilScript

(* parse a string into an AST, raising on failure *)
let parse_string (src : string) : Ast.program =
  let lexbuf = Lexing.from_string src in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = "<test>" };
  Parser.program Lexer.next_token lexbuf

(* parse and typecheck, returns unit or raises Type_error *)
let parse_and_check (src : string) : unit =
  let ast = parse_string src in
  Typecheck.check ast

(* a known-good minimal program used as a base for tests that need a valid AST *)
let minimal_valid_program =
  {|
constants:
  GRAVITY: 1.0
  JUMP_HEIGHT: 10
  SPEED: 4
players:
  p1:
    color: 255 0 0
    spawn: 1 1
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1,1,1],[0,0,0],[1,1,1]]
|}
