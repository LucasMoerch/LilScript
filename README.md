# P4 / LilScript

LilScript is a small Domain Specfic Language implemented in OCaml (ocamllex + Menhir + Dune).  

## Repo structure

- `lib/` — the LilScript library
  - `ast.ml` — AST types
  - `lexer.mll` — lexer (ocamllex)
  - `parser.mly` — parser (Menhir), builds the AST
- `bin/` — executable(s)
  - `main.ml` — CLI entrypoint (`lilscriptc`)
- `test/` — tests
- `example_games/` — example `.gg` programs (.gg for now)

## Requirements

- OCaml 4.13.1 (or compatible)
- Dune 3.21.1
- Menhir installed in the same environment as Dune/OCaml

To install menhir with opam:
```bash
opam install menhir
```
## Build
```bash
dune build
```
## Run
The executable is published as lilscriptc.
### Run on a file:
```bash
dune exec lilscriptc -- path/to/file.gg
```


