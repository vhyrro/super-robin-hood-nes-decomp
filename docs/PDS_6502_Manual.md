# PDS 6502 Assembler & Monitor Manual

> **Note:** This document was compiled from a Tesseract OCR scan of the original PDS manual. Some formatting artefacts from the scan have been corrected where possible.

## Table of Contents

1. [The PDS 6502 Assembler](#1-the-pds-6502-assembler)
2. [Expression Evaluation](#2-expression-evaluation)
3. [Assembler Pseudo Opcodes](#31-the-assembler-pseudo-opcodes)
4. [Assembly Listing Pseudo Opcodes](#32-assembly-listing-pseudo-opcodes)
5. [Example Programs](#41-example-programs)
6. [Example Macros](#43-example-macros-in-the-6502-assembler)
7. [The PDS Download Software](#51-the-pds-download-software)
8. [Download Software Protocols](#52-the-pds-download-software-protocols)
9. [Control Lines During PDS Communication](#53-the-control-lines-during-pds-communication)
10. [The PDS 6502 Monitor](#61-the-pds-6502-monitor-system)
11. [Monitor Commands](#62-the-pds-monitor-commands)
12. [Options and Configure System](#63-the-options-and-configure-system-in-the-monitor)
13. [The Trace System](#64-the-trace-system)
14. [Trace System Options](#65-the-tracer-options)

---

## 1. The PDS 6502 Assembler

The assembler is invoked from the editor at any position in the source code by pressing the `[ASSEM]` function key. Assembly begins at the start of file 0 and will continue through the files until the end of file 7, or an `END` is reached. If an error occurs during assembly the assembler will stop, display an error message and move the current cursor position to the start of the line containing the error. Clear the error message by pressing any key, correct the error and reassemble again.

Each line is individually processed and assembled. The assembler is looking for a number of possibilities the line could contain. After a label, PDS will expect to find a pseudo opcode or mnemonic. If you have an isolated label on a line, it is given the current value of the program counter.

Labels in PDS must start at the first character of the line. Labels can be of any length, containing any valid label characters for that particular assembler. The first character can be any valid label character, except the numeric digits 0 to 9. The valid label characters allowed in the 6502 assembler are: `a-z A-Z 0-9 . _ $`. Note the assembler is **not case sensitive** — it converts everything into upper case.

At the end of the label, PDS will ignore one non-label character. This means that if your source code has come from an assembler that demands labels be followed with colons or hashes, PDS will ignore the extra characters. For example, PDS accepts all of these syntaxes as label definitions for `FRED`:

```
FRED  NOP
FRED: NOP
FRED# NOP
```

Comments may be included anywhere in the source code — they are preceded by semicolons. Note: never use a semicolon for a comment immediately after a label, as it will be read as the label terminator character. After a semicolon, the rest of the line is ignored. At the very start of a line you may also use an asterisk to make the assembler ignore the line entirely. For example:

```
; This is just a line of comment
* So is this
NOP ; This is a comment after an instruction
```

---

## 2. Expression Evaluation

When a label is at the start of the line, it is set to the current value of the program counter (the address where code is assembled to). You may have any number of labels, each having the same value. For example, `FRED`, `JOHN`, and `BILL` below all have the same value — the memory address of the `NOP` instruction:

```
FRED
JOHN
BILL  NOP
```

Local labels are a major part of PDS. Any label that starts with a pling sign (`!`) is considered a local label. You may use local labels the same way you'd use normal labels, although every time you use a 'normal' label, all local label definitions are cleared. It is recommended to use normal labels at the start of main subroutines, and local labels within the subroutine. This way you will never get re-defined label errors. Local labels must be used in macros to prevent multiple definitions, and they will not affect other local labels with the same name — either in the main program or in nested macros.

If you wish to know the current address of the program counter (PC) in an expression, you may use `*`, which will return the current PC. Numbers in PDS may be entered in HEX, DECIMAL, ASCII, or BINARY:

- **Decimal:** Enter as normal. PDS allows numbers from -32768 to 65535. Note that minus numbers are a duplication of 32768 to 65535 (2's complement), so `-20/4` returns 16379 instead of -5.
- **Hex:** Precede with `&` or `$`. Example: `&1234`, `$ABCD`
- **Binary:** Precede with `%`. Example: `%1010`, `%1001110`
- **ASCII:** Enclose in double quotes. Example: `"a"` returns `$61`; `"ab"` returns `$6261`

Expressions in PDS can contain labels, numbers, and any number of brackets and operators. Expressions are evaluated from left to right using standard mathematical priorities (e.g. `2+3*6` returns 20, not 30). The operators available are:

| Operator | Description |
|----------|-------------|
| `-`      | Negate a number or label (not an expression; use `-1*(expression)` to negate an expression) |
| `+ - * /` | Add, subtract, multiply, divide. No error checks; results are MOD 65535. Division rounds down. |
| `&`      | Logical AND |
| `!`      | Logical OR |
| `~`      | Logical XOR |
| `=`      | Returns 1 if both operands are equal, else 0 |
| `<>`     | Returns 1 if operands are not equal |
| `>`      | Returns 1 if left > right |
| `<`      | Returns 1 if left < right |

If `>` or `<` is at the **start** of an expression, PDS returns either the low or high byte only. For example, `>$1234` returns `$34` (low byte) and `<$1234` returns `$12` (high byte). This default behaviour (arrow points at the byte returned) can be reversed in the configuration system. These operators can only be used at the start of expressions; to use them within an expression, surround the sub-expression in brackets, e.g. `23 + 52*(<FRED)`.

Operator evaluation order (highest priority first):

1. `(` and `)` — brackets
2. `<` and `>` — when used to return LSB and MSB
3. `*` and `/`
4. `+` and `-`
5. `=`, `<>`, `>`, `<` — when used as comparison operators
6. `&`, `!`, `~`

A useful feature in PDS is the ability to check the range of expressions. If you want an expression to return a value only within a specific range (e.g. between 100 and 120), insert the range directly after the expression enclosed in square brackets:

```
FRED*2+3~BILL [100,120]
```

This will give an "expression out of range" error if the result is below 100 or above 120. Ranges can themselves be expressions. One common mistake is to use brackets in the wrong place — for example, `LDA (FRED+2) %3` would give an "extra characters on line" error because the bracketed expression is treated as an indirect memory reference with Y. The correct forms are:

```
LDA 3%(FRED+2)
```
or
```
LDA 0+(FRED+2)%3
```

---

## 3.1 The Assembler Pseudo Opcodes

Most pseudo opcodes have a number of different syntaxes, to allow the programmer to use source code directly from other assemblers without many changes. Any or all of them can be used in your programs, and all perform exactly the same task. There are two pseudo opcode lists: the first covers the usual code-related pseudo ops, while the second list is specifically for assembly listing-related pseudo ops.

### ASK — Get a yes/no response from the user

`ASK` must be used on a line with a label. This pseudo opcode will stop assembly on pass 1, print the message following the `ASK` pseudo op, and add the prompt `> (Y/N)?` automatically. If `[N]` is pressed, the label is given a value of zero; pressing `[Y]` assigns a value of one. Note: due to the way the assembler works, any text following the command will be converted to upper case. To use lower case as well, put a single quote at the start of your message:

```
CHEAT  ASK  "Cheat mode
```

This will stop assembly and display `Cheat mode (Y/N)?` in the command window, then wait for a Y or N response. A similar pseudo opcode is `QUERY`.

### BANK — Downloads code into different memory banks

**Syntax:** `BANK <bank number 0–255> [, start address]`

This is a very complex command in PDS that allows the programmer to target computers with banked RAM or a RAM capacity greater than 64K. When PDS finds a `BANK` command, the indicated bank number is sent to the target computer. This selects the correct bank configuration and downloads all the assembled code before the `BANK` pseudo opcode — only code from the last `BANK` pseudo opcode (or the start of the program) is downloaded. If a start address is specified, the downloader will jump to that address and assembly continues.

The bank numbers mean nothing to PDS — they are passed directly to the target computer download software. The programmer must add their own routines to the download software to interpret them. By allowing an optional start address, the user can make the target computer jump to the routine just downloaded while PDS continues assembling. An example use case: if the download software is located at `$8000` and the programmer wants to write code to that address, they can download it somewhere else first:

```
ORG $7000
** DOWNLOAD SOFTWARE CODE (C64.DL1 for example) **
BANK 0,$7000
ORG $8000
** PROGRAM CODE **
END
```

Note: After a `BANK` command, the assembler is "reset" — apart from the symbol table — which means the user will have to insert a new `ORG` before code following the `BANK` pseudo op. The `SKIP` function will also be disabled (you will see `no skip` displayed after assembly). PDS will automatically download the code on pass 2 without prompting `Download (Y/N)?` when multiple banks are in use.

### CBM — Commodore define message

`CBM` has exactly the same syntax as `DB`, but any text in quotes will be given in Commodore 64 screen codes rather than ASCII. For example:

```
CBM  "CAT"
```
produces: `3,1,$14`

This command does not allow text to be used in expressions (e.g. `"C"+128` would not be allowed). See also `DB`.

### DB — Define bytes and messages

**Aliases:** `DFB`, `DEFB`, `BYTE`, `EQUB`, `.BYTE`, `ASCII`, `TEXT`, `ASC`, `STR`, `DEFM`, `DM`, `DFM`

Following the command there can be any number of parameters separated by commas, each of which must be an expression within the range -128 to 255. Strings of text and text mixed with numeric expressions can also be used:

```
DB  23,45+52-FRED,"This is a test message",13,10,"!1"+128
```

To include the quote character inside strings, put two quotes one after the other — e.g. `"Say ""HELLO""` produces `SAY "HELLO"`. `.BYTE` is slightly different: if there are no parameters it defaults to `BYTE 0`. For a faster way of storing data, see `HEX`. For similar commands see `CBM`, `DC`, and `STRING`.

### DC — Define message, ending in bit 7 set

`DC` is very similar to `DB`, but any text strings will have bit 7 set on their last character. Many programmers use this format for text to indicate the end of a string has been reached. For example:

```
DC  2,"cat",13,"i"
```
produces: `2,$63,$61,$74|$80,13,$69|$80`

### DH — Define high bytes only

**Alias:** `DHIGH`

Similar to `DW`, but adds a `<` (gets high byte of expression only) in front of all the expressions. Mainly used when you have tables of high and low bytes in programs — a common occurrence in 6502 code:

```
DH  65500,23,500
```
produces: `$FF,0,1`

See also `DL`.

### DL — Define low bytes only

**Alias:** `DLOW`

Functions similarly to `DW`, but a `>` (symbol to get low byte of expression) is added in front of all expressions. Mainly used when you have tables of high and low bytes. For example:

```
DL  65500,23,500
```
produces: `$DC,23,$F4`

See also `DH`.

### DO — Used in DO…LOOP or DO…UNTIL expressions

There are two different syntaxes for `DO`:

**Syntax 1:** `DO expression` / `LOOP`

This will repeat the block of code between the `DO` and `LOOP` pseudo opcodes a number of times equal to the expression. The expression is only evaluated once, when the `DO` is first assembled. When `LOOP` is executed the local labels are cleared, allowing local labels to be used inside `DO` structures:

```
DO  8
  LDA  (FRED),Y
  STA  BILL,X
  INX
  INY
LOOP
```

**Syntax 2:** `DO` / `UNTIL expression`

Similar to `DO...LOOP`, but the expression is evaluated each time and will only exit when it returns a non-zero value. This can be used to fill memory dynamically:

```
DO
  LDA  (FRED),Y
  STA  BILL,X
  INX
  INY
UNTIL  *>1000
```

This fills memory with the code until the PC goes above address 1000. Note that `*=1000` was not used, just in case the code "stepped over" that address — in that case it would keep looping until wrapping at 65535.

### DS — Define a space of memory

**Aliases:** `DFS`, `DEFS`, `BLOCK`

**Syntax:** `DS length_of_block [, filler_byte]`

Used for either leaving or filling areas of memory. `DS 20` will move the PC on 20 memory locations; when downloading, the 20 locations will be filled with random data. To fill with a specific value, use `DS 20,0`.

### DW — Define words

**Aliases:** `DFW`, `DEFW`, `WORD`

Similar to `DB`, but defines word (two-byte) values rather than byte values. There may be any number of parameters following the command, all separated by commas, but only strings one or two characters long are accepted. Expressions should range from -32768 to 65535. As with `.BYTE`, `.WORD` defaults to `DW 0` if no parameter is given. For a faster way of storing data, see `HEX`.

```
DW  0,23,23*5,FRED+45,"ab"
```

### END — End of your program

Normally the PDS assembler stops at the end of file 7. By inserting an `END` statement, the assembler will stop at that point. Specify the execution address of your program by placing it after `END`:

```
END  START
```
or
```
END  $8000
```

Once assembled with an execution address, downloading will cause the target computer to automatically jump to this address. If an execution address is not included, the target computer will continue executing the download software after downloading. You may also specify the execution address with the `EXEC` command, but may only specify the start address once.

### ERROR — Stop the assembly with a user error

**Syntax:** `ERROR message`

When the assembler encounters this line, it will terminate assembly and print the specified message in the command line window. Once a key is pressed, you are returned to the editor with the cursor on the `ERROR` line. Normally used inside an `IF...ELSE...ENDIF` structure when a condition has not been met. As with `ASK` and `QUERY`, the assembler will convert the message into uppercase unless a single quote is placed at the start of the message. A terminating quote is not required, and if used will be printed as part of the message.

```
ERROR  "Too many aliens!
ERROR  "Coordinates were off the screen
```

### EQU — Equate a value to a label

**Aliases:** `EQUATE`, `EQU`, `DEFL`, `=`

The line with `EQU` must have a label at the beginning. The label will be given the value of the expression following the `EQU`. The expression must return the same value on pass 1 and pass 2 — no undefined (forward) labels can be used in the expression. `DEFL` and `=` are slightly different: they allow the label on that line to be re-defined. You can redefine these labels as often as you wish:

```
FRED = 2       ;FRED is set to 2
FRED = FRED+1  ;FRED is now equals 3
```

Normal equates cannot be re-defined — a "multiply defined label" error will occur if you try. This can be very powerful when used with `DO...LOOP` for filling tables or building variable structures.

### EXEC — Define your program's start address

**Alias:** `START`

**Syntax:** `EXEC expression`

This will define the execution address of the program. After code is downloaded, the target computer will jump to this address. If an execution address is not specified, the code will still be downloaded but the target computer will continue running the download software. You may also define the start address using `END`. If you wish to trace programs or use the monitor, it is best not to put a start address for your programs.

### FREE — Adds up free space in your programs

**Syntax:** `FREE expression`

At the beginning of assembly, the assembler clears the free memory variable, and every time a `FREE` command is issued, the expression following the command is added to the free variable. At the end of assembly the free memory total is displayed in the command line window. To use `FREE` for adding up all free memory, insert a `FREE` pseudo opcode before each `ORG`:

```
FREE  $8000-*
ORG   $8000
```

If the PC was at `$7FF2` before the `ORG`, `FREE` will tell you there are 14 bytes of free RAM. Normally a `FREE` pseudo opcode is inserted before all `ORG`s, and a free at the end of the program with `RAMTOP-*` as the expression. Other uses include:

- **Finding the length of routines:** `FREE END-START` prints the routine's exact length after assembly.
- **Displaying label values:** `FREE DATAAREA` prints the value of `DATAAREA` after assembly, useful for the monitor.

### HEX — Define hex bytes

**Syntax:** `HEX xx....`

`HEX` is followed by 2-digit HEX bytes, which may be separated with spaces or tabs. You can fit up to 57 HEX bytes on one 120-character line. PDS often uses `HEX` statements because they are very fast, compact and easy to read. It is recommended to put all data in this format. If you have many `DEFB`s, you can assemble and download them, then upload them into `HEX` bytes using the monitor.

### IF — Conditional assembly

**Also covered:** `ENDIF`, `ELSE`, `IFF`, `IFS`

When assembling something depending on a condition, use the `IF` command. If the expression after `IF` returns a non-zero value, the code after the `IF` will be assembled. If the expression is zero, code will be ignored until an `ENDIF` is found. You may nest `IF` statements to a depth of 10:

```
IF  FRED=23
  ; This code will only be assembled if FRED=23
ENDIF
```

`ELSE` allows an alternate piece of code to be assembled if the expression is zero:

```
IF  FRED
  ; Assembled if FRED <> 0
ELSE
  ; Assembled if FRED = 0
ENDIF
```

`IFF` is similar to `IF`, but will only assemble the following code if the expression after `IFF` contains a forward reference. This is necessary because normal `IF` statements cannot have forward references — the assembler must know the route of action on both pass 1 and pass 2.

`IFS` is similar to `IF`, but is used for string comparisons. The code following will only be assembled if the two strings contained in square brackets are equal:

```
IFS  [FRED]  [BILL]
  ; This will NOT be assembled
ENDIF

IFS  [FRED]  [FRED]
  ; This will be assembled
ENDIF
```

`IFS` is mainly used in macros with parameters. You can compare the first string against a number of different strings — if any one of them is equal, the following code will be assembled:

```
IFS  [FRED]  [BILL]  [JOHN]  [TONY]  [FRED]
  ; This will be assembled (FRED matches)
ENDIF
```

You can also use `IFS` to see if a macro parameter exists: `IFS [@1] []`. Note that all parameters are converted to upper case due to the way the assembler works.

### INCLUDE — Reads source code from a disk file

**Alias:** `FILE`

**Syntax:** `INCLUDE filename`

When PDS finds an `INCLUDE` pseudo opcode in the source, it will try to open the specified file and start reading source code from that file. When the end of the disk file is reached, PDS will return to the line directly after the `INCLUDE` in memory. The filename may contain drive specifiers and path names:

```
INCLUDE  A:\PDS\GAMES\EMPIRE\GRAPHICS
INCLUDE  FRED
INCLUDE  BILL.TXT
```

You may not nest include files, but you can have as many as you like in your main program. If there are large amounts of data in the program (graphics data is a perfect example), storing them in include files is very efficient. As data in include files is only read in on pass 1 (with `SKIP` working), on a hard disk `INCLUDE`s are very fast and assembly is hardly slowed down.

### MACRO — Define a new command in the assembler

**Also covered:** `ENDM`, `JENDM`, `EXITM`

This pseudo op is used to generate new instructions for the assembler. To define a new instruction called `FRED` that inserts four NOPs into the object code:

```
FRED  MACRO
  NOP
  NOP
  NOP
  NOP
ENDM
```

This should be placed near the start of the program, before the macro is invoked. Whenever `FRED` is assembled as a normal instruction, four NOPs will be inserted. You may have up to 250 different macros, and you cannot have macros with the same name as pseudo ops or instructions already in the assembler.

Parameters may be passed to macros. Parameters should be separated by commas and are referred to in the macro definition by `@1` to `@9`. Macro parameters are **text strings** — not expressions — that are inserted into the code in place of the equivalent `@` number:

```
SUM  MACRO
  LDA  @1
  @2   #@3
  STA  @1
ENDM

SUM  FRED,ADC,3
SUM  FRED,EOR,23
```

A macro expression can be evaluated before it is inserted into the macro text by preceding the parameter number with `@@` instead of the normal `@`. This is useful if you wish to define a number of new labels within a macro:

```
FRED  MACRO
  VAR@@1  EQU  *
ENDM

FRED  3*2
```

This will create a variable called `VAR6` within the macro, while a normal `@1` would have tried to create a label called `VAR3*2`.

If all macro parameters are expressions, you can also refer to them as named labels within the macro by listing the parameter names after `MACRO`:

```
FRED  MACRO  JOHN,BILL,JANE
  LDA  JOHN
  ADC  BILL
  EOR  JANE
ENDM
```

Macros can be nested to a depth of four, but **may not be recursive**. Labels can be used in macros, although it is best to use local labels — using the macro more than once will give a "multiple definition" error with normal labels. Local labels in macros do not affect other local labels of the same name in the source code or in other nested macros.

Macro parameters are separated by commas; leading and trailing spaces are not passed to the macro. If you wish to pass the comma character, enclose the parameter in square brackets:

```
FRED  23,[45,56,67],98
; @1 = 23
; @2 = 45,56,67
; @3 = 98
```

`EXITM` is used with `IF`, `IFF`, or `IFS` statements inside a macro. When `EXITM` is executed, the macro definition halts and returns to the main program — it is essentially an `ENDM` that also clears any uncompleted conditional structures:

```
FRED  MACRO
  IFS  [@1]  []
    EXITM
  ENDIF
  ADC  @1
ENDM
```

This example will produce no code if no parameter is given, else it will add the parameter to A.

### ORG — Setup the current PC

**Alias:** `.ORG`

**Syntax:** `ORG new_PC [, true_PC]`

The `ORG` pseudo opcode defines a new assembly address and updates the program counter accordingly. You may have up to 100 `ORG`s in a program. The new PC must not be a forward reference — it shows where code will be assembled to in memory. If a `true_PC` parameter is given, all assembled code will use this value when referencing the PC, but the code will actually be inserted at the memory pointed to by the new PC. When downloading, PDS sends the code in blocks, one block per `ORG` section — only the sections of code that exist, not all memory in between.

```
ORG  $8000,$100
```

This places code in memory at `$8000`, but the code will only run properly when moved to address `$100`. This is useful for producing disk overlays or routine modules that move in memory. To remove the PC offset, use another `ORG` without a true PC parameter.

If employing a number of `ORG`s in programs, there is always the risk that code will overlap other pieces of code already written. PDS will not trap this automatically — the only way to tell is when you have `SKIP` on and the display reads `no skip` instead of giving a skip value. You may `ORG` anywhere in memory from 0 to `$FFFF`, and `ORG`s do not have to be sequential.

### QUERY — Will get an expression from the user

`QUERY` must be used on a line with a label. It will temporarily stop assembly on pass 1, display any message after the `QUERY` pseudo opcode followed by a flashing cursor. The user may enter an expression or number and press enter, then assembly continues. The label on the `QUERY` line will be assigned the value of the expression. As with `ASK`, text is converted to upper case unless a single quote is placed at the start of the message:

```
LIVES  QUERY  "How many lives do you want :
```

Labels may be entered as part of the expression, so you can define equates and use them in responses:

```
COMMODORE  EQU  1
BBC        EQU  0
FRED       QUERY  "Which machine is it for :
```

If the user enters `COMMODORE`, `FRED` will equal 1; entering `BBC` gives 0. A similar command is `ASK`.

### RADIX — Setup the default radix for the expression evaluator

**Alias:** `.RADIX`

**Syntax:** `RADIX expression`

The `RADIX` pseudo opcode defines the default base for the expression evaluator. Any value from 2 to 16 can be used. The default base is 10. If using a large amount of binary data, rather than putting `%` in front of all the data, you could insert a `RADIX 2` command before the data and a `RADIX 10` command after it:

```
RADIX  2
DB  10101101,10101010
DB  00101010,10101010
RADIX  10
```

Note: The expression following the `RADIX` pseudo op is **always** in base 10 (the default).

### REPEAT — Repeats the following line a number of times

**Syntax:** `REPEAT expression`

`REPEAT` is used for repeating one instruction or any line a number of times. For example:

```
REPEAT  4
LSR  A
```

This is equivalent to:

```
LSR  A
LSR  A
LSR  A
LSR  A
```

### SEND — Tells PDS where to send the program once assembled

**Aliases:** `.DLOAD`, `.DOWNLOAD`

**Syntax:** `SEND destination`

The `SEND` pseudo opcode is used to determine the destination of the object code once a program has been assembled. Valid destinations are:

| Destination   | Description                              |
|---------------|------------------------------------------|
| `SERIAL`      | Via the serial port at 9600 baud         |
| `SERIAL1`     | Serial, 19200 baud                       |
| `SERIAL2`     | Serial, 1200 baud                        |
| `SERIAL3`     | Serial, 300 baud                         |
| `COMPUTER0`   | Computer 1 port, 'nibble' protocol       |
| `COMPUTER1`   | Computer 1 port                          |
| `COMPUTER2`   | Computer 2 port                          |

When assembly is completed with a `SEND` command in the program, you will be prompted `Download (Y/N)?`. Any key other than `[N]` will download the code to the specified destination. Pressing `[Y]` again after download will re-download the code. While downloading, the cursor will flash. You can press `[FINISH]` at any time to break out of downloading. Note that the assembler does not have an automatic time-out during download (unlike other areas of PDS), to allow you time to get the target computer ready.

`COMPUTER0` uses a special form of download software that sends and receives 4 bits at a time (nibble protocol), needed for machines such as the BBC Micro. Serial port usage only applies to computers that do not have a PDS interface available, but the protocols remain identical (8 bits, 1 stop bit, no parity). Use the fastest reliable speed for your machine — most are better at 1200 baud than 9600.

### SKIP — Used to speed up assembly time

**Syntax:** `SKIP expression`

This command is specific to PDS and enables programs to assemble at nearly twice the speed with no drawbacks. The command makes a note on pass 1 of any large sections of program that don't need to be reassembled again on pass 2 — these are then skipped on pass 2. After assembly, the percentage of the skip table used is displayed in the command window. If the skip percentage returns 100%, the skip table was filled early on and has probably missed some blocks towards the end. The ideal skip table usage is about 80% to 95%.

The expression after `SKIP` tells the assembler the minimum size of a block (containing no forward references) that can be added to the skip table. For average-length programs this will range from about 15 to 30. If you have include files, try to have just data in them (no forward references) — that way they will only be read in once on pass 1 and be skipped on pass 2. `SKIP` must be placed at the start of programs, before any `ORG`s. If `no skip` is ever displayed, then an `ORG` is overlapping with a previously coded block, or you are using the `BANK` command (which disables skip).

### STRING — For defining strings ending in zero

`STRING` has the same syntax as `DB`, but any text strings will have a zero byte added after the last character. Many programmers use a zero to indicate the end of a string. For example:

```
STRING  13,"Cat","dog"
```
produces: `13,$43,$61,$74,0,$64,$6F,$67,0`

For similar commands see `DB`, `DC`, and `CBM`.

---

## 3.2 Assembly Listing Pseudo Opcodes

There are a number of pseudo opcodes specifically designed for listing assembled text. They have been separated from the main pseudo opcode list because they need to be explained together.

### LIST / LST / LST

`LIST ON` and `LIST OFF` control output to the screen. When `LIST ON` is selected, you will see the source code displayed in the current window as it is assembled on the second pass. The listing produced looks like:

```
2000  ORG  10
D00A: 00  NOP
D00B: 00  NOP
D00C:     END
```

The first HEX number at the start of each line shows the current address. The character directly following the HEX number shows the action taken:
- `:` — the line has been assembled
- `+` — the line was ignored (an `IF` structure failed)
- `>` — a macro definition was decoded at that line

After the hex number there are up to 5 assembled bytes displayed. If an `IF` or `EQU` was assembled, the result of the expression is displayed instead (e.g. `000E: 0017= FRED EQU 23`).

`LIST MACRO` toggles whether the contents of macros are displayed. With it on, a macro call shows the full expansion rather than just the macro name. Listings to the screen are paged — once a page is printed, a key must be pressed before the next page is displayed.

### LLIST / LLST

Are the same as `LIST`, except they output the listing to the printer. You may print to either screen or printer, or both simultaneously. Note that `LIST MACRO` applies to both printer and screen — `LLIST MACRO` is not accepted as a separate command.

### PRINTER

Works the same way as `DB` (define byte), but all the parameters are sent to the printer. This allows you to setup the printer with specialized control sequences:

```
PRINTER  27,"@",12
```

This would initialize and do a form feed on Epson compatible printers.

### SKP

This pseudo opcode needs just one parameter, and sends the specified number of line feeds to the printer:

```
SKP  5
```

This would send five line feeds to the printer, leaving five blank lines in your listing.

### PAGE

`PAGE` has a number of different syntaxes:

- `PAGE` — Issue a form feed to the printer, moving the paper to the next start of form.
- `PAGE expression` (parameter 15 to 255) — Define the form length (number of lines per page).
- `PAGE expression, expression` — First expression defines maximum line width; second defines form length.
- `PAGE "nnnnn` — Issue a form feed, then define the current title for the code listing (equivalent to `EJECT` and `TITLE` together). A leading quote preserves the case of the title text.

### TITLE / TTL

Defines the current title, which will be printed at the top of each page (centred) from this point on. The title is converted to upper case unless a single leading quote is included in the string expression.

### SUBTITLE / STITLE / SUBTTL

Defines the current sub-title that will be printed at the top left of each page. As with `TITLE`, will be converted to upper case unless a single leading quote is included.

### WIDTH expression

Defines the maximum line length. Any line longer than this value will either be split or truncated, depending on the current list options (see `LISTOPT`).

### LISTOPT / LSTOPT

**Syntax:** `LISTOPT expression`

This will set and reset the list option flags. The specified expression will be XORed with the current option flags, so `LSTOPT 5` followed by `LSTOPT 1` is exactly the same as `LSTOPT 4`. There are 16 different list options:

| Value | Function |
|-------|----------|
| 1     | Line numbers printed at the start of each line (can be referenced by editor functions; re-start from 1 at each file) |
| 4     | Add time and date to the top of pages |
| 8     | Add version number to top of pages |
| 16    | Add a page number in the top right |
| 32    | Add a page number in the bottom left; also issues a form feed then prints the PDS start-of-file header |
| 64    | Print file headers from the RAM source; when include files are started, print a small header |
| 128   | Print printer pseudo ops (e.g. PAGE, TITLE...) — normally these only change printer formats and are not sent to the printer |
| 256   | Print symbol table in PC order (else alphabetically) |
| 512   | Remove `$` or `&` from the end of the PC value |
| 1024  | Don't do pages — just continuous listing |
| 2048  | Truncate text at the end of line |
| 4096  | Same as `LIST MACRO` when enabled |
| 8192  | Add a file number in the top right corner |
| 16384 | When text wraps, print 3 tabs (else just a space) |
| 32768 | Global: ignore all list pseudo ops. When this bit is set, all following printer commands (including further `LSTOPT`s) will be ignored until another `LSTOPT` flips bit 15 again. |

`LISTOPT` defaults to a value of 0. Example of setting bit 32768 to globally ignore all printer commands:

```
LIST OFF
LSTOPT 32768
```

After this, even `LIST ON` will be ignored. To get a listing while ignoring all printer commands:

```
LIST ON
LSTOPT 32768
```

---

## 4.1 Example Programs

PDS is very flexible in allowing many different syntaxes for most pseudo opcodes. Below is an example "shell" of a PDS program:

```
SKIP  20           ;Turn skip on for speed
ORG   $8000        ;Must be after skip
** program source code **
SEND  COMPUTER1    ;Download after assembly
END   start        ;End source and give program execution address
```

The minimum source needed is an `ORG`, otherwise PDS will not know where to assemble the source code. Without `SKIP`, assembly time will increase. Without `SEND`, no download prompt will be given after assembly. Without `END`, assembly will only terminate at the end of file 7.

Below is an example program for flashing the screen on the Commodore 64 or BBC. When assembled, you are prompted to enter either `BBC` or `COMMODORE`. The screen will flash for a few seconds, then return to the download software:

```
ORG  $7000
SEND  COMPUTER1

COMMODORE  EQU  1
BBC        EQU  0

COMPUTER  QUERY  "'Enter computer for (BBC, COMMODORE) :"

START  LDY  #0

IF  COMPUTER
  SCREEN  EQU  $400
ELSE
  SCREEN  EQU  $7C00
ENDIF

BEGIN  LDA  #32
       JSR  FILL       ;Fill screen with spaces
       LDA  #127
       JSR  FILL       ;Fill screen with blocks
       DEY
       BNE  BEGIN      ;Repeat 256 times
       RTS             ;Return to downloader

FILL   LDX  #0
!1     STA  SCREEN,X
       STA  SCREEN+$100,X
       STA  SCREEN+$200,X
       STA  SCREEN+$300,X
       DEX
       BNE  !1
       RTS

END  START
```

---

## 4.3 Example Macros in the 6502 Assembler

Macros are very useful — they can save typing, memory, and improve source code readability. Here are a few sample macros.

### JCC — Expand the 6502 branch instruction set

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

This macro expands the 6502 instruction set. Instead of entering `Bcc addr` (where `cc` is a condition such as NE, CC, EQ, CS etc.) and being unsure if the branch can be made, it will insert a branch if a branch is possible, otherwise a jump is inserted instead. Note that it will always use a jump if you have a forward reference to a label, because it cannot know how far away the label might be:

```
FRED  NOP
JCC  EQ,FRED      ;Generates: BEQ FRED

FRED  DS  300
JCC  NE,FRED      ;Generates: BNE !1 / JMP !2 / !1: JMP FRED / !2:
```

### ZVAR — Define zero page variables automatically

```
ZVAR  MACRO
  @1  EQU  ZLIM
  ZLIM = ZLIM+@2
  IF  ZLIM>255
    ERROR  "Out of zero page work space with variable @1
  ENDIF
ENDM

ZLIM = 2
ZVAR  XVAL,2    ;Allocate 2 bytes for XVAL
ZVAR  YVAL,2    ;Allocate 2 bytes for YVAL
ZVAR  TEMP,1    ;Allocate 1 byte for TEMP
ZVAR  TABLE,250 ;Error: goes above zero page!
```

This macro allows you to define zero page variables automatically. An error will be generated if you try to use workspace above `$FF`. These types of macros are useful because memory addresses are allocated automatically — this prevents overlapping variables, which is a common programming error.

### CORG — ORG with overlap checking

```
CORG  MACRO
  IF  *>@1
    ERROR  "Overlapping code at address @1
  ENDIF
  ORG  @1
ENDM
```

Instead of using `ORG`, use `CORG address` and your code will be checked for overlapping sections automatically. This macro is also useful when using banked RAM, as `SKIP` is disabled in that mode and will not indicate overlapping code.

---

## 5.1 The PDS Download Software

The download software has been written over a period of time and heavily optimised for speed and size. All types of download software are supplied on the master disk. There are three main types:

**Short 'dumb' download software (`*.DL0`):** The shortest possible software that allows you to download and execute code. Should be used when free memory on the target machine is restricted. It will not operate correctly with most monitor commands (such as modify), although commands such as fill will still work. This version is also useful when writing new download software, or when the software must be typed in by hand.

**Long 'clever' download software (`*.DL1`):** When you purchase a target computer interface, this version of software is supplied on tape or disk. It is approximately 400 bytes. It will allow you to use all the monitor's features except Analyze (which requires the DL2 version), while still allowing you to download and execute a program from the assembler.

**Interrupt driven software (`*.DL2`):** This download software runs under the interrupts and allows you to use most monitor commands while your program is running on the target computer. This allows you to watch areas of memory change, stacks building down, or modify variables while a program is running. You may not alter registers or trace from the monitor, as this would cause data areas to clash. It is useful to insert the source code of the downloader within your own program while developing — this makes debugging faster and easier.

All download software can be positioned anywhere in memory and runs completely independently, with all data areas self-contained. DL0 and DL1 both have interrupts disabled, allowing you to download programs over operating system workspace or over interrupt vectors without crashing the target machine. When downloading programs, ensure that you **do not download over the downloader itself** — this applies even when downloading the download software itself, as self-modifying code is used in all versions.

Most users load their download software on tape or disk into a completely free area of memory. On the Commodore 64, `$C000` is normally a good location for the download software; `$1900` can be used on the BBC. Some 6502 programmers position the download software at the bottom of the stack, saving memory. To make your own version of the download software: load the correct software into PDS (e.g. `C64.DL1`), change the `ORG` at the top of the source to the required address, load the original download software into the target computer, then assemble and download the new version.

---

## 5.2 The PDS Download Software Protocols

The PDS communication protocols are designed to be machine-independent — the same protocols work regardless of the target machine's processor or make. All communication uses four major routines: SEND BYTE, GET BYTE, and two direction-swapping routines. The interface hardware has eight bi-directional data lines (buffered), one input flag, and one output flag.

At the start of the main download loop, you must continually read in bytes from the interface until a command byte is received (values 180 to 187). PDS may sometimes send a `179` padding byte; this should be ignored by the downloader and is only used to ensure all blocks of data are an even number of bytes long (keeping the handshaking lines in the same state at the start of each function).

### Command 180 — Download code

Downloads an area of memory from the main computer into the target computer. Present in all download software, used by the assembler. Programs are downloaded in blocks — from the start of one `ORG` to the beginning of the next. After the `180` command byte, the start address and length are downloaded (high byte first, then low byte). A length of zero is actually 65536. Example: to download four bytes `(255,65,23,45)` to address `$8000`:

```
179 - Padding byte
180 - Command: download
$80 - Start address, high
$00 - Start address, low
$00 - Length, high
$04 - Length, low
255 - 1st data byte
 65 - 2nd data byte
 23 - 3rd data byte
 45 - 4th data byte
```

### Command 181 — Jump to an address

Downloads an address from the main computer and `JSR`s to it. If an `RTS` is executed, control returns to the main loop. Present in all versions of download software; used by the assembler if you specify a start or exec address. The main computer always sends a padding `179` byte since there are only three bytes in this command. Example: to execute a routine at `$1234`:

```
179 - Padding byte
181 - Command: jump
$12 - Start address, high
$34 - Start address, low
```

### Command 182 — Upload memory

Not supported by DL0. Similar to Command 180 in format, except after the length is sent, the ports are reversed and the requested block is sent up to the main computer. Once the data block has been sent, the ports are reversed again and the main loop is entered. Example: to upload three bytes from `$1234`:

```
179 - Padding byte
182 - Command: upload
$12 - Start address, high
$34 - Start address, low
$00 - Length, high
$03 - Length, low
[Reverse ports]
??  - 1st upload byte
??  - 2nd upload byte
??  - 3rd upload byte
[Reverse ports]
```

Note that the two port reverses act as if one byte has been sent, hence the need for the padding byte.

### Command 183 — Select bank

Present in all versions of download software. Used by the assembler's `BANK` command and the monitor's `Z` command. The main computer sends the bank number byte unaltered and expects the target computer to act on it. You must write the code to support this command. It is a simple two-byte command: `183` followed by the bank number.

```
183 - Command: select bank
??? - Bank number (0–255)
```

### Command 184 — Send all registers to the main computer

Only present in DL1. Used by the tracing and register-related functions of the monitor. A block of 7 bytes are sent to the main computer using the upload command (182). The register block is stored in the following order:

```
P  - Status register
A
X
Y
S  - Stack pointer
PC - Low byte
PC - High byte
```

The register block is updated when the download software is first entered. When you jump out of the download software, all the registers are loaded with values from this table.

### Command 185 — Get registers from the main computer

Only found in DL1. Downloads a 7-byte register block from the main computer. The registers of the target computer will be loaded with these values when the download software is jumped out of. The register block is in the same format as Command 184.

### Command 186 — Trace code buffer

Only found in DL1. Used by the tracer. Three bytes are downloaded after the command and stored in a buffer. The registers are loaded from the register block, the four-byte buffer is executed, the registers are saved back into the register block, and the main loop is entered. The code executed in the buffer must be carefully chosen — executing jumps would cause the download software to lose control. If the instruction is shorter than three bytes, the rest of the buffer must be padded with NOPs. The tracer handles this automatically.

### Command 187 — Return Analyze address

Only used in DL2 software. Sends two bytes up to the main computer containing the address of the PC when the interrupt occurred. The `A` (Analyze) command in the monitor uses this to work out where the program is spending most of its time.

---

## 5.3 The Control Lines During PDS Communication

The protocol does not set control lines directly, but **toggles** the lines to communicate. All protocols are designed so that one computer can never get ahead of the other, even with a large speed difference. There are no error-checking protocols — the interfaces are very reliable, and error checking would slow down processes with no real benefit if an error were detected.

### Sending a byte to the target computer

1. The main computer puts the byte on the data lines, then flips its output line. The main computer now waits for the input line to change state.
2. The target computer waits for the control input to flip, reads the byte on the data lines, and then toggles its output control line.
3. The main computer initiates this process first; the target computer should finish the process first.

### Getting a byte from the target computer

1. The main computer waits for its control input to flip, then reads the byte from the data bus and flips its control output.
2. The target computer puts the byte on the data lines, then flips its output line. It then waits for its input control line to flip.
3. The target computer starts this process first; the main computer finishes first.

### Swapping ports: Main→Target to Target→Main

1. The main computer flips its data lines direction, then its control line.
2. The target computer waits until the control input flips, then reverses the direction of its data lines.
3. The main computer starts this process first and is finished first.

### Swapping ports: Target→Main to Main→Target

1. The main computer waits for its control input to flip, then changes the direction of its data lines.
2. The target computer changes the direction of its data lines, then flips its control output.
3. The target computer starts this process first and is finished first.

---

## 6.1 The PDS 6502 Monitor System

You may enter the monitor at any time from the main PDS editor by pressing the `[MONITOR]` function key. In the monitor, the screen is divided into two areas: the top two lines show the 6502 registers and their values; the main area is the command area. Cursor keys move around the command area; `[HOME]` moves to the top left; `[CTRL]+[HOME]` clears the screen and moves to the top left corner.

If you press cursor left at the beginning of a line, the cursor moves to the end of the previous line. Commands may be entered in upper or lower case and must start in the left-hand column. To execute a command, place the cursor anywhere on the line with the command and press `[RETURN]`. You may return to the editor from the monitor by pressing `[FINISH]` — the monitor screen is saved, allowing you to flip between the monitor and editor without losing any work.

You do not need a target computer attached to enter the monitor. If you are using the 'Clever' (DL1) software, all monitor commands will function as normal. If using the 'Dumb' (DL0) software, only a few commands will work. When a monitor command fails or contains an error, PDS will put a question mark at the end of the line and beep. If there is something wrong with the download software or the link between computers, you will get an error message such as `Error, other computer not receiving`. Check that the target computer is running the download software and that the connection is secure.

In all monitor commands, expressions are evaluated using the assembler's expression evaluator. If you have just assembled a piece of code, you may use labels in your expressions (e.g. `DSTART` disassembles from the label `START`). The evaluator has been expanded to allow you to access memory locations by putting **curly brackets** around an expression — the value within the brackets will be evaluated and used as an address, returning the byte at that location in the target computer. For example: `B FRED,{FRED}+1` increments the byte at location `FRED`. You may also return a **word** at a memory address using square brackets (e.g. `M{[FRED]}` would modify memory pointed to by the word at location `FRED`). Both types of brackets may be nested.

The commands that require no target computer attached are: `L`, `O`, `P`, `Q`, `V`, `X`. Commands compatible with each software type:

| Command | DL0 | DL1 | DL2 |
|---------|-----|-----|-----|
| A (Analyze) | ✗ | ✗ | ✓ |
| B (modify only) | ✓ | ✓ | ✓ |
| C (Copy) | ✗ | ✓ | ✓ |
| D (Disassemble) | ✗ | ✓ | ✓ |
| E (Enter) | ✓ | ✓ | ✓ |
| F (Fill) | ✓ | ✓ | ✓ |
| G (Call) | ✓* | ✓ | ✓ |
| J (Jump) | ✗ | ✓ | ✓ |
| M (Modify) | ✗ | ✓ | ✓ |
| R (Registers) | ✗ | ✓ | ✗ |
| S (Search) | ✗ | ✓ | ✓ |
| T (Trace) | ✗ | ✓ | ✗ |
| U (Upload) | ✗ | ✓ | ✓ |
| W (modify only) | ✓ | ✓ | ✓ |
| Z (Bank) | ✓ | ✓ | ✓ |

*With DL0, `G` performs a Jump rather than a Call.

---

## 6.2 The PDS Monitor Commands

### A — Analyze a program's execution

Requires DL2 software running under interrupts.

- `A` — Repeat the last Analyze command (or `A 0,65535,1` if not used before)
- `A start, end` — Analyze between two addresses
- `A start, end, count` — Same as above, but also sets the count value (stays set until changed)

Analyze is designed to show where your program is spending most of its time. Install DL2 in the target computer running under your program's interrupts. Type `A 0,65535,1` — this displays a bar graph, each bar covering about 4K of memory. PDS prints one star on a row when an interrupt occurs in that address range. To make it more accurate, increase the count value (PDS will print a star only after that many occurrences). Once a bar reaches the other side of the display, that's where your program spends most time — narrow the address range progressively until you have about 100 bytes. The minimum address range is 15 bytes.

Note: Analyze will not work properly if your program waits for VSYNCs or other timed events, as interrupts may always occur at the same point in the code.

### B — Change or display a byte at a memory location

- `B address` — Display the byte at the given address (in hex, decimal, binary, and ASCII)
- `B address, value` — Set the byte at the address to the given value (-128 to +255)

Display needs DL1; modify only needs DL0. The `W` command has the same function but works on words. Mainly used for altering values in your program to quickly see the effect of small changes.

```
B $4000,23       ;Load address $4000 with value 23
B FRED,{FRED}*2  ;Double the byte value at location FRED
```

### C — Copy block of memory

**Syntax:** `C start, end, new_start`

Requires DL1 (clever download software). Copies the block from `start` to `end` and places it starting at `new_start`. The new block can overwrite part or all of the old block. PDS uploads the entire block into the main computer, then downloads it at the new location.

```
C 0,$3FF,$4000       ;Move first 4K to address $4000
C VARS,VARE,NEWVARS  ;Move VARS..VARE block to NEWVARS
```

Gives an error if end < start, or if the new block would go above `$FFFF`.

### D — Disassemble memory

- `D` — Disassemble a block starting from where the last disassembly finished
- `D start` — Disassemble a block starting from `start`
- `D start, end` — Disassemble from `start` to `end` (stops on any key; any key resumes; `[FINISH]` or `[ESC]` stops)
- `D# start, end` — Disassemble and insert the result at the current editor cursor position (useful for comparing or examining other programmers' code)

Requires DL1. The PDS disassembler is a **symbolic disassembler** — if a program had just been assembled, the disassembler will use the label table when generating the disassembly (see `Q5` option). When it encounters an instruction it cannot disassemble, it prints `DB` followed by the bytes:

```
8000: FF  DB $FF
```

### E — Enter a program (hex/decimal program entry)

**Syntax:** `E start_address`

Used for entering programs when you have them in hex or decimal. As you enter the program, PDS will disassemble it when you enter whole instructions. PDS will allow you to delete characters entered wrongly; if you press delete when the cursor is next to the address, the address is decremented by one. Works with DL0 (dumb software).

```
E $8000
```
Then type `888C030260`, and PDS will display:
```
8000: 88      DEY
8001: 8C 03 02  STY $0203
8004: 60      RTS
8005: *
```

Press `[FINISH]` to stop entering. Hex or decimal entry format can be changed using the config system or `Q` options.

### F — Fill memory with data

**Syntax:** `F start, length, data_byte(s)`

Fills `length` bytes starting at `start` with the given data pattern. Memory can be filled with either a single value or a repeating pattern. Works with DL0. Gives an error if length is zero.

```
F 0,4096,0       ;Fill first 4K with 0
F 0,4096,1,2,3   ;Fill first 4K with repeating pattern 1,2,3
```

### G — Call a routine and return

**Syntax:** `G start_address`

Uses the download software to call the routine via `JSR` — there will be a return address on the stack. If `RTS` is executed, control returns to the download software. If you don't need to return to the download routine, use the `J` command instead. With DL0, this performs a Jump rather than a Call. Mainly used for testing routines in combination with the `R` command:

```
R X=23,Y=2
G MULTIPLY
R
```

### J — Jump to an address

**Syntax:** `J start_address`

Requires DL1. Similar to `G`, but executes a jump — there is no return address on the stack. Your program must jump back into the download software itself. Mainly used for jumping into the middle of a routine after setting up all registers.

### K — Enter sprite grabber

**Syntax:** `K x_bytes, y_pixels`

The sprite grabber allows you to grab sprites from a bitmap screen. Before using it, ensure the correct target computer is selected (`Q1` option) and the correct screen base address is defined (`P@` option). When entered, the sprite cursor is positioned at the top left of the screen (0,0).

Controls in the sprite grabber:
- **Cursor keys** — Move the sprite cursor
- **`[SPACE]`** — Invert the sprite under the cursor (to see exactly what area it covers); press again to revert
- **`[ENTER]`** — Upload the sprite into `HEX` statements at the current editor cursor position, and increment the sprite number
- **`[ESC]`** — Return to monitor

Different cursor types can be set using the `Q8` option. The sprite is uploaded in left-to-right, top-row-to-bottom-row format, compatible with the graphics editor.

### L — Loop and execute commands quickly

The `L` command causes PDS to execute a string of monitor commands repeatedly. Type all the commands starting in the top left of the screen, place an `L` at the end, and press enter on the `L` line. PDS will do a `HOME` and keep doing returns, executing any commands it comes across. Press any key to stop. If any command gives an error, the loop stops. When PDS reaches the `L` command it will also stop looping.

A common use is with DL2 (interrupt-driven) software while a game is playing — for example, `M DATAAREA` looping will show you the data area changing in real time. Complex loops can be built up:

```
R X=23,Y={BILL}
G MULTIPLY
W [STORE],[RESULT]
W STORE,[STORE]+2
B BILL,{BILL}+1
L
```

To stop a loop when a certain condition is met, add `X 1/([STORE]-ENDADDR)` — this stops with a division-by-zero error when `STORE` reaches `ENDADDR`.

### M — Modify a block of memory

- `M` — Modify starting from where the last modify command finished
- `M start` — Modify starting from `start`

Requires DL1. Shows a block of memory displaying hex and ASCII values. Move the cursor to alter hex bytes; pressing `[RETURN]` on the line downloads it (changing the altered bytes), then uploads and reprints the line. This means if you alter ROM, it will not change when you press enter — which allows you to confirm.

### N — Send a command down to the download software

**Syntax:** `N byte [, byte, byte, byte ...]`

Sends the specified bytes to the target computer. Intended to allow you to expand the PDS monitor yourself by adding custom commands to the download software's main loop. The range 170–200 is used (or reserved) by PDS protocols, so try to avoid these unless you have changed the download software. For example, if you add `CMP #5, BEQ MINE` to the main loop, you can trigger your custom routine with `N 5`. With DL2, you could use `N 0` to freeze the program and `N 1` to restart it, or `N 0` to exchange screens in a two-screen game.

### O — Set an offset for all addresses

- `O` — Show the current offset being added to all addresses
- `O offset` — Set the new offset

All memory addresses sent to and from the target computer will have this offset added to them first. For example, if a program is loaded at `$8000` but was supposed to be at `$9000`:

```
O $8000-$9000
```

From then on it will be as if the program is really at `$9000` — for example, `D $9000` would disassemble the start of the program.

### P — Work out screen coordinates or addresses

- `P address` — Return the x and y coordinates of the screen address
- `P x,y` — Return the screen address of the x,y coordinates
- `P@ address` — Set the start of the screen to `address`

Does not require a target computer. The computer must be set up in the config system or using the `Q` command first. Six different screen formats are supported:

| Number | Computer | Screen details |
|--------|----------|----------------|
| 0 | ZX Spectrum | Hires at `$4000`, 256×192 pixels |
| 1 | Commodore 64 | Hires at `0`, 320×200 pixels |
| 2 | Amstrad Mode 0 | Hires at `$C000`, 160×200 pixels |
| 3 | Amstrad Mode 1 | Hires at `$C000`, 320×200 pixels |
| 4 | Amstrad Mode 2 | Hires at `$C000`, 640×200 pixels |
| 5 | Special Amstrad | Spectrum-mimic mode at `$C000`, 256×192 pixels |

When using `P address`, the coordinates returned are for the leftmost pixel in that byte. If using a second screen or a moved screen base, use `P@ address` to specify the new start address.

### Q — Read or set options

- `Q option` — Print the current value of the option
- `Q option, value` — Set the option to the given value

Does not require a target computer. All options can also be found in the config system. See Chapter 6.3 for a full list of options. If `Q3,1` is set ("HEX expressions mode"), all numbers are treated as hex — commands such as `DABCD` or `MC9` can then be used without a `$` prefix.

### R — Set or update the register values

- `R` — Update all registers displayed at the top of the screen
- `R register=value [, register=value ...]` — Set one or more registers to specified values

Requires DL1. Valid registers are `A`, `X`, `Y`, `S`, `P`, and `PC` (16-bit). The registers at the top of the screen are only updated after tracing has finished or an `R` command has been executed. You may set multiple registers in one command:

```
R X=23,A=2,PC=$4000
```

### S — Search memory for data

**Syntax:** `S start, end, data [, data, ...]`

Requires DL1. Searches the specified memory range for a pattern of bytes. PDS uploads the block and searches through it in the main computer's memory. When a match is found, it prints the address of the first byte of the match and continues searching from the following byte.

```
S 0,100,23        ;Search first 100 bytes for value 23
S 0,100,1,2,3     ;Search for pattern 1,2,3
S 0,100,"PDS"     ;Search for string "PDS"
```

### T — Trace

- `T` — Start tracing from the current PC
- `T address` — Start tracing from `address`

Requires DL1. The PDS tracer is a **symbolic tracer** — if a program has just been assembled, the tracer will use the symbol table while tracing (see `Q5` option). This is one of the most complex features in the entire development system. For full details, see Chapter 6.4 on the trace system.

### U — Upload/Download memory from/to the target computer

Requires DL1. Three different formats:

- `U start, length [, bytes_per_line]` — Upload memory from target into the editor at the current cursor position as `HEX` statements (default 16 bytes per line; 1 to 55 bytes per line supported)
- `U >filename, start, length` — Upload memory from target into a disk file
- `U <filename, start [, length]` — Download a disk file into the target computer at `start` (if length not specified, the whole file is transferred)

```
U >SCREEN.C64,$400,1024   ;Upload Commodore screen to file
U <SCREEN.C64,$400        ;Download it back to the Commodore screen
```

### V — Show nearest label

**Syntax:** `V expression`

Does not require a target computer. Displays the nearest label before, after, and at the given address. Requires an assembled symbol table. Very useful when tracing or disassembling, as you can reference addresses with labels in your code.

```
; If BILL=$3E8, TOM=$514, DICK=$11B4:
V 2000
; Returns:
;   TOM ($0514), 02BC bytes below that address
;   No labels at that address
;   DICK ($11B4), 09E4 bytes above that address
```

### W — Change or display a word at a memory location

- `W address` — Display the word at the given address (in hex, decimal, binary, and ASCII)
- `W address, value` — Set the word at the address to the given value (-32768 to 65535)

Display needs DL1; modify only needs DL0. The `B` command has the same function but works on bytes.

```
W $4000,23          ;Load $4000 with 23 (low) and $4001 with 0 (high)
W FRED,{FRED}*2     ;Double the word value at FRED and FRED+1
```

### X — Evaluate an expression

**Syntax:** `X expression`

Does not require a target computer. Evaluates the given expression using the assembler's expression evaluator. If a program has just been assembled, label names may be used. The value is printed in hex, decimal, binary, and (if in the ASCII printable range 32–127) ASCII.

```
X 23+45%2
;Returns: HEX=0071, DEC=00113, BIN=00000000-01110001, "q"
```

### Z — Change the bank selected in the target computer

**Syntax:** `Z bank_number`

Sends the bank number (0–255) to the target computer. This command varies depending on the computer — in the download software there is a small section you must write yourself, which receives the bank number and sets up the computer's memory accordingly. For example, on a Spectrum 128 you could `OUT` it straight to a bank select port, or you could have a more complex routine with different setups for each bank value.

---

## 6.3 The Options and Configure System in the Monitor

The monitor can be changed or altered by a number of options, which can be set or examined either in the config system from the editor, or by using the `Q` command in the monitor.

| Option | Range | Description |
|--------|-------|-------------|
| Q0 | 1 or 2 | Which PDS port the monitor works from (default: port 1) |
| Q1 | 0 to 5 | Which computer PDS thinks it is attached to (used mainly in the `P` command for screen addressing) |
| Q2 | 0, 2–16 | Default radix for all monitor commands (default: 10). If set to 0, only hex numbers are accepted — no expressions, allowing commands like `DABCD` or `MC9` |
| Q3 | 0–255 | Number of lines displayed in the `M` command (default: 8). If 0, displays one screen at a time; arrow keys navigate screens |
| Q4 | 0–255 | Number of lines displayed in the `D` command (default: 8). If 0, displays one screen at a time |

**Q5 — Disassembler flags** (each bit in an 8-bit value controls a function):

| Bit | Value | Function |
|-----|-------|----------|
| 0   | 1     | All expressions in decimal (else hex) |
| 1   | 2     | Expressions in ASCII if in range |
| 2   | 4     | Tab after the instruction (else a space) |
| 3   | 8     | Initial address in decimal (else hex) |
| 4   | 16    | IX+nn and IY+nn always in decimal (else current radix) |
| 5   | 32    | Labels printed at the beginning of the line during disassembly or tracing |
| 6   | 64    | Labels printed with the instruction being disassembled or traced |
| 7   | 128   | If an exact label match is not found, offsets to that label will be displayed (range: -2 to +2) |

**Q6 — Trace system flags** (each bit controls a function):

| Bit | Value | Function |
|-----|-------|----------|
| 0   | 1     | When executing in "FAST" mode, do a VSYNC after each instruction (makes bar visible but slows tracer to ~50 instructions/second) |
| 1   | 2     | (E command) accepts decimal input (else hex) |
| 2   | 4     | Analyze doesn't stop when one bar reaches the end — keeps going until a key is pressed |

**Q8 — Sprite grabber flags:**

| Bit | Value | Function |
|-----|-------|----------|
| 2   | 4     | Cursor moves 8 pixels at a time in the Y direction |
| 3   | 8     | Cursor is stored on the screen (else XOR'd onto the screen) |
| 0–1 | 0–3   | Cursor type: `00` = default 8×1 pixel cursor; `01` = four corner bytes of sprite; `10` = top and bottom pixel lines of sprite; `11` = inverted block the size of the sprite |

---

## 6.4 The Trace System

You can start to trace a program by entering `T address` in the monitor. If the PC at the top of the screen is already pointing at the start of your program, just press `T`. You will need the DL1 (clever) download software in the target computer. When you enter the tracer, you will see 15 lines of source code disassembled along with their addresses and hex values. An inverted bar on the first line shows the current instruction. At the bottom of the screen is a memory display box, and above it are all the tracer options.

PDS traces programs by half-running and half-emulating them. When it encounters a `JMP $1234`, it simply loads PC with `$1234`. For more complex instructions such as `ADC #2`, it downloads the instruction along with padding NOPs into a three-byte buffer in the DL1 download software — restores all registers, executes the instruction, saves the registers, sends them back to the main computer, and continues with the next instruction. On an IBM PC, this achieves approximately 1000 instructions per second.

If PDS comes across an unknown instruction, it places the inverted bar on top of it and beeps. It will not continue until the PC is altered — either to another part of your program, or past that instruction. You can use illegal instructions (e.g. `$FD`) around your program to intentionally halt the tracer.

The tracer can use the symbols from your program while tracing. To do this, ensure the program has just been assembled and the `Q5` option is set up accordingly. Note that the programs you trace should not access the ports used by the PDS interface — this will almost certainly stop the tracer and probably crash the target computer. While DL1 is in use, interrupts are always disabled (the tracer will show when they are enabled/disabled, although they never really alter). If the interrupt routine is important (e.g. reading keyboards), call it manually from the tracer. If you trace a `HALT`, it is treated just like a `NOP` (unless interrupts are disabled).

---

## 6.5 The Tracer Options

There are 11 different options in the tracer main menu:

| Key | Option | Description |
|-----|--------|-------------|
| Any key | Step | Execute the next instruction and show any registers changed |
| `G` | Go full speed | Execute a jump into your program at the current PC — leaves download software and runs at full speed |
| `F` | Fast trace | Execute code fast (as if holding a key down); stops when any key is pressed |
| `Q` | Quick trace | Execute code quickly, only updating the PC in the register display without full screen update; stops on any key |
| `S` | Stack display | Open/close a box on the right showing the last 10 items pushed on the stack (PHA shows value and `A`; JSR shows `$L` and `$H`). Press `S` again to close. |
| `R` | Register values | Prompts for register and value in the form `reg=value` to change register values |
| `M` | Memory display | Show a block of 32 bytes in hex and ASCII, at a fixed address or pointed to by a register; updated after every instruction. Select `M` again to switch off. |
| `L` | Execution limits | Specify a range of addresses that can be traced; if the program goes outside these limits it stops and beeps. Defaults: lower=0, upper=`$FFFF`. |
| `N` | Next full speed | Execute the next instruction at full speed — useful for skipping over long routines (e.g. `JSR CLS`). If the routine takes over a second, the tracer may think the target hung; wait for it to finish, then enter `T` to continue. |
| `I` | Ignore instruction | Skip over the current instruction — mainly used for skipping out of loops or avoiding calling routines |
| `T` | Trace to condition | Trace as fast as possible with no display update until a condition is met. A second menu then appears: |

**Trace-to conditions (sub-menu after pressing `T`):**

| Key | Condition |
|-----|-----------|
| `K` | Trace until any key is pressed (fastest trace available) |
| `B` | Trace until a `BRK` is executed |
| `R` | Trace until an `RTS` is executed |
| `S` | Trace until the stack is altered in any way |
| `F` | Trace until a conditional instruction fails (does not jump) |
| `P` | Trace until a certain point is passed a specified number of times (acts as a breakpoint with countdown display) |
| `C` | Trace until a register or memory address goes outside set limits, or until a particular bit pattern occurs |
