# PDS 6502 — Language and Lexer Reference

Volume 1 of the PDS reverse-engineering set. This document describes the **lexical
and line-level grammar** of the PDS 6502 assembler (Proteus Development System,
1.2x) as used to build *Super Robin Hood*: how a source file is split into lines,
how lines are split into fields, how labels/symbols/numbers/comments are spelled,
and what a transpiler must do to reproduce the assembler's reading of the text.

It does **not** cover instruction encoding, addressing-mode selection, expression
*evaluation* arithmetic, or the download/object format. See the sibling volumes.

---

## 0. Sources, method, and how to read the tags

Every claim below is tagged:

| Tag | Meaning |
|-----|---------|
| **[D]** | Documented in the PDS manual (quoted/cited). |
| **[O]** | Observed in the shipped source corpus (`pds_src/src/`). Counts are from the corpus. |
| **[I]** | Inferred — consistent with all evidence, but not directly provable from the material available. |
| **[U]** | Unverified — written in the source, but not provably accepted by the assembler (e.g. dead macro text). |

Primary sources:

* `docs/PDS_6502_Manual.md` — cleaned OCR of *The PDS 6502 Manual*; cited as `M:NNN`.
* `PDS_Manual_6502.txt` — raw OCR of the same manual; cited where OCR reveals
  wording the cleanup lost (e.g. the valid-character list, `PDS:79-111`).
* `docs/manuals/P.D.S._Manual.pdf` — an **earlier, Z80-flavoured** edition of the
  manual (has a text layer). Used only for version-difference notes.
* `docs/manuals/PDS_executables.zip` → `help.65` — PDS's built-in instruction
  help; used for the accumulator operand form.
* `pds_src/src/*.ROU|*.PDS|*.MUS|*.DAT` — 34 text source files, 19,394 lines,
  plus one binary `DATA.MUS`. Build order is in `pds_src/src/ROBIN.PRJ`.

**Notation.** In the annotated listings, `→` is a TAB, `␠` is a space, and `¶`
marks end of line. Everything else is literal. Tabs matter enormously in this
language, so they are always made visible.

---

## 1. Physical layer: bytes, lines, EOF

### 1.1 What a "source file" is

PDS keeps source in RAM as an array of logical files (the assembler walks file 0
through file 7, `M:26`). On disk a file is a byte stream terminated by `^Z`
(0x1A). There is no header, no length field, no encoding declaration.

`[O]` All 34 text files end with 0x1A; nothing follows it except, in two files,
a single LF. `[O]` `DATA.MUS` has 0x1A at offset 135 and 4,216 bytes of raw binary
after it — **the extension does not guarantee text**. `[O]` `MAPDATA.DAT` and
`SPRITESD.DAT` are perfectly ordinary assembler source (mostly `HEX`).

### 1.2 Line terminators

| Form | Count in corpus | Notes |
|------|-----------------|-------|
| LF only (`\n`) | 32 files | post-extraction normalisation |
| CRLF (`\r\n`) | 2 files (`BANK8.PDS`, `BANK13.PDS`) | DOS-era copies |
| lone CR (`\r`) | 0 files | PDS's native separator; not preserved here |

`[I]` The PC-side editor stores lines separated by **CR (0x0D)** (project-level
knowledge; not re-derivable from this corpus, whose CRs were normalised away);
files that passed through DOS carry CRLF. The corpus here has been normalised to LF except
for the two CRLF files, so the original CR-only form is not directly observable.
A reader must therefore accept `CR`, `LF`, and `CRLF`, and must not treat a bare
CR as data. `[O]` There are no lone CRs anywhere in the corpus, so no line-splitting
ambiguity is exercised by the shipped sources.

`[O]` Line length: the longest line is 146 chars (`MAINLOOP.ROU:23`, a comment).
The only documented limit is indirect — `[D]` "You can fit up to 57 HEX bytes on
one 120-character line" (`M:319`). Treat 120 as a *display/listing* width, not a
hard lexer limit. `[I]` The assembler does not truncate at 120: the 1,347 active
`HEX` lines include 32-byte payloads, and the 146-char comment line is intact.

### 1.3 `^Z` (0x1A) is EOF

`[O]` Every text file ends `... 0x1A`; `[I]` the assembler stops reading a file at
the first 0x1A (PDS files are not NUL-terminated, and no NUL occurs in any text
file). A transpiler should truncate each file at the first 0x1A and then treat the
remainder as lines.

### 1.4 Stray control bytes 0x01 / 0x02 — a real, corpus-wide anomaly

`[O]` **56 bytes** with value 0x01 or 0x02 occur in **30 of the 34** text files.
`[I]` They look like editor **block markers** (0x01 = mark-block, 0x02 =
end-block) that were saved into the text by accident. They appear in every
syntactic position:

| Position | Count | Examples (`→`=TAB, `¶`=EOL) |
|----------|-------|---------------------------|
| at column 1 (alone, before a label, or before a TAB/comment) | 47 | `BANK12.PDS:17` = `\x02¶`; `PRTROBIN.ROU:1` = `\x01flashrobin→defb 4,2,…`; `TITLE.ROU:6` = `\x01;→lda #10`; `BANK13.PDS:1` = `\x01¶` |
| immediately after a column-1 label | 3 | `SPRITESD.DAT:351` = `pauses\x01→defb 5,…`; `XTRAROUS.ROU:862` = `redefinewaterbank\x02¶`; `REDEFCHR.ROU:36` = `\x01copyblockofchrs\x02␠;a=…` |
| after whitespace, before an opcode | 1 | `MUSIC1.MUS:174` = `GLISS_WAIT1→\x01equ chord_shape1\x02¶` |
| after a mid-line token or quote | 5 | `HISCORE.ROU:419` = `…"THE OLIVER TWINS^^"\x01,mdownline\x02,mdownline¶` (2); `MACROS.MUS:360` = `→endif\x02¶`; `JONSBIT.MUS:624` = `→endif\x02¶`; `MUSIC1.MUS:174` (end of `chord_shape1`) |

`[I]` PDS tolerates them because they are non-printing and are skipped/stripped by
the editor's line reader. Evidence: `PRTROBIN.ROU` is listed in `ROBIN.PRJ` and its
line 1 is `\x01flashrobin→defb …`; the label `flashrobin` is referenced later in
the same file. If the 0x01 were *not* ignored, `flashrobin` would be parsed as an
opcode and the build would fail.

**Rule for a transpiler:** after splitting into lines (and truncating at 0x1A),
delete bytes `0x00–0x08`, `0x0B`, `0x0C`, `0x0E–0x1A` (keep TAB) *before* any
lexical analysis. Deleting only 0x01/0x02 also works on this corpus. Do **not**
replace them with spaces — several sit between a label and its terminator, where a
space would change the parse (see §3.4).

### 1.5 Tabs

`[O]` 11,315 of the 11,597 indented statements start with a TAB; 282 start with a
space. Of the 2,178 label-bearing lines, 1,475 separate the label from what
follows with a TAB, 112 with a space, and 591 end at the label (EOL). Tabs are pure
separators; a tab is **one character** for the column-1 rule (a line whose first
byte is TAB has no label).

---

## 2. The line model

