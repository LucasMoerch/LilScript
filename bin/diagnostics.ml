open LilScript.Ast

(* formats a position as fname:line:col *)
let pos_str pos =
  let line = pos.Lexing.pos_lnum in
  let col = pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1 in
  Printf.sprintf "%s:%d:%d" pos.Lexing.pos_fname line col

(* checks for duplicate constant names, exits on first duplicate *)
let check_duplicates (constants : const_decl list) =
  let seen = Hashtbl.create 16 in
  List.iter
    (fun (c : const_decl) ->
      if Hashtbl.mem seen c.name then (
        Printf.eprintf "%s: Duplicate constant '%s'\n%!" (pos_str c.pos) c.name;
        exit 1)
      else Hashtbl.add seen c.name c)
    constants

(* checks that no two players share the same key for any action *)
let check_key_conflicts (players : player list) =
  let all_bindings =
    List.concat_map
      (fun (p : player) -> List.map (fun kb -> (p.name, kb.key)) p.keybinds)
      players
  in
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (pname, key) ->
      match Hashtbl.find_opt seen key with
      | Some other_player ->
          Printf.eprintf
            "Warning: players '%s' and '%s' share the key '%s' -- this may \
             cause unexpected input\n\
             %!"
            other_player pname key
      | None -> Hashtbl.add seen key pname)
    all_bindings

(* checks that an arena is defined either inline or via arena_file *)
let check_arena_present (prog : program) =
  match (prog.arena, prog.arena_file) with
  | None, None ->
      Printf.eprintf
        "Semantic error: no arena defined -- use 'arena:' or 'arena_file:'\n%!";
      exit 1
  | _ -> ()

(* checks that spawn coordinates are inside the arena bounds.
   called after arena_file is resolved so the dimensions are known *)
let check_spawn_bounds (players : player list) (arena : arena) =
  List.iter
    (fun (p : player) ->
      (* spawn is now an expression -- evaluate literals only, skip constant refs *)
      let eval_opt = function Econst (SCint i) -> Some i | _ -> None in
      let x = eval_opt p.spawn.x in
      let y = eval_opt p.spawn.y in
      (match x with
      | Some xv when xv >= arena.width ->
          Printf.eprintf
            "Semantic error: player '%s' spawn x=%d is outside arena width %d\n\
             %!"
            p.name xv arena.width;
          exit 1
      | _ -> ());
      match y with
      | Some yv when yv >= arena.height ->
          Printf.eprintf
            "Semantic error: player '%s' spawn y=%d is outside arena height %d\n\
             %!"
            p.name yv arena.height;
          exit 1
      | _ -> ())
    players

(* checks that at least one player is defined *)
let check_players_present (players : player list) =
  if players = [] then begin
    Printf.eprintf "Semantic error: no players defined\n%!";
    exit 1
  end

(* run all semantic checks in order *)
let check_all (prog : program) =
  check_arena_present prog;
  check_players_present prog.players;
  check_duplicates prog.constants;
  check_key_conflicts prog.players
