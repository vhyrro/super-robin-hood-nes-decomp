# Rewrite

This directory contains a rewrite of the original game with optimizations and quality-of-life features in mind
without affecting the base gameplay at all.

Notable changes include:
1. Easier to read with consistent variable names.
2. Ported to UNROM (mapper 2) instead of Camerica's Mapper 232.
3. Moved a function to an earlier bank to prevent constant bank switching per frame.
4. Removed the "smiley test" which wouldn't even work with a modified codebase.

## Build Instructions

First, extract the PP1 files into PNG graphics:

```sh
make extract-gfx
```

Next, build the actual project:

```sh
make LANG=en MAPS=maps/world.json
```

This builds the game with the original English text and with the original map data. The resulting game can be found at `robinhood.nes`, enjoy!

## (BETA) Speedrunning ROM

I've created a map file that blocks pathways that aren't supposed to be used during a speedrun, letting you quickly learn the correct fastest known route.
It forces you to perform tricks like the hyperjump, wall clips and more to get to Maid Marion as fast as possible.

Build instructions:
```sh
make LANG=en MAPS=maps/speedrunning_tutorial.json
```
