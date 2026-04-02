# PDS Reverse-Engineering — Shared Ledger

All agents: append findings here (dated/bulleted), and write long-form docs to
`docs/re/pds/`. Do **not** use Ghidra; one process owns it. Manual facts belong
in the ledger only if they are newly confirmed or contradicted.

## Confirmed: build/bank topology (empirical, 2026-10-31)

- `BANK n` **commits the code assembled since the previous BANK directive as bank n**.
  Source order is therefore: content … `BANK12 DEFB <B12,>B12` … `bank 12` … `ORG &8000` … next content.
- Logical banks 12,13,14,15 map to output files `ROBINV7.BC/.BD/.BE/.BF`
  (physical PRG banks 8,9,10,11 in the shipped ROM).
- Bank 12 `.BC` begins with `MAPDATA.DAT` at $8000 and ends with the
  `DEFB <B12,>B12` header bytes `00 02` at offsets 16382–3 → B12 = 2 bytes free,
  i.e. MAPDATA occupies 16382 bytes in the shipped ROM.
- The provided `MAPDATA.DAT` source assembles to **16382** bytes: 15,976
  `HEX` bytes plus **406** `DEFB`/`DEFS` bytes interleaved between the `HEX`
  runs. It matches `.BC[0:16382]` except **39 palette bytes** (`$0E`→`$0D` at
  `$061E`–`$06A2`); `.BC[16382:16384] = 00 02`. The older “15976 bytes plus a
  ~398-byte insertion” claim was a HEX-only counting artefact (see the
  correction below).
- Bank 13 `.BD` begins with music data (`0d 4c 07 80 …`), filler `0x37` from
  15772 (612 bytes free). Bank 14 `.BE` begins `a2 00 8e 00 20 8e 01 20`
  (`ldx #0 / stx $2000 / stx $2001` = CMLOGO init), filler from 16084.
- Bank 15 `.BF` starts at **$C000** (not $8000): `ORG &C004` in BANK14.PDS
  leaves offsets 0–3 before the first byte (`4c f8 c2` = `jmp pastnops` at
  $C004). `ENDCODE.ROU` puts `ORG $FFF9`, `rti` and the three vectors at the
  end; `.BF` tail `40 07 c0 84 c2 f9 ff` = rti / `$C007` (NMI) / `$C284`
  (RESET=START) / `$FFF9` (IRQ), confirming base $C000 and ORG semantics.
- `b12..b15 equ &C000-EDxx` (bank 14 uses `&BFFF-ED14`, bank 15 `&FFF9-ED15`)
  compute **free bytes**, not size. `T = b12+b13+b14+b15` is total free space.
- Filler for unused bank bytes is `0x37` (at least for banks 13–15); a bank
  file is padded to 16384 bytes.

## Confirmed: downloader/object record layout (from prior binary work)

- Each bank commit re-creates the output file (DOS AH=3C), so a fixed output
  filename overwrites earlier banks. Original names `.BC`…`.BF`.
- Records in the stream: `0xB3` padding, `0xB4` download (start hi/lo, length
  hi/lo, data), `0xB5` execute (hi/lo), `0xB7` select bank (+ bank byte).
- `length==0` means 65536 bytes.

## Confirmed: directive/corpus facts (2026-10-31, from `docs/re/pds/03-directives.md`)

- **Byte-extract operators are swapped vs ca65**: PDS `<expr` = **high** byte,
  `>expr` = **low** byte. Verified: `BANK12.PDS:6 DEFB <B12,>B12` with
  `B12 = $C000-$BFFE = 2` emits `00 02`, which are the last two bytes of
  `ROBINV7.BC`. Any transpiler must swap `<`/`>`.
- **CBM conversion rule (verified against `ROBINV7.BD`)**: `A`–`Z` → `$01`–`$1A`,
  everything else passed through as ASCII. `HISCORE.ROU:393 cbm "PRESS"` →
  `10 12 05 13 13` at `.BD` offset 6957; `"SCORE"` → `13 03 0F 12 05`;
  `"GAME OVER"` → `07 01 0D 05 20 0F 16 05 12`. The corpus' `^` padding emits
  **`$5E`** (ASCII `^`), not screen code `$1E` — PDS does not remap punctuation.
- **BANK = "commit preceding content as bank n" re-confirmed mechanically** by
  `ENDCODE.ROU:30-37`: `bank 12` then `do / org &8000 / defs &4000,0 /
  bank wipebanks / wipebanks = wipebanks+1 / until wipebanks=12`. Only the
  commit-preceding model makes the loop produce banks 0–11 with that 16 KiB
  block. The `BANK` also resets PC: `MUSIC1.MUS:1449 BANK 0` is followed by
  `ORG $FFFA` at :1454.
- **`SUB` (`START.ROU:34`) is a user macro**, not a mnemonic: `MACROS.PDS:504
  sub macro ;does a SEC SBC with any legal addressing mode`. Same for `ADD`
  (`MACROS.PDS:492`), `DJ`, `CHANGEBANK`, `NEGA`, `LDXY`, `MOVE.W`, ….
  Closes the ledger's "is SUB a 6502 mnemonic" question.
- **Undocumented directives found in the corpus** (absent from both manuals):
  `INCBIN file` (`MUSIC1.MUS:1434`, `CHRSETS.CHR:23,64,67,69-71`; label on the
  line gets the first byte), `PATH dir` (`MACROS.PDS:22 path c:\nes\robin`), and
  `OPTION a,b` (`JONSBIT.MUS:49`, `MACROS.MUS:25` = `OPTION 0,0`;
  `MUSIC1.MUS:1464` = `OPTION 0,1`) whose meaning is still unknown.
