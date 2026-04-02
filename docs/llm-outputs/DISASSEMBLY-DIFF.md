# Disassembly diff: transpiled ROM vs. retail *Quattro Adventure* cartridge

This document answers two questions:

1. Is `transpiler/out/robinhood.nes` really compiled from the released PDS source?
2. Where exactly does it differ from the copy of *Super Robin Hood* in the retail
   *Quattro Adventure* cartridge?

Short answer: **yes, it is a pure source build**, and the differences are
consistent with the released source being a **later revision than the retail
cartridge**, not an older one. The cartridge also contains a small 4-in-1
boot hand-off stub and some uninitialised filler that the released source does
not produce.

## 1. Method

- Original PRG banks were extracted with MesenCE from `Quattro Adventure.nes`:
  `nesPrgRom` pages 8–11, i.e. file offsets `16 + n*0x4000`, `n = 8..11`.
  (`/tmp/opencode/orig_bank8.bin` … `orig_bank11.bin`.)
- Transpiled banks are `robinhood.nes` offsets:
  - bank 12: `0x0010..0x4010`
  - bank 13: `0x4010..0x8010`
  - bank 14: `0x8010..0xC010`
  - bank 15: `0xC010..0x10010`
- Bank 12–15 are the logical PDS banks; the cartridge maps them to physical
  PRG pages 8–11 through the BF9096 mapper. Both ROMs were compared by
  logical bank, not by file position.
- Byte diffs were computed with a capstone-based script
  (`/tmp/opencode/bdiff.py`) and cross-checked with `da65` disassembly.
  Because code/data can move, `difflib.SequenceMatcher` alignment was used in
  addition to positional comparison.

## 2. Alignment summary

| Transpiled | Original | Positional identical | SequenceMatcher match | Main cause of difference |
|---|---|---|---|---|
| bank 12 | bank 8 | 16,345 / 16,384 (99.76%) | ~99.8% | 39 palette bytes |
| bank 13 | bank 9 | 9,422 / 16,384 (57.51%) | 87.0% | credits text added; code/table revision; +6 shift |
| bank 14 | bank 10 | 156 / 16,384 (0.95%) | **96.2%** | CMLOGO reordered; +0x117 shift before CHR data |
| bank 15 | bank 11 | 15,819 / 16,384 (96.55%) | 96.5% | calls into shifted bank 13; boot stub; free-space filler |

The positional percentage for bank 14 is misleading: almost all of its content
is identical, but the whole CHR/logo payload is shifted by `+0x117` bytes.

## 3. Bank 12 — map/palette (ours vs. original bank 8)

Only 39 bytes differ, all inside `$861E-$86A2`:

- Original: `$0D`
- Transpiled: `$0E`

Everything else, including the whole map data block, is byte-identical. This is
a palette-value revision in `MAPDATA.DAT`, not an assembler or transpiler bug.

## 4. Bank 13 — music/title/hiscore (ours vs. original bank 9)

Bytes `0x0000-0x1800` match exactly (`0x1800` = 6,144 bytes; first difference at
`0x1801`).

### 4.1 Early code: operand shifts only

Six early operand bytes differ because later data moved:

- `0x1801`, `0x1888`, `0x18BC`, `0x18E0`, `0x197E-0x1983`
- Examples: `LDA $9D70,Y` → `$9D7F` (+0x0F);
  `JSR $A1B3` → `$A1B9` (+6);
  `LDX #$6B / LDY #$9C` → `#$7A / #$9C` (+0x0F).

These are pointers/call targets, not different instructions.

### 4.2 Credits text: `GO DIZZY GO`

At `0x1C49` the transpiled bank inserts 16 bytes:

```
F9 20 20 07 0F 1B 20 04 09 1A 1A 19 20 07 0F 1B
   "  GO"     " DIZZY GO"
```

That is the C64 screen-code string `"  GO DIZZY GO"`, present in the released
source at `pds_src/src/HISCORE.ROU:423`:

```asm
cbm "  GO",27," DIZZY GO",27
```

The retail cartridge has the older credits list, ending at `FIREHAWK`:

```
... 06 09 12 05 08 01 17 0B FF     ; "FIREHAWK", end
```

So this line was added after the cartridge build.

### 4.3 Title-screen code: the third logo sprite was removed

At CPU `$9E06` the cartridge calls the sprite printer a third time:

