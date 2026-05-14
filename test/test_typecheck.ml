open OUnit2
open LilScript

(* helper to construct a fake position for AST nodes *)
let dummy_pos : Lexing.position =
  { pos_fname = "<test>"; pos_lnum = 1; pos_bol = 0; pos_cnum = 0 }

let dummy_loc = (dummy_pos, dummy_pos)
let mk_ident name : Ast.ident = { loc = dummy_loc; id = name; pos = dummy_pos }
let empty_env () = Hashtbl.create 4

(* assert a thunk raises Type_error, fail otherwise *)
let assert_raises_type_error msg thunk =
  try
    thunk ();
    assert_failure (msg ^ " (no exception raised)")
  with Typecheck.Type_error _ -> ()

let test_check_int_literal _ =
  let env = empty_env () in
  let t = Typecheck.check_expr env (Ast.Econst (Ast.SCint 5)) in
  assert_equal Typecheck.TInt t

let test_check_float_literal _ =
  let env = empty_env () in
  let t = Typecheck.check_expr env (Ast.Econst (Ast.SCfloat 1.5)) in
  assert_equal Typecheck.TFloat t

let test_check_bool_literal _ =
  let env = empty_env () in
  let t = Typecheck.check_expr env (Ast.Econst (Ast.SCbool true)) in
  assert_equal Typecheck.TBool t

let test_int_plus_int_is_int _ =
  let env = empty_env () in
  let e =
    Ast.Ebinop (Ast.Badd, Ast.Econst (Ast.SCint 1), Ast.Econst (Ast.SCint 2))
  in
  assert_equal Typecheck.TInt (Typecheck.check_expr env e)

let test_int_plus_float_is_float _ =
  let env = empty_env () in
  let e =
    Ast.Ebinop (Ast.Badd, Ast.Econst (Ast.SCint 1), Ast.Econst (Ast.SCfloat 2.0))
  in
  assert_equal Typecheck.TFloat (Typecheck.check_expr env e)

let test_int_plus_bool_raises _ =
  let env = empty_env () in
  let e =
    Ast.Ebinop (Ast.Badd, Ast.Econst (Ast.SCint 1), Ast.Econst (Ast.SCbool true))
  in
  assert_raises_type_error "int + bool should fail" (fun () ->
      ignore (Typecheck.check_expr env e))

let test_unknown_identifier_raises _ =
  let env = empty_env () in
  let e = Ast.Evar (mk_ident "no_such_name") in
  assert_raises_type_error "unknown ident should fail" (fun () ->
      ignore (Typecheck.check_expr env e))

let test_identifier_lookup _ =
  let env = empty_env () in
  Hashtbl.add env "x" Typecheck.TInt;
  let t = Typecheck.check_expr env (Ast.Evar (mk_ident "x")) in
  assert_equal Typecheck.TInt t

let suite =
  "typecheck"
  >::: [
         "check_int_literal" >:: test_check_int_literal;
         "check_float_literal" >:: test_check_float_literal;
         "check_bool_literal" >:: test_check_bool_literal;
         "int_plus_int_is_int" >:: test_int_plus_int_is_int;
         "int_plus_float_is_float" >:: test_int_plus_float_is_float;
         "int_plus_bool_raises" >:: test_int_plus_bool_raises;
         "unknown_identifier_raises" >:: test_unknown_identifier_raises;
         "identifier_lookup" >:: test_identifier_lookup;
       ]
