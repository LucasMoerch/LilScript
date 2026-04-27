%{
open Ast
open Keys
open Arena
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

%token PLUS MINUS MULTIPLY DIVIDE

%left PLUS MINUS
%left MULTIPLY DIVIDE

%token ARENA ARENA_FILE SPAWN PLAYERS COLOR
%token KEYS JUMP LEFT RIGHT
%token ASSETS BACKGROUND SOLID_TILE WIN_TILE LOSE_TILE

%start <Ast.program> program

%%

program:
  separators
  root_constants
  constants_block_opt
  players_block_opt
  arena_block_opt
  arena_file_block_opt
  assets_block_opt
  top_keybinds_opt
  separators
  EOF
    {
      let constants = $2 @ $3 in
      { constants; players = $4; arena = $5; arena_file = $6; assets = $7; stmts = $8 }
    }
;

separators:
  | /* empty */ { () }
  | separator separators { () }
;

separator:
  | NEWLINE { () }
  | DEDENT { () }
;

header_colon:
  | COLON { () }
  | separators COLON { () }
;

root_constants:
  | /* empty */ { [] }
  | root_constant root_constants { $1 :: $2 }
  | separator root_constants { $2 }
;

root_constant:
  | IDENT COLON INT NEWLINE
    { { name = $1; value = Cint $3; pos = $startpos } }
  | IDENT COLON FLOAT NEWLINE
    { { name = $1; value = Cfloat $3; pos = $startpos } }
  | IDENT COLON STRING NEWLINE
    { { name = $1; value = Cstring $3; pos = $startpos } }
  | IDENT COLON expr NEWLINE
    { { name = $1; value = Cexpr $3; pos = $startpos } }
  | IDENT COLON NEWLINE
    { { name = $1; value = Cempty; pos = $startpos } }
;

constants_block_opt:
  | /* empty */ { [] }
  | CONSTANTS header_colon NEWLINE INDENT const_lines DEDENT separators
    { $5 }
;

const_lines:
  | /* empty */ { [] }
  | const_line const_lines { $1 :: $2 }
  | NEWLINE const_lines { $2 }
;

const_line:
  | IDENT COLON INT NEWLINE
    { { name = $1; value = Cint $3; pos = $startpos } }
  | IDENT COLON FLOAT NEWLINE
    { { name = $1; value = Cfloat $3; pos = $startpos } }
  | IDENT COLON STRING NEWLINE
    { { name = $1; value = Cstring $3; pos = $startpos } }
  | IDENT COLON expr NEWLINE
    { { name = $1; value = Cexpr $3; pos = $startpos } }
  | IDENT COLON NEWLINE
    { { name = $1; value = Cempty; pos = $startpos } }
;

players_block_opt:
  | /* empty */ { [] }
  | PLAYERS header_colon NEWLINE INDENT player_lines DEDENT separators
    { $5 }
;

player_lines:
  | /* empty */ { [] }
  | player_decl player_lines { $1 :: $2 }
  | NEWLINE player_lines { $2 }
;

player_decl:
  | IDENT COLON NEWLINE INDENT player_fields DEDENT
    {
      let (color, spawn, keybinds) = $5 in
      { name = $1; color; spawn; keybinds }
    }
;

player_fields:
  | color_field spawn_field keys_field { ($1, $2, $3) }
  | color_field keys_field spawn_field { ($1, $3, $2) }
  | spawn_field color_field keys_field { ($2, $1, $3) }
  | spawn_field keys_field color_field { ($3, $1, $2) }
  | keys_field color_field spawn_field { ($2, $3, $1) }
  | keys_field spawn_field color_field { ($3, $2, $1) }
;

(* int_expr accepts either a literal int or a constant reference *)
int_expr:
  | INT   { Econst (SCint $1) }
  | IDENT { Evar { loc = ($startpos, $endpos); id = $1; pos = $startpos } }
;

color_field:
  | COLOR COLON int_expr int_expr int_expr NEWLINE
    { { red = $3; green = $4; blue = $5 } }
;

spawn_field:
  | SPAWN COLON int_expr int_expr NEWLINE
    { { x = $3; y = $4 } }
;

keys_field:
  | KEYS COLON NEWLINE INDENT keybind_lines DEDENT
    { $5 }
;

keybind_lines:
  | /* empty */ { [] }
  | keybind keybind_lines { $1 :: $2 }
  | NEWLINE keybind_lines { $2 }
;

key_name:
  | JUMP { Jump }
  | LEFT { MoveLeft }
  | RIGHT { MoveRight }
;

key_value:
  | IDENT { $1 }
  | STRING { $1 }
  | LEFT { "left" }
  | RIGHT { "right" }
  | JUMP { "jump" }
;

keybind:
  | key_name COLON key_value NEWLINE
    {
      if is_valid_key $3 then
        { action = $1; key = $3 }
      else
        failwith ("Invalid key: " ^ $3)
    }
;

arena_block_opt:
  | /* empty */ { None }
  | ARENA header_colon arena_literal separators
    { Some (make_arena $3) }
;

arena_literal:
  | LBRACKET arena_rows_opt RBRACKET { $2 }
;

arena_rows_opt:
  | /* empty */ { [] }
  | arena_rows maybe_comma { $1 }
;

arena_rows:
  | arena_row { [$1] }
  | arena_rows COMMA arena_row { $1 @ [$3] }
;

arena_row:
  | LBRACKET int_list_opt RBRACKET { $2 }
;

int_list_opt:
  | /* empty */ { [] }
  | int_list maybe_comma { $1 }
;

int_list:
  | INT { [$1] }
  | int_list COMMA INT { $1 @ [$3] }
;

maybe_comma:
  | /* empty */ { () }
  | COMMA { () }
;

arena_file_block_opt:
  | /* empty */                                      { None }
  | ARENA_FILE header_colon STRING NEWLINE separators { Some $3 }
;

(* assets block: optional, each field overrides one asset path *)
assets_block_opt:
  | /* empty */ { empty_assets }
  | ASSETS header_colon NEWLINE INDENT asset_lines DEDENT separators { $5 }
;

asset_lines:
  | /* empty */
    { empty_assets }
  | BACKGROUND COLON STRING NEWLINE asset_lines
    { { $5 with background = Some $3 } }
  | SOLID_TILE COLON STRING NEWLINE asset_lines
    { { $5 with solid = Some $3 } }
  | WIN_TILE COLON STRING NEWLINE asset_lines
    { { $5 with win = Some $3 } }
  | LOSE_TILE COLON STRING NEWLINE asset_lines
    { { $5 with lose = Some $3 } }
  | IDENT COLON STRING NEWLINE asset_lines
    { { $5 with player_assets = $5.player_assets @ [$3] } }
  | NEWLINE asset_lines { $2 }
;

top_keybinds_opt:
  | /* empty */ { [] }
  | top_keybinds { $1 }
;

top_keybinds:
  | top_keybind_stmt top_keybinds { $1 :: $2 }
  | top_keybind_stmt { [$1] }
;

top_keybind_stmt:
  | KEYS COLON NEWLINE INDENT keybind_lines DEDENT separators
    { Keybinds $5 }
;

expr:
  | INT { Econst (SCint $1) }
  | FLOAT { Econst (SCfloat $1) }
  | ident_tok { Evar $1 }
  | expr PLUS expr { Ebinop (Badd, $1, $3) }
  | expr MINUS expr { Ebinop (Bmin, $1, $3) }
  | expr MULTIPLY expr { Ebinop (Bmul, $1, $3) }
  | expr DIVIDE expr { Ebinop (Bdiv, $1, $3) }
  | LPAREN expr RPAREN { $2 }
  | LBRACKET separated_list(COMMA, expr) RBRACKET { Elist $2 }
;

ident_tok:
  | IDENT { { loc = ($startpos, $endpos); id = $1; pos = $startpos } }
;
