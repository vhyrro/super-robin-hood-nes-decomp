# PDS 6502 — Macros, local labels, conditionals and loops

Volume 04 of the PDS reverse-engineering set. This is the detailed reference for
the textual macro engine, `!` local-label scoping, `IF`/`IFF`/`IFS`, the
compile-time loop directives (`DO`/`LOOP`, `DO`/`UNTIL`, `REPEAT`) and the
`SKIP` speed hint.

**Scope:** `pds_src/src/MACROS.PDS`, `pds_src/src/MACROS.MUS`, and every
`MACRO`/`ENDM` use in the `.ROU`/`.PDS`/`.MUS` corpus. The shipped 6502 binary
(`version121_pds6502.exe`, assembler banner `6502 : v3.2`) is used only for its
diagnostic strings and for cross-checking limits; no Ghidra work is part of this
volume.

**Evidence tags**

| Tag | Meaning |
|---|---|
| **[M]** | Documented in `docs/PDS_6502_Manual.md` (OCR of *The PDS 6502 Manual*); page images checked where the OCR is ambiguous. |
| **[C]** | Observed in the real corpus (`pds_src/src/…`, file:line). |
| **[B]** | Observed in the 1.21/3.2 PC binary as a keyword or diagnostic string. |
| **[I]** | Inferred from the implementation model, from the way the corpus uses the feature, or from another volume; not directly documented/executed. |
| **[X]** | Conflict: sources disagree; read the note before relying on it. |

Where this volume contradicts `03-directives.md` or `09-transpiler-spec.md`, the
contradiction is called out explicitly; those files were written in parallel.

---

## 0. The five things to get right first

1. **`JENDM` is not a real PDS keyword.** The OCR text `ENDM ot / JENDM`
   (`PDS_Manual_6502.txt:805-806`) is a misread of the manual page, which lists
   `ENDM`, `.ENDM`, `EXITM`. The scanned page and the 1.21 keyword table have no
   `JENDM`. **[M]** **[B]** (Corrects `03-directives.md` §MACRO and
   `09-transpiler-spec.md` §4.1.)
2. **The macro *name* must be in column 1; the body does not.** The body is
   ordinary source: labels in column 1, instructions/directives indented. The
   1.21 error `A macro must start at the very begining of a line.` refers to the
   definition line, not to every body line. **[M]** **[C]**
3. **`DO`/`LOOP`/`UNTIL` cannot nest in 1.21.** The binary has the diagnostics
   `DO, LOOP and UNTIL cannot be nested` and
   `DO, LOOP and UNTIL may not be used in include files`. One loop level only,
   although loops are legal inside macros. A `DO` count of zero or less is an
   error. **[B]** (Corrects `03-directives.md` §DO…LOOP, which says nesting
   "works [I]".)
4. **`UNTIL` is a conflict.** The manual says it exits on a non-zero value
   (`docs/PDS_6502_Manual.md:222`); the 1.21 implementation reportedly exits only
   when the value is exactly **1** (`08-assembler-internals.md` §9.3). Every
   condition in the corpus is a comparison, which returns 0 or 1, so both rules
   agree there. For byte-exact 1.21 compatibility use `== 1`; for the manual's
   rule use `!= 0`. **[X]**
5. **`SKIP n` is a minimum block size, not "skip until address n".** The manual
   is explicit: pass 1 records forward-reference-free blocks of at least `n`
   bytes, pass 2 jumps over them. `09-transpiler-spec.md` §4.7 describes it as
   "skip source until the PC reaches `n`", which is wrong. It emits no bytes and
   is a pure speed hint. **[M]** (Corrects `08-assembler-internals.md` §9.4 and
   `09-transpiler-spec.md` §4.7.)

A sixth conflict, `IFS` with more than two bracket groups, is discussed in §5.3.

---

## 1. Where macros sit in PDS's line grammar

PDS is column-sensitive only for the label field. The canonical layout is:

```
LABEL<TAB>OPCODE<TAB>OPERAND<TAB>; COMMENT
```

* Field 1, the label, must start at column 1. One non-label character after the
  name is consumed (so `LABEL:`, `LABEL#`, even `LABEL;` are accepted; `;` there
  is the terminator, not a comment). **[M]**
