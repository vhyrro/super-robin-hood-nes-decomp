.segment "HEADER"
.byte "NES",$1a,4,0,$21,0,0,0,0,0,0,0,0,0
.include "vars.s"
.include "nes.s"

.segment "PRG0"
.include "bank0/mod.s"

.segment "PRG1"
.include "bank1/mod.s"

.segment "PRG2"
.include "bank2/mod.s"

.segment "PRG3"
.include "bank3/mod.s"