`[D]` "Each line is individually processed and assembled. The assembler is looking
for a number of possibilities the line could contain." (`M:28`) `[D]` "If you don't
want to define a label on a line you must enter at least one space or tab. In
between all the fields on a line, PDS will skip over any number of tabs and/or
spaces." (`PDS:106-107`)

Every line is one of four shapes:

```
blank          →␠␠␠¶
comment        ; …¶        |  * …¶        (also with leading whitespace)
label only     LABEL¶      |  LABEL→¶     (label gets the current PC)
statement      LABEL→LDA #0␠␠;comment¶
```

Field layout, left to right:

| # | Field | Must start at | Terminated by | Required? |
|---|-------|---------------|---------------|-----------|
| 1 | label | **column 1** | one non-label char, then whitespace | no |
| 2 | opcode/mnemonic/directive/macro | after whitespace | whitespace or EOL | no (label-only line) |
| 3 | operand | after whitespace | `;` or EOL | no |
| 4 | comment | anywhere after the label terminator | EOL | no |

The essential asymmetry: **field 1 is position-sensitive (column 1), fields 2–4
are not.** `[D]` "Labels in PDS must start at the first character of the line."
(`M:30`) A token that looks like a label but is indented is the *opcode*.

### 2.1 Reference parse algorithm

This algorithm was run over all 19,394 corpus lines and parses **every** line
(the only 5 exceptions are `@1→equ …` lines inside macro bodies, §3.7, which are
not source-level labels):

```
parse_line(raw):
    s = strip_cr(raw); if s == "" -> BLANK
    i = 0
    if s[0] in LABEL_START:                 # letter _ . $ !
        (label, i) = scan_label(s)          # §3
        if i < len(s) and s[i] not in " \t":
            i += 1                          # ← the one ignored terminator
        skip " \t"
        if i == len(s) or s[i] == ';':  -> LABEL_ONLY (or comment)
    else:
        skip " \t"
        if i == len(s):                    -> BLANK
        if s[i] in ";*":                   -> COMMENT   # '*' only here
    (opcode, i) = scan_token(s, i)          # §6
    skip " \t"
    operand = s[i:] up to first ';'
    if ';' present: comment = rest
```

`[O]` Results: 11,597 indented-opcode lines, 3,305 comment lines, 2,228 blank
lines, 1,471 `label + opcode`, 707 label-only/`label ;comment`, 81 whitespace-only
lines.

### 2.2 Worked examples from the corpus

```
START.ROU:4     start→sei¶                     label "start", opcode "sei"
START.ROU:5     ␠→cld¶                          no label; TAB skipped; opcode "cld"
START.ROU:2     ¶                               blank
START.ROU:10    ;→TAIWAN LOCK CHIP SOFTWARE¶    comment (col 1 ';')
BANK12.PDS:2    ED12¶                           label-only; ED12 := PC
BANK12.PDS:6    BANK12␠DEFB <B12,>B12 ;maps…¶   label, SPACE terminator, opcode
HISCORE.ROU:21  sizeofmessage␠equ 17→;size…¶    label, SPACE, opcode, comment
SPRITESD.DAT:3  spritetable ␠;;defw pointers…¶  label, SPACE, `;;` comment
```

`[O]` `START.ROU:5` shows that a leading space followed by a tab is fine; the
space terminates the (empty) label field, the tab is skipped.

---

## 3. Labels and symbols

### 3.1 Character set

`[D]` "The valid label characters allowed in the 6502 assembler are: `a-z A-Z 0-9 . _ $`"
(`M:30`; the raw OCR prints the set as `1.097AZ_¢`, `PDS:79-83`). `[D]` "The first
character can be any valid label character, **except the numeric digits 0 to 9**."

Therefore:

```
label_start  := ALPHA | "_" | "." | "$" | "!"      ("!" = local, §4)
label_char   := ALPHA | DIGIT | "_" | "." | "$"
```

`[O]` Corpus inventory (1,331 distinct global labels, 1,372 definitions, 294
distinct local-label spellings):

| Feature | Observed? | Example |
|---------|-----------|---------|
| lowercase / mixed case | yes | `start`, `movv`, `_STATUS1`, `gav_COUNTER` |
| leading `_` | yes (15 labels; 178 contain `_` anywhere) | `_spritedata`, `_control1` |
| embedded `.` | yes | `bank.tbl`, `move.w`, `move.val`, `robinchrs0.255` |
| embedded `$` | documented, **not observed** | — |
| leading `$` | legal, **not observed** (dangerous, §8) | — |
| leading `.` | legal, **not observed** (dangerous, §8) | — |
| leading digit | **never** | — |
| length | max 25 (`nowcollidebarrelwithrobin`, `ONSCREEN.ROU:1194`) | 83 labels > 16 chars |

`[D]` "Labels can be of any length" (`M:30`). `[O]` Labels sharing a 20-character
prefix exist and assemble, so the symbol table stores at least 21 significant
characters. `[I]` No truncation occurs up to 25 characters; do not truncate.

### 3.2 Case folding

`[D]` "the assembler is not case sensitive — it converts everything into upper
case." (`M:30`)

`[O]` Folding applies to *identifiers only*, not to string data:

* `HISCORE.ROU:66` defines `MOVV`, line 70 jumps to `movv`. ✔
* `SOUNDFX.ROU:586` defines `!METAL_BALL`, line 273 references `!metal_ball`. ✔
* `MACROS.MUS:292` `CLOCKS MACRO`, invoked as `CLOCKS`; `HISCORE.ROU:51` `move.w`
  (lowercase) is the same macro as `MACROS.PDS:516` `move.w`.
* `[D]` `"a"` returns `$61`, not `$41` (`M:67`) — string literals keep their case.
  Also `[D]` `DB …,"This is a test message",…` is offered as a byte-string example
  (`M:163`). So the folding is per-token, not a blanket `toupper()` of the file.

`[I]` Implementation note: compare symbols after ASCII upper-casing; keep the
literal bytes of `"…"` as written. Do **not** upper-case a line before lexing, or
you will destroy `"a"`/`"This is…"` and quoted ERROR messages.

### 3.3 Length and content rules of thumb

* `[O]` Labels are usually short mnemonics or long descriptive names
  (`checkifstillonladderdown`, `printblocktoscreencheck`).
* `[O]` Dots are used as a *visual separator* in generated names:
  `robinchrs0.255`, `beadchr157.23`, `!T3.0`. These are single identifiers, not
  numbers, and not field separators.
* `[D]` There is no documented length limit (`M:30`); `[I]` no truncation or
  normalisation of `.`/`_` was observed.

### 3.4 The one ignored character after a label

`[D]` "At the end of the label, PDS will ignore one non-label character. This means
that if your source code has come from an assembler that demands labels be followed
with colons or hashes, PDS will ignore the extra characters." (`M:32`)

`[D]` Accepted: `FRED NOP`, `FRED: NOP`, `FRED# NOP` (`M:35-38`).

The manual then warns that this also silently accepts mistakes (`PDS:95-105`):

```
FRED+ NOP        ; defines FRED, '+' is eaten, NOP assembled
FRED- NOP
FRED* NOP
FRED; NOP        ; ← the semicolon is the terminator, NOT a comment
```

`[D]` "Notice the semicolon in the fourth example does not cause the rest of the
line to be ignored, it is treated as the label terminator." (`PDS:105-106`)