* Field 2, the opcode/mnemonic/directive/**macro name**, must be indented by at
  least one space or tab. **[M]**
* Fields 3–4, operand and comment, are free-form. **[M]**

### 1.1 Definition line vs call line

```asm
; definition: name is a column-1 label, MACRO is the opcode
zvar<TAB>macro
@1<TAB>equ zlim
zlim<TAB>= zlim+@2
<TAB>if zlim>&ff
<TAB>ERROR "Out of zero page work space with variable @1
<TAB>endif
<TAB>endm

; call: macro name is in the opcode field
<TAB>zvar cm_frames<TAB>,1
```

* The definition line is `NAME MACRO [params]`. `NAME` is the label field, so it
  must be in column 1. After stripping editor `0x01`/`0x02` block markers, all
  107 corpus definitions follow this. **[C]**
* A call is a normal statement with the macro name in the **opcode** field, so a
  call cannot begin in column 1 unless the line also has a label before it.
  `putinheart<TAB>changebank 13` is a label plus a macro call. **[C]**
* This column rule is also why `LOOP` can be a label in `JONSBIT.MUS:149`
  (`LOOP` in column 1, then `JMP LOOP`) while `LOOP` in the opcode field is the
  loop terminator (`ENDCODE.ROU:37` uses lowercase `until`). The token is
  interpreted by field position, not by spelling. **[C]**
* A label on a call line is defined at the current PC, before the expansion
  emits anything. `putinheart<TAB>changebank 13` therefore labels the first byte
  of the expansion; a macro that emits nothing (`zvar`) labels the current PC.
  **[C]**

### 1.2 Legal macro names

Macro names use the label character set `A-Z a-z 0-9 . _ $` and are
case-insensitive. Dots and underscores are real: `move.w`, `move.b`,
`move.val`, `gav_ADD`, `gav_SUB`. **[C]**

A macro name may not collide with an instruction or pseudo-op; the manual says
so, and the binary reports `Unknown instruction` rather than silently preferring
one. `ADD` and `SUB` are legal macro names precisely because the 6502 has `ADC`
and `SBC`, not `ADD`/`SUB` (`MACROS.PDS:492,504`; used at `START.ROU:34` and
`HISCORE.ROU:91`). **[M]** **[C]**

A macro name is not a symbol: using it in an expression produces the binary
diagnostic `You are trying to reference a macro name`. Do not emit a symbol
table entry for the macro name itself. **[B]**

### 1.3 Macro calls are resolved before instruction lookup

After parameter substitution the expanded line is parsed exactly like source.
If the opcode field contains another macro name, that macro is expanded too
(§3.5). This is how `ldir` calls `ldirind` (`MACROS.PDS:453`) and `TIMEY` calls
`TICKS`/`CLOCKS` (`MACROS.MUS:351,354`). **[C]**

---

## 2. Definition syntax and limits

### 2.1 Grammar

```
NAME MACRO [p1,p2,p3,...]
    body line 1
    body line 2
    ...
ENDM
```

* `NAME` — column-1 label; becomes the macro name. **[M]**
* `MACRO` — the directive; `.MACRO` is also documented and present in the 1.21
  keyword table. `MACRO`/`.MACRO` are case-insensitive. **[M]** **[B]**
* `[p1,p2,...]` — optional **named** parameters, comma-separated. They are
  expressions, not raw text (§3.3). No corpus definition uses this form. **[M]**
* Body — any number of logical lines, including blank lines and comments. It is
  stored raw and not assembled at definition time. **[M]**
* `ENDM` — terminates the definition. `.ENDM` is the documented dotted alias.
  `ENDM` may be indented, and may be preceded by a label in column 1; the corpus
  has `!1<TAB>endm` at `MACROS.PDS:126`, which defines `!1` at the current PC and
  then closes the macro. **[M]** **[C]**
* There is **no `JENDM`**. See §0.1. The manual's “also covered” list is `ENDM`,
  `.ENDM`, `EXITM`. **[M]** **[B]**

There is no `ENDM`-with-name syntax and no macro-local `ENDM` label. The first
line whose opcode field is `ENDM` ends the definition.

### 2.2 Definition-time behaviour

* A macro definition is decoded on pass 1 and stored in the macro/symbol pool.
  It emits no bytes. In a `LIST` listing the definition line is marked `>`
  (“a macro definition was decoded at that line”). **[M]**
* The body is not evaluated at definition time. `zvar` references `zlim` before
  `zlim` is initialised (`MACROS.PDS:24-31`); that is legal because the body is
  only text until a call. **[C]**
* Macro definitions can be conditional. `MACROS.MUS` wraps all 39 of its
  definitions in `if musicon=1` … `endif` (`MACROS.MUS:1,360`); with
  `musicon=0` none of those macros exist. `JONSBIT.MUS` defines `DJ` inside the
  false `IF gav_master=0` block (`JONSBIT.MUS:43-55`), so `DJ` is effectively
  absent from the shipped build. A skipper must therefore **not install**
  definitions from a false conditional branch. **[C]**
* Definitions must precede calls in source order. A call before the definition
  is an unknown instruction. **[M]** **[I]**
* Macro definitions may **not** be nested. The binary has both
  `Macros cannot be nested` and (1.26 Z80 wording)
  `I'm not doing a macro, or you have nested macro definitions`. Nested macro
  *calls* are fine; nested `MACRO` … `ENDM` definitions are not. **[B]** **[C]**
* A macro may not be redefined under the same name; that is a symbol-table
  collision (`This is the second time that symbol has been defined`) or a
  macro-table error, depending on where the limit is hit. **[B]** **[I]**
* `INCLUDE` inside a macro body is rejected: `Include files not allowed in
  macros`. An include file may of course *contain* macro definitions and calls
  (the project uses `INCLUDE`/`FILE` at project level, but the assembler itself
  cannot nest includes). **[M]** **[B]**

### 2.3 Limits

| Limit | Value | Evidence |
|---|---|---|
| Macros defined | **250** | Manual p.26; binary `Only 250 macros may be defined`. **[M]** **[B]** |
| Positional parameters | **9** (`@1`…`@9`) | Manual; binary `Only 9 parameters allowed`, `Macro parameters may only be @1 to @9`. **[M]** **[B]** |
| Named parameters | up to the same 9 slots | Manual example uses 3; no corpus use. **[M]** |
| Nested macro **calls** | manual says “depth of four”; 1.21 string says “depth of 3” | Interpret as 3 nested calls inside the outermost, i.e. 4 active frames, or as 3 frames total; see §2.4. **[X]** |
| Recursion | forbidden | Binary `Recursion with macros not allowed`. **[B]** |
| Nested `IF` inside a macro | 10 (same global limit) | Manual; binary `Cannot have more than 10 nested IF's`. **[M]** **[B]** |
| Nested `DO` inside a macro | none (one loop level) | Binary `DO, LOOP and UNTIL cannot be nested`. **[B]** |
| Macro table space | shared with symbols | Binary `Out of symbol/macro table space`; 250 is a ceiling, the pool can fail first. **[B]** |

The corpus never stresses any of these: 107 definitions, static call depth 2
(`TIMEY` → `TICKS`/`CLOCKS`, `ldir` → `ldirind`, `testcrash` →
`blackandwhite`/`colour`), maximum `IF` nesting 4 in the whole build. **[C]**

### 2.4 The depth conflict

The manual says:

> Macros can be nested to a depth of four, but may not be recursive.
> — `docs/PDS_6502_Manual.md:435`

The 1.21 binary says:

> `Macros can only be nested to a depth of 3`

The safest reading is that the binary counts **nested calls** (a call inside a
call inside a call = 3), so four macro frames including the outer one are
active. A transpiler can implement `max_frames = 4` and reject the fifth; if
strict 1.21 compatibility matters, reject when more than 3 macros are nested
below the outermost. No corpus source comes close, so this is not a byte-level
risk.

### 2.5 `EXITM`

```
FRED MACRO
    IFS [@1] []
        EXITM
    ENDIF
    ADC @1
ENDM
```

* `EXITM` is a macro-only, conditional-only early return. The binary diagnostic
  is `EXITM can only be used inside a MACRO, in an IF statement`; a bare
  `EXITM`, or one in a macro outside an active `IF`/`IFF`/`IFS`, is an error.
  **[M]** **[B]**
* When executed it stops the current expansion immediately, returns to the
  caller, and **discards all uncompleted conditional frames opened in that
  macro** — “basically the same as an `ENDM`, except that uncompleted
  conditional structures are cleared” (`docs/PDS_6502_Manual.md:446-447`).
  **[M]**
* The `ENDIF` after `EXITM` is normally not reached; the manual example puts
  `EXITM` before `ENDIF` precisely to show this. **[M]**
* `EXITM` exits only the **current** (innermost) macro, not all nested calls.
  It does not clear the caller's `IF` frames. **[I]** (The frame stack in
  `08-assembler-internals.md` §9.2 restores one 0x104-byte frame.)
* `EXITM` also closes the macro's local-label scope; labels defined before the
  exit do not leak to the caller. **[I]**

Real uses: `WRITE` (`MACROS.MUS:214`) and `SETBANK` (`MACROS.MUS:233`), both
inside `IF`/`IFS`; see §9.6.

### 2.6 Listing controls

`LIST MACRO` toggles whether macro **calls** show the full expansion in the
listing. With it off (the default), a call is listed as the macro name; with it
on, the expanded body is shown. The listing's action characters are `:` for an
assembled line, `+` for a line ignored by a failed `IF`, and `>` for a decoded
macro definition. This affects only the listing, never the object bytes or the
expansion semantics. `LIST MACRO` applies to both screen and printer; `LLIST
MACRO` is not a separate command. **[M]**

---

## 3. Parameter model

### 3.1 Positional `@1`…`@9` are raw text

A positional parameter is **not** an expression. It is the exact argument text
(after trimming and bracket removal) inserted into the body. The manual is
explicit: “macro parameters need not be expressions. They are text strings that
are inserted into the code in the macro in place of the equivalent `@number`.”
(`docs/PDS_6502_Manual.md:397-400`). **[M]**

Because substitution is textual and happens before lexing, `@n` can be any of
these. The examples are corpus uses except the `SUM` mnemonic row, which is the
manual's example. **[C]** **[M]**

| Position | Example | Expansion |
|---|---|---|
| Whole label (column 1) | `MACROS.PDS:25` `@1<TAB>equ zlim` with `zvar cm_frames,1` | `CM_FRAMES<TAB>equ zlim` |
| Whole mnemonic | `docs/PDS_6502_Manual.md:405` `@2 #@3` with `SUM FRED,ADC,3` | `ADC #3` |
| Operand | `MACROS.PDS:120` `lda @1` with `addto16 address,5` | `lda address` |
| Operand fragment | `MACROS.PDS:125` `inc @1+1`, `MACROS.PDS:248` `lda #>@2` | `inc address+1`, `lda #>value` |
| Addressing-mode fragment | `MACROS.PDS:335` `lda @1,y`, `MACROS.PDS:382` `lda @1-UUU-1,x` | `lda source,y`, … |
| Inside a quoted message | `MACROS.PDS:28` `ERROR "Out of zero page work space with variable @1` | message contains `CM_FRAMES` |
| Inside a file path | `MACROS.MUS:157` `INCBIN C:\gav\NIN4\GFX4\@1.OBJ` | `INCBIN C:\gav\NIN4\GFX4\PIC.OBJ` |
| Branch operand | `MACROS.PDS:699` `bcc @1` | `bcc label` |

Consequences for a transpiler:

* Substitute first, then run the normal label/opcode/operand parser. Never try
  to lex `@1` as a symbol.
* The substituted text can change the line's field structure. A parameter that
  becomes a label at column 1 must be treated as a label; a parameter that
  becomes `ADC` in the opcode field must be treated as a mnemonic.
* Substitution inside strings is real (`ERROR "… @1`), so do not skip quoted
  regions when scanning for `@n`. The same is true for file paths. **[C]**
* Substitution inside a comment is harmless because the comment is stripped;
  however an argument containing `;` can terminate the expanded line early when
  the normal lexer runs. Do not use `;` in macro arguments. **[I]**
* `@` not followed by a digit is literal text. `@@` followed by a digit is the
  evaluated form (§3.2); scan `@@` before `@` so `@@1` is not read as `@` + `@1`.

Only `@1`…`@9` exist. `@0` and `@10` are not parameters; the binary rejects
them with `Macro parameters may only be @1 to @9`. **[B]**

### 3.2 `@@n` — evaluate the argument, then substitute the value

`@@n` evaluates the argument as an expression at expansion time and inserts the
**value** as a number token. The manual's example is a label generator: **[M]**

```
FRED  MACRO
VAR@@1  EQU  *
ENDM

FRED  3*2
```

expands to

```
VAR6  EQU  *
```

not `VAR3*2`. The manual explains: “This will create a variable called `VAR6`
within the macro, while a normal `@1` would have tried to create a label called
`VAR3*2`.” (`docs/PDS_6502_Manual.md:420-425`).

The only corpus use is `MACROS.MUS:326`:

```
TICKS  MACRO
    JSR TICKS@@1
ENDM
```

so `TICKS CLN` with `CLN=12` becomes `JSR TICKS12`; with `CLN=7`, `JSR TICKS7`.
This is how the music macros dispatch to a fixed per-length delay routine.
**[C]**

Implementation notes:

* Evaluation happens **before** insertion, in the caller's expression context
  (the macro body has not run yet). Use the current symbol table and `*` PC.
  **[I]**
* The result is formatted as a number token. Under the default `RADIX 10` it is
  decimal; `08-assembler-internals.md` §9.2 says “the current radix”. The only
  documented example is decimal, and the corpus never changes `RADIX`, so use
  decimal by default and do not rely on hex formatting. **[M]** **[X]**
* A forward reference in the argument is dangerous: the value would differ
  between passes. PDS's general rule is that such expressions must not contain
  forward references (`This expresion must not contain forward references`);
  treat an unresolved `@@n` as an error. **[B]** **[I]**
* `@@n` is a textual replacement like `@n`; it can appear inside a longer
  identifier (`VAR@@1`, `TICKS@@1`) or in an operand. It cannot be used as a
  whole mnemonic unless the resulting number is a valid mnemonic (it is not).
* A negative value is represented as its 16-bit two's-complement value by the
  assembler's number model (manual: negative numbers are 32768…65535). Whether
  `@@` prints `-1` or `65535` is not documented; avoid negative `@@`. **[I]**

### 3.3 Named parameters

The optional list after `MACRO` names the parameters:

```
FRED  MACRO  JOHN,BILL,JANE
    LDA  JOHN
    ADC  BILL
    EOR  JANE
ENDM
```

At a call `FRED 2,3,4`, the manual's `LIST MACRO` output shows: **[M]**

```
JOHN  = 2
BILL  = 3
JANE  = 4
    LDA JOHN
    ADC BILL
    EOR JANE
```

So the binding model is:

* Named parameters bind **by position**: `JOHN` ← arg 1, `BILL` ← arg 2, etc.
* At expansion, PDS synthesises redefinable assignments (`NAME = value`) before
  the body. `08-assembler-internals.md` §9.2 describes them as hidden
  replacement lines with a `\r<n> @<name>=` style prefix.
* They are usable anywhere an expression is expected, unlike raw `@n`. They are
  not text substitution; `LDA JOHN` evaluates `JOHN`'s numeric value.
* Positional `@n` remains available as well; `09-transpiler-spec.md` §4.1 says
  named parameters are “also counted for `@n`”. **[I]**
* Treat the names as **macro-local**. The manual says “refer to them as labels
  within the macro”; hidden replacement lines suggest they are scoped to the
  expansion. Whether a named parameter leaks into the global symbol table after
  `ENDM` is not documented; do not rely on it. **[M]** **[I]**
* Because they are assigned with `=`, repeated calls do not produce a
  “multiply defined label” error. A named parameter that collides with a real
  global label would shadow/overwrite it if the implementation is not scoped;
  avoid such names. **[I]**
* No corpus macro uses named parameters. Only the manual exercises them. **[C]**

### 3.4 Argument parsing: commas, `[]`, whitespace, empty and missing arguments

The call's operand text is split on commas **outside square brackets**.
Leading and trailing whitespace is removed from each argument; internal
whitespace is preserved. **[M]**

```
FRED  23,[45,56,67],98
```

gives

```
@1 = 23
@2 = 45,56,67
@3 = 98
```

The outer `[` `]` of a grouped argument are **removed**; the commas inside are
kept as part of that one argument. The manual page image makes this explicit
(`@2 = 45,56,67`, not `[45,56,67]`). **[M]**

Rules:

* `[a,b,c]` is one argument whose text is `a,b,c`.
* `[]` is the empty argument. It is how macros test “parameter not supplied”:
  `IFS [@1] []`, `IFS [@4][]` (§5.3).
* `a,,b` yields three arguments: `a`, empty, `b`. Trailing/leading commas yield
  empty arguments. **[I]** (Consistent with the `IFS [@n][]` idiom.)
* Missing trailing arguments are simply absent; `@n` for an absent argument
  expands to the empty string. This is used by `incr` (`MACROS.PDS:183`),
  `decr`, `sub`, `add`, and `TIMEY`. **[C]**
* Extra arguments are **not** rejected automatically. The assembler accepts up
  to 9; a 10th gives `Only 9 parameters allowed`. Individual macros check for
  extras with `IFS [@N+1] []` and `ERROR` (e.g. `incr` checks `@2`, `sldir`
  checks `@4`). A transpiler must not impose the macro's expected arity; it
  must pass the text through and let the macro's own `IFS` test decide. **[B]**
  **[C]**
* Whitespace inside `[]` is part of the argument text; it is not split. Whether
  PDS trims spaces immediately inside the brackets is not documented. The
  corpus never uses `[]` grouping outside `IFS`, so this is unexercised. **[I]**
* Case: the assembler folds identifiers to upper case, and the manual says “all
  the parameters will be converted into upper case” in the `IFS` note
  (`docs/PDS_6502_Manual.md:365`). Quoted string literals keep their case in
  data directives (`DC 2,"cat"` emits lowercase), so a quoted argument may keep
  its case. Real macro arguments are labels, numbers, `#`-fragments and DOS
  paths, all case-insensitive. Rule for a transpiler: fold identifiers for
  lookup and for `IFS`, but preserve the bytes of a quoted string literal.
  **[M]** **[C]** **[I]**
* A `;` comment starts at the call site before argument splitting; you cannot
  pass a semicolon as an argument without it becoming a comment. **[I]**
* Quotes do **not** protect commas in the call's argument list; the manual's
  only comma-protection mechanism is `[]`. A quoted argument containing a comma
  must still be bracketed. **[M]**
* The brackets are grouping only for macro-call arguments. `IFS` has its own
  bracket syntax and must see the brackets; do not strip them before parsing an
  `IFS` line. **[M]**

### 3.5 Substitution timing and expression/byte interactions

The model is: **store the body raw; at each call, substitute the body line,
then lex and assemble it.** This is proved by the corpus: **[C]**

* `@1<TAB>equ zlim` puts the substituted text in the column-1 label field. If
  lexing happened before substitution, `@` would be an illegal first label
  character.
* `@2 #@3` puts a substituted mnemonic in the opcode field.
* `lda #>@1` substitutes inside a byte-extraction expression; the `#`/`>` are
  parsed after substitution.
* `ERROR "… @1` and `INCBIN …@1.OBJ` substitute inside a quoted string/path.

Order of operations for one expanded line:

1. Strip editor control bytes (`0x01`/`0x02`) and DOS `^Z`.
2. Substitute `@@n` (evaluate) and `@n` (raw) left-to-right.
3. Lex label (column 1), opcode, operand, comment.
4. If the opcode is a macro name, recurse/queue another expansion.
5. Otherwise define labels and assemble the directive/instruction.
6. Update PC and listing.

Important consequences:

* **Expressions see the substituted text, not the original.** `@1` can be an
  operand fragment, a whole expression, or a string; `@@1` is already a number
  token and cannot be an operator fragment.
* **Byte operators apply after substitution.** `#>@1` with `@1=address` is
  `#>address`; with `@1=1234` it is `#>1234`. The `<`/`>` semantics are PDS's
  inverted ones: `<` = high byte, `>` = low byte (`03-directives.md` §0).
* **Do not rescan inserted text.** A single pass over the stored body is the
  natural implementation. If an argument's text itself contains `@2`, PDS's
  behaviour is not documented; rescanning would make argument text act like
  macro code, which is almost certainly not intended. Use one pass. **[I]**
* **Substitution happens per body line, not once for the whole body.** A
  multi-line body can use the same `@1` on every line. **[M]**
* **Nested calls are expanded after the outer line is substituted.** The inner
  call sees the outer arguments' text. Its own `@n` names are a fresh set, and
  its local labels are a fresh scope. **[C]**
* **Passes must agree.** Substitution itself is deterministic, but `@@n` and
  `IF` decisions can depend on symbols. If a value changes between pass 1 and
  pass 2, PDS reports `Phase error`/`Phase error between passes`. Do not use
  forward references in `IF` or `@@`. **[B]**

### 3.6 Byte-extraction order — the `MACROS.MUS` inversion

The byte operators are configuration-dependent. In the main build (no
`OPTION`), the ledger's byte-level checks establish:

```
<expr = HIGH byte      >expr = LOW byte       (PDS default)
```

`BANK12 DEFB <B12,>B12` with `B12=2` emits `00 02`, which is the last two bytes
of `ROBINV7.BC`; `BANK14` behaves the same. That is the order used by
`MACROS.PDS` (`defspr`, `add16toval`, `ldxy`) and by all bank headers. **[C]**

However, `MACROS.MUS` starts with:

```
OPTION 0,0        ; MACROS.MUS:25
```

and `JONSBIT.MUS` with the same (`JONSBIT.MUS:49`). `OPTION` is undocumented;
the only documented option number is `1` (logic precedence), and the corpus'
`0,0` is treated as a default/no-op by `02-expressions.md` §5 and the ledger.
**[C]** **[I]**

Under the verified default, the byte-order macros in `MACROS.MUS` are **inverted
relative to their names and intended 6502/PPU use**:

* `LOW` is `LDA #<@1` and `HIGH` is `LDA #>@1`; a pointer store
  `LOW ptr; STA dst; HIGH ptr; STA dst+1` needs low-then-high, but the default
  order makes it high-then-low.
* `VRAM` uses `HIGH` then `LOW`; the NES PPU `$2006` latch expects high-then-low,
  but the default order makes it low-then-high.
* `VECT` is `DB <@1,>@1`; a 6502 vector table is low-then-high, but the default
  order makes it high-then-low.
* `LOAD`/`MOVE`/`FADE` store the two bytes into a pointer/DAC address in the
  order that is wrong under the default.

Two explanations are possible:

1. `OPTION 0,0` changes the byte-extraction order for the rest of the file
   (conventional `<`=low, `>`=high). This is **not documented** and is
   contradicted by `02-expressions.md`'s no-op treatment.
2. The `MACROS.MUS`/`JONSBIT` byte-order macros are legacy code written for a
   different assembler convention, and are simply dead in this build. This is
   consistent with the call census: `WRITE`, `VECT`, `LOAD`, `MOVE`, `FADE`,
   `LOW`, `HIGH` and `VRAM` are all **uncalled in the live build**; the only
   `LOW`/`HIGH`/`VRAM` calls are in the dead `JONSBIT` driver (`gav_master=1`).
   **[C]**

Do **not** use these macros as evidence for the assembler's byte order. For the
live build, use the verified `BANK12/14` convention (`<`=high, `>`=low). If you
ever expand `WRITE`/`VRAM`/`LOAD`/`VECT`, decide explicitly whether to follow
the macro's *intent* (conventional low/high) or the assembler's default
(inverted); the two disagree. The annotated `WRITE` bytes in §9.6 are the
intended conventional order and are marked **[I]** for that reason.

Because macro bodies are stored raw, any `OPTION` byte-order change would affect
a body byte-op at **expansion time**, not definition time. Track it as state if
you implement `OPTION`; otherwise reject the file rather than guessing.

---

## 4. Local labels (`!name`)

### 4.1 Syntax and lifetime

A label whose first character is `!` is local:

```
!1   lda #0
     bne !1
```

* The `!` is not part of the normal label-character set; it is a special
  first character that selects local scope. After `!`, the normal label
  characters apply: letters, digits, `.`, `_`, `$`. A bare `!` is invalid
  (`A single local label character is not a valid label`). **[M]** **[B]**
* Local names are case-insensitive like all symbols. The corpus uses numeric
  (`!1`, `!14`, `!670`), named (`!POWERUP`, `!TRIANGLE`, `!SKIP`), and dotted
  (`!T3.3`) forms. **[C]**
* `!0` is a legal local name, not a special “current PC” operator. The only
  uses are `!0 DB "…"` followed by `IF *-!0 <> 19` (`CMLOGO.ROU:2732-2734`,
  `SMILEY.ROU:315-317`); this is an ordinary label at the start of the DB line,
  used to measure its length. There is no separate `!0` PC token in the manual.
  **[C]** (Clarifies the ledger's “start-of-line PC symbol” wording.)
* A local label is defined like any label: column 1, optionally with a
  following instruction on the same line. Same-line use works:
  `orgfullpage` has `!1<TAB>org (!1/256)*256+256` (`MACROS.PDS:109`), where `!1`
  is both defined and referenced in its own operand. **[C]**
* Forward references work **within one local scope**. `SOUNDFX.ROU:273` uses
  `DW !CHOOSE_LETTER,!EXTRA_LIFE,!metal_ball` while `!METAL_BALL` is defined at
  line 586, with no global label in between. A forward local reference that
  crosses a global-label boundary will not resolve, because the local table was
  cleared. **[C]** **[I]**

### 4.2 When locals are cleared

| Trigger | Clears locals? | Evidence |
|---|---|---|
| Any non-`!` label in column 1 | **yes** | Manual p.7/§2; empirical: 806 definitions, zero same-scope duplicates. **[M]** **[C]** |
| Entry to a macro expansion | **yes** (fresh scope) | Manual p.27; `MACROS.PDS` reuses `!1` in many separate macros. **[M]** **[C]** |
| Exit from a macro expansion | **yes** (caller's scope restored) | Manual p.27; locals do not leak. **[M]** |
| End of a `DO`/`LOOP` iteration (`LOOP`) | **yes** | Manual p.14: “When `LOOP` is executed the local labels are cleared.” **[M]** |
| `DO`/`UNTIL` iteration boundary | **yes** (loop boundary) | `08-assembler-internals.md` §6.7/§9.3; not separately documented. **[I]** |
| `ORG`/`BANK` | not documented | Every bank file starts with a global label, so no corpus case tests it. Treat as **not** clearing unless a global label follows. **[I]** |
| Start of file | yes (trivially) | — |

The PDS implementation indexes its local-label table by a current scope id
(`[0x6786]`), which is why locals die at the next global label or macro/loop
boundary (`08-assembler-internals.md` §6.7). This is the mechanism to mimic,
not ca65's `@` locals: PDS's reset points are different. **[I]**

### 4.3 Locals in macros are per-expansion and isolated from nested macros

The manual's example is the clearest statement: **[M]**

```
BILL  MACRO
!1    NOP
      JMP !1
ENDM

FRED  MACRO
!1    BILL
      JMP !1
ENDM

!1    FRED
      JMP !1
```

Each `!1` is a different symbol:

* The outer `!1` before `FRED` is in the caller's scope.
* The `!1` inside `FRED` is a new scope, even though it is on the same line as
  the nested `BILL` call.
* The `!1` inside `BILL` is another new scope.
* `JMP !1` after `BILL` inside `FRED` refers to `FRED`'s `!1`, not `BILL`'s.
* The final `JMP !1` in the caller refers to the caller's `!1`.

“Local labels in macros do not affect other local labels of the same name —
either in the main program or in nested macros.” (`docs/PDS_6502_Manual.md:435`).
**[M]**

A macro parameter that is textually `!1` does **not** reach the caller's `!1`:
the substituted body line is parsed in the macro's scope, so it resolves to the
macro's local `!1` (or a forward reference to it). The manual explicitly warns
about this (`docs/PDS_6502_Manual.md:439-441`). **[M]**

### 4.4 Interaction with `@n` and `@@n`

| Form | Kind | Scope at resolution |
|---|---|---|
| `!1` | local **symbol** | Current local scope; cleared as in §4.2. |
| `@1` | raw parameter **text** | Text is inserted; any `!` inside it is then resolved in the macro's current scope. |
| `@@1` | evaluated parameter **value** | Evaluated at expansion time in the caller's expression context; inserted as a number. |
| `JOHN` | named parameter **symbol** | Macro-local assignment (`JOHN = value`); usable in expressions. |

Do not conflate them. A macro that wants to pass a caller's local label should
pass a global label instead, or use a parameter that is not a `!` name.
Passing `!1` through `@@1` is especially unclear (evaluation context of a local
in the caller vs. the macro is not documented); avoid it. **[I]**

### 4.5 Mangled names for a transpiler

Use a **scope id** that increments at every PDS local-clear point, not merely a
per-macro counter:

```
scope_id = 0
mangle(!name) = "__PDS_L" + scope_id + "_" + upper(name)

on_global_label():      scope_id += 1
on_macro_entry():       push scope_id; scope_id = new_id()
on_macro_exit():        scope_id = pop()
on_loop_iteration_end():scope_id += 1
```

Example: the first call of `waitforninesprs` in scope 7 maps `!1` to
`__PDS_L7_1`; a second call in scope 8 maps it to `__PDS_L8_1`; if a global
label occurs inside one expansion, the following `!1` gets a new scope id and
therefore a different mangled name (which is exactly PDS's “cleared” semantics).
This is stronger than `macro_name + call_count + local`, which would collide if
a macro reuses `!1` after an internal global label. **[I]**

Scope ids must be assigned deterministically and reset identically on pass 1
and pass 2; otherwise the two passes can disagree on symbol values and produce a
phase error. The simplest rule is: reset the counter and all expansion counters
at the start of each pass.

---

## 5. Conditionals

### 5.1 `IF` / `ELSE` / `ENDIF`

```
IF expression
    ; assembled if expression != 0
ELSE
    ; assembled if expression == 0
ENDIF
```

* Non-zero is true, zero is false. **[M]**
* At most one `ELSE` per `IF`; a second gives `Cannot have more than one ELSE`.
  **[B]**
* Nesting depth **10**; the 11th gives `Cannot have more than 10 nested IF's`.
  The corpus maximum is 4 (`BANK14.PDS:9`). **[M]** **[B]** **[C]**
* A label **is** allowed on the `IF` line. `ENDCODE.ROU:27` has
  `endofcode<TAB>if endofcode>&fff9`; the label is defined at the current PC,
  then the condition is evaluated. `ELSE` and `ENDIF` must **not** have labels:
  `ELSE and ENDIF must not have labels`. **[C]** **[B]**
* `IF` emits nothing. A false branch emits nothing, defines no labels, and does
  not expand macros. In the listing, skipped lines are marked `+`; assembled
  lines are marked `:`. **[M]**
* The condition must be decidable identically on pass 1 and pass 2. A forward
  reference in an `IF` expression is an error:
  `This expresion must not contain forward references` (binary spelling).
  **[M]** **[B]**
* If the two passes nevertheless disagree, PDS reports `Phase error` or
  `Phase error between passes`. **[B]**
* `IF` may be used at top level, inside a macro, inside a loop, etc. A macro
  body's `IF` is evaluated at expansion time after `@n`/`@@n` substitution, so
  it can depend on arguments. `changebank` (`MACROS.PDS:170-180`) and `defspr`
  (`MACROS.PDS:46-58`) are the canonical examples. **[C]**

#### `IF` state machine (simplified)

PDS keeps five values: zero (not in an `IF`) plus four active states
(`08-assembler-internals.md` §9.1):

| State | Meaning |
|---|---|
| 0 | not in an `IF` |
| 1 | false branch: skip to `ELSE`/`ENDIF` |
| 2 | true branch: assemble to `ELSE`/`ENDIF` |
| 3 | true branch finished, `ELSE` seen: skip to `ENDIF` |
| 4 | `ELSE` branch: assemble to `ENDIF` |

A transpiler can model this with a stack of `{taken, else_seen, parent_skipping}`
frames and a `skip_depth` counter for nested conditionals inside a skipped
region.

#### What is parsed while skipping?

This is the part that usually breaks a reimplementation.

* The main line loop handles `ENDIF`, `ELSE` and nested `IF`/`IFS`/`IFF`
  **inline** while skipping; it does not call the normal directive handler.
  **[B]** (`08-assembler-internals.md` §9.1)
* Nested `IF`/`IFS`/`IFF` in a skipped block increment the nesting counter but
  their expressions are **not evaluated**. `ELSE`/`ENDIF` adjust the counter.
  **[B]**
* Ordinary directives, instructions, labels and macro calls in a skipped block
  are **not executed**: no bytes, no symbol definitions, no macro expansion.
  **[M]**
* Macro definitions in a skipped block are not installed. `MACROS.MUS` relies on
  this: the whole file is inside `if musicon=1`. A robust skipper should consume
  a `MACRO`…`ENDM` body as a unit while skipping so that any `IF`/`ENDIF` text
  inside the body cannot desynchronise the outer conditional. PDS has a
  “currently defining a macro” flag and a skip-suppress flag for this bookkeeping
  (`08-assembler-internals.md` §2.3). **[C]** **[I]**
* Comments and string literals are not directives: an `IF` inside a comment or
  string does not affect nesting. Only the opcode field counts. **[I]**
* `EXITM` in a skipped block is ignored (not executed). If the block is skipped,
  the macro simply continues to its `ENDM`.
* An unterminated nested `IF` in a skipped block eventually produces
  `No ENDIF after last IF` or `ENDIF was expected`.

### 5.2 `IFF` — assemble if the operand is a forward reference

`IFF` is `IF`'s counterpart for expressions that cannot be resolved on pass 1:

> `IFF` is similar to `IF`, but will only assemble the following code if the
> expression after `IFF` contains a forward reference. This is necessary because
> normal `IF` statements cannot have forward references — the assembler must
> know the route of action on both pass 1 and pass 2.
> — `docs/PDS_6502_Manual.md:343-345`

Semantics: **[M]** **[B]**

* Operand names a symbol (or expression containing a symbol) that is **not yet
  defined at this point on pass 1** → the block is assembled.
* Operand is fully known/resolved → the block is skipped (use `ELSE` if needed).
* It does not need the numeric value; it tests forwardness, so a forward label
  is fine.
* If the operand cannot be interpreted as a forward-reference test (syntax
  error), the manual says an error is given.
* On pass 2 all symbols are known, so the pass-1 decision must be remembered/used
  again; otherwise the two passes would choose different code sizes. PDS's
  symbol records and phase checking imply this; treat the pass-1 forward flag as
  authoritative. **[I]**

The canonical use is the manual's `JCC` macro (`docs/PDS_6502_Manual.md:741-767`):

```
JCC  MACRO
    IF  (@2-*<130) ! (*-@2<126)
        IFF  @2
        ELSE
            B@1  @2
            EXITM
        ENDIF
        B@1  !1
        JMP  !2
    !1  JMP  @2
    !2
    ENDIF
ENDM
```

For a backward target whose distance is known, `IFF @2` is false, so the short
`Bcc @2` is emitted. For a forward target, `IFF @2` is true, so the macro emits
the conservative long form (`Bcc !1 / JMP !2 / !1 JMP @2 / !2`). The macro's
outer `IF` is a distance test; the `IFF` is the “unknown distance” override.
There is **no `IFF` in the shipped corpus**; only this manual example uses it.
**[C]**

### 5.3 `IFS` — string comparison

Grammar:

```
IFS [s1] [s2] [s3] ...
```

* The first bracketed string is compared against each following bracketed
  string. Brackets are the delimiters; commas are not used (whitespace between
  groups is optional: `ifs [@2][]`). **[M]** **[C]**
* **Manual semantics: OR — assemble if `s1` equals any one of `s2…sn`.**
  The manual's explicit example is
  `IFS [FRED] [BILL] [JOHN] [TONY] [FRED]` → assembled because `FRED` matches
  the last group (`docs/PDS_6502_Manual.md:357-362`). **[M]**
* **Confirmed OR (binary):** the handler at `0e60:3482` copies the first group
  to `0x6AFC`, then compares each following group against it and returns true
  as soon as one matches; it returns false only after all groups mismatch.
  `IFS [FRED] [BILL] [JOHN] [TONY] [FRED]` is therefore true, as the manual
  says. The corpus has 26 `IFS` uses and **every one has exactly two bracket
  groups**, so it could not distinguish the two readings. Earlier
  `08-assembler-internals.md` §9.1 and `09-transpiler-spec.md` §4.3 said “all
  pairs must match”; that was wrong and has been corrected. **[B]**
* `[]` is the empty string. `IFS [@1] []` is the standard “was the parameter
  omitted?” test; `defspr` uses `IFS [@5] []` to make the fifth argument
  optional. **[M]** **[C]**
* Comparisons are case-insensitive in practice because the source is folded to
  upper case; the manual says “all the parameters will be converted into upper
  case.” Do not implement a case-sensitive compare for identifiers. **[M]**
* At least two bracket groups are required; a missing `[` or `]` gives
  `Syntax : IFS [xxx] [yyy], missing [` or `Missing ]`. **[B]**
* `IFS` supports `ELSE`/`ENDIF` and `EXITM` exactly like `IF`. It emits nothing.
  **[M]**
* `IFS` operands are raw text after macro substitution. A `]` inside an argument
  would terminate the group early; there is no escape mechanism. **[I]**

Real uses are almost all optional-argument/string dispatch:

```
MACROS.PDS:48   ifs [@5] []       ; defspr optional fifth byte
MACROS.PDS:184  ifs [@2][]        ; incr: exactly one arg
MACROS.MUS:228  IFS [@1] [X]      ; SETBANK: X register form
MACROS.MUS:237  IFS [@1] [A]      ; SETBANK: A register form
MACROS.MUS:332  IFS [@2] []       ; TIMEY optional second arg
```

**[C]**

### 5.4 `EXITM` inside conditionals

`EXITM` is only legal inside a macro **and** an active `IF`/`IFF`/`IFS`. It
exits the macro and discards the conditional frames opened in it. Two real
examples:

`SETBANK` (`MACROS.MUS:227-248`):

```
SETBANK MACRO
    IFS [@1] [X]
        TXA
        STA BANKBITS,X
        EXITM
    ENDIF

    IFS [@1] [A]
        TAX
        STA BANKBITS,X
    ELSE
        LDA #@1
        STA BANKBITS+@1
    ENDIF
ENDM
```

* `SETBANK X`: first `IFS` true; emits `TXA / STA BANKBITS,X`; `EXITM` leaves
  the macro before the second `IFS`. **[C]**
* `SETBANK A`: first `IFS` false; second true; emits `TAX / STA BANKBITS,X`.
  **[C]**
* `SETBANK 0`: both string tests false; `ELSE` emits `LDA #0 / STA BANKBITS+0`.
  **[C]**

`WRITE` (`MACROS.MUS:206-223`) uses `IF @1` then `EXITM` to select the top or
bottom nametable path; see §9.6.

### 5.5 Conditional error catalogue

All strings below are from the 1.21 6502 binary unless marked: **[B]**

| Message | Cause |
|---|---|
| `I'm not doing an IF` | `ELSE`/`ENDIF` with no open `IF`. |
| `Cannot have more than one ELSE` | second `ELSE` in one `IF`. |
| `ELSE and ENDIF must not have labels` | a label in column 1 on an `ELSE`/`ENDIF` line. |
| `No ENDIF after last IF` | end of source/macro with an open `IF`. |
| `ENDIF was expected` | block terminated where an `ENDIF` was required. |
| `Cannot have more than 10 nested IF's` | depth limit. |
| `This expresion must not contain forward references` | forward ref in `IF`/`EQU`/`ORG`/etc. |
| `Syntax : IFS [xxx] [yyy], missing [` | malformed `IFS`. |
| `Missing ]` | unclosed bracket group. |
| `EXITM can only be used inside a MACRO, in an IF statement` | bare `EXITM` or `EXITM` outside an active conditional. |
| `Phase error` / `Phase error between passes` | pass-1 and pass-2 decisions/sizes disagree. |

---

## 6. Loops

PDS loops are **compile-time unrollers**, not runtime loops. Every iteration
assembles the body again and advances the PC. There is no emitted loop
instruction unless the body contains one.

### 6.1 `DO expr` … `LOOP`

```
DO 8
    LDA (FRED),Y
    STA BILL,X
    INX
    INY
LOOP
```

* The count expression is evaluated **once**, at the `DO`. **[M]**
* The body is assembled exactly `count` times. `count` must be **greater than
  zero**; zero or negative gives `This parameter must not be zero or minus`.
  **[B]** (Corrects `03-directives.md`, which says N=0 emits nothing.)
* `LOOP` clears the local-label scope, so `!1` may be reused in every iteration.
  `DO 8 / ADC #20 / BCC !1 / INX / !1 INY / LOOP` is the manual's example
  (`docs/PDS_6502_Manual.md:209-218`). **[M]**
* `DO` cannot nest: `DO, LOOP and UNTIL cannot be nested`. One active loop. **[B]**
* `DO` and its `LOOP` must be in the same source section:
  `The LOOP or UNTIL must be in the same section of code as the DO`. **[B]**
* `DO` may be used inside a macro. `multword` uses `DO`/`UNTIL`
  (`MACROS.PDS:586-590`), and `REPEAT` is used inside `CLOCKS`. **[C]**
* `DO`/`LOOP` may **not** be used inside an include file:
  `DO, LOOP and UNTIL may not be used in include files`. **[B]**
* A label on the `DO` line (e.g. `runtablelo<TAB>do 47`,
  `CONTROL.ROU:911`) is defined **once**, before the first iteration, at the
  current PC. A label inside the body is redefined on every iteration; normal
  labels therefore produce `This is the second time that symbol has been
  defined`, while `=`/`DEFL` and `!` locals are safe. **[C]** **[I]**
* A label on the `LOOP` line would be at the end of every iteration and is
  therefore also a repeated definition unless it is a local. Avoid it. **[I]**

Real counted loops:

```
START.ROU:56-58       nops22  do 30 / nop / loop
TIMINGS.ROU:5-8       times16lo do 216 / defb >count / count = count+16 / loop
MAPSCROL.ROU:97-100   do 256 / defb >xx / xx = xx+14 / loop
CONTROL.ROU:911-914   runtablelo do 47 / defb runcounter / runcounter = ... / loop
```

`TIMINGS` generates a 216-entry low-byte table; `MAPSCROL` generates 256-entry
tables; `START` emits 30 NOPs. **[C]**

### 6.2 `DO` … `UNTIL expr`

```
DO
    LDA (FRED),Y
    STA BILL,X
    INX
    INY
UNTIL *>1000
```

* The body is assembled, then the expression is evaluated. Zero means repeat;
  a terminating value means exit. This is a do-while: the body runs at least
  once. **[M]**
* The expression is re-evaluated **every iteration**, so it can use `*` (PC),
  `=`/`DEFL` counters, and other symbols that change during unrolling. **[M]**
* The manual's example fills memory until the PC passes `$1000`. It recommends
  `* > 1000` rather than `* = 1000`, because a body that steps over `$1000`
  would never satisfy `=`, and would keep looping until the 16-bit PC wraps at
  `$FFFF`. **[M]**
* There is no iteration guard. A condition that never becomes true loops
  forever (or until the PC/size limit trips). A transpiler must impose a sane
  maximum and report an error. **[M]** **[I]**
* **Exit-value conflict:** the manual says “non-zero”, the 1.21 implementation
  reportedly tests exactly 1 (`08-assembler-internals.md` §9.3: `dec ax; jne
  repeat`). All corpus conditions are comparisons returning 0/1, so the corpus
  cannot distinguish them. Use `== 1` for binary-exact 1.21, or `!= 0` for the
  manual's wording; document the choice. **[X]**
* `UNTIL` also closes the iteration's local-label scope; the next iteration can
  reuse `!1`. **[I]**
* `DO`/`UNTIL` cannot nest and cannot be used in includes; the same section
  rule applies. **[B]**
* The body may contain `ORG` and `BANK`. `ENDCODE.ROU:32-37` is the proof:

```
wipebanks = 0
do
    org &8000
    defs &4000,0
    bank wipebanks
wipebanks = wipebanks+1
until wipebanks=12
```

Each iteration emits a 16 KiB block, then commits it as the next bank. The loop
frame survives the `BANK` reset; the bank wipe produces banks 0–11. **[C]**

`multword` (`MACROS.PDS:582-595`) is the macro-level `DO`/`UNTIL` example:

```
IF @2>1
mwn = @2
    DO
mwn = mwn/2
        asl @1
        rol @1+1
    until mwn EQU 1
ENDIF
```

For `@2=8`, the body runs 3 times (mwn 4, 2, 1), i.e. it shifts left
`floor(log2(@2))` times and multiplies by 8 — not “8 times by 2”. The comment
“no of times to mult by 2” is misleading; pass powers of two. **[C]**

### 6.3 `REPEAT expr` — repeat the next line

```
REPEAT 4
LSR A
```

is exactly four `LSR A` lines: bytes `4A 4A 4A 4A`. **[M]**

* `REPEAT` repeats the **single following logical source line**; it does not
  scan for a terminator. It is not `DO`/`LOOP`. **[M]**
* The count is evaluated at assembly time. Negative or forward values are
  rejected (`08-assembler-internals.md` §9.3); zero is not explicitly
  documented. Treat zero as “consume the line, emit nothing” or reject it
  consistently; the corpus always uses a positive value. **[X]** **[I]**
* The repeated line is assembled normally each time, so:
  * PC advances each time;
  * a normal label on that line is redefined on the second iteration (error);
  * a local label is **not** automatically given a new scope by `REPEAT` (unlike
    `LOOP`), so repeating a line with `!1` would also collide;
  * a macro call on that line is expanded afresh each time, so each expansion
    gets its own local scope.
  **[I]**
* `REPEAT` may be used inside a macro. `CLOCKS` uses it (`MACROS.MUS:295-296`):

```
IF CLN>8
    REPEAT (CLN-2)/7
    HEX 4868
CLN = CLN-(CLN-2)/7*7
ENDIF
```

`HEX 4868` is `PHA / PLA`; the `REPEAT` emits as many 2-byte delay pairs as the
cycle budget requires. **[C]**
* `REPEAT` is a directive line; it emits no bytes itself, only the next line's
  bytes N times.

### 6.4 Loop interactions summary

| Interaction | Behaviour |
|---|---|
| Labels / PC | Each iteration emits bytes and advances PC; labels inside body are redefined unless `=`/local. Label on `DO` line is defined once. |
| Local labels | `LOOP` (and loop boundary) clears locals; each iteration can reuse `!1`. `REPEAT` does not create a loop scope. |
| Macros | `DO`/`UNTIL`/`REPEAT` may appear inside macros; a macro call inside a loop body is expanded per iteration with a fresh local scope. |
| `ORG` / `BANK` | Allowed inside `DO`/`UNTIL` (`ENDCODE` bank wipe); PC/bank resets happen each iteration. |
| `SKIP` | A skip-table block that contains loop side effects (`=` updates, `DO`) must not be skipped on pass 2; PDS's “no forward references” test does not check side effects. Keep loops outside skippable data. **[I]** |
| Includes | `DO`/`LOOP`/`UNTIL` may not be used in include files. `REPEAT` is not explicitly banned. **[B]** |
| Nesting | `DO` loops cannot nest in 1.21. `REPEAT` of a line that contains a loop would be a nested loop in effect; avoid. **[B]** **[I]** |

`LOOP`/`UNTIL` outside a `DO` give `There was no DO` or `There was no DO <expr>`.
An unterminated `DO` at end of assembly gives
`You forgot to add a LOOP or UNTIL after the last DO`. **[B]**

---

## 7. `SKIP` — the pass-1 skip table

### 7.1 Semantics

```
SKIP 20
ORG $8000
...
```

* `SKIP n` enables the skip table with a **minimum block size** of `n` bytes.
  Typical values are 15–30. **[M]**
* On pass 1, for each block of source that contains **no forward references**
  and is at least `n` bytes long, PDS records the block in a table. On pass 2 it
  jumps over those source lines and simply advances the PC by the recorded
  size. Labels in the block were already defined on pass 1, so later code can
  still use them. **[M]**
* It emits no bytes and has no effect on the object code. It is purely an
  assembly-speed optimization. **[M]**
* At the end of assembly PDS prints the percentage of the skip table used. If
  it prints 100%, the table filled early and later blocks were missed; the
  manual considers 80–95% ideal. **[M]**
* If PDS prints `no skip`, skip was disabled — either an `ORG` overlapped a
  previously coded block, or a `BANK` command reset the assembler. **[M]**

### 7.2 Placement rules

* `SKIP` must appear **before any `ORG`**. The binary diagnostic is
  `Skip must be before any ORG's`; `09-transpiler-spec.md` §4.7's “skip source
  until the PC reaches n” is a misdescription. **[M]** **[B]** (Corrects
  `08-assembler-internals.md` §9.4 and `09-transpiler-spec.md` §4.7.)
* `SKIP` should appear only once: `SKIP <xxx> should only appear once`. **[B]**
* The expression must be greater than zero:
  `Skip must be followed by a number >0, about 20 is normal`. **[B]**
* It is a pass-1 directive. It has no pass-2 meaning except consuming the table
  built on pass 1. **[I]**

### 7.3 Interaction with `BANK` and overlapping `ORG`s

* `BANK` resets the assembler except the symbol table and disables skip. After a
  `BANK`, PDS prints `no skip`; the optimization is not active for the rest of
  the build. This is why the manual's `CORG` macro exists for banked code:
  `CORG` checks `IF *>@1` and reports an overlap itself, because `SKIP` no longer
  can. **[M]**
* Overlapping `ORG`s are not errors by themselves. PDS's only detection is the
  skip table: if an `ORG` lands inside a block already in the table, skip is
  disabled and `no skip` is displayed. The code still assembles, possibly
  overwriting earlier bytes. **[M]**
* The shipped source has **zero `SKIP` uses**. `CORG`/`JCC` are manual examples
  only, also unused. **[C]**

### 7.4 Transpiler treatment

`SKIP` can be a no-op for byte output, but validate it:

* reject after the first `ORG`;
* reject a second `SKIP`;
* reject `n <= 0`;
* if you implement diagnostics, warn that `BANK` disables it.

Do not model it as “assemble until PC reaches n”; that changes the program.
**[I]**

---

## 8. Taxonomy of the real macro libraries

The corpus has **107 macro definitions**:

| File | Definitions | Notes |
|---|---:|---|
| `MACROS.PDS` | **52** | The game's general macro library; 51 are normal, `cphlde` is preceded by a `0x01` editor block marker on its definition line (after stripping, it is a normal `cphlde MACRO`). |
| `MACROS.MUS` | **39** | Music/PPU macros, all inside `if musicon=1`. |
| `SOUNDFX.ROU` | **15** | Sound-effect data emitters (`PRIORITY`, `CHANNEL`, `FX_*`, …). |
| `JONSBIT.MUS` | **1** | `DJ` (`ORG *+(@1)`), inside the false `IF gav_master=0` block; effectively absent. |

The static maximum call depth is 2; 57 definitions are never expanded in the
shipped build. The tables below cover every macro in `MACROS.PDS` and
`MACROS.MUS` as requested. Arity is the **expected** number of positional
arguments inferred from the body/`IFS` checks; “1–2” means the macro itself
tests the second argument and accepts either form. `@` max is the highest `@n`
present in the body.

### 8.1 `MACROS.PDS` (52)

| Macro (line) | Arity | Purpose / generated code |
|---|---:|---|
| `zvar` (24) | 2 | Allocate zero-page variable `@1` of `@2` bytes: `@1 EQU zlim; zlim = zlim+@2`; error if `zlim > $FF`. No bytes. |
| `var` (34) | 2 | Same for the `$300` variable area: `@1 EQU varlim; varlim = varlim+@2`; error if `varlim > $743`. No bytes. |
| `defspr` (45) | 4–5 | Emit a sprite descriptor. For `@1 & 32` (2×2 sprite): `DB flags, X*±1, Y*±1, chrlo [, chrhi]`; otherwise `DB flags, X [, Y]`. `IFS [@5] []` / `IFS [@3] []` make the last byte optional. |
| `sprvar` (61) | 1 | `@1 EQU (*-spritetable)/2`: define a sprite-pointer index from the current table position. No bytes. |
| `chrvar` (65) | 1 | `@1 EQU (*-setsofchrstable)/5`: define a 5-byte character-set index. |
| `compchr` (69) | 1 | `@1 EQU (*-compactedchrstable)/4`: define a 4-byte compacted-character index. |
| `waitforsprcol` (73) | 0 | Wait for sprite collision: `BIT _statusreg` with `BVS !2` then `BVC !1`; two locals. |
| `waitforedge` (80) | 0 | Wait for the horizontal edge: `LDA _spritedata; CMP #255; BEQ !1`. |
| `waitforninesprs` (86) | 0 | Wait for nine sprites on a line: `LDX #8; LDA #$20; BIT _statusreg; BEQ !1; DEX; BNE !1`. |
| `flyback` (95) | 0 | Wait for vertical blank: `BIT _statusreg; BPL !1` (loop while bit 7 clear). |
| `blackscreen` (100) | 0 | Wait 60 vblanks: `LDY #60; BIT _statusreg; BPL !1; DEY; BNE !1`. |
| `orgfullpage` (108) | 0 | `ORG (!1/256)*256+256`: advance to the next page boundary; local `!1` is defined and used on the same line. |
| `flybackvar` (113) | 0 | `ASL flyflag; BIT flyflag; BPL !1`: a vblank wait gated by a variable flag. |
| `addto16` (119) | 2 | Add unsigned 8-bit `@2` to 16-bit memory `@1`: `LDA @1; CLC; ADC #@2; STA @1; BCC !1; INC @1+1`. No borrow path for negative values. |
| `deca` (128) | 0 | `SEC; SBC #1`: decrement A. |
| `inca` (133) | 0 | `CLC; ADC #1`: increment A. |
| `nega` (138) | 0 | Two's-complement negate A: `EOR #255; CLC; ADC #1`. |
| `blackandwhite` (144) | 0 | Save A/P, read `control1`, mask `#%00011110`, add 1, write `_control1`; monochrome mode. |
| `colour` (156) | 0 | Read `control1`, mask `#%00011110`, write `_control1`; colour mode. |
| `testcrash` (162) | 0 | `JSR turninteron` then loop `blackandwhite; colour; JMP !1`; a test/diagnostic loop. |
| `changebank` (169) | 1 | Compile-time bank dispatch: `12` → `JSR changebank12rou`; `13` → `JSR changebank13rou`; `14` → `LDA #14; STA bankno; STA bank.tbl+14`; other values emit nothing. |
| `incr` (183) | 1 | 16-bit increment memory `@1`: `INC @1; BNE !1; INC @1+1`; `IFS [@2][]` errors on an extra argument. |
| `decr` (194) | 1 | 16-bit decrement memory `@1`: `DEC @1; PHA; LDA #$FF; CMP @1; BNE !1; DEC @1+1; !1 PLA`; errors on extra arg. |
| `dca` (208) | 0 | `SEC; SBC #1`: decrement A (alias-like duplicate of `deca`). |
| `ica` (213) | 0 | `CLC; ADC #1`: increment A (duplicate of `inca`). |
| `add16to16` (218) | 3 | `@3 = @1 + @2` (16-bit memory operands). |
| `sub16from16` (232) | 3 | `@3 = @2 - @1` (16-bit memory operands). |
| `sub16fromval` (246) | 3 | `@3 = @2 - @1`, where `@2` is a 16-bit immediate value; error message mistakenly says `sub16from16`. |
| `add16to8` (260) | 3 | `@3 = @1(16-bit) + @2(8-bit)`; the comment's parameter order is misleading. |
| `sub8from16` (275) | 3 | `@3 = @2(16-bit) - @1(8-bit)`. |
| `add16toval` (289) | 3 | `@3 = @1 + @2` (16-bit value), with a compact carry path when `@1=@3` and `@2<256`; see §9.5. |
| `sldir` (325) | 3 | Small LDIR upward: copy `@3` bytes from `@1` to `@2` with `LDY #0; LDA @1,Y; STA @2,Y; INY; CPY #uuu; BNE !1`; `uuu=@3`, with `$100` mapped to 0 so `CPY #0` copies a full 256-byte page. |
| `sldirind` (352) | 3 | Small LDIR upward through pointers: `LDX @3; LDY #0; LDA (@1),Y; STA (@2),Y; INY; DEX; BNE !1`. |
| `slddr` (371) | 3 | Small LDIR downward with `LDX #uuu; LDA @1-UUU-1,X; STA @2-UUU-1,X; DEX; BNE !1`; `$100` is mapped to 0 so the X loop copies 256 bytes. The guard line `if uuu EQU$100` has no space before `$100`; the macro is uncalled, so this is not exercised. |
| `slddrind` (397) | 3 | Small LDIR downward through pointers: `LDY #@3-1; LDA (@1),Y; STA (@2),Y; DEY; BPL !1`. |
| `slddrdir` (417) | 3 | Small LDIR downward via `decr @1`/`decr @2` per byte (`decr` nested macro); X count. |
| `ldir` (437) | 3 | Big LDIR: load `ADDRESS/ADDRESS2/ADDRESS3` from `@1/@2/@3`, then call nested `ldirind address,address2,address3`. |
| `ldirind` (466) | 3 | Big LDIR indirect: copy the 16-bit count **stored at `@3`** bytes from `(@1)` to `(@2)`, incrementing both pointers and decrementing `@3` until zero. |
| `add` (492) | 1–2 | `CLC; ADC @1` or `CLC; ADC @1,@2`; a user macro because 6502 has no `ADD`. 211+ uses. |
| `sub` (504) | 1–2 | `SEC; SBC @1` or `SEC; SBC @1,@2`; a user macro because 6502 has no `SUB`. 2 uses. |
| `move.w` (516) | 2 | Copy 16-bit `@1` to `@2`: `LDA @1; STA @2; LDA @1+1; STA @2+1`. |
| `move.b` (527) | 2 | Copy 8-bit `@1` to `@2`: `LDA @1; STA @2`. |
| `move.val` (536) | 2 | Store 16-bit immediate `@1` into memory `@2`: low at `@2`, high at `@2+1`. |
| `cphlde` (543) | 2 | Compare 16-bit `@1` with `@2`; Z set if equal, carry set if `@1>=@2`. Definition line begins with a `0x01` block marker (stripped by the editor); unused. |
| `cpwordvalue` (553) | 2 | Compare 16-bit memory `@1` with 16-bit immediate `@2`; high byte first. |
| `cpxyvalue` (563) | 1 | Compare Y/X pair with 16-bit value `@1` (`CPY #<@1` = high, `CPX #>@1` = low); despite the comment, only one parameter. |
| `ldxy` (572) | 1 | `LDX #>@1` (low); `LDY #<@1` (high). |
| `stxy` (577) | 1 | Intended `STX #>@1` / `STY #<@1`, but 6502 has no immediate `STX`/`STY`; uncalled and defective. |
| `multword` (582) | 2 | Shift 16-bit `@1` left `floor(log2(@2))` times via `DO`/`UNTIL`; effectively multiplies by the largest power of two ≤ `@2`. |
| `tstatepause` (597) | 1 | Generate a cycle-exact delay for `@1` T-states using `IF`/`=` counters; huge macro with repeated NOP/BIT sequences. |
| `bgpz` (698) | 1 | `BCC @1` (“branch if gone past zero”). |
| `bngpz` (703) | 1 | `BCS @1` (“branch if not gone past zero”). |

### 8.2 `MACROS.MUS` (39)

All definitions are inside `if musicon=1` (`MACROS.MUS:1,360`), so they exist
only in a music-enabled build.

| Macro (line) | Arity | Purpose / generated code |
|---|---:|---|
| `NEXUS_RAM` (27) | 0 | `LDA #$8B; STA $C003` (mapper/RAM access). |
| `NEXUS_ROM` (32) | 0 | `LDA #$4B; STA $C003` (mapper/ROM access). |
| `DV` (37) | 1 | `DS @1`, then `IF *>$7F5` / `ERROR "OUT OF RAM...`: reserve space and guard the RAM top. |
| `SOAPY_BITS` (46) | 0 | `JSR TESTPDS`; a debug hook (`;NOP` lines commented out). |
| `DELAY` (53) | 1 | `LDX #@1; LDY #0; !1 DEY; BNE !1; DEX; BNE !1`: nested delay loop. |
| `ACCESS_ON` (62) | 0 | `LDA #$8B; STA $C003` (duplicate of `NEXUS_RAM`). |
| `ACCESS_OFF` (67) | 0 | `LDA #$4B; STA $C003` (duplicate of `NEXUS_ROM`). |
| `BWON` (72) | 0 | `LDA STATUS1; ORA #1; STA _STATUS1`: set monochrome. |
| `BWOFF` (78) | 0 | `LDA STATUS1; STA _STATUS1`: restore colour. |
| `VECT` (83) | 1 | `DB <@1,>@1`: intended low,high vector order, but under the verified default `<`=high this emits high,low. Unused. See §3.6. |
| `GFX` (90) | 3 | `LDA #0; JSR NEW_UNPACK; DW @1; DW @2; DB @3`: enqueue an unpack request. |
| `GFX_VBL` (102) | 3 | `INC DOWN_LOADING; LDA #128; JSR NEW_UNPACK; DW @1; DW @2; DB @3`: unpack during vblank. |
| `UNPACK` (115) | 3 | `JSR UNPACK_SCREEN; DW @1; DW @2; DB @3`. |
| `LOW` (125) | 1 | `LDA #<@1`: high byte under the verified default; the name expects low. Only dead code (`JONSBIT`, `WRITE`/`VRAM`) uses it. |
| `HIGH` (129) | 1 | `LDA #>@1`: low byte under the verified default; the name expects high. Only dead code (`JONSBIT`, `WRITE`/`VRAM`) uses it. |
| `LOWX` (133) | 1 | `LDX #<@1`: high under the default; name expects low. Unused. |
| `HIGHX` (137) | 1 | `LDX #>@1`: low under the default; name expects high. Unused. |
| `LOWY` (141) | 1 | `LDY #<@1`: high under the default; name expects low. Unused. |
| `HIGHY` (145) | 1 | `LDY #>@1`: low under the default; name expects high. Unused. |
| `VRAM` (149) | 1 | Set PPU address `$2006`: `HIGH @1` then `LOW @1`; intended high,low, but under the default this is low,high. Only dead `JONSBIT` calls. |
| `PIC` (156) | 1 | `INCBIN C:\gav\NIN4\GFX4\@1.OBJ`: include a picture file. |
| `UDG` (161) | 1 | `INCBIN …\@1.CHR`: include a character file. |
| `GRAPHIC` (166) | 1 | `INCBIN C:\gav\NIN2\GFX\@1.OBJ`. |
| `CHAR` (171) | 1 | `INCBIN C:\GAV\NIN2\GFX\@1.CHR`. |
| `GRAFIX` (176) | 1 | `INCBIN C:\GAV\NIN3\GFX\@1.OBJ`. |
| `CHARS` (180) | 1 | `INCBIN C:\GAV\NIN3\GFX\@1.CHR`. |
| `LOAD` (184) | 2 | Store `@2` into pointer `@1`: `LOW @2` then `HIGH @2`; intended low,high, but under the default this is high,low. Unused. |
| `FADE` (191) | 1 | `JSR SETFADE; LOW @1` to `$17E`; `HIGH @1` to `$17F`; intended low,high, inverted under the default. Unused. |
| `FADE2` (200) | 0 | `JSR SETFADE2`. |
| `WRITE` (206) | 4 | Write char `@4` at screen `@2,@3`; `IF @1` selects `$2400` vs `$2000`; top path ends in `EXITM`, bottom path falls through. Uncalled; its `HIGH`/`LOW` pair is inverted under the default order (§3.6). |
| `SETBANK` (227) | 1 | `IFS [@1] [X]` → `TXA/STA BANKBITS,X/EXITM`; `[A]` → `TAX/STA BANKBITS,X`; else `LDA #@1/STA BANKBITS+@1`. |
| `INN` (252) | 1 | 16-bit increment `@1`: `INC @1; BNE !1; INC @1+1`. |
| `G` (259) | 3 | `DW @1; DW @2; DB @3`: a 5-byte graphic descriptor. |
| `gav_ADD` (265) | 2 | `LDA @2; CLC; ADC @1; STA @2; BCC !1; INC @2+1`: add `@1` to 16-bit `@2`. |
| `gav_SUB` (275) | 2 | `LDA @2; SEC; SBC @1; STA @2; BCS !1; DEC @2+1`: subtract `@1` from 16-bit `@2`. |
| `MOVE` (285) | 2 | Same as `LOAD`: `LOW @2` then `HIGH @2` into pointer `@1`; intended low,high, inverted under the default. Unused. |
| `CLOCKS` (292) | 1 | Generate delay code for `@1` cycles: `CLN = @1 [2,350]`; `REPEAT` emits `PHA/PLA` pairs; `IF`/`BIT 0`/`NOP` fill the remainder. |
| `TICKS` (325) | 1 | `JSR TICKS@@1`: evaluate `@1` and call the `TICKS<n>` routine. The only `@@` use in the corpus. |
| `TIMEY` (330) | 1–2 | Generate music timing for `@1` (optional `@2`); `IFS [@2] []` distinguishes the forms; calls `TICKS`/`CLOCKS`. |

### 8.3 Library observations

* **Many macros are dead in the shipped build.** `defspr`, `addto16`,
  `waitforninesprs`, `waitforsprcol`, `sldir`, `ldir`, `multword`, `stxy`,
  `cpxyvalue`, `VECT`, `WRITE`, `SETBANK`, `TICKS`, `TIMEY`, etc. have zero
  call sites in the corpus. Do not assume a macro is exercised just because it
  is defined. **[C]**
* **`stxy` is not assemblable as written.** `STX #imm` / `STY #imm` do not
  exist on the 6502. It is uncalled, so the library still assembles. **[C]**
* **`cpxyvalue` takes one argument, not two.** The comment says “xy,value (16)”
  but the body only uses `@1` (`CPY #<@1; CPX #>@1`). The taxonomy arity is 1.
  **[C]**
* **`sub16fromval`'s error message says `sub16from16`** — a copy-paste bug in
  the macro, not an assembler issue. **[C]**
* **`multword` is log2, not repeated doubling.** See §6.2. **[C]**
* **`cphlde`'s definition line starts with a 0x01 editor block marker.** After
  stripping control bytes it is a normal definition. The macro is unused. **[C]**
* **`MACROS.MUS` macros are conditional on `musicon=1`**; `JONSBIT`'s `DJ` is
  inside a false `IF`. A macro table built without evaluating conditionals would
  wrongly expose them. **[C]**
* **The `MACROS.MUS` byte-order macros are inverted under the verified default**
  (`<`=high, `>`=low): `LOW` loads high, `HIGH` loads low, `VECT`/`VRAM`/
  `LOAD`/`MOVE`/`FADE` are high/low-swapped relative to their intent. All are
  dead in the live build (only the dead `JONSBIT` driver calls some). Either
  `OPTION 0,0` flips the order (unconfirmed) or this is legacy code for another
  assembler. See §3.6. Do not use them as byte-order evidence. **[C]** **[I]**

---

## 9. Fully annotated expansions

The examples below use real symbol values from `VARS.PDS` where possible.
`changebank 14` and `add16toval` are observed call sites; `defspr`'s arithmetic
is checked against the inline `defb` pattern at `SPRITESD.DAT:65`;
`waitforninesprs`/`addto16` have no call sites and their bytes are hand-assembled
from the macro body; `WRITE` is uncalled and its byte order is marked suspect in
§3.6. No PDS execution was used to produce these numbers.

| Symbol | Value | Source |
|---|---:|---|
| `cm_frames` | `$0000` | first `zvar`, `VARS.PDS:12` |
| `bankno` | `$000D` | `VARS.PDS:25` |
| `address` | `$001B` | `VARS.PDS:43` |
| `address+1` | `$001C` | — |
| `finishedloop` | `$0300` | first `var`, `VARS.PDS:27` |
| `robinxl` | `$0308` | `VARS.PDS:92` |
| `robinxh` | `$0309` | `VARS.PDS:93` |
| `scrxl` | `$003B` | `VARS.PDS:77` |
| `scrxh` | `$003C` | `VARS.PDS:78` |
| `_statusreg` | `$2002` | `VARS.PDS:223` |
| `bank.tbl` | `$C00A` | ledger, `BANK14.PDS` + mapper work |

The `zvar`/`var` values come from the allocator starting at `zlim=0` and
`varlim=$300`; the first few zero-page allocations are:

```
cm_frames=$00  control0=$01  control1=$02  interon=$03
seed=$04..$06  pad=$07  debounce=$08  y.scroll=$09  x.scroll=$0A
flyflag=$0B  vrampointer=$0C  bankno=$0D  spriteblockpointer=$0E
blockpointer=$0F  counter=$10 ...
```

and the first `var` allocations are `finishedloop=$300`, `chrfound=$301`,
`blockfound=$302`, `blockx=$303`, `blocky=$304`, `minmap=$305`, `maxmap=$306`,
`robindx=$307`, `robinxl=$308`, … **[C]**

### 9.1 `zvar` — allocate a zero-page variable

Call (observed, `VARS.PDS:12`):

```
zvar cm_frames ,1
```

Substituted body:

```
CM_FRAMES   EQU ZLIM
ZLIM        = ZLIM+1
IF ZLIM>&FF
    ERROR "Out of zero page work space with variable CM_FRAMES
ENDIF
```

Generated bytes: **none**. Symbol effects: `CM_FRAMES = $0000`, `ZLIM` becomes
`$0001`. The `IF` is false, so no error. `zvar seed,3` at `VARS.PDS:16` gives
`SEED=$0004`, `ZLIM=$0007`; `zvar bankno,1` gives `BANKNO=$000D`. **[C]**

Why `@1` must be raw: `@1` is in the column-1 label field. A text substitution
before lexing is the only way `@1 EQU` can work. `@2` is an expression fragment:
`zlim = zlim+@2` accepts `1`, `3`, `noofarrows`, `7*8*2`, etc. (`VARS.PDS`
contains all of these). The error message also uses `@1` inside a quoted string,
so substitution must not skip strings. **[C]**

The `var` twin is identical but uses `varlim` and limit `&743`; call
`var finishedloop ,1` gives `FINISHEDLOOP=$0300`, `VARLIM=$0301`. **[C]**

### 9.2 `defspr` — optional fifth byte and `IFS [@5] []`

Definition (`MACROS.PDS:45-59`):

```
defspr MACRO
    if (@1&32)
    db @1,(@2)*((@1&64~64)/32-1),(@3)*((@1&128~128)/64-1),@4
    ifs [@5] []
    else
    db @5
    endif
    else
    db @1,@2
    ifs [@3] []
    else
    db @3
    endif
    endif
endm
```

Call (synthetic, but equivalent to the inline data at `SPRITESD.DAT:65`):

```
cmdata1 EQU $1234
defspr %00100000,-3,8,>cmdata1,<cmdata1
```

Substitute; `@1 = %00100000` (32), `@2 = -3`, `@3 = 8`, `@4 = >cmdata1`
(low), `@5 = <cmdata1` (high):

```
if (32&32)                         ; true
db 32,(-3)*((32&64~64)/32-1),(8)*((32&128~128)/64-1),>cmdata1
ifs [<cmdata1] []                  ; false: @5 supplied
else
db <cmdata1                        ; executed
endif
else                               ; skipped
...
endif
```

Arithmetic:

* `32&64 = 0`; `0~64 = 64`; `64/32 = 2`; `2-1 = 1`; `-3*1 = -3` → `$FD`.
* `32&128 = 0`; `0~128 = 128`; `128/64 = 2`; `2-1 = 1`; `8*1 = 8` → `$08`.
* `>cmdata1` = low byte `$34`; `<cmdata1` = high byte `$12`.

Bytes: **`20 FD 08 34 12`**.

If the call omits the fifth argument:

```
defspr %00100000,-3,8,>cmdata1
```

then `@5` is empty, `IFS [] []` is **true**, and the `else db @5` is skipped.
Bytes: **`20 FD 08 34`**. This is exactly the optional-byte idiom.

If `@1 & 32` is clear (not a 2×2 sprite), the first branch is skipped:

```
defspr 0,5          -> db 0,5        ; IFS [@3] [] true, no third byte
defspr 0,5,6        -> db 0,5,6      ; third byte supplied
```

**[C]** for the definition/arithmetic; the call itself is synthetic, but the
resulting bytes match the inline `defb` pattern in `SPRITESD.DAT`.

The bit-6/bit-7 arithmetic is worth restating: for a 2×2 sprite, bit 6 set
makes the X displacement `-1` (flip horizontally), bit 7 set makes the Y
displacement `-1` (flip vertically). The macro is a compact sprite-descriptor
emitter.

### 9.3 `changebank` — compile-time `IF` dispatch

Definition (`MACROS.PDS:169-181`):

```
changebank MACRO
    if @1=12
    jsr changebank12rou
    endif
    if @1=13
    jsr changebank13rou
    endif
    if @1=14
    lda #@1
    sta bankno
    sta bank.tbl+@1
    endif
endm
```

Call (observed, `START.ROU:60`):

```
changebank 14
```

Expansion:

```
if 14=12
...
endif
if 14=13
...
endif
if 14=14
lda #14
sta bankno
sta bank.tbl+14
endif
```

Bytes:

```
A9 0E        LDA #$0E
85 0D        STA $0D          ; bankno
8D 18 C0     STA $C018        ; bank.tbl+14 ($C00A+14)
```

* `changebank 12` → `20 <changebank12rou>` (JSR absolute, 3 bytes).
* `changebank 13` → `20 <changebank13rou>`.
* `changebank 14` → 7 bytes as above.
* `changebank 15` (or any other value) → **no bytes**; all three `IF`s false.

This is a **compile-time** dispatch. `@1` is raw text substituted into the
`IF` expression; `changebank bankno` would compare the current value of the
symbol `bankno` at assembly time, not emit a runtime switch. Only constants
12/13/14 are meaningful. **[C]**

`bank.tbl` is `$C00A` and the table holds `00…0F`; the write at `+14` selects the
bank. The ledger's mapper work confirms the runtime effect. **[C]**

### 9.4 `waitforninesprs` — a no-argument macro with one local

Definition (`MACROS.PDS:86-93`):

```
waitforninesprs MACRO
    ldx #8
    lda #%00100000
!1  bit _statusreg
    beq !1
    dex
    bne !1
endm
```

Call (synthetic):

```
waitforninesprs
```

Expansion with `_statusreg = $2002`:

```
A2 08        LDX #8
A9 20        LDA #$20
2C 02 20     BIT $2002
F0 FB        BEQ !1        ; back to BIT
CA           DEX
D0 F8        BNE !1        ; back to BIT
```

* `BIT $2002` with `A=$20` tests PPU status bit 5 (sprite overflow); `BEQ`
  loops until it is set.
* The branch offsets: `BIT` at offset 4, `BEQ` at 7, next 9, target 4 →
  `4-9 = -5 = $FB`; `DEX` at 9, `BNE` at 10, next 12, target 4 →
  `4-12 = -8 = $F8`.
* `!1` is macro-local. A second call gets a different mangled label, so the
  two copies do not collide. **[C]**

### 9.5 `addto16` and `add16toval` — 16-bit arithmetic

#### `addto16` (simple 8-bit add)

Definition (`MACROS.PDS:119-126`):

```
addto16 MACRO
    lda @1
    clc
    adc #@2
    sta @1
    bcc !1
    inc @1+1
!1  endm
```

Call (synthetic):

```
addto16 address,5
```

with `address=$001B`:

```
A5 1B        LDA $1B
18           CLC
69 05        ADC #$05
85 1B        STA $1B
90 02        BCC !1        ; skip the high-byte increment
E6 1C        INC $1C
!1
```

Total 11 bytes. The branch is `+2` because `INC $1C` is 2 bytes. `@2` must be
an unsigned 0…255 value; negative values do not get a borrow path (the carry
only increments the high byte, never decrements it). **[C]**/[I] for the
negative caveat.

