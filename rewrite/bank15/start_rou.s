START:
sei
cld
ldx #255
txs
NUM = 10
DIF = 128
lda #NUM
sta 114
lda #<(1631 + NUM / 2 * DIF)
sta 112
lda #>(1631 + NUM / 2 * DIF)
sta 113
GHFH:
lda #4
sta 2032
LOCK1:
sta 65520
jsr LOCK2
sta 65521
jsr LOCK2
dec 2032
bne LOCK1
lda 112
sec
sbc #DIF
sta 112
bcs @_1
dec 113
@_1:
dec 114
bne GHFH
sta 65520
jmp PASTLOCK
LOCK2:
ldx 112
ldy 113
bit 255
LOCK3:
dex
bne LOCK3
dey
bne LOCK3
rts
PASTLOCK:
NOPS22:
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
lda #14
sta BANKNO
sta BANK_TBL + 14
jsr SMILEY
jsr CHANGEBANK12ROU
PASTNOPS:
lda CM_POWERUP
pha
lda #14
sta BANKNO
sta BANK_TBL + 14
jsr CM_LOGO
jsr CHANGEBANK12ROU
pla
tax
ldy #0
sty _CONTROL0
sty _CONTROL1
sty ADDRESS
sty ADDRESS + 1
CLEARRAM:
@_2:
lda #0
@_1:
sta (ADDRESS),Y
iny
bne @_1
@_3:
inc ADDRESS + 1
lda ADDRESS + 1
cmp #1
beq @_3
cmp #7
bne @_2
jsr CHANGEBANK13ROU
jsr COPYHISCORESTORAM
jsr CHANGEBANK12ROU
lda #144
sta CONTROL0
sta _CONTROL0
sta SEED
lda #30
sta CONTROL1
sta SEED + 1
jsr TURNINTEROFF1
jsr CHANGEBANK12ROU
lda #10
jsr STARTTUNE
