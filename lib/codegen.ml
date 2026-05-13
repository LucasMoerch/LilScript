open Ast

(* emit the fixed pygame boilerplate header *)
let emit_header buf =
  Buffer.add_string buf
    {|import pygame
import utils
import settings as settings_module
pygame.init()
|}

(* tagged value type returned by compile-time evaluation *)
type value = VInt of int | VFloat of float | VBool of bool | VString of string

(* compute the value of an expression at compile time, resolving constant references *)
let rec eval_const (consts : const_decl list) (e : expr) : value option =
  match e with
  | Econst (SCint i) -> Some (VInt i)
  | Econst (SCfloat f) -> Some (VFloat f)
  | Econst (SCbool b) -> Some (VBool b)
  | Econst (SCstring s) -> Some (VString s)
  | Evar id -> (
      match List.find_opt (fun (c : const_decl) -> c.name = id.id) consts with
      | Some { value = Cexpr inner; _ } -> eval_const consts inner
      | _ -> None)
  | Ebinop (op, e1, e2) -> (
      let v1 = eval_const consts e1 in
      let v2 = eval_const consts e2 in
      match (v1, v2) with
      | Some (VInt a), Some (VInt b) -> (
          match op with
          | Badd -> Some (VInt (a + b))
          | Bmin -> Some (VInt (a - b))
          | Bmul -> Some (VInt (a * b))
          | Bdiv when b <> 0 -> Some (VInt (a / b))
          | _ -> None)
      | Some (VFloat a), Some (VFloat b) -> (
          match op with
          | Badd -> Some (VFloat (a +. b))
          | Bmin -> Some (VFloat (a -. b))
          | Bmul -> Some (VFloat (a *. b))
          | Bdiv -> Some (VFloat (a /. b)))
      | Some (VInt a), Some (VFloat b) -> (
          let af = float_of_int a in
          match op with
          | Badd -> Some (VFloat (af +. b))
          | Bmin -> Some (VFloat (af -. b))
          | Bmul -> Some (VFloat (af *. b))
          | Bdiv -> Some (VFloat (af /. b)))
      | Some (VFloat a), Some (VInt b) -> (
          let bf = float_of_int b in
          match op with
          | Badd -> Some (VFloat (a +. bf))
          | Bmin -> Some (VFloat (a -. bf))
          | Bmul -> Some (VFloat (a *. bf))
          | Bdiv -> Some (VFloat (a /. bf)))
      | _ -> None)
  | Elist _ -> None

(* format a value as the python literal that should appear in generated code *)
let value_to_python_str = function
  | VInt i -> string_of_int i
  | VFloat f -> Printf.sprintf "%g" f
  | VBool b -> if b then "True" else "False"
  | VString s -> "\"" ^ s ^ "\""

(* look up a constant by name and convert its value to a string *)
let lookup_const name default consts =
  let lower = String.lowercase_ascii name in
  match
    List.find_opt
      (fun (c : const_decl) -> String.lowercase_ascii c.name = lower)
      consts
  with
  | Some { value = Cexpr e; _ } -> (
      match eval_const consts e with
      | Some v -> value_to_python_str v
      | None -> default)
  | _ -> default

(* convert tile_kind to the integer your Python runtime expects *)
let tile_kind_to_int = function
  | Tsolid -> 1
  | Twin -> 2
  | Tlose -> 3
  | Tempty -> 0

(* format an optional string as a Python string literal or None *)
let opt_path = function Some s -> Printf.sprintf "\"%s\"" s | None -> "None"

(* evaluate a color or spawn expression to an int for codegen.
   by the time we get here typecheck has already verified the type *)
let eval_to_int (consts : const_decl list) (e : expr) : int =
  match eval_const consts e with
  | Some (VInt i) -> i
  | _ -> failwith "codegen: color/spawn must resolve to int"