#### `add16toval` (16-bit value, with compact path)

Definition (`MACROS.PDS:289-318`):

```
add16toval MACRO
    if @1=@3
    lda @1
    clc
    adc #>@2
    sta @3
    if @2<256
    bcc !1
    inc @3+1
!1
    else
    lda @1+1
    adc #<@2
    sta @3+1
    endif
    else
    lda @1
    clc
    adc #>@2
    sta @3
    lda @1+1
    adc #<@2
    sta @3+1
    endif
endm
```

Remember PDS's byte order: `>` = low byte, `<` = high byte.

**Case A, observed** (`CONTROL.ROU:1125`):

```
add16toval robinxl,8,robinxl
```

`@1=@3`, so the first branch; `8<256` true, so carry path:

```
AD 08 03     LDA $0308
18           CLC
69 08        ADC #$08
8D 08 03     STA $0308
90 03        BCC !1        ; skip INC (3 bytes)
EE 09 03     INC $0309
!1
```

14 bytes. `BCC` is `+3` because `INC $0309` is 3 bytes.

**Case B, observed** (`CONTROL.ROU:1120`):

```
add16toval robinxl,-8,robinxl
```

`@1=@3`; `@2=-8` is `$FFF8` (manual: negative numbers are 32768…65535), so
`@2<256` is **false**. The `else` path adds the high byte too:

