# PDS 6502 — Pseudo-op / directive reference

Reference for every directive that the PDS 6502 assembler accepts, with operand
grammar, pass behaviour, emitted bytes and corpus evidence.

**Sources**

| Tag | Meaning |
|---|---|
| **[M]** | Documented in `docs/PDS_6502_Manual.md` (OCR of *The PDS 6502 Manual*). |
| **[M-old]** | Documented only in the earlier manual (`docs/manuals/P.D.S._Manual.pdf`, text layer extracted) — same directive set, extra dotted aliases. |
| **[C]** | Confirmed by real usage in `pds_src/src/` (file:line given). |
| **[B]** | Confirmed byte-for-byte against a shipped bank image (`ROBINV7.BC…BF`). |
| **[K]** | Confirmed by the keyword-dispatch table extracted from `version121_pds6502.exe` — `docs/re/ledger/KEYWORDS.md`. Note this is **1.21**; the corpus uses directives (`OPTION`, `INCBIN`, `PATH`) that are *not* in that table, so the shipped build is a later version (1.22+). |
| **[I]** | Inferred (not documented, not exercised, or deduced from lexer/other rules). Treat as "verify before relying". |

**Dotted aliases.** The manuals spell several directives with a leading dot
(`.BYTE .WORD .BLOCK .ORG .EQU .END .INCLUDE .MACRO .RADIX .DLOAD .DOWNLOAD`).
The 1.21 dispatcher buckets keywords by first letter `A`–`Z`, so a leading `.`
cannot be looked up at all. Treat **every dotted spelling as 1.22+ or OCR
noise**; the corpus never uses one. **[K]**

Where the two manuals disagree, the 6502 manual wins; the older manual is only
quoted for aliases the OCR of the 6502 manual clearly dropped.

---

## 0. Lexical rules that every directive depends on

These are not directives, but they change how operands parse. Get them wrong and
every directive mis-parses.

* **Columns.** A label must start in column 1. Everything else must be indented
  by at least one space/tab. Fields are separated by any run of spaces/tabs. **[M]**
* **Label terminator.** Exactly **one** non-label character after a label is
  ignored: `FRED NOP`, `FRED: NOP`, `FRED# NOP` are all `FRED`. Consequence:
  `FRED; NOP` does **not** treat `;` as a comment start — it is the terminator
  and `NOP` still assembles. **[M]**
* **Label characters.** `a–z A–Z 0–9 . _ $`; first character may not be a digit.
  A label alone on a line takes the current PC. **[M]**
* **Case.** The assembler folds source to upper case. Directives, labels,
  registers and hex digits are case-insensitive (`org`/`ORG`, `defb`/`DEFB`). **[M]**
  String *literals* keep their case — the manual's own `DC 2,"cat"` example
  emits `$63,$61,$74…`. Messages after `ASK`/`QUERY`/`ERROR`/`TITLE` are the
  exception: they are upper-cased unless the message starts with a single quote
  `'`. **[M]**
* **Comments.** `;` to end of line (but never straight after a label, see
  above); `*` in column 1 comments out the whole line. **[M]**
* **Numbers.** `123` decimal; `&1234` and `$1234` hex; `%1010` binary;
  `"a"` = `$61`, `"ab"` = `$6261` (first char is the low byte). Range
  −32768…65535, arithmetic is mod 65536, division rounds down. **[M]**