(* emit the Settings() call from arena + constants + assets *)
let emit_settings buf (arena : arena) (consts : const_decl list)
    (assets : assets) =
  let lk name def = lookup_const name def consts in
  Buffer.add_string buf
    (Printf.sprintf
       {|game_settings = settings_module.Settings(
    jump_height=%s, gravity=%s, speed=%s,
    time=%s, tick_speed=%s,
    tile_size=32, map_width=%d, map_height=%d,
    block_erase_mode=%s, erase_time=%s,
    asset_background=%s, asset_solid=%s, asset_win=%s, asset_lose=%s,
    asset_player1=%s, asset_player2=%s
)
|}
       (lk "JUMP_HEIGHT" "15") (lk "GRAVITY" "1.5") (lk "SPEED" "5")
       (lk "TIME" "60") (lk "TICK_SPEED" "60") arena.width arena.height
       (lk "BLOCK_ERASE_MODE" "False")
       (lk "ERASE_TIME" "0")
       (opt_path assets.background)
       (opt_path assets.solid) (opt_path assets.win) (opt_path assets.lose)
       (opt_path (List.nth_opt assets.player_assets 0))
       (opt_path (List.nth_opt assets.player_assets 1)))

(* flatten the 2D tile array and emit the mapList literal *)
let emit_map buf (tiles : tile_kind array array) =
  let flat = Array.to_list (Array.concat (Array.to_list tiles)) in
  let n = List.length flat in
  Buffer.add_string buf "mapList = [\n    ";
  List.iteri
    (fun i t ->
      Buffer.add_string buf (string_of_int (tile_kind_to_int t));
      if i < n - 1 then
        Buffer.add_string buf (if (i + 1) mod 20 = 0 then ",\n    " else ","))
    flat;
  Buffer.add_string buf "\n]\n"

(* find the key string bound to a given action in a keybind list *)
let find_key action keybinds =
  match List.find_opt (fun kb -> kb.action = action) keybinds with
  | Some kb -> kb.key
  | None -> "none"

(* emit one create_player call per player, passing player number for sprite lookup *)
let emit_players buf (players : player list) (consts : const_decl list) =
  List.iteri
    (fun i p ->
      let jump = find_key Jump p.keybinds in
      let left = find_key MoveLeft p.keybinds in
      let right = find_key MoveRight p.keybinds in
      (* evaluate color and spawn expressions to ints -- typecheck guarantees they are valid *)
      let r = eval_to_int consts p.color.red in
      let g = eval_to_int consts p.color.green in
      let b = eval_to_int consts p.color.blue in
      let sx = eval_to_int consts p.spawn.x in
      let sy = eval_to_int consts p.spawn.y in
      Buffer.add_string buf
        (Printf.sprintf
           "player%d = \
            utils.create_player(\"%s\",\"%s\",\"%s\",[%d,%d],(%d,%d,%d),game_settings,%d)\n"
           (i + 1) jump left right (sx * 32) (sy * 32) r g b (i + 1)))
    players

(* emit the game loop, parameterised on player count *)
let emit_loop buf (players : player list) =
  Buffer.add_string buf
    {|
blockList = utils.create_level(game_settings, mapList)
screen = pygame.display.set_mode((
    game_settings.map_width  * game_settings.tile_size,
    game_settings.map_height * game_settings.tile_size))
background = None
if game_settings.asset_background:
    try:
        background = pygame.image.load(game_settings.asset_background).convert_alpha()
        background = pygame.transform.scale(background, screen.get_size())
    except:
        pass
clock = pygame.time.Clock()
running = True
while running:
    if background:
        screen.blit(background, (0, 0))
    else:
        screen.fill((255,255,255))
    for b in blockList:
        b.draw_block(screen)
        b.update(game_settings)
|};
  List.iteri
    (fun i _ ->
      Buffer.add_string buf
        (Printf.sprintf "    player%d.draw(screen)\n" (i + 1)))
    players;
  Buffer.add_string buf
    {|    pygame.display.flip()
    keys = pygame.key.get_pressed()
|};
  List.iteri
    (fun i _ ->
      Buffer.add_string buf
        (Printf.sprintf "    player%d.handle_input(keys, blockList)\n" (i + 1)))
    players;
  Buffer.add_string buf
    {|    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    clock.tick(game_settings.tick_speed)
pygame.quit()
|}

(* top-level entry: takes a full AST, returns a Python source string *)
let generate (prog : program) : string =
  match prog.arena with
  | None -> failwith "codegen: no arena defined"
  | Some arena ->
      let buf = Buffer.create 1024 in
      emit_header buf;
      emit_settings buf arena prog.constants prog.assets;
      emit_map buf arena.tiles;
      (* pass constants so color and spawn expressions can be evaluated *)
      emit_players buf prog.players prog.constants;
      emit_loop buf prog.players;
      Buffer.contents buf