```
AD 08 03     LDA $0308
18           CLC
69 F8        ADC #$F8        ; >-8 = low byte F8
8D 08 03     STA $0308
AD 09 03     LDA $0309
69 FF        ADC #$FF        ; <-8 = high byte FF
8D 09 03     STA $0309
```

17 bytes. This is the correct 16-bit subtract-8, including the borrow.

**Case C, observed** (`MAPSCROL.ROU:520`):

```
add16toval robinxl,256+32,scrxl
```

`@1 != @3`, so the outer `else` path:

```
AD 08 03     LDA $0308
18           CLC
69 20        ADC #$20        ; low byte of 288
85 3B        STA $3B         ; scrxl (zero page)
AD 09 03     LDA $0309
69 01        ADC #$01        ; high byte of 288
85 3C        STA $3C         ; scrxh
```

15 bytes. Note `STA` becomes zero-page (`85`) for `scrxl=$3B`, but absolute
(`8D`) for `robinxl=$0308`; the assembler chooses the addressing mode per
substituted operand. **[C]**

### 9.6 `EXITM` in `SETBANK` and `WRITE`

#### `SETBANK`

Definition (`MACROS.MUS:227-248`) as in §5.4.

* `SETBANK X`:

```
8A           TXA
9D <lo> <hi> STA BANKBITS,X
             ; EXITM: second IFS/ELSE never reached
```

