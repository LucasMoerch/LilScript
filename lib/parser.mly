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

expr:
  | INT { Econst (SCint $1) }
  | e1 = expr PLUS e2 = expr { Ebinop (Badd, e1, e2) }
  | e1 = expr MINUS e2 = expr { Ebinop (Bmin, e1, e2) }
  | id = ident                                    /*Variables*/
      { Evar id }
  | e1 = expr o = binop e2 = expr                 /*Binary Operations*/
      { Ebinop (o, e1, e2) }
  ;

ident:
  | id = IDENT { { loc = ($startpos, $endpos); id; pos = $startpos } }
;

%inline binop:                                     /*Binds the binary operation to binop*/
  | PLUS { Badd }
  | MINUS { Bmin }
  | MULTIPLY { Bmul }
  | DIVIDE { Bdiv }
