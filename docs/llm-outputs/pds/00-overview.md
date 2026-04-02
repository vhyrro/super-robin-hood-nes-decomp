# PDS 6502 reverse-engineering series — overview

This directory reconstructs the PDS (Proteus Development System) 6502
assembler and its companion tools, as used to build *Super Robin Hood* for the
NES (Quattro Adventure). The goal is a byte-exact transpiler to ca65, so the
original source can be assembled and run in an emulator without the original
hardware.

## Volumes

| File | Contents |
|---|---|
| `00-overview.md` | This file: inventory, method, key results, reading order |
| `01-language-and-lexer.md` | Physical source format, labels, locals, comments, numbers, operands, grammar |
| `02-expressions.md` | Expression evaluator: precedence, byte operators, ranges, quirks |
| `03-directives.md` | Every pseudo-op/directive with exact semantics and examples |
| `04-macros-and-conditionals.md` | Macro system, `@n`/`@@n`, `IF`/`IFS`/`IFF`, `DO`/`LOOP`/`UNTIL`, `REPEAT` |
| `05-banking-and-object-format.md` | `ORG`/`BANK`/`END`/`SEND`, download framing, bank images, ROM mapping |
| `06-companion-tools.md` | `PP1PACK`, `PP1UNPAK`, `HEX2BIN`, `ARCE`, `.dl*` downloader stubs |
| `07-source-corpus-inventory.md` | Feature inventory and statistics for the released `pds_src/src` tree |
| `08-assembler-internals.md` | Disassembly-level internals: memory map, pass engine, tables, handlers, errors |
| `09-transpiler-spec.md` | Normative PDS→ca65 specification, test vectors, implementation checklist |

Supporting material:

| File | Contents |
|---|---|
| `../ledger/KEYWORDS.md` | Full 1.21 keyword table with pass-1/pass-2 handlers and parameters |
| `../ledger/FINDINGS.md` | Raw findings log, addresses, error strings, open questions |

## Binaries analysed

From `docs/manuals/PDS_executables.zip`:

| File | Size | Role |
|---|---|---|
| `version121_pds6502.exe` | 147547 | **Primary target.** PC PDS 1.21 editor + 6502 assembler, MS-DOS MZ |
| `version121_pdsz80.exe` | 150523 | Z80 sibling (same framework, different code generator) |
| `version126_pdsz80.exe` | 143195 | Older 1.26 Z80 build (used for version comparison) |
| `help.65` | 28160 | Complete 6502 instruction reference (no assembler directives) |
| `help.z80` | 23230 | Z80 instruction reference |
| `arce.com` | 5710 | Archiver |
| `dopds.bat`, `version121_read.me`, `version126_read.me`, `version126_read.8` | — | Setup/version notes |

From `docs/manuals/PDS_source_code.zip`: target-side downloader stubs
(`amstrad.dl*`, `bbc.dl1`, `c64.dl*`, `makec64.dl1`, `spec.dl*`). These are
target assembly, not assembler source; `c64warn.txt` documents the
`>`/`<` byte-order trap.

From `pds_src/src`:

| File | Role |
|---|---|
| `ROBINV7.BC/.BD/.BE/.BF` | Four 16 KB bank images (logical banks 12–15) — the build oracle |
| `PP1PACK.EXE`, `PP1UNPAK` | NES character-set packer/unpacker |
| `HEX2BIN.COM` | Converts PDS `HEX` dumps to `.BIN` |
| `.ROU`, `.PDS`, `.MUS`, `.DAT`, `.CHR` | Released source and data |

## Method

1. **Static analysis of the executable.** The MZ load module starts at file
   offset `0x600`; code segments are `0e60` (assembler) and `122b`
   (expression/symbol helpers). Ghidra shows them as `1e60`/`222b` because it
   adds `0x1000` to the segment. File offset is
   `0x600 + segment*16 + offset`.
2. **Keyword table extraction.** The 26-bucket first-letter table and every
   entry (name, pass-1 handler, pass-2 handler, parameter) were decoded into
   `../ledger/KEYWORDS.md`.
