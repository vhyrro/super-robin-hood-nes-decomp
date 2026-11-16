#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

BASE = {chr(ord("A") + i): i + 1 for i in range(26)}
BASE.update({"!": 27, "?": 28, "*": 29, ".": 30, ":": 31, " ": 32})
BASE.update({str(i): 33 + i for i in range(10)})

KEY_RE = re.compile(r"^[A-Za-z0-9_]+$")

DEFAULT_HIGH_SCORES = [
    "FIRST", "SECOND", "THIRD", "FOURTH", "FIFTH",
    "SIXTH", "SEVENTH", "EIGHTH", "NINTH", "TENTH",
]
HIGH_SCORE_NAME_SIZE = 9
HIGH_SCORE_NAME_PAD = 30


def load(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"{path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError(f"{path}: top-level value must be an object")
    return data


def charset_map(value):
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ValueError("charset must be an object")
    result = {}
    for char, tile in value.items():
        if not isinstance(char, str) or len(char) != 1:
            raise ValueError(f"charset key {char!r} must be one character")
        if not isinstance(tile, int) or not 200 <= tile <= 255:
            raise ValueError(f"charset[{char!r}] must be a tile number 200..255")
        if char in BASE:
            raise ValueError(f"charset[{char!r}] shadows a base glyph")
        if tile in result.values():
            raise ValueError(f"charset[{char!r}] reuses tile {tile}")
        result[char] = tile
    return result


def limits_map(value):
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ValueError("limits must be an object")
    result = {}
    for key, width in value.items():
        if not isinstance(key, str) or not KEY_RE.fullmatch(key):
            raise ValueError(f"invalid limit key {key!r}")
        if not isinstance(width, int) or width < 1:
            raise ValueError(f"limits[{key!r}] must be a positive integer")
        result[key] = width
    return result


def encode(text, charset, key, limit):
    values = []
    for lineno, line in enumerate(text.split("\n"), 1):
        if len(line) > limit:
            raise ValueError(f"{key}: line {lineno} is {len(line)} chars, limit is {limit}")
        for char in line:
            if char in BASE:
                values.append(BASE[char])
            elif char in charset:
                values.append(charset[char])
            else:
                raise ValueError(f"{key}: line {lineno} has unsupported character {char!r}")
        values.append(249)
    if values:
        values.pop()
    if len(values) >= 255:
        raise ValueError(f"{key}: encoded text is {len(values)} bytes, must be under 255")
    return values


def encode_name(name, charset, index):
    if not isinstance(name, str) or not name:
        raise ValueError(f"high_scores[{index}] must be a non-empty string")
    if len(name) > HIGH_SCORE_NAME_SIZE:
        raise ValueError(f"high_scores[{index}] is {len(name)} chars, max is {HIGH_SCORE_NAME_SIZE}")
    values = []
    for char in name:
        if char in BASE:
            values.append(BASE[char])
        elif char in charset:
            values.append(charset[char])
        else:
            raise ValueError(f"high_scores[{index}] has unsupported character {char!r}")
    return values + [HIGH_SCORE_NAME_PAD] * (HIGH_SCORE_NAME_SIZE - len(values))


def write_asm(messages, high_scores, out_path):
    lines = []
    for key, values in messages:
        lines.append(f"text_{key}:")
        if not values:
            lines.append("    .byte 0")
            continue
        for start in range(0, len(values), 16):
            chunk = ", ".join(str(value) for value in values[start:start + 16])
            lines.append(f"    .byte {chunk}, 0" if start + 16 >= len(values) else f"    .byte {chunk}")
    lines.append("text_high_score_names:")
    for start in range(0, len(high_scores), 16):
        chunk = ", ".join(str(value) for value in high_scores[start:start + 16])
        lines.append(f"    .byte {chunk}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    args = parser.parse_args()

    data = load(args.input)
    raw_messages = data.get("messages")
    if not isinstance(raw_messages, dict) or not raw_messages:
        raise ValueError("messages must be a non-empty object")
    charset = charset_map(data.get("charset"))
    limits = limits_map(data.get("limits"))
    raw_high_scores = data.get("high_scores", DEFAULT_HIGH_SCORES)
    if not isinstance(raw_high_scores, list) or len(raw_high_scores) != 10:
        raise ValueError("high_scores must contain exactly 10 names")

    encoded = []
    for key, text in raw_messages.items():
        if not isinstance(key, str) or not KEY_RE.fullmatch(key):
            raise ValueError(f"invalid message key {key!r}")
        if not isinstance(text, str):
            raise ValueError(f"{key}: message must be a string")
        limit = limits.get(key, 32)
        encoded.append((key, encode(text, charset, key, limit)))
    high_scores = [
        value
        for index, name in enumerate(raw_high_scores)
        for value in encode_name(name, charset, index)
    ]

    write_asm(encoded, high_scores, args.output)


if __name__ == "__main__":
    main()