- **`HEX` operand style in this corpus is concatenated digit pairs**, not
  space-separated bytes: e.g. `MAPDATA.DAT:5 HEX 0001030507080B08…`. 1442 `HEX`
  lines, none with an odd digit count, max 32 bytes on a 69-char line (the
  manual's limit is 57 bytes / 120 chars, unexercised).
- **True-PC ORG idiom**: `CMLOGO.ROU:2637` / `SMILEY.ROU:227` `ORG *,$20`
  (assemble in place, labels resolve at `$20` — a routine copied to zero page),
  restored with `ORG *,*` then `ORG *` (`CMLOGO.ROU:2745-6`,
  `SMILEY.ROU:328-9`). Whether `*` in ORG's first operand is the insertion PC or
  the true PC is **unresolved**: the manual's `ORG *-$100+$8000` example implies
  true PC, while `CMLOGO.ROU:2867 SMILEY_SIZE EQU *-SMILEY` only works if `*`
  is the physical PC after the restore.
- **Bank free-space marker caveat**: `.BC` ends with `00 02` at `$BFFE`, matching
  `BANK12 DEFB <B12,>B12`. The equivalent markers are **not** at the computed end
  offsets of `.BD` (`<B13,>B13` would be `64 02` at `$FD9C`) or `.BE`
  (`2C 01` at `$BED3`); both images end mid-data followed by `$37` filler. Either
  PDS excludes the trailing marker bytes from the committed image, or those
  images come from another revision — do not derive bank sizes from the markers.
- **`.PRJ` `FILE *name` disables that file**: `ROBIN.PRJ:7 FILE *C:\ROBIN\BANK8.PDS`
  skips the "dummy bank for overflowing" file, so the first committed bank is
  bank 12 (via `BANK12.PDS:14`) and `VARS.PDS:242 org &8000` supplies the initial
  PC. Project-file `FILE` is **not** the assembler's `INCLUDE/FILE`.
- **Directive census (assembler files, opcode position only)** for prioritising a
  transpiler: `HEX` 1374 (col 1) / 68 labelled, `DEFB` 656, `EQU` 274, `ENDIF`
  110, `MACRO`/`ENDM` 107 each (4 files), `IF` 81, `DB` 65, `DEFW` 64, `CBM` 55,
  `ERROR` 36, `IFS` 26, `ORG` 22, `DW` 18, `DH`/`DL` 15 each, `LOOP` 10,
  `BANK` 8, `DO` 7, `DS` 3, `FREE` 4, `SEND` 3, `OPTION` 3, `END`/`REPEAT`/
  `TITLE`-as-label 1. **Never used**: `DC`, `STRING`, `TEXT`, `ASC`, `BYTE`,
  `EQUB`, `BLOCK`, `RADIX`, `SKIP`, `EXEC`, `ASK` (only commented), `QUERY`,
  `INCLUDE`, `LISTOPT`, `PAGE`, `WIDTH`, `SKP`, `PRINTER`, `LLIST`, `EXITM` (2),
  `JENDM`, `.DLOAD`.
- **Max `IF` nesting actually used is 4** (`BANK14.PDS:9`); the documented limit
  of 10 and the 250-macro / 100-ORG limits are never stressed.

## Confirmed: source-corpus facts (2026-10-31, corpus inventory)

Full detail: `docs/re/pds/07-source-corpus-inventory.md`; scripts:
`docs/re/pds/tools/corpus_inventory.py` + snippets in §11 of that volume.

- **MAPDATA correction (supersedes the 15976-byte bullet above).** `MAPDATA.DAT`
  assembles to **16382** bytes, not 15976. The 15976 figure counts only its 1134 `HEX`
  lines; the file also has 101 `DEFB` lines + one `DEFS 8,3` = **406** bytes, which sit
  *between* the HEX runs. That is exactly the "~398-byte insertion"/406-byte gap seen
  against `.BC`; there is no shift. Assembled in source order the file is
  **byte-identical to `ROBINV7.BC[0:16382]` except 39 bytes**, all `0E`→`0D`, all in
  `gamepallettes`/`spritecolours` at `$061E`–`$06A2`. `.BC[16382:16384] = 00 02`.
  So the released source is a *slightly later* revision (colour edit), not earlier.
- **`<` / `>` byte extraction is inverted vs. the usual convention:** `<expr` = **MSB**,
  `>expr` = **LSB** (manual confirms, and it is a config switch). Verified on the ROM:
  `BANK12 DEFB <B12,>B12` with B12=2 emits `00 02`; `BANK14 DEFB <B14,>B14` with
  B14=$012D emits `01 2D`.
- **Bank trailers:** `.BC` has `DEFB <B12,>B12` (`00 02` @16382) and `.BE` has
  `DEFB <B14,>B14` (`01 2D`, B14=301 from the `&BFFF-ED14` formula, @16082). `.BF` has
  `BANK15`+`TOTAL` at `$FEA1` = `01 58 1C 8C`: `B15=$0158=344` is exact, but the `TOTAL`
  half (`$1C8C`) does not equal the released-source `T = 2+614+301+344 = $04ED` (stale
  field). `.BD`'s slot at 15770–1 holds `CB E4` instead of `B13=$0266` → `02 66`; note
  `B13` is **614**, not 612 (612 is the filler length).
- **Bank 14 layout is exact where it matters:** `CHRSETS.CHR` output occupies
  `.BE[2922:16082]` and all 12 `INCBIN` payloads (`HISCORE.PP1`, `TOPCHRS`, `BOTCHRS`,
  `ROBINCHR`, `BASECHR`, `BEADCHR`, `BOXCHR`, `ARCHCHR`, `ROCKCHR`, `BEDCHR`, `DOORCHR`,
  `OKCHR`) are byte-identical and contiguous starting at 2927. The `CMLOGO` region does
  not match the repo's `CMLOGO.PP1` and lacks the `"* SMILEY TEST V1.3 "` marker.
- **The live music driver is `MUSIC1.MUS`, not `JONSBIT.MUS`.** `JONSBIT`'s entire
  `ORG $C004` body is inside `IF gav_master=0`; at `gav_master=1` only two `DS 1,0`
  bytes at `ORG 2` remain (addresses $0002–3, outside the bank). `.BD[0..6]` =
  `0D 4C 07 80 4C 66 80` matches `MUSIC1.MUS:222-226` (`ORG $8000`/`DB 13`/two JMPs).
  `incbin data3` at `ORG $86DA` lands at `.BD` offset **1754** = `$06DA` exactly.
- **`CBM` is C64 screen code, confirmed from the ROM:** `cbm "PRESS"` emits
  `10 12 05 13 13` and `"START"` emits `13 14 01 12 14`; found at `.BD` offset 6955
  behind `defb maddr+&23,&0e` = `A3 0E`. (`CBM` = 55 uses: 30 HISCORE + 25 NEWBITS.)
- **`SUB`/`ADD` are project macros, not 6502 pseudo-mnemonics** (closes the open
  question): `MACROS.PDS:492` defines `ADD` (`clc`+`adc`, 1 or 2 operands, 223 uses) and
  `MACROS.PDS:504` defines `SUB` (`sec`+`sbc`, 2 uses: `START.ROU:34 sub #dif`,
  `HISCORE.ROU:91 sub hipos`).
- **Undocumented `!0`** is a start-of-line PC symbol (1 use, `CMLOGO.ROU:2732-2734`:
  `!0 DB "..."` then `IF *-!0 <> 19`). `@@` (evaluated macro parameter) has exactly one
  use (`MACROS.MUS:326 JSR TICKS@@1`); `[lo,hi]` range has one (`MACROS.MUS:293`).
- **Zero-use PDS features in this corpus:** `RADIX`, `SKIP`, `ASK`, `QUERY`, `INCLUDE`,
  `IFF`, `DC`, `STRING`, `BYTE`, `WORD`, `BLOCK`, `DFB`, `DFW`, `DFS`, `.BYTE`;
  mnemonics `BRK`, `CLI`, `CLV`, `SED`, `TSX`; addressing mode `(zp,X)`.
- **Source encoding:** 32/34 build files are bare LF; `BANK8.PDS` and `BANK13.PDS` are
  CRLF. 28/34 contain 1–2 embedded `0x01`/`0x02` editor block marks (sometimes inside a
  token, e.g. `MUSIC1.MUS:174 GLISS_WAIT1\t\x01equ …`), all files end `^Z` except
  `MACROS.PDS`/`VARS.PDS`. One indented `***` comment survives at `MAINLOOP.ROU:23`
  (146 chars), contradicting the manual's "column 1 only" rule.
- **Labels:** 2,139 definitions, 1,617 distinct; 759 are `!` locals; `.` is a legal label
  character (`bank.tbl`, `!T3.3`) and `compchr` *generates* labels whose text is a
  char-range descriptor (`basechr0.157` = table index 5, verified in `.BD`).
- Macro nesting: 107 definitions, 57 never expanded, static max depth 2 (manual allows
  4); `IFS [@n][]` (24 uses) is the optional-argument idiom; `[]` argument grouping is
  never used outside IFS.

## Open questions

- Exact encoding tables / operand-size rules.
- Expression evaluator implementation details (`OPTION 1,1`, `MOD 65535`, byte ops).
- Macro parameter substitution and `IFS` implementation.
- `OPTION a,b` semantics (only `0,0`/`0,1` in corpus).
- Which directives exist in 1.21 vs 1.26: 1.21 table has no `OPTION`, `INCBIN`,
  `PATH`, `WORD`, `BLOCK`, `DEFL`, `JENDM`, dotted aliases (`KEYWORDS.md`); the
  corpus uses the first three, so the shipped build is 1.22+.
- `*` inside `ORG`, first operand, while a true PC is active (see above).
- Whether the `DEFB <free,>free` trailer is part of the committed bank image.
- `INCBIN` pass-2 behaviour (re-read vs reuse pass-1 bytes).

## Confirmed: keyword dispatch table (2026-10-31, static extraction)

- 26-word first-letter bucket table at file offset `0x7072` in `version121_pds6502.exe`.
  DS offset = file offset - `0x930`; bucket values are DS offsets, add `0x930` to get file offsets.
- Each entry is `ASCIIZ(keyword-minus-first-letter)` + `u16 pass1_handler` + `u16 pass2_handler` + `u16 param`.
  Handler addresses are offsets in segment `1e60` (`1e60:XXXX`); the first letter is consumed by the bucket lookup.
- Full extracted list with handler addresses: `docs/re/ledger/KEYWORDS.md`.
- Generic implied/relative instruction handler is `16E4/16E8`, opcode in param; conditional branches `16F2/16FC`.
- No `PROJECT` keyword in 1.21 (`EJECT` exists); `JP` is an undocumented alias of `JMP`.
- Instruction groups: ADC `198F`, AND `1A27`, ASL `176F`, BIT `175C`, CMP `1ABD`, CPX `18D7`, CPY `1901`,
  DEC `195C`, EOR `1B53`, INC `192A`, JMP `170F/172E`, JSR `1740/174A`, LDA `1C7F`, LDX `1E73`,
  LDY `1EBD`, LSR `17C9`, ORA `1BE9`, ROL `1823`, ROR `187D`, SBC `1D15`, STA `1DAB`, STX `1E2E`, STY `1E50`.
- Data: DB family `2AF3/2B34`, DW family `2C6B`, DC `321B/31DE`, DL `355B`, DH `356B`, DS family `3040/307E`,
  HEX `318C`, CBM `3BB8`, STRING `3B76`.
- Control: IF `3090`, IFS `3482`, IFF `3682`, ELSE `30E6`, ENDIF `30F3`, MACRO `3272/326A`, ENDM `3380`,
  EXITM `35FD`, DO `399E`, LOOP `3A14`, UNTIL `3A6A`, REPEAT `396C`, BANK `3A99`, ORG `2A2C`,
  EQU/EQUATE `2E04/2E28`, RADIX `2E56`, INCLUDE/FILE `2E9A`, ASK `357D/2E28`, QUERY `30FD/2E28`,
  SEND `2F57/1269`, SKIP `3450/1269`, EXEC/START `2C78/1269`, ERROR `3533`, FREE `2A17/3A8A`,
  END `2BAE/2B86`, DEBUGSKIP `367C/1269`.
- Listing: LIST/LST `2CA0`, LLIST/LLST `2D72`, LISTOPT/LSTOPT `2A17/38F4`, PRINTER `2A17/3516`,
  PAGE `2A17/37A0`, TITLE/TTL `2A17/3764`, SUBTITLE/STITLE/SUBTTL `2A17/389E`, WIDTH `2A17/3858`, SKP `2A17/38DA`.

## Confirmed: lexical / line grammar (2026-10-31, from `docs/re/pds/01-language-and-lexer.md`)

- **Line model validated mechanically over the whole corpus.** A parser implementing
  "label iff a label char is at column 1; then consume exactly one non-label,
  non-whitespace byte; then skip spaces/tabs; `;` starts a comment" parses **all
  19,394 text lines**. The only 5 lines it cannot classify are `@1<TAB>equ …`
  macro-body label definitions (`MACROS.PDS:25,35,62,66,70`) — direct evidence that
  **macro parameters are substituted textually before lexing**.
- **Stray `0x01`/`0x02` editor block markers are real and pervasive**: 56 bytes in
  30 of 34 text files, at column 1 (47), immediately after a label (3), after a TAB
  before an opcode (1), and mid-line after tokens/quotes (5). Examples:
  `PRTROBIN.ROU:1 \x01flashrobin\tdefb …`, `SPRITESD.DAT:351 pauses\x01\tdefb`,
  `MUSIC1.MUS:174 GLISS_WAIT1\t\x01equ chord_shape1\x02`. They must be **deleted**
  (not replaced by spaces — 3 of them act as the label terminator). `PRTROBIN.ROU`
  is built (`ROBIN.PRJ`, no `*`), and its control-prefixed label is used later, so
  the assembler demonstrably ignores them. Not covered by either manual.
- **Local-label scope rule holds exactly**: 806 `!` definitions (294 spellings),
  1,014 references; treating every non-`!` column-1 label as a scope boundary yields
  **0 same-scope duplicates**. Forward references work inside a scope
  (`SOUNDFX.ROU:273 DW !metal_ball`, defined as `!METAL_BALL` at :586 with no global
  label between) — and this also confirms local labels are **case-folded**.
- **`*` comments are recognised after leading whitespace**, not only at column 1:
  `MAINLOOP.ROU:23` is a live `\t*** … ***` comment inside assembled code. Counts:
  3,253 `;` comment lines (3,098 at column 1, 155 indented) vs 52 `*` comments;
  993 trailing comments after code.
- **`LABEL;` (semicolon immediately after a label) does not exist in the corpus**
  (0 occurrences), but `LABEL<space>;;comment` does (`SPRITESD.DAT:3
  spritetable ;;defw …`), consistent with the manual's terminator rule.
- **Label terminators in practice** (2,178 label lines): TAB 1,475, space 112, EOL
  591; the only non-whitespace terminators used are the 0x01/0x02 markers. Colon and
  `#` terminators are documented but unused.
- **Labels/macros may contain `.` and are not truncated**: max 25 chars
  (`ONSCREEN.ROU:1194 nowcollidebarrelwithrobin`); labels sharing a 20-char prefix
  stay distinct. `hiscorechrs0.43` and `hiscorechrs0.43s` (`UNPACK.ROU:17,19`) are
  different symbols. `bank.tbl`, `move.w`, `!T3.0`, `robinchrs0.255` are single
  identifiers.
- **A directive keyword at column 1 is a label**: `MACROS.PDS:11 title\tequ 1`
  coexists with the `TITLE` listing pseudo-op; `JONSBIT.MUS:149 LOOP` is a real
  label (`JMP LOOP` at :166 etc.), while every `LOOP`/`DO`/`ENDIF` directive in the
  corpus is indented. Local labels `!BANK`/`!SKP`/`!LOOP`/`!END` dodge reserved
  words via the `!` sigil.
- **Operator usage is far rarer than the manual suggests**: `&` as AND only 4×
  (`(@1&32)` etc.), `!` as OR only 2× (`(CLN=30)!(CLN>31)`, no spaces), `%` as MOD
  **0×**, `~` XOR 1 line. `RADIX` is never used; the whole build is radix 10.
- **`EQU` appears as an infix equality operator twice**, both inside **never-invoked**
  macros: `MACROS.PDS:374 if uuu EQU$100` (in `slddr`) and `:590 until mwn EQU 1`
  (in `multword`). Neither `slddr` nor `multword` is called anywhere in the corpus,
  so this is *unverified* and also proves macro bodies are stored, not validated,
  until expansion. Under a greedy identifier scan (`$` is a label char) `EQU$100`
  is one token, so a transpiler needs a decision here.
- **Number syntax confirmed in use**: decimal with leading zeros (`cmp #07`,
  `defb …,00,…` — never octal), unary minus (`lda #-1`, `add16toval …,-8,…`), `&`
  and `$` hex with mixed-case digits (`&7eD`), `%` binary, `*` PC, `>`/`<`
  low/high byte. **No** `0x…`, no `1234h` suffix, no bare-hex with A–F letters.
- **Physical file facts**: 32 LF-only files, 2 CRLF (`BANK8.PDS`, `BANK13.PDS`), 0
  lone-CR files; every text file ends at `^Z` (0x1A); `DATA.MUS` has `^Z` at offset
  135 followed by 4,216 bytes of binary music data (extension is not a content
  guarantee). One line exceeds the 120-char guideline (146 chars, a comment).

## Confirmed/observed 2026-10-31 (volume 05: banking & object format)

Long form: `docs/re/pds/05-banking-and-object-format.md`.

- **CORRECTION to the MAPDATA bullet above.** Assembling `MAPDATA.DAT` in full
  (`HEX` + `DEFB` + `DEFS` + `DW`/`EQU`/labels) gives **16382 bytes** at
  `$8000–$BFFD`, not 15976. The 15976 figure is only the `HEX` bytes; the 398
  `DEFB` bytes (`solidchrs`) and `defs 8,3` are inline and match `.BC`. There is
  **no ~398-byte insertion**. Comparing the assembled stream with `ROBINV7.BC`:
  **51 differing bytes, all in `$860E–$86A2`** — 39 palette first-bytes
  `$0E` (source) vs `$0D` (.BC), and 12 bytes that are forward references to
  `compchr` symbols defined in bank 15 (`basechr0.157`, `rockchr157.99`, …;
  `.BC` values `05 09 05 06 0B 05 08 07 05 06 0A 07`). The released map source
  is therefore the same revision as the ROM bank apart from the palette nibble.
- **CORRECTION to the “bank free-space marker” bullet.** `.BE` *does* carry its
  marker: `$BED2–$BED3 = 01 2D`, and `$BFFF-$BED2 = $012D = 301` exactly. Note
  `b14` uses `&BFFF` (not `&C000`), so the marker is one smaller than the true
  bytes available (302). `.BD` is the only bank whose marker is absent:
  `$BD9A = ED13`, expected `02 66`, observed `CB E4` (music data); the two files
  and the shipped ROM agree on `CB E4`. `.BF`'s 4-byte trailer is at
  `$FEA1–$FEA4 = 01 58 1C 8C` (`B15=344=$FFF9-$FEA1`, exact).
- **`TOTAL` in `.BF` does not add up**: `T=$1C8C=7308`, but
  `b12+b13+b14+b15 = 2+614+301+344 = 1261 ($04ED)`. `B15` matches `.BF`'s own
  filler boundary, so the trailer is genuine; the difference (6047) implies the
  build that wrote `TOTAL` had bank 13 ~6 KiB shorter (`b13=6661`, content
  ~9723 bytes). `.BF` and `.BD` are therefore not from one coherent build —
  do not use `TOTAL` as a checksum of the four repo files.
- **`.BF` `$FFE4–$FFF8` is 21 bytes of non-source code**:
  `08 38 B0 07 68 28 60 EA EA 08 18 CE 03 C0 AD 02 C0 29 02 F0 F4` =
  `PHP/SEC/BCS/PLA/PLP/RTS/NOP/NOP/PHP/CLC/DEC $C003/LDA $C002/AND #2/BEQ`.
  It is a wait-for-PPU-status-bit-1 loop split at the exact addresses declared
  in `MACROS.PDS`: `ANALYZE=$FFE4`, `BREAKPOINT=$FFED`, `CHECKPDS=$FFF2`. No
  project file emits these bytes (no `ORG $FFE4`) and no game code calls those
  symbols. They are PDS downloader/monitor residue that the bank-15 download
  never covered; the shipped ROM has the identical 21 bytes.
- **`.BF` `$C000 = 0F`**, followed by `37 37 37`; the shipped ROM has
  `FE FF FF FF` there. `$0F` = 15 = the bank number, consistent with a bank
  stamp at the base when the first `ORG` is above it (inferred). Never executed
  (RESET = `$C284`).
- **The source's `bank 12` in `ENDCODE.ROU:28/30` contradicts the images.** The
  main payload belongs to bank **15** (BANK15/TOTAL labels, `.BF` content, the
  fixed mapper page at `$C000`). A literal master build would overwrite `.BC`
  with main code. Reproduce the main bank as 15 (or `BANK 15,START`).
- **`SEND MSDOS,<file>` IS implemented in the PC 1.21 binary** (corrects the
  “not supported” reading): static RE finds the keyword compare `MSDOS,` at
  linear `0x2155C`, filename at `DS:0x734E`, destination selector
  `[0x67E0]=0x10`; selector `0x10` does INT 21h `AH=3C` create/truncate
  (linear `0x1FC61`), 128-byte flush `AH=40` (`0x20FE1`), `AH=3E` close. The
  `Only SERIAL and COMPUTERx are supported` string belongs to a *different*
  destination/setup prompt, not the SEND parser. The file gets the same framed
  stream (`B3/B4/B5/B7`) as the wire, is re-created at every bank commit
  (overwrite hazard), and the original tree used one destination per bank
  (`ROBINV7.BC…BF`). The supplied `.B?` files are already flat 16 KiB images
  (no records), so a ROM build has nothing to strip.
- **PC PDS 1.21 cannot load `ROBIN.PRJ`**: the binary has no `project`,
  `asmflag`, `CURCOLOUR`, `COMMENT`, `WINDOW`, `CLOCK` or `ASSEMBLER` tokens
  (no project loader); its editor has 10 source slots (`0.PDS`…`9.PDS`, static
  RE), while the manual's assembly loop is file 0–7. The project has 34 entries.
  Rebuild by concatenating the enabled entries into ≤10 slot files; an
  all-`INCLUDE` master fails because `DO/LOOP/UNTIL` are
  forbidden in include files (`TIMINGS`, `START`, `MAPSCROL`, `CONTROL`,
  `ENDCODE`, `JONSBIT`, `MACROS` all use them). `INCLUDE` cannot nest; the DOS
  requirement is `FILES=20`. The “10-file limit” is therefore the PC editor's
  10 slots (`0.PDS`…`9.PDS`, RE) rather than the manual's 8-file (0–7) loop.
- **ROM comparison** (Quattro Adventure, 256 KiB, mapper 232): `.BC` is
  byte-identical to PRG bank 8 (0 diffs). `.BE` vs PRG 10: 306 diffs (289 are
  `$37` vs ROM `$00/$FF`, 17 real). `.BD` vs PRG 9: 3767 diffs (620 filler, 3147
  real); match through `$86D0`, 9 bytes of `$FF` in the ROM at `$86D1–$86D9`
  where `.BD` has data, match to `$B166`, then the ROM's `$B180–$BFFF` is largely
  a repeating 32-byte `$FF`/`$00` pattern (masked/erased region) where `.BD` has
  music data. `.BF` vs PRG 11:
  7012 diffs (282 filler, 6730 real) — the ROM is a different revision of the
  main bank. Only bank 12 is a bit-exact oracle.
- **Runtime bank table (mapper 232)**: `bank.tbl` at `$C00A–$C019` holds
  `00…0F`; `changebank`/`changebank12rou`/`changebank13rou`/`changebankrou`
  write the bank number N to `bank.tbl+N` (address and data both N). Mapper 232:
  `$8000–$BFFF` = `....BB..` outer 64 KiB block; `$C000–$FFFF` = `.... ..PP`
  inner 16 KiB page, with `$C000` fixed to page 3. Thus writes 12/13/14 select
  pages 0/1/2 (maps/music/chars at `$8000`) and bank 15 is the fixed page 3 at
  `$C000` → PRG 8/9/10/11. The `0..15` table also makes the write value equal
  the ROM byte at the write address (AND-bus-conflict-safe idiom).

## Non-letter keyword table and bare `=` (confirmed)

The A–Z bucket table at file `0x7072` is only consulted when the first
non-space character is `>` `'@'`. Every other first character selects the
default table at file `0x6ACE` (DS `0x619E`). Its entries store the **whole**
keyword (the first character is not consumed):

```
=        p1=3412 p2=3412   ; redefinable assignment (symbol type 2)
.BYTE    36DF/36DF
.WORD    372F/372F
.EQU     2E04/2E28
.RADIX   2E56/2E56
.ASCII   2AF3/2B34
.TEXT    2AF3/2B34
.BLOCK   3040/307E
.ORG     2A2C/2A2C
.LIST    2CA0/2CA0
.INCLUDE 2E9A/2E9A
.MACRO   3272/326A
.ENDM    3380/3380
.END      2BAE/2B86
```

`=` handler `0e60:3412`: requires the current label record `[0x67A4] != 0`
(else DS:0x57D1 “Line must have a label”), evaluates the expression (9325),
rejects a forward reference (bit 8, error DS:0x5B2B), then writes symbol type 2
and the value. `EQU` (`2E04`) is the same code path but writes type 1
(single-assignment). There is no `DEFL` keyword in 1.21: bare `=` is the
redefinable form. `.ORG`/`.BYTE`/etc. are real 1.21 aliases, not later
additions.

## Confirmed: expression evaluator (static analysis of 1.21, 2026-10-31)

Long form: `docs/re/pds/02-expressions.md`. Offsets are file offsets in
`version121_pds6502.exe` (ndisasm; no Ghidra). The 1.21 evaluator is shared by
assembler and monitor.

- **Arithmetic is MOD 65536, not 65535.** The manual says "MOD 65535" twice,
  but the evaluator uses 16-bit `add`/`sub`/`mul`/`div` with no reduction:
  `+` at `0xB0BE`, `-` at `0xB0A1`, `*` at `0xB0CE` (high word discarded),
  `/` at `0xB0B9` (unsigned `div`, DX=0). Consequence: `$FFFF+2` = **1**
  (manual would say 2); `60000+60000` = `$D4C0` (manual `$D4C1`);
  `60000*5` = `$93E0` (manual `$93E4`); `$FFFF+$FFFF` = `$FFFE` (manual 0).
  Use `& 0xFFFF` in any reimplementation. **Contradicts manual §2; ledger open
  question resolved for 1.21.**
- **Byte extraction is `<`=HIGH, `>`=LOW**; configurable swap. Parser reads
  the two chars from `[0xB76]`/`[0xB78]` (`0xAF63`/`0xAF69`). A leading byte
  op parses the **whole remaining expression** (`0xAF6F`) and masks the final
  result (`0xAF3C` low, `0xAF43` high). Mid-expression use bypasses the check
  (`0xAF4C`), so it needs brackets. Verified against
  `START.ROU:17,19`: `$065F+(10/2)*$80 = $08DF`; `ROBINV7.BF` offset `0x289`
  has `A9 0A 85 72 A9 DF 85 70 A9 08 85 71` — the `$08` proves the whole-
  expression binding (primary-only would give `$86`).
- **Unary minus is primary-level**, not expression-level: `0xB18C` sets a
  sign flag, primary parser `0xB192`, `neg ax` at `0xB2AE`. Hence
  `-20/4` = `65516/4` = **16379**, not `-5`. `-(expr)` is invalid; use
  `-1*(expr)`.
- **Actual priority bytes** (`BH`): `!`/`~`=1, `&`=2, comparisons=3,
  `+`/`-`=4, `*`/`/`=5; unary minus inside primary, byte op outside the loop.
  **The manual is wrong to put `&` in the same tier as `!`/`~`**: 1.21 gives
  `&` higher priority. Example `4!1&2` = `4!(1&2)` = 4, not `(4!1)&2` = 0.
  Same-priority operators are left-associative (`0xB00C` reduces on `<=`).
- **Comparisons are unsigned, result 1/0** (`0xB098`, `0xB0FA`; not `$FFFF`).
  So `-1>0` is true and `-1<0` is false. Division by zero = "Division by 0"
  (`0xB103`). Division is unsigned floor.
- **ASCII literals** are 1–2 chars, first char low byte (`"ab"`=`$6261`),
  case preserved; >2 chars = error. Parser `0xB15A`–`0xB169`.
- **`*` = logical PC**: `0xB182` computes `[0x6796]+[0x6798]`; `[0x6798]` is
  the true-PC offset set by `ORG new,true` (`0x11647`–`0x1165D`).
- **Forward refs**: unresolved label returns 0 and sets bit 3 of `[0x67D0]`
  (`0xB1D0`); the expression epilogue (`0xB017`) then forces the **whole**
  expression to 0 and skips the range check. In pass 2/known mode the same
  lookup errors "Cannot find label" (`0xB172`). `EQU`/`=`/`ORG`/`DS`/`IF`
  test the forward bit and reject it; `EQU`/`=` path confirmed in prior ledger
  entry, `ORG` at `0x11661`, `DS` at `0x11C45`/`0x11C5F`, `IF` at `0x11CA4`.
  `IFF` is the forward-ref escape hatch. The manual's `JCC` macro (ordinary
  `IF` around possibly-forward `@2`, then `IFF`) contradicts 1.21's IF
  rejection — flag as an open inconsistency.