* `SETBANK A`:

```
AA           TAX
9D <lo> <hi> STA BANKBITS,X
```

* `SETBANK 0` (observed, `JONSBIT.MUS:115,356`):

```
A9 00        LDA #0
8D <lo> <hi> STA BANKBITS+0
```

The string dispatch is compile-time: `X` and `A` are strings, not register
names in an expression. `IFS [@1] [X]` compares the raw text after uppercasing.
**[C]**

#### `WRITE`

Definition (`MACROS.MUS:206-223`):

```
WRITE MACRO
    IF @1
    HIGH $2400+(@3*32)+@2
    STA $2006
    LOW $2400+(@3*32)+@2
    STA $2006
    LDA #@4
    STA $2007
    EXITM
    ENDIF

    HIGH $2000+(@3*32)+@2
    STA $2006
    LOW $2000+(@3*32)+@2
    STA $2006
    LDA #@4
    STA $2007
ENDM
```

The macro *intends* `HIGH` = high byte and `LOW` = low byte, the correct PPU
latch order. Under the verified default (`<`=high, `>`=low) the two loads are
swapped, so the bytes below are the **intended** expansion, not a bank-verified
one. `WRITE` has no call sites in the shipped build. **[I]**

* `WRITE 0,5,3,65`: `IF 0` false, so the top block is skipped; the bottom
  block writes `$2065`:
  `A9 20 8D 06 20 A9 65 8D 06 20 A9 41 8D 07 20` (15 bytes, intended order).
  Under the literal default order the first two loads swap
  (`A9 65 ... A9 20 ...`), which would be the wrong PPU latch order; this is
  why the macro is flagged suspect.
