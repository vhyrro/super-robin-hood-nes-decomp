# PDS 6502 v1.21 — assembler internals

This volume documents how the PC PDS 1.21 6502 assembler actually works, as
recovered from `version121_pds6502.exe` (the 2003 re-release in
`docs/manuals/PDS_executables.zip`). It is the implementation-level companion to
the language reference (`01`), the directive reference (`03`) and the transpiler
specification (`09`).

Everything here was derived by static analysis. No claim in this document is
based on running the original IDE; where the manual and the binary disagree,
the binary wins and the discrepancy is called out.

## 0. Confidence and conventions

- **Confirmed** — read directly from disassembly, with the instruction
  addresses given.
- **Inferred** — follows from surrounding code but a branch was not traced end
  to end.
- **Open** — unresolved; listed in §12.

Address notation: `0e60:XXXX` is a real-mode address **as loaded**. Ghidra
displays the same code as segment `1e60` because it adds `0x1000` to the
segment number; do not mix the two.

File offset formula for the load module:

```
file_offset = 0x600 + real_segment * 16 + offset
```

Examples:

| Symbol | Real address | File offset |
|---|---|---|
| assembler entry | `0e60:0750` | `0x0F350` |
| main line loop | `0e60:0EC8` | `0x0FAC8` |
| branch encoder | `122b:8A02` | `0x1B2B2` |
| expression evaluator | `122b:86A4` | `0x1AF54` |
| symbol lookup | `122b:916E` | `0x1BA1E` |
| keyword table | DS:0x6742 | `0x7072` |
| keyword entries | DS:0x61A0–0x6738 | `0x6AD0`–`0x7068` |

All rows follow `0x600 + segment*16 + offset`.

The 1.21 executable is an MS-DOS MZ image: header 0x600 bytes, load module
starts at file 0x600, `CS:IP = 122b:0000`, `SS:SP = 0000:0322`. The assembler
proper lives in a separate segment (`0e60`) that the editor far-calls.

## 1. Memory map of the assembler

The assembler does not use a heap. Every table lives at a fixed offset in the
program's data segment (DS, which the loader sets to 0x1033 in the original
memory image; in file terms DS offset = file offset − 0x930).

### 1.1 Output area

| Address | Use |
|---|---|
| `[0x1687]` | segment of the current output buffer |
| `[0x6796]` | current program counter (offset into output segment) |
| `[0x6794]` | PC at the start of the current instruction/line |
| `[0x6798]` | ORG true-PC delta (`truePC − ORG address`) |
| `[0x6778]` | lowest address written in the current block |
| `[0x677A]` | highest address written in the current block |
| `[0x6BFA…]` | block list: start / current end / end, 2 bytes each |
| `[0x83BE…]` | 10-word committed-block descriptors |
| `[0x83CC]` | committed-block counter (max 100) |

`ES:DI` is the write pointer. On every new pass DI is reset to the first
block's start; the bytes written by pass 1 are still there. This is why pass-2
handlers can skip re-emitting instructions (see §5.3).

### 1.2 Assembler state

| Address | Meaning |
|---|---|
| `[0x67D0]` | state bitfield, see §2 |
| `[0x67D2]` | control bitfield, see §2 |
| `[0x67D4]` | expression/block bitfield, see §2 |
| `[0x67D6]` | output/listing bitfield, see §2 |
| `[0x67E2]` | IF state: 0 none, 1 false, 2 true, 3 true+ELSE seen, 4 in ELSE |
| `[0x67CC]` | nested-IF counter while skipping |
| `[0x67DE]` | current radix (default 10) |
| `[0x67E0]` | SEND destination selector (0 = none) |
| `[0x67E4]`, `[0x67E6]` | listing page length / width |
| `[0x67CE]` | number of ORGs seen |
| `[0x67DC]` | macro id counter |
| `[0x67CA]` | macro parameter counter (ASCII `'1'`…`'9'`) |
| `[0x67AE]` | macro/IF/include frame stack pointer (grows down from 0x67F0) |
| `[0x6784]` | symbol-pool allocation pointer |
| `[0x6786]` | current line number / local-label scope id |
| `[0x678A]` | indirect jump target used by END/pass switching (default 0x220F) |
| `[0x678C]` | saved IF state / macro stack pointer |
| `[0x6790]`, `[0x678E]` | saved SP / DI for the assembler invocation |
| `[0x679E]` | EXEC/END start address |
| `[0x67A0]` | end of the macro/symbol pool |
| `[0x67A4]` | current label record (set when a label is defined) |
| `[0x67B2]` | DO counter |
| `[0x67B4]`, `[0x67B6]`, `[0x67B8]` | saved DO source offset / segment / line |
| `[0x83CA]` | SKIP threshold |

### 1.3 Buffers

| Address | Size/use |
|---|---|
| `0x1373` | normalised current line (parse buffer) |
| `0x6B7C` | raw current line (listing copy) |
| `0x6AFC` | scratch/message/output-filename buffer |
| `0x1172` | 512-byte file read buffer, index in `[0x6780]`-family |
| `0x6DA2`… | INCLUDE filename buffer |
| `0x6AFE`… | SEND filename buffer |
| `0x721A`, `0x729A` | listing title / subtitle |
| `0x6E1A` | global symbol hash buckets (512 words) |
| `0x701A` | local (`!`) label buckets |
| `0x5F9E` | 256-byte character-class table used by the symbol hash |

