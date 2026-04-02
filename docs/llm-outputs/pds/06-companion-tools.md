# PDS companion tools and data formats

Volume 6 of the PDS reverse-engineering set. This volume covers the binaries and
data files that sit around the assembler: the NES character-set packer and its
target-side unpacker, the `HEX`-to-binary converter, the ARC extractor shipped
with the PDS distribution, the per-target download stubs (`.DL0/.DL1/.DL2`) and
the two help databases.

Confidence tags follow the rest of the series:

* **[C]** — read directly from the supplied binary or source (disassembly,
  strings, hexdump, source text);
* **[O]** — observed by running the real tool / decoding the real data;
* **[I]** — inference or interpretation, not directly proved;
* **[U]** — unverified / open; do not rely on it.

The short version: only `PP1PACK` and `HEX2BIN` matter for a reproducible build.
`PP1UNPAK` is not a host tool at all — it is target-side 6502 code that unpacks
`PP1` data into NES CHR RAM at runtime. `ARCE` is a third-party ARC extractor.
The `.dl*` files are target-side downloader **sources** for the original PDS
hardware link. `help.65`/`help.z80` are editor help databases.

---

## 0. Toolchain map and inventory

| File | Kind | Role | Needed to rebuild the ROM? |
|---|---|---|---|
| `PP1PACK.EXE` | DOS MZ, Turbo Pascal 3 | Packs NES 2bpp tiles into `.PP1` | Only if regenerating `.PP1` assets |
| `PP1UNPAK` / `UNPACK.ROU` | ASCII 6502 source | Target-side `.PP1` decoder | The code is part of the game; the file is reference |
| `HEX2BIN.COM` | DOS COM, Turbo Pascal 3 | Extracts `HEX` lines to a raw `.BIN` | Useful for asset extraction, not the game build |
| `ARCE.COM` | DOS COM, third-party | Extracts `.ARC` archives | No |
| `*.dl0/.dl1/.dl2` | ASCII target source | PDS hardware downloader sources | No — documentary only |
| `help.65` | ASCII | 6502 instruction reference | No |
| `help.z80` | binary/text mix | Z80 instruction reference | No |

| File | Size | SHA-256 (first 16 hex) |
|---|---:|---|
| `pds_src/src/HEX2BIN.COM` | 13,128 | `c825794facc90a5d` |
| `pds_src/src/PP1PACK.EXE` | 9,696 | `3ca5c942fb78b001` |
| `pds_src/src/PP1UNPAK` | 3,447 | `d23518ca74ae37c2` |
| `PDS_executables.zip:arce.com` | 5,710 | `5f6ef955760587a6` |
| `PDS_executables.zip:help.65` | 28,160 | `f4d3fe226b1edb2e` |
| `PDS_executables.zip:help.z80` | 23,230 | `b56859b4c26cc099` |
| `amstrad.dl0/.dl1/.dl2` | 2,477 / 5,276 / 5,079 | `25c89919…`, `d0deb339…`, `f682cfd3…` |
| `bbc.dl1` | 1,710 | `fc1a5bc039eb3108` |
| `c64.dl0/.dl1/.dl2` | 1,845 / 3,673 / 5,392 | `e1697d13…`, `d190a121…`, `0252fe66…` |
| `makec64.dl1` | 8,351 | `5941e1ed467b7ca5` |
| `spec.dl0/.dl1/.dl2` | 3,294 / 5,950 / 5,055 | `b4d172ff…`, `47638730…`, `802fe96d…` |

Corrections to the task brief:

* `HEX2BIN.COM` is **13,128** bytes, not 12,128 **[C]**.
* `PP1UNPAK` has **no executable form**: it is 3,447 bytes of PDS-format 6502
  source with local labels (`!T0`), `STXY`, `SETBANK`, `HEX ...;comment`,
  `EQU`, and a trailing `PP1_SIZE EQU *-PP1_DOWNLOAD3` **[C]**. It is the
  template that was pasted into the game as `UNPACK.ROU` (the game copy only
  replaces the mapper glue) **[C]**. There is no DOS-level input/output
  convention; its API is the 6502 entry-point contract in §2.7.
* The `.dl*` files are **PDS assembly source**, not target binaries: they use
  `ORG`, `SEND COMPUTER1`, `!local` labels and `&` hex, and are meant to be
  assembled and downloaded to the target machine **[C]**.

Tooling used:

```
strings -a -t x <file>                     xxd [-s off] [-l len] <file>
ndisasm -b16 -o 0x2cb0 -e 0x2bb0 HEX2BIN.COM    # user code of the TP3 .COM
file <file>; sha256sum <file>
dosbox 0.74-3 (headless under Xvfb, screenshots via ImageMagick import)
python3 docs/re/tools/pp1dec.py
```

The DOSBox runs used an 800×600 Xvfb display and XTest key injection to get
past the "press any key" prompts; all quoted program output is from screenshots
of the real tools.

---

## 1. The `PP1` character-set format

### 1.1 What it stores

A `.PP1` file is a **lossless, bit-packed set of 8×8 2bpp NES tiles**. One raw
tile is 16 bytes: 8 bytes of bit-plane 0 (one bit per pixel, MSB = leftmost)
followed by 8 bytes of bit-plane 1 — exactly the `$0000`/`$1000` CHR layout.
All 15 `.PP1` files in `pds_src/src` decode to whole tiles; 12 of them are
`INCBIN`ed verbatim into bank 14 in exactly the `CHRSETS.CHR` order
(`HISCORE, TOPCHRS, BOTCHRS, ROBINCHR, BASECHR, BEADCHR, BOXCHR, ARCHCHR,
ROCKCHR, BEDCHR, DOORCHR, OKCHR`), see `07-source-corpus-inventory.md` §7.5
**[O]**. `CMLOGO.PP1` is not the shipped logo revision; `SOLIDCHR.PP1` is a
one-tile packer test vector.

At run time `UNPACK.ROU` carries a `compactedchrstable` of
`(address, start-char, bank|128)` records and calls `PP1_UNPACK` for each set
**[C]**. The packed bytes are never expanded on the PC side; the NES expands
them straight into `$2007` (PPU data port) while the VRAM address is already
set.

