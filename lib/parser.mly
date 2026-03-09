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

%left PLUS MINUS
%left MULTIPLY DIVIDE

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
  | c = INT                                       /*Integer Constants*/ 
      { Econst (Cint c) }                        
  | id = ident                                    /*Variables*/
      { Evar id }
  | e1 = expr o = binop e2 = expr                 /*Binary Operations*/
      { Ebinop (o, e1, e2) }
  
    
  ;

stmt:
  | id = ident ASSIGN e = expr                    /* = Operator */
    { Sassign (id, e) }

ident:
  | id = IDENT { { loc = ($startpos, $endpos); id } }
;

%inline binop:                                     /*Binds the binary operation to binop*/                                  
  | PLUS { Badd }
  | MINUS { Bmin }
  | MULTIPLY { Bmul }
  | DIVIDE { Bdiv }
