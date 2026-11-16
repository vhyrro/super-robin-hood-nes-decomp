# Maps

`world.json` holds the editable terrain. Each map is 14 rows, one per screen row, and each row is a compact string of block symbols. A per-map `alphabet` maps those symbols to block IDs.

```json
{
  "blocks": {
    "empty": 0
  },
  "maps": [
    {
      "label": "map_b",
      "name": "Lava",
      "width": 72,
      "alphabet": {
        ".": 0,
        "#": 30,
        "@": 26
      },
      "rows": [
        "@#&%#~@#&%#&@#&%#&...",
        "%#*@#~..*@#*%#*..."
      ],
      "objects": [
        {"type": "key", "id": 21, "x": 37, "y": 56, "door": 249},
        {"type": "water"},
        {"type": "end"}
      ]
    }
  ]
}
```

- Keep the maps in `map_b` through `map_o` order.
- `name` is a unique display name for editors and does not affect the ROM. Names come from the mapinfo palette labels. Repeated areas are numbered left-to-right by their mapinfo world offset: `Water 1`..`Water 3`, `Church 1`..`Church 2`, `Sky 1`..`Sky 3`.
- `width` must match the map's width in `bank3/mapscrol_rou.s`.
- Every map needs exactly 14 rows, and every row must produce exactly `width` blocks.
- `alphabet` maps one-character symbols to block IDs. Symbols are local to each map, so `#` can mean different blocks in different maps. Symbols must be single non-whitespace characters other than `$`.
- `.` is used for empty (block 0) when a map contains it. `#` is the most common non-empty block in generated maps; you can change either mapping.
- Rows normally contain no spaces. Use `$XX` for a block that has no alphabet symbol, such as `$5D` in `map_g` or `$AE` in `map_h`.
- A row containing whitespace is read as tokens instead, so mixed styles work:
  ```json
  "rows": [
    "# # $49 ."
  ]
  ```
  Tokens may be `$XX`/decimal IDs, alphabet symbols, or multi-character names from the global `blocks` table. Numeric tokens are always IDs; use a compact row if a digit is an alphabet symbol.

- The optional global `blocks` table is for multi-character aliases. Add names for blocks you edit often, then use them in token rows:
  ```json
  "blocks": {
    "empty": 0,
    "my_wall": 73
  }
  ```
- `objects` stores extra entities with named fields. `type` is a name: `flash`, `guard`, `platform_h`, `platform_v`, `key`, `cannon`, `secret`, `marionette`, or `water`.
- Field layouts are `flash: x y block timer timer2`, `guard: id x y facing flags speed timer`, `platform_h: id x1_low x1_high x2_low x2_high y`, `platform_v: id x_low x_high y1 y2 y3`, `key: id x y door`, `cannon: x y direction speed timer`, `secret: id x y secret`, and `marionette: id x y`.
- `id` values must be unique within a map and at most 236; IDs 237..255 are reserved for doors. The map editor assigns the lowest free ID when placing an entity.
- Trailing fields may be omitted where the original record is shorter, such as a 4-byte cannon. Any bytes beyond the known layout stay in `data`.
- Fields are written in layout order; position-independent types such as `water` have no fields.
- `{"type": "end"}` terminates the list and must be last.
- `make` compiles `world.json` into `build/mapdata.s` and `build/objects.s`; `bank0/mod.s` and `bank3/xtracont_rou.s` link the generated files.

`mapdata_template.s` contains the block tables and original terrain. It is the compiler template and the source for `make extract-maps`. That command overwrites `world.json`, so do not run it after editing the JSON unless you intend to reset the maps. Existing names, alphabets, and global aliases are preserved when re-extracting; object records are regenerated from `objects_template.s`.

`world.json` currently reproduces the original terrain exactly. Bank 0 is full, so adding strips will not link until map data is compressed or moved.
