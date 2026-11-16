#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

import png2pp1
import textc

REWRITE = Path(__file__).resolve().parents[1]
GFX = REWRITE / "gfx"
MANIFEST = GFX / "manifest.json"
DEFAULT_OUTPUT = REWRITE / "build" / "text_preview.png"


def load_font(font_overlay: Path | None):
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = {asset["name"]: asset for asset in manifest["assets"]}
    asset = assets["hiscore"]
    palette = png2pp1.parse_palette(asset["palette"])
    raw = png2pp1.png_to_raw(GFX / asset["png"], asset["tiles"],
                             asset["cols"], palette)
    if font_overlay is not None:
        raw = png2pp1.apply_font(raw, font_overlay, palette)
    return raw, palette


def tile_image(raw: bytes, tile: int, palette, scale: int) -> Image.Image:
    image = Image.new("RGB", (8, 8), palette[0])
    pixels = image.load()
    for y, row in enumerate(png2pp1.tile_pixels(raw, tile)):
        for x, color in enumerate(row):
            pixels[x, y] = palette[color]
    return image.resize((8 * scale, 8 * scale), Image.NEAREST)


def text_color(palette) -> tuple[int, int, int]:
    red, green, blue = palette[0]
    return (0, 0, 0) if red + green + blue > 384 else (255, 255, 255)


def extract_font(path: Path) -> None:
    raw, palette = load_font(None)
    extra = raw[200 * 16:256 * 16]
    path.parent.mkdir(parents=True, exist_ok=True)
    png2pp1.raw_to_png(extra, path, png2pp1.FONT_COLS, palette)
    print(f"wrote {path}")


def preview(text_path: Path, output: Path, font_overlay: Path | None,
            scale: int) -> None:
    data = textc.load(text_path)
    messages = data.get("messages")
    if not isinstance(messages, dict) or not messages:
        raise ValueError("messages must be a non-empty object")
    charset = textc.charset_map(data.get("charset"))
    limits = textc.limits_map(data.get("limits"))
    raw, palette = load_font(font_overlay)
    tiles = {}
    ink = text_color(palette)
    font = ImageFont.load_default()
    label_height = 12
    pad = 8

    blocks = []
    width = 320
    for key, text in messages.items():
        if not isinstance(key, str) or not textc.KEY_RE.fullmatch(key):
            raise ValueError(f"invalid message key {key!r}")
        if not isinstance(text, str):
            raise ValueError(f"{key}: message must be a string")
        limit = limits.get(key, 32)
        values = textc.encode(text, charset, key, limit)
        lines = []
        line = []
        for value in values:
            if value == 249:
                lines.append(line)
                line = []
            else:
                line.append(value)
        lines.append(line)
        max_length = max(len(line) for line in lines)
        blocks.append((key, lines, max_length, limit))
        width = max(width, max_length * 8 * scale + pad * 2)

    high_scores = data.get("high_scores", textc.DEFAULT_HIGH_SCORES)
    if not isinstance(high_scores, list) or len(high_scores) != 10:
        raise ValueError("high_scores must contain exactly 10 names")
    for index, name in enumerate(high_scores):
        values = textc.encode_name(name, charset, index)
        blocks.append((f"high_scores[{index}]", [values], len(values), 9))
        width = max(width, len(values) * 8 * scale + pad * 2)

    height = pad + label_height
    height += sum(label_height + len(lines) * 8 * scale + pad
                  for _, lines, _, _ in blocks)
    image = Image.new("RGB", (width, height), palette[0])
    draw = ImageDraw.Draw(image)
    y = pad
    for key, lines, max_length, limit in blocks:
        draw.text((pad, y), f"{key}  {max_length}/{limit}", fill=ink, font=font)
        y += label_height
        for line in lines:
            x = pad
            for tile in line:
                tile_img = tiles.get(tile)
                if tile_img is None:
                    tile_img = tile_image(raw, tile, palette, scale)
                    tiles[tile] = tile_img
                image.paste(tile_img, (x, y))
                x += 8 * scale
            y += 8 * scale
        y += pad
        draw.line((0, y, width, y), fill=palette[2])
        y += 1

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, compress_level=9)
    print(f"wrote {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", type=Path)
    parser.add_argument("-o", "--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--font", type=Path)
    parser.add_argument("--extract-font", type=Path)
    parser.add_argument("--scale", type=int, default=3)
    args = parser.parse_args()
    try:
        if args.extract_font is not None:
            extract_font(args.extract_font)
        else:
            if args.input is None:
                parser.error("input is required unless --extract-font is used")
            if args.scale < 1:
                parser.error("--scale must be positive")
            preview(args.input, args.output, args.font, args.scale)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"error: {exc}") from None


if __name__ == "__main__":
    main()
