CA65 ?= ca65
LD65 ?= ld65
OUT  ?= robinhood.nes
REF  ?= ../transpiler/out/robinhood.nes

all: $(OUT)

build/main.o: $(wildcard *.s) $(wildcard bank*/*.s)
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

$(OUT): build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg --mapfile build/main.map -o $@ build/main.o

verify: $(OUT)
	@cmp -s $(OUT) $(REF) \
		&& echo "ok: $(OUT) is identical to $(REF)" \
		|| { echo "mismatch: $(OUT) differs from $(REF)"; exit 1; }

clean:
	rm -rf build $(OUT)

.PHONY: all clean verify
