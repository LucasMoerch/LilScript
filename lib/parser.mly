%{
open Ast
%}

%token CONSTANTS
%token COLON
%token NEWLINE INDENT DEDENT
%token <string> IDENT
%token <int> INT
%token EOF

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
  IDENT COLON INT NEWLINE { { name = $1; value = $3 } }
