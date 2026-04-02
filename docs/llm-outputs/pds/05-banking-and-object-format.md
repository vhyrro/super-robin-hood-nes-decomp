# 05 — Banking, object format, and reproducing the original build

Evidence tags used throughout:

- **[D]** documented in `docs/PDS_6502_Manual.md` (the 6502 manual).
- **[O]** observed directly in this repository: source text, bank images
  `pds_src/src/ROBINV7.BC/.BD/.BE/.BF`, the supplied DOS binaries, the ROM.
- **[I]** inferred (reasoning stated; not directly provable from the shipped
  material).

The source tree is the *Quattro Adventure* release of the Super Robin Hood
source (see `pds_src/README.md`). The only NES image in the repo is
`Quattro Adventure.nes`; Super Robin Hood occupies its **PRG banks 8–11**
(64 KiB) [O].

---

## 0. The two formats that are easily confused

PDS produces one of two very different things:

1. **A download stream** — the bytes that go down the parallel/serial link to a
   target running the PDS download software. This is a sequence of records
   (`0xB3` padding, `0xB4` download, `0xB7` select bank, …). It is *not* a ROM
   image and contains no 16 KiB padding.
2. **A bank image** — a flat 16 KiB piece of the program at a fixed base
   (`$8000` or `$C000`), with unwritten bytes filled. The four supplied
   `ROBINV7.B?` files are of this kind: exactly 16384 bytes each, no record
   framing at all [O].

`SEND COMPUTER1` (the shipped sources) produces (1) directly to hardware. The
undocumented `SEND MSDOS,<file>` described in §6 writes (1) to a disk file. The
`ROBINV7.B?` files in the repo are already (2) — they must have been converted
from (1) or produced by a bank-dumping tool; nothing in them has to be stripped
[O].

---

## 1. `BANK` — commit the code assembled so far as bank *n*

**Syntax** [D]:

```
BANK n [, execute_address]        ; n = 0..255
```

Semantics, as documented and as the sources use it:

1. PDS sends the bank number to the target (record `0xB7`, §5) [D].
2. It downloads **all bytes assembled since the previous `BANK` (or the start of
   the program)** as the blocks belonging to bank *n* [D].
3. If `execute_address` is present, the downloader `JSR`s there afterwards
   (record `0xB5`) [D].
4. The assembler is then **reset**: the symbol table survives, everything else
   does not. In particular the PC is cleared, so **a new `ORG` is mandatory**,
   and `SKIP` is disabled (the listing shows `no skip`) [D].
5. With more than one bank in the program, PDS downloads automatically on pass 2
   without asking `Download (Y/N)?` [D].

### Source-order proof (why the header bytes land at the *end* of a bank)

`BANK12.PDS` is [O]:

```asm
ED12
b12     equ &c000-ED12
        free b12
        LIST ON
BANK12  DEFB <B12,>B12      ; maps and data
        LIST OFF
endofbank12 if endofbank12>&c002
        error "game bank 12 overflowed
        endif
        bank 12
        org &8000
```

The `DEFB` is emitted **before** `bank 12`, so it is the last thing in the bank
12 payload; `bank 12` commits that payload. This is exactly why the trailer is
at the end of `.BC` (offset 16382), not at its start. The `ORG $8000` *after*
`bank 12` belongs to the next bank, not to bank 12.

Every bank in the tree follows the same shape: content … trailer … `BANK n` …
`ORG base` … next content. The `if endofbankNN > … error` lines are the
programmer's compile-time overflow checks; they emit no bytes [O].

### The bank number is opaque to PDS

PDS passes it through unchanged [D]. The value is therefore *target-defined*.
For this game only 0–15 are used, and at runtime the low two bits are the page
select (see §4) [I]. `BANK8.PDS` is a "dummy/overflow bank" (`b8 = ED8-&8000 =
0`, so its trailer would be `00 00`), but `ROBIN.PRJ` **disables** that entry
with the `FILE *` prefix [O/ledger]; no bank 8 is committed in the original
build, and the first real bank is 12. (If the `*` were not a disable marker, the
only difference would be an extra 2-byte bank 8 carrying `00 00`.)

### `ORG` must follow, and the wipe loop demonstrates it

`ENDCODE.ROU` (master build) [O]:

```asm
        bank 12
wipebanks = 0
        do
        org &8000
        defs &4000,0
        bank wipebanks
wipebanks = wipebanks+1
        until wipebanks=12
```

The `org &8000` at the top of each iteration is the re-`ORG` the manual
demands after a bank reset. Each iteration assembles 16 KiB of `$00` and commits
it to bank `wipebanks` (0…11), i.e. the master build deliberately wipes the
other twelve banks of the target's 256 KiB RAM.

### The optional execute address

`BANK 12,START` occurs in the non-master branch (`if master=0`) [O]. It commits
the current payload as bank 12 and then jumps to `START` (`$C284`) on the target.
The master branch (`master=1`, the shipped configuration) uses the plain
`bank 12` plus the wipe loop instead.

### A real inconsistency in the released `ENDCODE.ROU`

Read literally, the last `bank 12` in `ENDCODE.ROU` commits the whole main-code
payload (the contents of `$C004`…`$FFF8`) as **bank 12**, which would overwrite
`.BC` (the map bank). The surviving images, the trailer label `BANK15`, and the
game's own fixed page all say the main bank is **15**:

- `.BC` is map data and ends with the bank-12 trailer `00 02` [O].
- `.BF` is main code and its trailer at `$FEA1` is `01 58 1C 8C`
  (`B15 = $0158 = 344`) [O].