- **Range checks** `expr [lo,hi]`: parsed at `0xAF80`/`0x1B11B`, stored at
  `[0x3268]`/`[0x326A]`, flag `[0x326C]`; unsigned check at `0xB021`
  (`jc` below, `ja` above); only one per expression ("Multiple range check");
  bounds are full expressions; value unchanged.
- **OPTION**: not in the 1.21 keyword table, so 1.22+. `version126_read.8`:
  `OPTION 1,1` moves `& ! ~` to highest precedence; `OPTION 1,0` restores
  default. Corpus has `OPTION 0,0` (`MACROS.MUS:25`, `JONSBIT.MUS:49`),
  undocumented/no-op. Exact 1.26 priority numbers and whether `&` keeps its
  edge under option 1 remain unverified (no 1.26 6502 binary in the archive).
- **ca65 porting**: `<`/`>` reversed; ca65 unary byte ops bind to the next
  primary (wrap whole expr); ca65 is ≥32-bit signed (mask `& $FFFF`); ca65
  `!`=boolean NOT, `~`=unary NOT, `&`=bitwise AND at multiplicative priority;
  ca65 has no `&hhhh` hex prefix and no inline `[lo,hi]` range checks. See
  `docs/re/pds/02-expressions.md` §12.

## Confirmed/corrected: macro, conditional and loop subsystem (2026-10-31, volume 04)