The macro/IF/include frame is **0x104 bytes** and lives below `0x67F0`. Because
frames are pushed for macros, includes and IFs alike, “macro stack” and “IF
stack” in the original are the same stack.

## 2. State bits

### 2.1 `[0x67D0]` — run/pass state

| Bit | Meaning |
|---|---|
| 0x01 | SKIP active |
| 0x02 | EXEC/start address already specified |
| 0x04 | inside an IF (at least one IF active) |
| 0x08 | **forward reference seen on the current line** |
| 0x10 | **pass 1** |
| 0x20 | **pass 2** |
| 0x40 | current source is an INCLUDE/file stream |
| 0x80 | file stream active (buffered disk read) |

Entry `0e60:0750` sets `[0x67D0] = 0x10`. The per-pass initialiser at
`0e60:0EC8` preserves only the pass bits (`and [0x67D0],0x30`) and clears the
rest. At the end of pass 1 (`0e60:08F3`) the assembler tests bit 0x20; if it is
not set it prints the pass-1 progress line, sets bit 0x20 (and, if
`[0x67D6]&0x40`, also bit 0x10 — a re-run of the emitting pass requested by
`BANK`), resets `[0x73CE]`, and re-enters the loop.

Bit 0x08 is per-line, not per-pass: the evaluator sets it when a symbol lookup
fails during pass 1 (`122b:8920`), and `0e60:12A3` clears it after the line has
been fully processed.

### 2.2 `[0x67D2]` — control state

| Bit | Meaning |
|---|---|
| 0x01 | ORG/BANK reset pending |
| 0x02 | EXITM state |
| 0x04 | currently defining a macro |
| 0x10 | skip suppress (macro/IF bookkeeping) |
| 0x20 | start address already set |

### 2.3 `[0x67D4]` — expression/block state

| Bit | Meaning |
|---|---|
| 0x01 | DEBUGSKIP |
| 0x02 | ENDIF seen |
| 0x04, 0x08 | macro/include bookkeeping |
| 0x10 | infinite `DO` active |
| 0x20 | counted `DO` active |
| 0x40 | **this expression referenced a symbol defined later in pass 1** |

Bit 0x40 is the key to phase-stable zero-page encoding; see §5.2.

### 2.4 `[0x67D6]` — output/listing state

| Bit | Meaning |
|---|---|
| 0x08 | an ERROR was raised |
| 0x10 | BANK specified an execute address |
| 0x20 | SKIP was used |
| 0x40 | **BANK has been seen → pass 2 must re-emit data** |
| 0x80 | FREE was used |

Only `BANK` sets bit 0x40 (`0e60:3AC4`). Most data directives and the
instruction pass-2 stubs test this bit: if it is set they run their pass-1
emitting code again, otherwise they merely advance the output pointer.

## 3. Startup and the pass engine

### 3.1 Entry

The editor calls the assembler at `0e60:0750` (the `ASSEM` command's handler is
in the editor segment). Entry:

1. sets `[0x9948]=1`, `[0x67C8]=1`, `[0x95B2]=1`;
2. saves SP/DI in `[0x6790]`/`[0x678E]`;
3. points `[0x678A]` at `0x220F` (the “next pass / finish” jump target);
4. installs its own stack/segment fixups;
5. initialises `[0x60A7]=0x20`, `[0x678C]=0x6D98`, `[0x67CC]=0`,
   `[0x67D0]=0x10`, and clears `[0x67D2]`, `[0x67D4]`, `[0x67D6]`, `[0x67E0]`;
6. calls the main loop at `0e60:0EC8`.

The source for the first pass is not a file: the editor places the text in
memory at `ES=[0x168B]`, `DI=0x304` (normally `0x6000:0304`). The buffered
file reader is used for `INCLUDE`.

### 3.2 Two passes

The assembler always runs exactly two passes over the source, in this order:

1. **Pass 1** (`0x10`): defines labels, expands macros, evaluates what it can.
   Unresolved symbols become zero and set the per-line forward-reference bit.
   Instructions with forward references are sized as absolute (3 bytes).
2. **Pass 2** (`0x20`): symbols must resolve; label addresses are compared with
   the stored values and a mismatch is a `Phase error between passes`. The
   output bytes from pass 1 are reused; only changed data is re-emitted.

Both passes execute the full directive set. This matters for `DO`/`LOOP` and
`IF`: they are expanded in pass 1 and must produce identical control flow in
pass 2, or the phase check fails.

### 3.3 Main line loop (`0e60:0EC8`, `0e60:16FC` region, `0e60:1295`)

Per line:

1. fetch a line into `0x1373` (see §4);
2. skip spaces; empty line, `;` comment or `*` in the first non-blank column →
   next line;
3. handle `ENDIF` / `ELSE` / `IF` / `IFS` / `IFF` inline when an IF is active or
   a macro is being skipped (see §9);
4. parse an optional label in column 1 and record it (pass 1) or phase-check it
   (pass 2);
5. look up the remaining first token in the keyword table (§3.4), call the
   pass-appropriate handler;
