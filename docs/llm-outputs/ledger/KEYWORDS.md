# PDS 1.21 keyword table (extracted from version121_pds6502.exe)

Addresses are offsets in segment `1e60` (writing `1e60:XXXX`). Keyword table: file 0x6ad0-0x7068; bucket pointer table at file 0x7072 (26 words, A-Z), DS offset = file-0x930.
Entry format: `ASCIIZ(keyword minus first letter)`, then uint16 pass1 handler, uint16 pass2 handler, uint16 parameter (opcode for implied/relative, else 0). Each bucket ends with a 0x00 sentinel.

| First letter | Count | Keywords |
|---|---|---|
| A | 5 | `ADC`, `AND`, `ASL`, `ASC`, `ASK` |
| B | 12 | `BEQ`, `BNE`, `BCC`, `BCS`, `BIT`, `BMI`, `BPL`, `BVC`, `BVS`, `BRK`, `BANK`, `BYTE` |
| C | 8 | `CMP`, `CPX`, `CPY`, `CLC`, `CLD`, `CLI`, `CLV`, `CBM` |
| D | 24 | `DEX`, `DEY`, `DEC`, `DB`, `DW`, `DC`, `DO`, `DL`, `DLOW`, `DH`, `DHIGH`, `DFB`, `DS`, `DEFM`, `DM`, `DEFW`, `DFM`, `DEFB`, `DEFS`, `DFS`, `DOWNLOAD`, `DLOAD`, `DFW`, `DEBUGSKIP` |
| E | 12 | `EOR`, `EQU`, `ELSE`, `ENDM`, `ENDIF`, `END`, `EJECT`, `EXEC`, `EXITM`, `EQUB`, `EQUATE`, `ERROR` |
| F | 2 | `FILE`, `FREE` |
| G | 0 | — |
| H | 1 | `HEX` |
| I | 7 | `INX`, `INY`, `INC`, `IF`, `INCLUDE`, `IFS`, `IFF` |
| J | 3 | `JMP`, `JSR`, `JP` |
| K | 0 | — |
| L | 11 | `LDA`, `LDX`, `LDY`, `LSR`, `LOOP`, `LIST`, `LST`, `LLIST`, `LLST`, `LSTOPT`, `LISTOPT` |
| M | 1 | `MACRO` |
| N | 1 | `NOP` |
| O | 2 | `ORA`, `ORG` |
| P | 6 | `PHA`, `PLA`, `PHP`, `PLP`, `PRINTER`, `PAGE` |
| Q | 1 | `QUERY` |
| R | 6 | `RTS`, `ROL`, `ROR`, `REPEAT`, `RADIX`, `RTI` |
| S | 16 | `STA`, `STX`, `STY`, `SBC`, `SEC`, `SED`, `SEI`, `SEND`, `SKIP`, `SKP`, `SUBTITLE`, `SUBTTL`, `STRING`, `STITLE`, `STR`, `START` |
| T | 9 | `TAX`, `TAY`, `TYA`, `TXA`, `TSX`, `TXS`, `TITLE`, `TTL`, `TEXT` |
| U | 1 | `UNTIL` |
| V | 0 | — |
| W | 1 | `WIDTH` |
| X | 0 | — |
| Y | 0 | — |
| Z | 0 | — |

## Full table

