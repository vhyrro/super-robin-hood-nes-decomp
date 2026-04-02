# PDS 6502 → ca65 transpiler specification

This is the normative specification for a transpiler that turns PDS 6502
source (the language of `pds_src/src/*.ROU`, `*.PDS`, `*.MUS`) into ca65
assembly that can be built with cc65/ld65 and run on an NES emulator.

It is written against PDS 1.21, the version in
`docs/manuals/PDS_executables.zip`. The implementation details behind every
rule here are in `08-assembler-internals.md`; the surface language is in
`01-language-and-lexer.md` and `03-directives.md`.

The acceptance criterion is byte-exact output: for every bank whose original
image exists (`ROBINV7.BC`, `.BD`, `.BE`, `.BF`), the assembled bank must match
the original bytes, except where the released source is known to be a different
revision (see §9).

## 1. What the transpiler must reproduce

A PDS source file is not a context-free assembly file. The assembler performs,
in one program:

1. physical line handling (CR, tabs, Ctrl-Z, stray control bytes);
2. label/field splitting with PDS's peculiar one-character-after-label rule;
3. textual macro definition and expansion, including `@n`/`@@n`;
4. conditional assembly (`IF`/`IFS`/`IFF`/`ELSE`/`ENDIF`);
5. loop unrolling (`DO`/`LOOP`, `DO`/`UNTIL`, `REPEAT`);
6. a **two-pass** assembly with a symbol table, forward references and
   phase checking;
7. expression evaluation with PDS's operator precedence, byte operators and
   16-bit wrapping;
8. instruction sizing with the “forward reference ⇒ absolute” rule;
9. bank/block framing (`ORG`, `BANK`, `END`, `SEND`).

A naive line-by-line regex translator will fail on 3–8. The recommended design
is a small assembler front-end that emits ca65, not a text substitution tool.

## 2. Architecture

```
source bytes
   │
   ▼
[A] physical reader  ──► lines (with file/line provenance)
   │
   ▼
[B] field splitter   ──► label?, mnemonic, operand, comment
   │
   ▼
[C] macro engine     ──► macro definitions + expanded logical lines
   │                      (textual substitution, local-label renaming)
   ▼
[D] conditional engine ─► only the selected lines survive
   │                      (IF/IFS/IFF/ELSE/ENDIF)
   ▼
[E] loop unroller     ──► DO/LOOP, DO/UNTIL, REPEAT expanded
   │
   ▼
[F] two-pass core     ──► symbols, PC, ORG/BANK blocks, forward refs,
   │                      instruction sizes, data bytes
   ▼
[G] ca65 emitter      ──► .s/.inc files, segments, linker config
```

Stages C–E can share one pass over the source, but they must run **before**
instruction sizing, because macro bodies and loop bodies contain instructions
whose size depends on symbol values.

For a first implementation, run C–E once with a symbol environment populated by
`EQU`/`DEFL`/labels seen so far. The corpus only uses configuration equates
that are defined before their first `IF`, so this works. `IFF` needs the
two-pass core (or a symbol-presence query); see §4.6.

## 3. Stage A/B — lines and fields

### 3.1 Physical input

- End of line is CR (`0x0D`); accept LF and CRLF as a convenience.
- `0x1A` (Ctrl-Z) ends the file.
- Tabs are separators, not part of a label.
- Some released files contain stray `0x01`/`0x02` bytes (see `01` §1.4);
  preserve them as part of the surrounding text or drop them only if they occur
  outside labels/operands.
- A line may be longer than 80 columns; the original truncates around
  `0x13F1` bytes. Do not truncate below that.

### 3.2 Field splitting

PDS recognises a label only when it starts in **column 1**. The label is the
longest prefix of `[A-Za-z0-9._$]`. After the label, **one** non-label
character is consumed as a terminator; this is why all of these are legal:

```
FRED:      ; ':' consumed
FRED#      ; '#' consumed
FRED; comment
FRED       ; whitespace consumed
```

The `FRED;` case is a trap: the semicolon is consumed as the label terminator,
so the text after it is **not** a comment. The comment starts at the next `;`.

