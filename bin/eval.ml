open LilScript.Ast

(* evaluates an expr to float, crashes on non-numeric types *)
let rec eval_expr env = function
  | Econst (SCint i) -> float_of_int i
  | Econst (SCfloat f) -> f
  | Econst (SCbool _) -> failwith "Bool in arithmetic"
  | Econst (SCstring _) -> failwith "String in arithmetic"
  | Evar id -> (
      match Hashtbl.find_opt env id.id with
      | Some v -> v
      | None ->
          let pos = id.pos in
          Printf.eprintf "%s:%d:%d: Unknown constant '%s'\n%!"
            pos.Lexing.pos_fname pos.Lexing.pos_lnum
            (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1)
            id.id;
          exit 1)
  | Ebinop (op, e1, e2) -> (
      let v1 = eval_expr env e1 and v2 = eval_expr env e2 in
      match op with
      | Badd -> v1 +. v2
      | Bmin -> v1 -. v2
      | Bmul -> v1 *. v2
      | Bdiv -> v1 /. v2)
  | Elist _ -> failwith "List in arithmetic"

(* adds a numeric constant into the env hashtable *)
let add_to_env env (c : const_decl) =
  match c.value with
  | Cint i -> Hashtbl.add env c.name (float_of_int i)
  | Cfloat f -> Hashtbl.add env c.name f
  | Cexpr e -> Hashtbl.add env c.name (eval_expr env e)
  | _ -> ()

(* prints the evaluated value of a constant, exits on Cempty *)
let print_evaluated env (c : const_decl) =
  match c.value with
  | Cexpr e -> Printf.printf "%s = %g\n%!" c.name (eval_expr env e)
  | Cint i -> Printf.printf "%s = %d\n%!" c.name i
  | Cempty ->
      let pos = c.pos in
      Printf.eprintf "%s:%d:%d: Constant '%s' has no value\n%!"
        pos.Lexing.pos_fname pos.Lexing.pos_lnum
        (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1)
        c.name;
      exit 1
  | _ -> ()