| Keyword | pass1 | pass2 | param |
|---|---|---|---|
| `ADC` | 198F | 198F | 0000 |
| `AND` | 1A27 | 1A27 | 0000 |
| `ASL` | 176F | 176F | 0000 |
| `ASC` | 2AF3 | 2B34 | 0000 |
| `ASK` | 357D | 2E28 | 0000 |
| `BEQ` | 16F2 | 16FC | 00F0 |
| `BNE` | 16F2 | 16FC | 00D0 |
| `BCC` | 16F2 | 16FC | 0090 |
| `BCS` | 16F2 | 16FC | 00B0 |
| `BIT` | 175C | 175C | 0000 |
| `BMI` | 16F2 | 16FC | 0030 |
| `BPL` | 16F2 | 16FC | 0010 |
| `BVC` | 16F2 | 16FC | 0050 |
| `BVS` | 16F2 | 16FC | 0070 |
| `BRK` | 16E4 | 16E8 | 0000 |
| `BANK` | 3A99 | 3A99 | 0000 |
| `BYTE` | 2AF3 | 2B34 | 0000 |
| `CMP` | 1ABD | 1ABD | 0000 |
| `CPX` | 18D7 | 18D7 | 0000 |
| `CPY` | 1901 | 1901 | 0000 |
| `CLC` | 16E4 | 16E8 | 0018 |
| `CLD` | 16E4 | 16E8 | 00D8 |
| `CLI` | 16E4 | 16E8 | 0058 |
| `CLV` | 16E4 | 16E8 | 00B8 |
| `CBM` | 3BB8 | 3BB8 | 0000 |
| `DEX` | 16E4 | 16E8 | 00CA |
| `DEY` | 16E4 | 16E8 | 0088 |
| `DEC` | 195C | 195C | 0000 |
| `DB` | 2AF3 | 2B34 | 0000 |
| `DW` | 2C6B | 2C6B | 0000 |
| `DC` | 321B | 31DE | 0000 |
| `DO` | 399E | 399E | 0000 |
| `DL` | 355B | 355B | 0000 |
| `DLOW` | 355B | 355B | 0000 |
| `DH` | 356B | 356B | 0000 |
| `DHIGH` | 356B | 356B | 0000 |
| `DFB` | 2AF3 | 2B34 | 0000 |
| `DS` | 3040 | 307E | 0000 |
| `DEFM` | 2AF3 | 2B34 | 0000 |
| `DM` | 2AF3 | 2B34 | 0000 |
| `DEFW` | 2C6B | 2C6B | 0000 |
| `DFM` | 2AF3 | 2B34 | 0000 |
| `DEFB` | 2AF3 | 2B34 | 0000 |
| `DEFS` | 3040 | 307E | 0000 |
| `DFS` | 3040 | 307E | 0000 |
| `DOWNLOAD` | 2F57 | 1269 | 0000 |
| `DLOAD` | 2F57 | 1269 | 0000 |
| `DFW` | 2C6B | 2C6B | 0000 |
| `DEBUGSKIP` | 367C | 1269 | 0000 |
| `EOR` | 1B53 | 1B53 | 0000 |
| `EQU` | 2E04 | 2E28 | 0000 |
| `ELSE` | 30E6 | 30E6 | 0000 |
| `ENDM` | 3380 | 3380 | 0000 |
| `ENDIF` | 30F3 | 30F3 | 0000 |
| `END` | 2BAE | 2B86 | 0000 |
| `EJECT` | 2A17 | 3754 | 0000 |
| `EXEC` | 2C78 | 1269 | 0000 |
| `EXITM` | 35FD | 35FD | 0000 |
| `EQUB` | 2AF3 | 2B34 | 0000 |
| `EQUATE` | 2E04 | 2E28 | 0000 |
| `ERROR` | 3533 | 3533 | 0000 |
| `FILE` | 2E9A | 2E9A | 0000 |
| `FREE` | 2A17 | 3A8A | 0000 |
| `HEX` | 318C | 318C | 0000 |
| `INX` | 16E4 | 16E8 | 00E8 |
| `INY` | 16E4 | 16E8 | 00C8 |
| `INC` | 192A | 192A | 0000 |
| `IF` | 3090 | 3090 | 0000 |
| `INCLUDE` | 2E9A | 2E9A | 0000 |
| `IFS` | 3482 | 3482 | 0000 |
| `IFF` | 3682 | 3682 | 0000 |
| `JMP` | 170F | 172E | 0000 |
| `JSR` | 1740 | 174A | 0000 |
| `JP` | 170F | 172E | 0000 |
| `LDA` | 1C7F | 1C7F | 0000 |
| `LDX` | 1E73 | 1E73 | 0000 |
| `LDY` | 1EBD | 1EBD | 0000 |
| `LSR` | 17C9 | 17C9 | 0000 |
| `LOOP` | 3A14 | 3A14 | 0000 |
| `LIST` | 2CA0 | 2CA0 | 0000 |
| `LST` | 2CA0 | 2CA0 | 0000 |
| `LLIST` | 2D72 | 2D72 | 0000 |
| `LLST` | 2D72 | 2D72 | 0000 |
| `LSTOPT` | 2A17 | 38F4 | 0000 |
| `LISTOPT` | 2A17 | 38F4 | 0000 |
| `MACRO` | 3272 | 326A | 0000 |
| `NOP` | 16E4 | 16E8 | 00EA |
| `ORA` | 1BE9 | 1BE9 | 0000 |
| `ORG` | 2A2C | 2A2C | 0000 |
| `PHA` | 16E4 | 16E8 | 0048 |
| `PLA` | 16E4 | 16E8 | 0068 |
| `PHP` | 16E4 | 16E8 | 0008 |
| `PLP` | 16E4 | 16E8 | 0028 |
| `PRINTER` | 2A17 | 3516 | 0000 |
| `PAGE` | 2A17 | 37A0 | 0000 |
| `QUERY` | 30FD | 2E28 | 0000 |
| `RTS` | 16E4 | 16E8 | 0060 |
| `ROL` | 1823 | 1823 | 0000 |
| `ROR` | 187D | 187D | 0000 |
| `REPEAT` | 396C | 396C | 0000 |
| `RADIX` | 2E56 | 2E56 | 0000 |
| `RTI` | 16E4 | 16E8 | 0040 |
| `STA` | 1DAB | 1DAB | 0000 |
| `STX` | 1E2E | 1E2E | 0000 |
| `STY` | 1E50 | 1E50 | 0000 |
| `SBC` | 1D15 | 1D15 | 0000 |
| `SEC` | 16E4 | 16E8 | 0038 |
| `SED` | 16E4 | 16E8 | 00F8 |
| `SEI` | 16E4 | 16E8 | 0078 |
| `SEND` | 2F57 | 1269 | 0000 |
| `SKIP` | 3450 | 1269 | 0000 |
| `SKP` | 2A17 | 38DA | 0000 |
| `SUBTITLE` | 2A17 | 389E | 0000 |
| `SUBTTL` | 2A17 | 389E | 0000 |
| `STRING` | 3B76 | 3B76 | 0000 |
| `STITLE` | 2A17 | 389E | 0000 |
| `STR` | 2AF3 | 2B34 | 0000 |
| `START` | 2C78 | 1269 | 0000 |
| `TAX` | 16E4 | 16E8 | 00AA |
| `TAY` | 16E4 | 16E8 | 00A8 |
| `TYA` | 16E4 | 16E8 | 0098 |
| `TXA` | 16E4 | 16E8 | 008A |
| `TSX` | 16E4 | 16E8 | 00BA |
| `TXS` | 16E4 | 16E8 | 009A |
| `TITLE` | 2A17 | 3764 | 0000 |
| `TTL` | 2A17 | 3764 | 0000 |
| `TEXT` | 2AF3 | 2B34 | 0000 |
| `UNTIL` | 3A6A | 3A6A | 0000 |
| `WIDTH` | 2A17 | 3858 | 0000 |