Consequences a lexer must implement exactly:

1. After scanning the label's last label-character, if the next byte is **not**
   whitespace and **not** EOL, skip exactly **one** byte unconditionally.
2. Only then skip runs of spaces/tabs.
3. Only then can `;` start a comment.

`[O]` The corpus never uses `:`/`#` terminators (0 occurrences), but it *does*
exercise arbitrary-byte terminators through the 0x01/0x02 markers
(`pauses\x01→defb`, `redefinewaterbank\x02¶`, `copyblockofchrs\x02␠;…`), which is
independent confirmation that the skipped byte can be *any* non-label byte.

### 3.5 Label-only lines and multiple labels

`[D]` "If you have an isolated label on a line, it is given the current value of
the program counter." (`M:28`) `[D]` "You may have any number of labels, each
having the same value." (`M:52`)

`[O]` 707 label-only lines. Multiple labels for one address are written on
consecutive lines — **never** two on one line:

```
BANK14.PDS:19   bank_table→¶
BANK14.PDS:20   banktable¶
BANK14.PDS:21   bank.tbl→defb 0,1,2,…¶      ; three labels, two share the address
```

`[I]` Two labels on one line is impossible by construction: the second token is
the *opcode* field, and would be looked up as a mnemonic/macro. (No counter-example
exists in the corpus; all 1,471 label+opcode lines have a real opcode there.)

`[O]` Label followed by *only* whitespace still works: `START.ROU:84` `clearram→¶`
and `BANK14.PDS:19` `bank_table→¶`.

### 3.6 Labels that collide with reserved words

`[D]` A *macro* may not share a name with a pseudo-op or instruction (`M:398`), but
nothing forbids a *label* from doing so — the two namespaces are selected by field
position.

`[O]` Real collisions in the corpus:

| Line | Collision | Why it works |
|------|-----------|--------------|
| `MACROS.PDS:11` `title→equ 1` | `TITLE` is a listing pseudo-op | used only in operand position later (`if title=1`) |
| `MACROS.PDS:504` `sub→macro` | `SUB` is not a 6502 mnemonic | macro namespace |
| `MACROS.PDS:492` `add→macro` | `ADD` is not a 6502 mnemonic | 224 invocations of `add` |
| `JONSBIT.MUS:149` `LOOP¶` | `LOOP` is a DO…LOOP terminator | here it is a *label*; the file uses `JMP LOOP` |
| `CMLOGO.ROU:2425` `!BANK→EQU $14` | `BANK` directive | `!` makes it a distinct local symbol |
| `SOUNDFX.ROU:805` `!SKP→RTS` | `SKP` printer directive | idem |

**Gotcha:** a directive keyword at column 1 is a *label definition*, and a
directive is only a directive when it is in the opcode field (i.e. preceded by
whitespace). All 11,597 label-less statements in the corpus are indented; **no**
directive or mnemonic ever appears as the first token of a line.

### 3.7 Macro-body labels (`@1` at column 1)

`[O]` Five lines have a macro parameter in the label field:

```
MACROS.PDS:25   @1→equ zlim
MACROS.PDS:35   @1→equ varlim
```

`[I]` This proves macro expansion is **textual substitution before lexing**: the
line is not lexed as a label until `@1` has been replaced by the argument
(`cm_frames`, `control0`, …). A lexer must never see `@` at column 1 in expanded
code. (It can still meet `@1` in unexpanded macro bodies.)

---

## 4. Local labels (`!`)

### 4.1 Syntax and scope

`[D]` "Any label that starts with a pling sign (`!`) is considered a local label.
… every time you use a 'normal' label, all local label definitions are cleared."
(`M:60`)

`[D]` "When `LOOP` is executed the local labels are cleared, allowing local labels
to be used inside `DO` structures." (`M:209`) `[D]` Locals are isolated per macro
invocation and do not affect other locals of the same name in the main program or
nested macros (`M:60`, `M:435`).

Grammar:

```
local_label := "!" name_char { name_char }
name_char   := ALPHA | DIGIT | "_" | "." | "$"
```

`!` is **not** in the documented label-character set — it is a special first
character that switches on local scope.

`[O]` Usage is heavier than the manual suggests: **806 definitions**, 294 distinct
spellings, **1,014 references**. Spellings include:

```
!0 !1 !2 … !670        numeric locals (single and multi-digit)
!300 !600              multi-digit
!POWERUP !RESET !LOOP2  named locals
!T3.0 !T3.1            dots inside a local name
!metal_ball            mixed case
```

`[O]` The scope rule is empirically confirmed: walking all 34 files, treating every
non-`!` column-1 label as a scope boundary, there are **zero** duplicate local
definitions within one scope (`0` collisions across 806 definitions). Duplicates
only occur across scopes — e.g. `ONSCREEN.ROU` defines `!1` 27 times,
`CONTROL.ROU` 24 times, `XTRAROUS.ROU` 17 times.

`[O]` Forward references work **within** a scope: `SOUNDFX.ROU:273` uses
`DW !CHOOSE_LETTER,!EXTRA_LIFE,!metal_ball` while `!METAL_BALL` is defined at line
586, with no non-local label in between. `[I]` A forward local reference that
crosses a global label boundary will not resolve (the local was cleared), which is
the mechanism the manual describes for avoiding redefinition errors.

`[O]` Same-line use works: `MACROS.PDS` `orgfullpage` has `!1→org (!1/256)*256+256`
— the label is defined on the line and used in its own operand.

### 4.2 Scope reset triggers

| Trigger | Resets locals? | Evidence |
|---------|----------------|----------|
| any non-`!` label at column 1 | **yes** | `[D] M:60`; `[O]` 0 same-scope dups |
| macro invocation | **yes** (fresh scope per expansion) | `[D] M:60`, `M:435`; `[O]` `MACROS.PDS` reuses `!1` 22 times across separate macro bodies |
| `LOOP` (end of `DO…LOOP`) | **yes** | `[D] M:209` |
| `UNTIL` (end of `DO…UNTIL`) | not documented | — |
| `ORG` / `BANK` | not documented; untested | `[O]` every bank file starts with a global label (`ED12`, …), so no case exercises it |
| start of file | yes (trivially) | — |

`[D]` `BANK` resets the assembler except the symbol table (`M:143`). If locals
count as symbol-table entries they would survive a `BANK`; no corpus file tests
this, because every bank file starts with a global label (`ED12`, `ED13`, …).

### 4.3 `!1` vs `@1` vs `@@1`

These are three different mechanisms and must not be conflated:

| Form | Meaning | Scope | Example |
|------|---------|-------|---------|
| `!1` | local **symbol**, defined/used like a label, cleared on scope change | lexical | `!1→dec $72` / `bcs !1` |
| `@1` | macro **parameter**, textual substitution of the raw argument (a *string*, not an expression) | textual, before lexing | `LDA @1` with `SUM FRED,…` → `LDA FRED` |
| `@@1` | macro parameter **evaluated** then substituted as a decimal/hex value | textual, before lexing | `VAR@@1 EQU *` → `VAR6`; `JSR TICKS@@1` |
| `JOHN` | named macro parameter, declared after `MACRO` (`FRED MACRO JOHN,BILL,JANE`) | textual | `LDA JOHN` |