* `WRITE 1,5,3,65`: `IF 1` true; top block writes `$2465`:
  `A9 24 8D 06 20 A9 65 8D 06 20 A9 41 8D 07 20`, then `EXITM` leaves the
  macro before the bottom block. Without `EXITM`, both blocks would emit.

This is the cleanest illustration of `EXITM` as “an `ENDM` that also clears the
open `IF`”: the `ENDIF` after `EXITM` is not processed. **[M]** **[C]**

### 9.7 `TICKS` — `@@n` in an opcode

Definition (`MACROS.MUS:325-327`):

```
TICKS MACRO
    JSR TICKS@@1
ENDM
```

`TIMEY` calls `TICKS CLN` (`MACROS.MUS:351`). If `CLN=12` at expansion:

```
JSR TICKS12
```

bytes `20 <lo> <hi>` where the label `TICKS12` is defined elsewhere. If
`CLN=7`, `JSR TICKS7`. The `@@1` value is evaluated before insertion; this is
not the same as `JSR TICKS@1`, which would produce `JSR TICKS CLN` (invalid).
**[C]**

---

## 10. Macro-expansion algorithm for a transpiler

The following pseudocode is deliberately close to PDS's model, not to ca65.
It assumes a two-pass core and a stream of logical lines (editor control bytes
and `^Z` already stripped).