```asm
; cartridge
9E00: A2 10     LDX #$10
9E02: A0 04     LDY #$04
9E04: A9 26     LDA #$26        ; titlelogos
9E06: 20 F4 EC  JSR $ECF4
9E09: A2 B0     LDX #$B0
9E0B: A0 C6     LDY #$C6
9E0D: A9 27     LDA #$27        ; titlelogos+1
9E0F: 20 F4 EC  JSR $ECF4
9E12: A2 78     LDX #$78
9E14: A0 B4     LDY #$B4
9E16: A9 28     LDA #$28        ; titlelogos+2
9E18: 4C F4 EC  JMP $ECF4
```

The transpiled source (and therefore the released PDS source) only draws
`titlelogos` and `titlelogos+2`:

```asm
9E0F: A2 10     LDX #$10
9E11: A0 04     LDY #$04
9E13: A9 26     LDA #$26
9E15: 20 F4 EC  JSR $ECF4
9E18: A2 78     LDX #$78
9E1A: A0 B4     LDY #$B4
9E1C: A9 28     LDA #$28
9E1E: 4C F4 EC  JMP $ECF4
```

The missing 9 bytes are `JSR $ECF4 / LDX #$B0 / LDY #$C6 / LDA #$27`
(`titlelogos+1`, the Camerica logo). This is a real code change in the
released source: the retail title screen draws three logo sprites, the
released source draws two.

Net size accounting for bank 13:

- `+16` bytes: `"  GO DIZZY GO"` credits text (data).
- `-1` byte: the cartridge has one extra `$F9` (line terminator) before the
  `FIREHAWK` line; the released source has one fewer.
- `-9` bytes: the removed third title sprite above.

Net `+6` bytes, which is exactly the shift seen from `$ABD9` onward. The
`NEWBITS` sprite/sparkle routines themselves are byte-identical; their apparent
change at `0x2BD9` is only this downstream shift.

Remaining differences after the shift:

- The credits pointer table at `0x21F0`/`0x220D` moves by +6
  (entries such as `A23C` → `A242`, `A262` → `A268`).
- `0x3166`: a small table differs (`0E 9B 00 ...` in the cartridge vs
  `0E 95 FF` in ours).

### 4.4 Padding

From about `0x31A0` to `0x3FE0` the cartridge alternates 32-byte blocks of
`$00` and `$FF`; the transpiled bank is all `$FF` filler. This region is not
reference data/code — it is leftover content in the cartridge image outside the
assembled range.

## 5. Bank 14 — CMLOGO / CHR data (ours vs. original bank 10)

`SequenceMatcher` says 96.2% of this bank is identical content, in 94 blocks.

The first 8 bytes match:

```
A2 00 8E 00 20 8E 01 20     ; LDX #0 / STX $2000 / STX $2001
```

Then the cartridge starts clearing RAM:

```
A9 00 95 00 A9 FF 9D 00 03 E8 D0 F4 ...
```

while the transpiled bank starts with the powerup/reset check:

```
A0 97 AD FE 07 29 3F C9 04 09 40 B0 05 CC FF 07 F0 05
8C FF 07 A9 00 8D FE 07 20 74 84 A2 00 A9 00 95 ...
```

Source evidence:

- `pds_src/src/CMLOGO.ROU:1538+` (active `CM_LOGO`) does
  `LDX #0 / STX $2000 / STX $2001`, then powerup/reset detection, then
  `JSR CM_CHARACTERS`, then the RAM clear.
- `pds_src/src/CMLOGO.ROU:47-140` is a **commented-out older version** that
  clears RAM first and performs the powerup check afterwards. Its first bytes
  match the retail cartridge.
- `CMLOGO.ROU:1497` sets `CM_YEAR EQU 1993`; the commented header says
  `CM_YEAR EQU 1991`, and line 2309 tests `IF CM_YEAR = 1992`.

So the retail cartridge was built from the older CMLOGO path, and the released
source contains the later 1993 path.

Shift points caused by the extra code:

| Original offset | Transpiled offset | Shift |
|---|---|---|
| `0x00C2` | `0x00DE` | +0x1C |
| `0x036A` | `0x0386` | +0x1C |
| `0x042D` | `0x0496` | +0x69 |
| `0x0AFD` | `0x0C14` | +0x117 |

From original `0x0AFD` to `0x3ED1`, 13,269 bytes match transpiled
`0x0C14-0x3FE8` exactly. That is the logo/CHR payload, shifted but otherwise
unchanged.

The approximately 279 extra bytes before the CHR block are real new code and
new message data from the 1993 CMLOGO revision, not just reordering:

