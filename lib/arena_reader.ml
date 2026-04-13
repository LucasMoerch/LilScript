open Ast

(* maps the characters the editor writes to tile kinds *)
let tile_of_char path line_num = function
  | '#' -> Tsolid
  | 'G' -> Twin
  | 'L' -> Tlose
  | '.' -> Tempty
  | 'S' -> Tempty (* spawn is a player property, not a tile *)
  | c ->
      Printf.eprintf "%s:%d: Unknown tile character '%c', treating as empty\n%!"
        path line_num c;
      Tempty

let read_arena path =
  let ic = open_in path in
  (* first line is "width height" written by the editor *)
  let first_line = input_line ic in
  let width, height =
    match String.split_on_char ' ' (String.trim first_line) with
    | [ w; h ] -> (int_of_string w, int_of_string h)
    | _ -> failwith ("arena_reader: bad header in " ^ path)
  in
  let rows = ref [] in
  let line_num = ref 1 in
  (try
     while true do
       incr line_num;
       let line = input_line ic in
       if String.length line > 0 then begin
         let row =
           Array.init
             (min (String.length line) width)
             (fun i -> tile_of_char path !line_num line.[i])
         in
         rows := row :: !rows
       end
     done
   with End_of_file -> ());
  close_in ic;
  let row_arrays = List.rev !rows in
  if List.length row_arrays <> height then
    Printf.eprintf "Warning: %s header says %d rows but file has %d\n%!" path
      height (List.length row_arrays);
  { width; height; tiles = Array.of_list row_arrays }
