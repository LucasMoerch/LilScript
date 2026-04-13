{
open Parser
open Lexer_utils
}

let digit  = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z' '_']
let ident  = letter (letter | digit)*
let float  = digit+ '.' digit+

(* reads chars into buf until closing quote *)
rule string_literal buf = parse
  | '"'         { STRING (Buffer.contents buf) }
  | '\\' '"'    { Buffer.add_char buf '"';  string_literal buf lexbuf }
  | '\\' '\\'   { Buffer.add_char buf '\\'; string_literal buf lexbuf }
  | '\\' 'n'    { Buffer.add_char buf '\n'; string_literal buf lexbuf }
  | eof         { raise (Lexing_error ("Unterminated string", Lexing.lexeme_start_p lexbuf)) }
  | _ as c      { Buffer.add_char buf c;    string_literal buf lexbuf }

(* drain the pending queue before calling next_token_inner *)
and next_token = parse
  | "" {
      if Queue.is_empty pending
      then next_token_inner lexbuf
      else Queue.take pending
    }

and next_token_inner = parse
  (* leading whitespace at start of line sets the indent level *)
  | [' ' '\t']+ as ws {
      if !bol && !bracket_depth = 0 then (
        let n = String.fold_left (fun acc c -> acc + if c = '\t' then 4 else 1) 0 ws in
        bol := false;
        emit_indent_tokens n lexbuf;
        if Queue.is_empty pending then next_token lexbuf else Queue.take pending
      ) else
        next_token lexbuf
    }

  | "//" [^ '\n']* { next_token lexbuf }   (* line comment *)

  (* newlines inside brackets are ignored to allow multiline lists *)
  | "\r\n" | '\n' | '\r' {
      bol := true;
      Lexing.new_line lexbuf;
      if !bracket_depth > 0 then next_token lexbuf else NEWLINE
    }

  | ":"  { maybe_bol_token COLON    lexbuf }
  | "+"  { maybe_bol_token PLUS     lexbuf }
  | "-"  { maybe_bol_token MINUS    lexbuf }
  | "*"  { maybe_bol_token MULTIPLY lexbuf }
  | "/"  { maybe_bol_token DIVIDE   lexbuf }
  | "("  { maybe_bol_token LPAREN   lexbuf }
  | ")"  { maybe_bol_token RPAREN   lexbuf }

  (* brackets suppress newline tokens inside them *)
  | "[" {
      if !bol && !bracket_depth = 0 then emit_indent_tokens 0 lexbuf;
      bol := false;
      incr bracket_depth;
      LBRACKET
    }
  | "]" { bol := false; decr bracket_depth; RBRACKET }
  | "," { bol := false; COMMA }

  | '"' {
      if !bol && !bracket_depth = 0 then (
        emit_indent_tokens 0 lexbuf;
        bol := false;
        let tok = string_literal (Buffer.create 16) lexbuf in
        Queue.add tok pending;
        Queue.take pending
      ) else (
        bol := false;
        string_literal (Buffer.create 16) lexbuf
      )
    }

  (* float must come before int so "1.0" does not match digit+ first *)
  | float as f  { maybe_bol_token (FLOAT (float_of_string f)) lexbuf }
  | digit+ as n { maybe_bol_token (INT   (int_of_string  n)) lexbuf }
  | ident  as s { maybe_bol_token (keyword_or_ident s)        lexbuf }

  (* flush remaining DEDENTs before EOF *)
  | eof {
      while Stack.top indent_stack > 0 do
        ignore (Stack.pop indent_stack);
        Queue.add DEDENT pending
      done;
      if Queue.is_empty pending then EOF else Queue.take pending
    }

  | _ {
      raise (Lexing_error
        ("Unexpected character: " ^ Lexing.lexeme lexbuf,
         Lexing.lexeme_start_p lexbuf))
    }

{
}
