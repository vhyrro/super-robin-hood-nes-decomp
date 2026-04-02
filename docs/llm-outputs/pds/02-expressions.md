# PDS 6502 — Expression grammar and evaluator semantics

Reference for the expression evaluator used by the PDS 6502 assembler: tokens,
operator set, precedence, byte extraction, arithmetic domain, range checks,
forward references, and the exact behaviour needed to reimplement it or
transpile PDS source to ca65.

**Sources and tags**

| Tag | Meaning |
|---|---|
| **[M]** | Documented in `docs/PDS_6502_Manual.md` §2 (OCR of *The PDS 6502 Manual*). |
| **[M-img]** | Checked against the scanned manual page image (OCRed text corrected). |
| **[B]** | Confirmed by static disassembly of `version121_pds6502.exe` (`ndisasm`; no Ghidra). File offsets are from the start of the EXE. |
| **[C]** | Confirmed by real usage in `pds_src/src/`. |
| **[ROM]** | Confirmed byte-for-byte in the assembled bank image `pds_src/src/ROBINV7.BF` / shipped ROM. |
| **[D1.26]** | Documented only in `version126_read.8` from `docs/manuals/PDS_executables.zip`. |
| **[I]** | Inferred; not documented and not directly exercised. Verify before relying. |

The evaluator in 1.21 is one shared routine used by both the assembler and the
monitor. Its parser starts at file offset `0x1AF54`; the operator dispatch is
at `0x1B061`–`0x1B100`; number/string/label primaries are at
`0x1B15A`–`0x1B2A9`; the range-check parser is at `0xAF80`/`0x1B11B`; the
expression epilogue (forward-reference/range handling) is at `0xB017`.

---

## 0. Reimplementation summary

* Values are **unsigned 16-bit** in the evaluator. Arithmetic is **mod 65536**
  (`& $FFFF`), *not* mod 65535 as the manual claims. See §4.2.
* `>` at the start of an expression means **low byte**, `<` means **high
  byte** — the reverse of ca65. This is configurable ("swap").
* A leading byte operator applies to the **entire remaining expression**, not
  just the next primary. Mid-expression byte extraction requires brackets.
* Unary minus applies **only to the immediately following number, label, `*`,
  or parenthesised expression** — effectively at primary level. `-20/4` is
  `(-20)/4 = 16379`, not `-(20/4)`.
* Actual 1.21 precedence, high to low:
  `()` → unary `-` → `* /` → `+ -` → `= <> > <` → `&` → `! ~`.
  The manual groups `& ! ~` together; the binary gives `&` a higher priority
  than `!`/`~`.
* Comparisons are **unsigned** and return exactly **1 or 0**.
* Logic is bitwise, 16-bit, no short-circuit.
* `*` is the current logical PC (actual PC plus the `ORG new,true` offset).
* `expr [lo,hi]` only checks the value; it does not clamp it.
* In pass 1 an expression containing an unresolved label evaluates to **0**
  for the whole expression and sets a "forward reference" flag; range checks
  are skipped. Most directives that must know a value reject that flag.

---

## 1. Lexical elements

### 1.1 Numbers and radix

| Form | Example | Value |
|---|---|---|
| Decimal | `1234` | 1234 |
| Hex | `$1234`, `&1234`, `&ABCD` | 0x1234 |
| Binary | `%1010`, `%1001110` | 10, 78 |
| ASCII | `"a"`, `"ab"` | 0x0061, 0x6261 |

* Decimal literals are accepted from `0` to `65535`; a leading `-` is a
  separate unary operator. The parser rejects a literal that overflows 16 bits
  with **"Number too big"**. **[M] [B]**
* The manual says the allowed range is `-32768` to `65535`, but because `-` is
  applied after parsing, `-65535` is also accepted and equals `1`. **[M] [B]**
* `RADIX expression` changes the default base (2–16) used for unprefixed
  numbers. The `RADIX` argument itself is always decimal. `$`/`&` and `%`
  prefixes are unaffected. **[M]** The 1.21 parser reads the radix from
  `[0x67DE]` (`0xB201`, `0xB248`). **[B]**
* **There is no modulo operator.** `%` is only a binary-literal prefix. The
  OCR strings `LDA (FRED+2) %3`, `LDA 3%(FRED+2)` in the markdown manual are
  actually `*3`, `3*(FRED+2)` on the scanned page. **[M-img]**

### 1.2 ASCII literals

* An ASCII literal in an expression may contain **one or two characters**
  only. Longer text is a `DB`/`DW` string parameter, not a numeric expression.
  Error: `Missing ", only one or two characters are allowed in quotes`. **[B]**
* Packing is little-endian: first character is the **low** byte, second is the
  **high** byte. `"a"` = `$0061`, `"ab"` = `$6261`. **[M] [B]**
* Case is preserved in the literal itself: the manual explicitly says `"a"`
  returns `$61`. **Do not** uppercase quoted bytes even though identifiers are
  upper-cased. **[M]**
* `"ab"+1` is a normal arithmetic expression, value `$6262`. **[B]**
* `CBM` explicitly does **not** allow text in expressions (`"C"+128` is
  rejected), unlike `DB`. **[M]**
* Empty `""` is not documented and was not exercised; the 1.21 parser's
  one/two-character logic makes it an edge case. Treat as an error. **[I]**

### 1.3 Labels, local labels, and `*`

* Identifiers are case-insensitive; allowed characters are
  `A–Z a–z 0–9 . _ $`, first character not a digit. **[M]**
* `!name` is a local label. Local-label scope is cleared by the next normal
  label, by `LOOP`, and at macro boundaries. **[M]**
* `*` in **primary** position is the current PC. `*` in **operator** position
  is multiplication. A line whose first character is `*` is a comment. **[M]**
* `*` returns the *logical* PC: the 1.21 code computes `[0x6796] + [0x6798]`.
  `[0x6796]` is the real assembly PC; `[0x6798]` is the true-PC offset set by
  the second parameter of `ORG new,true` (`0x11647`–`0x1165D`). Thus `*` is
  the PC the program will run at, not necessarily the address where bytes are
  inserted. **[B]**

### 1.4 Token ambiguities

| Character(s) | Meaning depends on position |
|---|---|
| `>` `<` | At start of expression/subexpression: byte extraction. After a left operand: comparison. |
| `*` | Primary: PC. Between operands: multiply. |
| `-` | Primary position: unary negate. Between operands: subtract. |
| `!` | Operator position: bitwise OR. At start of a label: local-label marker. |
| `&` | Primary position: hex prefix (`&1234`). Operator position: bitwise AND. |
| `%` | Primary position: binary-literal prefix. Never modulo. |
| `#` | Immediate prefix, normally consumed by the operand parser. If it reaches the evaluator, 1.21 maps it to the `<>` handler (`0xB08E`); undocumented, do not use. **[B]** |
| `<>` | Single token only when the two characters are adjacent. `< >` is not `<>`. **[B]** |