`[D]` "Macro parameters are **text strings** — not expressions — that are inserted
into the code in place of the equivalent `@` number." (`M:400`) `[D]` `@@` evaluates
first (`M:413`). `[O]` Only `@1`–`@5` and one `@@1` occur; the manual allows `@1`–`@9`
(`M:400`).

`[D]` Commas can be quoted with `[…]` to pass them inside one parameter:
`FRED 23,[45,56,67],98` (`M:437-443`). `[O]` Not used in this corpus.

### 4.4 Version note: `$` was the local-label sigil in earlier PDS

`[D]` The early PDS manual (Z80 edition) says: "any label that starts with a dollar
sign (`$`) is considered a local label", and further "The `$` stands for current
PC only when it is followed by a non label character, otherwise it would be treated
as a local label reference." (`docs/manuals/P.D.S._Manual.pdf`, §2).

`[O]` The 6502 1.2x corpus uses `!` exclusively and `$` exclusively as a hex
prefix (811 occurrences, zero local-label uses). `[I]` `!` replaced `$` because the
`$`/PC/hex overloading was unworkable. A transpiler targeting this source tree
should implement `!` and may reject `$`-locals (or support them behind a
`--pds-1.0` flag).

---

## 5. Comments

### 5.1 Two comment introducers

`[D]` "Comments may be included anywhere in the source code — they are preceded by
semicolons. … At the very start of a line you may also use an asterisk to make the
assembler ignore the line entirely." (`M:40`)

```
; This is just a line of comment
* So is this
NOP ; This is a comment after an instruction
```

| Form | Where recognised | Count `[O]` |
|------|------------------|-------------|
| `;` at column 1 | after optional leading whitespace | 3,098 |
| of which `;;`/`;;;` | same | 316 |
| `;` indented | after whitespace, before any token | 155 |
| `*` at column 1 | **only** as first non-whitespace char | 51 |
| `*` indented | yes (one case) | 1 |
| trailing `;` after code | anywhere after the label terminator | 993 |

`[O]` `*` comments in the corpus are ASCII banners, e.g.
`GENERAL.ROU:1` = `******KEY PAD ROUTINE**************************`, and
`HISCORE.ROU:3-5`:

```
****************************************
*       high score sort routine→*
****************************************
```

`[O]` The single indented `*` comment is `MAINLOOP.ROU:23`
(`→*** Make sure that the completedgame variable is cleared! … ***`). It is live
code (inside no conditional), so `*` **after leading whitespace** must be treated
as a comment, not as an opcode.

`[I]` So the rule is "first non-whitespace byte of the line", not literally
"column 1", for both `;` and `*`. But once a label field has been recognised, `*`
is no longer a comment introducer — only `;` is. (No `LABEL *` line exists.)

### 5.2 The `LABEL;` trap

`[D]` "never use a semicolon for a comment immediately after a label, as it will be
read as the label terminator character." (`M:40`, `PDS:110-111`)

```
FRED; NOP        ; → label FRED, ';' eaten, NOP assembled. NOT a comment.
FRED ; NOP       ; → label FRED, space is the terminator, '; NOP' is a comment.
FRED␠␠;;comment  ; → label FRED, space terminator, ';;comment' is a comment.
```

`[O]` `SPRITESD.DAT:3` is a real instance of the safe form:
`spritetable ␠;;defw pointers to spritedefs 256 max¶` — label, space, `;;` comment.
`[O]` There are **zero** `LABEL;` (no-space) forms in the corpus; the dangerous form
is documented but not exercised.

### 5.3 Semicolons inside string literals

`[D]` "After a semicolon the rest of the line is ignored" (`M:40`) — stated without
exceptions. `[O]` No string literal in the corpus contains `;`, so the question is
untested. `[I]` The assembler almost certainly cuts at the first `;` regardless of
quotes (a simple `strchr`). A transpiler should reproduce that (cut before quoting),
or at minimum warn if it implements quote-aware comments, because the two differ on
inputs that exist in other PDS projects.

### 5.4 Comment content is arbitrary text

`[O]` Comments contain everything: code snippets (`;→lda #10`), `*`, `!`, `$`, `&`,
tabs, quotes and apostrophes (`;don't`, `;robin's x position`), and even the string
`"peter1234"`. Nothing inside a comment is tokenised. `[O]` 60 of the 707
label-only lines put a `;` comment after the label
(`spritetable ␠;;defw …`); the other 647 are bare labels or label+TAB.

---

## 6. The opcode / mnemonic field

### 6.1 Character set and case

`[O]` The opcode token uses the same alphabet as labels:

```
opcode := "=" | ( ALPHA | "_" | "." | "$" ) { ALPHA | DIGIT | "_" | "." | "$" }
```

* `[O]` 65 uses of the single-character opcode `=` (`EQU` alias): `CLN = @1 [2,350]`.
* `[O]` Dotted macro names: `move.w`, `move.b`, `move.val` (6 + 1 + 4 uses) —
  these are *opcodes*, not labels, when indented.
* `[D]` Dotted directive aliases exist: `.BYTE`, `.WORD`, `.ORG`, `.RADIX`,
  `.DLOAD`, `.DOWNLOAD` (`M:158`, `M:247`, `M:461`, `M:495`, `M:532`). None is used
  in this corpus, and at column 1 they would be labels (see §8).
* `[O]` Case: `LDA` and `lda` both occur in bulk; folding is case-insensitive.

### 6.2 Whitespace requirement

`[O]` Every opcode in the corpus is separated from its operand by at least one
space or tab; no `LDA#5`/`LDA($20),Y` forms occur. `[I]` Such forms would probably
work (the opcode scan stops at `#`/`(` anyway), but do not rely on it.

`[O]` 11,315 indented statements start with TAB, 282 with one or more spaces.
`[O]` The opcode field starts at column 2 in 11,531 cases, column 3 in 62, column 4
in 4 — i.e. **there are no fixed columns**; fields are whitespace-separated.
Typical style is one TAB, sometimes spaces for alignment (`BANK8.PDS`
`BANK8  DEFB` with two spaces).

### 6.3 Namespace resolution order

`[I]` From the corpus behaviour, the opcode field is resolved as:

1. Macro name (the corpus defines 107 macros, several of which shadow
   other-CPU mnemonics or plausible names: `add`, `sub`, `move.w`);
2. 6502 mnemonic (`LDA`, `BNE`, … incl. `A` operand handling for shifts);
3. pseudo-op/directive (`DEFB`, `ORG`, `IF`, …);
4. otherwise: error.

`[D]` Macros may not use a pseudo-op or instruction name (`M:398`), which keeps 1–3
unambiguous. `[O]` `add`/`sub` are safe only because they are not 6502 mnemonics.

### 6.4 Operand-less directives

`[O]` `ENDM`, `ENDIF`, `ELSE`, `LOOP`, `EXITM`, `END`, `RTS` etc. take no operand.
`NOP`/`RTS` may nevertheless carry a comment (`RTS             ;Return to
downloader`, `M:721`).

---

## 7. The operand field and its token kinds

At the *line* level, the operand field is "raw text from the first non-blank byte
after the opcode up to `;` (or EOL)". Its internal grammar depends on the opcode:

