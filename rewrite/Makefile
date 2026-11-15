CA65 ?= ca65
LD65 ?= ld65
OUT  ?= robinhood.nes

all: $(OUT)

build/main.o: $(wildcard *.s) $(wildcard bank*/*.s)
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

$(OUT): build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg --mapfile build/main.map -o $@ build/main.o

clean:
	rm -rf build $(OUT)

.PHONY: all clean
