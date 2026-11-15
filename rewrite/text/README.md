# Translations

Text lives in `text/<language>.json`. The build converts it to tile bytes and links it into bank1.

```sh
make LANG=de
```

`LANG` defaults to `en`, which builds `text/en.json`.

## File format

```json
{
  "charset": {
    "Ä": 200,
    "Ö": 201
  },
  "limits": {
    "score": 19
  },
  "messages": {
    "score": "PUNKTE",
    "press_start": "DRÜCKEN\nSTART"
  }
}
```

`messages` is required. `charset` and `limits` are optional.

`\n` starts a new line. Leading and trailing spaces are preserved because the layouts use them for positioning.

Base glyphs already exist in the font:

- `A`-`Z` = tiles 1-26
- `!` = 27, `?` = 28, `*` = 29, `.` = 30, `:` = 31
- space = 32
- `0`-`9` = tiles 33-42

Any other character must be mapped in `charset` to a tile number from 200 to 255. The text compiler rejects unknown characters, duplicate mappings, lines wider than their limit, and strings of 255 bytes or more.

## Custom glyphs

The font is the first part of `gfx/hiscore.png`. Tiles 200-255 (the last 56 tiles) are reserved for translation glyphs.

The sheet uses 16 tiles per row, 8x8 pixels per tile. Tile 200 is row 12, column 8, counting from zero. Draw glyphs with the sheet's four colors, then map characters to those tile numbers in `charset`.

Only 56 extra tiles are available. If a language needs more, split the font or reduce the character set; the compiler will reject tiles outside 200-255.

`make extract-gfx` recreates every PNG from the original PP1 files and overwrites edits. Do not run it after editing assets unless you intend to reset them.

## Untranslated content

The title-screen logo, high-score border graphics, and the default high-score placeholder names (`FIRST` ... `TENTH`) are still artwork/fixed data. The message text itself is fully externalized.
