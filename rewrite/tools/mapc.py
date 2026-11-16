#!/usr/bin/env python3
"""Extract and rebuild the editable Super Robin Hood terrain maps."""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP_LABELS = [
    "map_b",
    "map_c",
    "map_d",
    "map_e",
    "map_f",
    "map_g",
    "map_h",
    "map_i",
    "map_j",
    "map_l",
    "map_m",
    "map_n",
    "map_o",
]
PALETTE_NAMES = {
    "PALETTE_LAVA": "Lava",
    "PALETTE_WATER": "Water",
    "PALETTE_DUNGEON": "Dungeon",
    "PALETTE_KITCHEN": "Kitchen",
    "PALETTE_HALL": "Halls",
    "PALETTE_BEDROOM": "Bedroom",
    "PALETTE_CHURCH": "Church",
    "PALETTE_SKY": "Sky",
}
STRIP_ROWS = 14
BANK0_SIZE = 0x3FFE
DEFAULT_BLOCKS = {"empty": 0}
BLOCK_NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
COLOR_TOKEN = re.compile(r"\$[0-9A-Fa-f]{1,2}")
ALPHABET_SYMBOLS = ".#@%&*+-=~^_:;!?/|()[]{}<>,abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


def parse_int(token):
    token = token.strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    return int(token, 0)


def is_byte_line(line):
    return line.split(";", 1)[0].strip().startswith(".byte")


def map_ranges(lines):
    ranges = {}
    labels = []
    for index, line in enumerate(lines):
        match = re.match(r"^(map_[a-o]):\s*$", line)
        if match:
            labels.append((index, match.group(1)))
    for position, (start, label) in enumerate(labels):
        end = labels[position + 1][0] if position + 1 < len(labels) else len(lines)
        ranges[label] = (start, end)
    return ranges


def parse_map_bytes(lines, start, end):
    values = []
    for line in lines[start + 1 : end]:
        code = line.split(";", 1)[0].strip()
        if not code.startswith(".byte"):
            continue
        for token in code[5:].split(","):
            token = token.strip()
            if not token:
                continue
            if not re.fullmatch(r"\$[0-9A-Fa-f]{1,2}", token):
                raise ValueError(f"unsupported map byte {token!r}")
            value = parse_int(token)
            if value > 0xFF:
                raise ValueError(f"map byte out of range: {token}")
            values.append(value)
    return values


def parse_maps(lines):
    ranges = map_ranges(lines)
    return {label: parse_map_bytes(lines, start, end) for label, (start, end) in ranges.items()}


def parse_mapinfo(path):
    lines = path.read_text().splitlines()
    try:
        start = next(i for i, line in enumerate(lines) if line.strip() == "mapinfo:")
        end = next(i for i, line in enumerate(lines[start + 1 :], start + 1) if line.strip() == "tuneforstrip:")
    except StopIteration as exc:
        raise ValueError(f"could not find mapinfo/tuneforstrip in {path}") from exc

    tokens = []
    for line in lines[start + 1 : end]:
        code = line.split(";", 1)[0].strip()
        if not code.startswith(".byte"):
            continue
        tokens.extend(token.strip() for token in code[5:].split(",") if token.strip())

    if len(tokens) % 6:
        raise ValueError("mapinfo does not contain complete six-byte entries")

    info = {}
    for index in range(0, len(tokens), 6):
        entry = tokens[index : index + 6]
        match = re.fullmatch(r"<\((map_[a-o])\s*-\s*14\)", entry[0])
        if not match:
            raise ValueError(f"unexpected mapinfo pointer: {entry[0]}")
        label = match.group(1)
        palette_match = re.fullmatch(r"<\((PALETTE_[A-Z_]+)\)", entry[4])
        if not palette_match or palette_match.group(1) not in PALETTE_NAMES:
            raise ValueError(f"unexpected mapinfo palette: {entry[4]}")
        if label in info:
            raise ValueError(f"duplicate mapinfo entry for {label}")
        info[label] = {
            "offset": parse_int(entry[2]),
            "width": parse_int(entry[3]),
            "palette": palette_match.group(1),
        }

    if list(info) != MAP_LABELS:
        raise ValueError(f"unexpected mapinfo order: {list(info)}")
    return info


def make_map_names(info):
    groups = {}
    for label, entry in info.items():
        groups.setdefault(entry["palette"], []).append(label)

    names = {}
    for palette, labels in groups.items():
        ordered = sorted(labels, key=lambda label: (info[label]["offset"], label))
        base = PALETTE_NAMES[palette]
        for position, label in enumerate(ordered, 1):
            names[label] = base if len(ordered) == 1 else f"{base} {position}"
    return names


