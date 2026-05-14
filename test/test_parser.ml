open OUnit2
open LilScript
open Test_helpers

let test_single_constant _ =
  let src = {|
GRAVITY: 1.5
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|} in
  let ast = parse_string src in
  assert_equal 1 (List.length ast.constants);
  let c = List.hd ast.constants in
  assert_equal "gravity" c.name

let test_constants_block _ =
  let src = {|
constants:
  GRAVITY: 1.5
  SPEED: 4
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|} in
  let ast = parse_string src in
  assert_equal 2 (List.length ast.constants)

let test_arithmetic_precedence _ =
  (* 1 + 2 * 3 should parse as 1 + (2 * 3), not (1 + 2) * 3 *)
  let src = {|
X: 1 + 2 * 3
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|} in
  let ast = parse_string src in
  let c = List.hd ast.constants in
  match c.value with
  | Ast.Cexpr (Ast.Ebinop (Ast.Badd, _, Ast.Ebinop (Ast.Bmul, _, _))) -> ()
  | _ -> assert_failure "expected 1 + (2 * 3) shape"

let test_two_players _ =
  let src = {|
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
  p2:
    color: 0 0 0
    spawn: 1 1
    keys:
      JUMP: "w"
      LEFT: "a"
      RIGHT: "d"
arena: [[1]]
|} in
  let ast = parse_string src in
  assert_equal 2 (List.length ast.players)

let test_arena_inline _ =
  let src = {|
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1,0,1],[0,1,0]]
|} in
  let ast = parse_string src in
  match ast.arena with
  | Some a ->
      assert_equal 3 a.width;
      assert_equal 2 a.height
  | None -> assert_failure "expected inline arena"

let test_arena_file_reference _ =
  let src = {|
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena_file: "maps/level1.txt"
|} in
  let ast = parse_string src in
  assert_equal (Some "maps/level1.txt") ast.arena_file

let suite =
  "parser" >::: [
    "single_constant" >:: test_single_constant;
    "constants_block" >:: test_constants_block;
    "arithmetic_precedence" >:: test_arithmetic_precedence;
    "two_players" >:: test_two_players;
    "arena_inline" >:: test_arena_inline;
    "arena_file_reference" >:: test_arena_file_reference;
  ]