| Operand kind | Opcodes | Lexical form |
|--------------|---------|--------------|
| expression list | `DEFB/DB`, `DEFW/DW`, `DL`, `DH`, `DS`, `CBM`, `DC`, `STRING`, `PRINTER` | `expr {"," expr}` |
| single expression | `ORG`, `BANK`, `IF`, `IFF`, `UNTIL`, `REPEAT`, `FREE`, `EXEC/END`, `SEND`, `EQU/=`, `DO`, `SKIP`, `PAGE`, `WIDTH`, `LISTOPT` | `expr` (plus optional extra args) |
| instruction operand | mnemonics | addressing-mode syntax over expressions |
| hex payload | `HEX` | `hexpair { ws hexpair }` — *no commas* |
| filename | `INCLUDE/FILE`, `INCBIN` | unquoted path text (`C:\gav\NIN4\GFX4\@1.OBJ`) |
| path | `PATH` | unquoted path (`c:\nes\robin`) |
| message text | `ERROR`, `ASK`, `QUERY`, `TITLE`, `SUBTITLE`, `PAGE "…` | free text to EOL, optional leading `"` or `'`; **no closing quote required** |
| string list | `IFS` | `"[" text "]" { ws "[" text "]" }` |
| macro call | any macro | `param {"," param}`, where `[a,b]` protects commas |
| option pair | `OPTION` (undocumented) | `expr "," expr` |

### 7.1 Numbers

`[D]` "Numbers in PDS may be entered in HEX, DECIMAL, ASCII, or BINARY" (`M:62`).

| Form | Grammar | Value | Corpus example |
|------|---------|-------|----------------|
| decimal | `[0-9]+` | value in the current radix (default 10) | `num→equ→10` (`START.ROU:12`) |
| decimal, leading zeros | `0[0-9]+` | **decimal**, never octal | `cmp #07` (`START.ROU:93`), `defb …,00,…` (`HISCORE.ROU:350`) |
| negative | `-` immediately before a number/symbol | two's complement, range −32768…65535 | `lda #-1` (`CONTROL.ROU:336`), `add16toval robinxl,-8,robinxl` |
| hex, `&` | `&` HEX+ | 0…$FFFF | `b12→equ &c000-ED12` (`BANK12.PDS:3`) |
| hex, `$` | `$` HEX+ | 0…$FFFF | `_spritedata→equ $2004` (`VARS.PDS`) |
| hex, mixed case digits | | | `hiscoresinram→equ &7eD-17*10+1` (`VARS.PDS`) |
| binary | `%` [01]+ | 0…$FFFF | `lda #%10010000` (`START.ROU:138`), `DB %00111000` |
| ASCII literal | `"` 1–2 chars `"` | little-endian: `"a"`=$61, `"ab"`=$6261 | documented `M:67`; **no 1–2 char literal occurs in the corpus** |
| current PC | `*` | address of the current instruction | `CM_SHORT = *-CM_LOGO` (`CMLOGO.ROU:2342`) |
| high/low byte | `<expr`, `>expr` | `>$1234`=$34 (low), `<$1234`=$12 (high) | `DEFB <B12,>B12` (`BANK12.PDS:6`) |

Numbers are **not** delimited by a suffix. `[O]` No `0x…`, no `1234h`, no `#1234`
hex (`#` is the immediate marker); those belong to the Z80/early edition (`[D]`
early manual: "`#1234` or `1234h`"). `[O]` Zero occurrences of `0x` or `h`-suffix
in the 6502 corpus. `[O]` Bare `A–F` digits without `&`/`$` do not occur outside
identifiers, so there is no observed bare-hex form.

Usage counts `[O]`: `$`-hex 811, `&`-hex 594, `%`-binary 505, quoted strings 63,
`*`-PC ≈37, `[range]` 1 (`CLN = @1 [2,350]`).

### 7.2 RADIX

`[D]` "The `RADIX` pseudo opcode defines the default base for the expression
evaluator. Any value from 2 to 16 can be used. The default base is 10. …
Note: The expression following the `RADIX` pseudo op is **always** in base 10."
(`M:499-508`)

`[O]` Zero `RADIX` directives in the corpus; the entire build runs at radix 10.
`[I]` A lexer must therefore keep a mutable radix and value *unprefixed* digit runs
with it. `&`/`$`/`%` forms are radix-independent. `[I]` Because `RADIX`'s own
argument is always decimal, `RADIX 16` is `16`, not 22.

### 7.3 ASCII literals and the quote rules

`[D]` `"a"` → `$61`; `"ab"` → `$6261` (first char = low byte) (`M:67`).
`[D]` `DW` accepts strings "one or two characters long" (`M:247`); `DB` accepts
arbitrary text and mixes it with expressions (`M:160-166`).
`[D]` To embed a quote, double it: `"Say ""HELLO""` → `SAY "HELLO"` (`M:166`).

`[O]` 63 string literals, lengths 1…36, all in `DB`/`CBM`/`STRING`/`ERROR` data
contexts; **none** is used as a 1–2 char expression value. `[O]` No doubled quotes.

`[D]` A single leading `'` in a *message* operand preserves case
(`M:118`, `M:271`, `M:477`, `M:628`, `M:636`); `[O]` not used in this corpus.

### 7.4 Operators

`[D]` (`M:71-92`)

| Token | Meaning | Notes |
|-------|---------|-------|
| `+ - * /` | arithmetic | MOD 65535, division truncates |
| `%` | modulo | documented only by example (`M:100-108`); precedence with `* /` |
| `&` | bitwise AND | **also hex prefix** |
| `!` | bitwise OR | **also local-label prefix** |
| `~` | bitwise XOR | not in cleaned table (OCR dropped it); present in raw OCR `PDS:201` and used at `MACROS.PDS:47` |
| `=` | equality (1/0) | **also the EQU pseudo-op** |
| `<>` | inequality | |
| `<` `>` | comparison when *infix*; byte select when *prefix* | |
| `-` | unary negate (number/label only) | `-1*(expr)` to negate an expression |
| `(` `)` | grouping | also addressing-mode parentheses |
| `[` `]` | range check / IFS strings / macro comma-group | |

`[O]` `&` as an operator occurs only 4 times: `IF CLN&1` (`MACROS.MUS:311`),
`if (@1&32)` (`MACROS.PDS:46`), `(@1&64~64)`, `(@1&128~128)` (`MACROS.PDS:47`).
`[O]` `!` as OR occurs twice: `IF (CLN=30)!(CLN>31)` (`MACROS.MUS:337`) and
`(CLN=12)!(CLN>13)` (`MACROS.MUS:350`) — note the **no-space** form `)!(`, which
is why context, not spacing, must decide. `[O]` `%` as modulo: **0 occurrences**.
`[O]` `<`/`>` as comparisons: 72 lines (e.g. `if endofbank12>&c002`,
`IF *-!0 <> 19`).

`[D]` Precedence, highest first: `( )`; prefix `<`/`>`; `* /`; `+ -`;
comparisons `= <> > <`; `& ! ~` (`M:85-92`). `[I]` `%` groups with `* /`.
Expression evaluation itself is out of scope for this volume.

### 7.5 Range checks

`[D]` `expr [low,high]` after any expression; out-of-range is an error, otherwise
the bracket is ignored (`M:94-98`, `PDS:250-262`). Spaces/tabs may precede it.
`[O]` `CLN = @1 [2,350]` (`MACROS.MUS:293`). `[` `]` also delimit IFS strings
(26 `IFS` lines, e.g. `IFS [@2][]`) and macro comma-groups (`[…,…]`).