Full detail: `docs/re/pds/04-macros-and-conditionals.md`. Tags there: [M]
manual, [C] corpus, [B] 1.21/3.2 binary diagnostic, [I] inferred, [X] conflict.

- **`JENDM` does not exist — it is an OCR artefact.** `PDS_Manual_6502.txt:805-806`
  reads `ENDM ot / JENDM`, but the scanned manual page lists `ENDM`, `.ENDM`,
  `EXITM`; the 1.21 keyword table has no `JENDM`. Treat `ENDM`/`.ENDM` only.
  This corrects `03-directives.md` §MACRO and `09-transpiler-spec.md` §4.1.
- **Macro definition name is column-1; the body is ordinary source.** All 107
  corpus definitions have the name in column 1 after stripping 0x01/0x02 editor
  block markers. Body instructions/directives are indented; only body *labels*
  are column 1. The binary message `A macro must start at the very begining of a
  line.` refers to the definition line. This corrects an assumption in the task
  brief and is visible on the scanned manual p.26-28.
- **Loops cannot nest, and `DO 0`/negative is an error.** 1.21 strings:
  `DO, LOOP and UNTIL cannot be nested`,
  `This parameter must not be zero or minus`,
  `DO, LOOP and UNTIL may not be used in include files`,
  `The LOOP or UNTIL must be in the same section of code as the DO`,
  `There was no DO`, `You forgot to add a LOOP or UNTIL after the last DO`.
  This corrects `03-directives.md` §DO…LOOP ("nested DO blocks work [I]") and
  `09-transpiler-spec.md` §4.4 (it already has the >0 rule).