1. **Powerup/reset detection before the RAM clear** (28 bytes):

   ```asm
   80B0: A0 97     LDY #$97
   80B2: AD FE 07  LDA $07FE        ; CM_FLAGS
   80B5: 29 3F     AND #$3F
   80B7: C9 04     CMP #$04
   80B9: 09 40     ORA #$40
   80BB: B0 05     BCS ...
   80BD: CC FF 07  CPY $07FF
   80C0: F0 05     BEQ ...
   80C2: 8C FF 07  STY $07FF
   80C5: A9 00     LDA #$00
   80C7: 8D FE 07  STA $07FE
   80CA: 20 74 84  JSR $8474
   ```

   The cartridge skips this and goes straight to `A9 00 95 00 ...`
   (clear zero page / `$0300`).

2. **Extra logo/screen drawing writes** before the tile upload, e.g. a second
   PPU address/data pair around `$23CD`/`$23D5` that the cartridge does not
   write. This changes the Codemasters logo picture data.

3. **A new 16-byte copyright/message upload** at the end of the logo routine:

   ```asm
   847D: A9 09     LDA #$09
   847F: 8D 06 20  STA $2006        ; PPU $0900
   8482: A9 00     LDA #$00
   8484: 8D 06 20  STA $2006
   8487: A2 00     LDX #$00
   8489: BD F5 83  LDA $83F5,X      ; MESS93 (1993 message)
   848C: 8D 07 20  STA $2007
   848F: E8        INX
   8490: E0 10     CPX #$10
   8492: D0 F5     BNE $8489
   8494: 60        RTS
   ```

   `MESS93` at `$83F5` is 16 bytes of new 1993 text. The cartridge has no
   equivalent upload at this point.

The remaining delta is reordered/new CHR and message data; the 13,269-byte
payload from the CHR block onward is unchanged.

## 6. Bank 15 — fixed code (ours vs. original bank 11)

Header and vectors agree:

- `$C000`: `FE FF FF FF`
- `$C004`: `4C F8 C2` (`JMP PASTNOPS`)
- `$C007`: `4C 93 C4` (`JMP CM_NMI`)
- `$C00A`: bank table `00..0F`
- `$FFF9`: `40 07 C0 84 C2 F9 FF`
  (`RTI`, `$C007` NMI, `$C284` RESET, `$FFF9` IRQ)

### 6.1 Cartridge boot hand-off at `$C2CD`

The first real difference is `0x02CD`. The retail cartridge has a 22-byte stub:

```asm
C2CD  A0 14      LDY #$14
C2CF  B9 DA C2   LDA $C2DA,Y
C2D2  99 FF 05   STA $05FF,Y
C2D5  88         DEY
C2D6  D0 F7      BNE $C2CF
C2D8  4C 00 06   JMP $0600
C2DB  A9 18      LDA #$18
C2DD  8D 00 90   STA $9000
C2E0  4C 50 FB   JMP $FB50
```

It copies 20 bytes from `$C2DB-$C2EE` into RAM `$0600-$0613` and jumps to
`$0600`. The copied code executes:

```asm
LDA #$18
STA $9000       ; BF9096: select 64 KB block (value >> 3) & 3 = 3
JMP $FB50
```

A MesenCE trace starting at `$C2CD` with mapper block 2 shows:
`C2CD → C2D8 → $0600 → $FB50`, with `mapper.prgBlock` becoming 3. This is the
4-in-1 cartridge's hand-off into the game's block, not standalone game logic.
The released `START.ROU` has 30 `NOP`s in this position, so the cartridge build
used a patched/integration version of `START.ROU`.

### 6.2 Calls into shifted bank 13

Single-byte differences in the fixed bank are mostly operand bytes of calls
into bank 13, which moved because of the credits/title-sprite changes:

| Offset | Original | Transpiled | Cause |
|---|---|---|---|
| `0x02F3` | `20 06 89` | `20 19 8A` | bank 13 target moved |
| `0x03F0` | `JSR $F695` | `JSR $F69B` | +6 |
| `0x03F3` | `JSR $F6EE` | `JSR $F6F4` | +6 |
| `0x040B` | `DEC $7C2D` | `DEC $7C33` | +6 |
| `0x0417` | `DEC $7C2D` | `DEC $7C33` | +6 |
| `0x057D` | palette `$0D` | palette `$0E` | palette revision |
| `0x1C7F` | `JSR $C2D9` | `JSR $C2DF` | +6 |
| `0x1C84` | `JSR $C2DA` | `JSR $C2E0` | +6 |
| `0x3437` | `JSR $A47E` | `JSR $A484` | +6 |

The instruction streams themselves are the same; only the absolute addresses
are different because the bank-13 layout grew.

### 6.3 `COMPACTEDCHRSTABLE`