- On hardware, `$C000–$FFFF` is the *fixed* page 3 of the 64 KiB block, i.e. the
  fourth byte of the PDS bank group (12+3 = 15) [I].

So reproduce the main bank as **15**. Treat the `bank 12` in `ENDCODE.ROU` as a
release-time typo (or a dev-cart variant); the binaries prove the intended value.

**Limits:** bank number 0–255 [D]. The per-bank address ceilings used here are
`> &C002` for bank 12, `> &C001` for 13/14 and `> &FFF9` for the main bank [O].

---

## 2. `ORG` — one download block per section

**Syntax** [D]:

```
ORG new_PC [, true_PC]
```

- Up to **100** `ORG`s per program [D].
- `new_PC` must **not be a forward reference**: it is where the bytes are
  physically inserted [D].
- `true_PC`, if given, is used for `*` and all label values, while the bytes are
  still inserted at `new_PC`. This is the overlay/relocation facility [D].
- Downloading is done **one block per `ORG` section**, and only the sections that
  exist; the gap between two `ORG`s is not sent [D].
- `ORG` itself does not fill memory; filler is a separate concern (§3).

### Evidence in `.BF` (main bank, base `$C000`)

`BANK14.PDS` ends with [O]:

```asm
        bank 14
        org &c004
        jmp pastnops
        jmp cm_nmi
bank_table
banktable
bank.tbl defb 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
```

The main bank's first `ORG` is therefore `$C004`, not `$C000`. `.BF` confirms it
byte for byte [O]:

| address | bytes | meaning |
|---|---|---|
| `$C000` | `0F` | not assembled; never executed (see §9) |
| `$C001–$C003` | `37 37 37` | fill |
| `$C004` | `4C F8 C2` | `JMP $C2F8` (`pastnops`) |
| `$C007` | `4C 93 C4` | `JMP $C493` (`cm_nmi`), also the NMI vector target |
| `$C00A–$C019` | `00 01 … 0F` | `bank.tbl` (§4) |
| `$C284` | `78 D8 A2 FF 9A` | `START` = `sei/cld/ldx #$ff/txs` (`START.ROU`) |

`ENDCODE.ROU` then does [O]:

```asm
veryend
        org $fff9
irqinterupt rti
        defw &C007      ; CM_NMI
        defw START
        defw IRQINTERUPT
```

`.BF` ends with exactly [O]:

```
$FFF9: 40          RTI                (IRQ handler)
$FFFA: 07 C0       NMI   = $C007      (jmp cm_nmi)
$FFFC: 84 C2       RESET = $C284      (START)
$FFFE: F9 FF       IRQ   = $FFF9
```

This simultaneously proves: base `$C000`; the first `ORG` at `$C004`; the
vector block at `$FFF9`; and that `START` is `$C284`.

### The true-PC form is used for relocatable chunks

`CMLOGO.ROU` (included in bank 14) contains [O]:

```asm
!ROM_CHECK
        ORG *,$20       ; assemble here, but all labels/`*` are $20-relative
        ...
        ORG *,*         ; remove the offset (true PC = real PC)
        ORG *
```

`new_PC` stays `*` (no move), while `true_PC` becomes `$20`, so the block is
position-independent for copying to zero page. `ORG *,*` restores the identity
mapping. No project file uses a *different* `new_PC`/`true_PC` pair. (The
corpus does not independently prove whether the `*` in the *first* operand is
read as the physical or the true PC; at this point no prior true-PC offset is
active, so both readings give the same address. The ledger keeps this as an
open question.)

### Interaction with filler

Between `ORG` sections, and below the first `ORG` of a bank, the bank images
contain `$37` [O]. `DS` *without* a second operand is documented to download
random bytes, so use `DS n,$37` if you want a deterministic fill [D]. In the
Robin sources the only `DS` with an explicit fill is `defs 8,3` in `MAPDATA.DAT`
and two `DS n,$EA` blocks in `CMLOGO.ROU` [O].

---

## 3. The free-space convention (`bN`, `FREE`, `DEFB <B,>B`)

There is no PDS-level "bank header". The programmer adds one:

```asm
ED12                       ; label at the current PC, before the trailer
b12 equ &c000-ED12         ; number of bytes left to the bank end
        free b12           ; add to the global FREE total (display only)
        defb <B12,>B12     ; store the value, high byte then low byte
```

- `FREE e` adds `e` to a running total that PDS prints after assembly; it emits
  no bytes [D].
- `<` returns the **high** byte, `>` the **low** byte, when they start an
  expression [D]: `<$1234 = $12`, `>$1234 = $34`. The manual notes the default
  can be reversed by configuration, but the images prove the default here:
  `DEFB <B12,>B12` with `B12 = 2` produced `00 02` [O]. **The stored word is
  big-endian (high first).**
- The formulas are deliberately bank-specific [O]:

| bank | formula | end of region |
|---|---|---|
| 12 | `b12 equ &C000-ED12` | one past `$BFFF` |
| 13 | `b13 equ &C000-ED13` | one past `$BFFF` |
| 14 | `b14 equ &BFFF-ED14` | **`$BFFF` itself — off by one** |
| 15 | `b15 equ &FFF9-ED15` | start of the vector block |

`b14`'s use of `&BFFF` makes it one byte smaller than the true number of bytes
available (302 vs 301 in the image). `b15` is not "free space" either: it counts
from `ED15` all the way to the vector table, including the 21 bytes of
non-source code at `$FFE4–$FFF8` and the 4 trailer bytes themselves.

