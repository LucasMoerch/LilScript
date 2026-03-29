{
(* Bring the token constructors (CONSTANTS, IDENT, INT, NEWLINE, INDENT, ...) into scope *)
open Parser

(* Custom exception for reporting lexer errors back to main.ml *)
exception Lexing_error of string * Lexing.position

(* A stack of indentation levels (in "columns"). The top is the current indent *)
let indent_stack : int Stack.t = Stack.create ()

(* Queue of "extra" tokens we decided to emit (INDENT/DEDENT/NEWLINE) before returning
   the next real token. This is how we can produce multiple tokens from one match *)
let pending : token Queue.t = Queue.create ()

(* Beginning-of-line (BOL) flag: true iff the next characters we read are at BOL, so spaces/tabs
   should be interpreted as indentation. *)
let bol = ref true

(* Initialize indentation stack with indent level 0 *)
let () = Stack.push 0 indent_stack

let reset () =
  Stack.clear indent_stack;
  Stack.push 0 indent_stack;
  Queue.clear pending;
  bol := true


let lowercase = String.lowercase_ascii

(* Recognize keywords vs identifiers.
   - "constants" becomes the CONSTANTS token.
   - everything else becomes IDENT "<x>". *)
let keyword_or_ident s =
  let lower = lowercase s in
  match lower with
  | "constants" -> CONSTANTS
  | _ -> IDENT lower        (* Normalize to lowercase *)

(* Compare new indentation (n) with current indentation and enqueue INDENT/DEDENT
   - If n > current: we entered a new block -> push and emit INDENT token
   - If n < current: we exited one or more blocks -> pop and emit DEDENT(s) token
   - If n doesn't match any previous indent level: indentation error *)
let emit_indent_tokens n lexbuf =
  let current = Stack.top indent_stack in
  if n > current then (
    Stack.push n indent_stack;
    Queue.add INDENT pending
  ) else if n < current then (
    while n < Stack.top indent_stack do
      ignore (Stack.pop indent_stack);
      Queue.add DEDENT pending
    done;
    if Stack.top indent_stack <> n then
      raise (Lexing_error ("Indentation error", Lexing.lexeme_start_p lexbuf))
  )
}

(* ocamllex regexp definitions go here, outside the OCAML header block *)
let digit = ['0'-'9']
let float_lit= digit+ '.' digit* 	
let letter = ['a'-'z''A'-'Z''_']
let ident = letter (letter|digit)*

rule string_literal buf = parse
  (* If we encounter a closing quote, the string is finished. Return the buffered text. *)
  | '"' {
      STRING (Buffer.contents buf)
    }

  (* Escaped double quote: keep a literal double quote inside the string. *)
  | '\\' '"' {
      Buffer.add_char buf '"';
      string_literal buf lexbuf
    }

  (* Escaped backslash: keep a literal backslash inside the string. *)
  | '\\' '\\' {
      Buffer.add_char buf '\\';
      string_literal buf lexbuf
    }

  (* Escaped newline: store it as an actual newline character. *)
  | '\\' 'n' {
      Buffer.add_char buf '\n';
      string_literal buf lexbuf
    }

  (* EOF before a closing quote means the string is unterminated. *)
  | eof {
      raise (Lexing_error ("Unterminated string", Lexing.lexeme_start_p lexbuf))
    }

  (* Any other character belongs to the string unchanged. *)
  | _ as c {
      Buffer.add_char buf c;
      string_literal buf lexbuf
    }

and next_token = parse
  (* Whitespace (spaces/tabs). Only meaningful at beginning of line (bol = true) *)
  | [' ' '\t']+ as ws {
      if !bol then (
        (* Compute indentation width in columns, here tabs count as 4 spaces *)
        let n =
          ws |> String.to_seq |> Seq.fold_left (fun acc c ->
            acc + (if c = '\t' then 4 else 1)
          ) 0
        in
        (* After consuming indentation, we are no longer at BOL *)
        bol := false;

        (* Possibly enqueue INDENT/DEDENT tokens based on n *)
        emit_indent_tokens n lexbuf;

        (* If we enqueued something, return it first, otherwise continue lexing *)
        if Queue.is_empty pending then next_token lexbuf else Queue.take pending
      ) else
        (* Not at BOL: ignore extra spaces/tabs between tokens *)
        next_token lexbuf
    }

  (* Line comment: skip from // to end of line but not the newline itself *)
  | "//" [^'\n']* { next_token lexbuf }

  (* Newline: mark BOL and return a NEWLINE token *)
  | "\r\n" | '\n' | '\r' {
      bol := true;
      Lexing.new_line lexbuf;
      Queue.add NEWLINE pending;
      Queue.take pending
  }


  (* Single-character tokens *)
  | ":" { bol := false; COLON }
  | "+" { bol := false; PLUS }
  | "-" { bol := false; MINUS }
  | "*" { bol := false; MULTIPLY }
  | "/" { bol := false; DIVIDE }
  | "[" { bol := false; LBRACKET }
  | "]" { bol := false; RBRACKET }
  | "," { bol := false; COMMA }

  (* Keywords *)
  | "arena" { ARENA }
  | "win" { WIN }
  | "lose" { LOSE }
  | "spawn" { SPAWN }
  | "players" { PLAYERS }
  | "keys" { KEYS }
  | "jump" { JUMP }
  | "left" { LEFT }
  | "right" { RIGHT }

  (* Strings *)
  | '"' { string_literal (Buffer.create 16) lexbuf }

  (* Support for parentheses to allow grouped expressions like (2 + 3) *)
  | "(" { bol := false; LPAREN }
  | ")" { bol := false; RPAREN }

  | float_lit as f { bol := false; FLOAT (float_of_string f) }
  (* Integers *)
  | digit+ as n { bol := false; INT (int_of_string n) }

  (* Identifier or keyword *)
  | ident as s { bol := false; keyword_or_ident s }

  (* End of file: emit DEDENT tokens until we return to indentation level 0,
     then return EOF *)
  | eof {
      while Stack.top indent_stack > 0 do
        ignore (Stack.pop indent_stack);
        Queue.add DEDENT pending
      done;
      if Queue.is_empty pending then EOF else Queue.take pending
    }

  (* Anything else is a lexer error *)
  (*line 118 returns the character/string that matched "_", and "^" concatenates strings*)
  | _ {
      let c = Lexing.lexeme lexbuf in
      raise (Lexing_error ("Unexpected character: " ^ c, Lexing.lexeme_start_p lexbuf)) }

{
}
