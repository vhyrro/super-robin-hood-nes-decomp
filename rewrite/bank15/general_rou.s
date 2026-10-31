AMASK = 128
BMASK = 64
SELMASK = 32
STMASK = 16
UMASK = 8
DMASK = 4
LMASK = 2
RMASK = 1
READKEYPADS:
ldx #1
stx 16406
dex
stx 16406
PADLOOP1:
lda PAD
sta DEBOUNCE
ldy #8
PADLOOP2:
lda 16406
lsr A
rol PAD
dey
bne PADLOOP2
rts
RANDOM:
lda COUNTER
ror A
eor SEED + 1
eor SEED
rol A
ror SEED + 2
sta SEED + 1
eor #255
rol A
eor SEED
sta SEED
rts
TESTSTARTKEY:
lda #STMASK
bne GENERALKEYTEST
TESTSELECTKEY:
lda #SELMASK
bne GENERALKEYTEST
TESTANYKEY:
lda #255
GENERALKEYTEST:
sta TEMP
lda PAD
and TEMP
beq @_3
lda DEBOUNCE
and TEMP1
beq @_4
lda #0
@_3:
rts
@_4:
lda #1
rts
CHECKFORPAUSEKEY:
lda DONTPAUSE
bne @_7
@_6:
lda PAD
and #STMASK
beq @_1
lda DEBOUNCE
and #STMASK
bne @_1
lda PAUSE
@_7:
eor #1
sta PAUSE
beq @_2
lda #0
sta 16405
rts
@_2:
lda #15
sta 16405
@_1:
rts
CLEARFULLSPRITEBLOCK:
ldx #0
jsr CLEARSPRITEBLOCK1
SENDSPRITEBLOCK:
lda #0
sta _SPRITEADDR
lda #>(SPRITEBLOCK)
sta 16404
rts
TURNOFFTUNE:
lda #0
STARTTUNE:
tay
lda BANKNO
pha
jsr CHANGEBANK13ROU
lda #0
sta 16405
tya
jsr START_MUSIC
pla
jmp CHANGEBANKROU
SOUNDFX:
sta FFX_AD1L
txa
pha
tya
pha
lda BANKNO
pha
jsr CHANGEBANK13ROU
lda FFX_AD1L
jsr FX_SETUP
pla
jsr CHANGEBANKROU
pla
tay
pla
tax
rts
CHANGEBANKROU:
sta BANKNO
CHANGEBANKROU1:
tax
sta BANK_TBL,X
rts
CLEARSCR:
.byte $A0
.byte $00
.byte $FB
.byte $40
.byte $FB
.byte $20
.byte $00
.byte $FA
.byte $FA
.byte $FF
CLEARSPRITEBLOCK:
ldx #4
CLEARSPRITEBLOCK1:
stx SPRITEBLOCKPOINTER
@_1:
lda #254
sta SPRITEBLOCK,X
lda #0
sta SPRITEBLOCK + 3,X
sta SPRITEBLOCK + 2,X
sta SPRITEBLOCK + 1,X
inx
inx
inx
inx
bne @_1
rts
TURNINTERON1:
asl FLYFLAG
@M968__1:
bit FLYFLAG
bpl @M968__1
jsr SENDSPRITEBLOCK
TURNINTERON:
lda #255
sta DEBOUNCE
ldx X_SCROLL
ldy Y_SCROLL
stx _SCROLLCON
sty _SCROLLCON
lda CONTROL0
ldy CONTROL1
sta _CONTROL0
sty _CONTROL1
lda #255
sta INTERON
rts
TURNINTEROFFFADE:
lda #0
sta FINISHEDLOOP
lda #252
sta FADECOUNTER
FADEOFFSCREEN:
asl FLYFLAG
@M969__1:
bit FLYFLAG
bpl @M969__1
lda FADECOUNTER
cmp #255
bne FADEOFFSCREEN
jmp TURNINTEROFF1
TURNINTEROFF:
asl FLYFLAG
@M970__1:
bit FLYFLAG
bpl @M970__1
TURNINTEROFF1:
lda #0
sta FINISHEDLOOP
sta INTERON
sta _CONTROL1
sta X_SCROLL
sta Y_SCROLL
sta _SCROLLCON
sta _SCROLLCON
sta VRAMPOINTER
sta PAUSE
lda #30
sta CONTROL1
lda #144
sta CONTROL0
sta _CONTROL0
jmp CLEARFULLSPRITEBLOCK
ADDTOLIVES:
inc LIVES
rts
HIGHBITADD:
.byte $FF
.byte $00
.byte $00
PRINTLIVES:
lda LIVES
beq @_2
bmi @_2
cmp #3
bcc @_3
lda #3
@_3:
sta TEMP9
lda #0 + 64
sta TEMP
lda #32 - YDISPLACE
sta ADDRESS5
@_1:
ldy ADDRESS5
ldx #240
lda #1
jsr POKESPRITE2BY2
lda ADDRESS5
clc
adc #24
sta ADDRESS5
dec TEMP9
bne @_1
@_2:
rts
PRINTSCORE:
lda #128 - 10 * 3 - 4
ldy #0
@_3:
ldx SCORE,Y
bne @_4
clc
adc #5
iny
cpy #3
bne @_3
@_4:
sta TEMP
@_2:
lda SCORE,Y
clc
adc #128
ldx SPRITEBLOCKPOINTER
beq @_1
sta SPRITEBLOCK + 1,X
lda TEMP1
lda #2
sta SPRITEBLOCK + 2,X
lda TEMP
sta SPRITEBLOCK + 3,X
clc
adc #10
sta TEMP
lda #16
sta SPRITEBLOCK + 0,X
txa
clc
adc #4
sta SPRITEBLOCKPOINTER
iny
cpy #6
bne @_2
@_1:
rts
ADDTOSCORE:
sty TEMPY
pha
lsr
lsr
lsr
lsr
tay
pla
and #15
ADDTOLP:
clc
adc SCORE,Y
sta SCORE,Y
cmp #10
bcc ENDUPDATESCORE
sec
sbc #10
sta SCORE,Y
lda #1
dey
bpl ADDTOLP
ENDUPDATESCORE:
ldy TEMPY
rts
RESETSCORE:
ldy #6
@_1:
lda #0
sta SCORE,Y
lda #8
sta TREASURES,Y
dey
bpl @_1
rts
ADDTOHEARTS:
lda HEARTS
clc
adc #1
sta HEARTS
cmp #5
bcc @_2
inc LIVES
clc
adc #($FD)
sta HEARTS
lda #EXTRALIFEFX
jsr SOUNDFX
@_2:
rts
SUBFROMHEARTS:
ldy ROBININVINC
beq @_2
rts
@_2:
SUBFROMHEARTS1:
eor #255
clc
adc #1
clc
adc HEARTS
sta HEARTS
ldy #150
sty ROBININVINC
cmp #0
beq KILLYOU1
bpl LITTLEKILL
KILLYOUTOTALLY:
lda #0
sta HEARTS
KILLYOU1:
lda #100
sta KILLED
lda #1
sta TEMP2
lda #0
sta HEARTSTABLE + 0
sta HEARTSTABLE + 16
sta HEARTSTABLE + 32
ldx #32
jsr GOTSTARSX
lda #KILLYOUTOTALLYFX
jmp SOUNDFX
LITTLEKILL:
lda #0
jsr STARTSTARS
lda #KILLYOUFX
jmp SOUNDFX
PRINTHEARTS:
lda #24
sta TEMP
ldy HEARTS
bmi @_1
beq @_1
lda HEARTCOUNTER
bit PAUSE
bne @_3
clc
adc HEARTBEAT - 1,Y
sta HEARTCOUNTER
@_3:
lda HEARTCOUNTER
lsr
lsr
lsr
lsr
lsr
lsr
tax
lda HEARTSDEFS,X
sta TEMP1
@_2:
ldx SPRITEBLOCKPOINTER
beq @_1
lda TEMP1
sta SPRITEBLOCK + 1,X
lda #3
sta SPRITEBLOCK + 2,X
sta SPRITEBLOCK + 2 + 4,X
lda #16
sta SPRITEBLOCK + 3,X
lda TEMP
sta SPRITEBLOCK + 0,X
clc
adc #24
sta TEMP
txa
clc
adc #4
sta SPRITEBLOCKPOINTER
dey
bne @_2
@_1:
rts
HEARTSDEFS:
.byte $8A
.byte $8B
.byte $8C
.byte $8B
HEARTBEAT:
.byte $12
.byte $0E
.byte $0A
.byte $08
.byte $06
.byte $04
.byte $02
TREASPAL:
.byte $01
.byte $01
.byte $02
.byte $01
.byte $01
.byte $03
WAITFORSTARTKEY:
lda FADECOUNTER
cmp #255
beq @_2
cmp #0
bne @_4
lda PAD
and #STMASK
beq @_1
lda DEBOUNCE
and #STMASK
bne @_4
lda SOLIDFOUND
clc
adc #128
sta SOLIDFOUND
@_3:
lda #251
sta FADECOUNTER
bne @_4
@_2:
jsr TURNINTEROFF1
lda #1
rts
@_4:
lda #0
@_1:
rts
