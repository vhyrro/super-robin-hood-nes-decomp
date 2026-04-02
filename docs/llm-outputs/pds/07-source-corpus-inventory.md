# 07 — PDS 6502 source corpus inventory (Super Robin Hood)

**Scope.** Every file in `pds_src/src/` (66 real files; `rewrite/` ignored, no Ghidra used).
**Purpose.** Fix the transpiler's required feature set and its conformance tests from the
*actual* corpus, not from the manual's feature list.

Evidence tags used throughout:

* **[O]** observed — reproduced by the scripts in §11 against the files in the repo.
* **[I]** inferred — follows from observation plus the PDS manual, but not directly executed.
* **[M]** documented in `PDS_Manual_6502.txt` (the OCR'd PDS 6502 assembler manual at repo root).

Headline numbers (all **[O]**, PRJ build set only unless stated):

| metric | value |
|---|---|
| files in `pds_src/src/` | 66 total: 34 build sources + 4 unbuilt text sources + 23 binary assets/tools + `ROBIN.PRJ` + 4 bank images |
| files referenced by `ROBIN.PRJ` | 34 |
| text sources not built | 4 (`REDEFCHR.ROU`, `SMILEY.ROU`, `CM_CHARS`, `PP1UNPAK`) |
| binary assets / tooling | 23 |
| source bytes / lines (build set) | 306,741 bytes / 18,942 lines |
| code-bearing lines (build set) | 13,511 |
| distinct opcodes seen | 51 of 56 6502 mnemonics + 33 PDS pseudo-ops |
| macro definitions | 107 (57 never expanded) |
| label definitions | 2,139 (1,617 distinct names; 759 local `!` labels) |
| data bytes emitted by `HEX` lines | 18,748 total (15,976 of them in `MAPDATA`) |
| 6502 instruction lines | 8,364 |

---

## 1. Corpus at a glance

### 1.1 File categories

| category | count | files |
|---|---:|---|
| Assembler config / macro+variable prelude (`.PDS`) | 6 | `MACROS.PDS`, `VARS.PDS`, and the four `BANK*.PDS` |
| Game code `.ROU` (built) | 20 | `CMLOGO`, `HISCORE`, `TITLE`, `SOUNDFX`, `NEWBITS`, `EXPLODE`, `PRTROBIN`, `TIMINGS`, `START`, `MAINLOOP`, `INTERUPT`, `CONTROL`, `XTRACONT`, `XTRAROUS`, `ONSCREEN`, `SPRITESR`, `PRTMESS`, `UNPACK`, `GENERAL`, `MAPSCROL` |
| Bank-boundary `.ROU` | 1 | `ENDCODE.ROU` (plus the four `BANK*.PDS` above) |
| Game code `.ROU` (not built) | 2 | `REDEFCHR.ROU`, `SMILEY.ROU` |
| Music `.MUS` (text) | 3 | `MACROS.MUS`, `JONSBIT.MUS`, `MUSIC1.MUS` |
| Music `.MUS` (binary blob, unused) | 1 | `DATA.MUS` |
| Data `.DAT` | 2 | `MAPDATA.DAT`, `SPRITESD.DAT` |
| Charset source `.CHR` (text) | 1 | `CHRSETS.CHR` |
| Charset data `.CHR` (binary) | 2 | `OKCHR.CHR`, `RIP.CHR` |
| Packed graphics `.PP1` (binary) | 15 | `ARCHCHR`, `BASECHR`, `BEADCHR`, `BEDCHR`, `BOTCHRS`, `BOXCHR`, `CHRSET`, `CMLOGO.PP1`, `DOORCHR`, `HISCORE.PP1`, `OKCHR.PP1`, `ROBINCHR`, `ROCKCHR`, `SOLIDCHR`, `TOPCHRS` |
| Other binary blobs | 3 | `CMLOGO.OLD`, `DATA2`, `DATA3` (`DATA3` is used via `INCBIN`) |
| DOS tools (binary) | 2 | `HEX2BIN.COM`, `PP1PACK.EXE` |
| Text sources with no extension | 3 | `JUNK` (build), `PP1UNPAK` (not built), `CM_CHARS` (not built) |
| Project file | 1 | `ROBIN.PRJ` |
| Assembled bank images (oracle) | 4 | `ROBINV7.BC/.BD/.BE/.BF` |

`DATA3` (4,230 bytes) is not in the PRJ but **is** pulled in by `MUSIC1.MUS:1434
incbin data3` **[O]** — see §7.4. `DATA.MUS`/`DATA2` are unreferenced alternate blobs.

### 1.2 Build set (ROBIN.PRJ), in order

`ROBIN.PRJ` is a PDS *project* file, not source. Its grammar is
`project "…"`, `asmflag 0`, then a list of `FILE <path>`, `COMMENT "…"`,
`CURCOLOUR`, ending with `ASSEMBLER`, `WINDOW 66x19 at 12,29`, `CLOCK ON`, `^Z`.

| # | PRJ line | file | gate at top of file | role |
|---:|---:|---|---|---|
| 1 | 3 | `MACROS.PDS` | — | assembler config equates + 52 macros; `send computer1`, `path c:\nes\robin` |
| 2 | 5 | `VARS.PDS` | — | `zvar`/`var` allocations, NES register equates, final `org &8000` |
| 3 | 7 | `BANK8.PDS` (`FILE *` = force) | — | bank-8 header/commit, overflow guard |
| 4 | 10 | `MAPDATA.DAT` | — | 16,382 bytes of map/charset/palette data |
| 5 | 13 | `BANK12.PDS` | — | bank-12 header/commit |
| 6 | 16 | `MACROS.MUS` | `if musicon=1` (whole file) | 39 music macros + `OPTION 0,0` |
| 7 | 17 | `JONSBIT.MUS` | `if musicon=1`, then the driver body inside `IF gav_master=0` | Jon Menzies driver — **0 bytes in bank 13** at `gav_master=1` (only `status0/status1` `DS 1,0` at `ORG 2`, i.e. `$0002–$0003`, outside the bank) |
| 8 | 18 | `MUSIC1.MUS` | `if musicon=1` (whole file) | live music driver at `$8000` + `incbin data3` |
| 9 | 19 | `HISCORE.ROU` | `if hiscore=1` (whole file, `endif` last line) | high-score sort / entry / display, CBM messages |
| 10 | 22 | `TITLE.ROU` | `if title=1` (closes line 186) | title loop; `pulsecolour` + table after the `endif` |
| 11 | 25 | `SOUNDFX.ROU` | `if musicon=1` (whole file) | SFX engine + 16 byte-emitting FX macros |
| 12 | 28 | `NEWBITS.ROU` | `if showcoins=1` (closes line 43) | coin/secret/treasure logic; rest unconditional |
| 13 | 30 | `EXPLODE.ROU` | — | explosion/heart tables + code |
| 14 | 31 | `PRTROBIN.ROU` | — | Robin sprite frame table (starts with data) + print routine |
| 15 | 34 | `BANK13.PDS` | — | bank-13 header/commit |
| 16 | 37 | `CMLOGO.ROU` | `if absolutely=1` (lines 1499–3235) | Codemasters logo + smiley self-test; 2,350 of 3,238 lines are blank or comment |
| 17 | 40 | `CHRSETS.CHR` | — | 12 × `INCBIN` packed charsets (13,155 B) + 5 × `HEX` |
| 18 | 43 | `BANK14.PDS` | — | bank-14 header/commit, `org &c004`, `jmp pastnops`, `jmp cm_nmi`, `bank.tbl` |
| 19 | 46 | `TIMINGS.ROU` | — | scanline timing tables (DO/LOOP) + buffer code |
| 20 | 49 | `START.ROU` | — (internal `if absolutely=1` ×2) | reset entry, Taiwan lock, RAM clear |
| 21 | 52 | `MAINLOOP.ROU` | — (internal `title/testpause/hiscore/showcoins`) | main game loop |
| 22 | 55 | `INTERUPT.ROU` | — (internal `absolutely/analyzeon/musicon/testpause`) | NMI handler |
| 23 | 58 | `CONTROL.ROU` | — (internal `testpause`) | Robin movement/physics |
| 24 | 61 | `XTRACONT.ROU` | — | per-map "extras" data tables |
| 25 | 64 | `XTRAROUS.ROU` | — (internal `showcoins`) | extras behaviour |
| 26 | 67 | `ONSCREEN.ROU` | — | on-screen block/flame/object code |
| 27 | 70 | `SPRITESD.DAT` | — | sprite pointer table (`sprvar`) + sprite definitions |
| 28 | 73 | `SPRITESR.ROU` | — (internal `allowbehind`) | sprite renderer |
| 29 | 76 | `PRTMESS.ROU` | — | message printer + `m*` format opcodes |
| 30 | 79 | `UNPACK.ROU` | — (internal `absolutely`) | charset unpacker + `compactedchrstable` |
| 31 | 82 | `GENERAL.ROU` | — (internal `testpause` ×2) | keypad reader, misc |
| 32 | 85 | `MAPSCROL.ROU` | — | map scroll/print |
| 33 | 88 | `ENDCODE.ROU` | `if master=0` branch at 27 | bank-15 trailer, free-space accounting, vectors, wipe loop, `END` |
| 34 | 90 | `JUNK` | — | 73 `HEX` lines (1,168 B) of spare tiles |

`FILE *C:\ROBIN\BANK8.PDS` (line 7): the `*` is PDS's "force / no-skip" marker for a
file that a previous assembly left in a stale state **[I]** (the manual documents `SKIP`
and "no skip" but not the `FILE *` form; the marker's exact meaning is inferred).

The `CURCOLOUR RED ON GREEN` / `COMMENT "…"` pairs are editor cosmetics only **[O]**
(they never affect bytes).

---

## 2. Per-file inventory

`emitted` = bytes produced by data pseudo-ops counted *statically* (does not apply `IF`
gating and does include data lines inside macro *definitions*). It is a shape metric, not
a size claim. `!lbl` = `!` local-label definitions.

| # | file | bytes | lines | CRLF | tabs | maxlen | code lines | labels | !lbl | macros | emitted | emits? |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | `MACROS.PDS` | 14,637 | 732 | 0 | 783 | 78 | 562 | 121 | 27 | 52 | 8 | no (equ/macro only) |
| 2 | `VARS.PDS` | 5,440 | 244 | 0 | 417 | 103 | 183 | 31 | 0 | 0 | 0 | no |
| 3 | `BANK8.PDS` | 197 | 19 | **19** | 9 | 36 | 10 | 4 | 0 | 0 | 2 | 2 B header |
| 4 | `MAPDATA.DAT` | 44,162 | 1,338 | 0 | 1,257 | 62 | 1,266 | 37 | 0 | 0 | **16,382** | yes |
| 5 | `BANK12.PDS` | 191 | 17 | 0 | 10 | 36 | 11 | 4 | 0 | 0 | 2 | 2 B header |
| 6 | `MACROS.MUS` | 3,757 | 360 | 0 | 260 | 56 | 248 | 54 | 4 | 39 | 24 | no (gated `musicon`) |
| 7 | `JONSBIT.MUS` | 5,657 | 624 | 0 | 331 | 74 | 344 | 70 | 21 | 1 | 320 | no (`gav_master=1` skips body) |
| 8 | `MUSIC1.MUS` | 18,780 | 1,466 | 0 | 1,121 | 76 | 935 | 126 | 97 | 0 | 4,475 | yes |
| 9 | `HISCORE.ROU` | 9,201 | 507 | 0 | 437 | 91 | 422 | 78 | 22 | 0 | 442 | yes |
| 10 | `TITLE.ROU` | 4,535 | 208 | 0 | 128 | 69 | 184 | 20 | 2 | 0 | 884 | yes |
| 11 | `SOUNDFX.ROU` | 15,231 | 1,289 | 0 | 1,494 | 67 | 826 | 122 | 71 | 15 | 109 | yes |
| 12 | `NEWBITS.ROU` | 10,857 | 632 | 0 | 777 | 100 | 532 | 75 | 15 | 0 | 533 | partly (43 lines gated) |
| 13 | `EXPLODE.ROU` | 4,750 | 283 | 0 | 279 | 63 | 250 | 40 | 8 | 0 | 85 | yes |
| 14 | `PRTROBIN.ROU` | 4,061 | 261 | 0 | 294 | 69 | 233 | 29 | 14 | 0 | 60 | yes |
| 15 | `BANK13.PDS` | 220 | 16 | **16** | 9 | 50 | 11 | 4 | 0 | 0 | 2 | 2 B header |
| 16 | `CMLOGO.ROU` | 38,116 | 3,238 | 0 | 2,113 | 77 | 888 | 145 | 90 | 0 | 1,767 | yes (gated) |
| 17 | `CHRSETS.CHR` | 1,818 | 79 | 0 | 94 | 60 | 17 | 15 | 0 | 0 | **13,160** | yes |
| 18 | `BANK14.PDS` | 299 | 23 | 0 | 13 | 51 | 16 | 7 | 0 | 0 | 18 | 18 B header+tbl |
| 19 | `TIMINGS.ROU` | 1,617 | 111 | 0 | 96 | 43 | 97 | 23 | 3 | 0 | 20 | yes |
| 20 | `START.ROU` | 1,903 | 156 | 0 | 135 | 56 | 86 | 15 | 4 | 0 | 0 | code only |
| 21 | `MAINLOOP.ROU` | 3,597 | 229 | 0 | 170 | **146** | 171 | 24 | 15 | 0 | 0 | code only |
| 22 | `INTERUPT.ROU` | 2,255 | 190 | 0 | 160 | 70 | 161 | 24 | 8 | 0 | 8 | yes |
| 23 | `CONTROL.ROU` | 14,897 | 1,175 | 0 | 1,068 | 40 | 1,048 | 173 | 102 | 0 | 2 | code only |
| 24 | `XTRACONT.ROU` | 19,397 | 783 | 0 | 915 | 91 | 704 | 117 | 27 | 0 | 1,366 | yes |
| 25 | `XTRAROUS.ROU` | 12,093 | 868 | 0 | 799 | 108 | 788 | 107 | 48 | 0 | 9 | code only |
| 26 | `ONSCREEN.ROU` | 20,052 | 1,242 | 0 | 1,151 | 118 | 1,157 | 180 | 56 | 0 | 370 | yes |
| 27 | `SPRITESD.DAT` | 9,760 | 358 | 0 | 246 | 81 | 268 | 112 | 0 | 0 | 1,046 | yes |
| 28 | `SPRITESR.ROU` | 9,713 | 599 | 0 | 569 | 113 | 526 | 95 | 32 | 0 | 11 | yes |
| 29 | `PRTMESS.ROU` | 4,130 | 218 | 0 | 196 | 78 | 181 | 44 | 2 | 0 | 0 | code only |
| 30 | `UNPACK.ROU` | 5,118 | 422 | 0 | 302 | 57 | 280 | 66 | 31 | 0 | 74 | yes |
| 31 | `GENERAL.ROU` | 6,597 | 437 | 0 | 403 | 69 | 375 | 77 | 25 | 0 | 30 | yes |
| 32 | `MAPSCROL.ROU` | 10,437 | 698 | 0 | 627 | 73 | 627 | 90 | 35 | 0 | 133 | yes |
| 33 | `ENDCODE.ROU` | 491 | 47 | 0 | 27 | 47 | 31 | 10 | 0 | 0 | 16,394 | 4 B trailer + 16 KiB wipe |
| 34 | `JUNK` | 2,775 | 73 | 0 | 73 | 37 | 73 | 0 | 0 | 0 | 1,168 | yes |
| — | `REDEFCHR.ROU` | 2,435 | 121 | 0 | 120 | 69 | 82 | 11 | 0 | 0 | 0 | **not built** |
| — | `SMILEY.ROU` | 4,426 | 451 | 0 | 278 | 71 | 278 | 48 | 47 | 0 | 56 | **not built** |
| — | `CM_CHARS` | 201 | 14 | 0 | 10 | 30 | 10 | 2 | 0 | 0 | 1,412 | **not built** |
| — | `PP1UNPAK` | 3,447 | 338 | 0 | 219 | 57 | 210 | 61 | 31 | 0 | 18 | **not built** |

Every text file ends with DOS `^Z` (0x1A) **except** `MACROS.PDS` and `VARS.PDS`
(end 0x0A). Only `BANK8.PDS` (19) and `BANK13.PDS` (16) use CRLF; **all other text
sources are bare-LF** **[O]**.

`CMLOGO.ROU` is 60 % comment by line count (1,935 of 3,238 lines start with `;`) —
a large commented-out lineage of the logo code. `TITLE.ROU`/`HISCORE.ROU` carry the
`CBM` message programs; see §7.5.

---

## 3. Feature-usage matrix

Counts are leading-token occurrences (label stripped), over the 34 PRJ files.
Comments are stripped before counting, and `*` in column 1 is a comment, `*` in an
operand is the program counter.

### 3.1 Pseudo-ops / directives (per file and total)

| file | EQU | = | DEFB | DB | DEFW | DW | DEFS | DS | HEX | INCBIN | ORG | BANK | LIST | FREE | ERROR | MACRO | ENDM | IF | IFS | ELSE | ENDIF | DO | LOOP | UNTIL | REPEAT | EXITM | OPTION | SEND | PATH | END | CBM | DH | DL | DJ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| MACROS.PDS | 18 | 24 | . | 4 | . | . | . | . | . | . | 1 | . | . | . | 24 | 52 | 52 | 27 | 23 | 24 | 50 | 1 | . | 1 | . | . | . | 1 | 1 | . | . | . | . | . |
| VARS.PDS | 31 | . | . | . | . | . | . | . | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK8.PDS | 1 | . | 1 | . | . | . | . | . | . | . | 1 | 1 | 2 | . | 1 | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| MAPDATA.DAT | 13 | . | 101 | . | . | . | 1 | . | 1134 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK12.PDS | 1 | . | 1 | . | . | . | . | . | . | . | 1 | 1 | 2 | 1 | 1 | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| MACROS.MUS | . | 11 | . | 5 | . | 8 | . | 1 | 1 | 6 | . | . | . | . | 1 | 39 | 39 | 12 | 3 | 5 | 15 | . | . | . | 1 | 2 | 1 | . | . | . | . | . | . | . |
| JONSBIT.MUS | 2 | 4 | . | 1 | . | . | . | 3 | 2 | . | 6 | . | . | . | . | 1 | 1 | 3 | . | . | 3 | . | . | . | . | . | 1 | 1 | . | . | . | . | . | 19 |
| MUSIC1.MUS | 7 | 5 | . | 5 | . | 4 | . | . | . | 1 | 3 | 1 | . | 1 | . | . | . | 4 | . | . | 4 | . | . | . | . | . | 1 | . | . | . | . | 16 | 16 | . |
| HISCORE.ROU | 9 | . | 42 | . | 7 | . | 1 | . | 31 | . | . | . | . | . | . | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | 30 | . | . | . |
| TITLE.ROU | . | . | 32 | . | 4 | . | . | . | 41 | . | . | . | . | . | . | . | . | 2 | . | . | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| SOUNDFX.ROU | 27 | 1 | . | 16 | . | 7 | . | . | . | . | . | . | . | . | . | 15 | 15 | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| NEWBITS.ROU | . | . | 117 | . | 8 | . | . | . | . | . | . | . | . | . | . | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | 25 | . | . | . |
| EXPLODE.ROU | . | . | 5 | 4 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| PRTROBIN.ROU | . | . | 38 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK13.PDS | 1 | . | 1 | . | . | . | . | . | . | . | 1 | 1 | 2 | 1 | 1 | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| CMLOGO.ROU | 40 | 2 | 16 | 31 | . | . | . | 2 | 38 | 1 | 3 | . | . | . | 3 | . | . | 6 | . | 1 | 6 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| CHRSETS.CHR | . | . | . | . | . | . | . | . | 2 | 12 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK14.PDS | 1 | . | 2 | . | . | . | . | . | . | . | 1 | 1 | 2 | 1 | 1 | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| TIMINGS.ROU | 1 | 8 | 4 | . | . | . | . | . | 8 | . | . | . | . | . | . | . | . | . | . | . | . | 4 | 4 | . | . | . | . | . | . | . | . | . | . | . |
| START.ROU | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 2 | . | . | 2 | 1 | 1 | . | . | . | . | . | . | . | . | . | . | . |
| MAINLOOP.ROU | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 6 | . | 1 | 6 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| INTERUPT.ROU | . | . | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 5 | . | . | 5 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| CONTROL.ROU | 1 | 3 | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 2 | . | . | 2 | 1 | 1 | . | . | . | . | . | . | . | . | . | . | . |
| XTRACONT.ROU | 25 | . | 196 | . | 5 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| XTRAROUS.ROU | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| ONSCREEN.ROU | 15 | . | 45 | . | 19 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| SPRITESD.DAT | . | . | 142 | . | 21 | . | . | . | 83 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| SPRITESR.ROU | 21 | . | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 3 | . | . | 3 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| PRTMESS.ROU | 14 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| UNPACK.ROU | 15 | . | 14 | . | . | . | . | . | 5 | . | . | . | . | . | . | . | . | 1 | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| GENERAL.ROU | 8 | . | 5 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 2 | . | . | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . |
| MAPSCROL.ROU | 1 | 4 | 23 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 3 | 3 | . | . | . | . | . | . | . | . | . | . | . |
| ENDCODE.ROU | 2 | 2 | 2 | . | 3 | . | 1 | . | . | . | 2 | 3 | 2 | . | 1 | . | . | 2 | . | 1 | 2 | 1 | . | 1 | . | . | . | 1 | . | 1 | . | . | . | . |
| JUNK | . | . | . | . | . | . | . | . | 73 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| **total** | **256** | **64** | **794** | **66** | **67** | **19** | **3** | **6** | **1418** | **20** | **20** | **8** | **10** | **4** | **33** | **107** | **107** | **85** | **26** | **32** | **111** | **11** | **9** | **2** | **1** | **2** | **3** | **3** | **1** | **1** | **55** | **16** | **16** | **19** |

Notes:

* `EQU` (256) vs `=` (64): `=`/`DEFL` is redefinable (`FRED = FRED+1` **[M]**). Every
  `=` redefinition in the corpus is a loop counter or a free-space accumulator
  (`count`, `xx`, `CLN`, `tleft0`, `wipebanks`, `zlim`, `varlim`).
* `DEFB` 794 vs `DB` 66: `DB` is used almost exclusively *inside macro bodies* (a
  single-line data emitter), `DEFB` for source-level tables.
* `HEX` 1,418 lines = 18,748 bytes; `MAPDATA.DAT` alone is 1,134 lines / 15,976 bytes.
  It is the dominant *hand-written literal* form (the rest of the declared data comes
  from 13,160 bytes of `INCBIN` and `DEFB` tables).
* `DH`/`DL` (16 each) appear only in `MUSIC1.MUS` frequency tables; `DJ` (19) is not a
  PDS pseudo-op — it is a **project macro** (`JONSBIT.MUS:53`) that emits `ORG *+(@1)`.
* `CBM` 55 = 30 in `HISCORE.ROU` + 25 in `NEWBITS.ROU` (the only two users).
* `BANK` 8 directives total: one each in `BANK8/12/13/14.PDS`, one in `MUSIC1.MUS`
  (`BANK 0`, inside `gav_master=0`, inactive), and three in `ENDCODE.ROU`
  (`BANK 12,START` in the `master=0` branch, plus `bank 12` and `bank wipebanks` in the
  live branch).

### 3.2 6502 mnemonics (per file and total)

`.` = zero. Totals are instruction *lines*, not bytes.

| file | ADC | AND | ASL | BCC | BCS | BEQ | BIT | BMI | BNE | BPL | BVC | BVS | CLC | CLD | CMP | CPX | CPY | DEC | DEX | DEY | EOR | INC | INX | INY | JMP | JSR | LDA | LDX | LDY | LSR | NOP | ORA | PHA | PHP | PLA | PLP | ROL | ROR | RTI | RTS | SBC | SEC | SEI | STA | STX | STY | TAX | TAY | TXA | TXS | TYA |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| MACROS.PDS | 15 | 2 | 2 | 3 | 1 | 2 | 5 | . | 18 | 4 | 1 | 1 | 11 | . | 7 | 1 | 2 | 4 | 6 | 3 | 1 | 8 | . | 2 | 1 | 3 | 44 | 11 | 9 | . | 16 | 1 | 2 | 1 | 2 | 1 | 1 | . | . | . | 10 | 7 | . | 36 | 3 | 2 | . | . | . | . | . |
| VARS.PDS | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK8.PDS | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| MAPDATA.DAT | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK12.PDS | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| MACROS.MUS | 1 | . | . | 1 | 1 | . | 2 | . | 3 | . | . | . | 1 | . | . | . | . | 1 | 1 | 1 | . | 4 | . | . | . | 8 | 15 | 4 | 4 | . | 2 | 1 | 1 | . | 1 | . | . | . | . | . | 1 | 1 | . | 25 | . | . | 1 | . | 1 | . | . |
| JONSBIT.MUS | 2 | 7 | 1 | 3 | 3 | 10 | . | . | 8 | 4 | . | . | 2 | 1 | 12 | . | . | 3 | 2 | 1 | 7 | 5 | . | 1 | 8 | 30 | 44 | 5 | 6 | 5 | . | 3 | 3 | . | 3 | . | . | . | 1 | 9 | 1 | 1 | 1 | 57 | 1 | . | 2 | 2 | 2 | 1 | 1 |
| MUSIC1.MUS | 17 | 8 | 23 | 20 | 15 | 33 | . | 1 | 34 | . | . | . | 14 | . | 27 | 12 | . | 9 | . | 3 | . | 20 | 5 | 9 | 25 | 16 | 157 | 8 | 28 | 18 | . | 3 | 4 | . | 6 | . | 4 | . | . | 10 | 7 | 8 | . | 125 | . | 1 | . | 9 | 5 | . | . |
| HISCORE.ROU | . | 10 | 6 | 2 | 3 | 14 | 2 | 3 | 20 | 4 | . | . | . | . | 15 | 3 | 4 | 4 | 4 | 5 | . | 3 | 1 | 4 | 14 | 22 | 55 | 8 | 10 | . | . | . | . | . | . | . | . | . | . | 5 | . | . | . | 22 | 1 | 1 | 2 | 1 | 1 | . | 1 |
| TITLE.ROU | . | 6 | . | . | . | 2 | . | . | 4 | 1 | . | . | . | . | . | . | . | 1 | . | . | 2 | 1 | . | . | 4 | 13 | 23 | 4 | 3 | 2 | . | . | . | . | . | . | . | . | . | 2 | . | . | . | 15 | . | . | 1 | . | 1 | . | 1 |
| SOUNDFX.ROU | 7 | 8 | 17 | 6 | 4 | 9 | . | 1 | 9 | 1 | . | . | 5 | . | 12 | 1 | . | 3 | . | . | 4 | 6 | . | 2 | 5 | 8 | 64 | 3 | 11 | 12 | . | 2 | 6 | . | 6 | . | . | . | . | 13 | 7 | 5 | . | 55 | 3 | 2 | 3 | 10 | 8 | . | . |
| NEWBITS.ROU | . | 18 | 5 | 3 | 6 | 4 | . | . | 14 | 2 | . | . | . | . | 8 | 3 | 1 | 5 | 6 | 2 | 1 | . | 2 | 2 | 3 | 17 | 89 | 15 | 10 | 29 | . | . | . | . | . | . | . | . | . | 10 | 6 | 3 | . | 50 | 5 | . | 11 | 8 | 2 | . | 5 |
| EXPLODE.ROU | 4 | 5 | 3 | 4 | 2 | 4 | 1 | 2 | 13 | 2 | 1 | . | . | . | 3 | . | . | 4 | . | 2 | . | 4 | 2 | 4 | 5 | 12 | 48 | 1 | 6 | 5 | . | 1 | . | . | . | . | 1 | . | . | 8 | 13 | 7 | . | 39 | 1 | 3 | 1 | 1 | . | . | . |
| PRTROBIN.ROU | . | 8 | 6 | 1 | . | 12 | 1 | 1 | 5 | 1 | . | . | . | . | 6 | 1 | . | 1 | 2 | . | . | . | . | . | 6 | 12 | 34 | 11 | 7 | 7 | . | . | 1 | . | 1 | . | . | . | . | 4 | 3 | 3 | . | 22 | 6 | 6 | 6 | 1 | 1 | . | . |
| BANK13.PDS | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| CMLOGO.ROU | 11 | 6 | 7 | 12 | 6 | 12 | 2 | 3 | 51 | 6 | 1 | . | 11 | . | 14 | 13 | 3 | 5 | 18 | 17 | 4 | 8 | 27 | 10 | 3 | 15 | 113 | 32 | 30 | 9 | . | 7 | . | . | . | . | 1 | . | . | 11 | 10 | 10 | . | 123 | 31 | 23 | 1 | 2 | 9 | . | 1 |
| CHRSETS.CHR | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| BANK14.PDS | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 2 | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| TIMINGS.ROU | . | . | . | . | . | 2 | . | . | 2 | . | . | . | . | . | . | 1 | . | . | . | . | . | . | . | . | . | . | 20 | 1 | . | . | . | . | . | . | . | . | . | . | . | 5 | 2 | 1 | . | 19 | 1 | . | 2 | 2 | 1 | . | . |
| START.ROU | . | . | . | . | 1 | 1 | 1 | . | 6 | . | . | . | . | 1 | 2 | . | . | 3 | 1 | 1 | . | 1 | . | 1 | 1 | 7 | 11 | 2 | 2 | . | 1 | . | 1 | . | 1 | . | . | . | . | 1 | . | . | 1 | 14 | . | 4 | 1 | . | . | 1 | . |
| MAINLOOP.ROU | . | 6 | . | 1 | 1 | 5 | . | . | 11 | . | . | . | . | . | 6 | . | . | 2 | . | . | . | . | . | . | 5 | 39 | 31 | 3 | 2 | . | . | 1 | . | . | . | . | . | . | . | 1 | . | . | . | 14 | 1 | . | . | . | . | . | . |
| INTERUPT.ROU | . | 3 | . | . | . | 7 | 2 | 2 | 9 | . | . | . | . | . | 2 | . | 3 | 1 | . | . | . | 3 | . | 3 | 3 | 13 | 32 | 2 | 4 | . | . | . | 3 | . | 3 | . | . | . | 2 | 3 | . | . | . | 19 | 3 | 3 | 3 | 1 | 1 | . | 1 |
| CONTROL.ROU | 3 | 35 | 4 | 17 | 7 | 66 | 2 | 7 | 68 | 3 | . | . | . | . | 49 | 5 | 3 | 15 | 3 | 2 | 1 | 15 | 8 | 8 | 30 | 77 | 241 | 30 | 12 | 8 | . | . | 1 | 2 | 1 | 2 | . | 2 | . | 42 | 9 | 6 | . | 127 | 4 | 2 | 4 | 9 | . | . | 2 |
| XTRACONT.ROU | 1 | 9 | 9 | 6 | 6 | 14 | 1 | 1 | 16 | 6 | . | . | . | . | 12 | 4 | 1 | 12 | 2 | 1 | 3 | 6 | 3 | 12 | 8 | 17 | 91 | 25 | 14 | 7 | . | . | 1 | . | 1 | . | . | . | . | 20 | 14 | 11 | . | 58 | 3 | . | 6 | 7 | . | . | 4 |
| XTRAROUS.ROU | 3 | 18 | 8 | 5 | 19 | 20 | 1 | 8 | 36 | 6 | . | . | 1 | . | 31 | 1 | . | 4 | 1 | 1 | 2 | 9 | 1 | 19 | 26 | 69 | 171 | 22 | 36 | 16 | . | . | 3 | 1 | 4 | 1 | 1 | . | . | 11 | 29 | 22 | . | 70 | 1 | 4 | 5 | 10 | 1 | . | 6 |
| ONSCREEN.ROU | 6 | 40 | 7 | 16 | 15 | 27 | 1 | 10 | 62 | 11 | 1 | . | . | . | 31 | 8 | 7 | 1 | 5 | 3 | 8 | 1 | 4 | . | 38 | 63 | 247 | 34 | 40 | 18 | . | . | 1 | 1 | 3 | 1 | . | . | . | 17 | 24 | 18 | . | 130 | 8 | 4 | 9 | 17 | 1 | . | 4 |
| SPRITESD.DAT | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| SPRITESR.ROU | 18 | 5 | 14 | 16 | 12 | 10 | 10 | 7 | 7 | 6 | . | 1 | 17 | . | 1 | 5 | . | 11 | . | . | 4 | 3 | 15 | 16 | 11 | . | 74 | 14 | 8 | 8 | . | 2 | . | . | . | . | . | 2 | . | 7 | 2 | 4 | . | 100 | 15 | 6 | 6 | 2 | 2 | . | 3 |
| PRTMESS.ROU | 1 | 2 | . | 3 | 1 | 8 | . | . | 8 | . | . | . | 1 | . | 9 | . | 1 | 1 | 2 | . | . | 1 | 4 | 16 | 7 | 2 | 23 | 2 | 4 | . | . | . | 5 | . | 5 | . | . | . | . | 3 | 1 | 1 | . | 21 | 6 | 3 | 4 | 2 | . | . | 2 |
| UNPACK.ROU | 1 | 2 | 15 | 13 | 5 | 9 | . | . | 9 | 3 | . | . | . | . | 1 | . | . | 1 | 3 | . | . | 3 | . | 4 | 7 | 19 | 34 | 5 | 1 | 5 | . | 1 | 3 | . | 3 | . | 12 | . | . | 12 | . | . | . | 26 | 3 | 2 | 4 | 1 | 3 | . | . |
| GENERAL.ROU | 1 | 7 | . | 3 | . | 12 | 1 | 2 | 16 | 3 | . | . | 1 | . | 7 | . | 2 | 1 | 1 | 4 | 5 | 2 | 4 | 2 | 5 | 12 | 73 | 9 | 10 | 11 | . | . | 5 | . | 5 | . | 3 | 2 | . | 21 | 1 | 1 | . | 71 | 4 | 4 | 3 | 3 | 3 | . | 2 |
| MAPSCROL.ROU | 8 | 8 | 12 | 9 | 10 | 12 | 2 | 2 | 20 | 5 | . | . | . | . | 28 | 6 | 1 | 2 | 1 | 3 | . | 2 | 12 | 5 | 11 | 20 | 98 | 27 | 11 | 31 | . | 1 | 1 | . | 2 | . | 11 | 12 | . | 16 | 7 | 6 | . | 80 | 12 | 5 | 6 | 10 | 5 | . | 4 |
| ENDCODE.ROU | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | 1 | . | . | . | . | . | . | . | . | . | . | . | . |
| JUNK | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . |
| **total** | **99** | **213** | **139** | **144** | **118** | **295** | **34** | **50** | **449** | **68** | **4** | **2** | **64** | **2** | **283** | **64** | **28** | **94** | **58** | **49** | **42** | **105** | **88** | **120** | **228** | **494** | **1832** | **278** | **268** | **191** | **19** | **23** | **41** | **5** | **47** | **5** | **34** | **18** | **4** | **231** | **147** | **115** | **2** | **1318** | **112** | **75** | **81** | **98** | **47** | **2** | **37** |

### 3.3 Zero-use features (must still be *recognised* if the transpiler translates PDS source generally)

**6502 mnemonics never used (5):** `BRK`, `CLI`, `CLV`, `SED`, `TSX` **[O]**.
`TXS` is used (2), `SEI` (2), `CLD` (2), `RTI` (4).

**Pseudo-ops never used (14):** `RADIX`, `SKIP`, `ASK`, `QUERY`, `INCLUDE`, `IFF`, `DC`,
`STRING`, `BYTE`, `WORD`, `BLOCK`, `DFB`, `DFW`, `DFS` **[O]**.
`ASK` appears once, commented out: `JONSBIT.MUS:4` `;gav_MASTER ASK "Master version`.

**Zero-use forms:**

* `.BYTE` spelling of `DEFB` — 0 uses (only `DEFB`/`DB`) **[O]**.
* `INCLUDE` — 0 uses; `INCBIN` (binary include) is used 21 times instead.
* `RADIX`, `SKIP` — 0 uses (the manual's own examples use them).
* `(zp,X)` addressing — 0 uses **[O]** (`LDA (addr,X)` never appears).
* `[lo,hi]` range check — 1 use (`MACROS.MUS:293`).
* `@@` evaluated-parameter — 1 use (`MACROS.MUS:326`).
* `!0` — 1 use in the build set (`CMLOGO.ROU:2732`), 2 in the corpus (`SMILEY.ROU:315`).
* `OPTION` — 3 (`OPTION 0,0` ×2, `option 0,1` ×1).
* `DH`/`DL` — 16 + 16, one file.
* `LIST` — 10 lines, 5 files, always `LIST ON`/`LIST OFF` around a header `DEFB`.
* `FREE` — 4 (3 × `free b1x`, 1 × `FREE ASDA`).
* `END` — 1 (`ENDCODE.ROU:43`, bare `END`, no execution address).

### 3.4 Addressing modes actually used

| form | instruction lines | example |
|---|---:|---|
| absolute / zeropage (bare expression) | 4,238 | `SPRITESD.DAT`… `bit _statusreg` |
| immediate `#expr` | 1,421 | `lda #%00100000` |
| `abs,X` / `zp,X` | 702 | `lda times16hi,y` → `,x` forms, e.g. `sta bank.tbl+12` |
| `abs,Y` / `zp,Y` | 448 | `lda times16lo,y` |
| `(zp),Y` | 133 | `lda (address),y` |
| `(abs)` indirect (JMP only) | 4 | `EXPLODE.ROU:53 jmp (address)` |
| accumulator `A` | 4 | `GENERAL.ROU:20 lsr a` |
| `(zp,X)` | **0** | — |

`(abs)` appears only with `JMP` (jump-table dispatch): `EXPLODE.ROU:53`, `XTRACONT.ROU:25`,
`ONSCREEN.ROU:34`, `ONSCREEN.ROU:111`.

---

## 4. Labels, locals and macros

### 4.1 Counts

| metric | value | notes |
|---|---:|---|
| label definitions | 2,139 | every leading token in column 1 |
| distinct label names | 1,617 | 759 of the definitions are `!` locals, so most repetition is local reuse |
| local (`!`) definitions | 759 | 281 distinct `!names` |
| most-reused local | `!1` (185), `!2` (104), `!3` (63), `!4` (32), `!5` (20) | classic numeric locals |
| non-numeric locals | `!SKIP`, `!SKIP_ADSR`, `!TRIANGLE`, `!SMILEY_NAME`, `!SMILEY_BANK`, `!TST_BYTE`, `!BANK`, `!HL`, `!FGH`, `!T3.0`…`!T3.3` | letters, underscores and dots are legal |
| dotted (non-local) labels | 8 direct + 13 generated | `bank.tbl`, `move.b`, `move.w`, `move.val`, `!T3.x`; plus `compchr`-generated names such as `basechr0.157` |
| labels ≥ 22 chars | 8 | longest `nowcollidebarrelwithrobin` (25) |
| duplicates that are *not* redefinitions | 0 | all repeated non-local names are `=`/macro-loop counters |

**Critical detail:** a dot is a **label character**, not a scoping operator
(`bank.tbl`, `!T3.3`, `titletopchrs0.245`). `move.w`/`move.b`/`move.val` are macro
*names*. The `compchr` macro defines labels whose *text* is the char-range descriptor,
and the label's *value* is the table index:

```
UNPACK.ROU:21  compchr basechr0.157      ; defines label basechr0.157 = 5
MAPDATA.DAT:170 defb basechr0.157,rockchr157.99   ; emits 05 09   [O, verified in .BD]
```

Local-label scoping follows the manual **[M]**: a normal label clears all `!` definitions;
macro bodies scope their own locals; `LOOP` clears them too. This is why `!1` can be
defined 185 times.

### 4.2 Macro census

107 definitions, 1,075 call lines (including calls written inside other macro bodies),
57 never expanded. Max static nesting depth = **2**; max depth actually exercised in the
build = **2** (`VRAM`→`HIGH`/`LOW` in `JONSBIT.MUS`, `TESTCRASH`→`BLACKANDWHITE`/`COLOUR`).
The manual permits 4 **[M]**.

| macro | defined | expansions | files |
|---|---|---:|---|
| ZVAR | MACROS.PDS:24 | 98 | VARS.PDS:70, SOUNDFX.ROU:9, CMLOGO.ROU:9, MUSIC1.MUS:6, SPRITESR.ROU:3, INTERUPT.ROU:1 |
| VAR | MACROS.PDS:34 | 212 | MUSIC1.MUS:111, VARS.PDS:81, SOUNDFX.ROU:18, XTRACONT.ROU:2 |
| DEFSPR | MACROS.PDS:45 | 0 | — |
| SPRVAR | MACROS.PDS:61 | 18 | SPRITESD.DAT:18 |
| CHRVAR | MACROS.PDS:65 | 0 | — |
| COMPCHR | MACROS.PDS:69 | 14 | UNPACK.ROU:14 |
| WAITFORSPRCOL | MACROS.PDS:73 | 1 | TITLE.ROU:1 |
| WAITFOREDGE | MACROS.PDS:80 | 0 | — |
| WAITFORNINESPRS | MACROS.PDS:86 | 0 | — |
| FLYBACK | MACROS.PDS:95 | 0 | — |
| BLACKSCREEN | MACROS.PDS:100 | 0 | — |
| ORGFULLPAGE | MACROS.PDS:108 | 0 | — |
| FLYBACKVAR | MACROS.PDS:113 | 12 | GENERAL.ROU:3, MAINLOOP.ROU:2, PRTMESS.ROU:2, HISCORE/TITLE/INTERUPT/CONTROL/MAPSCROL:1 each |
| ADDTO16 | MACROS.PDS:119 | 0 | — |
| DECA | MACROS.PDS:128 | 0 | — |
| INCA | MACROS.PDS:133 | 1 | ONSCREEN.ROU:1 |
| NEGA | MACROS.PDS:138 | 6 | ONSCREEN.ROU:3, EXPLODE/INTERUPT/GENERAL:1 |
| BLACKANDWHITE | MACROS.PDS:144 | 1 | inside TESTCRASH |
| COLOUR | MACROS.PDS:156 | 1 | inside TESTCRASH |
| TESTCRASH | MACROS.PDS:162 | 2 | XTRACONT.ROU:1, MAPSCROL.ROU:1 |
| CHANGEBANK | MACROS.PDS:169 | 38 | MAINLOOP:12, XTRAROUS:8, START:7, CONTROL:6, ONSCREEN:5 |
| INCR | MACROS.PDS:183 | 4 | CONTROL:2, XTRAROUS:1, MAPSCROL:1 |
| DECR | MACROS.PDS:194 | 6 | MACROS.PDS:2, CONTROL:2, XTRAROUS:1, MAPSCROL:1 |
| DCA | MACROS.PDS:208 | 4 | ONSCREEN:2, CONTROL:1, XTRAROUS:1 |
| ICA | MACROS.PDS:213 | 0 | — |
| ADD16TO16 | MACROS.PDS:218 | 1 | EXPLODE.ROU:1 |
| SUB16FROM16 | MACROS.PDS:232 | 0 | — |
| SUB16FROMVAL | MACROS.PDS:246 | 0 | — |
| ADD16TO8 | MACROS.PDS:260 | 0 | — |
| SUB8FROM16 | MACROS.PDS:275 | 0 | — |
| ADD16TOVAL | MACROS.PDS:289 | 7 | HISCORE:4, CONTROL:2, MAPSCROL:1 |
| SLDIR | MACROS.PDS:325 | 0 | — |
| SLDIRIND | MACROS.PDS:352 | 0 | — |
| SLDDR | MACROS.PDS:371 | 0 | — |
| SLDDRIND | MACROS.PDS:397 | 1 | HISCORE.ROU:1 |
| SLDDRDIR | MACROS.PDS:417 | 0 | — |
| LDIR | MACROS.PDS:437 | 0 | — |
| LDIRIND | MACROS.PDS:466 | 1 | inside LDIR |
| **ADD** | MACROS.PDS:492 | **223** | ONSCREEN:64, MAPSCROL:28, CONTROL:26, XTRACONT:21, XTRAROUS:21, NEWBITS:13, SPRITESR:12, GENERAL:12, EXPLODE:10, PRTROBIN:9, HISCORE:5, TITLE:1, TIMINGS:1 |
| **SUB** | MACROS.PDS:504 | 2 | HISCORE:1 (`sub hipos`), START:1 (`sub #dif`) |
| MOVE.W | MACROS.PDS:516 | 6 | HISCORE:2, CONTROL:2, ONSCREEN:1, MAPSCROL:1 |
| MOVE.B | MACROS.PDS:527 | 1 | CONTROL:1 |
| MOVE.VAL | MACROS.PDS:536 | 4 | HISCORE:3, CONTROL:1 |
| CPHLDE | MACROS.PDS:543 | 1 | MAPSCROL:1 |
| CPWORDVALUE | MACROS.PDS:553 | 0 | — |
| CPXYVALUE | MACROS.PDS:563 | 0 | — |
| LDXY | MACROS.PDS:572 | 12 | HISCORE:7, CONTROL:3, TITLE:2 |
| STXY | MACROS.PDS:577 | 0 | — |
| MULTWORD | MACROS.PDS:582 | 0 | — |
| TSTATEPAUSE | MACROS.PDS:597 | 0 | — |
| BGPZ | MACROS.PDS:698 | 0 | — |
| BNGPZ | MACROS.PDS:703 | 0 | — |
| NEXUS_RAM | MACROS.MUS:27 | 2 | JONSBIT:2 |
| NEXUS_ROM | MACROS.MUS:32 | 2 | JONSBIT:2 |
| DV | MACROS.MUS:37 | 0 | — |
| SOAPY_BITS | MACROS.MUS:46 | 0 | — |
| DELAY | MACROS.MUS:53 | 0 | — |
| ACCESS_ON | MACROS.MUS:62 | 0 | — |
| ACCESS_OFF | MACROS.MUS:67 | 0 | — |
| BWON | MACROS.MUS:72 | 1 | JONSBIT:1 |
| BWOFF | MACROS.MUS:78 | 1 | JONSBIT:1 |
| VECT | MACROS.MUS:83 | 0 | — |
| GFX | MACROS.MUS:90 | 0 | — |
| GFX_VBL | MACROS.MUS:102 | 0 | — |
| UNPACK | MACROS.MUS:115 | 0 | — |
| LOW | MACROS.MUS:125 | 7 | MACROS.MUS:6, JONSBIT:1 |
| HIGH | MACROS.MUS:129 | 7 | MACROS.MUS:6, JONSBIT:1 |
| LOWX | MACROS.MUS:133 | 0 | — |
| HIGHX | MACROS.MUS:137 | 0 | — |
| LOWY | MACROS.MUS:141 | 0 | — |
| HIGHY | MACROS.MUS:145 | 0 | — |
| VRAM | MACROS.MUS:149 | 2 | JONSBIT:2 |
| PIC | MACROS.MUS:156 | 0 | — |
| UDG | MACROS.MUS:161 | 0 | — |
| GRAPHIC | MACROS.MUS:166 | 0 | — |
| CHAR | MACROS.MUS:171 | 0 | — |
| GRAFIX | MACROS.MUS:176 | 0 | — |
| CHARS | MACROS.MUS:180 | 0 | — |
| LOAD | MACROS.MUS:184 | 0 | — |
| FADE | MACROS.MUS:191 | 0 | — |
| FADE2 | MACROS.MUS:200 | 0 | — |
| WRITE | MACROS.MUS:206 | 0 | — |
| SETBANK | MACROS.MUS:227 | 2 | JONSBIT:2 |
| INN | MACROS.MUS:252 | 0 | — |
| G | MACROS.MUS:259 | 0 | — |
| GAV_ADD | MACROS.MUS:265 | 0 | — |
| GAV_SUB | MACROS.MUS:275 | 0 | — |
| MOVE | MACROS.MUS:285 | 0 | — |
| CLOCKS | MACROS.MUS:292 | 1 | inside TIMEY |
| TICKS | MACROS.MUS:325 | 1 | inside TIMEY |
| TIMEY | MACROS.MUS:330 | 0 | — |
| DJ | JONSBIT.MUS:53 | 19 | JONSBIT:19 |
| PRIORITY | SOUNDFX.ROU:133 | 39 | SOUNDFX |
| CHANNEL | SOUNDFX.ROU:137 | 39 | SOUNDFX |
| ATK_DEC | SOUNDFX.ROU:141 | 39 | SOUNDFX |
| FX_PULSE | SOUNDFX.ROU:145 | 39 | SOUNDFX |
| MIN_MAX_VOL | SOUNDFX.ROU:149 | 39 | SOUNDFX |
| MIN_VOL | SOUNDFX.ROU:153 | 0 | — |
| START_NOTE | SOUNDFX.ROU:158 | 39 | SOUNDFX |
| FX_RISE | SOUNDFX.ROU:162 | 0 | — |
| FX_FALL | SOUNDFX.ROU:166 | 6 | SOUNDFX |
| FX_UP | SOUNDFX.ROU:170 | 12 | SOUNDFX |
| FX_DOWN | SOUNDFX.ROU:174 | 11 | SOUNDFX |
| FX_NOTE | SOUNDFX.ROU:178 | 18 | SOUNDFX |
| FX_WAIT | SOUNDFX.ROU:182 | 26 | SOUNDFX |
| FX_TRIGGER | SOUNDFX.ROU:186 | 7 | SOUNDFX |
| FX_STOP | SOUNDFX.ROU:190 | 39 | SOUNDFX |

### 4.3 Macro features exercised

| feature | uses | where |
|---|---:|---|
| `@1`…`@9` textual parameters | 236 operand lines | everywhere |
| `@@n` evaluated parameter | 1 | `MACROS.MUS:326 JSR TICKS@@1` |
| `IFS [@n][]` (parameter is empty) | 24 | MACROS.PDS/MUS, the main "optional argument" idiom |
| `IFS [@n][X]` / `[A]` (compare literal) | 2 | `MACROS.MUS:228,237` |
| `EXITM` | 2 | `MACROS.MUS:214,233` |
| `[]` used to group comma-bearing arguments | **0** | never needed |
| macro-local `!` labels | 30 definitions + 35 references, all inside macro bodies | `!1`…`!4`, `!HL`, `!FGH` |
| macro recursion | 0 | not supported anyway |

`IFS` total 26 = 24 empty-tests + 2 literal compares. The `[]` syntax exists **only** as
the IFS string delimiter in this corpus — no `MACRO [a,b],c` call exists **[O]**.

---

## 5. Numeric and expression forms

Counts are *operand lines containing* the form (one line can match several).

| form | lines | representative exact line (file:line) |
|---|---:|---|
| decimal literal | 4,939 | `MACROS.PDS:10  absolutely	equ 1` |
| `+` | 861 | `MACROS.PDS:125  inc @1+1` |
| hex `$` | 521 | `MACROS.PDS:5  CHECKPDS	EQU $FFF2` |
| hex `&` | 391 | `VARS.PDS:6  cm_gamebyte	equ &7fd` |
| binary `%` | 290 | `MACROS.PDS:88  lda #%00100000` |
| `-` | 261 | `MACROS.PDS:381  !1	lda	@1-UUU-1,x` |
| unary minus on a literal | 222 | `EXPLODE.ROU:2  add #-18` ; `PRTROBIN.ROU:62  cmp #-4` |
| `*` multiply | 211 | `VARS.PDS:155  var attributes	,7*8*2` |
| parentheses | 177 | `MACROS.PDS:109  !1	org (!1/256)*256+256` |
| byte op *inside* expression (`#<`, `#>` after `,`/`(`) | 157 | `MACROS.PDS:248  lda #>@2` |
| `=` comparison | 54 | `MACROS.PDS:170  if @1=12` |
| `/` divide (floor) | 52 | `MACROS.PDS:62  @1	equ (*-spritetable)/2` |
| quoted string | 45 | `HISCORE.ROU:394  cbm mdownline,"START"` |
| byte op at **start** of expression | 43 | `BANK12.PDS:6  BANK12 DEFB <B12,>B12` |
| PC `*` | 37 | `MAPDATA.DAT:169  dungeonschrs equ * - mapchrsdefs` |
| `[` bracket | 27 | `MACROS.PDS:48  ifs [@5] []` |
| `>` comparison | 25 | `MACROS.PDS:331  if	uuu >255` |
| `&` logical AND | 3 | `MACROS.PDS:46  if (@1&32)` ; `MACROS.MUS:311  IF CLN&1` |
| PC-relative `*-N` | 2 | `MAPDATA.DAT:220  showlivescolours equ *-8` |
| `!` logical OR | 2 | `MACROS.MUS:337  IF (CLN=30)!(CLN>31)` |
| `~` logical XOR | 1 | `MACROS.PDS:47  db @1,(@2)*((@1&64~64)/32-1),…` |
| `<` comparison | 1 | `MACROS.PDS:296  if @2<256` |
| `[lo,hi]` range check | 1 | `MACROS.MUS:293  CLN = @1 [2,350]` |
| `<>` comparison | 1 | `CMLOGO.ROU:2734  IF *-!0 <> 19` |

### 5.1 The two ambiguities a transpiler must resolve

1. **`&` is both a hex prefix and logical AND.** PDS resolves it positionally: at the
   start of a *term* it is a hex prefix (`&7fd`), after an operand it is AND
   (`(@1&32)`, `CLN&1`). The classic trap is `if varlim>&743` (`MACROS.PDS:37`): the
   `>` is a comparison and `&743` is the hex literal `$743`; a lexer that treats every
   `&` as AND mis-parses the line.
   Rule that reproduces all 391 + 3 observed uses: `&` starts a hex literal iff the
   preceding character is an operator, `#`, `(`, `,`, or the start of the expression
   (`&7fd`, `#&0d-4`, `>&ff`); otherwise it is AND (`@1&32`, `CLN&1`).
2. **`<`/`>` are LSB/MSB extractors at the start of an expression, comparisons in the
   middle** **[M]**. PDS's default is *inverted* from the common convention:
   `<expr` returns the **high** byte and `>expr` returns the **low** byte.
   Verified against the ROM: `BANK12 DEFB <B12,>B12` with `B12 = 2` emits `00 02`
   (`<`=0=MSB, `>`=2=LSB) **[O]**, and
   `BANK14 DEFB <B14,>B14` with `B14 = $012D` emits `01 2D` **[O]**.
   The manual notes this is a configuration switch **[M]**, so a transpiler must take
   the direction from the build config, not hard-code it.

Consequences: `#<label` = high byte, `#>label` = low byte. All 43 start-of-operand uses
are byte extractions on symbols (`DEFB <B8,>B8`, `defb >explodeheartsl,>explodehearts,…`),
never comparisons, and all are consistent with `<`=MSB.

Further expression facts:

* 16-bit arithmetic wraps and negative literals are 2's complement, so `-20/4`
  evaluates as `65516/4 = 16379` **[M]**. The manual says "MOD 65535"; whether that is
  literal (65536→1) or loose for 16-bit truncation (65536→0) is **unresolved** — no
  corpus expression overflows, so it must be probed on the real assembler.
* Division floors **[M]**.
* Precedence, highest→lowest **[M]**: `()`; unary `<`/`>`; `*`,`/`; `+`,`-`;
  `=`,`<>`,`>`,`<`; `&`,`!`,`~`. Unary `-` applies only to a single number/label, not an
  expression (`-1*(expr)` is the documented idiom).
* `EQU` cannot forward-reference; `=`/`DEFL` can redefine.
* Strings in `DB`/`DEFW` are ASCII (`"ab"` = `$6261`, low byte first) **[M]**;
  strings in `CBM` are C64 screen codes, verified in the ROM (§7.4).

---

## 6. File/format details and parser hazards

| property | observation |
|---|---|
| line endings | 32 of 34 build files are **bare LF**; `BANK8.PDS` and `BANK13.PDS` are **CRLF** **[O]** |
| NUL bytes in text sources | 0 **[O]** |
| non-ASCII bytes in text sources | exactly the DOS `^Z` (0x1A) plus **1–2 embedded 0x01/0x02 "block mark" bytes** in 28 of 34 files **[O]** |
| final byte | 0x1A in 32/34; `MACROS.PDS`/`VARS.PDS` end 0x0A |
| trailing `END` | only `ENDCODE.ROU:43`; all other files rely on end-of-project |
| indentation | tabs (2,113–1,494 per big file); labels always column 1; op always preceded by ≥1 tab/space. Space-only indentation is rare but present |
| longest line | `MAINLOOP.ROU:23` = **146 chars** (over the manual's 120-char note for `HEX`) |
| comments | `;` anywhere outside quotes; `*` in **column 1** only (10 files, 46 lines) |
| `*` in code | program counter (`ORG *+(@1)`, `*-spritetable`, `equ * - mapchrsdefs`) |
| label terminator | PDS ignores **one** non-label character after a column-1 label, so `FRED:` and even `redefinewaterbank\x02` parse **[M]/[O]** |
| `!` labels | `!1`…`!5` numeric, plus `!SKIP`, `!HL`, `!T3.0`; scoped per normal label / macro |
| dotted identifiers | `bank.tbl`, `move.w`, `basechr0.157` — `.` is a label character |
| `^A`/`^B` (0x01/0x02) | editor block marks; e.g. `MUSIC1.MUS:174` is `GLISS_WAIT1\t\x01equ chord_shape1\x02` (the `\x01` sits between the label and `equ`) and `XTRAROUS.ROU:862` is `redefinewaterbank\x02` |

### 6.1 Parser hazards, ranked

1. **0x01/0x02 block marks (highest risk).** Present in 28/34 build files, sometimes
   *inside* a token boundary. Example where it changes meaning:
   `MUSIC1.MUS:174  GLISS_WAIT1\t\x01equ chord_shape1\x02` — if not stripped, the
   mnemonic becomes `\x01EQU` and the line fails. Whether PDS itself accepted these
   bytes is **unknown** (the shipped ROM may predate the edit), so strip every byte
   `< 0x20` except TAB/CR/LF. `[O]` presence, `[I]` assembler tolerance.
2. **`*` comment vs PC** — decide by column, not by character.
3. **`;` immediately after a label** — `[M]` says the `;` is consumed as the label
   terminator, so `FRED; comment` defines `FRED` and then assembles the comment text as
   the opcode. No such line exists in this corpus **[O]**, but the `\x02` case above is
   the same mechanism.
4. **One-character label terminator** — `FRED:` is fine; `FRED+` silently becomes label
   `FRED` plus `+` as the ignored terminator, not a label-plus-operator.
5. **Indented `*` comment.** `MAINLOOP.ROU:23` begins with a TAB then `*** …`. The manual
   only sanctions `*` in column 1; the line survives in shipped source, so PDS evidently
   ignores `*` after leading whitespace too — treat any line whose first non-blank
   character is `*` as a comment. `[O]` occurrence, `[I]` tolerance.
6. **`HEX` operands are raw hex digit runs**, not expressions: `HEX 0001030507080B08…`,
   spaces/tabs allowed between bytes. 1,134 lines in MAPDATA. A `;` comment may follow
   (`MAPDATA.DAT:224  hex 0e271a06   ;green`, `UNPACK.ROU:399  HEX 030303;02`).
7. **`DEFB` values may be `>sym`, `<sym`, `%bin`, `&hex`, `$hex`, expressions, or bare
   label names whose *value* is a small index** (`defb basechr0.157`).
8. **`ORG` has two forms**: `ORG pc` and `ORG pc,truepc` (`CMLOGO.ROU:2637 ORG *,$20`,
   `ORG *,*` at 2745). `ORG` does not emit filler; the gap is whatever the bank image
   uses (0x37).
9. **`BANK` takes an expression, not just a literal**: `bank wipebanks` inside the DO
   loop. Bank numbers are also project-defined (8/12/13/14), not sequential.
10. **A label may be the whole line** (`ED12`, `bank_table`, `veryend`); it takes the
    current PC.
11. **`ORG` may leave the bank window.** `JONSBIT.MUS` does `ORG 2` / `DS 1,0` inside
    bank 13; the bytes land at `$0002–$0003` and never appear in the 16 KiB bank image.
    A bank-aware emitter must route by address, not by "everything since the last BANK".
12. **`DS` without fill is undefined data** (`[M]`: downloader sends random bytes). Only
    `DEFS 8,3`, `DS 1,0`, `DS 13,$EA` etc. are used here, all with explicit fill.

---

## 7. Bank and content mapping

### 7.1 Commit semantics

`BANK n` commits everything assembled since the previous `BANK` directive as bank `n`
(ledger, confirmed). Source order is therefore:

```
content … EDn / bn equ / FREE / LIST ON / BANKn DEFB <Bn,>Bn / LIST OFF /
guard / bank n / org <base> … next content
```

The `Bn` label is placed *after* the content, so `Bn = top - EDn` is the **free byte
count** at that point; the two header bytes are the last source bytes of the bank.

Free-space formulas actually used:

| bank file | formula | value | header bytes in image |
|---|---|---:|---|
| `BANK8.PDS` | `b8 equ ED8-&8000` | 0 | not in any `.B?` image (bank 8 is dropped) |
| `BANK12.PDS` | `b12 equ &c000-ED12` | 2 | `00 02` @ `.BC` 16382–3 **[O]** |
| `BANK13.PDS` | `b13 equ &c000-ED13` | 614 (`$0266`) | **slot exists but holds `CB E4`, not `02 66`** @ `.BD` 15770–1 **[O]** |
| `BANK14.PDS` | `b14 equ &BFFF-ED14` | 301 (`$012D`) | `01 2D` @ `.BE` 16082–3 **[O]** |
| `ENDCODE.ROU` | `b15 equ &fff9-ED15`, `T equ b12+b13+b14+b15` | 344 (`$0158`) / 1261 (`$04ED`) | `01 58 1C 8C` @ `.BF` 16033–6 **[O]** |

`&BFFF` for bank 14 (rather than `&C000`) is why its header reads 301 while the image
leaves 300 bytes of `0x37`: the formula deliberately counts one byte before the top.

`B15` in `.BF` is exact (`$0158 = $FFF9 − $FEA1`), so the pair at `$FEA1` is definitely
`BANK15`/`TOTAL`. But the `T` half in the image is `$1C8C`, while the released source
computes `2 + 614 + 301 + 344 = 1261 = $04ED`. Either `T` was computed against a
different bank layout at build time or that field is stale; only the `B15` half is a
usable oracle **[O]/[I]**. The static literal `T` is never read at run time (no source
reference outside `ENDCODE.ROU`).

### 7.2 Which files land in which bank (shipped configuration)

| physical image | base | content assembled into it | size |
|---|---|---:|---:|
| `.BC` | `$8000` | `MAPDATA.DAT` + `BANK12` header | 16,382 + 2 = 16,384 |
| `.BD` | `$8000` | `MACROS.MUS` (0 B) + `JONSBIT.MUS` (0 B in-bank; 2 B at `$0002` from `DS`) + `MUSIC1.MUS` + `HISCORE` + `TITLE` + `SOUNDFX` + `NEWBITS` (partial) + `EXPLODE` + `PRTROBIN` + `BANK13` header | 15,770 source bytes + 2 stale trailer bytes, 612 fill |
| `.BE` | `$8000` | `CMLOGO.ROU` (absolutely-gated part) + `CHRSETS.CHR` + `BANK14` header | 16,084 content, 300 fill |
| `.BF` | `$C000` | `TIMINGS` … `MAPSCROL` + `ENDCODE` (4-byte B15/T trailer) + 21-byte monitor stub + `org $fff9` vectors | 16,384 (322 fill bytes) |

Prelude (`MACROS.PDS`, `VARS.PDS`) and `BANK8.PDS` form the bank-8 commit (2 bytes) and
are not present in any shipped image. **`MACROS.MUS` and `JONSBIT.MUS` contribute nothing
to bank 13** at the shipped configuration (`musicon=1`, `gav_master=1`): JONSBIT's whole
`ORG $C004` driver is inside `IF gav_master=0`, leaving only two `DS 1,0` bytes at
`ORG 2` (addresses `$0002–$0003`, outside the bank window). The live driver is
`MUSIC1.MUS` **[O]**, confirmed by `.BD[0..4] = 0d 4c 07 80 4c` matching
`MUSIC1.MUS:222-225` (`ORG $8000` / `DB 13` / `JMP START_MUSIC` / `JMP PLAY_MUSIC`).

**Bank 15 numbering quirk.** `ENDCODE.ROU` labels its header `BANK15` but commits with
`bank 12` (line 30) — i.e. the main bank is committed under bank number 12, the same
number used for the map bank earlier. Under the "each commit rewrites the output file"
rule this would clobber `.BC`; since the shipped images keep both, the output name must
be assigned per commit rather than derived from the bank number, or the `master=0` branch
was used (`BANK 12,START`). Either way: **do not derive the output filename from the bank
number**; use commit order. `[I]` — the exact naming rule is not recoverable from source
alone.

The `master=1` branch then commits banks 0…11 as 16 KiB of zeroes (`defs &4000,0` +
`bank wipebanks`) — 12 further commits that produce no shipped artefact.

### 7.3 ROM reconciliation: `.BC` (bank 12)

I rebuilt `MAPDATA.DAT` byte-for-byte with the mini-assembler in §11.2 (all `HEX`,
`DEFB`, `DEFS 8,3`, and the 7 dotted-label values MAPDATA uses, resolved from
`UNPACK.ROU`'s `compchr` order):

* assembled size **16,382** = 16,384 − 2 header bytes **[O]** (matches `.BC` exactly in length)
* **byte-identical to `.BC[0:16382]` except 39 bytes**, all `0x0E`→`0x0D`, all inside
  `gamepallettes` / `spritecolours`, offsets `$061E`–`$06A2` (`MAPDATA.DAT:185–227`) **[O]**
* `.BC[16382:16384] = 00 02`, the `BANK12 DEFB <B12,>B12` trailer **[O]**

**This corrects the ledger.** The ledger's "MAPDATA assembles to 15976 bytes … ~398-byte
insertion … 406-byte difference" counts **only the `HEX` lines** (15,976 exactly).
`MAPDATA.DAT` also contains 101 `DEFB` lines and one `DEFS 8,3`, whose 406 bytes sit
between the `HEX` runs — that is exactly the "insertion" and exactly the 406-byte gap.
Assembled in source order there is no shift at all; the only real difference is the
39-byte palette edit. The source is *slightly later* than the ROM (`$0D` in the ROM,
`$0E` in the source), not earlier.

| check | result |
|---|---|
| `HEX`-only bytes | 15,976 |
| `DEFB`+`DEFS` bytes | 406 |
| total | 16,382 |
| identical prefix vs `.BC` | 1,566 bytes (first palette byte), then 39 scattered diffs |
| trailing header | `00 02` at 16382 ✓ |

### 7.4 `.BD` (bank 13)

| probe | expected from source | image |
|---|---|---|
| byte 0 | `MUSIC1.MUS:223 DB 13` | `0D` ✓ |
| bytes 1–6 | `JMP START_MUSIC`, `JMP PLAY_MUSIC` | `4C 07 80 4C 66 80` ✓ |
| `incbin data3` at `ORG $86DA` | offset `$06DA` = 1754, 4,230 bytes | found at **1754**, `DATA3` byte-identical ✓ |
| `HISCORE` CBM `"PRESS"` | `A3 0E 10 12 05 13 13` at some offset | found at **6955** ✓ (confirms `CBM` = C64 screen codes) |
| last content byte | — | offset 15,771; 612 × `0x37` follow |
| `BANK13 DEFB <B13,>B13` | `02 66` (B13 = 614) at 15,770–1 | **hold `CB E4`** — the trailer slot exists but the trailer was not written |

So `.BD` is a near-exact build up to the trailer. Content before the trailer is 15,770
bytes; the two trailer bytes at 15,770–1 hold music data (`CB E4`) instead of `02 66`,
then 612 × `0x37` fill to 16 KiB. Either the image came from a revision without the
`BANK13 DEFB` line, or the trailer was overwritten. `[O]`, cause `[I]`.

### 7.5 `.BE` (bank 14)

| region | offset | contents |
|---|---:|---|
| CMLOGO code/data | 0 – 2,921 | starts `A2 00 8E 00 20 8E 01 20` (`ldx #0/stx $2000/stx $2001`) ✓ |
| `CHRSETS.CHR` | 2,922 – 16,081 | `HEX 0E0080` @2922, `HEX 0FFF` @2925, then 12 `INCBIN`s |
| `BANK14` header | 16,082 – 16,083 | `01 2D` (= 301) ✓ |
| filler | 16,084 – 16,383 | 300 × `0x37` |

All 12 `INCBIN` payloads are **byte-identical and contiguous** in exactly the
`CHRSETS.CHR` order **[O]**:

`HISCORE.PP1`@2927, `TOPCHRS`@4329, `BOTCHRS`@6522, `ROBINCHR`@8723, `BASECHR`@11344,
`BEADCHR`@12626, `BOXCHR`@12839, `ARCHCHR`@12885, `ROCKCHR`@13806, `BEDCHR`@14952,
`DOORCHR`@15501, `OKCHR`@16071.

The CMLOGO region does **not** match `CMLOGO.PP1` in the repo: a 23-chunk sample shows
15 chunks matching at offset 1,068 and the rest differing, and the `DB "* SMILEY TEST
V1.3 "` marker (CMLOGO.ROU:2732) is not present anywhere in `.BE` **[O]**. The shipped
build predates the repo's smiley/logo revision.

### 7.6 `.BF` (main bank, base `$C000`)

| offset | bytes | meaning |
|---:|---|---|
| 0 | `0F` | **not assembled**, never executed (0x0F = 15 = the logical bank number — suggestive but unproven) |
| 1–3 | `37 37 37` | filler in the `$C000–$C003` hole before `ORG &C004` |
| 4 | `4C F8 C2` | `jmp pastnops` (`BANK14.PDS:15` → `START.ROU:64`) ✓ |
| 7 | `4C 93 C4` | `jmp cm_nmi` (`BANK14.PDS:16` → `INTERUPT.ROU:4`) ✓ |
| 10 | `00 01 … 0F` | `bank.tbl` 16 bytes ✓ |
| … | code | `TIMINGS` … `MAPSCROL` |
| 16,032 | last byte before the trailer | |
| 16,033–16,036 | `01 58 1C 8C` | `BANK15 DEFB <B15,>B15` + `TOTAL DEFB <T,>T`; `B15 = $0158 = 344` is **exact**, `T = $1C8C` ≠ source `$04ED` |
| 16,037–16,355 | 319 × `0x37` | fill |
| 16,356–16,376 | 21 bytes of code | **non-source** PDS monitor stub (`ANALYZE = $FFE4` is the first byte) |
| 16,377–16,383 | `40 07 C0 84 C2 F9 FF` | `rti`, `$C007` (NMI), `$C284` (RESET=START), `$FFF9` (IRQ) ✓ |

The `BANK15` half of the trailer matches exactly, which pins the main bank's content end
at `$FEA0`; the `TOTAL` half is stale (see §7.1). The 21 bytes at `$FFE4–$FFF8` are not
produced by any source line — they are the only code in the banks that cannot be
regenerated from `pds_src/src`. The vectors themselves match `ENDCODE.ROU:21-25`.

### 7.7 Summary of image/source disagreements

| artefact | status |
|---|---|
| `.BC` = `MAPDATA.DAT` | exact length; 39-byte palette revision difference; header exact |
| `.BC` trailer | present, exact |
| `.BD` music code + `DATA3` + `HISCORE` text | exact at all probed offsets |
| `.BD` header | slot present but holds music data (`CB E4`), not `02 66` |
| `.BE` `CHRSETS.CHR` | exact, all 12 files |
| `.BE` `CMLOGO.ROU` | differs (packed logo revision + missing smiley) |
| `.BE` header | present, exact |
| `.BF` code | not verified byte-wise (needs a full assembler) |
| `.BF` vectors | exact |
| `.BF` header | `B15` exact (`01 58`), `TOTAL` stale (`1C 8C` vs `04 ED`) |
| `.BF` non-source bytes | 21-byte monitor stub at `$FFE4–$FFF8`, unassembled `0F` at `$C000` |

---

## 8. Transpiler priority list

Effort is person-days for a competent implementer, assuming a clean-room assembler that
already has a 6502 encoder. "PDS-specific" effort only.

### 8.1 Must support (the corpus cannot be assembled without these)

| # | feature | corpus evidence | effort |
|---|---|---|---:|
| 1 | column-1 label / tab-indented opcode / `;`-comment lexer, `*` comment, strip `0x01/0x02/0x1A` | §6 | 1 |
| 2 | expression evaluator: 16-bit wrap, PDS precedence, `$`/`&`/`%`, unary `-`, `<`/`>` byte ops (MSB/LSB default, configurable), `*`=PC, `&`/`!`/`~`, 4 comparisons | §5 | 3–4 |
| 3 | two-pass symbol table, local-label scoping (clear on normal label / macro / LOOP), forward refs for branches | §4.1 | 2 |
| 4 | 6502 encoder + zero-page/absolute size selection (incl. forced `abs` via forward ref) | §3.2 | 4–5 |
| 5 | `DEFB/DB`, `HEX`, `DEFW/DW`, `DEFS/DS` (with fill), `DH`, `DL` | §3.1 | 1.5 |
| 6 | `EQU` (non-redefinable) and `=`/`DEFL` (redefinable) | 256 + 64 uses | 0.5 |
| 7 | `INCBIN` with backslash paths, no-extension names, case-insensitive resolution, `PATH` prefix | 21 uses | 1 |
| 8 | `ORG` one- and two-operand forms | 23 uses, 8 distinct spellings | 0.5 |
| 9 | `IF`/`ELSE`/`ENDIF` with symbols defined conditionally (`zvar` inside `IF`), nesting ≥3 | 86/32/112 | 1 |
| 10 | `MACRO`/`ENDM`, `@1…@9` text substitution, macro-local `!` labels, nesting ≥4, `EXITM` | §4.2/4.3 | 3–4 |
| 11 | `IFS [a][b] …` multi-comparison string test | 26 uses | 1 |
| 12 | `DO n … LOOP` and `DO … UNTIL expr` | 11/9/2 | 1 |
| 13 | `CBM` (C64 screen codes) | 55 uses, verified against ROM | 0.5 |
| 14 | `BANK n`, `FREE`, `LIST ON/OFF`, `ERROR`, `OPTION`, `SEND`, `END` | §3.1 | 1 |
| 15 | multi-bank output + 16 KiB padding with `0x37` | §7 | 1 |

### 8.2 Rare but present (implement, low priority)

| feature | uses | effort |
|---|---|---:|
| `!0` (start-of-line PC; undocumented) | 1 | 0.5 |
| `[lo,hi]` range check | 1 | 0.5 |
| `~` XOR operator | 1 | 0.1 |
| `@@n` evaluated parameter | 1 | 0.5 |
| dotted / `concatenated` label names from macro parameters (`compchr basechr0.157`) | 14 | 0.5 |
| `ORG *,$20` and `ORG *,*` (true-PC relocation) | 3 | 0.5 |
| `REPEAT expr` (single following line) | 1 | 0.5 |
| `BANK <expr>,<execaddr>` | 1 branch (`master=0`) | 0.5 |
| `DEFS n,fill` | 1 (+2 elsewhere) | 0.1 |
| `DJ`-style macro that emits `ORG *+(@1)` | 19 | included in #8 |

### 8.3 Can be stubs (zero uses; warn and skip)

`RADIX`, `SKIP`, `ASK`, `QUERY`, `INCLUDE`, `IFF`, `DC`, `STRING`, `BYTE`, `WORD`,
`BLOCK`, `DFB`, `DFW`, `DFS`, `.BYTE`, `(zp,X)` encoding, `BRK`, `CLI`, `CLV`, `SED`,
`TSX`.

Stub cost ≈ 0.5 day total (recognise + error, do not silently mis-assemble).

### 8.4 Total

≈ **25–32 person-days** for a byte-exact assembler of this corpus, of which ~60 % is the
6502 encoder + expression evaluator. A transpiler that only needs a *readable* Z80/6502
re-emission and not byte-exactness can skip #4's size optimisation, `DH`/`DL`, and all of
§8.2, landing near **12–15 days**.

---

## 9. Conformance-test plan

### 9.1 Oracle hierarchy

1. **`ROBINV7.BC`** — strongest: byte-exact for 16,343/16,382 bytes, and the remaining 39
   are a known colour edit. Use as the primary golden.
2. **`ROBINV7.BE[2922:16084]`** — exact `CHRSETS.CHR` output plus the `01 2D` trailer.
3. **`ROBINV7.BD`** — exact at three independent anchors (music entry, `DATA3` block,
   `HISCORE` CBM text). Good for macro/`CBM`/`INCBIN`/`ORG` conformance, not for whole-bank
   byte equality (header absent, later revisions).
4. **`Super Robin Hood.nes`** — PRG banks 8–11; use only when a `.B?` image is suspect.
5. **`PDS_Manual_6502.txt`** — semantics oracle for features with no corpus use.

### 9.2 Golden tests (in dependency order)

| test | input | assertion |
|---|---|---|
| T1 lexer | all 34 files | token stream contains no `0x01/0x02/0x1A`; comment classification matches `grep '^\s*[*;]'` |
| T2 literals | `MAPDATA.DAT` | 1,134 `HEX` lines → 15,976 bytes; concatenated `bytes.fromhex` equality |
| T3 data pseudo-ops | `MAPDATA.DAT` | total 16,382 bytes; compare to `BC[0:16382]`, allow exactly the 39 palette diffs |
| T4 `CBM` | `HISCORE.ROU` block at 6,955 | `cbm "PRESS"` → `10 12 05 13 13`; `"START"` → `13 14 01 12 14` |
| T5 `INCBIN` + trailer | `CHRSETS.CHR` + `BANK14.PDS` | 13,160 + 2 bytes == `BE[2922:16084]` byte-exact |
| T6 `INCBIN` + `ORG` | `MUSIC1.MUS` alone | offsets 0–3 and the 4,230-byte `DATA3` blob at 1,754 match `BD` |
| T7 macros | `MACROS.PDS` + `VARS.PDS` only | assert `cm_frames=$00`, `control0=$01`, `control1=$02`, `interon=$03`, `seed=$04`, `pad=$07`, `debounce=$08` (zvar chain), `finishedloop=$0300` (first `var`), and `attributes` occupies `7*8*2 = 112` bytes |
| T8 macro optional args | synthetic `ADD`, `MOVE.W`, `DEFSPR`, `SETBANK X/A/literal` | golden byte strings derived from the macro bodies |
| T9 `IFS`/`EXITM` | `MACROS.MUS` `WRITE`/`SETBANK` | expansion with 0/1/2 args produces the three documented bodies |
| T10 `DO/LOOP`/`UNTIL` | `TIMINGS.ROU` | `times16lo` = `00 10 20 …` (216 B), `times16hi` = `00 00 … 01 …`; `xx` tables = 14 B each |
| T11 redefinable `=` | `TIMINGS.ROU`, `ENDCODE.ROU` | `count`, `xx`, `wipebanks` values at each use |
| T12 expression edge cases | synthetic | `-20/4 = 16379`; `7/3 = 2`; `< $1234 = $12`; `> $1234 = $34`; `(CLN=30)!(CLN>31)` truth table; `@1&64~64` ∈ {0,64}. Overflow: resolve `60000+60000` empirically (manual says MOD 65535 → 54465; plain 16-bit truncation → 54464) |
| T13 `BANK` accounting | whole project | `b12=2`, `b13=614`, `b14=301`, `b15=344`, `T=1261` (`$04ED`); image `TOTAL` field is stale (`$1C8C`) |
| T14 vectors | `ENDCODE.ROU` | last 7 bytes `40 07 C0 84 C2 F9 FF` |
| T15 negative | synthetic | `LDA (FRED+2)*3` must raise "extra characters on line" **[M]**; `DS 20` must leave unfilled (not zero) |

### 9.3 Regression corpus for the *transpiler* (not the assembler)

Because the goal is re-emission, also assert per-file invariants:

* every input file yields the same number of labels and the same local-label scoping
  (compare `symbols.json` produced by two independent runs);
* the emitted symbol addresses for all public labels in each bank match the addresses
  recovered from the ROM where known (e.g. `pastnops = $C2F8` from `.BF[4]`,
  `cm_nmi = $C493` from `.BF[7]`, `START = $C284` from the RESET vector).

### 9.4 What cannot be a golden

* `CMLOGO.ROU`'s packed-logo bytes (repo `CMLOGO.PP1` ≠ shipped revision).
* The `.BD` trailer bytes (`CB E4` instead of `02 66`) and the `.BF` `TOTAL` field (`$1C8C` vs `$04ED`).
* The 21 bytes at `.BF` `$FFE4–$FFF8` and the byte at `.BF` `$C000` (not produced by source).

---

## 10. Open items / risks

1. **`!0` semantics** — only one use; inferred as "PC at the start of this line". If it is
   actually a macro-invocation ordinal, `CMLOGO.ROU:2734` would fail its own 19-byte check,
   so start-of-line PC is the better bet.
2. **Control-byte tolerance** — the `0x01/0x02` marks may be post-build editor edits; no
   evidence that PDS accepted them. Strip, don't emulate.
3. **Output-file naming across `BANK` commits** — the source commits two different blocks
   as "bank 12"; the shipped set has four images. Naming must be commit-ordered (`[I]`).
4. **`FILE *` in the project file** — meaning inferred.
5. **`OPTION a,b`** — three uses, semantics undocumented in the manual text we have
   (`OPTION 0,0`, `option 0,1`). Treat as no-op unless proven otherwise.
6. **`SUB`/`ADD` are macros, not mnemonics.** This closes the ledger's open question:
   `MACROS.PDS:492` defines `ADD` (`clc`+`adc`, 1 or 2 operands) and `MACROS.PDS:504`
   defines `SUB` (`sec`+`sbc`). `START.ROU:34 sub #dif` is a macro expansion, not a
   non-standard opcode.

---

## 11. Reproduction

### 11.1 Full census

```bash
cd /path/to/SuperRobinHoodNESSource
python3 docs/re/pds/tools/corpus_inventory.py > /tmp/inventory.md
```

Emits: per-file inventory, pseudo-op matrix, mnemonic matrix, macro census, operand-form
census, label/structure census, encoding details, and the list of unrecognised leading
opcodes (currently one: the indented `***` comment in `MAINLOOP.ROU:23`).

### 11.2 MAPDATA byte-exact rebuild (the `.BC` oracle)

```python
import re
V = {'basechr0.157':5,'rockchr157.99':9,'beadchr157.23':6,'doorchr180.73':11,
     'archchr157.85':8,'boxchr247.9':7,'bedchr180.66':10}   # compchr indices
def num(x):
    x = x.strip()
    if x[0] == '%': return int(x[1:], 2)
    if x[0] in '&$': return int(x[1:], 16)
    return int(x)
def ev(x):
    x = x.strip()
    if x in V: return V[x]
    if x[0] == '<': return (num(x[1:]) & 0xffff) >> 8
    if x[0] == '>': return num(x[1:]) & 0xff
    return num(x) & 0xff

src = bytearray()
for ln, l in enumerate(open('MAPDATA.DAT', encoding='latin-1').read().replace('\x1a','').split('\n'), 1):
    l = l.replace('\r','').replace('\x01','').replace('\x02','')
    if not l.strip() or l.lstrip()[0] in '*;': continue
    out, q = [], False
    for ch in l:
        if ch == '"': q = not q
        if ch == ';' and not q: break
        out.append(ch)
    s = ''.join(out).rstrip()
    if not s.strip(): continue
    if not s[0].isspace():
        p = s.split(None, 1)
        if len(p) < 2: continue          # label-only line
        s = p[1]
    p = s.split(None, 1); op = p[0].upper(); a = p[1].strip() if len(p) > 1 else ''
    if op == 'HEX':  src += bytes.fromhex(re.sub(r'\s', '', a))
    elif op == 'DEFB': src += bytes(ev(i) for i in a.split(','))
    elif op == 'DEFS':
        n, fill = (int(x) for x in a.split(',')); src += bytes([fill]) * n
assert len(src) == 16382
rom = open('ROBINV7.BC','rb').read()
diff = [i for i in range(16382) if src[i] != rom[i]]
assert diff[0] == 0x061E and len(diff) == 39 and rom[16382:] == b'\x00\x02'
print('39 palette diffs at', hex(diff[0]), '..', hex(diff[-1]))
```

### 11.3 Anchor probes used in §7

```bash
# CBM encoding + HISCORE data offset in bank 13
python3 -c "b=open('pds_src/src/ROBINV7.BD','rb').read(); print(b.find(bytes([0xa3,0x0e,16,18,5,19,19])))"   # -> 6955
# DATA3 at ORG $86DA
python3 -c "b=open('pds_src/src/ROBINV7.BD','rb').read(); d=open('pds_src/src/DATA3','rb').read(); print(b.find(d))"  # -> 1754
# CHRSETS chain in bank 14
python3 -c "b=open('pds_src/src/ROBINV7.BE','rb').read(); print(b[2920:2932].hex(' '))"  # -> 00 00 0e 00 80 0f ff c8 20 a0 ff 7f
# bank-14 trailer
python3 -c "b=open('pds_src/src/ROBINV7.BE','rb').read(); print(b[16082:16084].hex(' '))"  # -> 01 2d
# bank-15 vectors
python3 -c "b=open('pds_src/src/ROBINV7.BF','rb').read(); print(b[16377:].hex(' '))"       # -> 40 07 c0 84 c2 f9 ff
```

### 11.4 Feature greps (as used for §3.3)

```bash
cd pds_src/src
grep -inE '(radix|skip|\bask\b|query|\binclude\b|iif|\bdc\b|string|\bbyte\b|\.byte|\bword\b|\bblock\b|dfb|dfw|dfs)' \
     *.ROU *.PDS *.MUS *.CHR *.DAT JUNK | grep -vE '^[^:]+:[0-9]+:;'
# -> 34 hits, all comments or label names (`!SKIP`, `sizeofscore`, "block num"); zero directives
grep -inE '(^|[[:space:]])cbm[[:space:]]' *.ROU | wc -l                   # -> 55 (30 HISCORE + 25 NEWBITS)
grep -nE '(^|[[:space:]])(do|loop|until|repeat)([[:space:]]|$)' -i *.ROU *.PDS *.MUS
grep -n '@@' *.ROU *.PDS *.MUS *.CHR *.DAT JUNK                          # -> MACROS.MUS:326
grep -nE '\[[^]]*,[^]]*\]' *.ROU *.PDS *.MUS *.CHR *.DAT JUNK            # -> MACROS.MUS:293
grep -nE '^\*' *.ROU *.PDS *.MUS *.CHR *.DAT JUNK | wc -l                # -> 51 (46 in the build set)
```

---

## 12. One-paragraph answer

The corpus is a single 6502 program split across 34 files and four 16 KiB banks, and its
shape is dominated by six things: `HEX` data (1,418 lines / 18.7 KiB), a handful of
`DEFB` tables, a 223-use `ADD` macro and 106 other macros, `IF`-gated feature blocks
(`absolutely`, `title`, `hiscore`, `musicon`, `testpause`, `showcoins`, `gav_master`,
`analyzeon`, `master`), `!` local labels (759), and two-pass PDS expressions with
inverted `<`/`>` byte extraction and context-sensitive `&`. Everything the manual calls
exotic — `RADIX`, `SKIP`, `ASK`, `QUERY`, `INCLUDE`, `IFF`, `DC`, `STRING`, `.BYTE`,
`[lo,hi]`, `@@` — is either absent or has a single use, so a byte-exact assembler for
this corpus needs roughly 25–32 person-days and can be validated to the byte against
`ROBINV7.BC` (modulo 39 palette bytes), `ROBINV7.BE`'s `CHRSETS` block, and three anchors
in `ROBINV7.BD`.
