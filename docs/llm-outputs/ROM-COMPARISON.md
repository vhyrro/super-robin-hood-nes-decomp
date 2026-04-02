# Transpiled ROM vs. the original Quattro Adventure cartridge

The transpiler in `transpiler/` turns the released PDS sources into a
four-bank mapper-232 ROM. Super Robin Hood occupies logical PDS banks 12–15,
which the original cartridge maps to physical PRG banks 8–11 (file offset
`0x20010` + `bank * 0x4000`).

## Method

The original PRG image was dumped from the running cartridge in MesenCE
through `emu.read(..., emu.memType.nesPrgRom)`. The four banks were then
compared byte for byte with the transpiled ROM banks:

```sh
# extract our banks
for i in 0 1 2 3; do
  dd if=transpiler/out/robinhood.nes \
     of=/tmp/our_bank$((i+12)).bin \
     bs=1 skip=$((16+i*0x4000)) count=$((0x4000))
done
```

## Result

| Ours | Original | Identical bytes | Match | First identical prefix |
|------|----------|-----------------|-------|------------------------|
| bank 12 (map)   | bank 8  | 16,345 / 16,384 | 99.76% | 1,566 |
| bank 13 (music/title/hiscore) | bank 9 | 9,422 / 16,384 | 57.51% | 6,145 |
| bank 14 (logo/CHR) | bank 10 | 156 / 16,384 | 0.95% | 8 |
| bank 15 (fixed code) | bank 11 | 15,819 / 16,384 | 96.55% | 717 |

These are not failures of the assembler. The released source is a later
revision than the cartridge build:

- **Bank 12** differs in exactly 39 palette bytes (`$0E` changed to `$0D`);
  everything else, including the full 16,382-byte map block and its
  `DEFB <B12,>B12` trailer, matches.
- **Bank 13** matches for the first 6,145 bytes. The remaining differences are
  mostly single operand bytes (symbol addresses) and later data/code blocks,
  consistent with source edits and re-assembled addresses.
- **Bank 14** matches its first eight bytes (`LDX #0 / STX $2000 / STX $2001`)
  and then diverges because the shipped `CMLOGO` revision clears RAM
  immediately, while the released source performs the power-up/reset check
  first and clears afterwards.
- **Bank 15** matches 96.55%. The first difference is at `$C2CD`, where the
  shipped ROM contains an extra copy loop and the released `START.ROU` has
  `nops22 do 30 / nop / loop` (30 NOPs). The remaining differences are late
  tables and the ENDCODE area.

A per-region disassembly analysis of every difference is in
[`DISASSEMBLY-DIFF.md`](DISASSEMBLY-DIFF.md).

## Does it run?

Yes. Under MesenCE (`--testRunner`, mapper 232):

- CIC timing lock completes by frame ~10 (previously the PDS `<`/`>` swap made
  it ~28× too long and looked like a hang).
- Bank 13 code executes by frame 30 (`PC=$F329`).
- By frame 240 the PPU is rendering: background and sprites enabled,
  193 non-zero nametable bytes, 2,086 non-zero CHR-RAM bytes, 256 non-zero OAM
  bytes, and the title palette is loaded (`04 1D 28 11 …`).

## Reproduce

```sh
cd transpiler
cargo run -- ../pds_src/src out
cd out && make
```
