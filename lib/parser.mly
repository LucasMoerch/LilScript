%{
open Ast
%}

%token CONSTANTS
%token COLON
%token NEWLINE INDENT DEDENT
%token <string> IDENT
%token <int> INT
%token EOF

//OPERATORS
%token PLUS MINUS MULTIPLY DIVIDE
%token ASSIGN
%start <Ast.program> program
%%

program:
  constants_block EOF { { constants = $1 } }

constants_block:
  CONSTANTS COLON NEWLINE INDENT const_lines DEDENT { $5 }

const_lines:
  /* empty */ { [] }
| const_line const_lines { $1 :: $2 }

const_line:
  IDENT COLON INT NEWLINE { { name = $1; value = Cint $3 } }
expr:
  | id = ident
      { Evar id }
  ;

ident:
  | id = IDENT { { loc = ($startpos, $endpos); id } }
;
stmt: 
  | id = ident ASSIGN e = expr
      { Sassign (id, e) }
  ;
/*Inline binary operators*/
%inline binop:
  | PLUS { Badd }
  | MINUS { Bmin }
  | MULTIPLY { Bmul }
  | DIVIDE { Bdiv }