- **`SKIP n` is a minimum block size, not "skip until address n".** The manual
  (scanned p.34) is explicit: pass 1 records forward-reference-free blocks of at
  least `n` bytes; pass 2 jumps over them. Binary: `Skip must be before any
  ORG's`, `SKIP <xxx> should only appear once`,
  `Skip must be followed by a number >0, about 20 is normal`.
  The "skip until the PC reaches n" wording in `08-assembler-internals.md` §9.4
  and `09-transpiler-spec.md` §4.7 is wrong. Corpus uses: **zero**.
- **`UNTIL` exit-value conflict.** Manual says non-zero exits; the 1.21
  implementation reportedly tests exactly 1 (`08` §9.3). All corpus conditions
  are comparisons returning 0/1 (`until wipebanks=12`, `until mwn EQU 1`), so
  both agree there. Do not use `UNTIL expr` expecting 2 to terminate.
- **`IFS` multi-group is OR (confirmed).** Manual p.24 says the first string is
  compared against *any* of the following (`IFS [FRED] [BILL] [JOHN] [TONY]
  [FRED]` assembles). Disassembly of `0e60:3482` confirms it: the first group
  is copied to `0x6AFC`, each later group is compared against that copy, and
  the handler returns true on the first match; all groups must fail for false.
  All 26 corpus `IFS` uses have exactly two bracket groups, so the corpus alone
  could not distinguish. `[]` is the empty string; `IFS [@n] []` is the
  optional-arg idiom (24 uses).