### 7.6 `HEX` payloads

`[D]` "`HEX` is followed by 2-digit HEX bytes, which may be separated with spaces or
tabs. You can fit up to 57 HEX bytes on one 120-character line." (`M:317-319`)

`[O]` 1,347 `HEX` directives (opcode field, including label+`HEX` and tab-indented
continuation lines); 111 further `HEX` lines are commented out:

```
MAPDATA.DAT:5   blkstl→HEX 0001030507080B08070D081113171B1F¶
MAPDATA.DAT:6   →HEX 23272B2F333434343B36333434343736¶
```

* `[O]` Max observed payload 32 bytes/line (manual allows 57).
* `[O]` No commas; separators are spaces/tabs only.
* `[O]` Lowercase digits accepted (`→hex 0e271a06   ;green`, `MAPDATA.DAT:224`).
* `[O]` A trailing comment can follow immediately: `PP1_FC3→HEX 030303;02`
  (`UNPACK.ROU:399`).
* `[I]` There is no continuation syntax; each line repeats `HEX`.
* `[I]` Odd digit counts are almost certainly an error; none occur.

### 7.7 Filenames and paths

`[D]` `INCLUDE` accepts drive/path names (`M:373-379`).
`[O]` Undocumented in this manual but used: `INCBIN` (8), `PATH` (1).

```
MACROS.PDS:22    →path c:\nes\robin
CMLOGO.ROU:2390  →incbin CMLOGO.PP1
MACROS.MUS:157   →INCBIN C:\gav\NIN4\GFX4\@1.OBJ
MUSIC1.MUS:1434  →incbin data3
```

`[I]` These operands are *not* expressions: the tokenizer must take the rest of the
line verbatim (up to `;`), allowing `\ / : .` and macro substitution, and must not
case-fold them into oblivion (DOS is case-insensitive, but `@1` must expand first).

### 7.8 Message operands (unterminated quotes)

`[O]` 34 `ERROR` lines; the message is raw text to EOL and usually has **no closing
quote**:

```
BANK12.PDS:11    →error "game bank 12 overflowed¶
ENDCODE.ROU:17   →error "main bank overflowed &fffa¶
MACROS.PDS:190   →error→wrong number of parameters in incr¶      ; no quote at all
```

`[D]` For `ERROR`, "A terminating quote is not required, and if used will be printed
as part of the message." (`M:271`) Same pattern for `ASK`/`QUERY`/`TITLE`/`PAGE`
(`M:118`, `M:477`, `M:628`).

`[I]` So a generic "string literal must be terminated" rule is wrong for these
directives; they need a special scanner. `[D]` Their text is uppercased unless it
starts with `'`.

---

## 8. Identifier ambiguities and how PDS resolves them

| Ambiguity | Resolution | Evidence |
|-----------|-----------|----------|
| `A` accumulator vs symbol named `A` | `A` is a reserved operand form for ASL/LSR/ROL/ROR (the only accumulator-mode ops in `help.65`); `help.65` lists `A` first for those four | `[D]` help.65; `[O]` `lsr a`, no symbol `A` in corpus |
| `$` hex vs local label (early PDS) vs label first char | 1.2x: `$`=hex in operand position. At **column 1**, `$` starts a *label* (`$FF` would be a legal symbol name, impossible to reference). | `[D]` `M:65`; `[D]` early manual; `[O]` no `$`-labels |
| `$` inside a label | legal but never used; greedy identifier scan makes `EQU$100` one token | `[D]` `M:30`; `[O]` zero embedded `$` except the dormant typo |
| `.` at token start | at column 1 → label (`.ORG` defines a label!); in opcode field → directive alias; in operand → part of an identifier (`bank.tbl`) or file extension | `[D]` `M:158`; `[O]` `bank.tbl`, `move.w` |
| digits at token start | illegal as label first char; legal inside labels and local labels (`!1`, `!670`) | `[D]` `M:30`; `[O]` 806 locals |
| symbol that looks like hex (`ED12`, `b12`, `deca`, `AA`, `FADE`) | plain symbol — hex needs `&`/`$` | `[O]` `BANK12.PDS:2` `ED12`, `MACROS.PDS:128` `deca`, `MUSIC1.MUS:1440` `AA` |
| `!` local label vs OR operator | `!` + name-char in operand position → local; `!` elsewhere → OR | `[O]` `)!(`, `bne !1` |
| `&` hex vs AND | prefix position (start of expression/after `,`/`#`) → hex; after an operand → AND | `[D]` `M:65`, `M:75`; `[O]` 594 vs 4 |
| `%` binary vs modulo | prefix position + only `0/1` → binary; otherwise modulo | `[D]` `M:66`, `M:100`; `[O]` 505 vs 0 |
| `<`/`>` byte-select vs comparison | at head of (sub)expression → byte-select; infix → comparison | `[D]` `M:83`; `[O]` `DEFB <B12,>B12` vs `if x>&c002` |
| `*` PC vs comment | first non-ws char of line → comment; inside an operand → PC | `[D]` `M:40`, `M:62`; `[O]` 52 comment lines vs ≈37 PC uses |
| `=` EQU vs equality | opcode field → EQU/bare `=` (redefinable); operand field → comparison | `[D]` `M:78`, `M:280`; `[O]` 65 opcodes, many comparisons |
| `EQU` as infix operator | used twice as an alias of `=` inside dormant macros | `[O]` `untill mwn EQU 1`; `[U]` unverified (§12) |
| `;` comment vs label terminator | terminator if it is the byte immediately after the label; otherwise comment | `[D]` `M:40`; `[O]` 0 `LABEL;` cases |

`[I]` Implementation hint: resolve `&/%/!</$` by **parser state** (operand expected
vs operator expected), not by regex. A pure token regex cannot separate
`(@1&32)` from `&32` or `)!(CLN` from `!1`.

---

## 9. Corpus anomalies, quantified