Offsets `0x31A8-0x31DD` hold the compacted-CHR pointer table. Entries differ
because the bank-14 CHR payload is shifted by `+0x117`. The transpiled table
points at the transpiled CHR data; it is self-consistent.

### 6.4 Free-space header

At `$FDF0` both banks contain `BANK15` and `TOTAL` bytes:

- Cartridge: `02 09 11 D3` → `B15 = 0x0209` free, `TOTAL = 0x11D3`
- Transpiled: `02 09 10 B6` → `B15 = 0x0210` free, `TOTAL = 0x10B6`

`B15` is the free space from `ED15` to `$FFF9` (`$FFF9 - $FDF0 = 0x209`).
The transpiled build has 7 more free bytes in bank 15 but **285 fewer free
bytes overall**, which is consistent with the later source being about 285
bytes larger (mostly the bank-14 CMLOGO additions and bank-13 text).

### 6.5 Cartridge tail at `$FDF4`

The cartridge contains code-looking bytes at `$FDF4-$FEC6`, e.g.:

```
C1 85 1C A2 0C 86 3A BD 00 86 C5 31 F0 1A ...
```

The transpiled ROM is `$FF` there. This region is **inside bank 15's declared
free space** (`$FDF4` is the first byte after `TOTAL`, and the bank declares
`0x209` free bytes up to `$FFF9`). It is therefore not emitted by `ENDCODE`;
it is leftover content in the cartridge image (the PDS downloader only writes
the assembled blocks, so the rest of the bank retains whatever was there
before). It is not missing source.

`pds_src/src/JUNK` is unrelated: it is a 2,775-byte `HEX` graphics/tile file.

## 7. Conclusion

- `transpiler/out/robinhood.nes` is compiled entirely from the released PDS
  source and assets. No retail PRG bank is embedded or copied in.
- It is **not** the exact retail build. The released source is a **later
  revision**, evidenced by:
  - `CM_YEAR 1993` and the reordered CMLOGO path (cartridge matches the
    commented-out older path),
  - the added `GO DIZZY GO` credit line,
  - the removed third title-screen logo sprite (`titlelogos+1`),
  - the larger overall code size (`TOTAL` free space 285 bytes smaller).

The only true code changes found are:

| Bank / address | Change |
|---|---|
| bank 13 `$9E09-$9E11` | third title sprite (`Camerica` logo) removed: -9 bytes |
| bank 14 `$80B0`+ | CMLOGO 1993 powerup detection, extra screen writes, `MESS93` upload: +279 bytes |
| bank 15 `$C2CD` | cartridge-only 4-in-1 boot/hand-off stub; released source has 30 NOPs |

Everything else is text/data, palette values, pointer tables shifted by the
above, or unused cartridge filler. No new gameplay routines or gameplay
patches were found.
- The cartridge has one integration-only feature the released source lacks:
  the `$C2CD` hand-off stub that selects BF9096 block 3 and jumps to `$FB50`.
- Remaining "differences" in bank 13/15 free space are filler/leftover bytes,
  not source.

So: the released source is **newer than the cartridge**, and a pure build
cannot be byte-identical to retail without reverting post-release source
changes or patching in the cartridge-specific boot stub.

To reproduce the retail bytes exactly, the minimum patch set would be:

1. Restore the commented-out older `CM_LOGO` ordering in `CMLOGO.ROU`.
2. Remove the `cbm "  GO",27," DIZZY GO",27` credits line and restore the
   extra `$F9` before `FIREHAWK`.
3. Restore the third title sprite (`titlelogos+1`, `LDX #$B0/LDY #$C6/LDA #$27`)
   in `TITLE.ROU`.
4. Restore the older palette value (`$0D`) in `MAPDATA.DAT`.
5. Decide whether to inject the `$C2CD` 4-in-1 hand-off stub (standalone builds
   do not need it).

## 8. Reproduce

```sh
cd transpiler
cargo run -- ../pds_src/src out
cd out
make
```

Comparison inputs:

```sh
# original banks 8-11 extracted with MesenCE into /tmp/opencode/orig_bank8.bin ...
# transpiled banks:
dd if=out/robinhood.nes of=/tmp/opencode/ours_b12.bin bs=1 skip=$((0x10))    count=$((0x4000))
dd if=out/robinhood.nes of=/tmp/opencode/ours_b13.bin bs=1 skip=$((0x4010))  count=$((0x4000))
dd if=out/robinhood.nes of=/tmp/opencode/ours_b14.bin bs=1 skip=$((0x8010))  count=$((0x4000))
dd if=out/robinhood.nes of=/tmp/opencode/ours_b15.bin bs=1 skip=$((0xC010))  count=$((0x4000))
```