- **Macro parameter facts confirmed by corpus**: `@1`…`@9` are raw text and can
  be a whole label (`@1 EQU zlim`), a mnemonic (`@2 #@3`), an operand fragment
  (`@1+1`, `#>@1`), a string message (`ERROR "… @1`) or a file path
  (`INCBIN …@1.OBJ`). `@@n` is evaluated; only use is
  `MACROS.MUS:326 JSR TICKS@@1`. `[a,b]` grouping strips the outer brackets
  (`@2 = 45,56,67`, manual p.30) and is not used outside `IFS` in the corpus.
  Missing args expand to empty; extra args are only caught by each macro's
  `IFS [@n][]` check, not by the assembler (max 9; 10th = `Only 9 parameters
  allowed`).
- **Macro/local label scope**: `!name` is a local symbol; locals are cleared at
  every non-`!` column-1 label, at macro entry/exit, and at each `LOOP`/`UNTIL`
  boundary. They are isolated per expansion and per nested macro. A parameter
  whose text is `!1` resolves in the macro's scope, not the caller's. `!0` in
  `CMLOGO.ROU:2732`/`SMILEY.ROU:315` is an ordinary local label at the DB line
  start, **not** a special current-PC token. A bare `!` is invalid
  (`A single local label character is not a valid label`).
