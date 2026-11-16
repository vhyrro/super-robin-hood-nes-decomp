# Rewrite Data Formats

Reference notes for future extraction/editing work in `rewrite/`.

## Maps

### Current representation

- Editable terrain: `rewrite/maps/world.json`.
- Compiler: `rewrite/tools/mapc.py` emits `rewrite/build/mapdata.s`, which is linked into `PRG0` at `$8000-$BFFD` via `rewrite/bank0/mod.s`.
- Legacy assembly template: `rewrite/maps/mapdata_template.s`. It contains the supporting tables plus the original terrain and is used by `mapc.py extract` and as the table source for `mapc.py build`.
- Original equivalent: `pds_src/src/MAPDATA.DAT`.
- 13 maps: `map_b` through `map_o`; there is no `map_k`. `map_a` aliases `map_b` and contains no data.
- Each map is a sequence of 14-byte strips. A strip is one screen column of 14 metatiles.
- Total terrain: 1,048 strips x 14 = 14,672 bytes.
- Runtime layout is strip-major: `terrain[strip * 14 + row]`.
- The editable JSON is row-major for readability; `mapc.py` transposes it back to strips.
- A byte is a block/metatile ID `$00-$FF`; `$00` is empty.
- Each block is 16x16 pixels, made from four 8x8 CHR tiles.

### Supporting tables

- `block_strip_top_left`, `block_strip_top_right`, `block_strip_bottom_left`, `block_strip_bottom_right`: 256-entry CHR tile lookup tables.
- `block_strip_attributes`: 256-entry 2-bit palette selection.
- `solidchrs`: 256 bytes of packed collision quadrant flags.
- `blockrous`: block-to-object spawn handlers, used by `rewrite/bank3/onscreen_rou.s`.
- `mapinfo`: 13 entries x 6 bytes in `rewrite/bank3/mapscrol_rou.s`. Fields: data pointer, world strip offset, width in strips, palette ID, charset ID.
- `mapheights`: per-map vertical world band, in `maps/mapdata_template.s`.
- `mapchrsdefs`: four CHR-set descriptors, in `maps/mapdata_template.s`.

Important: `mapinfo` stores `map_x - 14`, not `map_x`. The runtime derives `MAX_MAP = width - 16` and uses 8-bit strip/offset arithmetic. Widths currently range from 16 (`map_d`, `map_o`) to 208 (`map_f`).

### Runtime access

- `MAP_NUMBER` selects the `mapinfo` entry.
- `MAP_POINTER` points at the terrain.
- `MAP_STRIP` comes from player/screen X.
- Main readers: `times14table`, `getblockbit`, and `findblock` in `rewrite/bank3/mapscrol_rou.s`.

### Other map-related content

- Variable-length object records: `maprouspointer` / `map1rous` ... `map14rous` in `rewrite/bank3/xtracont_rou.s`.
- 3-byte door records: `doordata` in `xtracont_rou.s`.
- Secret-block lists: `secret_table` / `secret_N` in `rewrite/bank1/newbits_rou.s`.
- Original comments explaining keys, guards, platforms, secrets, and doors are in `pds_src/src/XTRACONT.ROU`.

### Extraction feasibility

Terrain extraction and recompilation are implemented in `mapc.py` and work without runtime changes if map count, order, widths, heights, and labels stay stable. Labels may move within bank0 as long as section order and the `label - 14` pointer convention are preserved.

`mapc.py build` validates JSON structure, map order, strip lengths, block IDs, widths against `mapinfo`, and total bank0 size. It preserves non-terrain lines from the template, including the `.res 8, 3` padding after `map_l`.

Structural edits do require runtime work:

- `PRG0` is full (`$3FFE` used). Adding strips or maps does not fit without banking or compression.
- Width must remain 16..255.
- The 14-row height is baked into `times14table`, rendering, collision, and vertical transitions.
- Adding/reordering maps requires updating `mapinfo`, `mapheights`, `tuneforstrip`, `maprouspointer`, and door/secret references.

### Editable map format

