# LilScript

LilScript is a compiler for a small Domain-Specific Language, written in OCaml (ocamllex + ocamlyacc + Dune). It takes `.lil` files and compiles them into Python source files that run on top of a Pygame runtime, letting you define simple 2D platformer games without writing Python directly.

---

## Repo Structure

```
LilScript/
├── bin/                  # Executables
│   ├── main.ml           # CLI entrypoint (lilscriptc)
│   ├── arena_editor.ml   # Terminal arena editor
│   ├── pretty.ml         # Token/AST pretty-printers
│   ├── diagnostics.ml    # Error reporting with positions
│   ├── eval.ml           # Constant evaluator
│   └── file_io.ml        # File read/write helpers
├── lib/                  # Core compiler library
│   ├── ast.ml            # AST type definitions
│   ├── lexer.mll         # ocamllex lexer rules
│   ├── lexer_utils.ml    # Lexer state (indent stack, pending queue)
│   ├── parser.mly        # ocamlyacc grammar
│   ├── codegen.ml        # Python code emitter
│   ├── arena_reader.ml   # Reads arena editor output into AST
│   ├── ast_printer.ml    # AST debug printer
│   └── keys.ml           # Key name validation
├── pygame/               # Python runtime (hand-written)
│   ├── utils.py
│   ├── settings.py
│   ├── player.py
│   ├── block.py
│   └── level.py
├── example_games/        # Sample .lil files and generated .py output
├── maps/                 # Arena files saved by the arena editor
├── test/
│   └── test_lilscript.ml
├── dune-project
└── lilscript.opam
```

---

## Requirements

- OCaml 4.13.1 or compatible
- Dune 3.x
- Python 3
- opam packages: `notty`, `notty.unix`, `ounit2`
- pip package: `pygame-ce`

Install OCaml dependencies:

```bash
opam install notty notty.unix ounit2
```

Set up a Python virtual environment and install the runtime dependency:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pygame-ce
```

To activate the venv in future sessions:

```bash
source .venv/bin/activate
```

---

## Build

```bash
dune build
```

---

## The Full Workflow

### 1. Design your arena in the terminal editor

Arrows to move the cursor, number keys to place tiles, `S` to save, `Q` to quit.

| Key | Tile |
|-----|------|
| `1` | Wall (solid) |
| `2` | Empty |
| `3` | Spawn marker (treated as empty atm) |
| `4` | Goal (win) |
| `5` | Lose |

Specify the output file and arena dimensions when launching the editor. Width and height are in tiles:

```bash
dune exec -- arena_editor --output maps/level1.txt --width 20 --height 15
```

If you reopen an existing file the saved dimensions are restored automatically and `--width`/`--height` are ignored:

```bash
dune exec -- arena_editor --output maps/level1.txt
```

The saved `.txt` file starts with a `width height` header line:

```
20 15
....................
....................
...###..............
```

### 2. Write a .lil file

```
constants:
  GRAVITY: 1.5
  JUMP_HEIGHT: 14
  SPEED: 4
  TICK_SPEED: 60

players:
  p1:
    color: 255 80 80
    spawn: 3 5
    keys:
      JUMP: "up"
      LEFT: "left"
      RIGHT: "right"
  p2:
    color: 80 255 80
    spawn: 10 5
    keys:
      JUMP: "w"
      LEFT: "a"
      RIGHT: "d"

arena_file: "maps/level1.txt"
```

**Supported constants** (all optional, these are the defaults):

| Name | Default | Effect |
|------|---------|--------|
| `GRAVITY` | `1.5` | Downward acceleration per frame |
| `JUMP_HEIGHT` | `15` | Upward velocity on jump |
| `SPEED` | `5` | Horizontal pixels per frame |
| `TICK_SPEED` | `60` | FPS cap |

**Known limitation:** constant names cannot collide with language keywords. Avoid naming constants `jump`, `left`, `right`, `keys`, `color`, `spawn`, `players`, `arena`, or `constants`.

**Spawn coordinates** are in tile units, not pixels. `spawn: 3 5` places the player at tile column 3, row 5.

### 3. Compile the .lil file to Python

```bash
dune exec -- lilscriptc example_games/mygame.lil
```

This writes `pygame/mygame.py`.

### 4. Run the game

```bash
pygame python3 pygame/mygame.py
```

---

## Compiler Flags

Print the token stream and exit:

```bash
dune exec -- lilscriptc --tokens path/to/file.lil
```

Dump the AST after parsing:

```bash
dune exec -- lilscriptc --ast path/to/file.lil
```

Write the generated Python to a specific path:

```bash
dune exec -- lilscriptc --output path/to/output.py path/to/file.lil
```

---

## Tests

```bash
dune test
```
