#!/usr/bin/env python3
"""corpus_inventory.py -- feature census of the Super Robin Hood PDS 6502 corpus.

Run from anywhere:  python3 docs/re/pds/tools/corpus_inventory.py
Reads ../pds_src/src (resolved relative to this file), never writes.

Outputs Markdown tables on stdout:
  * per-file inventory (size, line endings, labels, emitted bytes)
  * pseudo-op / directive per-file matrix
  * 6502 mnemonic per-file matrix
  * macro definition / expansion census
  * operand-form census

Parsing model (matches PDS as documented in PDS_Manual_6502.txt and observed):
  - a label is any token starting in column 1; the next token is the opcode
  - a line starting with ';' or '*' in column 1 is a comment
  - ';' starts a comment unless inside double quotes
  - '*' is also the program-counter symbol when it appears in an operand
"""
import os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..', 'pds_src', 'src'))

PRJ_ORDER = """MACROS.PDS VARS.PDS BANK8.PDS MAPDATA.DAT BANK12.PDS MACROS.MUS
JONSBIT.MUS MUSIC1.MUS HISCORE.ROU TITLE.ROU SOUNDFX.ROU NEWBITS.ROU
EXPLODE.ROU PRTROBIN.ROU BANK13.PDS CMLOGO.ROU CHRSETS.CHR BANK14.PDS
TIMINGS.ROU START.ROU MAINLOOP.ROU INTERUPT.ROU CONTROL.ROU XTRACONT.ROU
XTRAROUS.ROU ONSCREEN.ROU SPRITESD.DAT SPRITESR.ROU PRTMESS.ROU UNPACK.ROU
GENERAL.ROU MAPSCROL.ROU ENDCODE.ROU JUNK""".split()

# text sources present in the directory but not referenced by ROBIN.PRJ
NOT_BUILT_TEXT = ['REDEFCHR.ROU', 'SMILEY.ROU', 'CM_CHARS', 'PP1UNPAK']

# packed graphics / DOS binaries / ROM images: no PDS syntax
BINARY = """ARCHCHR.PP1 BASECHR.PP1 BEADCHR.PP1 BEDCHR.PP1 BOTCHRS.PP1 BOXCHR.PP1
CHRSET.PP1 CMLOGO.OLD CMLOGO.PP1 DATA.MUS DATA2 DATA3 DOORCHR.PP1 HISCORE.PP1
HEX2BIN.COM OKCHR.CHR OKCHR.PP1 PP1PACK.EXE RIP.CHR ROBINCHR.PP1 ROCKCHR.PP1
SOLIDCHR.PP1 TOPCHRS.PP1 ROBINV7.BC ROBINV7.BD ROBINV7.BE ROBINV7.BF""".split()

MNEMONICS = """ADC AND ASL BCC BCS BEQ BIT BMI BNE BPL BRK BVC BVS CLC CLD CLI CLV
CMP CPX CPY DEC DEX DEY EOR INC INX INY JMP JSR LDA LDX LDY LSR NOP ORA PHA PHP
PLA PLP ROL ROR RTI RTS SBC SEC SED SEI STA STX STY TAX TAY TSX TXA TXS TYA""".split()

DIRECTIVES = """EQU = DEFB DB DEFW DW DEFS DS HEX INCBIN ORG BANK LIST FREE ERROR
MACRO ENDM IF IFS ELSE ENDIF DO LOOP UNTIL REPEAT EXITM OPTION SEND PATH END
RADIX SKIP ASK QUERY INCLUDE CBM DC STRING BYTE WORD BLOCK DFB DFW DFS DH DL
DJ""".split()


def load(f):
    raw = open(os.path.join(SRC, f), 'rb').read()
    return raw


def text_lines(f):
    raw = load(f).decode('latin-1')
    for i, line in enumerate(raw.split('\n'), 1):
        yield i, line.replace('\r', '')