### 1.2 Container layout

```
offset  size   meaning
------  -----  --------------------------------------------------------------
0       1      character count; 0 means 256 chars
1..     var.   bitstream, MSB-first: bit 7 of each byte is consumed first
```

Output size is always `count * 16` bytes (count 0 → 4096). Any unused trailing
bits in the final input byte are ignored by the decoder **[O]**.

The bit reader is a normal MSB-first reader implemented in the 6502 code with a
sentinel: `TEMP2` starts at `$80`; `ASL TEMP2` returns the old bit 7, and when
the register becomes 0 the next byte is loaded and stored as `(byte<<1)|1`. The
stored 1 reaches bit 7 after exactly eight shifts, triggering the next reload
**[C/O]**. There is no extra ninth bit per byte.

The end-of-source comment `PP1_SIZE EQU *-PP1_DOWNLOAD3` (`;341+30`) is a
source-size note, not part of the data format **[C]**.

### 1.3 Per-character header and "groups"

For every character the stream starts with one bit:

| bit | meaning |
|---:|---|
| 1 | reuse the previous header (continue the current group) |
| 0 | a new header follows; this starts a new group |

The **first character of a file must start with 0**. PP1PACK reports the number
of `0` header bits as "# of groups" (verified: BOXCHR = 7, BASECHR = 64,
CHRSET = 1, ROBINCHR = 106) **[O]**.

A header defines a **four-colour transition model** (four colours, indexed
`c = 3, 2, 1, 0`; colour = the two pixel bits, plane 1 = bit 1):

```
type[c] : 2 bits
  type 0 : nothing else. Colour never changes (no bits per pixel).
  type 1 : fol1[c] = T1(c)
  type 2 : v = T3(c); then 1 bit: if 1, fol2[c] = v
  type 3 : fol3[c] = T3(c)
```

`T3(c)` also sets `fol1[c]` and `fol2[c]` as side effects (the fold chains are
built recursively). Helpers:

```
T1(c):  1        -> FC1[c]
        0 1      -> FC3[c]
        0 0      -> FC2[c]

T3(c):  v = T1(c)
        fol1[c] = v
        fol2[c] = LO[v][c]
        return HI[v][c]
```

Fold tables exactly as assembled (`;` starts a comment, so `FC3` is three bytes
and `FC2` three bytes; the fourth entry each reader sees is the first byte of
the *next* table because the tables are contiguous in memory — this overlap is
part of the format) **[C/O]**:

| table | bytes at `[c=0..3]` |
|---|---|
| `FC1` | `01 00 00 00` |
| `FC2` | `02 02 01 01` (4th byte = `FC1[0]`) |
| `FC3` | `03 03 03 02` (4th byte = `FC2[0]`) |
| `F0L`, `F0H` | `FC2`, `FC3` |
| `F1L`, `F1H` | `02 FF 00 00`, `FC3` |
| `F2L`, `F2H` | `FC1`, `03 03 FF 01` |
| `F3L`, `F3H` | `FC1`, `FC2` |

`FF` marks impossible combos; valid files never select them, so a decoder only
meets `FF` on corrupt data **[O/I]**.

### 1.4 Per-row coding

After the header, each character has exactly 8 rows. For each row:

| field | bits | meaning |
|---|---:|---|
| repeat | 1 | 1 = copy the previous row's two plane bytes; 0 = decode a row |
| first pixel | 2 | colour 0–3, literal |
| transition ×7 | 0–3 each | next colour, given the *current* colour's type |

`TEMP4`/`TEMP5` (the two plane bytes) are **not reset between characters**, so
a repeat bit on row 0 of a character copies row 7 of the previous character.
Real files use this (a decoder without persistent state fails on every
multi-character set) **[O]**.

Transitions (current colour `c`, `typ = type[c]`):

| type | bits | action |
|---|---|---|
| 0 | none | stay `c` |
| 1 | `1` | stay |
|   | `0` | `c = fol1[c]` |
| 2 | `1` | stay |
|   | `0 1` | `c = fol2[c]` |
|   | `0 0` | `c = fol1[c]` |
| 3 | `1` | stay |
|   | `0 1` | `c = fol1[c]` |
|   | `0 0 1` | `c = fol3[c]` |
|   | `0 0 0` | `c = fol2[c]` |

Packing (from `PP1UNPAK`, mirrored by every decoder):

```
TEMP4 = first_pixel
TEMP5 = (first_pixel >> 1) | 2      ; the |2 is the 7-step sentinel
repeat 7 times:
    c = <transition from current colour>
    TEMP4 = (TEMP4 << 1) | (c & 1)         ; plane 0 bit
    TEMP5 = (TEMP5 << 1) | ((c >> 1) & 1)  ; plane 1 bit
```

The `|2` sentinel makes the ROL carry set on exactly the seventh transition, so
the hardware loop always runs 8 pixels without a separate counter. The bytes are
in natural left-to-right order: `TEMP4` bit 7 = pixel 0 … bit 0 = pixel 7.

After 8 rows the character is emitted as:

```
8 × TEMP4 (plane 0, rows 0..7)
8 × TEMP5 (plane 1, rows 0..7)
```

The 6502 code writes each `TEMP4` immediately to `$2007`, buffers the eight
`TEMP5` values in `PP1_ZBUF`, then writes them in row order **[C]**.

### 1.5 Decoder, validation, and the shipped script

`docs/re/tools/pp1dec.py` is a dependency-free decoder derived from
`PP1UNPAK`; it mirrors the bit reader, header, fold tables and row loop exactly,
and has a built-in self-check:

```
$ python3 docs/re/tools/pp1dec.py --selfcheck
selfcheck ok
$ python3 docs/re/tools/pp1dec.py pds_src/src/OKCHR.PP1 -o /tmp/ok.raw
pds_src/src/OKCHR.PP1: 11 bytes, 1 chars, 11/11 bytes consumed -> 16 bytes raw
$ cmp /tmp/ok.raw pds_src/src/OKCHR.CHR && echo identical
identical
$ xxd -p /tmp/ok.raw
ffffffffffffffff9f6f6a6a99fafaff
```