6. after the handler, skip spaces and require CR or `;`; otherwise
   `Extra characters on line` (DS:0x5A0B, raised from `0e60:125A` via
   `0e60:21CD`);
7. clear the per-line forward-reference bit, update listing/free counters, loop.

There are two copies of the loop body (`0e60:0EC8` and `0e60:1295`); the second
is entered after an `INCLUDE` line or a macro line has been processed. They are
functionally identical.

### 3.4 Keyword dispatch

- If the first character is greater than `'@'`, the bucket base is
  `word[0x6742 + (char-'A')*2]` (26 entries, A–Z).
- Otherwise the default table at `0x619E` (file `0x6ACE`) is used. It holds the
  non-alphabetic keywords: `=` (handler `3412` both passes), `.BYTE`, `.WORD`,
  `.EQU`, `.RADIX`, `.ASCII`, `.TEXT`, `.BLOCK`, `.ORG`, `.LIST`, `.INCLUDE`,
  `.MACRO`, `.ENDM`, `.END`, in that order, ending with a `0x00` sentinel.
  For this table the whole keyword is stored (the first character is not
  consumed), unlike the A–Z buckets which store the name minus its first letter.
- Buckets are contiguous and end with a `0x00` sentinel.
- Each entry is: `ASCIIZ(keyword without its first letter)`, then three
  little-endian `uint16`: **pass-1 handler, pass-2 handler, parameter**.
- The parameter is the opcode byte for implied/branch instructions, zero
  otherwise.
- The handler is an offset in segment `0e60`; the parameter word is in `BX`
  when the handler is called.

The complete extracted table (129 entries in 1.21) is in
`docs/re/ledger/KEYWORDS.md`. Notable differences from the manual:

- `JP` is an alias for `JMP`.
- `WORD`, `BLOCK` and `ASCII` do **not** exist in 1.21.
- `TEXT`, `ASC`, `STR`, `EQUB`, `DEFB`, `DFB`, `DEFM`, `DM`, `DFM` do exist.
- `PROJECT` does not exist (only `EJECT`).
- `SUB` does not exist; `pds_src/src/MACROS.PDS:504` defines it as a macro.

## 4. Line input, preprocessing and lexing

### 4.1 Memory source

`0e60:0A6E` is the line fetch used for in-memory source (`[0x67D0]&0x40 == 0`):
it reads from `[0x6782]:[0x6780]` (initially `[0x168B]:0x304`) until CR,
copying to `0x1373`; a NUL/`0x1A` ends the source. It also maintains the raw
listing copy at `0x6B7C`.

### 4.2 File/include source

`0e60:0C84` is the line reader for includes. It pulls characters through
`0e60:0D6F`, which reads 512-byte blocks with DOS `INT 21h` AH=3F into
`0x1172`. A short read/EOF stores `0x1A` (Ctrl-Z) into the buffer, which is the
universal end-of-file marker.

`0e60:0D1C` closes the include file, pops the frame, restores the saved line
number and source pointer, and re-enters the main loop.

`INCLUDE`/`FILE` (`0e60:2E9A`) is one level deep only: it errors if the file
flag is already set (DS:0x581A/0x5E36). The filename is taken verbatim to
DS:0x6DA2 up to `;` or CR and opened with AH=3D00. The manual's “no nesting”
rule is real.

### 4.3 Line syntax implemented

The authoritative grammar is in `01-language-and-lexer.md`. The points that
matter to an emulator/transpiler:

- A label is recognised only at the beginning of the line (column 1). One
  non-label character after the label is consumed (so `LABEL:`, `LABEL#` and
  `LABEL;` work; the semicolon is *eaten*, not treated as a comment).
- Label characters are `A–Z a–z 0–9 . _ $`; everything is upper-cased for
  lookup. `!` introduces a local label scoped to the current global label /
  line.
- `;` starts a comment anywhere outside a string.
- `*` in the first non-blank position ignores the whole line.
- Strings are delimited by `"`; a doubled `""` inside a string is an escaped
  quote. The line reader (not the expression parser) handles this.
- A tab is a separator, not part of a label.
- Source files may contain stray `0x01`/`0x02` bytes; see `01` §1.4.

## 5. Instruction encoding

### 5.1 Common structure

Every mnemonic handler is a small state machine over the operand text:

1. skip spaces;
2. identify the addressing form by literal characters (`#`, `(`, `,X`, `,Y`);
3. emit the opcode with `STOSB`;
4. evaluate/copy the operand with the appropriate wrapper;
5. `STOSW` the 16-bit operand when needed;
6. return. The main loop checks the trailing text.

The generic implied handler is `0e60:16E4`:

```
16E4: mov al,bl      ; BL = opcode from the keyword table
      stosb
      ret
```

Its pass-2 counterpart is `0e60:16E8`:

```
16E8: test [0x67D6],0x40
      jne  16E4      ; BANK re-emit
      jmp  1268      ; else skip
```

Branches use `0e60:16F2` (pass 1) / `0e60:16FC` (pass 2):

```
16F2: mov al,bl
      stosb
      lcall 122b:931D   ; branch-offset encoder
      ret

16FC: cmp byte [es:di+1],0
      je  16F2          ; operand byte not yet written
      test [0x67D6],0x40
      jne 16F2
      jmp 1267          ; already emitted
```

