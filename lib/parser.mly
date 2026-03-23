%{
open Ast
open Keys
%}

%token LPAREN RPAREN
%token CONSTANTS
%token COLON COMMA LBRACKET RBRACKET
%token NEWLINE INDENT DEDENT
%token <string> IDENT
%token <int> INT
%token <string> STRING
%token <float> FLOAT
%token EOF

//OPERATORS
%token PLUS MINUS MULTIPLY DIVIDE

%left PLUS MINUS
%left MULTIPLY DIVIDE

//Keywords
%token ARENA WIN LOSE SPAWN PLAYERS
%token KEYS JUMP LEFT RIGHT

%start <Ast.program> program
%%

program:
  blocks trailing_newlines EOF { { constants = fst $1; stmts = snd $1 } }

trailing_newlines:
  | /* empty */ { () }
  | NEWLINE trailing_newlines { () }

blocks:
  | constants_block             { ($1, []) }
  | stmts                       { ([], $1) }
  | constants_block stmts       { ($1, $2) }
  | stmts constants_block       { ($2, $1) }

constants_block:
  CONSTANTS COLON NEWLINE INDENT const_lines DEDENT { $5 }

const_lines:
  | /* empty */ { [] }
  | const_line const_lines { $1 :: $2 }

const_line:
  | IDENT COLON INT NEWLINE {
      let start_pos = $startpos in
      { name = $1; value = Cint $3; pos = start_pos }
    }
  | IDENT COLON FLOAT NEWLINE {
      let start_pos = $startpos in
      { name = $1; value = Cfloat $3; pos = start_pos }
    }
  | IDENT COLON STRING NEWLINE {
      let start_pos = $startpos in
      { name = $1; value = Cstring $3; pos = start_pos }
    }
  | IDENT COLON expr NEWLINE {
      let start_pos = $startpos in
      { name = $1; value = Cexpr $3; pos = start_pos }
    }

(* Explicit operator rules for correct precedence, parens for grouping *)
expr:
  | INT                                          { Econst (SCint $1) }
  | FLOAT                                        { Econst (SCfloat $1) }
  | id = ident                                   { Evar id }
  | e1 = expr PLUS e2 = expr                     { Ebinop (Badd, e1, e2) }
  | e1 = expr MINUS e2 = expr                    { Ebinop (Bmin, e1, e2) }
  | e1 = expr MULTIPLY e2 = expr                 { Ebinop (Bmul, e1, e2) }
  | e1 = expr DIVIDE e2 = expr                   { Ebinop (Bdiv, e1, e2) }
  | LPAREN e = expr RPAREN                       { e }
  | LBRACKET e = separated_list(COMMA, expr) RBRACKET { Elist e }
  ;

ident:
  | id = IDENT { { loc = ($startpos, $endpos); id } }
  ;

stmts:
  | stmt        { [$1] }
  | stmts stmt  { $1 @ [$2] }

stmt:
  | KEYS COLON NEWLINE INDENT keybind_list DEDENT
      { Keybinds $5 }

keybind_list:
  | keybind               { [$1] }
  | keybind_list keybind  { $1 @ [$2] }

%inline key_name:
  | JUMP  { Jump }
  | LEFT  { Left }
  | RIGHT { Right }

keybind:
  | key_name COLON IDENT NEWLINE {
      if is_valid_key $3 then
        ($1, $3)
      else
        failwith ("Invalid key: " ^ $3)
    }