**Round-trip proof.** Every `.PP1` in `pds_src/src` was decoded, and the raw
output was fed back through the real `PP1PACK.EXE` under DOSBox; all 14
non-trivial files reproduce **byte-identical** `.PP1` output, and `SOLIDCHR`
equals the packer's output for 16×`FF` **[O]**:

| file | chars | packed | raw | consumed |
|---|---:|---:|---:|---|
| `OKCHR.PP1` | 1 | 11 | 16 | 11/11 |
| `SOLIDCHR.PP1` | 1 | 4 | 16 | 4/4 |
| `BOXCHR.PP1` | 9 | 46 | 144 | 46/46 |
| `BEADCHR.PP1` | 23 | 213 | 368 | 213/213 |
| `CHRSET.PP1` | 43 | 326 | 688 | 326/326 |
| `BEDCHR.PP1` | 66 | 549 | 1,056 | 549/549 |
| `DOORCHR.PP1` | 73 | 570 | 1,168 | 570/570 |
| `ARCHCHR.PP1` | 90 | 921 | 1,440 | 921/921 |
| `ROCKCHR.PP1` | 99 | 1,146 | 1,584 | 1,146/1,146 |
| `BASECHR.PP1` | 157 | 1,282 | 2,512 | 1,282/1,282 |
| `CMLOGO.PP1` | 157 | 1,412 | 2,512 | 1,412/1,412 |
| `HISCORE.PP1` | 200 | 1,402 | 3,200 | 1,402/1,402 |
| `BOTCHRS.PP1` | 245 | 2,201 | 3,920 | 2,201/2,201 |
| `TOPCHRS.PP1` | 245 | 2,193 | 3,920 | 2,193/2,193 |
| `ROBINCHR.PP1` | 256 (0) | 2,621 | 4,096 | 2,621/2,621 |

Sample raw output (`BASECHR`, first 64 bytes):

```
00000000: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000010: 0404 0404 0404 0402 0b0b 0b0b 0b0b 0300  ................
00000020: 2e2e 2e2e 2e2e 0c00 fefe fefe febe 1c08  ................
00000030: 0272 5252 5454 7404 0d15 3535 3333 130b  .rRRTTt...5533..
```

### 1.6 `PP1PACK.EXE` — invocation, output, limits

Turbo Pascal 3 MZ executable: 30-paragraph (480-byte) header, 111 relocations,
min alloc `0x07F7`, max alloc `0x11BB`, `SS:SP = 0937:1000`,
`CS:IP = 0000:021A` **[C]**.

Usage screen (screenshot, no arguments) **[O]**:

```
PP1PACK version 0.3-13/6/91 (c) Jon Menzies
Syntax - PP1PACK sourcename [destname]
This program intensively packs NES character sets.
No data will be written if 'destname' is omitted.
```

Rules, all observed **[O]**:

* `sourcename` is read as **raw 16-byte tiles**; length must be a multiple of 16
  and ≤ 4096. Exactly 4096 (256 chars) is accepted.
* With no `destname` it packs, prints the report, then prints
  `No destination file was specified.` and writes nothing (dry-run).
* A `destname` without an extension is used verbatim (`BXOUT`); no `.PP1` is
  appended. The tool never appends an extension.
* The destination is opened only at the end, after packing and statistics, so
  errors leave no file. `Writing packed data to …` is followed by `OK.` after a
  successful close.
* A zero-length source prints `Packing EMPTY.CHR... 0 characters.` and then
  does **not** terminate within 5 s (no output file) — treat 0 chars as
  unsupported **[O]**.
* Progress is `Packing <name>... <n> characters.`.

The report, from the real runs:

```
$ PP1PACK.EXE BS.CHR BSO.PP1
Packing BS.CHR... 157 characters.

# of groups = 64
Original size was 2512 bytes.
Predicted size was 1282 bytes.
Packed size is 1282 bytes (1230 bytes saved).
Percentage is 51.04% (48.96% saved).

Writing packed data to BSO.PP1...OK.
```

`Predicted size` always equalled the final packed size in every run (it is the
exact bit count rounded up); `Percentage = 100 * packed / original` with two
decimals, `saved = 100 - percentage` **[O]**.

Verified figures:

| input | chars | groups | packed | original | % |
|---|---:|---:|---:|---:|---:|
| `OKCHR.CHR` | 1 | 1 | 11 | 16 | 68.75 |
| `BOXCHR.CHR` | 9 | 7 | 46 | 144 | 31.94 |
| `CHRSET.CHR` | 43 | 1 | 326 | 688 | 47.38 |
| `BASECHR.CHR` | 157 | 64 | 1,282 | 2,512 | 51.04 |
| `ROBINCHR.CHR` | 256 | 106 | 2,621 | 4,096 | 63.99 |

Error paths (screenshots) **[O]**:

| situation | message |
|---|---|
| source > 4096 bytes | `Error - source file is too big! (max is 4096 bytes (256 chars))` |
| length % 16 != 0 | `Error - source file is not a whole number of characters long!` |
| missing source | TP3 runtime only: `Runtime error 002 at 0000:0376.` (no friendly message) |

**Packer strategy [I].** For each character the packer picks a transition model
(types/folds), and emits a new header only when reusing the previous one would
be larger — hence the "group" runs. The exact search/tie-breaking was not
reconstructed; it is not needed to decode, and re-encoding the decoded bytes
with the real tool is the only proven way to get identical `.PP1` output.

### 1.7 `PP1UNPAK` — the target-side API

`PP1UNPAK` (and the game copy `UNPACK.ROU`) define three entries **[C]**:

| entry | inputs | behaviour |
|---|---|---|
| `PP1_DOWNLOAD3` | pointer in `X`(lo)/`Y`(hi), bank in `A` | `STXY ADR1; TAX; JMP PP1_UNPACK` — switch to bank, unpack, restore bank |
| `PP1_DOWNLOAD2` | pointer in `X`/`Y` | `STXY ADR1`, then `X = $0D` (hard-coded bank placeholder) and fall into the decoder |
| `PP1_DOWNLOAD` | — | `LDX #$D` then the decoder (convenience wrapper) |
| `PP1_UNPACK` | `ADR1` = packed data, `$2007` address already set | writes 16 bytes per char |

