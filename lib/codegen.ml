open Ast

(* emit the fixed pygame boilerplate header *)
let emit_header buf =
  Buffer.add_string buf
    {|import pygame
import utils
import settings as settings_module
pygame.init()
|}

(* extract a float from a const_value, falling back to a default string *)
let const_value_to_str v default =
  match v with
  | Cfloat f -> Printf.sprintf "%g" f
  | Cint i -> string_of_int i
  | _ -> default

(* look up a constant by name and convert its value to a string *)
let lookup_const name default consts =
  let lower = String.lowercase_ascii name in
  match
    List.find_opt
      (fun (c : const_decl) -> String.lowercase_ascii c.name = lower)
      consts
  with
  | Some c -> const_value_to_str c.value default
  | None -> default

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
  match e with
  | Econst (SCint i) -> i
  | Evar id -> (
      match List.find_opt (fun (c : const_decl) -> c.name = id.id) consts with
      | Some { value = Cint i; _ } -> i
      | _ -> failwith ("codegen: cannot resolve '" ^ id.id ^ "' to int"))
  | _ -> failwith "codegen: color/spawn must be int expressions"

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