- **`MACROS.MUS` byte-order macros are inverted under the verified default.**
  The default is `<`=high, `>`=low (ledger BANK12/14 checks). `MACROS.MUS`
  defines `LOW` as `LDA #<@1` (high) and `HIGH` as `LDA #>@1` (low);
  `VECT`, `VRAM`, `LOAD`, `MOVE`, `FADE` and `WRITE` are correspondingly
  swapped relative to their names/6502 intent. All of these are **uncalled in
  the live build**; the only `LOW`/`HIGH`/`VRAM` calls are in the dead
  `JONSBIT` driver (`gav_master=1`). Either `OPTION 0,0` flips byte order
  (undocumented; `02-expressions.md` treats 0,0 as a no-op) or this is legacy
  code for another assembler. Do not use these macros as byte-order evidence.
- **Real macro library counts/defects**: `MACROS.PDS` 52 (51 normal +
  `cphlde`, whose definition line starts with a 0x01 editor block marker),
  `MACROS.MUS` 39, `SOUNDFX.ROU` 15, `JONSBIT.MUS` 1 (`DJ`, inside false
  `IF gav_master=0`) = 107. `stxy` (`MACROS.PDS:577`) is invalid 6502
  (`STX/STY #imm`) and uncalled. `cpxyvalue` takes one arg, not the
  two its comment suggests. `multword @2=8` shifts 3 times (log2), not 8.
  `sldir` maps `$100`→0 so `CPY #0` copies a full page; `slddr`'s
  `if uuu EQU$100` lacks a space and the macro is uncalled. `sub16fromval`'s
  error text names `sub16from16` (copy-paste).
