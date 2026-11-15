#!/usr/bin/env python3
"""Convert editable RGB PNG tile sheets to Codemasters PP1 and back."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

REWRITE = Path(__file__).resolve().parents[1]
ROOT = REWRITE.parent
PDS = ROOT / "pds_src" / "src"
GFX = REWRITE / "gfx"
MANIFEST = GFX / "manifest.json"
OUT = REWRITE / "build" / "gfx"

DEFAULT_PALETTE = ["#000000", "#F5F5F5", "#D98C4A", "#6A8CAF"]
COLS = 16


def parse_palette(values: list[str]) -> list[tuple[int, int, int]]:
    if not isinstance(values, list) or len(values) != 4:
        raise ValueError("palette must contain exactly four #RRGGBB colors")
    palette = []
    for value in values:
        if not isinstance(value, str) or len(value) != 7 or value[0] != "#":
            raise ValueError(f"invalid palette color: {value!r}")
        try:
            palette.append(tuple(int(value[i:i + 2], 16) for i in (1, 3, 5)))
        except ValueError:
            raise ValueError(f"invalid palette color: {value!r}") from None
    return palette


def palette_json(palette: list[tuple[int, int, int]]) -> list[str]:
    return [f"#{r:02X}{g:02X}{b:02X}" for r, g, b in palette]

ASSETS = [
    ("hiscore", "HISCORE.PP1"),
    ("title_top", "TOPCHRS.PP1"),
    ("title_bottom", "BOTCHRS.PP1"),
    ("robin", "ROBINCHR.PP1"),
    ("base", "BASECHR.PP1"),
    ("bead", "BEADCHR.PP1"),
    ("box", "BOXCHR.PP1"),
    ("arch", "ARCHCHR.PP1"),
    ("rock", "ROCKCHR.PP1"),
    ("bed", "BEDCHR.PP1"),
    ("door", "DOORCHR.PP1"),
    ("ok", "OKCHR.PP1"),
    ("cm_logo", "CMLOGO.PP1"),
    ("chrset", "CHRSET.PP1"),
    ("solid", "SOLIDCHR.PP1"),
]

MAP_PALETTE = ["#000000", "#FCA044", "#E45C10", "#A81000"]
HISCORE_PALETTE = ["#3CBCFC", "#F8F8F8", "#FCA044", "#000000"]
TITLE_PALETTE = ["#000000", "#3CBCFC", "#E45C10", "#F8D878"]
ROBIN_PALETTE = ["#000000", "#FCA044", "#00A800", "#A81000"]
CM_PALETTE = ["#F8B8F8", "#F878F8", "#D800CC", "#940084"]

ASSET_PALETTES = {
    "hiscore": HISCORE_PALETTE,
    "ok": HISCORE_PALETTE,
    "title_top": TITLE_PALETTE,
    "title_bottom": TITLE_PALETTE,
    "robin": ROBIN_PALETTE,
    "cm_logo": CM_PALETTE,
    "base": MAP_PALETTE,
    "bead": MAP_PALETTE,
    "box": MAP_PALETTE,
    "arch": MAP_PALETTE,
    "rock": MAP_PALETTE,
    "bed": MAP_PALETTE,
    "door": MAP_PALETTE,
    "chrset": MAP_PALETTE,
    "solid": MAP_PALETTE,
}

FC1 = [1, 0, 0, 0]
FC2 = [2, 2, 1, 1]
FC3 = [3, 3, 3, 2]
F1L = [2, 0xFF, 0, 0]
F1H = FC3
F2L = FC1
F2H = [3, 3, 0xFF, 1]
F3L = FC1
F3H = FC2
INF = 10**9


class Bits:
    def __init__(self, data: bytes, pos: int = 0):
        self.data = data
        self.pos = pos
        self.mask = 0x80

    def bit(self) -> int:
        carry = self.mask >> 7
        self.mask = (self.mask << 1) & 0xFF
        if self.mask == 0:
            self.mask = self.data[self.pos]
            self.pos += 1
            carry = self.mask >> 7
            self.mask = ((self.mask << 1) | 1) & 0xFF
        return carry

    def bits2(self) -> int:
        return (self.bit() << 1) | self.bit()


def t1(color: int, variant: int) -> tuple[int, list[int]]:
    if variant == 0:
        return FC1[color], [1]
    if variant == 1:
        return FC3[color], [0, 1]
    return FC2[color], [0, 0]


def t3(color: int, variant: int) -> tuple[int, int, int, list[int]]:
    value, bits = t1(color, variant)
    if value == 0:
        low, high = FC2[color], FC3[color]
    elif value == 1:
        low, high = F1L[color], F1H[color]
    elif value == 2:
        low, high = F2L[color], F2H[color]
    else:
        low, high = F3L[color], F3H[color]
    return value, low, high, bits


def make_options(color: int) -> list[dict]:
    options = []
    options.append({
        "type": 0,
        "bits": [0, 0],
        "fol1": None,
        "fol2": None,
        "fol3": None,
        "cost": [0 if nxt == color else INF for nxt in range(4)],
    })
    for variant in range(3):
        fol1, bits = t1(color, variant)
        options.append({
            "type": 1,
            "bits": [0, 1] + bits,
            "fol1": fol1,
            "fol2": None,
            "fol3": None,
            "cost": [1 if nxt == color else (2 if nxt == fol1 else INF)
                     for nxt in range(4)],
        })
    for variant in range(3):
        fol1, low, high, bits = t3(color, variant)
        for select_high in (0, 1):
            fol2 = high if select_high else low
            options.append({
                "type": 2,
                "bits": [1, 0] + bits + [select_high],
                "fol1": fol1,
                "fol2": fol2,
                "fol3": None,
                "cost": [1 if nxt == color
                         else (2 if nxt in (fol1, fol2) else INF)
                         for nxt in range(4)],
            })
    for variant in range(3):
        fol1, low, high, bits = t3(color, variant)
        options.append({
            "type": 3,
            "bits": [1, 1] + bits,
            "fol1": fol1,
            "fol2": low,
            "fol3": high,
            "cost": [1 if nxt == color
                     else (2 if nxt == fol1
                           else (3 if nxt in (low, high) else INF))
                     for nxt in range(4)],
        })
    return options


OPTIONS = [make_options(color) for color in range(4)]


def emit_transition(bits: list[int], option: dict, color: int, nxt: int) -> None:
    kind = option["type"]
    if kind == 0:
        if nxt != color:
            raise ValueError("type 0 cannot change colour")
        return
    if kind == 1:
        if nxt == color:
            bits.append(1)
        elif nxt == option["fol1"]:
            bits.append(0)
        else:
            raise ValueError("type 1 transition")
        return
    if kind == 2:
        if nxt == color:
            bits.append(1)
        elif nxt == option["fol2"]:
            bits.extend((0, 1))
        elif nxt == option["fol1"]:
            bits.extend((0, 0))
        else:
            raise ValueError("type 2 transition")
        return
    if nxt == color:
        bits.append(1)
    elif nxt == option["fol1"]:
        bits.extend((0, 1))
    elif nxt == option["fol3"]:
        bits.extend((0, 0, 1))
    elif nxt == option["fol2"]:
        bits.extend((0, 0, 0))
    else:
        raise ValueError("type 3 transition")


def decode_pp1(data: bytes) -> tuple[bytes, int]:
    count = data[0] or 256
    reader = Bits(data, 1)
    types = [0] * 4
    fol1 = [0] * 4
    fol2 = [0] * 4
    fol3 = [0] * 4
    out = bytearray()
    previous = None

    def read_t1(color: int) -> int:
        if reader.bit():
            return FC1[color]
        if reader.bit():
            return FC3[color]
        return FC2[color]

    def read_t3(color: int) -> int:
        value = read_t1(color)
        fol1[color] = value
        low, high = [(FC2, FC3), (F1L, F1H), (F2L, F2H), (F3L, F3H)][value]
        fol2[color] = low[color]
        return high[color]

    for _ in range(count):
        if reader.bit() == 0:
            for color in (3, 2, 1, 0):
                kind = reader.bits2()
                types[color] = kind
                if kind == 0:
                    continue
                if kind == 1:
                    fol1[color] = read_t1(color)
                elif kind == 2:
                    value = read_t3(color)
                    if reader.bit():
                        fol2[color] = value
                else:
                    fol3[color] = read_t3(color)
        rows = [0] * 8
        for line in range(8):
            if reader.bit():
                plane0, plane1 = previous
            else:
                color = reader.bits2()
                plane0 = color
                plane1 = (color >> 1) | 2
                for _ in range(7):
                    kind = types[color]
                    if kind == 1:
                        if reader.bit() == 0:
                            color = fol1[color]
                    elif kind == 2:
                        if reader.bit() == 0:
                            color = fol2[color] if reader.bit() else fol1[color]
                    elif kind == 3:
                        if reader.bit() == 0:
                            if reader.bit() == 0:
                                color = fol3[color] if reader.bit() else fol2[color]
                            else:
                                color = fol1[color]
                    plane0 = ((plane0 << 1) | (color & 1)) & 0xFF
                    plane1 = ((plane1 << 1) | (color >> 1)) & 0xFF
            previous = (plane0, plane1)
            rows[line] = plane1
            out.append(plane0)
        out.extend(rows)
    return bytes(out), reader.pos


def encode_pp1(raw: bytes) -> bytes:
    if len(raw) % 16 or not raw:
        raise ValueError("raw CHR must contain 16-byte tiles")
    count = len(raw) // 16
    if count > 256:
        raise ValueError("PP1 supports at most 256 tiles")

    pixels = []
    for tile in range(count):
        rows = []
        data = raw[tile * 16:(tile + 1) * 16]
        for line in range(8):
            low = data[line]
            high = data[line + 8]
            rows.append([((low >> (7 - x)) & 1) | (((high >> (7 - x)) & 1) << 1)
                         for x in range(8)])
        pixels.append(rows)

    repeat = [[False] * 8 for _ in range(count)]
    counts = [[[0] * 4 for _ in range(4)] for _ in range(count)]
    base = [0] * count
    previous = None
    for tile in range(count):
        for line in range(8):
            row = pixels[tile][line]
            if previous is not None and row == previous:
                repeat[tile][line] = True
                base[tile] += 1
            else:
                base[tile] += 2
                for x in range(7):
                    counts[tile][row[x]][row[x + 1]] += 1
            previous = row

    contrib = [[[0] * 13 for _ in range(4)] for _ in range(count)]
    for tile in range(count):
        for color in range(4):
            for index, option in enumerate(OPTIONS[color]):
                cost = 0
                for nxt in range(4):
                    amount = counts[tile][color][nxt]
                    if amount:
                        step = option["cost"][nxt]
                        if step >= INF:
                            cost = INF
                            break
                        cost += amount * step
                contrib[tile][color][index] = cost

    dp = [INF] * (count + 1)
    previous_group = [-1] * (count + 1)
    dp[0] = 0
    for start in range(count):
        if dp[start] >= INF:
            continue
        cumulative = [[0] * 13 for _ in range(4)]
        base_sum = 0
        for end in range(start, count):
            base_sum += base[end]
            for color in range(4):
                total = cumulative[color]
                add = contrib[end][color]
                for index in range(13):
                    total[index] += add[index]
            group = 1 + (end - start) + base_sum
            ok = True
            for color in range(4):
                best = INF
                for index, option in enumerate(OPTIONS[color]):
                    value = len(option["bits"]) + cumulative[color][index]
                    if value < best:
                        best = value
                if best >= INF:
                    ok = False
                    break
                group += best
            if ok and dp[start] + group < dp[end + 1]:
                dp[end + 1] = dp[start] + group
                previous_group[end + 1] = start

    if dp[count] >= INF:
        raise ValueError("could not encode tile set")
    groups = []
    end = count
    while end > 0:
        start = previous_group[end]
        if start < 0:
            raise ValueError("invalid group chain")
        groups.append((start, end))
        end = start
    groups.reverse()

    bits = []
    for start, end in groups:
        cumulative = [[0] * 13 for _ in range(4)]
        for tile in range(start, end):
            for color in range(4):
                for index in range(13):
                    cumulative[color][index] += contrib[tile][color][index]
        chosen = [0] * 4
        for color in range(4):
            best = INF
            for index, option in enumerate(OPTIONS[color]):
                value = len(option["bits"]) + cumulative[color][index]
                if value < best:
                    best = value
                    chosen[color] = index
        header = []
        for color in (3, 2, 1, 0):
            header.extend(OPTIONS[color][chosen[color]]["bits"])
        for tile in range(start, end):
            if tile == start:
                bits.append(0)
                bits.extend(header)
            else:
                bits.append(1)
            for line in range(8):
                if repeat[tile][line]:
                    bits.append(1)
                    continue
                bits.append(0)
                row = pixels[tile][line]
                bits.append((row[0] >> 1) & 1)
                bits.append(row[0] & 1)
                for x in range(7):
                    color = row[x]
                    emit_transition(bits, OPTIONS[color][chosen[color]],
                                    color, row[x + 1])

    out = bytearray([count & 0xFF])
    for offset in range(0, len(bits), 8):
        chunk = bits[offset:offset + 8]
        value = 0
        for bit in chunk:
            value = (value << 1) | bit
        out.append(value << (8 - len(chunk)))
    decoded, _ = decode_pp1(bytes(out))
    if decoded != raw:
        raise ValueError("PP1 encoder round-trip failed")
    return bytes(out)


def tile_pixels(data: bytes, tile: int) -> list[list[int]]:
    rows = []
    for line in range(8):
        low = data[tile * 16 + line]
        high = data[tile * 16 + line + 8]
        rows.append([((low >> (7 - x)) & 1) | (((high >> (7 - x)) & 1) << 1)
                     for x in range(8)])
    return rows


def raw_to_png(raw: bytes, path: Path, cols: int,
               palette: list[tuple[int, int, int]]) -> None:
    count = len(raw) // 16
    rows = (count + cols - 1) // cols
    image = Image.new("RGB", (cols * 8, rows * 8), palette[0])
    pixels = image.load()
    for tile in range(count):
        tx = (tile % cols) * 8
        ty = (tile // cols) * 8
        for line, row in enumerate(tile_pixels(raw, tile)):
            for x, color in enumerate(row):
                pixels[tx + x, ty + line] = palette[color]
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, compress_level=9)


def png_to_raw(path: Path, count: int, cols: int,
               palette: list[tuple[int, int, int]]) -> bytes:
    color_index = {color: i for i, color in enumerate(palette)}
    image = Image.open(path).convert("RGB")
    rows = (count + cols - 1) // cols
    expected = (cols * 8, rows * 8)
    if image.size != expected:
        raise ValueError(f"{path}: expected {expected[0]}x{expected[1]}, "
                         f"got {image.width}x{image.height}")
    pixels = image.load()
    raw = bytearray()
    for tile in range(count):
        tx = (tile % cols) * 8
        ty = (tile // cols) * 8
        plane0 = [0] * 8
        plane1 = [0] * 8
        for line in range(8):
            for x in range(8):
                color = color_index.get(pixels[tx + x, ty + line])
                if color is None:
                    raise ValueError(
                        f"{path}: pixel {(tx + x, ty + line)} is not one of "
                        f"{palette_json(palette)}")
                plane0[line] |= ((color & 1) << (7 - x))
                plane1[line] |= (((color >> 1) & 1) << (7 - x))
        raw.extend(plane0)
        raw.extend(plane1)
    return bytes(raw)


def load_manifest() -> dict:
    if not MANIFEST.exists():
        return {}
    try:
        document = json.loads(MANIFEST.read_text())
    except (OSError, ValueError) as exc:
        raise ValueError(f"{MANIFEST}: {exc}") from None
    if not isinstance(document, dict):
        raise ValueError(f"{MANIFEST}: expected a JSON object")
    return document


def read_palette() -> list[tuple[int, int, int]]:
    return parse_palette(load_manifest().get("palette", DEFAULT_PALETTE))


def read_asset_palettes() -> dict[str, list[tuple[int, int, int]]]:
    assets = load_manifest().get("assets", [])
    if not isinstance(assets, list):
        raise ValueError(f"{MANIFEST}: assets must be a list")
    palettes = {}
    for asset in assets:
        if not isinstance(asset, dict):
            raise ValueError(f"{MANIFEST}: each asset must be an object")
        if "palette" not in asset:
            continue
        name = asset.get("name", "<unnamed>")
        try:
            palettes[name] = parse_palette(asset["palette"])
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{MANIFEST}: asset {name!r}: {exc}") from None
    return palettes


def extract() -> None:
    palette = read_palette()
    asset_palettes = read_asset_palettes()
    manifest = []
    GFX.mkdir(parents=True, exist_ok=True)
    for name, source in ASSETS:
        data = (PDS / source).read_bytes()
        raw, _ = decode_pp1(data)
        count = len(raw) // 16
        cols = min(COLS, count)
        png = GFX / f"{name}.png"
        current = asset_palettes.get(name)
        if current is None:
            current = parse_palette(ASSET_PALETTES.get(name,
                                                       palette_json(palette)))
        raw_to_png(raw, png, cols, current)
        assert png_to_raw(png, count, cols, current) == raw, name
        manifest.append({
            "name": name,
            "source": source,
            "png": png.name,
            "tiles": count,
            "cols": cols,
            "palette": palette_json(current),
        })
        print(f"{name}: {count} tiles, {len(data)} -> {png.name}")
    MANIFEST.write_text(json.dumps({
        "palette": palette_json(palette),
        "assets": manifest,
    }, indent=2) + "\n")
    print(f"wrote {MANIFEST.relative_to(ROOT)}")


def build() -> None:
    document = load_manifest()
    if not document:
        raise ValueError(f"{MANIFEST}: missing")
    default_palette = document.get("palette", DEFAULT_PALETTE)
    manifest = document["assets"]
    OUT.mkdir(parents=True, exist_ok=True)
    total = 0
    for asset in manifest:
        palette = parse_palette(asset.get("palette", default_palette))
        path = GFX / asset["png"]
        raw = png_to_raw(path, asset["tiles"], asset["cols"], palette)
        packed = encode_pp1(raw)
        (OUT / f"{asset['name']}.pp1").write_bytes(packed)
        total += len(packed)
    print(f"generated {len(manifest)} PP1 files, {total} bytes")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("extract", "build"))
    args = parser.parse_args()
    if args.command == "extract":
        extract()
    else:
        build()


if __name__ == "__main__":
    main()
