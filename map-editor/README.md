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
- Alt + left click: pick a block
- Middle click or Space + left click: pan
- Mouse wheel: zoom
- Ctrl/Cmd+S: save
- Ctrl/Cmd+Z: undo
- Revert: restore the original map from `rewrite/maps/mapdata_template.s`
- Ctrl/Cmd+Y or Ctrl/Cmd+Shift+Z: redo

Use the JSON path field and **Import** / **Export** for alternate map files.