Contract, as documented in the source comments and implemented:

* **In:** `ADR1` points at the packed set; `X` = bank number for the banked
  entry; the PPU VRAM address must already be set (the routine writes `$2007`
  only).
* **Out:** `ADR1` advanced past the consumed bytes; `TEMP8` = number of
  characters just unpacked. Clobbers `TEMP1..TEMP7`, `PP1_TYPES` (16 bytes),
  `PP1_ZBUF` (8 bytes), `ADR1`, `A/X/Y`.
* **Size:** `PP1_SIZE EQU *-PP1_DOWNLOAD3` with the author's note `;341+30`,
  i.e. roughly 371 bytes **[C/I]**.
* **Banking:** the standalone template does `LDA $8000 / PHA / SETBANK X` and
  restores with `PLA / SETBANK A`; the game copy replaces this with
  `bankno` + `changebankrou` and supports `PP1_DOWNLOAD3` with an explicit bank
  **[C]**.
* Count byte 0 means 256: `STA TEMP1; … / DEC TEMP1; BEQ done` runs the body
  first, so 0 → one pass plus 255 more. This matches PP1PACK's `0` for 256
  chars **[C/O]**.

In the released game the standalone `PP1UNPAK` is **not assembled**; its body is
pasted into `UNPACK.ROU` with the game's `ADR1`, `TEMP*`, `STXY` and
`SETBANK`/`CHANGEBANKROU` definitions. A transpiler must treat `UNPACK.ROU` as
the real source and `PP1UNPAK` as reference **[C]**.

### 1.8 Limitations / quirks checklist

* Count 0 = 256 (not empty). Do not "fix" it to empty.
* Header state and row bytes persist across characters; row 0 of char N may
  repeat row 7 of char N-1.
* Tables rely on contiguous layout (`FC2[3]` is `FC1[0]`, `FC3[3]` is
  `FC2[0]`); a clean reimplementation must copy the 4-byte effective arrays.
* `0xFF` in `F1L`/`F2H` marks impossible folds; valid files never select them.
* Header bit 1 = "reuse"; the first char must use 0.
* Unused tail bits of the last byte are ignored.
* PP1PACK hangs on a 0-byte input; it does not validate same source/dest.

### 1.9 What the transpiler/build pipeline needs

* `INCBIN *.PP1` is already a raw byte copy and needs **no** change: the shipped
  ROM contains the packed bytes, and `UNPACK.ROU` expands them on the NES.
* For asset tooling or tests, use `docs/re/tools/pp1dec.py` to obtain editable
  tiles; do **not** invent a new container, and if you must re-pack, use the
  original `PP1PACK.EXE` (or reproduce its header/group choice exactly, which
  is not yet specified).
* The only normative decoder is `PP1_UNPACK`; the script is a byte-exact
  equivalent (round-trip proved on all 15 repo sets).

---

## 2. `HEX2BIN.COM` — PDS `HEX` statements to raw binary

### 2.1 Identity

13,128-byte DOS `.COM` produced by Turbo Pascal 3 (Borland copyright string,
TP3 runtime at the start, user code at the end; the image starts with a jump
into the TP3 runtime). Author/version:
`HEX2BIN version 1.0-17/7/90 (c) Jon Menzies`.

### 2.2 Invocation and prompts

```
HEX2BIN source [target]
```

Screenshot with no arguments **[O]**:

```
Syntax - HEX2BIN source [target]
HEX2BIN version 1.0-17/7/90 (c) Jon Menzies
Converts file from PDS HEX statements to .BIN file
It will cope with commented-out bits but not with IFed-out bits!
All HEX statements must be in capitals!
```

Behaviour **[O]**:

* `target` default: the source name with its extension replaced by `.BIN`
  (`T1.TXT` → `T1.BIN`, `NOEXT` → `NOEXT.BIN`). An explicit target is used
  verbatim; no extension is appended.
* Source and target must differ (`Error - source and target files must be
  different.`) — checked *before* the confirmation prompt.
* It prints `Converting from <src> to <tgt>` and then
  `Press Ctrl-C to abort or any other key to proceed...`, and waits for a key.
  In a batch/CI setting this prompt must be suppressed or fed a key.
* The target is created (truncated) before conversion; if a later line fails,
  bytes already written stay in the file (e.g. a good line 1 followed by a bad
  line 2 leaves the 1 byte and aborts).
* On success it prints `Read <n> lines, wrote <m> bytes.` where `n` counts
  converted `HEX` statements, not physical lines.

### 2.3 Accepted line grammar (empirical)

The parser is much pickier than the PDS assembler. `HEX` must be **preceded by
a space or tab somewhere earlier on the line**; `HEX` in column 1 is ignored.
After the keyword exactly one space/tab is consumed and the *contiguous* run of
uppercase hex digits after it is converted; the run stops at the first
non-hex character (space, tab, `;`, comma, CR, …). There is no multi-token
syntax: `HEX 01 02` converts only `01`.

| line | output | note |
|---|---|---|
| ` HEX 0102030405` | `01 02 03 04 05` | canonical PDS style |
| `  HEX 02`, `\tHEX 03` | `02`, `03` | any amount of leading whitespace |
| `X HEX 0A`, `ABCD HEX 1` | `0A`, `1C`(odd) | any text before the whitespace |
| `HEX 01` (column 1) | — | ignored |
| `aHEX 01`, `abHEX 02` | — | no whitespace before `HEX` |
| ` HEXX 0C`, ` HEX0 0D` | — | `HEX` must be followed by space/tab |
| ` hex 01`, ` Hex 01` | — | keyword is case-sensitive |
| ` HEX  18` (two spaces) | — | second space becomes the data's first char |
| ` HEX 01 02`, ` HEX 01\t02` | `01` | space/tab terminates |
| ` HEX 01;02`, ` HEX 0E;0F` | `01`, `0E` | `;` terminates (comment) |
| ` HEX 01,02` | `01` | comma terminates |
| ` HEX 0a` | error | lowercase digit rejected |
| ` HEX 0G` | error | `G` not in the digit table |