def parse(f):
    """Yield dicts for lines that contain code."""
    for lineno, line in text_lines(f):
        # the PDS editor left ^A / ^B marks in a few files; they are not syntax
        line = line.replace('\x01', '').replace('\x02', '').replace('\x1a', '')
        if not line.strip():
            continue
        if line[0] in '*;':
            continue
        strings, code, q = [], [], False
        for ch in line:
            if ch == '"':
                q = not q
                continue
            if ch == ';' and not q:
                break
            if q:
                strings.append(ch)
            else:
                code.append(ch)
        code = ''.join(code).rstrip()
        if not code.strip():
            continue
        if code[0].isspace():
            label, rest = None, code.strip()
        else:
            tok = code.split(None, 1)
            label = tok[0]
            rest = tok[1].strip() if len(tok) > 1 else ''
        if not rest:
            yield dict(lineno=lineno, raw=line, label=label, op=None,
                       operand='', strings=''.join(strings), indent=None)
            continue
        tok = rest.split(None, 1)
        op = tok[0].upper()
        operand = tok[1].strip() if len(tok) > 1 else ''
        yield dict(lineno=lineno, raw=line, label=label, op=op, operand=operand,
                   strings=''.join(strings), indent=code[0])


def emitted_bytes(f):
    """Approximate bytes emitted by data pseudo-ops (ignores instruction sizes)."""
    total = 0
    for r in parse(f):
        op, a = r['op'], r['operand']
        if op == 'HEX':
            h = re.sub(r'\s', '', a)
            total += len(h) // 2
        elif op in ('DEFB', 'DB'):
            total += sum(item_bytes(x) for x in split_args(a))
        elif op in ('DEFW', 'DW', 'DEFW', 'WORD', 'DH', 'DL', 'DJ'):
            n = len(split_args(a))
            total += 2 * n if op not in ('DH', 'DL') else n
        elif op in ('DEFS', 'DS', 'BLOCK', 'DFS'):
            n = eval_int(split_args(a)[0]) if split_args(a) else 0
            total += n or 0
        elif op == 'INCBIN':
            name = os.path.basename(a.replace('\\', '/')).strip().lower()
            for cand in os.listdir(SRC):
                if cand.lower() == name:
                    total += os.path.getsize(os.path.join(SRC, cand))
    return total


def split_args(a):
    out, cur, depth, q = [], [], 0, False
    for ch in a:
        if ch == '"':
            q = not q
        if ch == '[':
            depth += 1
        if ch == ']':
            depth -= 1
        if ch == ',' and not q and depth == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    if ''.join(cur).strip() or out:
        out.append(''.join(cur))
    return [x.strip() for x in out if x.strip()]


def item_bytes(x):
    if x.startswith('"'):
        return len(x.strip('"'))
    return 1


def eval_int(x):
    x = x.strip()
    m = re.match(r'^[&$]([0-9A-Fa-f]+)$', x)
    if m:
        return int(m.group(1), 16)
    m = re.match(r'^%([01]+)$', x)
    if m:
        return int(m.group(1), 2)
    m = re.match(r'^(\d+)$', x)
    if m:
        return int(m.group(1))
    return 0


