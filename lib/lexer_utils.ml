open Parser

exception Lexing_error of string * Lexing.position

(* shared mutable state for indent tracking *)
let indent_stack : int Stack.t = Stack.create ()
let pending : token Queue.t = Queue.create ()
let bol = ref true
let bracket_depth = ref 0

(* seed the stack with column zero *)
let () = Stack.push 0 indent_stack
let lowercase = String.lowercase_ascii

(* maps a lowercase string to its keyword token, falls back to IDENT *)
let keyword_or_ident s =
  match lowercase s with
  | "constants" -> CONSTANTS
  | "arena" -> ARENA
  | "spawn" -> SPAWN
  | "players" -> PLAYERS
  | "keys" -> KEYS
  | "color" -> COLOR
  | "jump" -> JUMP
  | "left" -> LEFT
  | "right" -> RIGHT
  | "arena_file" -> ARENA_FILE
  | lower -> IDENT lower

(* pushes INDENT or pops DEDENTs based on column n vs the stack top *)
let emit_indent_tokens n lexbuf =
  let current = Stack.top indent_stack in
  if n > current then (
    Stack.push n indent_stack;
    Queue.add INDENT pending)
  else if n < current then (
    while n < Stack.top indent_stack do
      ignore (Stack.pop indent_stack);
      Queue.add DEDENT pending
    done;
    if Stack.top indent_stack <> n then
      raise (Lexing_error ("Indentation error", Lexing.lexeme_start_p lexbuf)))

(* queues any pending DEDENTs, then queues tok, then returns the front of the queue.
   called at the start of a line so structural tokens come out after any dedents. *)
let maybe_bol_token tok lexbuf =
  if !bol && !bracket_depth = 0 then (
    emit_indent_tokens 0 lexbuf;
    bol := false;
    Queue.add tok pending;
    Queue.take pending)
  else (
    bol := false;
    tok)