`JMP` uses `0e60:170F`/`172E`, `JSR` uses `1740`/`174A`; their pass-2 stubs
have the same “word already nonzero” test.

### 5.2 Zero-page vs absolute

`0e60:1F06` returns ZF=1 for zero-page and ZF=0 for absolute:

```
AX = eval()
if (pass 2) {
    if (AH != 0) return ABS;
    if ([0x67D4]&0x40) return ABS;   // forward-referenced symbol
    return ZP;
}
if ([0x67D0]&0x08) return ABS;       // forward ref on this line
if (AH != 0) return ABS;
return ZP;
```

Consequences:

- A plain operand with high byte zero is zero-page (2 bytes).
- **An operand that references a symbol defined later in the source is always
  encoded absolute (3 bytes) in both passes**, even if it eventually resolves
  to `$00xx`. This is not a size optimisation; it is required for phase
  stability.
- A forward reference in an expression sets the line flag even if other terms
  are known; the whole instruction becomes absolute.
- On pass 2 the same decision is recovered from the `0x40` bit set by the
  evaluator when the symbol record lies at or beyond the current pool pointer.

### 5.3 Immediate and single-byte checks

| Wrapper | Address | Rule |
|---|---|---|
| immediate byte | `122b:8A5A` (via `9321`) | accept `0x0000–0x00FF` and `0xFF80–0xFFFF`; otherwise `Operand must be -128 to 256` (DS:0x3008) |
| single-byte operand | `0e60:1F26` | high byte must be 0; otherwise `Bad operand` (DS:0x56D4) |
| full word | `122b:86A4` (via `9325`) | 16-bit value |

The immediate message says 256 but the maximum accepted is 255.

### 5.4 Branch offset

`122b:8A02` (called through the `122b:931D` trampoline):

```
AX = eval()
if (pass 1 && AX == 0) { emit 0; return; }    // unresolved placeholder
AX = AX - [0x6794] - [0x6798] - 2
if AH == 0x00: require AL <  0x80 else "Relative destination too far ahead"
if AH == 0xFF: require AL >= 0x80 else "Relative destination too far behind"
otherwise:     use the sign of AH to choose ahead/behind
emit AL
```

The range is the standard `+127 / -128`. The error messages include the amount
and `($%X) bytes`.

### 5.5 Operand forms per mnemonic

The handler addresses for all 56 mnemonics are in `KEYWORDS.md`. The forms are
the standard 6502 forms, with these PDS-specific details:

- `#expr` → immediate. **No** `#<`/`#>` special case: the byte operator is part
  of the expression (`lda #>label` = low byte of `label`).
- `(expr,X)` and `(expr),Y` are the only indirect forms. `(expr,Y)` is
  rejected (error `0e60:1A20`).
- `expr,X` / `expr,Y` choose zero-page or absolute via §5.2.
- `LDA expr,Y` is always absolute (`B9`); there is no zero-page,Y form.
- `ASL` (and the other shift/rotate/inc/dec group) accepts an empty operand or
  `A` as the accumulator form. The check is literal: `A` followed by CR, space
  or `;`.
- `JMP (expr)`: the handler emits `6C` and leaves the `(` in the input; the
  expression evaluator parses the parenthesised expression and consumes both
  parentheses. This is why `jmp (address)` works without an extra syntax rule.
- `JSR` accepts only an absolute word (`20`).
- `BIT` accepts only `expr` (`24`/`2C`).
- Mnemonic and register letters are matched upper-case only; the source is
  upper-cased before lookup.

## 6. Expression engine (`122b:86A4`)

### 6.1 Entry points

| Address | Role |
|---|---|
| `122b:86A4` | full expression: clear range state, clear `[0x67D4]&0x40`, skip spaces |
| `122b:86AE` | skip spaces then parse (used for range bounds and parenthesised subexpressions) |
| `122b:86BF` | push the sentinel precedence 0 and parse |
| `122b:86C2` | parse a primary / parenthesised expression |
| `122b:8708` | read the next operator and its precedence |
| `122b:875C` | precedence reduction loop |
| `122b:87B1` | apply an operator |
| `122b:886B` | range assertion `[lo,hi]` |
| `122b:88E2` | primary: number, string, `*`, symbol |

### 6.2 Byte operators

At the very start of an expression, the character in `[0xB76]` (default `>`)
returns the **low** byte of the whole following expression, and `[0xB78]`
(default `<`) returns the **high** byte:

```
if (c == [0xB76]) { consume; AX = parse_whole_expr(); AH = 0; return AX; }
if (c == [0xB78]) { consume; AX = parse_whole_expr(); AL = AH; return AX; }
```

“Whole expression” means the parser is re-entered at precedence 0, so
`>$065f+((num/2)*dif)` negates nothing: it parses `$065f+...` first and then
takes the low byte. The same is true for `<`.

The defaults are stored as the bytes `3E 90 3C 90` at DS:0xB76/0xB78
(file 0x14A6). The assembler's option screen can swap them; the source corpus
and the c64 warning assume `>`=LSB, `<`=MSB.

Mid-expression `>` and `<` are ordinary comparisons (precedence 3), not byte
operators.