### 10.1 Data structures

```text
Macro:
    name          # upper-case
    named[]       # optional named parameters, upper-case
    body[]        # raw logical lines, unexpanded

Frame:            # one per macro call
    macro
    args[]        # raw text, 0..9
    named_values  # name -> integer
    if_base       # if_stack depth at entry
    scope_id      # local-label scope
    saved_scope   # caller's scope id

Context:
    macros{}      # name -> Macro, max 250
    symbols{}     # global symbols, value + defined_pass + source_index
    pc
    pass          # 1 or 2
    if_stack[]    # IfFrame {taken, else_seen, parent_skipping}
    macro_stack[] # names, for recursion detection
    scope_id      # current local-label scope
    scope_stack[] # saved scopes for nested macros
    expansion_id  # monotonic counter for diagnostics
```

### 10.2 Main line processor

```text
process_lines(lines, frame = None):
    i = 0
    while i < len(lines):
        line = lines[i]

        if skipping():
            if opcode_field(line) == "MACRO":
                i = skip_to_endm(lines, i)   # do not install; do not count inner IFs
            else:
                handle_skipped(line)         # only IF/ELSE/ENDIF bookkeeping
            i += 1
            continue

        label, op, operand = parse_fields(line)

        if op == "MACRO":
            define_macro(label, operand, lines, i)   # consumes to ENDM
            i = end_of_macro + 1
            continue

        if op in macros:
            expand_macro(macros[op], operand, line)
            i += 1
            continue

        if op in ("IF", "IFF", "IFS", "ELSE", "ENDIF"):
            handle_conditional(op, operand)
            i += 1
            continue

        if op == "DO":
            i = handle_do(lines, i, operand)
            continue

        if op == "REPEAT":
            i = handle_repeat(lines, i, operand)
            continue

        if op == "SKIP":
            handle_skip(operand)
            i += 1
            continue

        assemble_line(label, op, operand, line)
        i += 1
```

`expand_macro` must feed the expanded lines back through `process_lines`, not
just assemble them. That is how nested macro calls, inner `IF`s, inner loops and
`EXITM` work.

### 10.3 Definition capture

```text
define_macro(name, param_text, lines, i):
    if name in macros: error "second definition"
    if len(macros) >= 250: error "Only 250 macros may be defined"
    named = split_commas(param_text)       # upper-case, trim
    if len(named) > 9: error "Only 9 parameters allowed"

    body = []
    j = i + 1
    while j < len(lines):
        if opcode_field(lines[j]) == "ENDM":
            break
        body.append(lines[j])
        j += 1
    if j == len(lines): error "You forgot an ENDM after the last macro"

    macros[name] = Macro(name, named, body)
    return j
```

`opcode_field` must ignore a preceding label: `!1<TAB>ENDM` is still the
terminator. It must also ignore `ENDM` text in comments/strings.

Nested definitions: if a body line's opcode is `MACRO`, error
`Macros cannot be nested` (or the 1.26 wording). Do not recurse.

### 10.4 Argument parsing

```text
split_args(text):
    args = []
    cur = ""
    depth = 0
    for ch in text:
        if ch == '[':
            depth += 1
            if depth > 1: cur += ch   # keep nested bracket text
        elif ch == ']':
            if depth == 0: error "Missing ]"
            depth -= 1
            if depth > 0: cur += ch
        elif ch == ',' and depth == 0:
            args.append(trim(cur)); cur = ""
        else:
            cur += ch
    if depth != 0: error "Missing ]"
    args.append(trim(cur))

    if len(args) > 9: error "Only 9 parameters allowed"
    return args
```

The outer `[]` pair is dropped because `depth` never appends the first `[` and
the matching `]` is not appended at depth 0. If you prefer a simpler version:
split on top-level commas, then strip one outer `[` … `]` pair from each
argument. Both produce the manual's `@2 = 45,56,67`.

Do **not** use `split_args` for an `IFS` line. `IFS` has its own bracket parser:

```text
parse_ifs(text):
    groups = []
    while text:
        skip spaces
        expect '['; read until matching ']'; groups.append(content)
    if len(groups) < 2: error "Syntax : IFS ..."
    return groups
```

### 10.5 Substitution

```text
substitute(line, args, named_values, caller_symbols):
    out = ""
    k = 0
    while k < len(line):
        if line[k] == '@' and k+2 < len(line) and line[k+1] == '@'
           and is_digit(line[k+2]):
            n, k2 = parse_digits(line, k+2)  # consume all digits
            if n < 1 or n > 9: error "Macro parameters may only be @1 to @9"
            raw = arg_or_empty(args, n)
            if raw == "": error "cannot evaluate empty @@n"
            val = eval_expr(raw, caller_symbols, pc)
            if unknown(val): error "forward reference in @@n"
            out += format_number(val)       # decimal by default
            k = k2
        elif line[k] == '@' and k+1 < len(line) and is_digit(line[k+1]):
            n, k2 = parse_digits(line, k+1)
            if n < 1 or n > 9: error "Macro parameters may only be @1 to @9"
            out += arg_or_empty(args, n)    # raw text, empty if missing
            k = k2
        else:
            out += line[k]
            k += 1
    return out
```

Important: this is a **single pass** over the original body line. Do not rescan
the inserted text. Scan `@@` before `@`. `@0`/`@10` are not parameters; leave
them alone or error as PDS does.

`format_number`: decimal under default `RADIX 10`; if you honour `RADIX`, use the
current radix for the number token. The manual's only example is decimal
(`VAR6`), and the corpus never changes `RADIX`.

Named parameters:

```text
bind_named(macro, args, caller_symbols):
    for i, name in enumerate(macro.named):
        raw = arg_or_empty(args, i+1)
        if raw == "":
            value = 0 or error            # PDS would evaluate empty -> error
        else:
            value = eval_expr(raw, caller_symbols, pc)
        named_values[name] = value
        # Optional: queue a hidden "NAME = value" line for listing parity.
```

Treat `named_values` as macro-local. Do not add them to the global symbol table
unless you have confirmed the original leaks them (it is undocumented).

### 10.6 Local-label mangling

```text
mangle_local(name, scope_id):
    return "__PDS_L" + scope_id + "_" + upper(name)

new_scope():
    scope_id += 1
    return scope_id

on_global_label():
    # A non-! label clears all locals in the current scope.
    scope_id += 1

expand_macro(...):
    saved = scope_id
    frame.scope_id = new_scope()
    push macro_stack; push scope
    ...
    if exiting: if_stack.truncate(frame.if_base)
    scope_id = saved
    pop macro_stack
```

* `!name` in a definition or reference maps through `mangle_local`.
* On a global label inside an expansion, call `on_global_label()`, so a later
  `!name` gets a different suffix.
* At each `LOOP`/`UNTIL` iteration end, call `on_global_label()` (or a dedicated
  `new_scope()`); this is PDS's local-clear point.
* `REPEAT` does **not** call `new_scope()` between repetitions of the same line;
  if the repeated line defines a non-local or local label, it will collide,
  matching PDS's multiple-definition behavior. (If you decide to be more
  forgiving, document the deviation.)
* Reset the scope counter at the start of each pass and process identically.
  Do not use a symbol-table insertion-order counter that depends on pass-2
  cache hits.

### 10.7 Macro expansion with recursion guard

```text
expand_macro(macro, arg_text, call_line):
    if macro.name in macro_stack:
        error "Recursion with macros not allowed"
    if len(macro_stack) >= MAX_FRAMES:   # 4 total / 3 nested, see §2.4
        error "Macros can only be nested to a depth of 3"

    args = split_args(arg_text)
    frame = Frame(macro, args, if_base=len(if_stack),
                  saved_scope=scope_id, scope_id=new_scope())
    bind_named(macro, args, caller_symbols)

    macro_stack.push(macro.name)
    try:
        for body_line in macro.body:
            expanded = substitute(body_line, args, frame.named_values,
                                  caller_symbols)
            process_line(expanded, frame)
    except ExitMacro:
        pass
    finally:
        if len(if_stack) > frame.if_base:
            # A normal ENDM with an open IF is an error; EXITM already cleared.
            if not exited_by_exitm:
                error "No ENDIF after last IF"
            if_stack.truncate(frame.if_base)
        scope_id = frame.saved_scope
        macro_stack.pop()
```

`EXITM` handler:

```text
on_EXITM():
    if not inside_macro: error "EXITM can only be used inside a MACRO..."
    if not if_active:    error "EXITM can only be used inside a MACRO, in an IF statement"
    raise ExitMacro
```

`ENDM` is not processed as a body line; it is the terminator consumed by the
definition reader. If an `ENDM` appears while not defining, error
`I'm not doing a macro`.

### 10.8 Conditional handling

```text
handle_conditional(op, operand):
    if skipping():
        if op in ("IF", "IFF", "IFS"): skip_depth += 1
        elif op == "ENDIF":
            skip_depth -= 1
            if skip_depth == 0: skipping = false
        elif op == "ELSE" and skip_depth == 1:
            # toggle the current frame; no expression evaluation
            ...
        return

    if op == "IF":
        val = eval_expr(operand)
        if unknown(val): error "This expresion must not contain forward references"
        push_if(taken = (val != 0))
    elif op == "IFF":
        push_if(taken = has_forward_ref(operand))
    elif op == "IFS":
        groups = parse_ifs(operand)
        push_if(taken = any(equal_fold(groups[0], g) for g in groups[1:]))
    elif op == "ELSE":
        if current.else_seen: error "Cannot have more than one ELSE"
        current.else_seen = true
        current.taken = not current.taken
    elif op == "ENDIF":
        pop_if()
```

`push_if`/`pop_if` also set `skipping` when the new frame is false and no outer
frame is already skipping. `ELSE`/`ENDIF` with a label in column 1 should be
rejected before this point (`ELSE and ENDIF must not have labels`).

For `IFF`, `has_forward_ref` is a **syntactic/symbol-table** test:

```text
has_forward_ref(expr):
    for sym in symbols_referenced(expr):
        if sym not in symbols or symbols[sym].defined_pass == 0:
            return true
    return false
```

On pass 2, use the pass-1 `defined_pass`/`forward` flag, not the now-complete
symbol table, or the branch will change. If you precompute source order, a
symbol defined later in the file is a forward reference.

### 10.9 Loop unrolling

```text
handle_do(lines, i, operand):
    if inside_loop: error "DO, LOOP and UNTIL cannot be nested"
    body, terminator, end = scan_to_loop_or_until(lines, i+1)
    # scan_to_loop_or_until must reject a nested DO and a missing terminator
    # ("You forgot to add a LOOP or UNTIL after the last DO").

    if operand == "":
        # DO ... UNTIL
        while true:
            for line in body: process_line(line, frame)
            if ++iterations > MAX_ITER: error "DO/UNTIL did not terminate"
            val = eval_expr(terminator.operand)
            if val == 1: break               # binary-exact; or val != 0 per manual
            on_loop_iteration_end()          # local scope clear before next copy
    else:
        count = eval_expr(operand)
        if unknown(count): error
        if count <= 0: error "This parameter must not be zero or minus"
        for k in range(count):
            for line in body: process_line(line, frame)
            on_loop_iteration_end()
    return end + 1
```

Notes:

* The label on the `DO` line is assembled by the normal line processor before
  `handle_do`; do not re-define it per iteration.
* `BANK`/`ORG` inside the body are processed normally each iteration; do not
  reset the loop frame on `BANK`.
* If `body` is empty and the `UNTIL` condition is false, error immediately
  (otherwise infinite loop with no progress).
* `MAX_ITER` is your safety net; PDS has none.

`REPEAT`:

```text
handle_repeat(lines, i, operand):
    n = eval_expr(operand)
    if unknown(n) or n < 0: error
    next_line = lines[i+1]
    for k in range(n):
        process_line(next_line, frame)   # same local scope each time
    return i + 2
```

If `n == 0`, the next line is consumed but not assembled. If `next_line` is a
macro call, each call creates its own scope; if it is a plain line with a label,
the second repetition is a multiple-definition error, as in PDS.

### 10.10 `SKIP` handling

```text
handle_skip(operand):
    if pass != 1: return                  # no pass-2 effect
    if skip_seen: error "SKIP ... should only appear once"
    if org_seen:  error "Skip must be before any ORG's"
    n = eval_expr(operand)
    if n <= 0: error "Skip must be followed by a number >0..."
    skip_threshold = n
    skip_seen = true
    # optional: build a skip table for diagnostics; never change bytes
```

For byte output, `SKIP` is a no-op. For a faithful listing/diagnostic, you can
print `skip=<percent>` or `no skip` when `BANK` is used or an `ORG` overlaps a
recorded block, but this does not affect the object.

### 10.11 Pass model

```text
for pass in (1, 2):
    reset_pc()
    reset_scope_ids()
    reset_if_stack()
    reset_macro_stack()
    reset_expansion_counters()
    # Macro definitions: re-read source identically, or reuse the pass-1 table.
    process_lines(source_lines)
    if pass == 1: freeze_symbols()
    else: compare_pc_and_symbols()        # phase errors
```

PDS defines macros and labels on pass 1 and re-expands on pass 2. The safest
transpiler is to process the same source text with the same decisions both
times, using the pass-1 symbol table for `IFF` and for `IF` stability checks.
Any pass-dependent `@@n`/`IF`/`IFF` decision must be reported as a phase error
rather than silently producing different bytes.

### 10.12 Implementation checklist