* **Byte extraction.** **`<expr` = HIGH byte, `>expr` = LOW byte** ("the arrow
  points at the byte returned"). This is the **opposite** of ca65. **[M]** **[C]**
  Verified: `B12 = 2` → `DEFB <B12,>B12` emits `00 02`, and that is exactly the
  last two bytes of `ROBINV7.BC` (`BANK12.PDS:6`). **[B]**
* **Operators.** `+ - * /`, `&` AND, `!` OR, `~` XOR, `= <> > <` comparisons
  (1/0). Precedence: `()` > `<`/`>` byte ops > `*`/`/` > `+`/`-` > comparisons >
  `& ! ~`. Unary `-` applies to a number/label only. **[M]**
* **Range checks.** `expr [lo,hi]` after any operand → "expression out of range"
  error. Bounds may be expressions. **[M]** **[C]** `MACROS.MUS:293`
  `CLN = @1 [2,350]`.
* **PC symbol.** `*` in an expression is the current PC. `*` in column 1 is a
  comment. **[M]**
* **Local labels.** `!name`; cleared whenever a non-local label is defined, and
  on `LOOP`, macro entry/exit. **[M]**

---

## 1. Data definition directives

Summary table (details below):

| Directive | Aliases | Unit | Byte order |
|---|---|---|---|
| `DB` | `DFB DEFB BYTE EQUB .BYTE ASCII TEXT ASC STR DEFM DM DFM` (+`.ASCII .TEXT` [M-old]) | byte / string | as written |
| `DC` | — | byte / string + `$80` terminator | as written |
| `DW` | `DFW DEFW WORD` (+`.WORD` [M-old]) | word | low, high |
| `DH` | `DHIGH` | high byte only | n/a |
| `DL` | `DLOW` | low byte only | n/a |
| `DS` | `DFS DEFS BLOCK` (+`.BLOCK` [M-old]) | fill | n/a |
| `HEX` | — | byte | as written |
| `CBM` | — | byte (screen code) | as written |
| `STRING` | — | byte / string + `$00` | as written |
| `INCBIN` | — | raw file | as stored |

Shared rules for every directive in this section:

* **Label / PC:** a label on the line takes the address of the **first** byte
  emitted; the PC advances by exactly the number of bytes emitted. Emitted bytes
  always go to consecutive addresses (no alignment).
* **Byte order:** `DW` is the only multi-byte emitter and is little-endian;
  everything else writes in source order.
* **`*` in operands:** the manual does not say whether `*` inside a data
  statement sees the PC before or after earlier operands on the same line. The
  corpus never depends on it; assume **start of line** and flag any use. **[I]**
* **Both passes:** the byte count must be identical on pass 1 and pass 2. It is
  fixed by the source (any length/size expression must be pass-stable), so the
  output is the same on both passes.

### DB — define bytes and messages

`DB p1,p2,…` — any number of comma-separated parameters.

* **Aliases:** `DFB`, `DEFB`, `BYTE`, `EQUB`, `ASCII`, `TEXT`, `ASC`, `STR`,
  `DEFM`, `DM`, `DFM`. **[M]** The earlier manual additionally lists
  `.ASCII`, `.TEXT` and prints `DEM` for `DEFM` (OCR). **[M-old]**
  The 1.21 keyword table contains `DB, DFB, DEFB, BYTE, EQUB, ASC, DEFM, DM,
  DFM, STR, TEXT`, **all sharing one handler** (`2AF3/2B34`) — so every spelling
  is bit-identical in behaviour. **[K]**
  `ASCII`, `.BYTE`, `.ASCII` and `.TEXT` are missing from that table; the dotted
  forms cannot be dispatched at all in 1.21 (the table is bucketed by the first
  letter, `A`–`Z`), so they are either 1.22+ additions or OCR artefacts of the
  manual. Verify before relying on them.
* **Operand grammar:** each parameter is either
  * an expression in **−128…255**, emitted as one byte (`value & $FF`, so
    `-1` → `$FF`, `255` → `$FF`), or
  * a `"string"`, emitted as **one byte per character in source order**, plain
    ASCII, no terminator, case preserved.
  * A **single-character** string may participate in arithmetic and acts as its
    character code: `"!1"+128` → `$A1`. **[M]** A multi-character string is a
    byte list, not a number (using it inside arithmetic is not meaningful).
* **Quote doubling:** `""` inside a literal emits one `"`; `"Say ""HELLO"""` →
  `SAY "HELLO"`. **[M]**
* **No operand:** only the `.BYTE` spelling is documented to default to
  `BYTE 0` (one `$00`). This **cannot** be a per-spelling difference in 1.21 —
  all DB aliases share one handler **[K]** — so either the manual describes a
  later version that special-cases the token, or the claim is wrong. Bare `DB`
  with no operand: treat as an error until tested. **[M]**/**[I]**
* **Pass 1 vs 2:** behaviourally identical, because the byte count never depends
  on values (forward references in operands are harmless — resolvable on pass 2).
  Internally PDS runs a *different* handler on each pass (`2AF3`/`2B34`, §7), so
  pass 1 probably only advances the PC; do not capture bytes from a pass-1 trace.
* **Emits:** 1 byte per expression, 1 byte per string character.
* **Limits/errors:** −128…255 per expression, else *expression out of range*.
* **PC/labels:** a label on the line gets the address of the **first** byte; PC
  advances by the number of bytes emitted.
* **Corpus:** `CMLOGO.ROU:2732` `!0 DB "* SMILEY TEST V1.3 "`;
  `MACROS.PDS:45` `db @1,@2` inside `defspr`; `HISCORE.ROU:394`
  `cbm mdownline,"START"` shows strings and numeric equates mixed.

### DC — define bytes, last character of each string gets bit 7

* **Aliases:** none.
* **Operand grammar:** exactly as `DB` (−128…255 expressions, strings).
* **Emits:** numbers unchanged; for **each string**, all characters ASCII **and
  the last character ORed with `$80`**. There is no terminator *after* the
  string, the terminator *is* the last character.
* **Pass 1/2:** same size both passes; handlers differ per pass (`321B`/`31DE`). **[K]**
* **Limits/errors:** same as `DB`.
* **Worked example [M]:** `DC 2,"cat",13,"i"` →
  `02 63 61 74 F4 0D 69 E9`
  (`t`=$74→$F4, `i`=$69→$E9; the manual's `$74|$80` / `$A1` are OCR damage of
  `$F4` / `$E9` — the rule "bit 7 set on the last character" is unambiguous).
* **Corpus:** none (0 uses).

### DW — define words

* **Aliases:** `DFW`, `DEFW`, `WORD` (`.WORD` [M-old]). 1.21 has `DW`, `DFW`,
  `DEFW` only (`2C6B`), **no `WORD`** — that alias is 1.22+ or an OCR artefact. **[K]**
* **Operand grammar:** comma-separated expressions in **−32768…65535**, or
  strings of **one or two characters only**.
* **Emits:** **low byte first, then high byte** (6502 little-endian).
  * `DW $1234` → `34 12`
  * `DW "ab"` → the string is the 16-bit value `$6261` (`"a"`=low, `"b"`=high),
    emitted `61 62`
  * `DW "a"` → `61 00`
* **No operand:** the `.WORD` spelling defaults to `DW 0` → `00 00`. **[M]** But
  `WORD` does not exist in 1.21 at all **[K]**, so this is unverified for the
  shipped toolchain.
* **Pass 1/2:** identical (operand width is fixed).
* **Limits/errors:** 3+ character string → error (string too long) **[I]**;
  out-of-range expression → *expression out of range*.
* **Corpus:** `ENDCODE.ROU:24` `defw START`; `MUSIC1.MUS:1430`
  `DW TUNE1A-2,TUNE1B-2,…`; `SOUNDFX.ROU:267` `DW !TAP,!PING,…` (forward refs,
  fine because the width is fixed).

### DH — define high bytes only

* **Aliases:** `DHIGH`.
* **Operand grammar:** same accepted range as `DW` (−32768…65535); **no strings** **[I]**.
* **Emits:** one byte per expression, the **high** byte, i.e. internally
  `DEFB <e1,<e2,…` (PDS `<` = MSB).
* **Worked example [M]:** `DH 65500,23,500` → `FF 00 01`
  (65500=$FFDC, 23=$0017, 500=$01F4).
* **Pass 1/2:** identical.
* **Corpus:** `MUSIC1.MUS:1374-1389` — a 16-line high-byte table
  (`DH $6AE,$64E,$5F3,…`).
* **Gotcha:** a transpiler must translate `<`→ca65 `>` here (byte ops are
  swapped, see §8).

### DL — define low bytes only

* **Aliases:** `DLOW`.
* **Operand grammar:** as `DH`.
* **Emits:** one byte per expression, the **low** byte (internally `>expr`).
* **Worked example [M]:** `DL 65500,23,500` → `DC 17 F4`
  (note the manual's DL example is mis-printed as `DH`, and 23 is shown as the
  decimal `23` = `$17`).
* **Corpus:** `MUSIC1.MUS:1357-1372` — low-byte twin of the DH table.
* **Gotcha:** `<`/`>` swap vs ca65.

### DS — define space

* **Aliases:** `DFS`, `DEFS`, `BLOCK` (`.BLOCK` [M-old]). 1.21 has `DS`, `DFS`,
  `DEFS` (`3040/307E`) but **no `BLOCK`**. **[K]**
* **Grammar:** `DS length [, filler]`.
* **Emits:** exactly `length` bytes of output: the `filler` byte if given,
  otherwise **uninitialised/"random" data** (the manual warns you cannot assume
  anything — the shipped bank images are padded with `$37`). PC advances by
  `length`. For a transpiler: always supply an explicit fill (`.res n,fill`),
  never leave the gap undefined.
* **Pass 1/2:** same size both passes; only the PC matters. (Handlers are split
  per pass, `3040`/`307E`. **[K]**)
* **Limits/errors:** length is a normal expression (0…$FFFF range); negative or
  overflowing length → range/PC error **[I]**. No documented maximum.
* **PC/labels:** label = first reserved address.
* **Corpus:** `ENDCODE.ROU:34` `defs &4000,0` (16 KiB of zeros, used to wipe a
  bank); `HISCORE.ROU:501` `checkhiscores defs 9,128`; `CMLOGO.ROU:2728-9`
  `DS 13,$EA` / `DS 15,$EA` (padding to a fixed routine length);
  `JONSBIT.MUS:19` `status0 ds 1,0`.

### HEX — define hex bytes

* **Aliases:** none.
* **Grammar:** `HEX` followed by hex digit **pairs**. Spaces/tabs may separate
  bytes **[M]**; the corpus writes the pairs **run together**:
  `HEX 0001030507080B08…` (= 16 bytes). Commas are never used, and since the
  scanner consumes hex digit pairs anything else should be an error. **[C]**/**[I]**
* **Emits:** one byte per pair, in order. Bytes are written as **two hex digits**
  (`0E`, not `E`) **[I]**.
* **Pass 1/2:** identical, pure data.
* **Limits/errors:** documented limit **57 bytes per 120-character line**.
  Odd number of hex digits / non-hex char → error **[I]**. Corpus maximum is
  32 bytes on a 69-character line (measured over 1442 `HEX` lines). **[C]**
* **PC/labels:** label allowed and gets the first byte — `MAPDATA.DAT:5`
  `blkstl HEX 0001…`.
* **Corpus:** 1442 uses; `MAPDATA.DAT:5`, `CHRSETS.CHR:17` `hex 0e0080`
  (3 bytes, with two spaces before a comment), `JUNK`, `SPRITESD.DAT`.
* **Note:** the manual calls this the recommended format for bulk data because
  it is the fastest to assemble.

### CBM — Commodore screen codes

* **Aliases:** none.
* **Grammar:** exactly `DB` (comma-separated expressions −128…255 and strings),
  **but text may not be used in expressions** (`"C"+128` is rejected). **[M]**
* **Emits:** numbers unchanged; each character of each string converted to a
  C64 **screen code**.
* **Conversion, verified against the binary and the ROM [B]:** the handler
  (`0e60:3BB8`) maps each string character with `AL & $3F` and **rejects any
  character `>= $60`** (error DS:0x5E5A, e.g. lower-case `a`–`z`). Thus
  `A`–`Z` → `$01`–`$1A`, space `$20` → `$20`, digits `$30`–`$39` → `$30`–`$39`,
  and `^` ($5E) → `$1E`. Evidence: `HISCORE.ROU:393 cbm "PRESS"` appears in
  `ROBINV7.BD` as `10 12 05 13 13`; `"SCORE"` → `13 03 0F 12 05`;
  `"GAME OVER"` → `07 01 0D 05 20 0F 16 05 12`; and `initnames`
  `cbm "FIRST^^^^"` is at `.BD` offset 0x1CC5 as
  `06 09 12 13 14 1E 1E 1E 1E` — so `^` is remapped, not passed through.
* **No terminator** is added; use numeric screen codes (`27`, `$8D`, `mend`) for
  control/DEL/graphics characters, as NEWBITS.ROU does.
* **Pass 1/2:** identical.
* **Corpus:** 55 uses, all in `HISCORE.ROU` and `NEWBITS.ROU`, e.g.
  `NEWBITS.ROU:426` `cbm maddr+&20,&8d,"SCORE"` (numeric prefix, then screen
  text), `HISCORE.ROU:423` `cbm "  GO",27," DIZZY GO",27`.
* **Why it matters:** the NES build uses `CBM` as its main text encoder
  (screen codes are also its font/tile indices), mixed with raw screen codes for
  control characters — so the generated bytes double as tile numbers. **[C]**

### STRING — zero-terminated strings

* **Aliases:** none.
* **Grammar:** exactly `DB`.
* **Emits:** numbers unchanged; after **each string**, one `$00` is appended
  (the terminator is *additional*, unlike `DC`).
* **Worked example [M]:** `STRING 13,"Cat","dog"` →
  `0D 43 61 74 00 64 6F 67 00`
* **Pass 1/2:** identical.
* **Corpus:** none (0 uses; DC also unused — the ROM's text uses raw `DEFB`
  tables and screen codes).

---

## 2. Symbols and program counter

### EQU / EQUATE — constant

* **Aliases:** `EQUATE`, `EQU` (`.EQU` [M-old]). 1.21 confirms `EQU`/`EQUATE`
  as one handler (`2E04/2E28`) and has **no `DEFL`** — see the next entry. **[K]**
* **Grammar:** `label EQU expression` — **a label is mandatory**.
* **Pass 1/2:** the expression must evaluate to the **same value on both
  passes**; forward references are forbidden (the manual's wording: expression
  must return the same value on pass 1 and 2, no undefined labels). **[M]**
* **Emits:** nothing.
* **Limits/errors:** redefining an `EQU` symbol → *multiply defined label*.
  `EQU` with no label, or with an unresolvable/forward reference → error.
* **Corpus:** 269 uses (opcode position, `corpus_stats.py`).
  `MACROS.PDS:18 master equ 1`;
  `MAPDATA.DAT:169 dungeonschrs equ * - mapchrsdefs`;
  `CMLOGO.ROU:2392 CM_TOTAL EQU *-CM_LOGO`;
  `ENDCODE.ROU:7 T EQU b12+b13+b14+b15`.
* **Note:** `EQU *` is the "label = here" idiom; several labels on consecutive
  lines are legal and all get the same value.

### DEFL and `=` — redefinable symbol

* **Aliases:** `DEFL`, `=` (the old manual groups `EQU, EQUATE, .EQU, DEFL, =`
  together but explains that only `DEFL`/`=` are re-definable). **[M]**
  **`DEFL` is not in the 1.21 keyword table**, but bare `=` **is**: it lives in
  the non-letter keyword table at file `0x6ACE` (DS `0x619E`) with handler
  `0x3412` for both passes, and sets symbol type 2 (redefinable). So in 1.21 the
  re-definable form is `=` only; `DEFL` is 1.22+ or a manual error. **[K]**
* **Grammar (1.21):** `label = expression`. (`label DEFL expression` is the
  manual's older spelling; there is no `DEFL` keyword in the 1.21 binary.)
  Whitespace is required: the label terminator eats one character, so
  `FRED=2` would terminate the label on `=` and then try to assemble `2` as an
  opcode **[I]** — the corpus always writes a space/tab. **[C]**
* **Pass 1/2:** re-evaluated on every encounter, so it must still be
  deterministic across passes (it is, as long as it does not depend on
  forward references — a forward reference produces different values on the two
  passes and is an error **[I]**).
* **Emits:** nothing.
* **Limits/errors:** range checks allowed: `MACROS.MUS:293 CLN = @1 [2,350]`.
* **Corpus:** 64 uses, almost all loop counters:
  `CONTROL.ROU:909-913` `runaccel = 256/48` / `runcounter = 0` …
  `runcounter = runcounter+runaccel`; `ENDCODE.ROU:31,36`;
  `MACROS.PDS:26 zlim = zlim+@2`.

### ORG — set the program counter

* **Aliases:** `.ORG` **[M]** — confirmed in 1.21: the non-letter table at
  file `0x6ACE` contains `.ORG` with handler `2A2C`, the same as plain `ORG`.
  (The A–Z bucket table is only for alphabetic keywords; `.` and `=` fall
  through to this default table.) **[K]**
* **Grammar:** `ORG new_pc [, true_pc]`.
  * `new_pc` — where bytes are **inserted**; must **not** be a forward reference;
    range `0…$FFFF`; at most **100 ORGs** per program.
  * `true_pc` — the value **labels and `*` use** while bytes still go to
    `new_pc`. This is the overlay / relocatable-module feature.
* **Pass 1/2:** both passes take the same branch; `new_pc` must be computable on
  pass 1. Each `ORG` also starts a **new download block** (records are emitted
  per ORG section, not per contiguous range) **[M]**.
* **Emits:** nothing; changes PC.
* **Limits/errors:** >100 ORGs → error; forward-reference `new_pc` → error.
  Overlap is **not** detected ("the only way to tell is when you have `SKIP` on
  and the display reads `no skip`"). The manual's `CORG` macro is the workaround.
* **Corpus:**
  * `BANK14.PDS:14 org &c004` — first byte of bank 15 lands at `$C004`.
  * `ENDCODE.ROU:21 org $fff9` — vector block.
  * `VARS.PDS:242 org &8000` — the ORG that starts the whole build (before the
    first bank commit).
  * `JONSBIT.MUS:54 ORG *+(@1)` — "reserve space" macro (`DJ`), equivalently
    `ORG *+n`.
  * **True-PC idiom:** `CMLOGO.ROU:2637 ORG *,$20` … `CMLOGO.ROU:2745-2746
    ORG *,*` / `ORG *` (and the identical `SMILEY.ROU:227`, `328-329`). Code is
    inserted where it is, but its labels resolve as if it ran at `$20` — i.e. a
    routine that is copied into zero page before execution.
* **Interaction with BANK (commit order):** `BANK` commits everything assembled
  *before* it, then the assembler is reset and **a new `ORG` is required** for the
  following bytes. So the order is always
  `…content…` → `BANK n` → `ORG addr` → `…next content…`. See §3 BANK and
  `docs/re/ledger/FINDINGS.md`.
* **Open item [I]:** the manual's follow-up example (`ORG *-$100+$8000` after
  `ORG $8000,$100`) only works if `*` returns the **true** PC, but the corpus
  restores with `ORG *,*` / `ORG *` and then uses `*` as the physical address
  (`CMLOGO.ROU:2867 SMILEY_SIZE EQU *-SMILEY`). Either `*` returns the
  insertion PC and the manual example is stale, or PDS special-cases `*` in
  ORG's first operand. Unresolved; do not depend on mid-block `*` for a
  transpiler. Flagged in the ledger.

### EXEC / START — execution address

* **Aliases:** `START` **[M]**.
* **Grammar:** `EXEC expression` (label optional/ignored).
* **Emits:** nothing; records the download "jump to" address (protocol command
  181). Only **one** start address may be given in the whole program, by either
  `END expr` or `EXEC` **[M]**.
* **Pass 1/2:** value needed at download time (pass 2); the corpus always uses
  an already-defined label.
* **Limits/errors:** second start address → error **[I]** ("may only specify the
  start address once").
* **Corpus:** no `EXEC` is used. `START` occurs only as a *label*
  (`START.ROU:4 start sei`) and as an operand (`ENDCODE.ROU:24 defw START`,
  `ENDCODE.ROU:28 BANK 12,START`). Beware: `START` in the opcode column is the
  directive, in column 1 it is a label.

### END — end of source

* **Aliases:** `.END` **[M-old]**.
* **Grammar:** `END [expression]`; the optional expression is the execution
  address (`END START`, `END $8000`).
* **Emits:** nothing. Stops assembly immediately (otherwise assembly runs to the
  end of the last source file).
* **Pass 1/2:** stops both passes at the same line.
* **Corpus:** `ENDCODE.ROU:43` — bare `END`, because the start address is
  supplied by `BANK 12,START` (which jumps after downloading) instead.

### ERROR — abort with a message

* **Grammar:** `ERROR message`. A leading `"` is optional; **no closing quote is
  required**, and if present it is printed as part of the message. Text is
  upper-cased unless the message starts with `'`. **[M]**
* **Emits:** nothing; terminates assembly on the spot and returns to the editor
  with the cursor on the ERROR line.
* **Pass 1/2:** fires on whichever pass reaches it (so an `IF` guard that is
  true on both passes is needed for build-time asserts).
* **Corpus:** `BANK12.PDS:11` `error "game bank 12 overflowed`;
  `MACROS.PDS:28` `ERROR "Out of zero page work space with variable @1` (inside
  the `zvar` macro — note the unterminated quote);
  `CMLOGO.ROU:2415` `ERROR "SMILEY_HIBANK must be $0..$F`.
* **Error text is data, not code:** never emitted into the image.

### FREE — accounting only

* **Grammar:** `FREE expression`. Sums into a counter that is zeroed at the start
  of each assembly and printed at the end. **[M]**
* **Emits:** nothing. Purely a report.
* **Corpus:** `BANK12.PDS:4 free b12`; `MUSIC1.MUS:1437 FREE ASDA`;
  `ENDCODE.ROU:7` uses `T = b12+b13+b14+b15` for the same purpose.
* **Transpiler:** ignore (optionally re-implement as a size report).

### `*` — current PC

Not a directive, but the symbol used by ORG/DS/FREE idioms. `*` = current
assembly PC; see the ORG open item for true-PC behaviour. **[M]**

---

## 3. Assembly control

### IF / ELSE / ENDIF — conditional assembly

* **Grammar:** `IF expression` … `[ELSE …]` `ENDIF`. Non-zero = assemble.
* **Pass 1/2:** the condition **must be decidable identically on both passes** —
  no forward references. Nesting depth **10**. **[M]** (corpus maximum observed:
  4, `BANK14.PDS:9`).
* **Emits:** nothing itself; the skipped lines emit nothing. In the listing,
  assembled lines are marked `:`, skipped lines `+`.
* **Errors:** unterminated `IF`; forward reference in the expression; nesting
  overflow.
* **Corpus:** `BANK12.PDS:10-12`
  `endofbank12 if endofbank12>&c002` / `error …` / `endif`;
  `ENDCODE.ROU:27-39` `if master=0 … else … endif`;
  `MACROS.PDS:48-56` IF/IFS/ELSE nest inside a macro.

### IFF — "if the operand is a forward reference"

* **Grammar:** `IFF expression`, same block structure as `IF`.
* **Semantics:** assembles the block **only if the expression contains a
  forward reference** (i.e. could not be resolved on pass 1). Used to choose
  between short and long code when the distance is unknown. **[M]**
* **Emits:** nothing.
* **Corpus:** none, but the manual's `JCC` macro depends on it
  (`docs/PDS_6502_Manual.md` §4.3) — `IFF @2` selects the `JMP` form for forward
  targets and the branch form for backward ones.

### IFS — string comparison

* **Grammar:** `IFS [s1] [s2] [s3] …` — brackets, **no commas**; whitespace
  between groups is optional (`MACROS.PDS:184 ifs [@2][]`). Assembles if `s1`
  equals **any** of `s2…sn`. `[]` is the empty string, so `IFS [@1] []` tests
  "parameter not supplied". Comparisons are case-insensitive (source is folded
  to upper case). **[M]**
* **Emits:** nothing.
* **Corpus:** 26 uses, all macro argument dispatch:
  `MACROS.PDS:48 ifs [@5] []`, `MACROS.MUS:228 IFS [@1] [X]`,
  `MACROS.PDS:184` (optional second parameter).
* **Note:** `IFS` without arguments is not valid; at least two bracketed strings
  are needed.

### DO … LOOP — repeat a block N times

* **Grammar:** `DO expression` … `LOOP`.
* **Semantics:** the body between `DO` and `LOOP` is assembled `expression`
  times. The count is evaluated **once**, at the `DO`. `LOOP` clears local
  labels, so `!1` can be reused inside the block. **[M]**
* **Emits:** the body, N times (so N × body size bytes).
* **Limits/errors:** N is a normal expression; N=0 emits nothing; nested
  `DO` blocks work **[I]** (not documented, not exercised).
* **Label on the DO line:** `CONTROL.ROU:911 runtablelo do 47` — the label takes
  the PC before the first copy.
* **Corpus:** `START.ROU:56-58 nops22 do 30 / nop / loop`;
  `TIMINGS.ROU:5-8 times16lo do 216 / defb >count / count = count+16 / loop`
  (generates a 216-entry low-byte table `00 10 20 …`);
  `MAPSCROL.ROU:97-100 do 256 / … / loop`.

### DO … UNTIL — assemble until a condition holds

* **Grammar:** `DO` … `UNTIL expression`.
* **Semantics:** the body is re-assembled and the expression re-evaluated after
  each copy; it stops when the expression is **non-zero**. Used to emit a
  variable amount of code (fill until the PC passes an address). **[M]**
* **Emits:** the body, repeated.
* **Errors:** an `UNTIL` that never becomes true loops forever (no guard is
  documented). The manual recommends `*>1000` rather than `*=1000` so a
  "step over" cannot run to `$FFFF` wrap.
* **Corpus:** `ENDCODE.ROU:32-37 do / org &8000 / defs &4000,0 /
  bank wipebanks / wipebanks = wipebanks+1 / until wipebanks=12` — the only
  UNTIL in the corpus, and it drives the 12 bank-wipe downloads.

### REPEAT — repeat the next line

* **Grammar:** `REPEAT expression`, then the **single following source line** is
  assembled `expression` times. It does not scan for a terminator line (unlike
  `DO…LOOP`). **[M]**
* **Emits:** that line's bytes, N times.
* **Corpus:** `MACROS.MUS:295-296 REPEAT (CLN-2)/7` followed by `HEX 4868`
  (i.e. `PHA/PLA` repeated) — a delay-loop generator.

### SKIP — assembler speed hint

* **Grammar:** `SKIP expression` — minimum block size, typically 15–30.
* **Semantics:** pass-1-only optimisation: mark forward-reference-free blocks so
  pass 2 can skip re-assembling them. Must appear **before any ORG**; disabled
  by `BANK`. At the end of assembly PDS prints the percentage of the skip table
  used, or `no skip` if an ORG overlapped or a BANK was used. **[M]**
* **Emits:** nothing. **Transpiler: no-op.**
* **Corpus:** none (0 uses).

### BANK — commit a bank and download it

* **Grammar:** `BANK n [, start_address]`, `n` = **0…255**, passed through to the
  target unchanged. **[M]**
* **Semantics (confirmed):** `BANK n` **commits everything assembled since the
  previous `BANK` (or since the start of the program) as bank `n`**, downloads
  it, optionally `JSR`s to `start_address`, then **resets the assembler** — the
  symbol table survives, but the PC does not, so an `ORG` must follow. `SKIP`
  is disabled ("no skip" is printed). On pass 2, banks download automatically
  without the `Download (Y/N)?` prompt. **[M]** **[C]** **[B]**
* **Emit order in the source:** content → (optional `label DEFB <free,>free`
  header) → `BANK n` → `ORG addr` → next content.
  `BANK12.PDS` is the canonical shape:

  ```
  ED12                       ; label = PC at end of the previous content
  b12  equ &c000-ED12        ; free bytes in the bank
       free b12
  BANK12 DEFB <B12,>B12      ; 2 marker bytes at the end of this bank
       bank 12               ; <<< commit + download as bank 12
       org &8000             ; new PC for the next segment
  ```
* **Confirmation from the wipe loop:** `ENDCODE.ROU:30-37` commits the main code
  with `bank 12`, then loops `org &8000 / defs &4000,0 / bank wipebanks` with
  `wipebanks` = 0…11. Each iteration therefore emits a 16 KiB zero block that
  the **next** `BANK` commits as bank `wipebanks` — only the
  "commit everything before the BANK directive" model produces banks 0–11 here.
* **Corpus:** `BANK12.PDS:14 bank 12`; `ENDCODE.ROU:28 BANK 12,START` (start
  address form); `MUSIC1.MUS:1449 BANK 0` (separate music build);
  `MUSIC1.MUS:1454 ORG $FFFA` after it (proves the ORG-after-BANK rule).
* **Output side effects:** each commit re-creates its output file; bank images
  are padded to 16384 bytes with `$37`, and the last shipped bank (`$C000`-based)
  is `ROBINV7.BF` (see ledger). Indirect evidence for the file naming
  `name.B<hexbank>`: `.BC`…`.BF` = banks 12…15.
* **Open item:** the corpus' `DEFB <free,>free` marker is present at the end of
  `ROBINV7.BC` (`00 02` at `$BFFE`), but the corresponding markers are **not**
  at the computed end addresses of `.BD`/`.BE` (both end mid-data, followed by
  `$37` filler). Either PDS does not include the final marker bytes in the bank
  image, or those two images come from a different revision. Do not derive bank
  sizes from the marker bytes alone.

### INCLUDE / FILE — pull in a source file

* **Aliases:** `INCLUDE`, `FILE` (`.INCLUDE` [M-old]).
* **Grammar:** `INCLUDE filename` — drive/path allowed
  (`INCLUDE A:\PDS\GAMES\EMPIRE\GRAPHICS`). Filename is raw text to end of line
  (no quotes in the manual's examples).
* **Semantics:** inserts the file's lines at that point; returns to the line
  after the INCLUDE at EOF. **Includes may not nest**; unlimited count
  otherwise. Read on **pass 1 only** (so with `SKIP` they cost nothing on
  pass 2). **[M]**
* **Emits:** whatever the included file emits.
* **Corpus:** no assembler `INCLUDE` in the corpus — the includes live in the
  **project file** `ROBIN.PRJ` (`FILE C:\ROBIN\MACROS.PDS`, …), which is a
  different grammar (`FILE`, `COMMENT`, `CURCOLOUR`, `project`, `asmflag`,
  `ASSEMBLER`, `WINDOW`, `CLOCK`). Note `ROBIN.PRJ:7 FILE *C:\ROBIN\BANK8.PDS`
  — the `*` disables that file (it is the "dummy bank for overflowing"
  placeholder). Do not confuse project `FILE` with assembler `FILE`.

### MACRO / ENDM / JENDM / EXITM — user instructions

Full mechanics belong to the macro volume; the directive surface is:

* **Definition:** `name MACRO [p1,p2,…]` … `ENDM`. The manual lists `JENDM` as
  an alias of `ENDM`, but that is an OCR artefact: 1.21 contains `MACRO`
  (`3272/326A`) and `ENDM` (`3380`) only, with **no `JENDM`**. **[K]**
* **Parameters:** text, not expressions. `@1`…`@9` textual substitution;
  `@@1` substitutes the **evaluated** expression (`MACROS.MUS:326
  JSR TICKS@@1`); listing names after `MACRO` makes them usable as symbols
  (`FRED MACRO JOHN,BILL,JANE`). `[a,b,c]` brackets let one parameter contain
  commas. **[M]**
* **Limits:** 250 macros, nesting depth **3** in the 1.21 binary (the manual
  says 4; the error string says 3), no recursion, a macro may not shadow an
  existing mnemonic/pseudo-op. Local labels (`!1`) are scoped per expansion, so
  they are the only safe labels inside a macro. **[M] [K]**
* **EXITM:** early return from the current macro; also clears any open
  `IF`/`IFF`/`IFS` structures opened inside it. **[M]**
* **Emits:** exactly the body's bytes (none for a definition itself).
* **Corpus:** `MACROS.PDS:24-30 zvar`, `:184-191 incr` (IFS + label + ERROR),
  `MACROS.MUS:206-220 WRITE` (EXITM inside `IF`), `JONSBIT.MUS:53-55 DJ`
  (`ORG *+(@1)` space reservation). 107 MACRO/ENDM pairs, 2 EXITM.

### ASK — yes/no prompt → 0/1

* **Grammar:** `label ASK message` — **a label is mandatory**. Stops assembly on
  **pass 1**, prints `message (Y/N)?`; `Y` → label = 1, `N` → label = 0.
  Message upper-cased unless it starts with `'`. **[M]**
* **Emits:** nothing.
* **Corpus:** only commented out: `JONSBIT.MUS:4 ;gav_MASTER ASK "Master version`
  (replaced by `gav_master = 1` at line 6 — the standard way to make a build
  reproducible; do the same in a transpiler).

### QUERY — prompt for an expression

* **Grammar:** `label QUERY message`; label mandatory. Stops on pass 1, reads an
  expression (labels allowed) into the label. Upper-cases the message unless it
  starts with `'`. **[M]**
* **Emits:** nothing. No corpus use (manual example only).

### RADIX — default number base

* **Grammar:** `RADIX expression`, **2…16**, operand itself always decimal.
  Default 10. Affects unprefixed literals until changed. **[M]**
* **Emits:** nothing. No corpus use. A transpiler must either reimplement it or
  rewrite unprefixed literals.

### OPTION — undocumented

* **Grammar as seen:** `OPTION expr,expr` — `OPTION 0,0`
  (`JONSBIT.MUS:49`, `MACROS.MUS:25`) and `option 0,1` (`MUSIC1.MUS:1464`,
  inside the `if master=0` branch after `ORG $FFFA`/vector words).
* **Status:** **not documented in either manual**; semantics unknown. It is
  accepted by the assembler (these sources shipped). **[C]**
* **Emits:** nothing observable in the object stream (the surrounding data is
  contiguous).
* **Transpiler:** ignore it, but log a warning so an unexpected semantic is not
  silently lost.

---

## 4. Listing / reporting directives

**All of these emit no object code.** For a transpiler they are parse-and-drop
(they must still be *recognised*, because the corpus uses `LIST ON`/`OFF` at the
top of every bank file).

| Directive | Grammar | Effect | Corpus |
|---|---|---|---|
| `LIST` / `LST` | `LIST ON` \| `OFF` \| `MACRO` | screen listing on pass 2; `MACRO` toggles expanding macro bodies | `BANK12.PDS:5,7`, 10 uses |
| `LLIST` / `LLST` | same as `LIST` | same, but to the printer; `LLIST MACRO` is rejected (the toggle is shared) **[M]** | none |
| `PRINTER` | same grammar as `DB` | sends the bytes to the printer (escape sequences), not to the image | none |
| `SKP` | `SKP n` | `n` line feeds to the printer | none |
| `PAGE` | `PAGE` / `PAGE len(15-255)` / `PAGE width,len` / `PAGE "title` | form feed; set form length; set width+length; form feed + title | none |
| `EJECT` | `EJECT` | form feed (same as bare `PAGE`); `PAGE "title` = `EJECT`+`TITLE` **[M]** | none |
| `TITLE` / `TTL` | `TITLE text` | centred page title, upper-cased unless it starts with `'` | none (`MACROS.PDS:11 title equ 1` is a *label*, not this) |
| `SUBTITLE` / `STITLE` / `SUBTTL` | `SUBTITLE text` | top-left page sub-title | none |
| `WIDTH` | `WIDTH expr` | max line length; over-long lines split or truncated per `LISTOPT` bit 2048 | none |
| `LISTOPT` / `LSTOPT` | `LISTOPT expr` | **XOR**s `expr` into the 16-bit option word (initial 0) | none |

`LISTOPT` bits — all documented, none affect the object code:

| Bit | Effect |
|---|---|
| 1 | line numbers at the start of each line (restart at 1 per file) |
| 4 | time and date at the top of pages |
| 8 | version number at the top of pages |
| 16 | page number top right |
| 32 | page number bottom left; also form-feed + PDS start-of-file header |
| 64 | print headers for RAM source; small header when an include starts |
| 128 | print printer pseudo-ops (PAGE/TITLE/…) themselves |
| 256 | symbol table in PC order (else alphabetical) |
| 512 | drop `$`/`&` from PC values |
| 1024 | no paging, continuous listing |
| 2048 | truncate text at end of line |
| 4096 | same as `LIST MACRO` |
| 8192 | file number in the top right |
| 16384 | wrapped text gets 3 tabs instead of 1 space |
| 32768 | **global ignore**: ignore all list pseudo-ops, including further `LISTOPT`s, until another `LISTOPT` flips bit 15 |

Because the value is XORed, `LSTOPT 5` then `LSTOPT 1` equals `LSTOPT 4`;
`LISTOPT` starts at 0.

**Pass-behaviour evidence [K]:** in the 1.21 keyword table every printer
directive has the *stub* handler `2A17` on pass 1 and its real handler on pass 2
(`LISTOPT 2A17/38F4`, `PRINTER 2A17/3516`, `PAGE 2A17/37A0`, `TITLE`/`TTL`
`2A17/3764`, `SUBTITLE`/`STITLE`/`SUBTTL` `2A17/389E`, `WIDTH 2A17/3858`,
`SKP 2A17/38DA`, `EJECT 2A17/3754`, and `FREE 2A17/3A8A`). That is mechanical
proof that these directives do nothing at all on pass 1 — exactly what a
transpiler should do with them (nothing). `LIST`/`LST` (`2CA0`) and
`LLIST`/`LLST` (`2D72`) use one handler on both passes.

---

## 5. Download / IO directives

### SEND — choose the download destination

* **Aliases:** `.DLOAD`, `.DOWNLOAD` **[M]**. 1.21 has `DLOAD`/`DOWNLOAD`
  (`2F57/1269`, with `SEND`) and no dotted forms. **[K]**
* **Grammar:** `SEND destination`.
* **Destinations [M]:**

| Name | Meaning |
|---|---|
| `SERIAL` | serial port, 9600 baud |
| `SERIAL1` | serial, 19200 |
| `SERIAL2` | serial, 1200 |
| `SERIAL3` | serial, 300 |
| `COMPUTER0` | computer port 1, **nibble** protocol (BBC etc.) |
| `COMPUTER1` | computer port 1 |
| `COMPUTER2` | computer port 2 |
| `MSDOS` | **undocumented** — reported elsewhere as a file destination; not in either manual and **not exercised by this corpus**. Treat as unverified **[I]** |

* **Semantics:** selects the port used after assembly and causes the
  `Download (Y/N)?` prompt. While a `BANK` build is in progress, downloads are
  automatic on pass 2. **[M]**
* **Emits:** nothing into the image.
* **Corpus:** `MACROS.PDS:8 send computer1`, `ENDCODE.ROU:40 send computer1`,
  `JONSBIT.MUS:48 SEND COMPUTER1`. Always `COMPUTER1` — no evidence for the
  serial or nibble paths in this build.
* **Transpiler:** ignore (or map to a build step).

---

## 6. Undocumented directives found in the corpus

These behave as directives (accepted in the opcode column) but are not in either
supplied manual. `INCBIN`/`PATH`/`OPTION` are used by the corpus; `DEBUGSKIP`
comes from the 1.21 keyword table and is unused.

| Directive | Evidence | Behaviour | Status |
|---|---|---|---|
| `INCBIN file` | `MUSIC1.MUS:1434 incbin data3`; `CHRSETS.CHR:23 incbin hiscore.pp1`; `CHRSETS.CHR:64 titletopchrs incbin topchrs.pp1` | inserts the raw bytes of the file at the current PC; label on the line takes the first byte; no source parsing. Same family as `HEX` | **[C]** semantics obvious; pass behaviour unknown (assume both passes) **[I]** |
| `PATH dir` | `MACROS.PDS:22 path c:\nes\robin` | sets the default directory for later `INCLUDE`/`INCBIN` | **[C]**, semantics inferred from name **[I]** |
| `OPTION a,b` | §3 | unknown | **[C]** |
| `DEBUGSKIP` | 1.21 keyword table (`367C/1269`) | unknown; not in either manual, no corpus use. Name suggests a debug/skip switch. Pass 2 uses the same no-op handler as `SEND`/`SKIP` | **[K]** |
| project `FILE`/`COMMENT`/`CURCOLOUR`/`ASSEMBLER`/`WINDOW`/`CLOCK`/`project`/`asmflag` | `ROBIN.PRJ` | editor project file, **not** the assembler | **[C]** |

`INCBIN` is important: `CHRSETS.CHR` is the graphics-data builder for bank 14 and
uses it for every charset (`titletopchrs incbin topchrs.pp1`, …). A transpiler
must support it (`ca65: .incbin`) or the bank cannot be rebuilt.

---

## 7. Pass model (what a transpiler must reproduce)

| Phase | PDS behaviour |
|---|---|
| Pass 1 | evaluates everything, fills the symbol table, keeps `EQU`/`=` results, executes `ASK`/`QUERY` prompts, reads `INCLUDE`/`INCBIN` files, records `SKIP` blocks, records bank boundaries |
| Pass 2 | re-assembles, using pass-1 symbols for forward references; downloads banks automatically; prints the listing |
| Merge rule | `EQU` must produce the **same** value in both passes; `=`/`DEFL` is re-evaluated each time; `IF`/`IFS` need a pass-1-decidable condition (`IFF` is the escape hatch); `ORG new_pc` must be pass-1 computable |
| Stability | every data directive must emit an identical byte count in both passes; that is automatic for `DB/DW/DH/DL/DS/HEX/CBM/STRING` but *not* for `DO…UNTIL` (size depends on the evaluated PC) |

**Hard evidence from the 1.21 dispatch table [K]** (`pass1/pass2` handler
addresses, `docs/re/ledger/KEYWORDS.md`):

| Group | Directives | Meaning |
|---|---|---|
| one handler for both passes | `IF` `IFS` `IFF` `ELSE` `ENDIF` `DO` `LOOP` `UNTIL` `REPEAT` `BANK` `ORG` `EQU`/`EQUATE` `RADIX` `INCLUDE`/`FILE` `ERROR` `ENDM` `EXITM` `HEX` `CBM` `STRING` `DW`/`DEFW`/`DFW` `DH`/`DHIGH` `DL`/`DLOW` `LIST`/`LST` `LLIST`/`LLST` | pure assembly-time action; identical on both passes |
| different handler per pass | `DB` family `2AF3/2B34`, `DS` family `3040/307E`, `DC 321B/31DE`, `MACRO 3272/326A`, `END 2BAE/2B86` | for data directives **pass 1 emits the bytes** and pass 2 walks the same syntax advancing DI without storing (unless `[0x67D6]&0x40`, i.e. a BANK was seen, in which case pass 2 re-emits); `MACRO`/`END` are control-only |
| pass-1 stub `2A17` | `FREE` `LISTOPT`/`LSTOPT` `PRINTER` `PAGE` `TITLE`/`TTL` `SUBTITLE`/`STITLE`/`SUBTTL` `WIDTH` `SKP` `EJECT` | inert on pass 1, effective on pass 2 |
| pass-2 handler `1269` (no code) | `SEND` `DOWNLOAD` `DLOAD` `SKIP` `EXEC`/`START` `DEBUGSKIP` | configuration only, never emits bytes |
| pass-2 handler = `EQU` (`2E28`) | `ASK 357D/2E28`, `QUERY 30FD/2E28` | on pass 2 they behave exactly like an equate of the value captured on pass 1 — mechanical proof of the documented prompt-on-pass-1 behaviour |

Also from the same table: `JP` is an undocumented alias of `JMP`
(`170F/172E`), and there are **no** `OPTION`, `INCBIN`, `PATH`, `WORD`, `BLOCK`,
`DEFL` or `JENDM` keywords in 1.21 — consistent with those being 1.22+/1.26
additions (the corpus' `OPTION`/`INCBIN`/`PATH` prove the shipped build is not
1.21). Dotted forms **do** exist, but only in the non-letter table: `.BYTE`,
`.WORD`, `.EQU`, `.RADIX`, `.ASCII`, `.TEXT`, `.BLOCK`, `.ORG`, `.LIST`,
`.INCLUDE`, `.MACRO`, `.ENDM`, `.END`, plus bare `=`. This table is at file
`0x6ACE`; the 26-word A–Z bucket table at `0x7072` does not cover `.` or `=`.

---

## 8. PDS → ca65 mapping

| PDS | ca65 | Notes |
|---|---|---|
| `DB`/`DEFB`/`BYTE`/`EQUB`/`.BYTE`/`TEXT`/`ASC`/`STR`/`DEFM`/`DM`/`DFM` | `.byte` | direct; strings direct |
| `DC` | needs codegen | `.byte "ca"`, `'t' \| $80` per string |
| `DW`/`DEFW`/`WORD` | `.word` | direct, both little-endian |
| `DH` | needs codegen | `.byte >a,>b` (**ca65 `>` = high**) |
| `DL` | needs codegen | `.byte <a,<b` (**ca65 `<` = low**) |
| `DS`/`DEFS`/`BLOCK` | `.res n` / `.res n,fill` | PDS default fill is undefined → always emit an explicit fill |
| `HEX` | needs conversion | `.byte $xx,$xx,…` |
| `CBM` | needs codegen | per-char screen-code table (see §1) |
| `STRING` | needs codegen | `.byte "text",0` per string |
| `INCBIN` | `.incbin` | direct |
| `PATH` | `-I` include search path / build glue | |
| `EQU` | `NAME = expr` | ca65 permits redefinition, PDS does not — add a guard/comment |
| `DEFL` / `=` | `NAME .set expr` | direct |
| `ORG` | `.org` or segment in the linker config | PDS multi-region layout is better modelled with one `MEMORY` area per bank |
| `ORG new,true` | needs codegen | no ca65 equivalent; emit the block into a segment whose labels use the true base |
| `EXEC`/`START` | needs build glue | produce a symbol for the emulator/loader |
| `END` | needs build glue | drop; the file list ends there |
| `ERROR` | build-time assertion | fail the build with the same message |
| `FREE` | drop (optional size report) | |
| `IF`/`ELSE`/`ENDIF` | `.if`/`.else`/`.endif` | direct, but forward refs must be resolved by the transpiler first |
| `IFF` | needs codegen | "operand is a forward reference" has no ca65 analog |
| `IFS` | needs codegen | string compare of macro args |
| `DO n`…`LOOP` | `.repeat n` … `.endrep` | syntactic expansion (block form) |
| `DO`…`UNTIL` | needs codegen | PC-dependent size; expand at transpile time |
| `REPEAT n` | `.repeat n` + next line + `.endrep` | |
| `SKIP` | drop | no-op |
| `BANK` | needs build glue | one segment/file per bank, `$37` padding to 16 KiB |
| `INCLUDE`/`FILE` | `.include` | direct |
| `MACRO`/`ENDM` | `.macro`/`.endmacro` | `@n` → named params; needs rewriting |
| `EXITM` | `.exitmacro` | direct after rewriting |
| `ASK`/`QUERY` | `.define`/build config | never prompt in a transpiler |
| `RADIX` | needs preprocessing | ca65 has no radix switch |
| `OPTION` | drop + warn | unknown semantics |
| `LIST`/`LISTOPT`/`TITLE`/`PAGE`/`EJECT`/`WIDTH`/`SKP`/`PRINTER`/`LLIST` | drop | listing only |
| `DEBUGSKIP` | drop + warn | undocumented; unused in corpus |
| `SEND` | drop | build step |
| `*` (PC) | `*` | direct |
| `<expr` (high) | `>expr` | **swap** |
| `>expr` (low) | `<expr` | **swap** |
| `expr [lo,hi]` | drop or `.assert` | |
| `!` (OR) | `\|` | |
| `~` (XOR) | `^` | |
| `&` (AND) | `&` | same |
| `"a"` as a number | `'a'` | ca65 char constant |
| `!label` local labels | `@label` / `.scope` | needs renaming |
| `$80` / `&80` / `%1010` | `$80` / `%1010` | `&` must be rewritten to `$` |

---

## 9. Worked byte-level examples

All verified against the manuals, and where possible against the ROM images.

**1. Bank free-space header** — `BANK12.PDS:2-6`, `B12 = $C000-$BFFE = 2`:

```
BANK12 DEFB <B12,>B12      ; < = high byte, > = low byte, B12 = 2
                           -> 00 02
```
Matches the last two bytes of `ROBINV7.BC` (`… f8 00 02` at `$BFFE`). **[B]**

**2. High/low tables** — `DH 65500,23,500` → `FF 00 01`; `DL 65500,23,500` →
`DC 17 F4`. **[M]**

**3. Bit-7 terminated message** — `DC 2,"cat",13,"i"`:

```
02        2
63 61 74  "cat"  (63='c', 61='a')
F4        't'=$74 | $80
0D        CR
69        'i'
E9        'i'=$69 | $80
```

**4. Zero-terminated** — `STRING 13,"Cat","dog"`:
`0D 43 61 74 00 64 6F 67 00`. **[M]**

**5. Screen-code text** — `cbm "PRESS"` (`HISCORE.ROU:393`) → `10 12 05 13 13`,
found at `ROBINV7.BD` offset 6957. **[B]**

**6. Generic data** — `DB "AB",-1` → `41 42 FF`;
`DW "ab",$1234` → `61 62 34 12`;
`HEX 0e0080` (`CHRSETS.CHR:17`) → `0E 00 80`.

**7. Generated table** — `TIMINGS.ROU:3-8`:

```
count = 0
times16lo do 216
    defb >count          ; > = LOW byte
count = count+16
    loop
```
emits 216 bytes: `00 10 20 30 …` (`count` = 0,16,32,…), i.e. a low-byte
lookup table. `times16lo` = `$8000`-relative start address.

**8. Full bank shape** — reconstructed from `VARS.PDS`, `BANK12.PDS`,
`MAPDATA.DAT` (source order, `BANK8.PDS` disabled by `ROBIN.PRJ:7`):

```
VARS.PDS:242      org &8000          ; PC=$8000, bank not yet committed
MAPDATA.DAT:5     blkstl HEX 0001…   ; HEX+DEFB+DEFS = 16,382 bytes total
BANK12.PDS:2      ED12               ; ED12 = end PC
BANK12.PDS:3      b12 equ &c000-ED12 ; free bytes
BANK12.PDS:6      BANK12 DEFB <B12,>B12
BANK12.PDS:14     bank 12            ; commit everything above as bank 12
BANK12.PDS:16     org &8000          ; next segment (music) starts at $8000
```

---

## 10. Implementation checklist

1. **Lexer** — labels only in column 1; exactly one label-terminator char;
   `;` comment (respect quotes); `*` in column 1 = comment; case-fold everything
   except string literals and `'`-prefixed messages.
2. **Expression evaluator** — PDS precedence, `& ! ~` operators, mod-65536
   arithmetic, **`<`=MSB / `>`=LSB**, char literals `"a"` = `$61`, `*` = PC,
   `[lo,hi]` range checks.
3. **PC model** — insertion PC + optional true PC (labels/`*`); `ORG` resets;
   `ORG` also starts a new emitted block.
4. **Data emitters** — byte/word order, string packing (DB one byte per char,
   DC last char `|$80`, STRING trailing `$00`, CBM screen codes, DW 1–2 char
   strings as words), fixed width in both passes.
5. **Passes** — two passes, pass-1 prompts, `EQU` stability check, forward-ref
   rule for `IF`, `IFF` = "has forward ref", `IFS` = string set match.
6. **Repetition** — `DO…LOOP` (evaluate once), `DO…UNTIL` (re-evaluate, PC
   dependent), `REPEAT` (next line only), `LOOP` clears local labels.
7. **Macros** — `@1..@9` text, `@@1` evaluated, named params, `[a,b]` bracket
   escaping of commas, `EXITM`, expansion depth 3 (manual says 4; the 1.21
   binary's error text says 3), no recursion, scoped `!` labels.
8. **Banks** — buffer bytes since the previous `BANK`; on `BANK n` commit the
   buffer as bank `n`, write `$37`-padded 16 KiB image, optionally emit the
   jump-to-start record, then **require** an `ORG`; disable skip.
9. **Download/output** — per-ORG records, `$B3` pad / `$B4` download /
   `$B5` execute / `$B7` select-bank; `SEND` chooses the port (see ledger).
10. **Ignore list** — all listing directives, `SKIP`, `FREE`, `SEND`, `OPTION`
    (warn), project-file directives.
11. **Fail loudly** — never silently accept an unknown opcode in columns ≥ 2: the
    corpus relies on user macros (`DJ`, `zvar`, `changebank`, …) and a typo in a
    directive name looks exactly like an undefined macro.
12. **Pick a target version.** The alias sets differ: 1.21 has no `OPTION`,
    `INCBIN`, `PATH`, `WORD`, `BLOCK`, `DEFL` or `JENDM`, but the corpus uses
    `OPTION`/`INCBIN`/`PATH`. Dotted aliases (`.BYTE`, `.WORD`, `.ORG`, `.MACRO`
    …) **do** exist in 1.21 via the non-letter table. Transpile against the union
    seen in the corpus, and reject the manual-only aliases (`WORD`, `BLOCK`,
    `DEFL`, `JENDM`) if bit-exactness with this build matters.

### Accepted-but-unknown inventory

| Token | Where | Resolution |
|---|---|---|
| `SUB` | `START.ROU:34` | user macro `sub` in `MACROS.PDS:504` (answers the ledger's open question — not a 6502 mnemonic) |
| `DJ`, `ZVAR`, `VAR`, `DEFSPR`, `CHANGEBANK`, `ADD`, `ADD16TOVAL`, `MOVE.W`, `DECR`, `LDXY`, `NEGA`, `BLACKANDWHITE`, `WAITFORSTART` | corpus | user macros (`MACROS.PDS`, `MACROS.MUS`, `JONSBIT.MUS`) |

---

## 11. Open questions (for the ledger)

1. Exact `*` resolution inside `ORG`'s first operand when a true PC is active
   (see ORG; `CMLOGO.ROU:2745-6` vs the manual's `ORG *-$100+$8000` example).
2. `OPTION a,b` semantics (all three corpus uses are `0,0` or `0,1`).
3. Whether the trailing `DEFB <free,>free` marker is part of the committed bank
   image: present in `ROBINV7.BC`, absent at the computed offsets in
   `.BD`/`.BE`.
4. `INCBIN` pass-2 behaviour (whether the file is re-read or the pass-1 bytes
   are reused) — relevant only for build reproducibility.
5. PDS 1.21 vs 1.26 directive differences (e.g. whether `OPTION`, `INCBIN`,
   `PATH` exist in both).