`T EQU b12+b13+b14+b15` is the total; bank 15 stores it as `DEFB <T,>T`
(`TOTAL`) [O].

### What is actually in the supplied images

| bank | trailer address (offset) | expected bytes | image bytes | decoded | verdict |
|---|---|---|---|---|---|
| 12 | `$BFFE` (16382) | `B12=$0002` | `00 02` | 2 | exact |
| 13 | `$BD9A` (15770) | `B13=$0266` | `CB E4` | — | **no trailer in image** |
| 14 | `$BED2` (16082) | `B14=$012D` | `01 2D` | 301 | exact (formula is 1 low) |
| 15 | `$FEA1` (16033) | `B15=$0158` | `01 58` | 344 | exact |
| 15 | `$FEA3` (16035) | `T` | `1C 8C` | 7308 | **inconsistent, §9** |

For bank 13 the last two content bytes are `CB E4` and the `$37` run starts at
15772. That geometry is exactly `2 + 612` bytes of room at `ED13 = 15770`, so
the *slot* for a trailer exists, but its value is not `02 66`; the bytes are
music data. Both `.BD` and the shipped ROM agree on `CB E4` [O]. The released
`BANK13.PDS` therefore postdates the image (or the build skipped that line).

The runtime never reads these trailers. A full source search finds no reference
to `BANK12`, `BANK13`, `BANK14`, `BANK15` or `TOTAL` outside their definitions
[O]. They are build metadata for the programmer and for a byte-level audit of
the bank images.

---

## 4. The only runtime table: `bank.tbl` in bank 14/15

`BANK14.PDS` places a 16-byte table in the fixed page [O]:

```
$C00A: 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
```

Labels `bank_table`, `banktable` and `bank.tbl` all point at `$C00A`. It is
**written, never read**:

```asm
changebank12rou  lda #12 : sta bankno : sta bank.tbl+12 : rts   ; TIMINGS.ROU
changebank13rou  lda #13 : sta bankno : sta bank.tbl+13 : rts
changebankrou    sta bankno
changebankrou1   tax : sta bank.tbl,x : rts                    ; GENERAL.ROU
```

`changebank 14` in `MACROS.PDS` expands to `lda #14 / sta bankno / sta
bank.tbl+14`. The interrupt handler saves `bankno`, forces `bank.tbl+13` while
playing music, then restores it [O].

Why a table at all? On the Quattro board (iNES mapper **232**) the registers are
[D from the mapper documentation, O from the header `mapper=232`]:

- `$8000–$BFFF`: select one of four 64 KiB **outer** blocks (the block bits are
  in the written value; the exact bit positions are in the mapper notes and are
  not exercised by the game code).
- `$C000–$FFFF`: `.... ..PP` — select one of four 16 KiB pages of the current
  block: `PP` = page at `$8000–$BFFF`, while `$C000–$FFFF` is fixed to page 3.

So writing *n* to a `$C000` address selects page `n & 3`. Values 12, 13, 14 give
pages 0, 1, 2 = maps, music, charsets at `$8000`; the main code is page 3 at
`$C000` and cannot be switched away. The table also makes the written value
equal the ROM byte at the written address (`$C00A + n` contains `n`), which is
the standard AND-bus-conflict-safe idiom; this is why the table is 16 bytes of
`0..15` rather than a single register address [I, but strongly supported by the
construction].

The physical ROM mapping is therefore:

```
logical bank 12 -> page 0 -> PRG bank 8   (maps,      $8000-$BFFF)
logical bank 13 -> page 1 -> PRG bank 9   (music,     $8000-$BFFF)
logical bank 14 -> page 2 -> PRG bank 10  (charsets,  $8000-$BFFF)
logical bank 15 -> page 3 -> PRG bank 11  (main code, $C000-$FFFF, fixed)
```

The `-4` between the PDS bank number and the PRG index is just where the 64 KiB
block sits in the 256 KiB Quattro cartridge (block 2, PRG 8–11) [I]. PDS itself
does not perform this mapping; it is a property of the cartridge build.

---

## 5. Download records (the object-code wire format)

All numbers below are decimal in the manual and hex here [D]:

| byte | command | payload | used by |
|---|---|---|---|
| `0xB3` (179) | padding | none — ignore | any record with odd total length |
| `0xB4` (180) | download | start hi, start lo, length hi, length lo, data | assembler, monitor fill |
| `0xB5` (181) | execute / jump | address hi, address lo | assembler when `BANK n,addr`, `EXEC`, `END addr`; `JSR` (returns on `RTS`) |
| `0xB6` (182) | upload | address hi/lo, length hi/lo, then ports reverse | monitor (DL1+) |
| `0xB7` (183) | select bank | bank byte | assembler `BANK`, monitor `Z` |
| `0xB8` (184) | send registers | 7 bytes target→main | monitor, DL1 |
| `0xB9` (185) | get registers | 7 bytes main→target | monitor, DL1 |
| `0xBA` (186) | trace | 3 bytes | monitor tracer, DL1 |
| `0xBB` (187) | analyze | 2 bytes target→main | monitor `A`, DL2 |

Details that matter when parsing:

- Addresses and lengths are **high byte first** [D].
- `length = 0` means **65536** [D].
- `0xB4` is emitted once per `ORG` section, from the section start to the next
  `ORG` (or the end of the program); intervening holes are not sent [D].