Comment handling: a line whose first character is `*` is skipped; `;` starts a
comment; lines without an accepted `HEX` token are silently skipped (they are
not counted in "Read N lines").

### 2.4 Algorithm (from the disassembly)

The per-line converter is the procedure at file offset `0x2e5e` (address
`0x2f5e` in COM terms) and the pair loop at `0x2f69` **[C]**:

1. `readln` into a 128-byte Pascal string at `0x41b` (max 127 chars).
2. Increment the physical line counter.
3. If `line[1] = '*'` → skip.
4. Find the `HEX` token (`POS`); if absent, or at a position that fails the
   indentation rule, skip.
5. Extract the payload following `HEX ` into the line buffer (the separator
   character remains as position 1).
6. If the payload contains `;`, cut the comment.
7. If the payload's first character is a space or tab (the double-space case),
   produce nothing.
8. `n = Length(payload) div 2`; for `i = 1..n` read characters at offsets
   `2i` and `2i+1` (i.e. chars 2,3 then 4,5 …; **char 1 is skipped**).
   Convert each with `POS(char, "0123456789ABCDEF") - 1`; the byte is
   `hi*16 + lo`. If the result is negative → error.
9. Write the byte to the target; count a converted line.
10. At EOF print the summary.

Because `POS` returns 0 for a non-hex character, `lo = -1` and the expression
yields `hi*16 - 1` (a borrow into the high nibble) rather than an error,
*unless* the high nibble is also 0/not found, in which case the result is
negative and the run aborts. This explains the observed "bad digit" behaviour:
`0G` errors (`0*16-1 = -1`), while `1G` would silently produce `0x0F`
**[O/C]**.

Odd-length payloads read one byte past the end of the string inside the
128-byte line buffer, so the trailing byte is a stale character from the
original line. Reproducible but not a spec **[O]**:

| line | output |
|---|---|
| ` HEX 1` | `1E` |
| `ABCD HEX 1` | `1C` |
| ` HEX 1 ` (trailing space) | `0F` |
| ` HEX 123` | `12 2F` |
| ` HEX 12345` | `12 34 52` |
| ` HEX 54321` | `54 32 14` |
| `ABCD HEX 54321` | `54 32 1E` |

→ **Always emit an even number of hex digits per line.** The trailing-byte
values depend on stale buffer contents (they change with the prefix text and
payload length) and must not be relied on.

### 2.5 Messages (exact)

```
Syntax - HEX2BIN source [target]
HEX2BIN version 1.0-17/7/90 (c) Jon Menzies
Converts file from PDS HEX statements to .BIN file
It will cope with commented-out bits but not with IFed-out bits!
All HEX statements must be in capitals!
Converting from <source> to <target>
Press Ctrl-C to abort or any other key to proceed...
Read <n> lines, wrote <m> bytes.
Bad or missing hex digit at line <physical-line>:
<offending line>
Error - source and target files must be different.
```

The "All HEX statements must be in capitals!" line is part of the **usage
screen**, not an error message; lowercase `hex` lines are silently ignored
**[O]**.

### 2.6 Known limitations

* Requires a space/tab before `HEX`; a line beginning with `HEX` is ignored.
* Exactly one separator after `HEX`; a second space/tab makes the line a no-op.
* Only one contiguous run of digits per line; `HEX 01 02` loses `02`.
* Uppercase digits only; lowercase aborts the whole conversion at that line.
* Odd digit counts produce a garbage trailing byte (see above) — never do it.
* `;` comments are handled, but `IF`/`IFS`-ed-out blocks are not (`IFed-out
  bits` warning); the tool converts text, it does not assemble.
* 127-character line limit (Pascal string); longer PDS lines are truncated.
* Error reporting is a single pass: the first bad line aborts, leaving a
  partial target.
* No `HEX` line-length validation against the PDS 57-bytes-per-line limit.

### 2.7 What the pipeline needs

The transpiler should parse `HEX` itself, with the **assembler's** grammar
(spaces and tabs allowed between bytes, comments after `;`), not HEX2BIN's
restricted grammar. HEX2BIN is only useful as an oracle for the historical
`.BIN` files; if reproducing those byte-for-byte, remember it uses only the
first contiguous digit run and requires the indented ` HEX ` spelling.

---

## 3. `arce.com` — ARC extractor

5,710-byte DOS `.COM`, **ARCE 2.08 — Extract ARC files — 12/31/86**, by Vernon
D. Buerg and Wayne Chin (System Enhancement Associates); the strings include the
full SEA copyright and "You may copy and distribute this program freely…" **[C]**.

* Extract-only (no add/create commands). Usage string:
  `Usage:  arce d:path\filename.ext  [filespecs...] [d:\outpath] [/R][/P][/Q]`
  — `/R` reuse existing files, `/P` extract to stdout, `/Q` quiet; the archive
  extension defaults to `.ARC`; wildcards allowed; DOS 2.0+.
* Method names in its dispatch table: `extract`, `Extract`, `un-Pack`,
  `unSqueeze`, `uncrunch`, `unCrunch`, `Uncrunch`, `UnCrunch`, `unSquash`.
  Squash is recognised but reports `- WARNING: Squash method not supported!`;
  other messages: `- WARNING: file CRC does not match!`,
  `- premature EOF reading …`, `- CREATE failed.`,
  `archive format 7 not yet supported`, `=== Invalid archive format!`,
  `Not enough memory.`, `- file already exists. Overwrite it? (y/N)`.
* Distribution use: `dopds.bat` does `MD C:\PDS`, `COPY A:*.* C:\PDS`,
  `ARCE PDS`, `DEL ARCE.COM`, `DEL PDS.ARC`; the 1.26 read-me says
  "ARCE PDS will uncrunsh the PDS downloader source codes and help files"
  **[O]**. That is why the zip's `.dl*`/`help.*` are plain files: they came out
  of `PDS.ARC`.

Not executed here; the above is from strings/headers only. ARC's on-disk
container (13-byte header + method-specific data + `0x1A` EOF) was not needed
because the archive is already extracted in the zip **[U]**.

---

## 4. `.DL0/.DL1/.DL2` download stubs

