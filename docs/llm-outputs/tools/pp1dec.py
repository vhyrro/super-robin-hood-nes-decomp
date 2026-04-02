#!/usr/bin/env python3
"""PP1 packed NES character-set decoder.

Format reverse-engineered from pds_src/src/PP1UNPAK (PDS 6502 source) and
validated by round-tripping every .PP1 in pds_src/src through PP1PACK.EXE.

Usage:  pp1dec.py packed.pp1 [-o raw.chr] [-q]
Output: raw 16-byte NES tiles (8 bytes plane 0, then 8 bytes plane 1).
"""
import sys

class Bits:
    """MSB-first reader; mirrors the 6502 TEMP2 register ($80 sentinel)."""
    def __init__(self, data, pos=0):
        self.d, self.p, self.t = data, pos, 0x80
    def bit(self):
        c = self.t >> 7
        self.t = (self.t << 1) & 0xFF
        if self.t == 0:                      # ASL TEMP2 -> 0 => fetch
            self.t = self.d[self.p]
            self.p += 1
            c = self.t >> 7
            self.t = ((self.t << 1) | 1) & 0xFF
        return c
    def bits2(self):
        return (self.bit() << 1) | self.bit()

# Colour-fold tables, as assembled (FC2/FC3 run into FC1 in memory, hence
# the 4th entry of each).
FC3 = [3, 3, 3, 2]
FC2 = [2, 2, 1, 1]
FC1 = [1, 0, 0, 0]
F0L, F0H = FC2, FC3
F1L, F1H = [2, 0xFF, 0, 0], FC3
F2L, F2H = FC1, [3, 3, 0xFF, 1]
F3L, F3H = FC1, FC2

def _t1(b, x):
    if b.bit(): return FC1[x]
    if b.bit(): return FC3[x]
    return FC2[x]

def _t3(b, x, fol1, fol2):
    v = _t1(b, x)
    fol1[x] = v
    lo, hi = [(F0L, F0H), (F1L, F1H), (F2L, F2H), (F3L, F3H)][v]
    fol2[x] = lo[x]
    return hi[x]

def decode(data):
    n = data[0] or 256
    b = Bits(data, 1)
    types = [0]*4; fol1 = [0]*4; fol2 = [0]*4; fol3 = [0]*4
    out = bytearray(); prev = None
    for _ in range(n):
        if b.bit() == 0:                    # new header for this group
            for x in (3, 2, 1, 0):
                t = b.bits2(); types[x] = t
                if t == 0:
                    continue
                if t == 1:
                    fol1[x] = _t1(b, x)
                elif t == 2:
                    v = _t3(b, x, fol1, fol2)
                    if b.bit():
                        fol2[x] = v
                else:
                    fol3[x] = _t3(b, x, fol1, fol2)
        rows = [0]*8
        for line in range(8):
            if b.bit():                     # repeat the previous row
                t4, t5 = prev
            else:
                x = b.bits2()               # first pixel: literal colour
                t4, t5 = x, (x >> 1) | 2    # sentinel makes exactly 7 steps
                for _ in range(7):
                    typ = types[x]
                    if typ == 1:
                        if b.bit() == 0: x = fol1[x]
                    elif typ == 2:
                        if b.bit() == 0:
                            x = fol2[x] if b.bit() else fol1[x]
                    elif typ == 3:
                        if b.bit() == 0:
                            if b.bit() == 0:
                                x = fol3[x] if b.bit() else fol2[x]
                            else:
                                x = fol1[x]
                    t4 = ((t4 << 1) | (x & 1)) & 0xFF
                    t5 = ((t5 << 1) | (x >> 1)) & 0xFF
            prev = (t4, t5)
            rows[line] = t5
            out.append(t4)                  # plane 0 row, in order
        out.extend(rows)                    # plane 1 rows, in order
    return bytes(out), b.p

def _selfcheck():
    # Known good pair shipped in the repo.
    packed = bytes.fromhex('0120a35e539416a9f8bfe0')
    raw = bytes.fromhex('ffffffffffffffff9f6f6a6a99fafaff')
    got, used = decode(packed)
    assert got == raw, (got.hex(), raw.hex())
    assert used == len(packed)
    print('selfcheck ok')

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--selfcheck':
        _selfcheck(); raise SystemExit
    src = sys.argv[1]
    out = sys.argv[sys.argv.index('-o') + 1] if '-o' in sys.argv else None
    quiet = '-q' in sys.argv
    d = open(src, 'rb').read()
    raw, used = decode(d)
    if out:
        open(out, 'wb').write(raw)
    else:
        sys.stdout.buffer.write(raw)
    if not quiet:
        sys.stderr.write(f'{src}: {len(d)} bytes, {d[0] or 256} chars, '
                         f'{used}/{len(d)} bytes consumed -> {len(raw)} bytes raw\n')
