open Notty
open Notty_unix

(* Types *)

type tile = Empty | Wall | Spawn | Goal | Lose
type arena = { width : int; height : int; grid : tile array array }
type editor = { arena : arena; cursor_x : int; cursor_y : int; running : bool }

(* Tile Helpers *)

let char_of_tile = function
  | Empty -> '.'
  | Wall -> '#'
  | Spawn -> 'S'
  | Goal -> 'G'
  | Lose -> 'L'

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

  let help =
    I.string A.empty
      "Arrows: move | 1:Wall 2:Empty 3:Spawn 4:Goal 5:Lose| S:save Q:quit"
  in

  I.vcat [ grid_image; I.void 1 1; help ]

(* Saving *)

let save_arena editor =
  let oc = open_out "arena.txt" in
  Array.iter
    (fun row ->
      Array.iter (fun tile -> output_char oc (char_of_tile tile)) row;
      output_char oc '\n')
    editor.arena.grid;
  close_out oc

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
    | `Key (key, _) ->
        let editor' = handle_input editor key in
        loop term editor'
    | _ -> loop term editor
  end

(* Entry Point *)

let () =
  let term = Term.create () in

  let width = 10 in
  let height = 6 in

  let grid = Array.make_matrix height width Empty in

  let arena = { width; height; grid } in

  let editor = { arena; cursor_x = 0; cursor_y = 0; running = true } in

  loop term editor