If the label is followed immediately by a mnemonic with no separator, the
terminator character is consumed and the rest is the mnemonic field.

Operand/comment split: the first `;` outside a string starts the comment.

A line whose first non-blank character is `*` is ignored entirely.

### 3.3 Output fields for the emitter

Keep, per logical line:

```
{file, line_no, label: Option<String>, mnemonic: Option<String>,
 operand: String, comment: String}
```

Keep the original comment text for the listing/debug output; it does not affect
the ROM, but it makes the generated ca65 readable.

## 4. Stage C/D/E — macros, conditionals, loops

### 4.1 Macro definition

Syntax:

```
NAME MACRO [param1,param2,...]
    ...body...
ENDM
```

- `NAME` is a label in column 1; macros are case-insensitive.
- Positional parameters are `@1`…`@9`. Named parameters may follow `MACRO`;
  they are substituted by name and also counted for `@n`.
- The body may contain `!n` local labels, `IF`/`IFS`, `EXITM`, and nested macro
  *calls* (not nested definitions).
- Maximum 3 nested macro expansions, 250 macros, 9 parameters. Recursion is an
  error.
- `JENDM` is accepted as an `ENDM` alias in the manual; the 1.21 keyword table
  has only `ENDM`, so treat `JENDM` as an extension only if the target source
  needs it (it does not, in this corpus).

Representation: store the body as a list of logical lines with parameter
placeholders. Expansion is textual: substitute `@n` with the raw argument
string and `@@n` with the decimal (or current-radix) value of evaluating the
argument in the caller's symbol environment.

Important details:

- `@n` substitution is raw text, including spaces and commas inside `[...]`
  argument groups. Split macro arguments on commas **outside** `[...]`.
- `@@n` is evaluated at expansion time and formatted in the current `RADIX`
  (default 10). It is not a ca65 expression; it is a literal number.
- A macro call may omit trailing arguments. Missing `@n` expands to empty text.
  This is used by `sub` (`MACROS.PDS:504`) with `IFS [@2][]`.
- Local labels inside a macro (`!1`, `!2`, …) must be renamed per expansion.
  Use a unique expansion counter: `<macro>_<n>_<local>`.
- `EXITM` leaves the current macro expansion immediately. In the corpus it is
  used inside an `IF` inside a macro.

### 4.2 Macro calls

A line whose mnemonic field matches a defined macro name is a call. Macro names
take precedence over instructions/pseudo-ops (the original refuses to define a
macro with an existing keyword name, so there is no ambiguity in valid source).
Arguments are the operand text, split on top-level commas; `[]` groups commas
and is stripped for the substitution? No — the brackets are part of the
argument text and are used by `IFS`; preserve them.

Example from `MACROS.PDS`:

```
sub macro
    ifs [@2][]
    sec
    sbc @1
    else
    ifs [@3][]
    sec
    sbc @1,@2
    endif
    endif
endm
```

`sub #dif` expands with `@1="#dif"`, `@2=""`, `@3=""`; the first `IFS` is true
(empty equals empty), producing `sec / sbc #dif`.

### 4.3 Conditionals

`IF expr` … `ELSE` … `ENDIF`:

- Evaluate `expr` with the current symbol environment.
- A forward reference in `IF` is an error in PDS. In the transpiler, if a
  symbol is unknown, report an error rather than guessing (except `IFF`).
- `ELSE` selects the other branch; at most one.
- Nesting: 10 levels in 1.21.
- `IF` inside a skipped branch is not evaluated; only the nesting depth is
  tracked.

`IFS [s1][s2]...`:

- The first group is compared against **each following group**; the result is
  true if **any** group matches it (OR semantics — this is what `0e60:3482`
  implements and what the manual's five-group example requires).
- Comparison is byte-for-byte and case-sensitive.
- Empty `[]` is the empty string.
- The comparison is done on the raw text after macro substitution.
- This is the workhorse of the corpus (26 uses) and is how optional macro
  arguments are tested.

`IFF symbol`:

- Assembles the branch when `symbol` is a forward reference at that point
  (i.e. it is not defined yet). This is the manual's wording and matches the
  handler's symbol-table test.
- In a one-pass transpiler, treat it as “symbol is not currently in the symbol
  table”; in a two-pass core, use the pass-1 “defined later” record.

`ELSE`/`ENDIF` must not have labels (PDS errors if they do).

### 4.4 `DO` / `LOOP`

```
do count
    ...body...
loop
```

- `count` is evaluated once, at the `DO`, and must be > 0.
- The body is assembled `count` times.
- Local labels (`!n`) are cleared at each `LOOP`, so each iteration gets a fresh
  local-label scope.
- `DO` cannot nest in 1.21 (error), so a transpiler can implement it with a
  simple loop over the stored body.

### 4.5 `DO` / `UNTIL`

```
do
    ...body...
until expr
```

- The body is assembled repeatedly until `expr` evaluates to **exactly 1**.
- `0` and any value other than `1` repeat. This is the binary's behaviour and
  differs from the manual's “non-zero exits” wording.
- `DO`/`UNTIL` cannot nest and cannot be used inside an include.

A transpiler can unroll this at assembly time only if the loop is statically
bounded. If it is not, report an error; PDS itself would loop forever.

### 4.6 `REPEAT`

`REPEAT n` repeats the **following line** `n` times. `n` must be a positive
constant. Implement it by duplicating the next logical line in the IR.

### 4.7 `SKIP`

`SKIP n` is a pass-1 optimisation hint used before the first `ORG`, not an
address target: PDS records source blocks of at least `n` bytes in a skip
table so pass 2 can jump over them. It has no effect on the emitted bytes. A
transpiler may ignore it, but should validate that it appears once, before any
`ORG`, with `n > 0` (PDS errors otherwise); `BANK` disables the mechanism.

## 5. Stage F — the two-pass core

### 5.1 Symbols

- Names are case-insensitive; upper-case all names for lookup, but keep a
  display name for diagnostics.
- Valid characters: `A-Z a-z 0-9 . _ $`. `!` starts a local label.
- A local label is scoped to the current global label and to the current
  `MACRO` expansion / `DO` iteration. Rename it at expansion time; do not rely
  on ca65's `@` locals for this, because PDS's scope reset points differ.
- `EQU` is single-assignment. Bare `=` is the redefinable form in 1.21
  (`DEFL` is not a keyword there, despite the manual).
- A label and an `EQU` for the same name on the same line are the normal
  constant form; `EQU` requires a label.
- Duplicate definition on pass 2 is an error.
- `*` is the current PC plus the ORG true-PC delta.

### 5.2 Two passes

Pass 1:

- assign addresses, define labels;
- evaluate expressions; unknown symbols become 0 and mark the line as having a
  forward reference;
- size instructions: if the line has a forward reference, use the absolute
  form; otherwise use zero-page if the value is `< 0x100`;
- do not emit final bytes (or emit into a scratch buffer).

Pass 2:

- all symbols must resolve;
- re-evaluate and emit bytes;
- compare each label's address with the pass-1 value; mismatch is a phase
  error.

The forward-reference rule is the subtle part. The original stores a per-line
flag and a per-symbol “defined later” bit, and uses them to force absolute
addressing in both passes. A transpiler can implement it more simply:

```
size(operand) =
    if operand references any symbol not yet defined in pass 1:
        absolute (2-byte operand)
    else if value <= 0xFF:
        zero-page (1-byte operand)
    else:
        absolute
```

and then use the same size in pass 2. This yields identical bytes.

### 5.3 Blocks and PC

- `ORG addr[,truePC]` sets the output PC to `addr`; `truePC` sets the value
  reported by `*` and used by branch calculations:
  `pc_delta = truePC - addr`.
- `BANK n` closes the current block, starts a new bank, and resets the PC to 0.
  An `ORG` must follow.
- `END [addr]` closes the final block.
- `DS` advances the PC and fills; `FREE` does not advance.
- `EQU` does not advance.

The transpiler does not need to reproduce the original's in-memory block list;
it needs the same addresses and the same bank boundaries.

## 6. Expressions

### 6.1 Grammar

```
expr        := or_expr
or_expr     := xor_expr (('!' | '~') xor_expr)*
xor_expr    := and_expr ('~' and_expr)*        // see note
and_expr    := cmp_expr ('&' cmp_expr)*
cmp_expr    := add_expr (('='|'<>'|'>'|'<') add_expr)*
add_expr    := mul_expr (('+'|'-') mul_expr)*
mul_expr    := unary (('*'|'/') unary)*
unary       := ('>' | '<') expr | '-' unary | primary
primary     := number | string | '*' | symbol | '(' expr ')' | '[' expr ']'
```

The actual precedence table (from `08` §6.3) is:

| Level | Operators | Associativity |
|---|---|---|
| 1 | `!` OR, `~` XOR | left |
| 2 | `&` AND | left |
| 3 | `=`, `<>`, `>`, `<` | left |
| 4 | `+`, `-` | left |
| 5 | `*`, `/` | left |

`!` and `~` are both level 1, not separate levels. `<>` is not-equal. Do not
confuse unary `>`/`<` (only at the start of an expression) with binary
comparison `>`/`<` (level 3).

### 6.2 Values

- All values are 16-bit and wrap on `+`, `-`, `*`.
- Division is unsigned and floors; divide-by-zero is an error.
- Comparisons return 0 or 1.
- Decimal literals: `[0-9]+` in the current radix (default 10).
- Hex: `$` or `&` followed by up to four hex digits.
- Binary: `%` followed by up to 16 bits.
- Character literals: `"a"` = `0x0061`, `"ab"` = `0x6261` (first char low).
  Only 1–2 characters.
- `*` = current PC.
- A leading `-` negates the primary; `--` cancels.
- A trailing range `[lo,hi]` checks `lo <= value <= hi`; it is a separate
  syntax, not array indexing.
- `RADIX n` changes the default base for decimal-looking literals; the `RADIX`
  argument itself is always decimal.

### 6.3 Byte operators (the biggest compatibility trap)

In PDS:

```
>expr   → low byte of the whole following expression
<expr   → high byte of the whole following expression
```

The operator applies to the **entire remaining expression**, not just the next
primary. So:

```
lda #>$065f+((num/2)*dif)
```

means `low_byte($065f + ((num/2)*dif))`, not `(low_byte($065f)) + ...`.

ca65 uses the opposite convention: `<expr` is low, `>expr` is high, and the
unary operator binds tightly. Therefore emit:

```
PDS  >expr   →  ca65  <(expr)
PDS  <expr   →  ca65  >(expr)
```

The parentheses are mandatory to reproduce the whole-expression scope.

Mid-expression PDS `>`/`<` are comparisons, not byte operators. They map to
ca65's comparison? ca65 has no expression comparison operators that return
0/1 in the same way; evaluate them at transpile time when both sides are
constant, or emit a helper. In this corpus, mid-expression comparisons are
rare; document and fail loudly if one is found in a non-constant context.

### 6.4 Forward references

A symbol that is not yet defined in pass 1:

- contributes 0 to the expression;
- marks the line as having a forward reference;
- makes the instruction absolute, not zero-page;
- makes `IF`, `ORG`, `EQU`, `RADIX`, `SKIP` and `END addr` errors (they require
  known values).

### 6.5 Division quirk

If a line has a forward reference and also uses `/`, PDS skips the division and
returns the right operand. This is a bug, not a feature. The transpiler should
either reproduce it (for byte-exactness) or reject it with a clear diagnostic.
The corpus does not rely on it; rejecting is safer.

## 7. Instruction translation

### 7.1 Mnemonics

PDS mnemonic set is the standard 6502 set plus `JP` = `JMP`, and minus `SUB`
(which is a user macro). Translate:

| PDS | ca65 |
|---|---|
| `JP` | `jmp` |
| everything else | same mnemonic (lower-case is fine) |

### 7.2 Operand forms

| PDS | ca65 | Notes |
|---|---|---|
| `#expr` | `#(expr)` | immediate; PDS byte ops already converted |
| `expr` | `expr` | auto ZP/ABS rule applies |
| `expr,X` | `expr,x` | |
| `expr,Y` | `expr,y` | |
| `(expr,X)` | `(expr,x)` | |
| `(expr),Y` | `(expr),y` | |
| `(expr)` for `JMP` | `(expr)` | indirect JMP |
| `A` or empty | `a` or empty | accumulator form |
| `(expr,Y)` | — | PDS rejects it; do not emit |

The ca65 assembler will make its own zero-page/absolute choice. To reproduce
PDS exactly, **force the size** where it matters:

- PDS absolute form when the operand is a forward reference: emit an explicit
  absolute expression. In ca65, a symbol that is later defined may still be
  chosen as zero-page if its value is <$100. Use `a:` (absolute) or
  `.byte`-level encoding to force it.
- PDS zero-page form when the operand is a known value <$100: ca65 will choose
  zero-page automatically.
- For `LDA expr,Y`, PDS always uses absolute (`B9`); ca65 will do the same
  because there is no zero-page,Y form.

If exact bytes matter more than readability, emit instructions as `.byte`
sequences computed by the transpiler. A hybrid is recommended: emit normal
ca65 instructions for known-size operands and `.byte` for forward-referenced
zero-page candidates.

### 7.3 Implied/accumulator

PDS accepts an empty operand or `A`; ca65 accepts both. Beware `ASL A` vs
`ASL`; emit `asl` for the empty form and `asl a` for the explicit form.

### 7.4 Branch ranges

PDS enforces `-128…+127`. ca65 will also error, but the message differs. The
transpiler should compute the offset itself to report the PDS-style error
(“too far ahead/behind”) and to guarantee the same bytes.

## 8. Directive translation

| PDS | ca65 / action |
|---|---|
| `DB`, `DEFB`, `DFB`, `BYTE`, `EQUB`, `DEFM`, `DM`, `DFM`, `TEXT`, `ASC`, `STR`, `.ASCII` | `.byte` with converted items |
| `DC` | `.byte` with last char of each string (and each numeric byte) ORed with `$80` |
| `CBM` | `.byte` with ASCII→C64 screen code conversion (`AL & $3F`; `>= $60` is an error) |
| `DW`, `DEFW`, `DFW`, `.WORD` | `.word` |
| `DH`, `DHIGH` | high byte of each expression, `.byte` |
| `DL`, `DLOW` | low byte of each expression, `.byte` |
| `DS`, `DEFS`, `DFS`, `.BLOCK` | `.res count, fill` |
| `HEX` | `.byte $xx,$xx,...` |
| `STRING` | `.byte "text", 0` |
| `EQU`, `EQUATE` | `name = expr` |
| `=` (and `DEFL` only on later PDS) | `name = expr` (redefinable) |
| `ORG addr[,truePC]` | `.org addr` in the current segment; `truePC` only affects `*`, so model it in the expression evaluator |
| `BANK n` | start a new segment for logical bank `n` |
| `END [addr]` | close the segment; optionally record the execute address |
| `EXEC`, `START` | record the execute address |
| `FREE` | ignore (statistics only) |
| `ERROR` | emit `.error "message"` |
| `IF`/`ELSE`/`ENDIF` | `.if`/`.else`/`.endif` **or** resolve at transpile time |
| `IFS` | resolve at transpile time |
| `IFF` | resolve at transpile time |
| `DO`/`LOOP` | unroll |
| `DO`/`UNTIL` | unroll if statically bounded |
| `REPEAT` | duplicate the next line |
| `SKIP` | ignore (hint) |
| `INCLUDE`, `FILE` | inline the file (PDS has no nesting) |
| `MACRO`, `ENDM`, `EXITM` | expand at transpile time |
| `RADIX` | update the numeric base used by the evaluator |
| `LIST`, `LLIST`, `PRINTER`, `PAGE`, `TITLE`, `SUBTITLE`, `WIDTH`, `SKP`, `LISTOPT` | ignore for the ROM; optionally reproduce in a listing |
| `SEND` | ignore for ROM; optionally emit a framed `.bin` for oracle testing |
| `ASK`, `QUERY` | not used in the corpus; resolve from a config or fail |

### 8.1 `DB` details

- Strings: `"abc"` emits `a b c`; `""` inside a string is an escaped quote.
- A string may be mixed with expressions: `DB "AB",0,$ff`.
- `.byte "AB"` in ca65 emits the same bytes, but ca65 string escapes differ;
  convert to a byte list for full control.
- Negative values are accepted in the range `-128…255`; ca65 `.byte -1`
  emits `$FF`, which matches.

### 8.2 `DC` details

`DC "ABC"` emits `A B C|$80` — only the **last** byte of each string gets bit
7 set. For a single-character string, that is `C|$80`. Implement by emitting
the string bytes and ORing the last one.

### 8.3 `CBM` details

`CBM "ABC"` emits Commodore screen codes, not ASCII: the handler (`3BB8`)
masks each character with `$3F` and rejects any character `>= $60`. So
`A`–`Z` → `$01`–`$1A`, digits stay `$30`–`$39`, space stays `$20`, and
`^` (`$5E`) → `$1E`. Numeric items are emitted raw. CBM is used 46 times in
the game source (mostly UI text); ROM evidence is in `03-directives.md`.

### 8.4 `DS` details

`DS count[,fill]` emits `count` copies of `fill` (default 0) and advances the
PC. In ca65, `.res count, fill` works inside a segment. If `fill` is an
expression, evaluate it first.

### 8.5 `STRING`

`STRING "text"` emits the text followed by a 0 terminator. Multiple strings are
allowed; each gets its own terminator. A numeric item is emitted as one raw
byte with **no** terminator (`STRING 13,"Cat","dog"` → `0D 43 61 74 00 64 6F
67 00`).

### 8.6 `ORG` / `BANK` / `END` for NES

The game uses logical banks 12–15, which map to PRG banks 8–11 of a 16-bank
Mapper 232 image. The original build produced one 16 KB file per bank, padded
with `$37`.

Recommended ca65 layout:

```
.segment "BANK12"   ; $8000-$BFFF, fill $37
.org $8000
...
.segment "BANK13"
.org $8000
...
```

with a linker config:

```
MEMORY {
    HEADER: start=$0000, size=$0010, type=ro, file=%O, fill=yes;
    PRG0:   start=$8000, size=$4000, type=ro, file=%O, fill=yes, fillval=$37;
    ...
}
SEGMENTS {
    HEADER: load=HEADER, type=ro;
    BANK12: load=PRG8, type=ro;
    ...
}
```

For bank 15, the base is `$C000` because `BANK14.PDS` ends with
`org &c004`. Preserve the `ORG` values from the source; do not assume every
bank starts at `$8000`.

The bytes at the start/end of each bank (`BANK8 DEFB <B8,>B8`, etc.) are
ordinary data, not linker metadata. Do not synthesize them.

### 8.7 `SEND`

For an emulator ROM, ignore `SEND`. For oracle testing, optionally emit the
framed stream described in `08` §8: `$B3` padding, `$B4` download records,
`$B7` bank select, `$B5` execute. The original `SEND MSDOS` output is the only
way to compare against the original toolchain's framing.

## 9. Byte-exactness and the original bank images

The four reference images in `pds_src/src` are the best oracle:

| File | Logical bank | Size | Notes |
|---|---|---|---|
| `ROBINV7.BC` | 12 | 16384 | byte-identical to shipped ROM PRG bank 8 at 0x20010 |
| `ROBINV7.BD` | 13 | 16384 | diverges from the shipped ROM after ~1745 bytes |
| `ROBINV7.BE` | 14 | 16384 | diverges after ~1066 bytes |
| `ROBINV7.BF` | 15 | 16384 | not identical to the shipped ROM bank 11 |

Known revision differences:

- `MAPDATA.DAT` in the release assembles to 16,382 bytes (`HEX` + `DEFB` +
  `DEFS`) and matches `ROBINV7.BC[0:16382]` except 39 palette bytes
  (`$0E`→`$0D` at `$061E`–`$06A2`). The earlier “15976 bytes / 398-byte
  insertion” figure counted only the `HEX` lines.
- Bank 13/14 diverge early for the same reason (later source changes).
- Bank 15's base is `$C000`, and its vectors are `$C007` (NMI), `$C284`
  (RESET=START), `$FFF9` (IRQ), matching `ENDCODE.ROU`.

Use the images to validate:

1. bank boundaries and sizes;
2. `ORG` bases;
3. `$37` fill;
4. the header/free-space bytes (`DEFB <bN,>bN`) and `T EQU ...`;
5. instruction encoding for the stable prefix.

Do not expect a full-image match for banks 12–14; the released source is a
different revision.

## 10. Test vectors

### 10.1 Expression evaluator

| Expression | PDS value | Why |
|---|---|---|
| `10-2*3` | 4 | precedence, not left-to-right |
| `2+3*6` | 20 | |
| `-20/4` | 16379 | negative primary then unsigned division |
| `>$1234` | `$34` | `>` = low byte |
| `<$1234` | `$12` | `<` = high byte |
| `>$065f+((10/2)*$80)` | `$DF` | byte op applies to whole expression |
| `"ab"` | `$6261` | first char low |
| `5>3` | 1 | comparison |
| `3>5` | 0 | comparison |
| `5<>3` | 1 | not equal |
| `1!2&0` | 1 | OR level 1, AND level 2 |
| `5 [1,10]` | 5 | range ok |
| `11 [1,10]` | error | range fail |
| `1/0` | error | divide by zero |

### 10.2 Encoding

| Source | Bytes | Why |
|---|---|---|
| `lda #$10` | `A9 10` | immediate |
| `lda $10` | `A5 10` | known zero-page |
| `lda later` where `later=$10` | `AD 10 00` | forward ref ⇒ absolute |
| `lda later,x` | `BD 10 00` | forward ref ⇒ absolute,X |
| `lda ($10),y` | `B1 10` | indirect indexed |
| `lda ($10,x)` | `A1 10` | indexed indirect |
| `jmp (vec)` | `6C lo hi` | indirect JMP |
| `asl` / `asl a` | `0A` | accumulator |
| `beq label` (offset 0) | `F0 00` | branch |
| `beq far` (offset +200) | error | out of range |

### 10.3 Macro/conditional

| Source | Result |
|---|---|
| `IFS [a][a]` | true |
| `IFS [a][A]` | false (case-sensitive) |
| `IFS [][ ]` | false (space is a character) |
| `IFS [@2][]` with missing `@2` | true |
| `@@1` with `@1="2+3"` | `5` (evaluated, current radix) |
| `@1` with `@1="2+3"` | `2+3` (raw text) |
| `DO 3 / nop / LOOP` | three `nop`s |
| `DO / ... / UNTIL 1` | one iteration |
| `DO / ... / UNTIL 2` | infinite (quirk: only 1 exits) |
| `REPEAT 3` before `nop` | three `nop`s |

### 10.4 Bank/framing

- `BANK 12` then `ORG $8000` then `DB 1,2` then `BANK 13` produces a bank-12
  block containing `01 02` at `$8000` and a `$B7 0C` record in the send stream.
- `BANK 12,$8000` additionally emits `$B5 80 00` after the data.
- `END $8000` emits the final execute record.
- `ORG $C004` in bank 15 places the first byte at `$C004`; bytes `$C000–$C003`
  come from the preceding block (in the original, the `BANK14` tail).

## 11. ca65 emission rules

### 11.1 Labels

- PDS labels are case-insensitive; ca65 labels are case-sensitive. Upper-case
  all labels and all references to them, or preserve the original and resolve
  case-insensitively in the transpiler. The safest is to emit a canonical
  upper-case name.
- Replace characters ca65 does not accept:
  - `.` → `_` (e.g. `y.scroll` → `Y_SCROLL`);
  - `$` → `_` (e.g. `temp$` → `TEMP_`);
  - `!` locals → a generated unique name (see §4.1).
- Detect collisions after sanitisation and append a deterministic suffix.
- Do not rely on ca65's `@` cheap locals for PDS `!` labels; their scope rules
  differ.

### 11.2 Byte operators

```ca65
; PDS: lda #>$065f+((num/2)*dif)
lda #<($065f+((NUM/2)*DIF))     ; PDS '>' = low
; PDS: lda #<$065f+...
lda #>($065f+((NUM/2)*DIF))     ; PDS '<' = high
```

### 11.3 `*`

ca65 `*` is the current PC. PDS `*` includes the `truePC` delta from
`ORG addr,truePC`; if the project uses that feature, emit
`(* - ORG_ADDR + TRUE_PC)` or adjust at transpile time.

### 11.4 Strings

Convert PDS strings to explicit byte lists. This avoids ca65 escape and
encoding differences, and makes `DC`/`CBM` straightforward.

### 11.5 Comments and listing

Preserve comments and original line numbers as ca65 comments. This is
invaluable when comparing a listing to the original source, and costs nothing
in the ROM.

## 12. Source-corpus gotchas

These are real constructs in `pds_src/src` that a transpiler must handle:

| Construct | Where | Handling |
|---|---|---|
| `sub #dif` | `START.ROU`, `HISCORE.ROU` | user macro in `MACROS.PDS:504` |
| `changebank 14` | `START.ROU` | user macro; expand |
| `IFS [@5] []` | `MACROS.PDS` | empty argument test |
| `!1` inside macros | `MACROS.PDS` | rename per expansion |
| labels with `.` and `$` | `VARS.PDS`, `MAINLOOP.ROU` | sanitise |
| `lda #>$065f+...` | `START.ROU` | whole-expression byte op |
| `do 30 / nop / loop` | `START.ROU` | loop unroll |
| `org &c004` | `BANK14.PDS` | bank 15 base |
| `defw &C007` vectors | `ENDCODE.ROU` | ordinary words |
| `HEX` blocks | `MAPDATA.DAT`, `CHRSETS.CHR` | parse pairs |
| `CBM` text | UI routines | screen-code table |
| `OPTION 0,0` | `MACROS.MUS` | ignore (or record) |
| `send computer1` | `MACROS.PDS`, `ENDCODE.ROU` | ignore for ROM |

## 13. Implementation checklist

- [ ] Physical reader: CR/LF, Ctrl-Z, tabs, stray control bytes.
- [ ] Field splitter with the one-character-after-label rule.
- [ ] Macro definitions, positional/named parameters, `@n`/`@@n`, `EXITM`,
      local-label renaming, depth/recursion limits.
- [ ] Conditional engine: `IF`/`ELSE`/`ENDIF`, `IFS` (OR over later groups, case-sensitive),
      `IFF` (forward symbol).
- [ ] Loop unroller: `DO`/`LOOP`, `DO`/`UNTIL` (only 1 exits), `REPEAT`.
- [ ] Symbol table: globals, locals, `EQU`, bare `=` (and later-PDS `DEFL`), case-insensitive.
- [ ] Expression evaluator: precedence, byte ops with whole-expression scope,
      wrapping arithmetic, comparisons, range, radix, strings, `*`.
- [ ] Two-pass sizing: forward ref ⇒ absolute; phase check.
- [ ] Instruction encoder: all 56 mnemonics, all addressing forms, branch
      range, immediate/single-byte checks.
- [ ] Data directives: DB/DC/CBM/DW/DH/DL/DS/HEX/STRING.
- [ ] Blocks: ORG (with truePC), BANK, END, start address, `$37` fill.
- [ ] ca65 emitter: labels, expressions, strings, comments, segments.
- [ ] Linker config for the four banks and the NES header.
- [ ] Golden tests: expression vectors, encoding vectors, macro vectors, and
      the stable prefixes of `ROBINV7.BC/.BD/.BE/.BF`.
- [ ] Differential test: assemble the same source with a reference PDS
      implementation (DOSBox-X/dosemu2 or a patched headless run) and compare
      bytes/listing.

## 14. Open questions

1. `CBM`'s exact screen-code table and whether it differs from the standard
   PETSCII/C64 screen-code mapping. Resolve against the 46 corpus uses.
2. `STRING`'s exact handling of multiple strings and embedded NULs.
3. The 1.26 6502 build's keyword set and limits (only 1.21 was analysed).
4. `IFF`'s exact “defined later” test in pass 2; treat as forward-symbol
   presence unless proven otherwise.
5. The `OPTION` directive's full syntax (the option screen exists; the source
   only uses `OPTION 0,0`/`1,1`).