def main():
    prj = [f for f in PRJ_ORDER if os.path.exists(os.path.join(SRC, f))]
    files = prj + [f for f in NOT_BUILT_TEXT if os.path.exists(os.path.join(SRC, f))]

    print('## Per-file inventory (generated)\n')
    print('| # | file | bytes | lines | CRLF | tabs | NUL | maxlen | code lines | labels | !lbl | macro defs | emitted data bytes |')
    print('|---|------|------:|------:|-----:|-----:|----:|-------:|-----------:|-------:|-----:|-----------:|-------------------:|')
    for i, f in enumerate(files, 1):
        raw = load(f)
        recs = list(parse(f))
        labs = [r['label'] for r in recs if r['label']]
        loc = [x for x in labs if x.startswith('!')]
        mdef = sum(1 for r in recs if r['op'] == 'MACRO')
        ml = max((len(l) for _, l in text_lines(f)), default=0)
        print(f"| {i} | {f} | {len(raw)} | {raw.count(10)} | {raw.count(b'\r\n')} | "
              f"{raw.count(9)} | {raw.count(0)} | {ml} | {len(recs)} | {len(labs)} | "
              f"{len(loc)} | {mdef} | {emitted_bytes(f)} |")

    # --- directive matrix
    allops = collections.Counter()
    per = collections.defaultdict(collections.Counter)
    for f in prj:
        for r in parse(f):
            if r['op']:
                allops[r['op']] += 1
                per[f][r['op']] += 1
    dirs = [d for d in DIRECTIVES if allops.get(d)]
    print('\n## Pseudo-op / directive matrix (generated)\n')
    print('| file | ' + ' | '.join(dirs) + ' |')
    print('|---|' + '---:|' * len(dirs))
    for f in prj:
        row = [str(per[f][d]) if per[f][d] else '.' for d in dirs]
        print(f'| {f} | ' + ' | '.join(row) + ' |')
    print('| **total** | ' + ' | '.join(f'**{allops[d]}**' for d in dirs) + ' |')

    # --- mnemonic matrix
    mns = [m for m in MNEMONICS if allops.get(m)]
    print('\n## 6502 mnemonic matrix (generated)\n')
    print('| file | ' + ' | '.join(mns) + ' |')
    print('|---|' + '---:|' * len(mns))
    for f in prj:
        row = [str(per[f][m]) if per[f][m] else '.' for m in mns]
        print(f'| {f} | ' + ' | '.join(row) + ' |')
    print('| **total** | ' + ' | '.join(f'**{allops[m]}**' for m in mns) + ' |')

    # --- macro census
    defs = {}
    for f in prj:
        for r in parse(f):
            if r['op'] == 'MACRO' and r['label']:
                defs[r['label'].upper()] = (f, r['lineno'])
    use = collections.Counter()
    usefile = collections.defaultdict(collections.Counter)
    for f in prj:
        for r in parse(f):
            if r['op'] in defs:
                use[r['op']] += 1
                usefile[r['op']][f] += 1
    print(f'\n## Macro census (generated)\n\n{len(defs)} definitions, '
          f'{sum(use.values())} expansion lines, '
          f'{len([k for k in defs if not use[k]])} never expanded.\n')
    print('| macro | defined | expansions | files |')
    print('|---|---|---:|---|')
    for k in defs:
        where = ', '.join(f'{a}:{b}' for a, b in usefile[k].most_common())
        print(f'| {k} | {defs[k][0]}:{defs[k][1]} | {use[k]} | {where or "-"} |')

    # --- operand forms
    C = collections.Counter()
    ex = collections.defaultdict(list)

    def note(name, f, r):
        C[name] += 1
        if len(ex[name]) < 3:
            ex[name].append(f"{f}:{r['lineno']}: {r['raw'].strip()}")

    for f in prj:
        for r in parse(f):
            a = r['operand']
            if not a:
                continue
            if re.search(r'(?<![\w$&%])\$[0-9A-Fa-f]+', a):
                note('hex $', f, r)
            if re.search(r'(?<![\w])=?&[0-9A-Fa-f]+', a):
                note('hex &', f, r)
            if re.search(r'(?<![\w%])%[01]+', a):
                note('binary %', f, r)
            if re.search(r'(?<![\w$&%.])[0-9]+', a):
                note('decimal', f, r)
            if re.search(r'(^|[#,(])-\s*[0-9]+', a):
                note('unary minus (literal)', f, r)
            if re.search(r'\*-\s*[0-9]+', a):
                note('PC-relative *-N', f, r)
            if r['strings']:
                note('quoted string', f, r)
            if re.search(r'(?<![\w*])\*(?!\*)', a):
                note('PC *', f, r)
            if re.match(r'^[<>]', a):
                note('byte op at expression start', f, r)
            if re.search(r'[#,(]\s*[<>]', a):
                note('byte op inside expression', f, r)
            if re.search(r'\[[^]]*,[^]]*\]', a):
                note('range [lo,hi]', f, r)
            if '(' in a:
                note('parentheses', f, r)
            if re.search(r'[\w)]\s*\+', a):
                note('+', f, r)
            if re.search(r'[\w)]\s*-\s*[\w$&%<]', a):
                note('-', f, r)
            if re.search(r'[\w)]\s*\*\s*[\w$&%(<]', a):
                note('* (multiply)', f, r)
            if re.search(r'[\w)]\s*/\s*[\w$&%(<]', a):
                note('/ (divide)', f, r)
            if re.search(r'[^<>!]=', a):
                note('= comparison', f, r)
            if '<>' in a:
                note('<> comparison', f, r)
            if re.search(r'[\w)]\s*>\s*[\w$&%(<]', a):
                note('> comparison', f, r)
            if re.search(r'[\w)]\s*<\s*[\w$&%(<]', a):
                note('< comparison', f, r)
            if re.search(r'\)\s*!', a) or re.search(r'!\s*\(', a):
                note('! logical OR', f, r)
            if re.search(r'\)\s*&|\w\s*&\s*\(|\w&\w', a):
                note('& logical AND', f, r)
            if '~' in a:
                note('~ logical XOR', f, r)
            if '@' in a:
                note('macro parameter @n', f, r)
            if '[' in a:
                note('square bracket', f, r)

    print('\n## Operand-form census (generated)\n')
    print('| form | lines | examples |')
    print('|---|---:|---|')
    for k, v in C.most_common():
        print(f'| {k} | {v} | ' + '<br>'.join(e.replace('|', '\\|') for e in ex[k]) + ' |')

    print('\n## Label / structure census (generated)\n')
    print('| file | labels | !local defs | !local refs | !0 | dotted | plain | MAXIFdepth | DO | LOOP | UNTIL | REPEAT | IFS | IF | IFF |')
    print('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
    for f in prj:
        recs = [r for r in parse(f)]
        labs = [r['label'] for r in recs if r['label']]
        locdef = [x for x in labs if x.startswith('!')]
        dotted = [x for x in labs if '.' in x]
        # local label references in operands
        locref = sum(len(re.findall(r'![A-Za-z0-9_.]+', r['operand'] or '')) for r in recs)
        bang0 = sum(1 for r in recs if (r['operand'] or '').find('!0') >= 0)
        depth = maxdepth = 0
        for r in recs:
            if r['op'] == 'IF':
                depth += 1
                maxdepth = max(maxdepth, depth)
            elif r['op'] == 'ENDIF':
                depth = max(0, depth - 1)
        c = collections.Counter(r['op'] for r in recs)
        print(f"| {f} | {len(labs)} | {len(locdef)} | {locref} | {bang0} | {len(dotted)} | "
              f"{len(labs)-len(locdef)-len(dotted)} | {maxdepth} | {c['DO']} | {c['LOOP']} | "
              f"{c['UNTIL']} | {c['REPEAT']} | {c['IFS']} | {c['IF']} | {c['IFF']} |")

    print('\n## Line / encoding details (generated)\n')
    print('| file | last byte | ends END? | ends ^Z? | non-ASCII bytes | NUL | CRLF | bare LF |')
    print('|---|---|---|---|---:|---:|---:|---:|')
    for f in prj:
        raw = load(f)
        last = raw[-1] if raw else 0
        txt = raw.decode('latin-1')
        ends_end = bool(re.search(r'(?im)^\s*END\s*$', txt))
        nonascii = sum(1 for b in raw if b > 126 or (b < 32 and b not in (9, 10, 13)))
        print(f"| {f} | 0x{last:02X} | {'yes' if ends_end else 'no'} | "
              f"{'yes' if last == 0x1A else 'no'} | {nonascii} | {raw.count(0)} | "
              f"{raw.count(b'\r\n')} | {raw.count(10) - raw.count(b'\r\n')} |")

    print('\n## Unrecognised leading opcodes (generated)\n')
    known = set(MNEMONICS) | set(DIRECTIVES) | set(defs)
    unknown = collections.Counter()
    for f in prj:
        for r in parse(f):
            if r['op'] and r['op'] not in known:
                unknown[(r['op'], f)] += 1
    for (op, f), n in sorted(unknown.items()):
        print(f'- `{op}` x{n} in {f}')


if __name__ == '__main__':
    main()
