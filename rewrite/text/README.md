# Translations

This directory allows you to create custom translations and fonts for Super Robin Hood.

To use a translation, use the `LANG` flag when building:

```sh
make LANG=de # builds `de.json`
```

`LANG` defaults to `en`, which builds `text/en.json`.

## File format

```json
{
  "charset": {
    "Ä": 200,
    "Ö": 201,
    "Ü": 202
  },
  "limits": {
    "score": 19
  },
  "high_scores": [
    "ERSTER",
    "ZWEITER",
    "DRITTER",
    "VIERTER",
    "FÜNFTER",
    "SECHSTER",
    "SIEBTER",
    "ACHTER",
    "NEUNTER",
    "ZEHNTER"
  ],
  "messages": {
    "score": "PUNKTE",
    "press_start": "DRÜCKEN\nSTART"
  }
}
```

`messages` is required. `charset`, `limits`, and `high_scores` are optional. `high_scores` must contain ten names, each at most nine characters; shorter names are padded with dots.

`\n` starts a new line. Leading and trailing spaces are preserved because the layouts use them for positioning.

Base glyphs already exist in the font:

- `A`-`Z` = tiles 1-26
- `!` = 27, `?` = 28, `*` = 29, `.` = 30, `:` = 31
- space = 32
- `0`-`9` = tiles 33-42

Any other character must be mapped in `charset` to a tile number from 200 to 255. The text compiler rejects unknown characters, duplicate mappings, lines wider than their limit, and strings of 255 bytes or more.

## Custom glyphs

Tiles 200-255 of the HISCORE font are reserved for translation glyphs. The base font is `gfx/hiscore.png`; tiles 200-255 are at row 12, column 8, counting from zero.

For a language-specific font, create an overlay:

```sh
make font-template LANG=de
```

This writes `text/fonts/de.png`, a 128x32 sheet with 16 tiles per row. The first 56 tiles correspond to font tiles 200-255; the last 8 slots are unused. Draw glyphs there with the same four colors as `gfx/hiscore.png`, then map characters to tiles 200-255 in `charset`.

The overlay is used automatically by `make LANG=de` and `make preview LANG=de`. Without an overlay, the base HISCORE tiles are used.

Only 56 extra tiles are available. If a language needs more, split the font or reduce the character set; the compiler will reject tiles outside 200-255.

The Polish pack is a complete example: `text/pl.json` uses `Ą Ć Ę Ł Ń Ó Ś Ź Ż`, and `text/fonts/pl.png` contains the matching glyphs in tiles 200-208.

`make extract-gfx` recreates every base PNG from the original PP1 files and overwrites edits. It does not touch `text/fonts/`.

## Preview

```sh
make preview LANG=de
```

This writes `build/text_preview.png`, showing every message in the selected font, with each line's length and limit. It is a text-layout preview, not a full screen mockup: message positions and graphics still live in the assembly.

## Tests

```sh
make test
```

This builds the current language and runs the Mesen test scripts in `tests/`. Set `MESEN` if `mesen-ce` is not on your `PATH`.

## Untranslated content

The title-screen logo and high-score border graphics are artwork. Proper names and game titles in the credits are intentionally left unchanged. Message text and high-score placeholder names are externalized.