def strips_from_bytes(label, values, width):
    expected = width * STRIP_ROWS
    if len(values) != expected:
        raise ValueError(f"{label}: expected {expected} bytes for width {width}, found {len(values)}")
    return [values[index : index + STRIP_ROWS] for index in range(0, len(values), STRIP_ROWS)]


def parse_block(token, alphabet, blocks, label):
    token = token.strip()
    if COLOR_TOKEN.fullmatch(token):
        value = int(token[1:], 16)
    elif token.lower().startswith("0x"):
        try:
            value = int(token, 16)
        except ValueError as exc:
            raise ValueError(f"{label}: invalid block token {token!r}") from exc
    elif token.isdigit():
        value = int(token, 10)
    elif token in alphabet:
        value = alphabet[token]
    elif token in blocks:
        value = blocks[token]
    else:
        raise ValueError(f"{label}: unknown block token {token!r}")
    if not 0 <= value <= 0xFF:
        raise ValueError(f"{label}: block {token!r} is outside 0..255")
    return value


def parse_symbol_row(row, alphabet, label, row_index):
    values = []
    index = 0
    while index < len(row):
        symbol = row[index]
        if symbol == "$":
            token = row[index : index + 3]
            if not COLOR_TOKEN.fullmatch(token):
                raise ValueError(f"{label}: row {row_index} has an invalid $XX escape at column {index}")
            values.append(int(token[1:], 16))
            index += 3
            continue
        if symbol not in alphabet:
            raise ValueError(f"{label}: row {row_index} symbol {symbol!r} is not in the map alphabet")
        values.append(alphabet[symbol])
        index += 1
    return values


def parse_row(row, alphabet, blocks, label, row_index):
    if any(character.isspace() for character in row):
        return [
            parse_block(token, alphabet, blocks, label)
            for token in row.split()
        ]
    return parse_symbol_row(row, alphabet, label, row_index)


def validate_blocks(value, path):
    if value is None:
        return dict(DEFAULT_BLOCKS)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: blocks must be an object mapping names to IDs")
    blocks = {}
    for name, block_id in value.items():
        if not isinstance(name, str) or not BLOCK_NAME.fullmatch(name):
            raise ValueError(f"{path}: block name {name!r} must match [A-Za-z_][A-Za-z0-9_]*")
        if not isinstance(block_id, int) or not 0 <= block_id <= 0xFF:
            raise ValueError(f"{path}: block {name!r} must be an integer from 0 to 255")
        blocks[name] = block_id
    return blocks or dict(DEFAULT_BLOCKS)


def validate_alphabet(value, path, label):
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ValueError(f"{path}: {label} alphabet must be an object mapping symbols to IDs")
    alphabet = {}
    for symbol, block_id in value.items():
        if not isinstance(symbol, str) or len(symbol) != 1 or symbol.isspace() or symbol == "$":
            raise ValueError(
                f"{path}: {label} alphabet symbol {symbol!r} must be one non-whitespace character other than '$'"
            )
        if not isinstance(block_id, int) or not 0 <= block_id <= 0xFF:
            raise ValueError(f"{path}: {label} alphabet symbol {symbol!r} must map to an integer from 0 to 255")
        alphabet[symbol] = block_id
    return alphabet


def load_world(path):
    try:
        document = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: {exc}") from exc
    if not isinstance(document, dict) or not isinstance(document.get("maps"), list):
        raise ValueError(f"{path}: expected an object with a maps list")

    blocks = validate_blocks(document.get("blocks"), path)
    maps = []
    seen = set()
    for entry in document["maps"]:
        if not isinstance(entry, dict):
            raise ValueError(f"{path}: each map must be an object")
        label = entry.get("label")
        width = entry.get("width")
        rows = entry.get("rows")
        name = entry.get("name", label)
        if label not in MAP_LABELS:
            raise ValueError(f"{path}: unknown map label {label!r}")
        if label in seen:
            raise ValueError(f"{path}: duplicate map label {label}")
        seen.add(label)
        if not isinstance(name, str) or not name.strip():
            raise ValueError(f"{label}: name must be a non-empty string")
        if not isinstance(width, int) or not 16 <= width <= 255:
            raise ValueError(f"{label}: width must be an integer from 16 to 255")
        if not isinstance(rows, list) or len(rows) != STRIP_ROWS:
            raise ValueError(f"{label}: expected {STRIP_ROWS} rows")
        alphabet = validate_alphabet(entry.get("alphabet"), path, label)
        clean_rows = []
        for row_index, row in enumerate(rows):
            if not isinstance(row, str):
                raise ValueError(f"{label}: row {row_index} must be a string of block IDs or symbols")
            values = parse_row(row, alphabet, blocks, label, row_index)
            if len(values) != width:
                raise ValueError(f"{label}: row {row_index} has {len(values)} blocks, expected {width}")
            clean_rows.append(values)
        maps.append({"label": label, "name": name, "width": width, "alphabet": alphabet, "rows": clean_rows})

    labels = [entry["label"] for entry in maps]
    if labels != MAP_LABELS:
        raise ValueError(f"maps must be ordered as: {', '.join(MAP_LABELS)}")
    names = [entry["name"] for entry in maps]
    if len(names) != len(set(names)):
        raise ValueError("map names must be unique")
    return maps, blocks