- [ ] Parse label at column 1; opcode/operand after whitespace.
- [ ] Define macros only when the definition line is in an assembled branch.
- [ ] Store body raw; do not substitute at definition time.
- [ ] Split call arguments on top-level commas; strip one outer `[]` pair.
- [ ] Missing `@n` -> empty text; extra args -> allowed up to 9.
- [ ] Substitute `@@n` before `@n`; one pass; no rescan.
- [ ] Push/pop local scopes on macro entry/exit, global labels and loop ends.
- [ ] Reject recursion and >4 frames (or >3 nested, per §2.4).
- [ ] Enforce 250 macros, 9 params, 10 IFs, one ELSE, no nested DO.
- [ ] `EXITM` only in macro + active IF; truncate that macro's IF frames.
- [ ] `IFS` any-match per manual; empty `[]` compares equal to empty.
- [ ] `IFF` uses pass-1 forwardness, not pass-2 values.
- [ ] `DO` count > 0; `UNTIL` re-evaluates each iteration; safety cap.
- [ ] `REPEAT` duplicates one line, not a block.
- [ ] `SKIP` no-op for bytes; validate placement only.
- [ ] Reset scope/expansion counters per pass for deterministic mangling.

---

## 11. Test vectors

Each vector gives the exact source, the expansion (or symbol effect) and the
expected bytes. PC values are chosen to make branches concrete. `>` = low byte,
`<` = high byte.

### 11.1 `SUM` — raw `@1`/`@2`/`@3`

```asm
SUM MACRO
    LDA @1
    @2  #@3
    STA @1
ENDM

FRED EQU $0308
    SUM FRED,ADC,3
```

Expansion:

```asm
    LDA FRED
    ADC #3
    STA FRED
```

Bytes: `AD 08 03 69 03 8D 08 03` (8 bytes).

### 11.2 `SHOW` — bracket grouping

```asm
SHOW MACRO
    DB @1
    DB @2
    DB @3
ENDM

    SHOW 23,[45,56,67],98
```

Arguments: `@1=23`, `@2=45,56,67`, `@3=98`.
Expansion:

```asm
    DB 23
    DB 45,56,67
    DB 98
```

Bytes: `17 2D 38 43 62` (5 bytes).

### 11.3 `VAR@@1` — evaluated parameter

```asm
FRED MACRO
VAR@@1 EQU *
ENDM

FRED 3*2
```

Expansion:

```asm
VAR6 EQU *
```

Bytes: none. Symbol: `VAR6 = current PC`.

### 11.4 Optional parameter with `IFS [@1] []`

```asm
FRED MACRO
    IFS [@1] []
        EXITM
    ENDIF
    ADC @1
ENDM

    FRED            ; no argument
    FRED 23         ; one argument
```

Expansions:

```asm
; FRED        -> (nothing)
; FRED 23     -> ADC 23
```

Bytes: first call none; second `65 17` (`ADC $17`, zero page). Note the manual
example uses `ADC @1` without `#`; if you want immediate, pass `#23` and the
byte is `69 17`. [M]

### 11.5 Local labels are per-expansion

```asm
BILL MACRO
!1  NOP
    JMP !1
ENDM

    ORG $8000
    BILL
    BILL
```

Expansions (conceptually, before mangling):

```asm
; call 1
!1  NOP
    JMP !1
; call 2
!1  NOP
    JMP !1
```

Mangled:

```asm
; call 1
__PDS_L1_1: NOP
            JMP __PDS_L1_1
; call 2
__PDS_L2_1: NOP
            JMP __PDS_L2_1
```

Bytes at `$8000`: `EA 4C 00 80` then at `$8004`: `EA 4C 04 80`.

### 11.6 `defspr` — optional fifth byte

```asm
cmdata1 EQU $1234
    defspr %00100000,-3,8,>cmdata1,<cmdata1   ; 5 args
    defspr %00100000,-3,8,>cmdata1            ; 4 args
    defspr 0,5                                ; 2 args, non-2x2
    defspr 0,5,6                              ; 3 args, non-2x2
```

Bytes:

```
20 FD 08 34 12      ; 5 args
20 FD 08 34         ; 4 args (IFS [@5] [] true)
00 05               ; 2 args (IFS [@3] [] true)
00 05 06            ; 3 args
```

### 11.7 `changebank` — compile-time dispatch

```asm
    changebank 12
    changebank 13
    changebank 14
    changebank 15
```

Bytes (addresses of the `changebank12rou`/`13rou` routines are link-dependent):

```
20 <lo12> <hi12>          ; JSR changebank12rou
20 <lo13> <hi13>          ; JSR changebank13rou
A9 0E 85 0D 8D 18 C0      ; LDA #14; STA bankno; STA bank.tbl+14
                           ; changebank 15 -> nothing
```

### 11.8 `waitforninesprs`

```asm
    waitforninesprs
    waitforninesprs
```

First expansion: `A2 08 A9 20 2C 02 20 F0 FB CA D0 F8`.
Second expansion has different local labels but the same bytes; the branch
targets are relative, so the encodings are identical:
`A2 08 A9 20 2C 02 20 F0 FB CA D0 F8`.

### 11.9 `addto16`

```asm
address EQU $1B
    addto16 address,5
```

Bytes: `A5 1B 18 69 05 85 1B 90 02 E6 1C` (11 bytes).

### 11.10 `add16toval`

```asm
robinxl EQU $0308
robinxh EQU $0309
scrxl   EQU $3B
scrxh   EQU $3C

    add16toval robinxl,8,robinxl
    add16toval robinxl,-8,robinxl
    add16toval robinxl,256+32,scrxl
```

Bytes:

```
AD 08 03 18 69 08 8D 08 03 90 03 EE 09 03          ; 14 bytes
AD 08 03 18 69 F8 8D 08 03 AD 09 03 69 FF 8D 09 03 ; 17 bytes
AD 08 03 18 69 20 85 3B AD 09 03 69 01 85 3C       ; 15 bytes
```

### 11.11 `DO`/`LOOP`

```asm
xx = 0
    DO 3
    DB xx
xx = xx+1
    LOOP
```

Bytes: `00 01 02`. The `=` counter is redefinable; a normal label would be a
multiple definition on the second iteration.

### 11.12 `DO`/`UNTIL`

```asm
xx = 0
    DO
    DB xx
xx = xx+1
    UNTIL xx=3
```

Bytes: `00 01 02`. The condition is evaluated after each body copy; at `xx=3`
it returns 1 and the loop exits (both the manual's non-zero rule and the
binary's exactly-1 rule agree here).

### 11.13 `REPEAT`

```asm
    REPEAT 4
    LSR A
```

Bytes: `4A 4A 4A 4A`.

### 11.14 `IF`/`ELSE`/`ENDIF`

```asm
    IF 0
    DB 1
    ELSE
    DB 2
    ENDIF
```

Bytes: `02`. `IF 1` would emit `01`.

### 11.15 `IFS` — empty and multiple groups

```asm
    IFS [FRED] [FRED]          ; true
    DB 1
    ENDIF

    IFS [FRED] [BILL]          ; false
    DB 2
    ENDIF

    IFS [] []                  ; true: empty equals empty
    DB 3
    ENDIF

    IFS [FRED] [BILL] [JOHN] [TONY] [FRED]   ; true (OR; confirmed at 0e60:3482)
    DB 4
    ENDIF
```

Expected: `01` and `03` and `04` (if OR semantics); `02` is skipped. With the
conflicting AND semantics, the last block would be skipped. This is the
disputed case; all shipped uses have exactly two groups.

### 11.16 `IFF` — forward vs backward

```asm
BACK EQU 1
    IFF BACK          ; false: BACK is already defined
    DB 1
    ELSE
    DB 2
    ENDIF

    IFF FORWARD       ; true: FORWARD is defined later
    DB 3
    ELSE
    DB 4
    ENDIF
FORWARD EQU 1
```

Bytes: `02 03`. On pass 2, the decisions must be the same as pass 1; use the
pass-1 forward flag.

---

## 12. Open questions and confidence

| Item | Status | Note |
|---|---|---|
| `JENDM` | **Resolved** | Not a keyword; OCR misread of `ENDM`/`.ENDM`. |
| Body column rule | **Resolved** | Definition name column 1; body ordinary source. |
| `IFS` >2 groups | **Confirmed OR** | `0e60:3482` returns true on any later-group match; corpus only uses 2 groups. |
| `UNTIL` exit value | **Open/conflict** | Manual non-zero; 1.21 reportedly exactly 1; corpus 0/1 only. |
| `DO` nesting | **Resolved** | Cannot nest in 1.21. |
| `DO` zero/negative | **Resolved** | Error in 1.21; manual silent. |
| `REPEAT` zero | **Open** | Binary says negative/forward error; zero untested. |
| `@@n` formatting | **Mostly resolved** | Decimal under default RADIX; current-radix formatting per 08 is unverified. |
| `@@n` with negative/forward | **Open** | Avoid; not documented/exercised. |
| Named-param leakage | **Open** | Manual shows `NAME = value`; whether it survives `ENDM` is undocumented. |
| `IFS` exact whitespace trimming | **Open** | `[]` used for empty; spaces inside brackets untested. |
| Macro definitions in skipped blocks | **Mostly resolved** | Not installed; consume body to `ENDM` to keep nesting sane. |
| `REPEAT` local-label scope | **Inferred** | No loop scope; repeated `!1` likely collides. |
| `OPTION 0,0` meaning | **Open** | Documented options are `1,0`/`1,1` (logic precedence); `0,0` is undocumented and usually treated as a no-op. It does **not** rescue the inverted `MACROS.MUS` byte macros unless proven. See §3.6. |
| `MACROS.MUS` LOW/HIGH | **Open/defect** | All byte-order macros are inverted under the verified default and all are dead in the live build. Legacy or `OPTION`-dependent; do not rely. |
| `ORG`/`BANK` local-label clearing | **Open** | No corpus case; treat as not clearing. |
| `SKIP` + side effects | **Inferred** | PDS checks forward refs, not `=`/DO side effects; keep loops out. |
| `@` in comments/strings | **Partially resolved** | Strings substitute (`ERROR`, `INCBIN`); comments are stripped. |
| `stxy`/`slddr` defects | **Resolved** | `STX/STY #imm` invalid; `EQU$100` typo; both uncalled. |

The items marked **Resolved** are safe to encode in a transpiler. The
**Open/conflict** items do not affect the shipped corpus because the source
never exercises the disputed forms, but they matter for a general PDS clone.

---

## 13. Source index

Manual (OCR markdown; page images checked):

* `docs/PDS_6502_Manual.md:203-232` — `DO`/`LOOP`/`UNTIL`.
* `:323-365` — `IF`/`ELSE`/`ENDIF`/`IFF`/`IFS`.
* `:383-458` — `MACRO`/`ENDM`/`EXITM`/parameters/limits/local labels.
* `:510-520` — `REPEAT`.
* `:552-558` — `SKIP`.
* `:737-800` — example macros `JCC`, `ZVAR`, `CORG`.

Corpus:

* `pds_src/src/MACROS.PDS:24-705` — the 52 general macros.
* `pds_src/src/MACROS.MUS:27-358` — the 39 music/PPU macros.
* `pds_src/src/VARS.PDS:12-155` — `zvar`/`var` calls; first allocations and
  `bankno=$0D`, `robinxl=$0308`.
* `pds_src/src/START.ROU:56-72` — `do 30` and `changebank 14/12`.
* `pds_src/src/TIMINGS.ROU:5-36` — counted `DO` table generation.
* `pds_src/src/MAPSCROL.ROU:97-106,505-508` — counted `DO`; `add16toval`.
* `pds_src/src/CONTROL.ROU:911-914,1120-1125` — `DO` and `add16toval`.
* `pds_src/src/ENDCODE.ROU:27-39` — `IF`/`ELSE`/`ENDIF` and `DO`/`UNTIL` bank
  wipe.
* `pds_src/src/JONSBIT.MUS:149` — a label named `LOOP`; `:53-55` — `DJ`.
* `pds_src/src/SOUNDFX.ROU:133-192` — the 15 sound-effect macros.
* `pds_src/src/SPRITESD.DAT:4-49` — `sprvar` calls and the inline sprite
  descriptor format that `defspr` mirrors.
* `pds_src/src/MACROS.MUS:25` — `OPTION 0,0` (undocumented/no-op in the
  ledger's model); `pds_src/src/JONSBIT.MUS:49` — the same;
  `MUSIC1.MUS:1464` — `OPTION 0,1`. See §3.6 for the byte-order caveat.

Binary evidence:

* `version121_pds6502.exe` (assembler banner `6502 : v3.2`) diagnostic strings
  quoted throughout, especially:
  * `A macro must start at the very begining of a line.`
  * `Macros cannot be nested`, `Macros can only be nested to a depth of 3`,
    `Recursion with macros not allowed`, `Only 250 macros may be defined`,
    `Only 9 parameters allowed`, `Macro parameters may only be @1 to @9`.
  * `Cannot have more than 10 nested IF's`, `Cannot have more than one ELSE`,
    `ELSE and ENDIF must not have labels`, `No ENDIF after last IF`,
    `ENDIF was expected`, `This expresion must not contain forward references`.
  * `DO, LOOP and UNTIL cannot be nested`,
    `DO, LOOP and UNTIL may not be used in include files`,
    `This parameter must not be zero or minus`, `There was no DO`,
    `The LOOP or UNTIL must be in the same section of code as the DO`,
    `You forgot to add a LOOP or UNTIL after the last DO`.
  * `Skip must be before any ORG's`, `Skip must be followed by a number >0,
    about 20 is normal`, `SKIP <xxx> should only appear once`.
  * `A single local label character is not a valid label`,
    `You are trying to reference a macro name`,
    `Out of symbol/macro table space`.

Cross-references in this documentation set:

* `docs/re/pds/01-language-and-lexer.md` — line grammar, control bytes, local
  labels.
* `docs/re/pds/03-directives.md` — directive reference; corrects `JENDM`,
  `DO` nesting and `SKIP` wording in this volume's §0.
* `docs/re/pds/08-assembler-internals.md` — IF state machine, macro frame,
  `UNTIL` exact-1 behavior, symbol/local scope id.
* `docs/re/pds/09-transpiler-spec.md` — stage-by-stage transpiler; this volume
  supplies the detailed macro/conditional semantics and flags the `IFS`,
  `SKIP`, bracket and `JENDM` discrepancies.

---

*End of volume 04.*
