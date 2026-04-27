open Ast

(* the types we track -- numeric covers both int and float for arithmetic *)
type lil_type = TInt | TFloat | TString | TBool

(* raised on any type or semantic error, carries a human readable message *)
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
    (fun (c : const_decl) ->
      match c.value with
      | Cint _ -> Hashtbl.add env c.name TInt
      | Cfloat _ -> Hashtbl.add env c.name TFloat
      | Cstring _ -> Hashtbl.add env c.name TString
      | Cbool _ -> Hashtbl.add env c.name TBool
      | Cexpr _ -> ()
      | Cempty -> ())
    consts;
  env

(* check an expression and return its type.
   raises Type_error on failure *)
let rec check_expr env (e : expr) : lil_type =
  match e with
  | Econst (SCint _) -> TInt
  | Econst (SCfloat _) -> TFloat
  | Econst (SCbool _) ->
      raise (Type_error "boolean cannot be used in arithmetic")
  | Econst (SCstring _) ->
      raise (Type_error "string cannot be used in arithmetic")
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
      | TFloat, _ | _, TFloat -> TFloat
      | TInt, TInt -> TInt
      | _ ->
          raise
            (Type_error
               (Printf.sprintf
                  "arithmetic requires numeric operands, got %s and %s"
                  (string_of_type t1) (string_of_type t2))))
  | Elist _ -> raise (Type_error "list cannot be used in arithmetic")

(* check an expression resolves to int specifically -- used for color and spawn *)
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
   only works for literals and simple arithmetic -- constant refs not yet supported *)
let rec eval_int_expr (e : expr) : int option =
  match e with
  | Econst (SCint i) -> Some i
  | Ebinop (Badd, e1, e2) -> (
      match (eval_int_expr e1, eval_int_expr e2) with
      | Some a, Some b -> Some (a + b)
      | _ -> None)
  | Ebinop (Bmin, e1, e2) -> (
      match (eval_int_expr e1, eval_int_expr e2) with
      | Some a, Some b -> Some (a - b)
      | _ -> None)
  | Ebinop (Bmul, e1, e2) -> (
      match (eval_int_expr e1, eval_int_expr e2) with
      | Some a, Some b -> Some (a * b)
      | _ -> None)
  | Ebinop (Bdiv, e1, e2) -> (
      match (eval_int_expr e1, eval_int_expr e2) with
      | Some a, Some b when b <> 0 -> Some (a / b)
      | _ -> None)
  | _ -> None (* constant refs return None -- we skip range check *)

(* check a color component expression -- must be int, range checked if possible *)
let check_color_component env player_name field (e : expr) =
  check_int_expr env (Printf.sprintf "player '%s' color %s" player_name field) e;
  (* if the value is a literal we can range check it at compile time *)
  match eval_int_expr e with
  | Some v when v < 0 || v > 255 ->
      raise
        (Type_error
           (Printf.sprintf "player '%s' %s color value %d is out of range 0-255"
              player_name field v))
  | _ -> ()

(* check spawn component expression -- must be int *)
let check_spawn_component env player_name axis (e : expr) =
  check_int_expr env (Printf.sprintf "player '%s' spawn %s" player_name axis) e

(* check a single constant and add its resolved type to env.
   prints a warning for empty constants but does not raise *)
let check_const env (c : const_decl) =
  match c.value with
  | Cexpr e ->
      let t = check_expr env e in
      Hashtbl.replace env c.name t
  | Cint _ -> Hashtbl.replace env c.name TInt
  | Cfloat _ -> Hashtbl.replace env c.name TFloat
  | Cstring _ -> Hashtbl.replace env c.name TString
  | Cbool _ -> Hashtbl.replace env c.name TBool
  | Cempty ->
      Printf.eprintf "%s: warning: constant '%s' has no value\n%!"
        (pos_str c.pos) c.name

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

(* top-level type checker -- call after parsing, before codegen.
   raises Type_error on the first problem found *)
let check (prog : program) =
  let env = build_env prog.constants in
  (* check constants in order so expressions can reference earlier ones *)
  List.iter (check_const env) prog.constants;
  (* check each player's color, spawn, and keybinds *)
  List.iter
    (fun (p : player) ->
      (* type check color -- each component must be an int expression *)
      check_color_component env p.name "red" p.color.red;
      check_color_component env p.name "green" p.color.green;
      check_color_component env p.name "blue" p.color.blue;
      (* type check spawn -- each component must be an int expression *)
      check_spawn_component env p.name "x" p.spawn.x;
      check_spawn_component env p.name "y" p.spawn.y;
      check_keybinds p)
    prog.players