### 4.1 Nature

These are **PDS assembly sources for the target machine**, not PC-side
binaries and not compiled stubs. Each file is a complete program with its own
`ORG`, `SEND COMPUTER1` directive (marks it as downloader software) and `END`.
They implement the target end of the PDS serial link: read a command byte,
perform it, loop. Sizes in comments are the assembled code sizes (e.g.
"180 bytes", "460 bytes", "114 bytes").

The PC sends the byte stream described in `05-banking-and-object-format.md`
and in manual §5.2 **[C/M]**. Protocol summary:

| byte | command | payload | reply |
|---:|---|---|---|
| `0xB3` (179) | padding | — | — (ignored; keeps blocks even) |
| `0xB4` (180) | download | start hi,lo; length hi,lo; data | — |
| `0xB5` (181) | execute | address hi,lo | — (JSR/JMP, returns to loop) |
| `0xB6` (182) | upload | start hi,lo; length hi,lo | data bytes |
| `0xB7` (183) | select bank | bank byte | — |
| `0xB8` (184) | send registers | — | 7-byte register block |
| `0xB9` (185) | get registers | 7-byte register block | — |
| `0xBA` (186) | trace | 3-byte instruction buffer | registers after execution |
| `0xBB` (187) | analyse | — | PC hi,lo where the interrupt occurred |

Addresses and lengths are big-endian (hi first); length 0 means 65536. The
register block order is `P, A, X, Y, S, PCl, PCh` (the C64 DL1 keeps an extra
byte for the `$01` bank latch). The link is a 4-wire handshake: one "data
valid" flag and one "received" flag; the target toggles its flag on every byte,
so both sides know the phase. The PC always sends a 179 pad before an odd-sized
command.

### 4.2 Per-platform files

| file | target | ORG | code size | entry points | commands | I/O / handshake |
|---|---|---:|---:|---|---|---|
| `c64.dl0` | C64 | `$8000` | 180 | `START` | B4,B5 | CIA1 `$DD00/$DD01`; flags bit 2 in / bit 3 out; `SEI`, `$01=$25`, `$DD02=$3B`, sprites/screen/volume off; no zero page |
| `c64.dl1` | C64 | `$8000` | 460 | `START`, `MONITOR`, `RUNIT` | B4,B5,B6,B7,B8,B9,BA | same ports; 8-byte `REG` (`P,A,X,Y,S,PCl,PCh,$01`); full trace/monitor |
| `c64.dl2` | C64 | `$C000` | 428 | `BEGIN`, `NEWIRQ`, `PDSSETUP`, `PDSMONITOR`, `!EXIT` | B4,B5,B6,B7,BB | IRQ-driven: `PDSSETUP` once, `PDSMONITOR` from the user IRQ (old vector saved at `$314/$315`); `EXEC $FCE2` cold start |
| `makec64.dl1` | C64 | `$8000` | 8,351 (file) | `BEGIN`, `SAVEIT`, embedded DL1 at `PDSCODE` | B4,B5,B6,B7,B8,B9,BA | master-disk builder (see §4.3) |
| `amstrad.dl0` | CPC | `8000h` | 114 | `START` | B4,B5,B7 | Z80 ports `FBEE/FBED`; `OUT (C)` handshake with `D` flag; `DI`; bank byte written to port `7Fxx` with the bank in `E` |
| `amstrad.dl1` | CPC | `8000h` | 374 | `START`, `MONITOR`, `RUNIT`, `UPLOAD1` | B4,B5,B6,B7,B8,B9,BA | same; 26-byte register block; direction swap via `FBED` |
| `amstrad.dl2` | CPC | `39000` | ~5 KB (file) | `PDSSETUP`, `MONITOR`, `INTR`, `EXIT` | B4,B5,B6,B7,BB | IM1 example hooks `(39h)`; `MONITOR` from the user IRQ, HL = interrupted PC |
| `bbc.dl1` | BBC Micro | `0` (relocatable) | 1,710 (file) | `START`, `MAINLOOP`, `GETBYTE`, `SENDBYTE` | B4,B5,B6 only | 6522 VIA `$FE60/$FE62`; **nibble handshake** (two 4-bit halves per byte, CB2 pulses); no bank/regs/analyse |
| `spec.dl0` | ZX Spectrum | `8000h` | 102 | `START` | B4,B5,B7 | Z80 ports `7F/3F/5F/1F`; `DI`; bank via `OUT (7FFDh)` |
| `spec.dl1` | ZX Spectrum | `8000h` | 344 | `START`, `MONITOR`, `RUNIT`, `UPLOAD1` | B4..BA | same; 26-byte register block; direction swap via `5F` |
| `spec.dl2` | ZX Spectrum | `0F000h` | ~5 KB (file) | `PDSSETUP`, `MONITOR`, `EXIT` | B4,B5,B6,B7,BB | IM2 demo: vector at `0FFF4h/0FFF5h`, ISR calls `MONITOR` |

All end with `SEND COMPUTER1` / `END`; `.DL0` is the "dumb" minimum (download +
execute), `.DL1` adds the monitor commands, `.DL2` is interrupt-driven and adds
analyse (187) **[C/M]**. Where a size is marked "(file)" the source comment
does not state the code size.

### 4.3 How `makec64.dl1` differs

`makec64.dl1` is not a downloader to run as-is; it is a **factory for a
bootable C64 PDS master**:

* It still starts with `ORG $8000` / `SEND COMPUTER1`, but the first bytes are
  an autostart cartridge signature (`DW BEGIN, DW BEGIN, DB $C3,$C2,$CD,"80"`),
  followed by a 25×40 title screen built from `HEX` lines ("PDS 1985-7" logo).
* `BEGIN` kills the autostart (`STX $8004`), copies the embedded downloader
  from `PDSCODE` to `ADDRESS` (`$200`, configurable), copies the title screen
  to `$0400/$0500/$0600` and colour RAM, sets border/background, and jumps to
  `ADDRESS`.
* `PDSCODE ORG *,ADDRESS` then contains the **entire `c64.dl1` source
  verbatim**, assembled at `$0200` instead of `$8000` — that is the whole
  difference in the downloader itself.
