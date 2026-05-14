open OUnit2
open LilScript
open Test_helpers

let assert_raises_or_exits msg thunk =
  (* diagnostics.ml uses exit 1 on failure rather than raising.
     we run the thunk and let it either pass or exit; tests expecting failure
     should be run as integration tests at the pipeline level instead.
     here we only test the pure raise-based path of typecheck. *)
  try
    thunk ();
    assert_failure (msg ^ " (no exception)")
  with Typecheck.Type_error _ -> ()

let test_duplicate_keybind_missing _ =
  (* a player with no jump key should fail typecheck *)
  let src =
    {|
players:
  p1:
    color: 255 0 0
    spawn: 1 1
    keys:
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  assert_raises_or_exits "missing jump key" (fun () -> parse_and_check src)

let test_color_out_of_range _ =
  let src =
    {|
players:
  p1:
    color: 300 0 0
    spawn: 1 1
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  assert_raises_or_exits "color > 255" (fun () -> parse_and_check src)

let test_color_through_constant _ =
  (* a color value that resolves through a constant should also be range-checked *)
  let src =
    {|
constants:
  BAD_RED: 300
players:
  p1:
    color: BAD_RED 0 0
    spawn: 1 1
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  assert_raises_or_exits "color via constant > 255" (fun () ->
      parse_and_check src)

let test_magic_constant_wrong_type _ =
  let src =
    {|
constants:
  GRAVITY: "fast"
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
  assert_raises_or_exits "gravity must be numeric" (fun () ->
      parse_and_check src)

let suite =
  "diagnostics"
  >::: [
         "missing_jump_key" >:: test_duplicate_keybind_missing;
         "color_out_of_range" >:: test_color_out_of_range;
         "color_through_constant" >:: test_color_through_constant;
         "magic_constant_wrong_type" >:: test_magic_constant_wrong_type;
       ]