| Anomaly | Count | Example / note |
|---------|-------|----------------|
| 0x01/0x02 block markers | 56 in 30 files | §1.4; delete them |
| lines with `^Z` at EOF | 34/34 text files | truncate at 0x1A |
| files with data after `^Z` | 1 (`DATA.MUS`) | binary music blob |
| CRLF files | 2 (`BANK8.PDS`, `BANK13.PDS`) | rest LF-only |
| tab-indented statements | 11,315 | tabs are the norm |
| space-indented statements | 282 | `␠→cld`, ` compchr …` |
| one-space indented macro call | 2 | `UNPACK.ROU:21`, `:35` |
| label-only lines | 707 | 647 bare labels + 60 `label ;comment` |
| lines with a label and an opcode | 1,471 | 547 `!` locals + 924 globals |
| `;` comments (all forms) | 3,253 | 993 trailing after code |
| `*` comments | 52 | 1 of them tab-indented |
| `<`,`>` comparisons | 72 lines | `endofbank12>&c002` |
| `&` bitwise AND | 4 | `(@1&32)` |
| `!` bitwise OR | 2 | `(CLN=30)!(CLN>31)` |
| `%` modulo | 0 | only documented/example |
| `RADIX` | 0 | entire build is radix 10 |
| `INCLUDE` | 0 | `INCBIN` is used instead |
| `INCBIN` | 8 | `incbin data3`, `INCBIN …\@1.OBJ` |
| undocumented directives | 3 kinds | `OPTION` (3), `INCBIN` (8), `PATH` (1) |
| `@1` at column 1 | 5 | macro-body label definitions |
| `@@1` | 1 | `JSR TICKS@@1` |
| lines with a dotted token | 82 | identifiers/macros (`bank.tbl`, `move.w`, `!T3.0`) and filenames (`CMLOGO.PP1`) |
| files beginning with a conditional | 7 | `HISCORE.ROU:2`, `JONSBIT.MUS:2`, `MACROS.MUS:1`, `MUSIC1.MUS:2`, `NEWBITS.ROU:1`, `SOUNDFX.ROU:2`, `TITLE.ROU:1` — always `→if …`, never column 1 |
| files beginning with a comment | 9 | 6 start with `;` (`CMLOGO.ROU:1` is `;` alone), 3 with `*` (`GENERAL.ROU:1`) |
| longest line | 146 chars | a `***` comment; over the 120 guideline |
| longest label | 25 chars | `nowcollidebarrelwithrobin` |
| same-name global redefinitions outside macro bodies | 0 except bare `=` | `runcounter`, `wipebanks`, `xx`, `count`, `AA` are all `=` redefinitions |
| duplicate locals in one scope | 0 | strong confirmation of §4.2 |

Two real defects preserved in the shipped source (do not "fix" silently if the
goal is a bit-identical rebuild):

* `MACROS.PDS:374` `→if→uuu→EQU$100` — `EQU` and `$100` are jammed together inside
  the never-invoked `slddr` macro. Under a greedy identifier lexer this is one
  token; the line only makes sense if `EQU` is an infix operator. Dormant.
* `MACROS.PDS:590` `→until mwn→EQU 1` — `EQU` used where `=` is expected, inside the
  never-invoked `multword` macro. Dormant.
* `UNPACK.ROU:17` `compchr hiscorechrs0.43` and `:19` `compchr hiscorechrs0.43s`
  define **two different symbols**. Likewise `REDEFCHR.ROU` mentions both
  `solidchr255.1` and `solidchr255.1s`. Do not normalise the trailing `s` away;
  it is part of the identifier.

---

## 10. Formal grammar (EBNF)

Written for a transpiler author. `[I]` marks productions that encode an inference;
everything else is directly documented or observed. Terminals are quoted; `?…?`
denotes a byte-class predicate.

```ebnf
(* ================= physical layer ================= *)

file            = { source_char } [ eof ] ;
eof             = %x1A ;                      (* ^Z: stop reading here *)

(* split on any of: LF, CRLF, CR.  A trailing CR is not part of the line. *)
raw_line        = { ? any byte except CR, LF, %x1A ? } ;

(* preprocessing: delete %x00-%x08, %x0B, %x0C, %x0E-%x1A before lexing.
   Keep HTAB (%x09).  This removes the editor's 0x01/0x02 block markers. *)

(* ================= one logical line ================= *)

logical_line    = blank | comment_line | statement ;

blank           = ws ;
comment_line    = ws ( ";" | "*" ) { text_char } ;      (* no label field *)
ws              = { " " | HTAB } ;

statement       = [ label_part ] [ opcode_part ] [ comment_part ] ;
                  (* label_part is only legal at column 1; otherwise this
                     production starts at opcode_part *)

(* --- field 1: label, ONLY if it begins at byte offset 0 --- *)
label_part      = label [ terminator ] ;
label           = global_label | local_label ;
global_label    = label_start { label_char } ;
local_label     = "!" label_char { label_char } ;
label_start     = ALPHA | "_" | "." | "$" ;
label_char      = ALPHA | DIGIT | "_" | "." | "$" ;

(* exactly one non-label, non-whitespace byte is discarded after a label: *)
terminator      = ? any byte not in label_char and not in { " ", HTAB } ? ;

(* --- field 2: opcode / mnemonic / directive / macro name --- *)
opcode_part     = ws opcode ;
opcode          = "=" | identifier ;
identifier      = label_start { label_char } ;         (* dots allowed: move.w *)

(* --- field 3: operand (raw; interpretation is opcode-specific) --- *)
operand_part    = ws operand ;
operand         = { ? any byte except ";" ? } ;

(* --- field 4: comment --- *)
comment_part    = ";" { text_char } ;

text_char       = ? any byte except CR, LF ? ;
ALPHA           = "A".."Z" | "a".."z" ;                (* folded for identifiers *)
DIGIT           = "0".."9" ;

(* ================= expressions (operand contents) ================= *)

expr            = prefix_expr { infix_op prefix_expr } [ range_check ] ;
prefix_expr     = "-" prefix_expr
                | byte_op prefix_expr
                | primary ;
primary         = number | hex | binary | char_literal | pc
                | symbol | "(" expr ")" ;
pc              = "*" ;
symbol          = global_label | local_label ;
byte_op         = "<" | ">" ;
infix_op        = "+" | "-" | "*" | "/" | "%" | "&" | "!" | "~"
                | "=" | "<>" | "<" | ">" | "EQU" ;     (* EQU: unverified *)

range_check     = "[" expr "," expr "]" ;

number          = DIGIT { DIGIT | ALPHA } ;            (* valued in current RADIX;
                                                          at radix 16 an unprefixed
                                                          hex-digit token is a
                                                          number, not a symbol *)
hex             = ( "&" | "$" ) HEXDIGIT { HEXDIGIT } ;
binary          = "%" BINDIGIT { BINDIGIT } ;
char_literal    = '"' one_or_two_chars '"' ;           (* little-endian value;
                                                          "" escapes one quote *)

HEXDIGIT        = DIGIT | "A".."F" | "a".."f" ;
BINDIGIT        = "0" | "1" ;

(* ================= directive-specific operand forms ================= *)

expr_list       = expr { "," expr } ;
hex_payload     = hex_pair { ws hex_pair } ;           (* HEX: no commas *)
hex_pair        = HEXDIGIT HEXDIGIT ;
filename        = { ? any byte except ";" ? } ;        (* INCBIN / INCLUDE / PATH *)
message_text    = { ? any byte except EOL ? } ;        (* ERROR/ASK/QUERY/... *)
ifs_list        = "[" { ? any byte except "]" ? } "]"
                  { ws "[" { ? any byte except "]" ? } "]" } ;
macro_arg       = expr | "[" { ? any byte except "]" ? } "]" ;
macro_args      = macro_arg { "," macro_arg } ;
```

Disambiguation rules the grammar cannot express by itself (apply in this order):

1. If the first byte of the line is a `label_start`, parse `label_part`. Else there
   is no label; skip `ws`; `;`/`*` means comment.
2. After `label`, consume exactly one byte if it is not `ws` and not EOL.
3. `;` starts `comment_part` only *after* the terminator has been consumed.
4. `*` starts `comment_line` only if no label field was parsed.
5. In `expr`, `&`/`%`/`!`/`<`/`>` are literals/prefix operators at
   `prefix_expr` position and infix operators after a complete `prefix_expr`.
6. `EQU` is a mnemonic alias in `opcode` position and (probably) `=` in
   `infix_op` position.

---

## 11. Gotchas for a transpiler