Whitespace and tabs are ignored between tokens, including before a range
check. **[M]**

---

## 2. Operators, precedence, associativity

### 2.1 Manual specification

The manual's table (`docs/PDS_6502_Manual.md:71-92`) is:

| Operator | Meaning |
|---|---|
| `-` (unary) | Negate a number or label, **not an expression**; use `-1*(expr)` for an expression. |
| `+ - * /` | Add, subtract, multiply, divide. No overflow checks; result "MOD 65535"; division rounds down. |
| `&` | Logical AND (bitwise). |
| `!` | Logical OR (bitwise). |
| `~` | Logical XOR (bitwise). |
| `=` | 1 if equal, else 0. |
| `<>` | 1 if not equal. |
| `>` | 1 if left > right. |
| `<` | 1 if left < right. |

Documented priority, highest first:

1. `(` `)`
2. `<` `>` — byte extraction
3. `*` `/`
4. `+` `-`
5. `=` `<>` `>` `<` — comparisons
6. `&` `!` `~`

The manual says expressions are evaluated "from left to right, except for
operators with higher priorities", i.e. left-associative within one priority.
**[M]**

### 2.2 Actual 1.21 priority table

The parser stores a priority byte `BH` with each operator and reduces when the
next operator's priority is `<=` the pending one (`0xB00C`: `cmp bh,ch; jna`),
which is exactly left-associative precedence climbing. The bytes are:

| Priority (BH) | Operators | Code |
|---|---|---|
| 1 (lowest) | `!` OR, `~` XOR | `0xB045` |
| 2 | `&` AND | `0xB049` |
| 3 | `=`, `<>`, `>`, `<` comparisons | `0xB04D`, `0xB057` |
| 4 | `+`, `-` | `0xB041` |
| 5 (highest binary) | `*`, `/` | `0xB03D` |
| — | unary `-` | inside primary, `0xB18C`/`0xB2A9` |
| — | byte extraction `<`/`>` at expression start | outside the loop, `0xAF54`–`0xAF6D` |

**Important correction:** `&` is *not* the same priority as `!`/`~` in the
implementation. It binds tighter than OR/XOR but looser than comparisons. The
manual's grouping of `& ! ~` into one tier is wrong for 1.21. Example:
`4!1&2` evaluates as `4!(1&2)` = `4`, not `(4!1)&2` = `0`. **[B]**

### 2.3 Associativity

All binary operators are left-associative at equal priority. Examples:

* `10-3-2` = `(10-3)-2` = 5.
* `100/7*7` = `(100/7)*7` = `14*7` = 98.
* `2&1!4` = `(2&1)!4` = `4` (with `&` higher, also `4`).
* `1!2~3` = `(1!2)~3` = `0`.
* `a+b-c` = `(a+b)-c`.

The corpus relies on this in `MACROS.MUS:298`,
`CLN = CLN-(CLN-2)/7*7`, and `MACROS.MUS:339`,
`IF CLN-CLN/5*5=1` (a modulo-5 test). **[C]**

### 2.4 `OPTION 1,1` — alternative logic precedence

`version126_read.8` (1.26 update notes):

> 6. OPTION 1,1 will change the expression evaluator to give logics the
>    highest precedence, ie: &!~ will be evaluated befor other opperators.
>    OPTION 1,0 (defualt) is the old method.

So:

| Form | Effect |
|---|---|
| `OPTION 1,0` | Default: logic is lowest (manual/1.21 behaviour). |
| `OPTION 1,1` | `&`, `!`, `~` are evaluated **before** arithmetic and comparisons. |
| `OPTION 0,0` | Appears in the corpus (`MACROS.MUS:25`, `JONSBIT.MUS:49`). Meaning undocumented; treat as a default/no-op. **[C] [I]** |

`OPTION` is not in the 1.21 keyword table (`docs/re/ledger/KEYWORDS.md`), so it
is 1.22+; the shipped corpus was assembled with a later version. The 1.26
6502 binary is not in the archive, so the exact priority numbers under
`OPTION 1,1` are **[D1.26] + [I]**.

Recommended model: under `OPTION 1,1` all three logic operators move as a
group above `* /` and `+ -` (brackets still group; unary minus still binds to a
primary; a leading byte operator still masks the final whole-expression
value). Whether `&` keeps its edge over `!`/`~` under `OPTION 1,1` is not
documented — do not rely on it; parenthesise.

`OPTION 1,1` is stateful for the rest of the assembly. Put it at the top of the
file. **[I]**

---

## 3. Unary byte extraction (`>` low, `<` high)

### 3.1 Default direction and reversal

