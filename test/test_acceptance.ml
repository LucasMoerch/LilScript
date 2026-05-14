open OUnit2
open LilScript
open Test_helpers

(* the example file from the report, with arena_file removed
   so the test does not depend on a file on disk *)
let mvp_example =
  {|
constants:
  GRAVITY: 1.2
  JUMP_HEIGHT: 14
  SPEED: 4
  TICK_SPEED: 60
  BLOCK_ERASE_MODE: true
  ERASE_TIME: 3000
players:
  p1:
    color: 255 80 80
    spawn: 2 2
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
  p2:
    color: 80 255 80
    spawn: 3 3
    keys:
      JUMP: "w"
      LEFT: "a"
      RIGHT: "d"
arena: [[1,1,1,1],[0,0,0,0],[1,1,1,1]]
|}

let test_mvp_compiles_end_to_end _ =
  let ast = parse_string mvp_example in
  Typecheck.check ast;
  let py = Codegen.generate ast in
  if String.length py < 100 then
    assert_failure "generated python suspiciously short"

let test_mvp_has_two_players_in_output _ =
  let ast = parse_string mvp_example in
  Typecheck.check ast;
  let py = Codegen.generate ast in
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
  assert_bool "player1 should be emitted" (contains py "player1 =");
  assert_bool "player2 should be emitted" (contains py "player2 =")

let test_program_with_only_one_player _ =
  let src =
    {|
players:
  p1:
    color: 0 0 0
    spawn: 0 0
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
arena: [[1]]
|}
  in
  let ast = parse_string src in
  Typecheck.check ast;
  let _py = Codegen.generate ast in
  ()

let suite =
  "acceptance"
  >::: [
         "mvp_compiles" >:: test_mvp_compiles_end_to_end;
         "mvp_two_players" >:: test_mvp_has_two_players_in_output;
         "single_player" >:: test_program_with_only_one_player;
       ]
