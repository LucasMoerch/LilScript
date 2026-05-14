open OUnit2
open LilScript
open Test_helpers

(* parse, typecheck, and generate; return the python string *)
let compile_to_python src =
  let ast = parse_string src in
  Typecheck.check ast;
  Codegen.generate ast

let assert_contains needle haystack =
  let contains s sub =
    let len_s = String.length s and len_sub = String.length sub in
    if len_sub > len_s then false
    else
      let rec loop i =
        if i + len_sub > len_s then false
        else if String.sub s i len_sub = sub then true
        else loop (i + 1)
      in
      loop 0
  in
  if not (contains haystack needle) then
    assert_failure (Printf.sprintf "expected output to contain %S" needle)

let test_emits_pygame_import _ =
  let py = compile_to_python minimal_valid_program in
  assert_contains "import pygame" py

let test_emits_settings_call _ =
  let py = compile_to_python minimal_valid_program in
  assert_contains "settings_module.Settings(" py

let test_block_erase_mode_emitted_as_true _ =
  let src =
    {|
constants:
  BLOCK_ERASE_MODE: true
  ERASE_TIME: 500
players:
  p1:
    color: 0 0 0
    spawn: 1 1
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  let py = compile_to_python src in
  assert_contains "block_erase_mode=True" py;
  assert_contains "erase_time=500" py

let test_constant_arithmetic_evaluated _ =
  let src =
    {|
constants:
  GRAVITY: 1 + 1
players:
  p1:
    color: 0 0 0
    spawn: 1 1
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  let py = compile_to_python src in
  assert_contains "gravity=2" py

let suite =
  "codegen"
  >::: [
         "emits_pygame_import" >:: test_emits_pygame_import;
         "emits_settings_call" >:: test_emits_settings_call;
         "block_erase_mode_true" >:: test_block_erase_mode_emitted_as_true;
         "constant_arithmetic_evaluated" >:: test_constant_arithmetic_evaluated;
       ]