### 6.3 Precedence and associativity

From `122b:8708`–`87B0`:

| Precedence | Operators | Notes |
|---|---|---|
| 1 | `!` (OR), `~` (XOR) | lowest |
| 2 | `&` (AND) | |
| 3 | `=`, `<>`, `>`, `<` | comparisons return 1/0 |
| 4 | `+`, `-` | |
| 5 | `*`, `/` | highest |
| 0 | `[` (range), `)` | terminates the expression |

`0x7F` is accepted as an alias for `/`. `<>` is converted internally to `#`
(not equal). The reducer is left-associative: it reduces while the new
precedence is less than or equal to the stacked precedence.

Parentheses recurse through `86AE` (so a byte operator is legal immediately
after `(`).

### 6.4 Arithmetic

- `+`, `-` and `*` are 16-bit wrapping operations; overflow is discarded.
- `/` computes `left / right` with `DX:AX`, unsigned. Division by zero raises
  DS:0x313D.
- **Quirk:** if the current line has the forward-reference bit set
  (`[0x67D0]&0x08`), the `/` operator is skipped entirely and the function
  returns the right operand. Do not rely on division in an expression that also
  has an unresolved symbol; real programs should avoid it.
- Comparisons: `=` and `#`/`<>` return 1 for equal/not-equal; `>` returns 1 if
  left > right; `<` returns 1 if left < right.
- Bitwise `&`, `!`, `~` operate on the full 16-bit value.

### 6.5 Range assertion

`expr [lo,hi]` is parsed by `122b:886B` before the normal operator loop:

1. only one range per expression (`[0x326C]` must be 0, else error 0x3160);
2. parse `lo` with `86AE`, require `,`;
3. parse `hi` with `86AE`, require `hi >= lo`;
4. require `]`, set `[0x326C]=1`.

The range operator has precedence 0, so it ends the expression. At the end of
the expression (`8767`):

- if the line has a forward reference, return 0 without checking (the range is
  checked again on the next pass);
- otherwise, if `[0x326C]` is set and the value is outside
  `[0x3268,0x326A]`, raise the range error (DS:0x316F).

Bounds may themselves be full expressions. If the assembler option at
`[0x9947]` is 1, `[...]` and `{...}` instead act as grouping delimiters, so
range assertions are disabled; this is a compatibility switch, not the default.

### 6.6 Primaries

`122b:88E2`:

- leading `-` toggles DH bit 7; `--` cancels it; the sign is applied to the
  primary value at the end (`neg ax`). It does **not** negate a following
  expression, matching the manual.
- decimal digits are only decimal when `[0x67DE] == 10`; accumulation is
  `CX = CX*10 + digit`, with overflow above 65535 (DS:0x311E).
- `$` or `&` starts hex, up to four digits; overflow sets DS:0x311E; a bad
  digit has its own message.
- `%` starts binary, up to 16 bits.
- `"a"` → `0x0061`; `"ab"` → `0x6261` (first character is the low byte, second
  the high byte). One or two characters only; longer → DS:0x3087.
- `*` → `[0x6796] + [0x6798]`, the current PC plus the ORG true-PC delta.
- anything else is a symbol lookup (`122b:916E`).

### 6.7 Symbol lookup

`122b:916E` computes a hash with the 256-byte class table at `0x5F9E`:

```
hash = 0
for each character:
    hash = (hash << 1) XOR class[char]
```

The length is kept separately. Global symbols are linked from the bucket table
at `0x6E1A` (512 words). Local `!` labels use the table at `0x701A`, indexed by
`(hash - [0x6786]) * 2`; `[0x6786]` is the current line/scope id, which is why
local labels die at the next global label or macro/loop boundary.

Record layout in the symbol pool:

```
[next-link word]
[length/flags byte]
[name bytes…]
[0]
[value word]
```

The pool pointer is `[0x6784]`, initialised to 1. A lookup result in `BX`
(pointing at the record) at or beyond `[0x6784]` means “defined later in this
pass”; that sets `[0x67D4]&0x40`, which forces absolute addressing in pass 2.

On pass 2 an unknown symbol is an error (DS:0x30C3); on pass 1 it sets the
per-line forward-reference bit and returns 0.

## 7. Data and directive handlers

The surface semantics are in `03-directives.md`; this section records the
implementation details that matter for a byte-exact transpiler.

### 7.1 `DB` family (`2AF3` pass 1, `2B34` pass 2)

Pass 1:

- skip spaces;
- if the item starts with `"`, copy characters until the closing quote;
  `""` copies one `"`; a CR before the closing quote is DS:0x570F
  `Missing quote`; each byte is stored with `STOSB`;
- else evaluate with the immediate-byte wrapper (`9321`) and store one byte;
- if the next non-space is `,`, repeat.

Pass 2: if `[0x67D6]&0x40` (BANK), run the pass-1 code; otherwise walk the same
syntax and increment DI once per byte without storing. The pass-1 bytes are
still in the buffer.

`DC` (`321B`) is `DB` plus `or byte [di-1],0x80` on the last character of each
string (and on each numeric byte). `CBM` is a **separate handler** (`3BB8`): it
stores numbers raw, but maps every string character with `AL & $3F` and raises
DS:0x5E5A for any character `>= $60` (lower-case letters are rejected). See
§7.9. `BYTE`, `DEFB`, `DFB`, `DEFM`, `DM`, `DFM`, `ASCII`, `TEXT`, `ASC`,
`STR` all alias the `DB` handler.