* Default: **`>` = LOW byte, `<` = HIGH byte** ("the arrow points at the byte
  returned"). `>$1234` = `$34`; `<$1234` = `$12`. **[M]**
* This is the **opposite** of most 6502 assemblers including ca65. The PDS
  distribution's own `c64warn.txt` says:
  > The PDS assembler for 6502 code uses the ">WORD" and "<WORD" expressions
  > the other way around than most other 6502 assemblers, ie. LSB and MSB are
  > exchanged.
  **[M]**
* The editor configuration menu has an entry **"1. Swap < and > in
  expressions."** (string in `version121_pds6502.exe`). Reversing it makes
  `>$1234` return `$12`. The parser reads the two byte-op characters from
  `[0xB76]` and `[0xB78]` (`0xAF63`, `0xAF69`), so the swap is done at the
  character level. **[M] [B]**
* The swap affects byte extraction, and therefore also `DH`/`DL` (which
  prepend `<`/`>` internally). It does **not** change comparison `>`/`<`.
  **[I]**

### 3.2 A leading byte operator wraps the ENTIRE remaining expression

This is the single most error-prone rule. The manual says the operators "can
only be used at the start of expressions, eg: `>23*52+FRED`", and the 1.21
parser confirms it: on seeing the configured low/high character at
`0xAF54`–`0xAF67`, it calls `0xAF6F`, which parses the *whole* expression
recursively and only then masks the result (`0xAF3C` low, `0xAF43` high).
**[M] [B]**

**Proof from the shipped code.** `START.ROU:13-21`:

```asm
num  equ 10
dif  equ $80

lda #num
sta $72
lda #>$065f+((num/2)*dif)
sta $70
lda #<$065f+((num/2)*dif)
sta $71
```

`$065F + (10/2)*$80 = $065F + $0280 = $08DF`.

| Interpretation | `>` line result | `<` line result |
|---|---|---|
| Byte op wraps whole expression | low($08DF) = **$DF** | high($08DF) = **$08** |
| Byte op binds only to `$065F` | low($065F)+$0280 = $02DF → byte **$DF** | high($065F)+$0280 = $0286 → byte **$86** |

`ROBINV7.BF` offset `0x289` (= address `$C289`) contains:

```
A9 0A 85 72 A9 DF 85 70 A9 08 85 71
lda #$0A / sta $72 / lda #$DF / sta $70 / lda #$08 / sta $71
```

The `$08` proves the whole-expression binding. The low-byte line happens to
give `$DF` under both interpretations because `$02DF & $FF == $08DF & $FF`.
**[ROM]**

Note that low-byte extraction is a ring homomorphism (`low(a+b) =
low(a)+low(b)` mod 256), so many low-byte examples do not distinguish the two
interpretations. Use a high-byte case, or a division, to test:
`>256/2` is `low(128) = 128` under whole-expression binding, but
`low(256)/2 = 0` if the byte op bound only to `256`. **[B]**

### 3.3 Mid-expression use requires brackets

* After a binary operator the parser enters at `0xAF4C`, which skips spaces and
  jumps to `0xAF72` **without** the byte-op check. A `<`/`>` there is therefore
  a comparison token, or a syntax error if no left operand exists. It is never
  a byte operator. **[M] [B]**
* To extract a byte of a subexpression, bracket it: `23+52*(<FRED)`. The `(`
  starts a fresh expression at `0xAF5E`, which does run the byte-op check.
  **[M] [B]**
* Consequence: `23+<FRED` is invalid; `23+(<FRED)` and `23+52*(<FRED)` are
  valid. The corpus follows this: `NEWBITS.ROU:548`
  `lda #<(&fe*16+&1008)`, `CMLOGO.ROU:2373` `lda #<(&90*16)`,
  `MACROS.MUS:343` `LDX #<(CLN/5)+1`. **[C]**
* Nested unparenthesised byte ops (`><$1234`) are not allowed; after the outer
  byte op the parser bypasses the check for the inner one. Use `>(<$1234)`.
  **[B]**

### 3.4 How to parenthesise when transpiling

For a PDS expression `>E` (low of the whole `E`), emit ca65:

```asm
<(E_as_ca65)        ; ca65 '<' = low
```

For PDS `<E` (high of the whole `E`):

```asm
>(E_as_ca65)        ; ca65 '>' = high
```

Do **not** emit `<$065f+...` or `>$065f+...`: ca65's unary byte operators bind
to the next primary, so the arithmetic would move outside the extraction.
Always wrap the entire translated subexpression.

---

## 4. Unary minus and the arithmetic domain

### 4.1 Unary minus

`-` in primary position sets a sign flag and parses exactly one primary
(number, label, `*`, or parenthesised expression), then applies 16-bit `neg`
(`0xB18C`, `0xB2A9`). It is **not** a general expression prefix. **[M] [B]**

* `-20` = `65516` (`$FFEC`). Therefore `-20/4` = `65516/4` = **16379**
  (`$3FFB`), not `-5`. **[M] [B]**
* `-(20)` works because `(` is a primary, but `-(20/4)` is a syntax error;
  use `-1*(20/4)` to negate a whole expression. **[M]**
* `-FRED*2` = `(-FRED)*2`; `-FRED/2` = `(-FRED)/2`, not `-(FRED/2)`.
* Unary minus of 0 is 0; `-1` = `$FFFF`; `-32768` = `$8000`; `-65535` = 1.
  **[B]**

### 4.2 MOD 65535 vs MOD 65536 — the manual is wrong

The manual says, twice: "There are no error checks on these operations, so you
may have expressions such as 60000*5 or 60000+60000 which will return the
result MOD 65535." **[M]**

The 1.21 implementation does **not** reduce mod 65535. It uses ordinary 16-bit
x86 operations:

| Operator | Code | Effect |
|---|---|---|
| `+` | `add ax,dx` at `0xB0BE` | 16-bit wrap, mod 65536 |
| `-` | `sub dx,ax` at `0xB0A1` | 16-bit wrap, mod 65536 |
| `*` | `mul cx` at `0xB0CE`; high word in `DX` is discarded when the pending operand is popped | low 16 bits, mod 65536 |
| `/` | `div cx` at `0xB0B9` with `DX=0` | unsigned 16-bit quotient, remainder discarded |

There is no modulo-65535 reduction anywhere in the evaluator. **[B]**

So the correct reimplementation rule is:

```text
result = value & 0xFFFF
```

not `value % 65535`.

This differs from the manual only when the true result is a multiple of 65535
(or just above one):

| Expression | Manual (mod 65535) | Actual 1.21 (mod 65536) |
|---|---|---|
| `$FFFF+2` | 2 | **1** |
| `60000+60000` | 54465 (`$D4C1`) | **54464 (`$D4C0`)** |
| `60000*5` | 37860 (`$93E4`) | **37856 (`$93E0`)** |
| `$FFFF+$FFFF` | 0 | **65534 (`$FFFE`)** |

Use the **actual** column for binary parity. The 1.26 6502 binary is not in the
archive; if exact parity with 1.26 is required, test one of these vectors
there. **[I]**

A second argument that the modulus must be 65536: unary minus produces
`$FFFF` for `-1`. Under a literal mod-65535 reduction `$FFFF` would become 0,
which would make `-1` useless. The evaluator stores the value as a 16-bit word
and only binary arithmetic wraps.

### 4.3 Division and rounding

* Both operands are treated as **unsigned 16-bit**. `div` is unsigned.
* Division rounds **down** (floor of the unsigned value): `7/3 = 2`,
  `100/7 = 14`. **[M] [B]**
* Because negative literals are two's complement, division of a "negative"
  value divides the large unsigned value:
  * `-20/4` = `65516/4` = 16379.
  * `-1/2` = `65535/2` = 32767.
  * `-5/2` = `65531/2` = 32765.
* Division by zero raises **"Division by 0"** (`0xB103`); it is not defined as
  0. **[B]**
* There is no modulo operator. To compute `a mod b`, write `a-(a/b)*b`, as the
  corpus does: `CLN-CLN/5*5=1` (`MACROS.MUS:339`). **[C]**

### 4.4 Overflow and underflow

All arithmetic is 16-bit two's complement/wrap:

| Expression | Value |
|---|---|
| `$FFFF+2` | `$0001` |
| `0-1` | `$FFFF` |
| `$8000*2` | `$0000` |
| `$FFFF*$FFFF` | `$0001` (because (-1)×(-1)=1) |
| `$8000/$FFFF` | 0 |
| `$FFFF/$2` | `$7FFF` |

No overflow error is raised for `+ - *`; only "Number too big" for a literal
that does not fit 16 bits, and "Division by 0". **[M] [B]**

---

## 5. Comparisons and logic

### 5.1 Comparisons

* `=`, `<>`, `>`, `<` are **unsigned** 16-bit comparisons and return exactly
  **1** (true) or **0** (false). Not `$FFFF`. **[M] [B]**
* The 1.21 code uses `ja`/`jbe`-style unsigned branches (`0xB098`, `0xB0FA`),
  so `-1 > 0` is **true** (`$FFFF > 0`) and `-1 < 0` is **false**. Treat
  negative-looking literals as large unsigned values. **[B] [I for spec]**
* `=` and `<>` compare the full 16-bit values.
* There is no `<=` or `>=`; write `a<b ! a=b` (but remember `!` is OR) or
  `a>b = 0`. **[M]**
* Comparisons are lower priority than `+ - * /`, so `1+2=3` means
  `(1+2)=3` = 1. **[M] [B]**

### 5.2 Logic

* `&` = bitwise AND, `!` = bitwise OR, `~` = bitwise XOR, all on 16-bit
  values. **[M] [B]**
* No short-circuit evaluation; both operands are always evaluated. This
  matters for division by zero and for forward references. **[B]**
* Actual 1.21 priority: `&` (2) binds tighter than `!`/`~` (1). The manual's
  single tier is wrong. `4!1&2` = `4!(1&2)` = 4. **[B]**
* `!` has no unary logical-NOT meaning, and `~` has no unary bitwise-NOT
  meaning in PDS. `!FRED` would be parsed as a local label, not logical not.
  **[B]**
* `&` is also the hex prefix; `&$` is not valid. `$` is unambiguous.
* Logic is evaluated after comparisons in the default mode, so
  `FRED>0 & BILL<5` means `(FRED>0) & (BILL<5)`. **[M] [B]**

### 5.3 `OPTION 1,1`

Under `OPTION 1,1`, `& ! ~` are evaluated before arithmetic/comparisons. For
example:

| Expression | Default 1,0 | `OPTION 1,1` |
|---|---|---|
| `4+1&2` | `(4+1)&2` = 0 | `4+(1&2)` = 4 |
| `1+2*3&1` | `(1+6)&1` = 1 | `1+2*(3&1)` = 3 |

`OPTION 0,0` in the corpus has no documented effect; the 1.26 readme only
documents option number 1. **[D1.26] [C] [I]**

---

## 6. Range assertions `expr [lo,hi]`

### 6.1 Syntax and semantics

After an expression, optionally separated by spaces/tabs, write:

```text
expression [low,high]
```

* Both bounds are full expressions (byte operators, labels, arithmetic).
  `[100,120]`, `[BILL*2,BILL*2+20]`. **[M] [B]**
* The range is **only a check**. The expression's value and emitted bytes are
  unchanged; the range is discarded. **[M]**
* Comparison is unsigned: error if `value < low` or `value > high`
  (`0xB021`: `cmp ax,[lo]; jc error`, `cmp ax,[hi]; ja error`). **[B]**
* If `low > high`, the range itself is invalid: **"Error in range"**. **[B]**
* Only one range check per expression. A second one produces **"Multiple range
  check"** (`0xB11B` checks the flag before parsing). **[B]**
* A range check on an expression that contains a forward reference is skipped,
  because the expression epilogue returns 0 before reaching the range check.
  **[B]**

### 6.2 Where it is legal

It is part of the expression grammar used by the assembler, so it is legal
wherever the assembler evaluates an operand expression:

* instruction operands: `LDA FRED+23*2 [58,70]` **[M]**
* data directives, per parameter: `DB ...`, `DW ...` etc. **[I, by shared
  evaluator]**
* `EQU`/`=`/`DEFL` right-hand side: `CLN = @1 [2,350]`
  (`MACROS.MUS:293`) **[C]**
* conditional expressions (`IF`/`IFF`) **[I, by shared evaluator]**
* `ORG`, `DS`, `BANK`, `REPEAT`, `DO`, `SKIP` operands **[I]**

It is **not** legal inside `IFS` brackets: those are raw strings, not
expressions. It is also not available in the monitor, where `[...]` means
"word at address". **[M] [B]**

### 6.3 Operand-level range vs directive-level range

`DB` separately requires each numeric parameter to be in `-128..255`; `DW`
requires `-32768..65535`; immediate operands have their own 8-bit/16-bit
checks. These are **not** the `[lo,hi]` mechanism and their error messages
differ. **[M]**

---

## 7. ASCII literals, `IFS`, and `@@n` macro parameters

### 7.1 ASCII in expressions

Covered in §1.2: one or two characters, little-endian, case preserved,
`"ab"` = `$6261`. In `DB`, a quoted string parameter is emitted as a sequence
of bytes; in an arithmetic expression only the 1–2 character numeric form is
valid. **[M] [B]**

### 7.2 `IFS` — string comparison (not an expression)

Syntax:

```text
IFS [string1] [string2] [string3] ...
```

* The following block is assembled if `string1` equals **any** of the other
  bracketed strings. **[M]**
* Strings are compared as raw text after macro substitution; they are **not**
  evaluated as expressions. All parameters are upper-cased by the assembler.
  **[M]**
* `IFS [@1] []` is the standard "was parameter 1 supplied?" test. The corpus
  uses `IFS [@5][]` in `MACROS.PDS` (`defspr` and several macros). **[M] [C]**
* Brackets may contain commas: `FRED 23,[45,56,67],98` passes `45,56,67` as
  one parameter. **[M]**
* `IFS` pairs with `ELSE`/`ENDIF`; `EXITM` can leave a macro from inside it.
  **[M]**

### 7.3 `@@n` — evaluated macro parameters

* `@1`…`@9` are **text substitution**: the parameter text is inserted
  verbatim. It may be a label, an expression, or a bracketed comma list.
  **[M]**
* `@@1`…`@@9` evaluate the parameter as an expression **before** insertion and
  substitute the resulting value in decimal. Example: `VAR@@1 EQU *` invoked
  as `FRED 3*2` creates `VAR6`. **[M]**
* `TICKS@@1` (`MACROS.MUS:326`) uses this to build a label name from a computed
  number. **[C]**
* Because `@@n` is evaluated at expansion time, forward references in the
  parameter behave like any other expression: pass 1 gives 0 / sets the
  forward flag, and directives that require constants will reject it. **[I]**

---

## 8. Forward references and pass behaviour

### 8.1 What pass 1 does

The evaluator keeps a "forward reference" bit (bit 3 of `[0x67D0]`). When a
label lookup fails in pass 1, it sets that bit (`0xB1D0`) and the label
contributes **0** to the arithmetic. At the end of the expression, the
epilogue (`0xB017`) checks the bit and, if set, returns **0 for the whole
expression**, regardless of what the partial arithmetic produced:

```asm
0xB017: test byte [0x67D0],0x08
        jz   normal
        xor  ax,ax
        ret
```

Consequences:

* `FRED+1` with `FRED` forward is **0**, not 1.
* `100/FRED` with `FRED` forward does **not** raise "Division by 0": the
  divide path at `87F8` tests the forward bit and jumps over the division,
  leaving the right operand in AX; the epilogue then forces the whole
  expression to 0. **[B]**
* Range checks are skipped when the forward bit is set. **[B]**
* In pass 2 an unresolved label is an error: **"Cannot find label"**
  (`0xB172` path; `[0x67D0]` bit 5 is set in the pass-2/known-value mode).
  **[B]**

### 8.2 Contexts that permit forward references

| Context | Forward reference | Evidence |
|---|---|---|
| Instruction/data operand (`LDA FRED`, `DW FRED`) | **Allowed**; pass 1 value 0, resolved pass 2. Operand width must be stable (PDS assumes word size for an unresolved symbol; a later zero-page resolution would be a phase error). | **[M] [B] [I for width]** |
| `EQU` / `=` / `DEFL` RHS | **Rejected**: "This expression must not contain forward references". | **[M] [B]** |
| `ORG` new PC and true-PC parameter | **Rejected**. | **[M] [B]** (`0x11661`) |
| `DS`/`DEFS` length and filler | **Rejected**. | **[B]** (`0x11C45`, `0x11C5F`) |
| `IF` / `ELSE` condition | **Rejected** by the conditional handler, which tests the forward bit and jumps to the error. Use `IFF` instead. | **[M] [B]** (`0x11CA4`) |
| `IFF` condition | **Required**: assembles only if the expression contains a forward reference. | **[M]** |
| `BANK` bank number | Must be a constant known at assembly time. | **[M] [I]** |
| `BANK n,start` start address | Might be allowed forward because it is only used at download time; not exercised. Keep it constant. | **[I]** |
| `REPEAT`, `DO` count, `SKIP` | Must be known on pass 1 (they control how much code is read/emitted). | **[M] [I]** |
| `UNTIL` condition | May use labels, but each iteration must evaluate; unresolved gives 0. | **[I]** |

### 8.3 `IFF` interaction

`IFF expr` does not test the numeric value; it tests whether the expression
contains a forward reference:

* forward reference present → assemble the `IFF` branch;
* no forward reference → skip to `ELSE` (if any) or `ENDIF`.

This is why the manual's `JCC` macro wraps a possibly-forward branch target in
`IF ... IFF @2 ...`. **[M]**

**Documented contradiction:** the manual's `JCC` macro uses an ordinary `IF`
around an expression containing the possibly-forward `@2`, then uses `IFF @2`
inside. But the 1.21 conditional handler rejects a forward reference in `IF`
before `IFF` is reached. The manual also states plainly that normal `IF`
cannot have forward references. Treat the `JCC` example as inconsistent with
1.21; a faithful transpiler should reject forward refs in `IF`, and use `IFF`
only where the source really uses `IFF`. **[M] vs [B]**

### 8.4 `ORG` and `*` with a true PC

`ORG new,true` sets the assembly address to `new` but makes `*` and all PC
references use `true`. The evaluator computes `*` as `PC + offset`, where
`offset = true - new` is stored at `[0x6798]` (`0x11647`–`0x1165D`). **[M]**
**[B]**

---

## 9. Formal grammar

### 9.1 Manual-specification grammar (default precedence)

```text
line_expr   ::= expr range?
range       ::= '[' expr ',' expr ']'

expr        ::= byteop? logic
byteop      ::= '>' | '<'                  # configured direction
logic       ::= compare (('&'|'!'|'~') compare)*
compare     ::= sum (('='|'<>'|'>'|'<') sum)*
sum         ::= product (('+'|'-') product)*
product     ::= unary (('*'|'/') unary)*
unary       ::= '-' primary | primary
primary     ::= number
              | string
              | label
              | '*'
              | '(' expr ')'
```

* `byteop?` is at the **outermost** level, so it applies to the whole
  `logic` result. It is also available at the start of any parenthesised
  subexpression because `(` recurses into `expr`.
* `unary` is not recursive into `expr`: `-(...)` is only valid because `(...)`
  is a `primary`; `-1*(...)` is the documented way to negate an expression.
* `range?` is parsed by the caller after the expression; it is not an operator.

### 9.2 Actual 1.21 grammar (`&` tighter than `!`/`~`)

```text
expr        ::= byteop? or
or          ::= and (('!'|'~') and)*        # priority 1
and         ::= compare ('&' compare)*       # priority 2
compare     ::= sum (('='|'<>'|'>'|'<') sum)*  # priority 3
sum         ::= product (('+'|'-') product)*    # priority 4
product     ::= unary (('*'|'/') unary)*        # priority 5
unary       ::= '-' primary | primary
primary     ::= number | string | label | '*' | '(' expr ')'
```

### 9.3 `OPTION 1,1` grammar (1.26, inferred shape)

```text
expr        ::= byteop? compare
compare     ::= sum (('='|'<>'|'>'|'<') sum)*
sum         ::= product (('+'|'-') product)*
product     ::= logic (('*'|'/') logic)*
logic       ::= unary (('&'|'!'|'~') unary)*
unary       ::= '-' primary | primary
primary     ::= number | string | label | '*' | '(' expr ')'
```

This keeps brackets and unary minus above logic, and puts logic above `* /`.
The exact relative order of `&` vs `!`/`~` under `OPTION 1,1` is not
documented; the grammar above treats them as one tier. **[D1.26] [I]**

---

## 10. Reference evaluator pseudocode

```python
MASK = 0xFFFF

def u16(x):
    return x & MASK

def evaluate(tokens, pc, option11=False):
    # The caller has already tokenised. 'pc' is the logical PC for '*'.
    pos = 0

    def peek():  return tokens[pos] if pos < len(tokens) else EOF
    def take():  nonlocal pos; t = tokens[pos]; pos += 1; return t

    # ---- top level -------------------------------------------------
    def expr():
        lowhigh = None
        if peek() in ('<', '>'):
            lowhigh = take()          # only at start of expr(), incl. after '('
        v = compare() if option11 else or_expr()
        if lowhigh == '>':       # default: '>' = low
            v = v & 0xFF
        elif lowhigh == '<':     # default: '<' = high
            v = (v >> 8) & 0xFF
        return u16(v)

    # ---- default precedence (actual 1.21: & above ! ~) -------------
    def or_expr():                       # priority 1
        v = and_expr()
        while peek() in ('!', '~'):
            op = take(); r = and_expr()
            v = u16(v | r) if op == '!' else u16(v ^ r)
        return v

    def and_expr():                      # priority 2
        v = compare()
        while peek() == '&':
            take(); v = u16(v & compare())
        return v

    def compare():
        v = sum()
        while peek() in ('=', '<>', '>', '<'):
            op = take(); r = sum()
            if   op == '=':  v = 1 if v == r else 0
            elif op == '<>': v = 1 if v != r else 0
            elif op == '>':  v = 1 if v > r else 0   # unsigned
            else:            v = 1 if v < r else 0
        return u16(v)

    def sum():
        v = product()
        while peek() in ('+', '-'):
            op = take(); r = product()
            v = u16(v + r) if op == '+' else u16(v - r)
        return v

    def product():
        v = unary()
        while peek() in ('*', '/'):
            op = take(); r = unary()
            if op == '*':
                v = u16(v * r)          # low 16 bits
            else:
                if forward_ref:         # 87F8: skip division entirely
                    v = r               # epilogue will force the result to 0
                elif r == 0:
                    error("Division by 0")
                else:
                    v = u16(v // r)     # unsigned floor
        return v

    def unary():
        if peek() == '-':
            take()
            return u16(-primary())
        return primary()

    def primary():
        t = take()
        if t == '(':
            v = expr()
            expect(')')
            return v
        if t == '*':
            return u16(pc)
        if is_number(t):
            return parse_number(t)       # 0..65535
        if is_string(t):
            return parse_ascii(t)        # 1-2 chars, first low
        if is_label(t):
            return lookup(t)             # pass 1: 0 + forward flag
        error("Bad number, or extra characters")

    return expr(), pos
```

Notes:

* For the **manual-spec** evaluator, replace `or_expr`/`and_expr` with a single
  loop over `& ! ~` at priority 1. For `OPTION 1,1`, change `product()` to call
  a single logic tier instead of `unary()`, and `expr()` to call `compare()`.
* The actual 1.21 evaluator uses `& 0xFFFF`, not `% 65535`, at every binary
  arithmetic operator. If you deliberately emulate the manual's claim, use
  `v = v % 65535` at `+`, `-`, `*` and `/` — but then `-1` (65535) becomes 0,
  so this is not a faithful model of the shipped binary. See §4.2.
* `lookup` must distinguish pass 1 (return 0 and set the forward flag) from
  pass 2 (raise "Cannot find label").
* `parse_number` must reject >65535. `parse_ascii` rejects >2 characters.
* The byte-op character mapping is configurable; the default is `>`→low,
  `<`→high.

---

## 11. Worked test vectors

Definitions used below: `FRED = $1234`, `BILL = $0040`, PC = `$8000` where
`*` appears. "lo/hi" are `v & $FF` and `(v >> 8) & $FF` of the final 16-bit
value. Values are actual 1.21 semantics (§4.2).

| # | Expression | Value | lo | hi | Notes |
|---|---|---|---|---|---|
| 1 | `>$1234` | `$0034` | `$34` | `$00` | `>` = low |
| 2 | `<$1234` | `$0012` | `$12` | `$00` | `<` = high |
| 3 | `>23*52+FRED` | `$00E0` | `$E0` | `$00` | 23*52+4660 = 5856 = `$16E0`; low is `$E0`. Low-byte extraction happens to agree with the wrong parse. |
| 4 | `23+52*(<FRED)` | `$03BF` | `$BF` | `$03` | 52*`$12`+23 = 959. Manual's bracketed form. |
| 5 | `-20/4` | `$3FFB` | `$FB` | `$3F` | 16379; unary minus binds to 20 only. |
| 6 | `$FFFF+2` | `$0001` | `$01` | `$00` | Actual wrap; manual's mod-65535 would give 2. |
| 7 | `"ab"` | `$6261` | `$61` | `$62` | 'a' low, 'b' high. |
| 8 | `"a"` | `$0061` | `$61` | `$00` | case preserved. |
| 9 | `*` at `$8000` | `$8000` | `$00` | `$80` | current logical PC. |
| 10 | `5=4` | 0 | `$00` | `$00` | equality |
| 11 | `23=23` | 1 | `$01` | `$00` | equality |
| 12 | `5<>4` | 1 | `$01` | `$00` | not equal |
| 13 | `$10>$0F` | 1 | `$01` | `$00` | unsigned greater |
| 14 | `$10<$0F` | 0 | `$00` | `$00` | unsigned less |
| 15 | `-1>0` | 1 | `$01` | `$00` | `$FFFF > 0` unsigned |
| 16 | `-1<0` | 0 | `$00` | `$00` | unsigned comparison, not signed |
| 17 | `$F0&$3C` | `$0030` | `$30` | `$00` | AND |
| 18 | `$F0!$0F` | `$00FF` | `$FF` | `$00` | OR |
| 19 | `$FF~$0F` | `$00F0` | `$F0` | `$00` | XOR |
| 20 | `2+7&3` | 1 | `$01` | `$00` | manual example: (2+7)&3 |
| 21 | `7&3+2` | 5 | `$05` | `$00` | manual example: 7&(3+2) |
| 22 | `4!1&2` | 4 | `$04` | `$00` | `&` binds tighter than `!` in 1.21 |
| 23 | `1!2~3` | 0 | `$00` | `$00` | `!` and `~` same tier, left-to-right |
| 24 | `4+1&2` | 0 | `$00` | `$00` | default: (4+1)&2 |
| 25 | `4+1&2` with `OPTION 1,1` | 4 | `$04` | `$00` | 4+(1&2) |
| 26 | `1+2*3&1` | 1 | `$01` | `$00` | default: (1+6)&1 |
| 27 | `1+2*3&1` with `OPTION 1,1` | 3 | `$03` | `$00` | 1+2*(3&1) |
| 28 | `60000+60000` | `$D4C0` | `$C0` | `$D4` | 54464; manual claims `$D4C1`. |
| 29 | `60000*5` | `$93E0` | `$E0` | `$93` | 37856; manual claims `$93E4`. |
| 30 | `23-52` | `$FFE3` | `$E3` | `$FF` | underflow wraps |
| 31 | `$FFFF+$FFFF` | `$FFFE` | `$FE` | `$FF` | manual mod-65535 would give 0 |
| 32 | `-1` | `$FFFF` | `$FF` | `$FF` | two's complement |
| 33 | `-32768` | `$8000` | `$00` | `$80` | two's complement |
| 34 | `-1*2` | `$FFFE` | `$FE` | `$FF` | `(-1)*2` |
| 35 | `65535/2` | `$7FFF` | `$FF` | `$7F` | 32767 |
| 36 | `-1/2` | `$7FFF` | `$FF` | `$7F` | 65535/2 = 32767 |
| 37 | `100/7` | `$000E` | `$0E` | `$00` | floor |
| 38 | `>256/2` | `$0080` | `$80` | `$00` | whole-expression byte op: low(128) |
| 39 | `>$065f+((10/2)*$80)` | `$00DF` | `$DF` | `$00` | `START.ROU` low line |
| 40 | `<$065f+((10/2)*$80)` | `$0008` | `$08` | `$00` | `START.ROU` high line; ROM proof |
| 41 | `hiscores+10*17-7-1` | `$07E6` | `$E6` | `$07` | `highscores = $0744`, `HISCORE.ROU` |
| 42 | `&7eD-17*10+1` | `$0744` | `$44` | `$07` | `VARS.PDS` `hiscoresinram` |
| 43 | `CLN-CLN/5*5` with `CLN=30` | 0 | `$00` | `$00` | modulo-5 test, `MACROS.MUS:339` |
| 44 | `(CLN-2)/7*7` with `CLN=30` | 28 | `$1C` | `$00` | left-to-right `*`/`/` |
| 45 | `"ab"+1` | `$6262` | `$62` | `$62` | ASCII arithmetic |
| 46 | `"a"+128` | `$00E1` | `$E1` | `$00` | matches manual `"!1"+128` style |
| 47 | `>23*52+FRED` low as `DB` byte | `$E0` | `$E0` | — | emitted byte would be `$E0` |
| 48 | `T EQU b12+b13+b14+b15` | symbolic | — | — | total free bytes; `ENDCODE.ROU:7` |
| 49 | `B12` header `DEFB <B12,>B12` with `B12=2` | bytes `00 02` | `$00` | `$02` | last two bytes of `ROBINV7.BC`; proves byte direction |
| 50 | `TOTAL DEFB <T,>T` | low first, high second | — | — | `ENDCODE.ROU:11` |

Range-check examples:

| Expression | Value | Range | Result |
|---|---|---|---|
| `FRED*2+3~BILL [100,120]` with `FRED=$20`, `BILL=$40` | `(64+3)~64 = 3` | 100..120 | **error** (`Expression out of range`) |
| `LDA FRED+23*2 [58,70]` with `FRED=0` | 46 | 58..70 | **error** (below) |
| `LDA FRED+23*2 [58,70]` with `FRED=12` | 58 | 58..70 | OK, assembles `LDA 58` |
| `CLN = @1 [2,350]` with `@1=1` | 1 | 2..350 | **error** |
| `CLN = @1 [2,350]` with `@1=30` | 30 | 2..350 | OK |

---

## 12. PDS → ca65 transpiler gotchas

### 12.1 Byte extraction: reversed and binds differently

| PDS | ca65 | Fix |
|---|---|---|
| `>X` (low) | `<X` | swap the character |
| `<X` (high) | `>X` | swap the character |
| `>$065f+E` (low of whole) | `<( $065f+E )` | wrap the **entire** translated expression |
| `<E` (high of whole) | `>( E )` | wrap the entire translated expression |
| `23+52*(<FRED)` | `23+52*(>FRED)` | bracket already present; just swap |
| `(<FRED)` | `(>FRED)` | fine |
| `><X` | `>(<X)` | PDS itself rejects this; use brackets |

In ca65, unary `<`/`>` have precedence 1 and bind to the next primary, so
`>$065f+E` means `(> $065f) + E`, not `>($065f+E)`. This is the exact bug that
would otherwise turn `$08` into `$86` in `START.ROU`.

### 12.2 Precedence and operator spelling

| PDS | Meaning | ca65 equivalent | Problem |
|---|---|---|---|
| `&` | bitwise AND, priority **low** (above only `!~`) | `&` / `.BITAND`, priority **2** (same as `*`) | must parenthesise |
| `!` | bitwise OR, priority 1 | `\|` / `.BITOR`, priority 3 | `!` in ca65 is boolean NOT (priority 7) |
| `~` | bitwise XOR, priority 1 | `^` / `.BITXOR`, priority 2 | `~` in ca65 is unary bitwise NOT |
| `=` | equality | `=` | same |
| `<>` | not equal | `<>` | same |
| `>` `<` (infix) | comparisons | `>` `<` | same spelling, different from PDS unary use |
| no `<=`/`>=` | — | `<=`/`>=` exist | don't introduce them |
| no `&&`/`\|\|` | — | `.AND`/`.OR` are boolean shortcut | PDS logic is bitwise, not boolean |

The safest rule: **fully parenthesise every PDS expression that contains more
than one operator**, then translate the operators. Do not rely on ca65's
precedence matching PDS's.

### 12.3 Arithmetic width, division, modulo

* PDS is unsigned 16-bit with wrap at 65536. ca65 evaluates with at least
  32-bit precision (and signed values). `$FFFF+2` is `$10001` in ca65, not 1.
* Insert `& $FFFF` after **each** arithmetic operation, not just at the end:
  comparisons and division depend on the wrapped value. E.g. PDS
  `($FFFF+2)<5` is `1<5` = true; ca65 `($FFFF+2)<5` is `65537<5` = false.
* ca65 `&` is bitwise AND with high precedence; write `((expr) & $FFFF)`.
* PDS `/` is unsigned floor. ca65 `/` is 32-bit; for negative-looking values
  the signedness differs. **Constant-fold all arithmetic in the transpiler**
  using the PDS rules from §10, and emit the resulting literal, whenever the
  operands are assembly-time constants (which is almost all of this corpus).
* PDS has no `.MOD`; `%` is a binary prefix. Do not translate `%` to `.MOD`.
  If the source computes `a-(a/b)*b`, keep that form and mask.
* ca65 `<`/`>` used for byte extraction return 8-bit values; PDS returns a
  16-bit value with the other byte zero. When the result is used in further
  arithmetic (not just as a byte operand), wrap/mask appropriately.

### 12.4 Number syntax

| PDS | ca65 | Fix |
|---|---|---|
| `$1234` | `$1234` | same |
| `&1234` | `$1234` | **`&` is bitwise AND in ca65, not a hex prefix** |
| `%1010` | `%1010` | same |
| `1234` | `1234` | same, but PDS `RADIX` may change the base |
| `"ab"` | string, not a number | constant-fold to `$6261` |
| `"a"` | string/char | constant-fold to `$0061` or `'a'` |
| `*` | `*` | ca65 PC is the start of the current line; same idea |

`RADIX n` has no direct ca65 equivalent. The transpiler must convert every
unprefixed literal in the affected region to an explicit `$`/`%`/decimal form.

### 12.5 Labels, local labels, and macro parameters

* PDS local labels `!1`, `!2` are scoped to the next normal label/macro
  boundary. ca65 uses `@1` cheap locals or anonymous `:` labels. Rename all of
  them uniquely; do not emit `!1` (ca65 would read `!` as boolean NOT).
* PDS `@1`…`@9` macro parameters are text substitution. ca65 macro parameters
  are `.param`/`.define`; map them explicitly.
* PDS `@@1` is an **evaluated** parameter (decimal). In ca65 `@` begins a
  cheap local label, so `@@1` is especially dangerous. Compute the value in
  the transpiler and emit a literal, or use `.sprintf`/`.ident` in ca65.
* PDS `IFS [@n][]` is a string-presence test. ca65 has `.IFBLANK`/`.IFNBLANK`
  and `.PARAMCOUNT`; use those, not a numeric comparison.
* PDS `IF`/`IFF` forward-reference rules do not map 1:1 to ca65's `.IF`
  (ca65 is one-pass and can defer some expressions). Keep the PDS pass
  semantics in the transpiler; do not rely on ca65 to reproduce them.

### 12.6 Range assertions

`expr [lo,hi]` has no ca65 inline equivalent. Since it only validates and does
not change the value, the simplest faithful translation is to **drop it**
(binary parity is unaffected). If you want to keep the check, emit:

```asm
.assert (value) >= (low), error, "expression out of range"
.assert (value) <= (high), error, "expression out of range"
```

but make sure `value`, `low`, `high` are translated with PDS semantics first
(16-bit mask, unsigned comparison). Do not use ca65's signed 32-bit comparison
directly.

### 12.7 `OPTION 1,1`

ca65 has no equivalent. If a PDS file contains `OPTION 1,1`, the transpiler
must either:

1. re-parenthesise every expression according to the alternative precedence
   (§9.3), or
2. reject the file with a clear error.

`OPTION 1,0` and `OPTION 0,0` can be ignored (they restore/default the old
behaviour). **[D1.26] [C] [I]**

### 12.8 Parentheses at the start of an operand

PDS and ca65 share the same trap: an operand that starts with `(` is parsed as
indirect addressing, not grouping. The manual's example:

```asm
LDA (FRED+2)*3      ; error: indirect,Y then extra characters
LDA 3*(FRED+2)      ; OK
LDA 0+(FRED+2)*3    ; OK
```

This is an **operand-parser** rule, not an expression-evaluator rule, but it
must be preserved by the transpiler. The scanned manual confirms the operator
is `*`, not `%`; the OCR in the markdown is wrong. **[M-img]**

---

## 13. Open questions / things to verify against a real 1.26 6502 build

1. **MOD 65535 vs 65536.** 1.21 is proven 16-bit wrap. The manual claims
   65535. If the 1.26 6502 build exists, test `$FFFF+2`; the whole document
   assumes 1.21 behaviour (`1`). **[B] vs [M]**
2. **`OPTION 1,1` exact priority numbers.** The readme only says logic goes
   first. Whether `&` remains tighter than `!`/`~`, and whether a leading
   byte operator still wraps the whole expression after the reorder, needs a
   1.26 test.
3. **`OPTION 0,0`.** Present in the corpus, undocumented. Likely a no-op or
   an unrelated option group.
4. **Pass-1 operand width.** Confirmed that an unresolved expression returns
   0. Confirmed that `EQU`, `ORG`, `DS`, and `IF` reject the forward flag. Not
   confirmed whether an unresolved instruction operand is forced to absolute
   (3 bytes) or allowed to default to zero page and later phase-error. The
   corpus defines all zero-page variables before use, so it does not exercise
   this.
5. **`BANK` expression restrictions.** Bank number is presumably constant;
   whether the optional start address may be forward is untested.
6. **`IF` + `IFF` contradiction.** The manual's `JCC` macro suggests forward
   refs in `IF` are tolerated, but the 1.21 handler rejects them. Verify on
   the version actually used to build the corpus (1.22+).
7. **Empty ASCII literal `""`.** Undocumented edge case in the
   one/two-character parser.

---

## 14. Corpus cross-reference

| File:line | Expression | Demonstrates |
|---|---|---|
| `START.ROU:13,17,19` | `num equ 10`, `dif equ $80`, `#>$065f+((num/2)*dif)` | leading byte op wraps whole expression; ROM proof |
| `START.ROU:34` | `sub #dif` | `#` immediate prefix, not an expression operator |
| `ENDCODE.ROU:4,7` | `b15 equ &fff9-ED15`, `T EQU b12+b13+b14+b15` | `&` hex prefix, left-to-right `+` |
| `ENDCODE.ROU:10-11` | `DEFB <B15,>B15`, `TOTAL DEFB <T,>T` | `<` high, `>` low |
| `BANK12.PDS:3-6` | `b12 equ &c000-ED12`, `DEFB <B12,>B12` | free-byte arithmetic, header bytes |
| `BANK13.PDS:3-6`, `BANK14.PDS:3-6` | same pattern with `&BFFF`, `&C001` | bank boundary expressions |
| `MACROS.PDS:47` | `(@1&64~64)/32-1`, `(@1&128~128)/64-1` | `&` before `~`, parentheses, division |
| `MACROS.PDS:62,66,70` | `(*-spritetable)/2` etc. | `*` PC, subtraction, division |
| `MACROS.PDS:109` | `org (!1/256)*256+256` | `*`/`/` before `+`, local label |
| `MACROS.PDS:290-318` | `if @1=@3`, `if @2<256`, `bcc !1` | comparisons, branches |
| `MACROS.PDS:330-355` | `CLN = @1`, `CLN+(@2)*113+(@2)*66/100` | assignment, precedence |
| `MACROS.MUS:25` | `OPTION 0,0` | OPTION directive in corpus |
| `MACROS.MUS:40` | `IF *>$7F5` | `*` comparison |
| `MACROS.MUS:293` | `CLN = @1 [2,350]` | range assertion |
| `MACROS.MUS:298` | `CLN = CLN-(CLN-2)/7*7` | left-to-right `*`/`/` |
| `MACROS.MUS:337,339` | `IF (CLN=30)!(CLN>31)`, `IF CLN-CLN/5*5=1` | `!`, modulo-by-subtraction |
| `MACROS.MUS:343-344` | `LDX #<(CLN/5)+1`, `LDY #>(CLN/5)+256` | bracketed byte ops in immediate operands |
| `NEWBITS.ROU:548-577` | `lda #<(&fe*16+&1008)` | explicit brackets for mid-expression byte op |
| `CMLOGO.ROU:2373-2375` | `lda #<(&90*16)` | same |
| `VARS.PDS` | `var attributes,7*8*2`, `changedblocks,3*maxchangedblocks`, `hiscoresinram equ &7eD-17*10+1` | data-size arithmetic, `&` hex |
| `HISCORE.ROU` | `highscores+numberentries*sizeofmessage-sizeofscore-namenumafter` | multiplicative before additive, left-to-right `+ -` |
| `SMILEY.ROU:317` | `IF *-!0 <> 19` | `*`, local label, `<>` |
| `TITLE.ROU:78,90` | `#24*8-ydisplace`, `#16*8-1-8` | immediate arithmetic |
| `GENERAL.ROU:234` | `#128-10*3-4` | `*` before `-` |
| `MACROS.MUS:326` | `JSR TICKS@@1` | evaluated macro parameter |
| `MACROS.PDS:46` | `ifs [@5][]` | string-presence test |