def format_world(maps, blocks):
    lines = ["{", '  "blocks": {']
    block_items = list(blocks.items())
    for index, (name, block_id) in enumerate(block_items):
        suffix = "," if index + 1 < len(block_items) else ""
        lines.append(f'    {json.dumps(name)}: {block_id}{suffix}')
    lines.extend(["  },", '  "maps": ['])
    for map_index, entry in enumerate(maps):
        lines.append("    {")
        lines.append(f'      "label": {json.dumps(entry["label"])},')
        lines.append(f'      "name": {json.dumps(entry["name"])},')
        lines.append(f'      "width": {entry["width"]},')
        alphabet = entry.get("alphabet", {})
        if alphabet:
            lines.append('      "alphabet": {')
            alphabet_items = list(alphabet.items())
            for symbol_index, (symbol, block_id) in enumerate(alphabet_items):
                suffix = "," if symbol_index + 1 < len(alphabet_items) else ""
                lines.append(f"        {json.dumps(symbol)}: {block_id}{suffix}")
            lines.append("      },")
        reverse = {}
        for symbol, block_id in alphabet.items():
            reverse.setdefault(block_id, symbol)
        lines.append('      "rows": [')
        for row_index, row in enumerate(entry["rows"]):
            suffix = "," if row_index + 1 < len(entry["rows"]) else ""
            rendered = "".join(reverse.get(value, f"${value:02X}") for value in row)
            lines.append(f"        {json.dumps(rendered)}{suffix}")
        lines.append("      ]")
        lines.append("    }" + ("," if map_index + 1 < len(maps) else ""))
    lines.extend(["  ]", "}"])
    return "\n".join(lines) + "\n"


def read_existing_blocks(path):
    if not path.exists():
        return dict(DEFAULT_BLOCKS)
    try:
        document = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return dict(DEFAULT_BLOCKS)
    if isinstance(document, dict):
        return validate_blocks(document.get("blocks"), path)
    return dict(DEFAULT_BLOCKS)


def read_existing_alphabets(path):
    if not path.exists():
        return {}
    try:
        document = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(document, dict) or not isinstance(document.get("maps"), list):
        return {}
    alphabets = {}
    for entry in document["maps"]:
        if not isinstance(entry, dict):
            continue
        label = entry.get("label")
        if label in MAP_LABELS:
            alphabets[label] = validate_alphabet(entry.get("alphabet"), path, label)
    return alphabets


def read_existing_names(path):
    if not path.exists():
        return {}
    try:
        document = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(document, dict) or not isinstance(document.get("maps"), list):
        return {}
    names = {}
    for entry in document["maps"]:
        if not isinstance(entry, dict):
            continue
        label = entry.get("label")
        name = entry.get("name")
        if label in MAP_LABELS and isinstance(name, str) and name.strip():
            names[label] = name
    return names


def make_alphabet(values, existing=None):
    alphabet = dict(existing or {})
    counts = {}
    for value in values:
        counts[value] = counts.get(value, 0) + 1
    used_symbols = set(alphabet)
    used_ids = set(alphabet.values())

    if 0 in counts and 0 not in used_ids and "." not in used_symbols:
        alphabet["."] = 0
        used_symbols.add(".")
        used_ids.add(0)

    remaining = [
        value for value in sorted(counts, key=lambda value: (-counts[value], value))
        if value not in used_ids
    ]
    if remaining and "#" not in used_symbols:
        alphabet["#"] = remaining.pop(0)
        used_symbols.add("#")
        used_ids.add(alphabet["#"])

    for value in remaining:
        for symbol in ALPHABET_SYMBOLS:
            if symbol == "." and 0 not in counts:
                continue
            if symbol not in used_symbols:
                alphabet[symbol] = value
                used_symbols.add(symbol)
                used_ids.add(value)
                break
        else:
            break
    return alphabet


def rows_from_strips(strips):
    return [[strip[row] for strip in strips] for row in range(STRIP_ROWS)]


