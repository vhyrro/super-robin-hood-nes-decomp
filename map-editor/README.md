# Super Robin Hood Map Editor

**IMPORTANT**: This is a purely vibe coded project, and thus doesn't uphold my personal standards
for programming. However, it is a fully functional application in its own right.

A small native editor for `rewrite/maps/world.json`.

## Run

```sh
cargo run --release
cd ../rewrite && make
```

## Controls

- Left click: paint the selected block
- Right click: erase
- Alt + left click or the **Pick block from map** button: select the block under the cursor
- Middle click or Space + left click: pan
- Mouse wheel: zoom
- Ctrl/Cmd+S: save
- Ctrl/Cmd+Z: undo
- Revert: restore the original map from `rewrite/maps/mapdata_template.s`
- Ctrl/Cmd+Y or Ctrl/Cmd+Shift+Z: redo
- Right panel **Entities** tab: choose an entity type, then left-click the map once to place it
- Right panel **Objects** tab: select an object to highlight it on the map and edit all of its named fields

The right panel has **Blocks**, **Objects**, and **Entities** tabs. Use the JSON path field and **Import** / **Export** for alternate map files.