1. **Column 1 is load-bearing.** Never trim leading whitespace before deciding
   whether a label exists. A token in column 1 is a label; the same token indented
   is an opcode.
2. **Drop exactly one byte after a label**, whatever it is (`:`, `#`, `,`, `;`,
   0x02 …). Do not drop whitespace *and* the next byte: `LABEL␠:␠NOP` means label
   `LABEL`, then opcode `:` — an error, not `NOP`.
3. **`LABEL;comment` is not a comment.** Only `LABEL␠;comment` is.
4. **`*` is a comment only at the start of a line** (after optional whitespace),
   and never after a label. It is also the current-PC symbol inside operands.
5. **Strip 0x01/0x02 (and ideally all C0 controls except TAB) globally, not
   line-start only.** They occur after labels, after quotes and between a tab and
   an opcode. Replacing them with spaces changes the parse where they act as the
   label terminator.
6. **Truncate at 0x1A**, accept CR/LF/CRLF. Do not treat CR as data.
7. **Do not upper-case the whole line.** Upper-case identifiers for lookup; leave
   string literal bytes alone (`"a"` = $61) and apply the `'`-prefix rule to
   message directives.
8. **A missing closing quote is normal** for `ERROR/ASK/QUERY/TITLE/SUBTITLE/PAGE`.
   Their operand is raw text to EOL; do not report "unterminated string".
9. **Numbers have no suffixes.** `0x10` and `10h` are Z80/other-assembler forms
   and must not be accepted as 6502 source; `#` marks immediates, not hex.
10. **`#` is the immediate marker, not a hex marker.** `#$ff` is immediate 255.
11. **`%` and `&` are dual-use.** Decide by parser position; `(@1&32)` is AND,
    `#&32` is hex; `3%(FS)`, if you ever see it, is modulo, `%1010` is binary.
    Prefer stateful parsing over a regex tokenizer.
12. **`!` is dual-use.** `!name` in operand position is a local label; `!` between
    operands is OR. `)!(…` has no spaces.
13. **`<`/`>` are dual-use.** Prefix = byte select (`<B12`, `>B12`), infix =
    comparison (`x>&c002`). `<>` is only ever comparison and cannot start an
    expression.
14. **Local labels are scoped, not file-scoped.** Reset on every non-`!` label
    (also on macro entry and `LOOP`). Forward references are legal inside the
    scope. Do not build one flat symbol table.
15. **`!1` ≠ `@1`.** `@n` is textual substitution (possibly multiple tokens, may
    contain commas via `[…]`); `!n` is a symbol.
16. **Macro bodies are stored, not lexed, until invocation.** `EQU$100` proves
    invalid text survives in a never-invoked macro. A transpiler that validates
    eagerly will reject code the real assembler accepted. Options: lazily validate,
    or warn.
17. **Macro names live in the opcode namespace and may contain dots**
    (`move.w`). Symbol names may contain dots too (`bank.tbl`,
    `robinchrs0.255`). Never split an identifier at `.`.
18. **`HEX` is not an expression list.** Bytes are 2 hex digits separated by
    whitespace; commas are invalid; lowercase is fine; a comment may follow with no
    space.
19. **Filenames are raw text.** `INCBIN`/`INCLUDE`/`PATH` take `C:\…`, `@1`
    substitution and lowercase; do not tokenise as expressions and do not reject
    `\` or `:`.
20. **Directive keywords can be labels.** `title equ 1`, `LOOP` as a label. Field
    position decides the namespace; do not reserve words globally.
21. **Radix is mutable** (`RADIX`), and its argument is always decimal. Default 10;
    the corpus never changes it.
22. **`.org`, `.byte`, `.radix` at column 1 are labels**, not directives. If you
    accept the dotted aliases at all, only accept them in the opcode field.
23. **`$` at column 1 would be a label, not a number.** Do not run number lexing
    over field 1.
24. **Comments can contain anything** — quotes, `;`, tabs, `!`, `$`, unbalanced
    brackets. Cut at the first `;` (after the label terminator) and stop.
25. **Whitespace runs are free-form.** There are no fixed columns; one tab is
    idiomatic but `␠␠`, `␠→`, and `→→` all occur.
26. **A label-only line defines the symbol at the current PC**, even with trailing
    whitespace and nothing else (`clearram→¶`).
27. **Bank files are ordinary source.** `BANK12.PDS` etc. are just text emitted at
    that point in the build; the `BANK n` operand is a decimal bank number, and
    `bank 12,START` is the two-argument form.

---

## 12. Open questions

1. `[U]` **Is `EQU` a legal infix equality operator?** Both corpus uses are in
   never-invoked macros (`slddr`, `multword`), so no successful assembly proves it.
   The cleanest reading of `→if→uuu→EQU$100` is that it was meant to be `=`.
2. `[U]` **Is the whole line upper-cased before tokenising?** The manual's
   `"a"`=$61 claim and its mixed-case `DB` example say no for literals, while
   "due to the way the assembler works" for ASK/IFS says yes for parameters. No
   lowercase data literal exists in the corpus to settle it.
3. `[U]` **Is comment stripping quote-aware?** No `;` occurs inside a literal.
4. `[U]` **`OPTION a,b` semantics.** Used 3× (`OPTION 0,0`, `option 0,1`) and
   documented nowhere in either manual edition. Must be preserved verbatim.
5. `[U]` **`INCBIN` semantics** (path resolution vs `PATH`, whether it is a
   pass-1-only include like `INCLUDE`).
6. `[U]` **Exact symbol length limit**, if any. 25-char names work, and distinct
   labels sharing a 20-char prefix remain distinct.
7. `[U]` **Local-label clear on `UNTIL`** (manual only mentions `LOOP`).
8. `[U]` **`A` vs a user symbol named `A`** in non-accumulator operand position;
   no such symbol exists here.

---

## Appendix A — literal forms → values (quick table)

| Source text | Value | Notes |
|-------------|-------|-------|
| `0` | 0 | decimal |
| `10` | 10 | decimal |
| `07` | 7 | decimal; **not** octal |
| `255` | 255 | |
| `-1` | 65535 | 2's complement (`lda #-1`) |
| `-8` | 65528 | `add16toval robinxl,-8,…` |
| `&ff` | 255 | hex |
| `&8000` | 32768 | |
| `&c000` | 49152 | |
| `&7eD` | 2029 | case-insensitive hex digits |
| `$ff` | 255 | hex |
| `$2004` | 8196 | |
| `%1010` | 10 | binary |
| `%00100000` | 32 | |
| `*` | PC | current assembly address |
| `"a"` | $61 | documented; not present in corpus |
| `"ab"` | $6261 | 'a' low byte, 'b' high byte |
| `<B12` | high byte of B12 | prefix byte-select |
| `>B12` | low byte of B12 | prefix byte-select |
| `#$ff` | immediate 255 | `#` is not part of the number |
| `#%10010000` | immediate 128 | |
| `ED12` | symbol | `[O]` label, not hex |
| `deca` | symbol | `[O]` label whose letters are all hex digits |
| `bank.tbl` | symbol | dot is part of the identifier |
| `!1` | local symbol | not a macro parameter |
| `@1` | macro parameter text | only inside macro bodies |
| `@@1` | evaluated macro parameter | substituted as a number |