- `0xB3` is inserted so the whole command block has an even number of bytes; the
  downloader must ignore it. It is *not* a record length and can appear before
  any command [D].
- The assembler's `BANK` sequence is: select bank (`0xB7 n`), then the `0xB4`
  block(s) accumulated since the previous `BANK`, then optionally `0xB5`
  [D, order inferred from the manual's description; the images cannot show it].
- A plain single-bank program is just `0xB4` block(s) plus an optional `0xB5`.

### Handshake / control lines [D]

The interface has eight buffered bidirectional data lines, one input flag and one
output flag. Nothing is level-signalled; every transfer **toggles** a line, so
one side can never run ahead:

- main→target: main puts the byte, flips its output, waits for its input to
  flip; target waits for its input to flip, reads, flips its output. Main
  starts, target finishes.
- target→main: target puts the byte, flips its output, waits; main waits for its
  input, reads, flips its output. Target starts, main finishes.
- reversing direction is itself a handshake and behaves like one phantom byte —
  hence the `0xB3` before the 3-byte `0xB5` and before `0xB6`.
- There is no error checking or time-out. Speeds are 300–19200 baud on serial,
  or the parallel COMPUTER1/2 ports; `COMPUTER0` is the nibble protocol (BBC).

### Which records does a ROM build need?

**None.** The record stream exists only to move bytes into a live target. A
cartridge image is produced by placing the same bytes at absolute file offsets;
the supplied `.BC–.BF` files contain no records at all [O]. If you are
reconstructing the build for a ROM, ignore `SEND`/`BANK` entirely and emit bank
images (§8).

---

## 6. Undocumented `SEND MSDOS,<file>`

The 6502 manual lists only `SERIAL`, `SERIAL1..3`, `COMPUTER0/1/2` [D]. The PC
1.21 binary nevertheless **does** implement a file destination; this was found
by static reverse engineering of `version121_pds6502.exe` [O]:

- It compares the keyword `MSDOS,` (linear `0x2155C`), copies the filename to
  `DS:0x734E`, and sets destination selector `[0x67E0] = 0x10`.
- Selector `0x10` writes with INT 21h: `AH=3C` create/truncate (linear
  `0x1FC61`), a 128-byte buffer flushed with `AH=40` (linear `0x20FE1`), and
  `AH=3E` close at the end. Write failures print
  `Error writing output file to disk`.
- The same send-byte dispatch table (`cs:[bx+0x16D2]`; `0x10` = DOS file) is
  used for every record, so the file is byte-for-byte what the parallel port
  would have received.

(The string `Only SERIAL and COMPUTERx are supported` in the same binary belongs
to a different destination/setup prompt, not to the `SEND` parser. It does not
disable `MSDOS`.)

What that means for reconstruction:

- The output is the **same framed byte stream** as the wire
  (`0xB3`/`0xB4`/`0xB5`/`0xB7`), not a raw 16 KiB bank [O/RE].
- The output file is **created/truncated for each bank** as the bank is
  committed (`AH=3C`). One fixed filename therefore keeps only the **last**
  bank — the overwrite hazard.
- The workaround used by the original tree is one destination per bank, named
  after the bank: `ROBINV7.BC` (= bank 12), `.BD` (13), `.BE` (14), `.BF` (15).
  In practice this means a `SEND MSDOS,ROBINV7.B<hex>` line immediately before
  each `BANK`, because a single `SEND` at the top of the program applies to all
  banks and is re-opened on every commit. (A capture tool can instead patch the
  `AH=3C` create into `AH=3D AL=2` open + seek-to-end, or patch the filename to
  append the bank number; the object itself lives only in host RAM and is never
  written to disk otherwise [O/RE].)
- The shipped `send computer1` in `MACROS.PDS`/`ENDCODE.ROU` is for the live
  parallel link, not a file.

### Converting a MSDOS stream to a 16 KiB bank image

Parse **sequentially** (never search for `0xB4`: the byte can occur inside music
data), and drop anything outside the bank window:

```python
def extract_bank(stream, base, size=0x4000, fill=0x37):
    bank = bytearray([fill]) * size
    i = 0
    while i < len(stream):
        cmd = stream[i]; i += 1
        if cmd == 0xB3:                      # padding
            continue
        if cmd == 0xB4:                      # download
            start  = (stream[i] << 8) | stream[i+1]; i += 2
            length = (stream[i] << 8) | stream[i+1]; i += 2
            if length == 0:                  # 0 means 65536
                length = 0x10000
            data = stream[i:i+length]; i += length
            lo = max(start, base)
            hi = min(start + length, base + size)
            if lo < hi:                      # clip to this bank
                bank[lo-base:hi-base] = data[lo-start:hi-start]
        elif cmd == 0xB5:                    # execute (2 bytes)
            i += 2
        elif cmd == 0xB7:                    # select bank (1 byte)
            i += 1
        elif cmd == 0xB6:
            raise ValueError("upload record in an assembler file")
        else:
            raise ValueError(f"unknown record {cmd:02X} at {i-1}")
    return bytes(bank)
```

Notes:

- `0xB4` records whose start is outside the window are dropped. This matters:
  the music bank really does contain a two-byte block at `$0002` (`JONSBIT.MUS`
  `org 2` / `status0 ds 1,0` / `status1 ds 1,0`) that cannot be part of a
  `$8000`-based ROM bank [O].
- `length = 0` (65536) would span several banks; clip as above.
- Fill unwritten bytes with `$37` to match the supplied images [O]. Other
  values are functionally equivalent, but `$37` is the convention here.
- The supplied `.BC–.BF` are **already the result of this operation** (flat,
  16384 bytes, `$37` fill). For them there are no header/trailer bytes to strip.
  A `SEND MSDOS` capture is the only thing that needs the parser.

---

## 7. Reconstructing the original build

### 7.1 Order (`ROBIN.PRJ`, 34 `FILE` entries) [O]

| # | file | lands in / effect |
|---|---|---|
| 1 | `MACROS.PDS` | `SEND COMPUTER1`, config `EQU`s, macros, `path c:\nes\robin`; no bytes |
| 2 | `VARS.PDS` | variable `EQU`s; ends with `org &8000` |
| 3 | `BANK8.PDS` | **skipped**: `FILE *C:\ROBIN\BANK8.PDS` disables it; `BANK 8` never runs [ledger] |
| 4 | `MAPDATA.DAT` | map data at `$8000` (initial PC supplied by `VARS.PDS:242 org &8000`) |
| 5 | `BANK12.PDS` | trailer, `BANK 12`, `ORG $8000` |
| 6–14 | `MACROS.MUS`, `JONSBIT.MUS`, `MUSIC1.MUS`, `HISCORE.ROU`, `TITLE.ROU`, `SOUNDFX.ROU`, `NEWBITS.ROU`, `EXPLODE.ROU`, `PRTROBIN.ROU` | bank 13 content at `$8000` |
| 15 | `BANK13.PDS` | trailer, `BANK 13`, `ORG $8000` |
| 16–17 | `CMLOGO.ROU`, `CHRSETS.CHR` | bank 14 content at `$8000` |
| 18 | `BANK14.PDS` | trailer, `BANK 14`, `ORG $C004`, `jmp pastnops`, `jmp cm_nmi`, `bank.tbl` → **bank 15 content starts here** |
| 19–32 | `TIMINGS.ROU`, `START.ROU`, `MAINLOOP.ROU`, `INTERUPT.ROU`, `CONTROL.ROU`, `XTRACONT.ROU`, `XTRAROUS.ROU`, `ONSCREEN.ROU`, `SPRITESD.DAT`, `SPRITESR.ROU`, `PRTMESS.ROU`, `UNPACK.ROU`, `GENERAL.ROU`, `MAPSCROL.ROU` | bank 15 at `$C004…` |
| 33 | `ENDCODE.ROU` | `B15`/`TOTAL` trailers, `ORG $FFF9` + vectors, `BANK 12`/wipe loop, `SEND`, `END` |
| 34 | `JUNK` | after `END`; never assembled |

Note that the *file name does not always match the bank*: `BANK14.PDS`'s
post-`bank 14` code is bank 15, and `BANK12.PDS`'s `org &8000` belongs to the
next bank. This is normal for the convention. Because `BANK8.PDS` is disabled,
the program has no `ORG` at all until `VARS.PDS`'s trailing `org &8000`; it is
that `ORG` that positions `MAPDATA.DAT` [O].

`JUNK` is raw `HEX` data after an `END`; `END` stops assembly [D], so it is dead
source in the project (probably a scratch buffer).

### 7.2 Configuration switches

`MACROS.PDS` sets [O]:

```asm
absolutely equ 1
title      equ 1
hiscore    equ 1
musicon    equ 1
testpause  equ 0
startlevel equ 5
analyzeon  equ 0
master     equ 1
showcoins  equ 0
ydisplace  equ 12
```

- `master=1` selects the **wipe-banks-0–11** path in `ENDCODE`; `master=0`
  selects `BANK 12,START` (development image with an execute address).
- `title/hiscore/musicon=1` enable the title/hiscore/music code in banks 13 and
  15. `analyzeon=0` omits the monitor `JSR ANALYZE` hook.
- `gav_master = 1` (set in `JONSBIT.MUS`; its `ASK` is commented out) disables
  the alternative standalone music-driver blocks, including the
  `BANK 0` + `ORG $FFFA` path in `MUSIC1.MUS` [O].
- `testpause/startlevel/showcoins/ydisplace` only affect gameplay constants.

The shipped configuration therefore produces **four** real banks (12–15), plus
the twelve wipe banks 0–11 written by the master loop. The dummy bank 8 file is
disabled and never produced.

### 7.3 Why PC PDS 1.21 cannot load `ROBIN.PRJ`

[O] from the supplied binary and source:

1. The project file is a list of editor-file commands:
   `project "SUPER ROBIN HOOD"`, `asmflag 0`, `FILE C:\ROBIN\…`,
   `COMMENT "…"`, `CURCOLOUR RED ON GREEN`, `ASSEMBLER`,
   `WINDOW 66x19 at 12,29`, `CLOCK ON`. These are not 6502 assembler
   directives.
2. The PC 1.21 executable contains **none** of the tokens `project`,
   `asmflag`, `CURCOLOUR`, `COMMENT`, `WINDOW`, `CLOCK`, `ASSEMBLER` (string
   search of `version121_pds6502.exe`). It has no project loader; it is an
   editor with a fixed set of source windows.
3. The PC editor has a fixed set of source slots. Static RE of the 1.21 binary
   gives `0.PDS`…`9.PDS` = **10 files** [O/RE]; the original 6502 manual's
   assembly loop is written as file 0–7 [D], and the binary's window setup asks
   “8 windows or 16 windows?”. The exact mapping between “windows” and source
   slots is version-dependent, but the project has **34** files — far more than
   any of these limits — so it cannot be represented.
4. All paths are absolute `C:\ROBIN\…`; on any other machine they do not exist.

The “10-file limit” is therefore real: **10 editor slots** (`0.PDS`…`9.PDS`) on
the PC build [O/RE], with the manual's older 8-file (0–7) convention [D]. The
practical extra limits are DOS file handles for `INCLUDE` (the binary asks for
`FILES=20` in `CONFIG.SYS`) and the ban on nested includes [O/D].

### 7.4 Practical rebuild on PC PDS 1.21

Because assembly is just “file 0, file 1, … last slot, or until `END`” (0–7 in
the manual, 0–9 in the PC build), the simplest faithful rebuild is
**concatenation**, not a project file:

1. Create up to ten text files (`0.PDS`…`9.PDS`) by concatenating the enabled
   project entries in the table order (skip `BANK8.PDS` because of its `FILE *`
   prefix, and `JUNK` because it is after `END`), splitting only at file
   boundaries. Add a trailing CR/LF to every file.
2. Load them into editor slots 0–9 and press `[ASSEM]`.
3. Forward references are fine: PDS is two-pass and keeps symbols across banks
   (this is essential — `MAPDATA.DAT` references `compchr` symbols defined in
   bank 15, e.g. `basechr0.157` in `UNPACK.ROU`) [O].
4. Neutralise `SEND COMPUTER1`/`BANK` only if you are not downloading; for a ROM
   build use the bank images instead (§8).

A single `INCLUDE` master file is tempting, but **`DO`/`LOOP`/`UNTIL` are
forbidden in include files** (binary string: “DO, LOOP and UNTIL may not be used
in include files”) and several project files use them (`TIMINGS.ROU`,
`MAPSCROL.ROU`, `START.ROU`, `CONTROL.ROU`, `ENDCODE.ROU`, `JONSBIT.MUS`,
`MACROS.PDS`) [O]. Concatenating into real editor windows avoids the
restriction. If you do use `INCLUDE`, it cannot nest (“Includes cannot be
nested”) and the include must end on a CR (“Please end include file in a C/R”).

Runtime note for the 1.21 binary [O/RE]: it refuses to run unless the DOS major
version is **exactly 3** (`mov ah,30h / int 21h / cmp al,3 / jne` at linear
`0x223EF`); patch file offset `0x129EF` from `75` (JNE) to `72` (JB) for
DOSBox/FreeDOS. The IDE itself is reported not to draw correctly under DOSBox
0.74, so a headless/batch patch of the assembler (or a PDS-semantics assembler
validated against `.BC–.BF`) is the practical route.

---

## 8. A modern transpiler recipe (PDS → 256 KiB mapper-232 ROM)

The goal: produce the same four 16 KiB images, place them at PRG 8–11, and add
the iNES header. Everything below is independent of PDS's download records.

### 8.1 Assembly model

- One **global symbol table** for the whole program (PDS keeps symbols across
  `BANK`) [D].
- Per bank: a 16 KiB buffer based at `$8000` (banks 12–14) or `$C000` (bank 15),
  pre-filled with `$37`.
- `BANK n` = “flush the pending bytes into buffer *n*, then clear PC” [D].
- `ORG a[,t]` = set PC (and true PC) with no output [D].
- Drop output whose address is outside the target buffer; for a ROM build the
  only such case is `JONSBIT.MUS`'s `ORG 2` two-byte block [O].

```
banks = {12: fill(0x37,0x4000), 13: ..., 14: ..., 15: ...}
base  = {12:0x8000, 13:0x8000, 14:0x8000, 15:0xC000}
prg   = {12:8, 13:9, 14:10, 15:11}

for entry in project_order:               # ROBIN.PRJ minus BANK8.PDS and JUNK
    assemble_into(entry, banks, base, symtab)   # shared symtab, two passes

# bank-15 specific: the first ORG is $C004
# vectors already emitted by ENDCODE:
#   $FFF9 40, $FFFA $C007, $FFFC $C284, $FFFE $FFF9
```

### 8.2 Trailers (only needed for byte-identical output)

Compute exactly as the sources do, or copy the image bytes:

```
B12 = 0x0002   -> 00 02 at $BFFE
B13 = 0xC000 - ED13                  # $0266 for the released layout
B14 = 0xBFFF - ED14 = 0x012D         # note the $BFFF off-by-one
B15 = 0xFFF9 - ED15 = 0x0158         # $FEA1
T   = B12+B13+B14+B15                # released-source arithmetic: $04ED
                                     # .BF image says $1C8C (see §9)
```

If the goal is a *runnable* ROM, these bytes are dead; write the source-computed
values (or `$37`) and move on. If the goal is a bit-exact `.BF`, copy `01 58 1C
8C`, keep the 21 bytes at `$FFE4–$FFF8` (§9), and put `0F` at `$C000` (§9.6).

### 8.3 ROM container

The supplied ROM header is [O]:

```
4E 45 53 1A  10 00  81 E0  00 00 00 00 00 00 00 00
 "NES"^Z     16 PRG  0 CHR  mapper low=0, high=E -> 232
             (CHR RAM 8K)  vertical mirroring
```

- PRG = 16 × 16 KiB = 256 KiB; file size `16 + 0x40000 = 262160`.
- CHR count 0 (mapper 232 uses 8 KiB CHR RAM).
- PRG bank *n* starts at `16 + n*0x4000`:

| PRG | file offset | content |
|---|---|---|
| 8 | `0x20010` | `.BC` (maps) |
| 9 | `0x24010` | `.BD` (music) |
| 10 | `0x28010` | `.BE` (charsets) |
| 11 | `0x2C010` | `.BF` (main code + vectors) |

```
rom = bytearray(b'\x37' * 0x40010)
rom[0:16] = bytes.fromhex('4e45531a100081e00000000000000000')
for logical in (12,13,14,15):
    off = 16 + prg[logical]*0x4000
    rom[off:off+0x4000] = banks[logical]
write('srh.nes', rom)
```

Filling PRG 0–7 with `$37` makes a standalone SRH image, but note the **boot
caveat**: mapper 232 powers up with outer block 0 selected; the retail Quattro
menu selects block 2 (PRG 8–11) before jumping to the game. An emulator test
needs the outer block pre-set to 2, or a small boot stub in block 0 page 3
(`$C000`) that writes the block-select value for block 2 to `$8000–$BFFF` and
then jumps into the mirrored address. This is a cartridge-menu concern, not a
PDS concern; the four bank images themselves are complete.

---

## 9. Verification against the real images — and the contradictions

### 9.1 Lengths and fill

| file | size | last non-fill byte (offset) | `$37` fill | filler offsets |
|---|---|---|---|---|
| `.BC` (12) | 16384 | 16383 (`00 02` trailer at 16382–3) | 0 | — |
| `.BD` (13) | 16384 | 15771 | 612 | 15772–16383 |
| `.BE` (14) | 16384 | 16083 (`01 2D` trailer at 16082–3) | 300 | 16084–16383 |
| `.BF` (15) | 16384 | 16383 (code/trailer + stub + vectors) | 3 + 319 = 322 | 1–3, 16037–16355 |

`.BF` additionally has 21 non-filler bytes at `$FFE4–$FFF8` (offset 16356–16376)
and the 7 vector bytes at `$FFF9–$FFFF`.

### 9.2 The MAPDATA correction (supersedes the earlier ledger note)

Assembling `MAPDATA.DAT` in full (`HEX`, `DEFB`, `DW`, `DEFS`, `EQU`, labels)
gives **16382 bytes** at `$8000–$BFFD`, exactly filling bank 12 up to its
two-byte trailer. Compared with `.BC`:

- **51 differing bytes, all in `$860E–$86A2`** (offset 1550–1698).
- **12 of them** are forward references to the `compchr` symbols
  (`basechr0.157`, `rockchr157.99`, …) defined in bank 15
  (`UNPACK.ROU`). They are not source/ROM differences; a standalone assembly
  just has to resolve them. `.BC` holds `05 09 05 06 0B 05 08 07 05 06 0A 07`.
- **39 of them** are palettes where the source has `$0E` and `.BC` has `$0D`
  (`&0e,&27,&17,&06` vs `0D 27 17 06`, etc.). That is a genuine one-byte-per-line
  revision difference, not an insertion.

So the earlier “15976-byte source vs 16382-byte ROM with a ~398-byte insertion”
is a **parsing artefact**: 15976 is only the `HEX` bytes. The 398 `DEFB` bytes
(the `solidchrs` block) and the 8-byte `defs 8,3` are inline and match the ROM.
There is **no** 398-byte insertion. The released MAPDATA is the same revision as
`.BC` apart from the palette nibble and the unresolved forward references.

### 9.3 Bank 13 has no valid trailer

Recomputed from the image geometry: `ED13 = $BD9A` (offset 15770), so
`B13 = $C000-$BD9A = $0266 = 614`, and the file has 612 bytes of `$37` after the
would-be 2-byte trailer. The bytes actually there are `CB E4`, the last music
bytes; the shipped ROM has the same two bytes. Conclusion: the build that
produced `.BD` did **not** emit `DEFB <B13,>B13` (the released `BANK13.PDS`
postdates it), or emitted a value other than `02 66`. There is no plausible
`<B13,>B13` value equal to `CB E4`.

### 9.4 Bank 15's `TOTAL` does not add up

`.BF`'s trailer at `$FEA1` is:

```
01 58   B15 = $0158 = 344  = $FFF9-$FEA1   (matches .BF's geometry exactly)
1C 8C   T   = $1C8C = 7308
```

But `b12 + b13 + b14 + b15 = 2 + 614 + 301 + 344 = 1261 ($04ED)`. The image says
7308, a difference of **6047 ($179F)**. Since `B15` matches this image's own
filler boundary, the trailer is genuine and correctly parsed; the inconsistency
is in `T`. If `b12` and `b14` are as observed, `b13` would have to be
`T - (2+301+344) = 6661`, i.e. the build that wrote `TOTAL` had bank 13 ending
at about `$A5FB` (≈9723 bytes of content), some 6 KiB shorter than the `.BD`
image. Either `.BF` and `.BD` come from different builds/revisions, or the
released `ENDCODE.ROU`/`BANK13.PDS` differ from the ones used for the images. Do
not trust `TOTAL` as a checksum of the four files in this repo.

### 9.5 The 21 bytes at `$FFE4–$FFF8` are not game source

Disassembly of `.BF` `$FFE4–$FFF8`:

```
$FFE4  PHP
$FFE5  SEC
$FFE6  BCS $FFEF
$FFE8  PLA
$FFE9  PLP
$FFEA  RTS
$FFEB  NOP : NOP
$FFED  PHP
$FFEE  CLC
$FFEF  DEC $C003
$FFF2  LDA $C002
$FFF5  AND #$02
$FFF7  BEQ $FFED
$FFF9  RTI            ; IRQ vector
```

`$C002` is the PPU status port (bit 1 = sprite-0 hit) when executing from ROM;
`DEC $C003` is a delay. This is a “wait for sprite 0” loop split into three
entry points. The entry addresses are exactly the constants declared in
`MACROS.PDS` [O]:

```asm
CHECKPDS  EQU $FFF2
BREAKPOINT EQU $FFED
ANALYZE   EQU $FFE4
```

No file in the project emits these bytes (no `ORG $FFE4`; the only `ORG`s are
listed in §2), and no game code calls `CHECKPDS`/`BREAKPOINT`/`ANALYZE` [O].
They are the resident PDS download-software/monitor hooks — or residue of them —
that the bank-15 download did not overwrite, and the `$37` fill stops at
`$FFE4` for the same reason [I]. The shipped ROM contains the same 21 bytes,
which suggests the cartridge image was built from the PDS bank dumps rather than
from a re-link [I]. They are dead in the game (`analyzeon=0`, IRQ is a plain
`rti`).

### 9.6 `$C000` = `0F`

`.BF` has `0F 37 37 37` at `$C000–$C003`; the shipped ROM has `FE FF FF FF`
[O]. The byte is not emitted by any source. `$0F` = 15 = the bank number, which
looks like a bank stamp written at the base when the first `ORG` is above it
[I]. It is never executed (RESET = `$C284`), so fill it with `$37` unless you
need a bit-exact `.BF`.

### 9.7 `.B?` vs the shipped Quattro ROM

The only ROM available is the multicart. Byte comparison of the 16 KiB slices
[O]:

| image | PRG | identical? | differing bytes | of which `$37` vs ROM `$00/$FF` | real content differences |
|---|---|---|---|---|---|
| `.BC` | 8 | **yes** | 0 | 0 | 0 |
| `.BD` | 9 | no | 3767 | 620 | 3147 |
| `.BE` | 10 | no | 306 | 289 | 17 |
| `.BF` | 11 | no | 7012 | 282 | 6730 |

- `.BE` differs only in a couple of code bytes plus the ROM's own padding
  choice (`$00`/`$FF` where `.BE` has `$37`).
- `.BD` matches the ROM exactly from `$8000` to `$86D0`; the ROM then has 9 bytes
  of `$FF` at `$86D1–$86D9` where `.BD` has data, after which the two match again
  up to `$B166`. From `$B180` the ROM's upper ~12 KiB is largely blank: a
  repeating pattern of 32-byte `$FF` and `$00` blocks (with a few other bytes),
  while `.BD` has music tables. That is not plausible assembled source and looks
  like a masked/erased region in the ROM dump; use `.BD` as the bank-13 oracle.
- `.BF` has extensive real code differences (e.g. the `$C000` stamp, `$FE00`
  region), so the shipped ROM is a later/different revision of the main bank.

Conclusion: only bank 12 is a bit-exact oracle. Banks 13–15 in the repo are
older (or differently configured) builds; the *structure* (bases, ORG holes,
vectors, `$37` fill) is consistent, the *content* is not always.

### 9.8 `ENDCODE`'s `bank 12`

As noted in §1, the released `ENDCODE.ROU` commits the main payload with
`bank 12`, which contradicts `.BC` being maps and `.BF` being the main bank.
The file-based evidence (trailer labels, `.BF` content, the wipe loop producing
files for 0–11) says the main bank is **15**. Reproduce with `BANK 15` (or
`BANK 15,START` for the dev variant). If you literally run the released
`ENDCODE.ROU` with a per-bank file destination, the final `bank 12` truncates
and overwrites the map file — a spectacular illustration of the overwrite
hazard.

---

## 10. Summary table

| logical bank | source files | output | PRG | load base / first ORG | observed free / trailer |
|---|---|---|---|---|---|
| 8 (dummy) | `MACROS.PDS`, `VARS.PDS`, `BANK8.PDS` | **not built** (`FILE *` disables `BANK8.PDS`) | — | — | — |
| 12 maps | `MAPDATA.DAT` (+`BANK12.PDS`) | `ROBINV7.BC` | 8 | `$8000` / `$8000` | 0 filler; content 16382; `B12=2` → `00 02` |
| 13 music/title | `MACROS.MUS`, `JONSBIT.MUS`, `MUSIC1.MUS`, `HISCORE`, `TITLE`, `SOUNDFX`, `NEWBITS`, `EXPLODE`, `PRTROBIN` (+`BANK13.PDS`) | `ROBINV7.BD` | 9 | `$8000` | 612 filler; content 15772; trailer missing (expected `02 66`) |
| 14 chars | `CMLOGO.ROU`, `CHRSETS.CHR` (+`BANK14.PDS` trailer part) | `ROBINV7.BE` | 10 | `$8000` | 300 filler; content 16084; `B14=301` → `01 2D` |
| 15 main | `BANK14.PDS` (tail), `TIMINGS`…`MAPSCROL`, `ENDCODE` | `ROBINV7.BF` | 11 | `$C000` / `$C004` | 322 filler + 21 downloader bytes; `B15=344` → `01 58`; `T=7308` → `1C 8C` |

Build knobs: `master=1` (wipe 0–11), `title/hiscore/musicon=1`,
`analyzeon=0`, `gav_master=1`. ROM header `4E 45 53 1A 10 00 81 E0…`
(256 KiB PRG, CHR RAM, mapper 232). Vectors at `$FFF9`: `40`, NMI `$C007`,
RESET `$C284`, IRQ `$FFF9`.
