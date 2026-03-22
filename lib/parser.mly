%{
open Ast
%}

%token LPAREN RPAREN (* Tokens for parentheses to support grouped expressions *)
%token CONSTANTS
%token COLON
%token NEWLINE INDENT DEDENT
%token <string> IDENT
%token <int> INT
%token EOF

//OPERATORS
%token PLUS MINUS MULTIPLY DIVIDE

%left PLUS MINUS
%left MULTIPLY DIVIDE

%start <Ast.program> program
%%

program:
  constants_block trailing_newlines EOF { { constants = $1 } }

trailing_newlines:
  /* empty */ { () }
| NEWLINE trailing_newlines { () }

constants_block:
  CONSTANTS COLON NEWLINE INDENT const_lines DEDENT { $5 }

const_lines:
  /* empty */ { [] }
| const_line const_lines { $1 :: $2 }

const_line:
  | IDENT COLON INT NEWLINE {
    let start_pos = $startpos in
    { name = $1; value = Cint $3; pos = start_pos } }
    
  | IDENT COLON expr NEWLINE
    { { name = $1; value = Cexpr $3; pos = $startpos } }

  | IDENT COLON NEWLINE
      { { name = $1; value = Cempty; pos = $startpos } }

(* Update the expression grammar by removing generic binop rule (expr o expr) because it breaks precedence
, added explicit rules for each operator so precedence works correctly and
 added parentheses rule to allow grouping: (expr) *)
expr:
  | INT { Econst (SCint $1) }
  | id = ident { Evar id }

  | e1 = expr PLUS e2 = expr { Ebinop (Badd, e1, e2) }
  | e1 = expr MINUS e2 = expr { Ebinop (Bmin, e1, e2) }
  | e1 = expr MULTIPLY e2 = expr { Ebinop (Bmul, e1, e2) }
  | e1 = expr DIVIDE e2 = expr { Ebinop (Bdiv, e1, e2) }

  | LPAREN e = expr RPAREN { e }
;

ident:
  | id = IDENT { { loc = ($startpos, $endpos); id; pos = $startpos } }
;
