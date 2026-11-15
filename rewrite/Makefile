CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3
OUT  ?= robinhood.nes
GFX  := $(wildcard gfx/*.png)

all: $(OUT)

build/gfx/.stamp: tools/png2pp1.py gfx/manifest.json $(GFX)
	$(PYTHON) tools/png2pp1.py build
	@touch $@

build/main.o: $(wildcard *.s) $(wildcard bank*/*.s) build/gfx/.stamp
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

$(OUT): build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg --mapfile build/main.map -o $@ build/main.o

extract-gfx:
	$(PYTHON) tools/png2pp1.py extract

clean:
	rm -rf build $(OUT)

.PHONY: all clean extract-gfx