`rewrite/maps/world.json` is the source of truth for terrain. Abbreviated example:

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
      ]
    }
  ]
}
```

- Maps must remain in `map_b`..`map_o` order (13 maps).
- `name` is a unique editor display name and does not affect runtime labels or `mapinfo`.
- Names are derived from the mapinfo palette labels plus the world x offset. Repeated palettes are numbered left-to-right: `Water 1`..`Water 3`, `Church 1`..`Church 2`, `Sky 1`..`Sky 3`; unique areas use `Lava`, `Dungeon`, `Kitchen`, `Halls`, `Bedroom`.
- `width` must match `mapinfo`, and each map has exactly 14 rows, one per screen row.
- Each map's optional `alphabet` maps one-character symbols to block IDs. Symbols are local to each map, so `#` can mean different blocks in different maps. Symbols must be single non-whitespace characters other than `$`.
- A row without whitespace is a compact symbol grid; every character is one block. `$XX` is a fallback escape for an ID without a symbol.
- A row containing whitespace is parsed as separate tokens instead, allowing mixed forms such as `# # $49` and multi-character aliases. Numeric tokens are always IDs; use a compact row if a digit is an alphabet symbol.
- `.` is used for block 0 when present; `#` is the most common non-empty block in auto-generated alphabets.
- `blocks` maps optional multi-character names to IDs, so editors can use aliases such as `"empty": 0` or `"my_wall": 73`.
- There are 89 printable alphabet symbols. Maps with more unique blocks, currently `map_g` and `map_h`, use `$XX` escapes for the remainder.
- The compiler transposes rows to the runtime strip-major layout.
- Supporting block tables, palettes, charset descriptors, and `mapheights` remain in `maps/mapdata_template.s` and `bank3/mapscrol_rou.s`.
- `make` runs `mapc.py build` and links `build/mapdata.s`.
- `make extract-maps` regenerates the JSON from the legacy template and overwrites terrain edits while preserving existing names, per-map alphabets, and `blocks` aliases.

The compiler validates structure, map order, widths, block IDs, alphabet mappings, row lengths, total bank0 size, and the generated terrain. The current extract -> build round trip reproduces the original map bytes exactly. Follow edits with `make` and the existing Mesen smoke tests.

Historical prior art: a Rust map editor existed at git commit `962b7e06` (`map-editor/src/data.rs`, `render.rs`).

## Sprite table

### Current representation

- `spritetable` in `rewrite/bank3/spritesd_dat.s`: 66 big-endian words (132 bytes).
- In the current build it occupies `$E949-$E9CC`; use labels rather than absolute addresses.
- The table is indexed by sprite number. `SPRITE_*` constants are `(label - spritetable) / 2`; code also does arithmetic such as `SPRITE_MORE_LEGS + 3`.
- `spritedefs` follows the table (`$E9CD-$ED5E`, 914 bytes in the current build).

Each sprite starts with a frame count. Each frame contains:

1. Flag byte:
   - bit 7: vertical flip
   - bit 6: horizontal flip
   - bit 5: dx/dy present
   - bit 4: inline tile vs. pointer
   - bit 3: inline 2x2 auto-increment
   - bit 2: use `SPRITE_COLOUR`
   - bits 1-0: palette
2. Optional signed dx/dy bytes.
3. Either one inline base tile (2x2 expands to base+1..+3) or a 16-bit pointer to a character block.
4. Character block: `width << 4 | height`, followed by `width * height` tile bytes.

The renderer is in `rewrite/bank3/spritesr_rou.s`, with `printsprite` / `printspriterev` and window variants. It supports up to 256 table entries through the `spritetable + 256` carry path.

Animation is mostly code, not data: player head/body/legs composition and `spriteheights` in `rewrite/bank1/prtrobin_rou.s`, fire sequence, bat frame bits, barrels, and guard state are in gameplay code. Do not treat those as extractable frame tables in v1.

### Extraction feasibility

Extraction and recompilation are feasible without 6502 changes if generated assembly emits labels for frame pointers. ca65 relocates `<(label)` / `>(label)`. Keep table order and group boundaries stable so every `SPRITE_*` ID and any arithmetic on IDs remains valid.

Runtime changes are only needed for named animations, more than 255 frames per sprite, more than 256 table entries, moving sprite data out of fixed bank3, or changing animation code.

### Recommended editable format

A proposed `rewrite/sprites/frames.json` would contain:

- Ordered groups with explicit stable IDs and frame names.
- Per frame: flips, palette, `use_colour`, dx/dy, and either inline tile/size or a block reference.
- `blocks`: `{ "w": 4, "h": 1, "tiles": [...] }`.

A `rewrite/tools/sprites.py` compiler would:

- `extract`: parse `spritesd_dat.s`, resolve its small expression subset, and write JSON.
- `build`: emit `build/spritesd_dat.s` with the same bits, labels, and `SPRITE_*` aliases.
- Replace the include in `bank3/mod.s` and add Makefile dependencies.

Validation should enforce table size <= 256, frame count <= 255, block dimensions 1..15, exact payload lengths, and stable ID values. Keep the data in bank3; bank3 has only about 377 bytes free in the current build.

Primary round-trip test: extract -> build -> assemble, then compare the linked `PRG3` slice for `spritetable` through the sprite definitions. Follow with the Mesen gameplay test.

## Constraints summary

- Bank0: full; terrain edits must fit.
- Bank3: nearly full; sprite changes must not grow much.
- Do not use PNG as the authoritative map or sprite source; PNGs are rendered previews with palette/scale ambiguity.
- Do not reorder maps or sprite groups without updating every code reference and stable ID.
