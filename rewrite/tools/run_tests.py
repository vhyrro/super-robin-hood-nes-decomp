#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
from pathlib import Path

REWRITE = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r"@@([A-Za-z0-9_]+)@@")
SYMBOL = re.compile(r'name="([^"]+)".*?val=0x([0-9A-Fa-f]+)')


def load_symbols(path: Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    return {name: int(value, 16) for name, value in SYMBOL.findall(text)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rom", type=Path, default=REWRITE / "robinhood.nes")
    parser.add_argument("--mesen", default="mesen-ce")
    parser.add_argument("--timeout", type=int, default=45)
    args = parser.parse_args()

    debug_file = REWRITE / "build" / "main.dbg"
    if not debug_file.exists():
        print(f"missing {debug_file}; build the ROM first", file=sys.stderr)
        return 1
    symbols = load_symbols(debug_file)
    rom = args.rom.resolve()
    if not rom.exists():
        print(f"missing ROM {rom}", file=sys.stderr)
        return 1
    tests = sorted((REWRITE / "tests").glob("*.lua"))
    if not tests:
        print("no tests found", file=sys.stderr)
        return 1

    out_dir = REWRITE / "build" / "tests"
    out_dir.mkdir(parents=True, exist_ok=True)
    failed = []
    for test in tests:
        def replace(match):
            name = match.group(1)
            if name not in symbols:
                raise ValueError(f"{test.name}: unknown symbol {name!r}")
            return f"0x{symbols[name]:04X}"

        script = out_dir / test.name
        try:
            script_text = TOKEN.sub(replace, test.read_text(encoding="utf-8"))
        except ValueError as exc:
            print(f"FAIL {test.name}: {exc}")
            failed.append(test.name)
            continue
        script.write_text(script_text, encoding="utf-8")
        command = [
            args.mesen,
            "--testRunner",
            "--novideo",
            "--noaudio",
            "--noinput",
            f"--timeout={args.timeout}",
            str(script),
            str(rom),
        ]
        try:
            result = subprocess.run(command, cwd=REWRITE, text=True,
                                    capture_output=True)
        except OSError as exc:
            print(f"FAIL {test.name}: {exc}")
            failed.append(test.name)
            continue
        if result.returncode == 0:
            print(f"PASS {test.name}")
        else:
            print(f"FAIL {test.name} (exit {result.returncode})")
            if result.stdout:
                print(result.stdout, end="")
            if result.stderr:
                print(result.stderr, end="", file=sys.stderr)
            failed.append(test.name)

    if failed:
        print(f"{len(failed)} test(s) failed: {', '.join(failed)}")
        return 1
    print(f"{len(tests)} test(s) passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
