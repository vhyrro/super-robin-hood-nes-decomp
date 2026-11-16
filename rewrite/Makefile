CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3
MESEN ?= mesen-ce
OUT  ?= robinhood.nes
LANG := en
TEXT := text/$(LANG).json
FONT := text/fonts/$(LANG).png
FONT_FLAG := $(if $(wildcard $(FONT)),--font $(FONT),)
GFX  := $(wildcard gfx/*.png)
MAPS := maps/world.json

all: $(OUT)

build/lang: FORCE
	@mkdir -p build
	@if [ "$$(cat $@ 2>/dev/null)" != "$(LANG)" ]; then printf '%s\n' "$(LANG)" > $@; fi

build/font: FORCE
	@mkdir -p build
	@if [ "$$(cat $@ 2>/dev/null)" != "$(if $(wildcard $(FONT)),$(FONT),-)" ]; then printf '%s\n' "$(if $(wildcard $(FONT)),$(FONT),-)" > $@; fi

build/gfx/.stamp: build/lang build/font tools/png2pp1.py gfx/manifest.json $(GFX) $(wildcard text/fonts/*.png)
	$(PYTHON) tools/png2pp1.py build $(FONT_FLAG)
	@touch $@

build/text.s: build/lang tools/textc.py $(TEXT)
	$(PYTHON) tools/textc.py $(TEXT) -o $@

build/mapdata.s: tools/mapc.py $(MAPS) maps/mapdata_template.s
	$(PYTHON) tools/mapc.py build $(MAPS) -o $@

build/main.o: $(wildcard *.s) $(wildcard bank*/*.s) build/text.s build/gfx/.stamp build/mapdata.s
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

$(OUT): build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg --mapfile build/main.map -o $@ build/main.o

build/text_preview.png: build/lang build/font tools/textpreview.py $(TEXT) gfx/manifest.json $(GFX) $(wildcard $(FONT))
	$(PYTHON) tools/textpreview.py $(TEXT) -o $@ $(FONT_FLAG)

preview: build/text_preview.png

font-template:
	$(PYTHON) tools/textpreview.py --extract-font $(FONT)

test: $(OUT)
	$(PYTHON) tools/run_tests.py --rom "$(OUT)" --mesen "$(MESEN)"

extract-gfx:
	$(PYTHON) tools/png2pp1.py extract

extract-maps:
	$(PYTHON) tools/mapc.py extract

clean:
	rm -rf build $(OUT)

FORCE:

.PHONY: all clean extract-gfx extract-maps font-template preview test FORCE
