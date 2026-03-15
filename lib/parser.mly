%{
open Ast
%}

%token CONSTANTS
%token COLON COMMA LBRACKET RBRACKET
%token NEWLINE INDENT DEDENT
%token <string> IDENT
%token <int> INT
%token <string> STRING
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
  constants_block EOF { { constants = $1 } }

constants_block:
  CONSTANTS COLON NEWLINE INDENT const_lines DEDENT { $5 }

const_lines:
  /* empty */ { [] }
| const_line const_lines { $1 :: $2 }

const_line:
  | IDENT COLON INT NEWLINE { { name = $1; value = Cint $3 } }
  | IDENT COLON expr NEWLINE { { name = $1; value = Cexpr $3 } }

expr:
  | INT { Econst (SCint $1) }
  (*| e1 = expr PLUS e2 = expr { Ebinop (Badd, e1, e2) }These two are redundant*)
  (*| e1 = expr MINUS e2 = expr { Ebinop (Bmin, e1, e2) } They are already contained in the generic binop operations*)
  | id = ident                                    /*Variables*/
      { Evar id }
  | e1 = expr op = binop e2 = expr                 /*Binary Operations*/
      { Ebinop (op, e1, e2) }
  | LBRACKET e=seperated_list(COMMA, expr) RBRACKET {Elist} /*Lists*/
  ;
  /*KEYS COMMA NEWLINE JUMP COMMA expr NEWLINE RIGHT COMMA expr NEWLINE LEFT COMMA expr/*
ident:
  | id = IDENT { { loc = ($startpos, $endpos); id } }
;

%inline binop:                                     /*Binds the binary operation to binop*/
  | PLUS { Badd }
  | MINUS { Bmin }
  | MULTIPLY { Bmul }
  | DIVIDE { Bdiv }