def strips_from_rows(rows):
    width = len(rows[0])
    return [[rows[row][column] for row in range(STRIP_ROWS)] for column in range(width)]


def replace_maps(template, maps):
    lines = template.splitlines()
    ranges = map_ranges(lines)
    values_by_label = {entry["label"]: entry for entry in maps}

    for label in reversed(MAP_LABELS):
        if label not in ranges:
            raise ValueError(f"map label {label} is missing from the template")
        start, end = ranges[label]
        byte_indexes = [index for index in range(start + 1, end) if is_byte_line(lines[index])]
        if not byte_indexes:
            raise ValueError(f"map label {label} has no terrain bytes in the template")
        kept = [line for index, line in enumerate(lines[start + 1 : end], start + 1) if index not in byte_indexes]
        generated = [
            ".byte " + ",".join(f"${value:02X}" for value in strip)
            for strip in values_by_label[label]["strips"]
        ]
        lines = lines[: start + 1] + generated + kept + lines[end:]

    built = "\n".join(lines) + "\n"
    parsed = parse_maps(built.splitlines())
    for entry in maps:
        expected = [value for strip in entry["strips"] for value in strip]
        if parsed[entry["label"]] != expected:
            raise ValueError(f"{entry['label']}: generated terrain does not match the JSON")
    return built


def count_bytes(lines):
    total = 0
    for line in lines:
        code = line.split(";", 1)[0].strip()
        if code.startswith(".byte"):
            total += len([token for token in code[5:].split(",") if token.strip()])
        elif code.startswith(".res"):
            arguments = [part.strip() for part in code[4:].split(",")]
            total += parse_int(arguments[0])
        elif code.startswith(".word"):
            total += 2 * len([token for token in code[5:].split(",") if token.strip()])
    return total


def extract(args):
    template = args.template.read_text()
    info = parse_mapinfo(args.mapinfo)
    widths = {label: entry["width"] for label, entry in info.items()}
    names = make_map_names(info)
    raw_maps = parse_maps(template.splitlines())
    blocks = read_existing_blocks(args.output)
    alphabets = read_existing_alphabets(args.output)
    existing_names = read_existing_names(args.output)

    maps = []
    for label in MAP_LABELS:
        if label not in raw_maps:
            raise ValueError(f"{label} is missing from {args.template}")
        strips = strips_from_bytes(label, raw_maps[label], widths[label])
        rows = rows_from_strips(strips)
        maps.append(
            {
                "label": label,
                "name": existing_names.get(label, names[label]),
                "width": widths[label],
                "alphabet": make_alphabet(
                    [value for row in rows for value in row],
                    alphabets.get(label),
                ),
                "rows": rows,
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(format_world(maps, blocks))
    print(f"extracted {len(maps)} maps, {sum(entry['width'] for entry in maps)} strips to {args.output}")


def build(args):
    maps, _blocks = load_world(args.world)
    info = parse_mapinfo(args.mapinfo)
    built_maps = []
    for entry in maps:
        if entry["width"] != info[entry["label"]]["width"]:
            raise ValueError(
                f"{entry['label']}: width {entry['width']} does not match mapinfo width {info[entry['label']]['width']}"
            )
        built_maps.append(
            {
                "label": entry["label"],
                "width": entry["width"],
                "strips": strips_from_rows(entry["rows"]),
            }
        )

    built = replace_maps(args.template.read_text(), built_maps)
    total = count_bytes(built.splitlines())
    if total > BANK0_SIZE:
        raise ValueError(f"generated bank 0 uses {total} bytes, maximum is {BANK0_SIZE}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(built)
    print(f"built {len(built_maps)} maps into {args.output} ({total} bytes in bank 0)")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    extract_parser = subparsers.add_parser("extract")
    extract_parser.add_argument("--template", type=Path, default=ROOT / "maps/mapdata_template.s")
    extract_parser.add_argument("--mapinfo", type=Path, default=ROOT / "bank3/mapscrol_rou.s")
    extract_parser.add_argument("-o", "--output", type=Path, default=ROOT / "maps/world.json")
    extract_parser.set_defaults(handler=extract)

    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("world", nargs="?", type=Path, default=ROOT / "maps/world.json")
    build_parser.add_argument("--template", type=Path, default=ROOT / "maps/mapdata_template.s")
    build_parser.add_argument("--mapinfo", type=Path, default=ROOT / "bank3/mapscrol_rou.s")
    build_parser.add_argument("-o", "--output", type=Path, default=ROOT / "build/mapdata.s")
    build_parser.set_defaults(handler=build)

    args = parser.parse_args(argv)
    try:
        args.handler(args)
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
