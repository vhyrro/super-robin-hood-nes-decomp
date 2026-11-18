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
MAPS ?= maps/world.json

PATCHES    ?=
PATCH_DIR  := build/patched
SRC        := Makefile main.s nes.s vars.s robinhood.cfg bank0 bank1 bank2 bank3 gfx maps text tools tests

OPTIMIZED_PATCHES := patches/0000-optimizations.patch patches/0001-nmi-audio-clear.patch patches/0002-raw-first-chr.patch
OPTIMIZED_OUT     := build/robinhood-optimized.nes
HARDCORE_PATCHES  := patches/0000-optimizations.patch patches/0005-bugfix.patch patches/0006-hardcore.patch
HARDCORE_OUT      := build/robinhood-hardcore.nes


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

build/maps: FORCE
	@mkdir -p build
	@if [ "$$(cat $@ 2>/dev/null)" != "$(MAPS)" ]; then printf '%s\n' "$(MAPS)" > $@; fi

build/mapdata.s: build/maps tools/mapc.py $(MAPS) maps/mapdata_template.s maps/objects_template.s
	$(PYTHON) tools/mapc.py build $(MAPS) -o $@ --objects-output build/objects.s

build/objects.s: build/mapdata.s

build/main.o: $(wildcard *.s) $(wildcard bank*/*.s) build/text.s build/gfx/.stamp build/mapdata.s build/objects.s
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

ifeq ($(strip $(PATCHES)),)
$(OUT): FORCE build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg --mapfile build/main.map -o $@ build/main.o
else
$(OUT): FORCE
	@rm -rf $(PATCH_DIR)
	@mkdir -p $(PATCH_DIR)
	@cp -a $(SRC) $(PATCH_DIR)/
	@for p in $(PATCHES); do \
		echo "Applying $$p"; \
		(cd $(PATCH_DIR) && patch -p1 < "$(CURDIR)/$$p"); \
	done
	@$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(OUT))
endif

build/text_preview.png: build/lang build/font tools/textpreview.py $(TEXT) gfx/manifest.json $(GFX) $(wildcard $(FONT))
	$(PYTHON) tools/textpreview.py $(TEXT) -o $@ $(FONT_FLAG)

preview: build/text_preview.png

font-template:
	$(PYTHON) tools/textpreview.py --extract-font $(FONT)

ifeq ($(strip $(PATCHES)),)
test: $(OUT)
	$(PYTHON) tools/run_tests.py --rom "$(OUT)" --mesen "$(MESEN)"
else
test: $(OUT)
	$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(OUT)) test
endif

optimized:
	@rm -rf $(PATCH_DIR)
	@mkdir -p $(PATCH_DIR)
	@cp -a $(SRC) $(PATCH_DIR)/
	@for p in $(OPTIMIZED_PATCHES); do \
		echo "Applying $$p"; \
		(cd $(PATCH_DIR) && patch -p1 < "$(CURDIR)/$$p"); \
	done
	@$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(OPTIMIZED_OUT))

optimized-test: optimized
	@$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(OPTIMIZED_OUT)) test

hardcore:
	@rm -rf $(PATCH_DIR)
	@mkdir -p $(PATCH_DIR)
	@cp -a $(SRC) $(PATCH_DIR)/
	@for p in $(HARDCORE_PATCHES); do \
		echo "Applying $$p"; \
		(cd $(PATCH_DIR) && patch -p1 < "$(CURDIR)/$$p"); \
	done
	@$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(HARDCORE_OUT)) MAPS=maps/hardcore_world.json

hardcore-test: hardcore
	@$(MAKE) -C $(PATCH_DIR) PATCHES= OUT=$(abspath $(HARDCORE_OUT)) MAPS=maps/hardcore_world.json test

extract-gfx:
	$(PYTHON) tools/png2pp1.py extract

extract-maps:
	$(PYTHON) tools/mapc.py extract

clean:
	rm -rf build $(OUT)

FORCE:

.PHONY: all clean extract-gfx extract-maps font-template preview test optimized optimized-test hardcore hardcore-test FORCE