### 7.2 `HEX` (`318C`)

Parses the operand as a sequence of hex digit pairs, skipping spaces. Each pair
is stored with `STOSB`; parsing stops at the first non-hex character. A bad
digit raises DS:0x5903. The pass-2 handler advances DI by the same number of
bytes.

### 7.3 `DW` family (`2C6B`)

Loops: increment SI, evaluate a full word (`9325`), `STOSW`, and repeat while
the next non-space is `,`. Strings of one or two characters evaluate as in
§6.6. Little-endian output.

### 7.4 `DL` / `DH` (`355B` / `356B`)

- `DL`: evaluate, clear AH, store one byte.
- `DH`: evaluate, `AL = AH`, store one byte.

Both repeat on commas.

### 7.5 `DS` (`3040` pass 1, `307E` pass 2)

Pass 1: evaluate the count, optionally evaluate a fill byte after a comma (with
the immediate-byte wrapper), then `REP STOSB`. Pass 2: if the BANK re-emit flag
is set, run pass 1; otherwise `ADD DI,AX`.

### 7.6 `ORG` (`2A2C`)

- Increment `[0x67CE]` (max 100; DS error if exceeded).
- Evaluate the address into `[0x67C2]`.
- Optional second expression (after `,`) is the **true PC**:
  `[0x6798] = truePC − address`. The output pointer/PC stays at `address`, but
  `*` and branch calculations use `PC + delta`.
- Reject any forward reference (DS:0x5B2B).
- First ORG: initialise the block list at `[0x6792]+0x6BFC` and set DI to the
  address.
- Later ORGs: if DI equals the previous block end, extend it; otherwise record
  the closed block and commit it via `0e60:2AC8`, then start a new one.
- Update the lowest address `[0x6778]`.

### 7.7 `BANK` (`3A99`)

`BANK n[,start]`:

- clear `[0x67D6]&0xEF`;
- evaluate the bank number with the immediate-byte wrapper;
- optional `,start` sets `[0x67BC]` and `[0x67D6]|=0x10`;
- **pass 1:** set the forward-ref bit and `[0x67D6]|=0x40` (request that pass 2
  re-emits the data), then reset;
- **pass 2:** if `[0x67E0]` (SEND destination) is zero, just reset; otherwise
  for every block in the list, obtain the send routine from
  `cs:[selector+0x16D2]`, send `0xB7`, send the bank byte, then send the block
  bytes;
- reset: `[0x67CE]=0`, `[0x6792]=0`, DI=0, `[0x6796]=0`, `[0x67D2]|=1`.

The reset is why a `BANK` must be followed by an `ORG`; the next content starts
at address 0 otherwise.

### 7.8 `SEND` (`2F57`) and `END`/`EXEC` (`2BAE`/`2C78`)

`SEND` accepts `MSDOS,<filename>` (selector 0x10, filename to DS:0x734E), the
serial aliases (selectors 2/4/6/8) and `COMPUTER0/1/2` (0x0A/0x0C/0x0E).
Unknown destinations raise DS:0x5855.

`END [addr]` commits the final block, sets the optional start address, and
jumps to `0e60:089A` (end of pass). `EXEC`/`START` only set the start address;
a second one is an error (DS:0x5C14). Both reject use inside an include/macro
and reject a forward-referenced address.

### 7.9 `STRING` (`3B76`) and `CBM` (`3BB8`)

`STRING`: each quoted string is copied verbatim (doubled quote → one quote),
then a single `$00` terminator is stored. A numeric expression stores one raw
byte with **no** terminator. Items repeat on commas, so
`STRING 13,"Cat","dog"` emits `0D 43 61 74 00 64 6F 67 00`.

`CBM`: numeric items are stored raw; string characters are translated with
`AL & $3F`; any character `>= $60` raises DS:0x5E5A. Therefore
`A`–`Z`→`$01`–`$1A`, space→`$20`, digits unchanged, `^`→`$1E`. ROM check:
`cbm "FIRST^^^^"` at `ROBINV7.BD` offset 0x1CC5 is
`06 09 12 13 14 1E 1E 1E 1E`.

## 8. Committed blocks and the download stream

Each `ORG`/`BANK`/`END` boundary creates a 10-word descriptor at `0x83BE`:

```
source segment, source offset, PC, instruction PC, ...
bank-base words (0x4000, 0x8000, 0xC000), ...
```

`[0x83CC]` counts descriptors and is capped at 100. `SEND` walks the list of
block ranges at `0x6BFA`.

For `SEND MSDOS` the byte stream is the hardware download protocol, not a raw
binary:

| Byte | Meaning |
|---|---|
| `0xB3` (179) | padding |
| `0xB4` (180) | download: start address hi/lo, length hi/lo, data |
| `0xB5` (181) | execute: address hi/lo |
| `0xB7` (183) | select bank: bank number |
| `0xB6` (182) | upload (not emitted by the assembler) |

Length 0 means 65536. There is no checksum. `BANK` emits `0xB7` before the
bank's blocks. `END addr` / `BANK n,addr` emit `0xB5 addr` after the data.