- **Annotated byte vectors in volume 04**: `zvar`/`var` no bytes;
  `defspr` 5 args `20 FD 08 34 12`, 4 args `20 FD 08 34`;
  `changebank 14` `A9 0E 85 0D 8D 18 C0`;
  `waitforninesprs` `A2 08 A9 20 2C 02 20 F0 FB CA D0 F8`;
  `addto16 address,5` `A5 1B 18 69 05 85 1B 90 02 E6 1C`;
  `add16toval robinxl,±8,robinxl` 14/17 bytes as in §9.5;
  `DO 3` → `00 01 02`; `REPEAT 4 / LSR A` → `4A 4A 4A 4A`.

## Companion tools / data formats (2026-10-31, volume 06)

- `PP1UNPAK` is **not a COM/EXE**: 3,447 bytes of PDS 6502 source (local `!`
  labels, `STXY`, `SETBANK`, `HEX`), the template for `UNPACK.ROU`. API:
  `PP1_DOWNLOAD3` (pointer in X/Y, bank in A) / `PP1_DOWNLOAD2` (pointer in
  X/Y, bank $0D) / `PP1_UNPACK` (ADR1);
  writes 16 bytes/char to `$2007`, returns advanced `ADR1` + `TEMP8`.
- PP1 container: byte 0 = char count (**0 = 256**), then an MSB-first bitstream.
  Per char: 1 bit (1 = reuse header), optional header (for c=3..0: 2-bit type;
  type1/2/3 fold payloads), then 8 rows: 1 repeat bit or [2-bit first pixel +
  7 transitions]. `TEMP4/5` persist **across characters**; row 0 may repeat
  row 7 of the previous char.
- PP1 fold tables are contiguous and overlapping: `FC1=01 00 00 00`,
  `FC2=02 02 01 01`, `FC3=03 03 03 02` (the 4th byte of each is the next
  table's first byte). Transition codes: type1 1=stay/0=fol1; type2
  1=stay/01=fol2/00=fol1; type3 1=stay/01=fol1/001=fol3/000=fol2.
- `docs/re/tools/pp1dec.py` decodes all 15 repo `.PP1` files with exact byte
  consumption; 14 re-pack byte-identically with the real `PP1PACK.EXE`
  (`SOLIDCHR` matches the packer output for 16×FF). Self-check included.
- `PP1PACK.EXE` = TP3 MZ, version 0.3-13/6/91. Max 4096 bytes (256 chars),
  length must be a multiple of 16. `destname` optional (then no file);
  extension never appended. "Predicted size" always equals final size;
  `% = 100*packed/original` (2 dp). Groups = number of new headers (verified:
  BOXCHR 7, BASECHR 64, CHRSET 1, ROBINCHR 106). 0-byte input does not
  terminate. Missing source = TP3 `Runtime error 002 at 0000:0376`.
- `HEX2BIN.COM` is **13,128** bytes (not 12,128), TP3 COM, v1.0-17/7/90.
  Grammar: `HEX` must be preceded by a space/tab somewhere earlier on the line
  (`HEX` at column 1 is ignored); exactly one separator after `HEX`; one
  contiguous run of uppercase digits per line, terminated by space/tab/`;`/`,`.
  Lowercase digits abort with `Bad or missing hex digit at line N`; error line
  number is the physical line, `Read N lines` counts converted statements.
  Odd digit counts read past the string and emit a stale trailing byte
  (e.g. ` HEX 1`→`1E`, ` HEX 123`→`12 2F`) — always use even counts.
- Default target = source with extension replaced by `.BIN`; explicit target
  used verbatim; same-file check happens before the "any key" prompt; target is
  created before conversion, so aborts leave partial/0-byte files.
- `arce.com` = **ARCE 2.08 — Extract ARC files — 12/31/86** (V. Buerg/W. Chin,
  SEA), 5,710-byte COM, extract-only, methods through Crunch (Squash warns
  "not supported"); this is what `dopds.bat`/`ARCE PDS` used to unpack the
  shipped `PDS.ARC` (.dl sources + help files).
- `.dl0/.dl1/.dl2` are **PDS assembly sources** for the target, not binaries:
  `.dl0` = download+execute (+bank), `.dl1` = full monitor (upload/regs/trace),
  `.dl2` = interrupt-driven + analyse (0xBB). Command bytes 0xB3 pad,
  0xB4 down, 0xB5 exec, 0xB6 upload, 0xB7 bank, 0xB8/B9 regs, 0xBA trace,
  0xBB analyse; addresses/lengths big-endian, length 0 = 65536.
  `bbc.dl1` is the outlier: 4-bit nibble handshake on the 6522, only
  B4/B5/B6. `makec64.dl1` is a master builder: autostart vector + title screen,
  copies the embedded DL1 (`ORG *,ADDRESS`) to `$0200`, saves `"D"` via KERNAL.
- `help.65`: plain ASCII/CRLF, 28,160 B, 1,595 lines, 58 topics (`*KEYWORD` in
  column 1, alphabetical), last entry truncated. Two 0x1A bytes at offset
  27,762 sit *inside* "cycles"; 396 bytes of text follow, so not a clean EOF.
- `help.z80`: 23,230 B, no LF, CR line ends, 1,322 NUL pad bytes, 5 high-bit
  bytes, 0x80-byte binary prefix [U]; same `*KEYWORD` topic convention, text
  from ~0x80. Render by dropping NULs/prefix and splitting on CR.
