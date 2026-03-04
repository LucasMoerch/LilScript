# P4 / OurLang

OurLang is a small Domain Specfic Language implemented in OCaml (ocamllex + Menhir + Dune).  

## Repo structure

- `lib/` — the OurLang library
  - `ast.ml` — AST types
  - `lexer.mll` — lexer (ocamllex)
  - `parser.mly` — parser (Menhir), builds the AST
- `bin/` — executable(s)
  - `main.ml` — CLI entrypoint (`ourlangc`)
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
The executable is published as ourlangc.
### Run on a file:
```bash
dune exec ourlangc -- path/to/file.gg
```


