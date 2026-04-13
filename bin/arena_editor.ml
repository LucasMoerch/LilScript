open Notty
open Notty_unix

(* Types *)
type tile = Empty | Wall | Spawn | Goal | Lose
type arena = { width : int; height : int; grid : tile array array }
type editor = { arena : arena; cursor_x : int; cursor_y : int; running : bool }

(* cli output path and dimensions *)
let output_path = ref "arena.txt"
let width_arg = ref 20
let height_arg = ref 15

let options =
  [
    ("--output", Arg.Set_string output_path, "Path to write arena file");
    ("--width", Arg.Set_int width_arg, "Arena width in tiles (default 20)");
    ("--height", Arg.Set_int height_arg, "Arena height in tiles (default 15)");
  ]

(* Tile Helpers *)
let char_of_tile = function
  | Empty -> '.'
  | Wall -> '#'
  | Spawn -> 'S'
  | Goal -> 'G'
  | Lose -> 'L'

let tile_of_char = function
  | '#' -> Wall
  | 'S' -> Spawn
  | 'G' -> Goal
  | 'L' -> Lose
  | _ -> Empty

let set_tile editor tile =
  let { arena; cursor_x; cursor_y; _ } = editor in
  arena.grid.(cursor_y).(cursor_x) <- tile;
  editor

(* Rendering *)
let draw editor =
  let { arena; cursor_x; cursor_y; _ } = editor in
  let rows =
    Array.mapi
      (fun y row ->
        let cols =
          Array.mapi
            (fun x tile ->
              let ch = char_of_tile tile in
              if x = cursor_x && y = cursor_y then
                I.string A.(st bold ++ fg lightred) (String.make 1 ch)
              else I.string A.empty (String.make 1 ch))
            row
        in
        I.hcat (Array.to_list cols))
      arena.grid
  in
  let grid_image = I.vcat (Array.to_list rows) in
  let info =
    I.string A.empty
      (Printf.sprintf
         "Arena %dx%d | Arrows: move | 1:Wall 2:Empty 3:Spawn 4:Goal 5:Lose | \
          S:save Q:quit"
         arena.width arena.height)
  in
  I.vcat [ grid_image; I.void 1 1; info ]

(* Saving *)
let save_arena editor =
  let dir = Filename.dirname !output_path in
  if dir <> "." && not (Sys.file_exists dir) then Unix.mkdir dir 0o755;
  let oc = open_out !output_path in
  (* header line: width and height so the file is self-describing *)
  Printf.fprintf oc "%d %d\n" editor.arena.width editor.arena.height;
  Array.iter
    (fun row ->
      Array.iter (fun tile -> output_char oc (char_of_tile tile)) row;
      output_char oc '\n')
    editor.arena.grid;
  close_out oc;
  Printf.printf "Saved to %s\n%!" !output_path

(* load an existing arena file if it exists, otherwise start blank *)
let load_or_create path width height =
  if Sys.file_exists path then begin
    let ic = open_in path in
    let first_line = input_line ic in
    let w, h =
      match String.split_on_char ' ' (String.trim first_line) with
      | [ a; b ] -> (int_of_string a, int_of_string b)
      | _ -> failwith ("arena_editor: bad header in " ^ path)
    in
    let grid = Array.make_matrix h w Empty in
    for y = 0 to h - 1 do
      let line = input_line ic in
      String.iteri
        (fun x c -> if x < w then grid.(y).(x) <- tile_of_char c)
        line
    done;
    close_in ic;
    { width = w; height = h; grid }
  end
  else { width; height; grid = Array.make_matrix height width Empty }

(* Input Handling *)
let handle_input editor = function
  | `Arrow `Up -> { editor with cursor_y = max 0 (editor.cursor_y - 1) }
  | `Arrow `Down ->
      {
        editor with
        cursor_y = min (editor.arena.height - 1) (editor.cursor_y + 1);
      }
  | `Arrow `Left -> { editor with cursor_x = max 0 (editor.cursor_x - 1) }
  | `Arrow `Right ->
      {
        editor with
        cursor_x = min (editor.arena.width - 1) (editor.cursor_x + 1);
      }
  | `ASCII '1' -> set_tile editor Wall
  | `ASCII '2' -> set_tile editor Empty
  | `ASCII '3' -> set_tile editor Spawn
  | `ASCII '4' -> set_tile editor Goal
  | `ASCII '5' -> set_tile editor Lose
  | `ASCII 's' | `ASCII 'S' ->
      save_arena editor;
      editor
  | `ASCII 'q' | `ASCII 'Q' -> { editor with running = false }
  | _ -> editor

(* Main Loop *)
let rec loop term editor =
  if editor.running then begin
    Term.image term (draw editor);
    match Term.event term with
    | `Key (key, _) -> loop term (handle_input editor key)
    | _ -> loop term editor
  end

(* Entry Point *)
let () =
  Arg.parse options
    (fun _ -> ())
    "Usage: arena_editor [--output path] [--width n] [--height n]";
  let term = Term.create () in
  let arena = load_or_create !output_path !width_arg !height_arg in
  let editor = { arena; cursor_x = 0; cursor_y = 0; running = true } in
  loop term editor