3. **Handler decompilation/disassembly.** Entry, pass loop, line reader,
   macro/IF frames, expression evaluator, operand parsers, data directives,
   `ORG`/`BANK`/`SEND`, and the listing engine were traced.
4. **Corpus cross-check.** Feature counts and byte-level checks against the
   four bank images (`07`, `05`).
5. **Behavioural oracle.** The reference banks and the shipped ROM are used to
   validate bank boundaries, fill bytes, vectors and stable code prefixes.

No claim relies on running the IDE. The original editor hangs under DOSBox
because it takes over INT 8/9 without chaining, so the analysis is headless.

## Key results (the short version)

1. **`>` is the low byte, `<` is the high byte** in PDS 6502 — the opposite of
   ca65 — and a leading byte operator applies to the **entire** following
   expression (`>$065f+...` = low byte of the sum). This is configurable in the
   original option screen but is the default and what the source assumes.
2. **Expressions are precedence-based**, not strict left-to-right:
   `!`/`~` (1), `&` (2), comparisons (3), `+`/`-` (4), `*`/`/` (5),
   left-associative, 16-bit wrapping. `-20/4` = 16379.
3. **Forward-referenced operands are always absolute** (3 bytes), even if the
   symbol later resolves below `$100`. This is a phase-stability rule, not an
   optimisation; a transpiler must reproduce it for byte-exact output.
4. **`UNTIL` exits only on exactly 1**, not on any non-zero value. `IFS`
   compares all `[...]` pairs byte-for-byte, case-sensitively, and empty `[]`
   matches empty.
5. **`BANK n` commits the content assembled since the previous `BANK` as bank
   `n`**, resets the PC, and requires a following `ORG`. Each bank is a 16 KB
   image; unused bytes are `$37`; the original files are `ROBINV7.BC`–`.BF`
   for logical banks 12–15.
6. **`SEND MSDOS` writes the hardware download stream**, not a raw binary:
   `$B3` padding, `$B4` download, `$B5` execute, `$B7` bank select. A fixed
   output filename is recreated for every bank, which is why the original build
   used one file per bank.
7. **The 1.21 keyword set differs from the manual**: no bare `WORD`, `BLOCK`,
   `ASCII`, `PROJECT` or `SUB` (but dotted `.WORD`, `.BLOCK`, `.ASCII`,
   `.ORG`, `.MACRO` and bare `=` exist); `JP` is a `JMP` alias; `SUB` is a user
   macro in `MACROS.PDS:504`.
8. **The original build ran two passes**, reusing the output buffer; pass-2
   data emitted only when `BANK` requested a re-emit. The transpiler can ignore
   the mechanism but must preserve the resulting bytes.
9. **`MAPDATA.DAT` assembles to 16,382 bytes** (15,976 `HEX` + 406
   `DEFB`/`DEFS`), matching `ROBINV7.BC[0:16382]` except 39 palette bytes
   (`$0E`→`$0D` at `$061E`–`$06A2`). Bank 12 is therefore almost byte-exact;
   banks 13/14 still diverge due to later source revisions.

## Reading order for a transpiler author

1. `01` — what a line means and how labels/numbers are tokenised.
2. `02` — expressions, especially byte operators and precedence.
3. `03` — directives you must implement.
4. `04` — macro/conditional/loop expansion.
5. `05` — bank layout and the object format.
6. `09` — the normative implementation spec and test vectors.
7. `08` — only when you need the exact binary behaviour or an error address.

`07` is a checklist of which features the actual game uses; `06` covers the
data tools, which are separate from the assembler.

## Status

Volumes `00`–`09` are written (no volume is missing). Open
items are listed at the end of each volume, principally: the 1.26 6502 keyword
set, the precise `IFF` pass-2 record test, and `PP1PACK`'s encoder heuristic.
`CBM`, `STRING`, `IFS` and `SKIP` are resolved in `03`/`04`/`08`. The open
items do not block a transpiler for the released source; they matter for full
compatibility and for byte-identical asset regeneration.