Because each `BANK` send path re-creates the output file with DOS AH=3C, a
single fixed filename is overwritten by every bank. The original build used
one file per bank: `ROBINV7.BC`, `.BD`, `.BE`, `.BF` for banks 12–15.

## 9. Conditionals, macros and loops

### 9.1 IF state machine

`[0x67E2]`:

| Value | Meaning |
|---|---|
| 0 | not in an IF |
| 1 | in the false branch (skip lines) |
| 2 | in the true branch (assemble) |
| 3 | true branch finished, ELSE seen (skip until ENDIF) |
| 4 | in the ELSE branch (assemble) |

The main loop handles `ENDIF`/`ELSE`/nested `IF` without calling the directive
handler when it is skipping. `IF` (`3090`) pushes the previous state on the
frame stack, clears the IF-active bit when nothing is skipped, evaluates the
expression, and sets state 1/2. `IFS` (`3482`) copies the first literal
`[string]` to `0x6AFC`, then compares each following `[string]` against it
byte-for-byte. It returns **true as soon as one group matches** (the manual's
OR semantics; `[a][b][a]` is true), and false if none match. Empty `[]` matches
empty; whitespace between groups is skipped. `IFF`
(`3682`) is a symbol lookup: the block is assembled when the operand refers to
a symbol defined later (a forward reference). `ELSE`/`ENDIF` dispatcher entries
are error traps; the inline loop normally consumes them.

Limits: 10 nested IFs, one `ELSE` per `IF`. `IF`/`IFS`/`IFF` in a skipped block
increment the nesting counter without evaluating.

### 9.2 Macro definition and expansion

- `MACRO` (`3272`) requires a label (the macro name). Nested definitions are an
  error; the body is read until a line whose first token is `ENDM` and is
  stored backwards in the pool ending at `[0x67A0]`.
- Parameters are positional `@1`…`@9`; the counter starts at ASCII `'1'` and
  errors at `':'` (10th). Named parameters are stored as replacement lines with
  a 6-byte `\r<n> @<name>=` style prefix.
- `@n` substitutes the raw parameter text. `@@n` evaluates the parameter as an
  expression and substitutes the value in the current radix (expansion at
  `0e60:0D9B`, helper `0e60:0E9F`).
- `ENDM` (`3380`) pops a 0x104-byte frame, restoring the source pointer, line
  number and IF state.
- `EXITM` (`35FD`) is only legal inside a macro and an active IF; it restores
  the saved line and frame and leaves the macro.
- Recursion is rejected. The binary limit is depth **3**, not the manual's 4.

### 9.3 DO/LOOP/UNTIL and REPEAT

- `DO` (`399E`) cannot nest (error 0x5CFC) and cannot be used in an include
  (0x5D20). With no operand it sets the infinite bit (`[0x67D4]|=0x10`) and
  saves the source position. With an operand it sets the counted bit
  (`|=0x20`), evaluates the count into `[0x67B2]`; zero or negative is an error
  (0x5D54).
- `LOOP` (`3A14`) requires counted mode; it decrements the counter and either
  clears the bit or restores the saved source position.
- `UNTIL` (`3A6A`) requires infinite mode; it evaluates the expression and
  exits only when the value is exactly **1** (`dec ax; jne repeat`). 0 repeats;
  2 or any other value also repeats. This contradicts the manual's “exits when
  non-zero” wording and matters for source compatibility.
- `REPEAT n` (`396C`) stores `n | 0x8000` in `[0x67AC]`; the main loop repeats
  the following line while decrementing. A negative/forward value errors.

### 9.4 SKIP and FREE

- `SKIP n` (`3450`) is a **pass-1 optimisation hint**, not an address target.
  It must appear before the first `ORG` (`[0x67CE]==0`, else error 0x5AD3),
  may appear only once, and `n` must be > 0; the value is stored in
  `[0x83CA]` and the pass-1 bit is cleared. On pass 1 the assembler records a
  block whenever its size (`PC - [0x83D2]`, the last recorded start) is at
  least `n` and the table is not full (`[0x83CC] < 0xC7`): a 20-byte descriptor
  is written at `[0x83BE]` (source segment/offset, PC, sizes and bank bases)
  and the pointer/count are advanced (`0e60:12B6`–`0x1315` and three parallel
  paths at `0x1334`, `0x1420`, `0x1490`, plus `0x2C0E`). On pass 2 those
  recorded blocks can be jumped over instead of re-parsed. It emits no bytes.
  `BANK` disables the mechanism (`no skip`); overlapping `ORG`s disable it too.
- `FREE n` (`3A8A`) sets `[0x67D6]|=0x80` and adds `n` to the free-space total
  `[0x67BA]`, which is printed in the final statistics. It emits nothing.

### 9.5 EQU, DEFL, RADIX, INCLUDE, ERROR

- `EQU`/`EQUATE` (`2E04`) needs a label on the same line, evaluates without
  forward references, and stores a type-1 record (value word) in the symbol
  pool. Type 1 is single-assignment.
