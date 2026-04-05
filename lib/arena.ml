open Ast

(* maps raw ints from the source to tile variants, fails on unknown values *)
let tile_of_int = function
  | 0 -> Tempty
  | 1 -> Tsolid
  | 2 -> Twin
  | 3 -> Tlose
  | n -> failwith ("Invalid arena tile: " ^ string_of_int n)

(* takes a list of int lists and builds a validated arena record.
   fails if rows have mismatched widths. *)
let make_arena rows =
  let row_arrays =
    List.map (fun row -> Array.of_list (List.map tile_of_int row)) rows
  in
  let height = List.length row_arrays in
  let width =
    match row_arrays with
    | [] -> 0
    | row :: rest ->
        let w = Array.length row in
        List.iter
          (fun r ->
            if Array.length r <> w then
              failwith "Arena rows must all have the same width")
          rest;
        w
  in
  { width; height; tiles = Array.of_list row_arrays }