## Non-letter / dotted default table (file 0x6ACE, DS 0x619E)

Used when the first non-space character is **not** `A`–`Z` (`AL <= '@'` or
`AL > 'Z'`). This table stores **whole** keywords (the first character is not
consumed). Entry = `ASCIIZ(name)` + `uint16 pass1` + `uint16 pass2` +
`uint16 param`, terminated by a `0x00` sentinel.

| Keyword | pass1 | pass2 | param |
|---|---|---|---|
| `=` | 3412 | 3412 | 0000 |
| `.BYTE` | 36DF | 36DF | 0000 |
| `.WORD` | 372F | 372F | 0000 |
| `.EQU` | 2E04 | 2E28 | 0000 |
| `.RADIX` | 2E56 | 2E56 | 0000 |
| `.ASCII` | 2AF3 | 2B34 | 0000 |
| `.TEXT` | 2AF3 | 2B34 | 0000 |
| `.BLOCK` | 3040 | 307E | 0000 |
| `.ORG` | 2A2C | 2A2C | 0000 |
| `.LIST` | 2CA0 | 2CA0 | 0000 |
| `.INCLUDE` | 2E9A | 2E9A | 0000 |
| `.MACRO` | 3272 | 326A | 0000 |
| `.ENDM` | 3380 | 3380 | 0000 |
| `.END` | 2BAE | 2B86 | 0000 |

Notes:
- `=` stores symbol type 2 (redefinable); `EQU` stores type 1
  (single-assignment). There is no `DEFL` in 1.21.
- There is no bare `WORD`, `BLOCK`, `ASCII`, `PROJECT`, `OPTION`, `PATH` or
  `INCBIN` in 1.21.
- The A–Z table above is selected only when the first character is `'A'..'Z'`;
  every other first character falls through to this table.
