open Ast

(* the types we track, numeric covers both int and float for arithmetic *)
type lil_type = TInt | TFloat | TString | TBool

(* raised on any type or semantic errore *)
exception Type_error of string

let string_of_type = function
  | TInt -> "int"
  | TFloat -> "float"
  | TString -> "string"
  | TBool -> "bool"

(* format a position for error messages *)
let pos_str (pos : Lexing.position) =
  Printf.sprintf "%s:%d:%d" pos.Lexing.pos_fname pos.Lexing.pos_lnum
    (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1)

(* build a type environment from the constant list *)
let build_env (consts : const_decl list) : (string, lil_type) Hashtbl.t =
  let env = Hashtbl.create 16 in
  List.iter
    (fun (c : const_decl) -> match c.value with Cexpr _ -> () | Cempty -> ())
    consts;
  env

(* check an expression and return its type.
   raises Type_error on failure *)
let rec check_expr env (e : expr) : lil_type =
  match e with
  | Econst (SCint _) -> TInt
  | Econst (SCfloat _) -> TFloat
  | Econst (SCbool _) -> TBool
  | Econst (SCstring _) -> TString
  | Evar id -> (
      match Hashtbl.find_opt env id.id with
      | Some t -> t
      | None ->
          raise
            (Type_error
               (Printf.sprintf "%s: undefined constant '%s'" (pos_str id.pos)
                  id.id)))
  | Ebinop (_, e1, e2) -> (
      let t1 = check_expr env e1 in
      let t2 = check_expr env e2 in
      (* if either side is float the result is float *)
      match (t1, t2) with
      | TFloat, TFloat | TFloat, TInt | TInt, TFloat -> TFloat
      | TInt, TInt -> TInt
      | _ ->
          raise
            (Type_error
               (Printf.sprintf
                  "arithmetic requires numeric operands, got %s and %s"
                  (string_of_type t1) (string_of_type t2))))
  | Elist _ -> raise (Type_error "list cannot be used in arithmetic")

(* check an expression resolves to int specifically, used for color and spawn *)
let check_int_expr env context (e : expr) : unit =
  match check_expr env e with
  | TInt -> ()
  | TFloat ->
      raise
        (Type_error (Printf.sprintf "%s: expected int but got float" context))
  | t ->
      raise
        (Type_error
           (Printf.sprintf "%s: expected int but got %s" context
              (string_of_type t)))

(* evaluate an int expression to its value at compile time for range checks.
   handles literals, simple arithmetic, and resolves constant references *)
let rec eval_int_expr (consts : const_decl list) (e : expr) : int option =
  match e with
  | Econst (SCint i) -> Some i
  | Evar id -> (
      (* resolve constant references so range checks work across indirection *)
      match List.find_opt (fun (c : const_decl) -> c.name = id.id) consts with
      | Some { value = Cexpr inner; _ } -> eval_int_expr consts inner
      | _ -> None)
  | Ebinop (Badd, e1, e2) -> (
      match (eval_int_expr consts e1, eval_int_expr consts e2) with
      | Some a, Some b -> Some (a + b)
      | _ -> None)
  | Ebinop (Bmin, e1, e2) -> (
      match (eval_int_expr consts e1, eval_int_expr consts e2) with
      | Some a, Some b -> Some (a - b)
      | _ -> None)
  | Ebinop (Bmul, e1, e2) -> (
      match (eval_int_expr consts e1, eval_int_expr consts e2) with
      | Some a, Some b -> Some (a * b)
      | _ -> None)
  | Ebinop (Bdiv, e1, e2) -> (
      match (eval_int_expr consts e1, eval_int_expr consts e2) with
      | Some a, Some b when b <> 0 -> Some (a / b)
      | _ -> None)
  | _ -> None (* unresolvable references return None *)

(* check a color component expression *)
let check_color_component consts env player_name field (e : expr) =
  check_int_expr env (Printf.sprintf "player '%s' color %s" player_name field) e;
  (* if the value is a literal we can range check it at compile time *)
  match eval_int_expr consts e with
  | Some v when v < 0 || v > 255 ->
      raise
        (Type_error
           (Printf.sprintf "player '%s' %s color value %d is out of range 0-255"
              player_name field v))
  | _ -> ()

(* check spawn component expression *)
let check_spawn_component env player_name axis (e : expr) =
  check_int_expr env (Printf.sprintf "player '%s' spawn %s" player_name axis) e

(* check a single constant and add its resolved type to env.
   prints a warning for empty constants but does not raise *)
let check_const env (c : const_decl) =
  match c.value with
  | Cexpr e ->
      let t = check_expr env e in
      Hashtbl.replace env c.name t
  | Cempty ->
      Printf.eprintf "%s: warning: constant '%s' has no value\n%!"
        (pos_str c.pos) c.name

(* known magic constant names that the codegen reads, with their expected types.
   these names are not reserved but when present they must have the right type *)
let magic_constant_types =
  [
    ("GRAVITY", [ TInt; TFloat ]);
    ("JUMP_HEIGHT", [ TInt; TFloat ]);
    ("SPEED", [ TInt; TFloat ]);
    ("TIME", [ TInt ]);
    ("TICK_SPEED", [ TInt; TFloat ]);
    ("ERASE_TIME", [ TInt ]);
    ("BLOCK_ERASE_MODE", [ TBool ]);
  ]

(* verify any magic constants present have the expected type *)
let check_magic_constants env =
  List.iter
    (fun (name, allowed) ->
      (* lexer lowercases all identifiers so the env key is the lowercase form *)
      let lower = String.lowercase_ascii name in
      match Hashtbl.find_opt env lower with
      | Some t when not (List.mem t allowed) ->
          let expected =
            String.concat " or " (List.map string_of_type allowed)
          in
          raise
            (Type_error
               (Printf.sprintf "magic constant '%s' must be %s but is %s" name
                  expected (string_of_type t)))
      | _ -> ())
    magic_constant_types

(* check all three required keybinds are present for a player *)
let check_keybinds (p : player) =
  let has action = List.exists (fun kb -> kb.action = action) p.keybinds in
  if not (has Jump) then
    raise
      (Type_error
         (Printf.sprintf "player '%s' is missing a jump keybind" p.name));
  if not (has MoveLeft) then
    raise
      (Type_error
         (Printf.sprintf "player '%s' is missing a left keybind" p.name));
  if not (has MoveRight) then
    raise
      (Type_error
         (Printf.sprintf "player '%s' is missing a right keybind" p.name))

(* top-level type checker *)
let check (prog : program) =
  let env = build_env prog.constants in
  (* check constants in order so expressions can reference earlier ones *)
  List.iter (check_const env) prog.constants;
  (* validate that magic constants have their expected types *)
  check_magic_constants env;
  (* check each player's color, spawn, and keybinds *)
  List.iter
    (fun (p : player) ->
      (* type check color, each component must be an int expression *)
      check_color_component prog.constants env p.name "red" p.color.red;
      check_color_component prog.constants env p.name "green" p.color.green;
      check_color_component prog.constants env p.name "blue" p.color.blue;
      (* type check spawn, each component must be an int expression *)
      check_spawn_component env p.name "x" p.spawn.x;
      check_spawn_component env p.name "y" p.spawn.y;
      check_keybinds p)
    prog.players