- Bare `=` (handler `3412`, both passes, in the non-letter table) follows the
  same path but stores type 2, which is re-evaluable/redefinable. It also needs
  a label (`[0x67A4] != 0`, else DS:0x57D1 “Line must have a label”) and
  rejects forward references (jumps to the DS:0x5B2B error). There is **no
  `DEFL` keyword** in 1.21; `=` is the redefinition syntax.
- `RADIX` (`2E56`) parses its own argument in base 10, rejects forward
  references, accepts 2–16, and stores the value in `[0x67DE]`.
- `INCLUDE`/`FILE` (`2E9A`) opens one file, saves the current line in
  `[0x677C]`, sets the file bits, and resets the line counter. Nested includes
  are an error.
- `ERROR` (`3533`) copies the message into `0x6AFC`, sets the error bit, and
  aborts through `0e60:21CD`.

## 10. Diagnostics

The full message catalogue is in `docs/re/ledger/FINDINGS.md`; the important
phase and size diagnostics are:

| Message | DS offset | Trigger |
|---|---|---|
| `Bad operand` | 0x56D4 | single-byte context, high byte non-zero |
| `Operand must be -128 to 256` | 0x3008 | immediate outside `0x00–0xFF`/`0xFF80–0xFFFF` |
| `Relative destination too far ahead` | 0x31B4 | branch offset > +127 |
| `Relative destination too far behind` | 0x3187 | branch offset < −128 |
| `This expresion must not contain forward references` | 0x5B2B | ORG/EQU/RADIX etc. with a forward symbol |
| `Phase error between passes` | — | pass-2 PC differs from pass-1 label value |
| `Extra characters on line` | 0x5A0B | unparsed text after an instruction/directive |
| `Must have an ORG at the beginning` | — | first emitted byte before ORG |
| `Only 100 ORG's allowed` | — | `[0x67CE] == 100` |
| `Macros cannot be nested` | — | MACRO inside MACRO |
| `Only 250 macros may be defined` | — | macro pool exhausted |
| `Missing ENDM after the last macro` | 0x5B98 | EOF in a macro body |
| `Only 9 parameters allowed` | — | 10th `@n` |
| `Cannot have more than 10 nested IF's` | — | nested IF counter |
| `DO, LOOP and UNTIL cannot be nested` | — | DO inside DO |
| `Ram or Rom overflow` | — | `DS`/`ORG` beyond 0xFFFF |

Errors are raised through a single dispatcher (`0e60:21CD`) that prints the
message, increments the error count and, for fatal errors, jumps to the
`Assembly aborted` path.

## 11. Version and documentation discrepancies

| Item | Manual | Binary 1.21 | Action for transpiler |
|---|---|---|---|
| `>` / `<` | `>`=low, `<`=high | confirmed, but **configurable** at DS:0xB76/0xB78 | assume defaults; expose a flag |
| `WORD` / `BLOCK` / `ASCII` | listed | absent | accept as aliases only if targeting the manual |
| `PROJECT` | old Apricot PDS | absent | do not emit |
| macro depth | 4 | 3 | reject deeper nesting |
| `DO` nesting | implied possible | rejected | reject nested DO |
| `UNTIL` exit | non-zero | only value 1 | reproduce value-1 semantics |
| `OPTION 1,1` | precedence change | option string exists | treat as opt-in |
| `SUB` | not documented | not a keyword | it is a user macro |
| `JP` | absent | alias for JMP | accept |
| division with forward ref | undefined | returns the divisor | do not rely on it |
| division by zero | error | error DS:0x313D | error |
| compare results | 0/1 | 0/1 | same |

## 12. Open questions

1. `[0x67D6]` bits 0x01/0x04 and `[0x67D2]` bits 0x08/0x10 are only partially
   mapped; they affect macro/listing bookkeeping, not emitted bytes.
2. The 1.26 binaries (`version126_pdsz80.exe`, and the 1.26 6502 build if it
   exists) may differ in the keyword set and macro limits; only 1.21 was
   analysed here.
3. `IFF`'s exact record test at `3682` (whether it uses the pass-2 pool pointer
   or a symbol flag) is inferred from the surrounding code; it behaves as
   “assemble when the operand is a forward reference”.

## 13. What this means for the transpiler

The normative rules are in `09-transpiler-spec.md`. The non-obvious ones that
must be reproduced byte-for-byte are:

1. `>` is low byte, `<` is high byte, and a leading byte operator consumes the
   **entire following expression**, not just the next primary.
2. The evaluator is precedence-based and left-associative, not strict
   left-to-right; comparisons are 0/1; arithmetic wraps at 16 bits.
3. A forward-referenced operand is encoded absolute in **both** passes.
4. `UNTIL` exits only on exactly 1.
5. `IFS` compares raw bytes and is true when the first `[...]` group equals
   **any** later group (OR semantics).
6. `BANK` both commits the preceding block and triggers a second emit pass for
   that data; the transpiler can ignore the pass mechanism but must preserve
   the resulting bytes and bank framing.
7. `ORG addr,truePC` changes `*` and branch targets, not the output address.
8. `EQU` is single-assignment; bare `=` is the redefinable form in 1.21
   (`DEFL` does not exist there).
9. A `BANK` resets the PC; an `ORG` must follow.
10. `@n` is raw text substitution, `@@n` is expression evaluation; this is a
    textual macro system, not a function call.