* `SAVEIT` (the program's `END` address) prints
  `PLEASE WAIT - MAKING A NEW PDS MASTER.`, calls the KERNAL
  (`$FFBA/$FFBD/$FFD8`), saves from `$8000` to `$86xx` as file `"D"` on
  `DEVICE` (8 disk / 1 tape), then `JMP $FCE2`.
* Practical consequence: the disk is `LOAD"D",8,1` and runs the downloader from
  `$0200`, with the title screen; the plain `c64.dl1` assumes the user loads it
  and jumps to `$8000`.

Everything else (command loop, ports, register block) is identical to
`c64.dl1`.

### 4.4 What the build pipeline needs

Nothing at assemble time: the downloaders are target-side programs from the
original distribution, not part of the Super Robin Hood build. They matter only
if the pipeline emulates the PDS download link: the command bytes, big-endian
framing, `0xB3` padding and the 7/26-byte register block above are the contract.
The sources also document `SEND` and PDS local-label syntax.

`c64warn.txt` repeats the compatibility note confirmed in volume 02:

> The PDS assembler for 6502 code uses the `>WORD` and `<WORD` expressions the
> other way around than most other 6502 assemblers, i.e. LSB and MSB are
> exchanged.

---

## 5. `help.65` and `help.z80`

These are the editor's help databases, not assembler inputs. The PDS editor
looks up a keyword and displays the matching topic.

### 5.1 `help.65` — plain DOS text

* 28,160 bytes, pure 7-bit ASCII, CRLF line endings, 1,595 lines, 656 blank
  lines **[O]**. There are two `0x1A` bytes at offsets 27,762–3 — but they sit
  *inside* the word “cycles” (`…\x1a\x1acles\r\n…`), and 396 more bytes of text
  follow. So this is a concatenated/mid-file-EOF artifact, not a clean DOS EOF;
  read the file as plain text to the end and ignore `0x1A`.
* Topic format: a line starting with `*` in **column 1**, immediately followed
  by the keyword (`*ADC`, `*AND`, …); the body follows. Entries are separated
  by blank lines and are in alphabetical mnemonic order. 58 keyword topics
  (flag-diagram lines such as `*    **` also begin with `*` and must not be
  mistaken for topics; require `^\*[A-Z0-9]{2,6}$`).
* Entry layout (from `*ADC`): mnemonic line, one-line synopsis
  (`ADC o<TAB><TAB><TAB>A = A + o + C`), blank lines, prose description, an
  operand/addressing table (`OPERAND / BINARY / HEX / CYCLES`) with tab stops,
  a cycle note, then `SV BDIZC` and a `**    **` flag mask line.
* The file is truncated mid-sentence at the end (`The old contents `), so the
  last topic (`*TYA`, repeated) is incomplete **[O]**.
* Rendering: read as text (CP437/ASCII), split on CRLF, index `*`-lines; wide
  tab stops (8 columns) are needed to reproduce the tables. `less`/`cat` works;
  an HTML renderer only needs to expand tabs and preserve blank lines.

### 5.2 `help.z80` — Z80 help file in a raw/CP/M-style buffer

* 23,230 bytes; **not** a plain text file: 1,405 CR (`0x0D`) line separators,
  **no LF**, 1,322 NUL bytes used as padding/record separators, 5 bytes with the
  high bit set, and a 128-byte binary prefix **[O]**.
* The prefix (`0x00–0x7F`) contains small binary structures: at `0x00`
  `03 00 05 02 00 00 BC 1B 00 00 AA 5A 6D 05 0C 12 1E 28 FF 01 58 01 5D 7F`,
  a table of `01 xx` pairs at `0x3F` (`01 03 01 06 01 09 … 01 1B`), the ASCII
  string `0000000000`, and more words at `0x70`. Its exact meaning is **not**
  established **[U]**; it looks like editor state/function-key/first-page
  metadata. A renderer should skip it (text effectively starts at `0x80`), but
  `0x100–0x1FF` contains `F0\0F1\0…F9\0` labels that belong to the help pages.
* Body: ordinary help text with `\r` as the line break and `\x00` as
  padding/record separator; topics are again `*KEYWORD` at the start of a line
  (`*ADC`, `*ADD`, `*CALL`, `*PDS`, `*CHR`, `*ASCII`, …). It includes PDS
  editor screen mock-ups (`;  PDS  v1.1 :0000:  (C) 1985/6 P.D Systems`,
  `File "Z80 Help file"`, `Version 00.56`) and Z80 instruction pages with
  ASCII-art timing diagrams (`+---------4--------+ +--7--+ +-----19----+`).
* `0x5AAA` contains `0x93`, a leftover display/attribute byte inside the text
  (`…position 1.\r\x93\r\r`); the other high bytes are in the prefix
  (`0x06=0xBC`, `0x0A=0xAA`, `0x12=0xFF`, `0x70=0xBE`).
* The file ends with the "no help" text:
  `Sorry no help available.` / `Please add a new topic to this help file` /
  `by putting the keyword after a '*' in` / `character position 1.` — which
  confirms the topic convention shared with `help.65`.
* Rendering recipe: drop/ignore `0x00–0x7F`; decode the rest as ASCII, treating
  both `0x0D` and `0x00` as line breaks, collapsing empty runs, and replacing
  `0x93` with a space. That reconstructs readable pages; the topic index is
  `^\*[A-Z0-9]{2,6}` after normalisation.

### 5.3 What the pipeline needs

Nothing: neither help file is referenced by the assembler or by the game build.
They matter only for reproducing the PDS *editor* experience. If a tool wants
to index them, the `*KEYWORD` convention above is the whole format; `help.65`
is directly readable, `help.z80` needs the CR/NUL normalisation.

---

## 6. What a modern rebuild needs

For a reproducible, emulator-runnable ROM the companion tools split cleanly:

1. **No host-side packer is required** if the checked-in `.PP1` assets are
   reused. `INCBIN` them verbatim.
2. **A `HEX2BIN` replacement is not required** either: the transpiler already
   has to parse `HEX` to assemble the source, and it must do a better job than
   `HEX2BIN` (conditional evaluation, macros, labels).
3. **`PP1UNPAK` is runtime code.** Keep `UNPACK.ROU` and its `CHANGEBANKROU`
   helpers in the translated source; do not replace it with a build-time
   converter unless the game's bank layout is also changed.
4. **`ARCE` and the `.dl*` sources are documentary.** They do not belong in the
   build.
5. **`HEX2BIN` semantics are a warning, not a specification**: its inability to
   handle `IF` is exactly the kind of shortcut a transpiler must not copy.

Asset manifest relevant to this volume:

| Asset | Use | Mode |
|---|---|---|
| `*.PP1` | packed CHR loaded by `PP1_UNPACK` | binary `INCBIN` |
| `CHRSETS.CHR` | direct CHR data (byte-exact in `.BE[2922:16082]`) | binary `INCBIN` |
| `ROBINV7.BC/.BD/.BE/.BF` | reference bank images | test oracle only |

---

## 7. `INCBIN` and the PDS revision question

`INCBIN` is used by the released corpus but is **not** in the 1.21 keyword
table. The same is true of `OPTION` (`MACROS.MUS:25 OPTION 0,0`) and `PATH`
(`MACROS.PDS:22 path c:\nes\robin`). Consequences:

* The shipped source was built with a **later PDS** than the 1.21 binary
  analysed in volumes 01–05/08, or those lines live in macros that are never
  expanded (they do not: `CMLOGO.ROU:2390` is a top-level `incbin`).
* A transpiler must implement `INCBIN` (read a file, append its bytes at the
  current PC), `OPTION` (at least parse and ignore/record it), and `PATH`
  (resolve include/incbin paths), even though 1.21 does not.
* `INCBIN` has no download framing of its own: it contributes bytes to the
  current `ORG` block exactly like `DB`, and `BANK` commits them.

This is a compatibility requirement, not an optional extension. See volume 09
§8.

---

## 8. Reproduction commands

```sh
# hashes / types
sha256sum pds_src/src/HEX2BIN.COM pds_src/src/PP1PACK.EXE pds_src/src/PP1UNPAK \
          /tmp/opencode/pds/arce.com /tmp/opencode/pds/help.65 /tmp/opencode/pds/help.z80

# HEX2BIN
unzip -o docs/manuals/PDS_executables.zip -d /tmp/opencode/pds
cp pds_src/src/HEX2BIN.COM /tmp/opencode/pds/hex/
# in DOSBox: HEX2BIN T.TXT T.BIN  (answer the "any key" prompt)

# PP1 decode / round-trip
python3 docs/re/tools/pp1dec.py --selfcheck
python3 docs/re/tools/pp1dec.py pds_src/src/BASECHR.PP1 -o base.raw
# then: PP1PACK.EXE base.raw base.PP1  and compare with pds_src/src/BASECHR.PP1

# headless DOSBox (0.74-3) for screenshots
Xvfb :77 -screen 0 800x600x24 &
DISPLAY=:77 dosbox -c "mount c /tmp/opencode/pds/dos" -c "c:" \
  -c "PP1PACK.EXE OKCHR.CHR OUT.PP1"
DISPLAY=:77 import -window root shot.png
```

The DOSBox keyboard prompt was satisfied with an XTest `Return` injection; a
plain `-c "exit"` would run the program but skip the prompt.

---

## 9. Verification performed

* `PP1UNPAK` header/equates and control flow read from the 3,447-byte ASCII
  source; its body matches `UNPACK.ROU:75+` **[C]**.
* Bit-level decoder implemented in `docs/re/tools/pp1dec.py`, self-checked
  against `OKCHR.PP1`/`OKCHR.CHR`, and round-tripped through the real
  `PP1PACK.EXE` for all 15 repo `.PP1` files (14 byte-identical re-packs plus
  the `SOLIDCHR` vector) **[O]**.
* `PP1PACK.EXE` usage/limits/statistics and error messages observed in DOSBox
  (screenshots): 4096-byte limit, 16-byte multiple, 0-byte hang, group counts,
  percentage formula **[O]**.
* `HEX2BIN.COM` grammar probed with ~40 one-line source files: indentation rule,
  one-run-per-line rule, lowercase rejection, odd-length behaviour, default
  `.BIN` naming, same-file check, partial-output-on-error **[O]**; pair loop
  read at `0x2f69` **[C]**.
* `ARCE.COM` banner/usage/strings read from the 5,710-byte COM **[C]**.
* `.dl*` sizes, `ORG`s, entry points, command bytes and handshakes read from
  the extracted sources **[C]**; protocol cross-checked against manual §5.2
  **[C/M]**.
* `help.65`/`help.z80` byte statistics, topic convention and rendering rules
  derived from the files themselves **[O]**.

No claim is made that `PP1PACK`'s encoder is byte-reproducible; only that its
output format is decodable by `PP1_UNPACK` and that decoded data re-packs
identically with the original tool. No claim is made that the `.dl*` sources
cover every PDS target or every handshake variant.

---

## 10. Open questions

1. **`PP1PACK` header search.** The exact objective and tie-breaking used to
   pick a group header are not reconstructed. Re-encoding with the original
   tool is the only proven way to reproduce a `.PP1`; a compatible but
   different encoder would still decode identically.
2. **`PP1UNPAK` size.** `PP1_SIZE` comment says "341+30"; the assembled length
   depends on the `SETBANK`/`STXY` macro expansion and was not measured.
3. **HEX2BIN odd-length mechanism.** The "stale byte after the string" model
   explains the observed values for the tested prefixes but was not proved for
   every case (the exact offsets depend on TP3's `Copy`/`Delete` runtime calls
   at `0x11cc/0x133f/0x11fb/0x138d`). Treat odd counts as undefined.
4. **`help.z80` prefix.** The 128-byte header and the `0x93` byte were not
   decoded; the rendering recipe treats them as opaque.
5. **ARCE container details.** Only strings/usage were inspected; the actual
   `PDS.ARC` was not extracted with it here (the zip already contains the
   results).
6. **C64 `makec64.dl1` save range.** The `$FFD8` arguments were read from the
   source but the exact `$86xx` end and its hardware behaviour were not
   confirmed.
