use std::fs;
use std::path::Path;

use anyhow::{Context, Result};

use crate::bank::Bank;
use crate::transpiler::Transpiled;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Layout {
    Source,
    SplitAtBank14,
}

pub struct SourceFile {
    pub name: &'static str,
    pub bank: Bank,
    pub layout: Layout,
}

pub const FILES: &[SourceFile] = &[
    SourceFile {
        name: "MACROS.PDS",
        bank: Bank::Prg12,
        layout: Layout::Source,
    },
    SourceFile {
        name: "VARS.PDS",
        bank: Bank::Prg12,
        layout: Layout::Source,
    },
    SourceFile {
        name: "MAPDATA.DAT",
        bank: Bank::Prg12,
        layout: Layout::Source,
    },
    SourceFile {
        name: "BANK12.PDS",
        bank: Bank::Prg12,
        layout: Layout::Source,
    },
    SourceFile {
        name: "MACROS.MUS",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "JONSBIT.MUS",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "MUSIC1.MUS",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "HISCORE.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "TITLE.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "SOUNDFX.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "NEWBITS.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "EXPLODE.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "PRTROBIN.ROU",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "BANK13.PDS",
        bank: Bank::Prg13,
        layout: Layout::Source,
    },
    SourceFile {
        name: "CMLOGO.ROU",
        bank: Bank::Prg14,
        layout: Layout::Source,
    },
    SourceFile {
        name: "CHRSETS.CHR",
        bank: Bank::Prg14,
        layout: Layout::SplitAtBank14,
    },
    SourceFile {
        name: "BANK14.PDS",
        bank: Bank::Prg15,
        layout: Layout::SplitAtBank14,
    },
    SourceFile {
        name: "TIMINGS.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "START.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "MAINLOOP.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "INTERUPT.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "CONTROL.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "XTRACONT.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "XTRAROUS.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "ONSCREEN.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "SPRITESD.DAT",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "SPRITESR.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "PRTMESS.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "UNPACK.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "GENERAL.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "MAPSCROL.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
    SourceFile {
        name: "ENDCODE.ROU",
        bank: Bank::Prg15,
        layout: Layout::Source,
    },
];

const NES_INC: &str = r#"; NES hardware constants
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014
APU_STATUS = $4015
APU_SND1  = $4000
APU_SND2  = $4001
APU_TRI   = $4008
APU_NOISE = $400C
APU_DMC   = $4010
JOY1      = $4016
JOY2      = $4017
"#;

const LINKER_CONFIG: &str = r#"MEMORY {
    ZP:     start = $0000, size = $0100, type = rw, file = "";
    RAM:    start = $0200, size = $0600, type = rw, file = "";
    HDR:    start = $0000, size = $0010, file = %O, fill = yes, fillval = $00;
    PRG12:  start = $8000, size = $4000, file = %O, fill = yes, fillval = $FF;
    PRG13:  start = $8000, size = $06DA, file = %O, fill = yes, fillval = $FF;
    PRG13B: start = $86DA, size = $3926, file = %O, fill = yes, fillval = $FF;
    PRG14:  start = $8000, size = $4000, file = %O, fill = yes, fillval = $FF;
    PRGBASE: start = $C000, size = $0004, file = %O, fill = yes, fillval = $37;
    PRG15:  start = $C004, size = $3FF5, file = %O, fill = yes, fillval = $FF;
    VECTORS: start = $FFF9, size = $0007, file = %O, fill = yes, fillval = $FF;
}
SEGMENTS {
    HEADER:  load = HDR,   type = ro;
    PRG12:   load = PRG12, type = ro;
    PRG13:   load = PRG13, type = ro;
    PRG13B:  load = PRG13B, type = ro;
    PRG14:   load = PRG14, type = ro;
    PRGBASE: load = PRGBASE, type = ro;
    PRG15:   load = PRG15, type = ro;
    VECTORS: load = VECTORS, type = ro;
    ZEROPAGE: load = ZP,   type = zp;
    BSS:     load = RAM,   type = bss;
}
"#;

const MAKEFILE: &str = r#"CA65 ?= ca65
LD65 ?= ld65
OUT  ?= robinhood.nes

all: $(OUT)

build/main.o: main.s $(wildcard *.inc) nes.inc
	@mkdir -p build
	$(CA65) -g -t none -o $@ main.s

$(OUT): build/main.o robinhood.cfg
	$(LD65) -C robinhood.cfg --dbgfile build/main.dbg -o $@ build/main.o

clean:
	rm -rf build $(OUT)

.PHONY: all clean
"#;

pub fn write(directory: &Path, transpiled: &Transpiled) -> Result<()> {
    write_file(&directory.join("nes.inc"), NES_INC)?;
    write_file(&directory.join("robinhood.cfg"), LINKER_CONFIG)?;
    write_file(&directory.join("Makefile"), MAKEFILE)?;

    for bank in Bank::ALL {
        write_file(
            &directory.join(format!("bank{}.inc", bank.number())),
            &transpiled.bank_source(bank),
        )?;
    }

    write_file(&directory.join("main.s"), &assemble_main())?;

    Ok(())
}

fn write_file(path: &Path, contents: &str) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }

    fs::write(path, contents).with_context(|| format!("failed to write {}", path.display()))
}

fn assemble_main() -> String {
    let mut source = String::from("; Generated by pds2ca65\n");
    source.push_str(".segment \"HEADER\"\n");
    source.push_str(".byte \"NES\",$1a,4,0,$81,$e0,0,0,0,0,0,0,0,0\n");
    source.push_str(".include \"nes.inc\"\n");
    source.push_str(".segment \"PRGBASE\"\n.byte $FE,$FF,$FF,$FF\n");

    for bank in Bank::ALL {
        source.push_str(&format!(
            "\n.segment \"{}\"\n.include \"bank{}.inc\"\n",
            bank.segment(),
            bank.number()
        ));
    }

    source
}
