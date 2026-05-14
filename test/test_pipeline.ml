open OUnit2
open LilScript
open Test_helpers

let test_minimal_program_parses _ =
  let _ast = parse_string minimal_valid_program in
  ()

let test_minimal_program_typechecks _ = parse_and_check minimal_valid_program

let test_constant_arithmetic _ =
  let src =
    {|
constants:
  BASE: 10
  DOUBLED: BASE * 2
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
  parse_and_check src

let test_bool_in_arithmetic_fails _ =
  let src =
    {|
constants:
  GRAVITY: 1 + true
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
  try
    parse_and_check src;
    assert_failure "expected Type_error for 1 + true"
  with Typecheck.Type_error _ -> ()

let test_block_erase_mode_boolean _ =
  let src =
    {|
constants:
  BLOCK_ERASE_MODE: true
  ERASE_TIME: 1000
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
  parse_and_check src

let suite =
  "pipeline"
  >::: [
         "minimal_parses" >:: test_minimal_program_parses;
         "minimal_typechecks" >:: test_minimal_program_typechecks;
         "constant_arithmetic" >:: test_constant_arithmetic;
         "bool_in_arithmetic_fails" >:: test_bool_in_arithmetic_fails;
         "block_erase_mode_boolean" >:: test_block_erase_mode_boolean;
       ]
