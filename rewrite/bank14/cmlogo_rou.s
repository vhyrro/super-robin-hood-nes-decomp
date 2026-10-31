CM_USERNMI = 1
CM_SPAGE = 768
CM_YEAR = 1993
CM_SYPOS = CM_SPAGE
CM_SDATA = CM_SPAGE + 1
CM_SCTRL = CM_SPAGE + 2
CM_SXPOS = CM_SPAGE + 3
CM_STINDX = 1
CM_COLINDX = 2
CM_YSCRPOS = 3
CM_TIME = 4
CM_STADRL = 5
CM_CODEXPOS = 6
CM_CODEYPOS = 7
CM_TEMP1 = 12
CM_TEMP2 = 13
CM_TEMP3 = 14
CM_TEMP4 = 15
CM_ADR1 = 16
CM_ADR1L = 16
CM_ADR1H = 17
CM_NUPZBUF = 18
CM_LOGO:
ldx #0
stx 8192
stx 8193
ldy #151
lda CM_FLAGS
and #63
cmp #4
ora #64
bcs @POWERUP
cpy CM_POWERUP
beq @RESET
@POWERUP:
sty CM_POWERUP
lda #0
@RESET:
sta CM_FLAGS
jsr CM_CHARACTERS
ldx #0
@_55:
lda #0
sta 0,X
lda #255
sta CM_SPAGE,X
inx
bne @_55
ldx #4
@IN:
lda CM_INITTAB,X
sta CM_YSCRPOS,X
dex
bpl @IN
lda #32
sta 8198
ldx #0
stx 8198
ldy #16
txa
@CV0:
sta 8199
dex
bne @CV0
dey
bne @CV0
@AB2:
lda CM_ABMAP,X
beq @ABDONE
sta 8198
inx
lda CM_ABMAP,X
sta 8198
inx
ldy CM_ABMAP,X
inx
@AB1:
lda CM_ABMAP,X
sta 8199
inx
dey
bne @AB1
beq @AB2
@ABDONE:
lda #35
sta 8198
lda #232
sta 8198
ldy #3
lda #80
@AB5:
ldx #8
@AB6:
sta 8199
dex
bne @AB6
lda #85
dey
bne @AB5
ldy #35
sty 8198
ldx #194 + 8
stx 8198
sta 8199
sta 8199
sta 8199
sta 8199
sty 8198
ldx #205 + 8
stx 8198
lda #5
sta 8199
ldx #19
lda #0
@CSFX:
sta 16384,X
dex
bpl @CSFX
lda #128
sta 8192
CM_LOOP:
jsr CM_VBLANK
lda #15
sta 16405
ldx CM_FRAMES
txa
and #1
sta CM_TEMP1
cpx #CM_NOISESTART
bcs @N2
txa
lsr
bpl @N0
@N2:
txa
lsr
lsr
lsr
tay
lda CM_SFXNOISE - 3,Y
cmp #2
bcs @N0
adc CM_TEMP1
@N0:
sta 16398
ldy #0
sty 16387
dey
sty 16391
sty 16399
lda #21
sta 16396
cpx #CM_NOISESTART
bcc @_670
lda #48
sta 16386
txa
sec
sbc #CM_NOISESTART - 8
eor #255
lsr
lsr
cmp #48
bcs @_11
lda #0
@_11:
ora #16 + 128
sta 16384
cpx #CM_NOISELEN
bcc @_600
lda #16
sta 16396
bne @_600
@_670:
txa
lsr
ora #16 + 128
sta 16384
sta 16388
txa
asl
asl
asl
sta 16386
sta 16390
lda #2
clc
adc CM_TEMP1
sta 16387
sta 16391
@_600:
lda CM_FRAMES
beq @TIMEOUT
bit CM_FLAGS
bvc @CM_LOOP
cmp #64
bcc @CM_LOOP
ldy #1
sty 16406
dey
sty 16406
ldy #8
@J1:
lda 16406
ora 16407
lsr
bcs @TIMEOUT
dey
bne @J1
@CM_LOOP:
jmp CM_LOOP
@TIMEOUT:
lda #0
sta 8192
sta 8193
sta 16405
lda CM_FLAGS
ora #128
sta CM_FLAGS
rts
CM_VBLANK:
lda CM_FRAMES
@_1:
cmp CM_FRAMES
beq @_1
ldx #0
lda #63
sta 8198
stx 8198
ldy #4
@P2:
ldx #7
@P1:
lda CM_PALETTE,X
sta 8199
dex
bpl @P1
dey
bne @P2
ldx CM_COLINDX
ldy #63
sty 8198
lda #17
sta 8198
lda CM_COLFADE,X
bmi @EOF
sta 8199
lda CM_COLFADE + 1,X
sta 8199
lda CM_COLFADE + 2,X
sta 8199
sty 8198
ldy #3
sty 8198
sta 8199
sta 8199
sta 8199
sta 8199
sta 8199
ldy #63
sty 8198
ldy #27
sty 8198
sta 8199
inx
inx
inx
dec CM_TIME
bne @EOF
inc CM_TIME
stx CM_COLINDX
@EOF:
CM_STRIP:
lda #4
sta 8192
lda #33
sta 8198
lda CM_STADRL
sta 8198
inc CM_STADRL
ldx CM_STINDX
ldy CM_STDATA,X
dey
bpl @DONE
@_2:
lda 8199
dey
bmi @_2
@_1:
inx
lda CM_STDATA,X
bmi @_3
sta 8199
bpl @_1
@_3:
stx CM_STINDX
@DONE:
CM_CODEWRITE:
lda CM_SXPOS + 32
cmp #161
bne @NC
lda #33
sta 8198
lda #76 + 64
sta 8198
lda #8
sta 8199
lda #244 + 64 - 256
sta CM_ADR1L
ldy #CM_C1CHR
ldx #0
@LOOP2:
lda #32 + 1
sta 8198
lda CM_ADR1L
sta 8198
dec CM_ADR1L
lda CM_CODEMAP,X
@_20:
asl
beq @NEXT2
bcc @SKIP
sty 8199
iny
bne @_20
@SKIP:
bit 8199
bcc @_20
@NEXT2:
inx
cpx #9
bne @LOOP2
@NC:
lda #32 + 1
sta 8192
sta 8198
lda #244 + 64 - 256
sta 8198
ldx #142
stx 8199
inx
stx 8199
lda #0
sta 8195
lda #CM_SPAGE / 256
sta 16404
lda #129
sta 8192
lda CM_YSCRPOS
beq @AT_REST
sec
sbc #4
sta CM_YSCRPOS
@AT_REST:
asl
eor #255
sta 8197
lda CM_YSCRPOS
sta 8197
lda #30
sta 8193
CM_CODE:
CM_C1CHR = 1
CM_C2CHR = 25
ldy #0
lda CM_CODEXPOS
clc
adc #8
cmp #169
beq CM_QUART
sta CM_CODEXPOS
lda CM_CODEYPOS
sec
sbc #4
sta CM_CODEYPOS
ldx #10
lda #CM_C2CHR
jsr @CM_CODEPLOT
ldx #0
lda #CM_C1CHR
@CM_CODEPLOT:
sta CM_TEMP4
lda CM_CODEXPOS
sta CM_TEMP1
@LOOP2:
lda CM_CODEYPOS
sta CM_TEMP2
lda CM_CODEMAP,X
beq @DONE
sta CM_TEMP3
inx
@LOOP:
asl CM_TEMP3
beq @NEXT2
bcc @NEXT
lda CM_TEMP4
inc CM_TEMP4
sta CM_SDATA,Y
lda #2
sta CM_SCTRL,Y
lda CM_TEMP1
cmp #224
bcs @DONE
sta CM_SXPOS,Y
lda CM_TEMP2
sta CM_SYPOS,Y
iny
iny
iny
iny
@NEXT:
lda CM_TEMP2
clc
adc #8
sta CM_TEMP2
bne @LOOP
@NEXT2:
lda CM_TEMP1
sec
sbc #8
sta CM_TEMP1
bne @LOOP2
@DONE:
rts
CM_QUART:
CM_QX = 89
CM_QY = 47 + 16
CM_QCHR = 33
lda #CM_QCHR
sta CM_TEMP4
lda #CM_QY
sta CM_TEMP2
ldx #0
ldy #32
@LOOP2:
lda #CM_QX
sta CM_TEMP1
lda CM_QUARTMAP,X
sta CM_TEMP3
inx
@LOOP:
asl CM_TEMP3
bcc @NEXT
lda CM_TEMP4
inc CM_TEMP4
sta CM_SDATA,Y
sta CM_SDATA + 4,Y
sta CM_SDATA + 8,Y
sta CM_SDATA + 12,Y
lda #32
sta CM_SCTRL,Y
lda #96
sta CM_SCTRL + 4,Y
lda #160
sta CM_SCTRL + 8,Y
lda #224
sta CM_SCTRL + 12,Y
lda CM_TEMP1
sta CM_SXPOS,Y
sta CM_SXPOS + 8,Y
eor #255
sec
sbc #5
sta CM_SXPOS + 4,Y
sta CM_SXPOS + 12,Y
lda CM_TEMP2
sta CM_SYPOS,Y
sta CM_SYPOS + 4,Y
eor #255
sec
sbc #167 - CM_QY * 2
sta CM_SYPOS + 8,Y
sta CM_SYPOS + 12,Y
tya
clc
adc #16
tay
@NEXT:
lda CM_TEMP1
clc
adc #8
sta CM_TEMP1
cmp #CM_QX + 8 * 5
bne @LOOP
lda CM_TEMP2
clc
adc #8
sta CM_TEMP2
cmp #CM_QY + 8 * 6
bne @LOOP2
rts
CM_SFXNOISE:
.byte $04,$06,$01,$01
CM_NOISESTART = 24
CM_NOISELEN = 56
CM_TRIANGLEN = 44
CM_INITTAB:
.byte $5C,$18,$49,$F1,$9F
CM_STDATA:
.byte $88,$2F,$30
.byte $86,$31,$32,$33,$34
.byte $85,$35,$36,$37,$38
.byte $85,$39,$3A,$3B
.byte $84,$3C,$3D,$3E,$3F,$40
.byte $84,$41,$42,$43,$44,$19
.byte $84,$45,$46,$47,$48
.byte $83,$49,$4A,$4B,$4C,$4D
.byte $82,$4E,$4F,$50,$51,$52,$0B
.byte $82,$53,$54,$55,$56,$0B
.byte $82,$57,$58,$59,$0B
.byte $82,$5A,$5B,$5C
.byte $81,$5D,$5E
.byte $80
CM_COLFADE:
.byte $04,$04,$04
.byte $04,$04,$03
.byte $04,$04,$13
.byte $03,$14,$12
.byte $02,$16,$11
.byte $01,$18,$11
.byte $80
CM_QUARTMAP:
.byte $38
.byte $78
.byte $E0
.byte $C0
.byte $80
.byte $80
CM_CODEMAP:
.byte $22
.byte $22
.byte $62
.byte $E2
.byte $72
.byte $7A
.byte $7A
.byte $7A
.byte $0E
.byte $00
.byte $12
.byte $12
.byte $12
.byte $1A
.byte $0A
.byte $02
.byte $06
.byte $06
.byte $02
.byte $00
CHR3:
MESS93:
.byte $00
.byte $8C
.byte $52
.byte $42
.byte $CE
.byte $42
.byte $92
.byte $0C
.byte $00
.byte $8C
.byte $52
.byte $42
.byte $CE
.byte $42
.byte $92
.byte $0C
CM_ABMAP:
.byte $22,$C5,$15,$5F,$60,$61,$62,$63,$64,$65,$66,$63,$67,$00,$60,$60,$68,$63,$63,$68,$5F,$69,$6A,$6B
.byte $22,$E5,$15,$6C,$6D,$6E,$6F,$70,$71,$63,$72,$70,$73,$00,$6D,$74,$75,$70,$70,$75,$6C,$76,$77,$78
.byte $23,$25,$15,$79,$7A,$7B,$90,$7D,$7E,$7F,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D
.byte $20,$AA,$0C,$91,$62,$92,$66,$93,$94,$95,$96,$65,$66,$60,$61
.byte $20,$CA,$0C,$97,$6F,$98,$72,$99,$9A,$9B,$9C,$63,$72,$74,$6E
.byte $00
CM_PALETTE:
.byte $34,$24,$14,$04
.byte $11,$28,$1D,$04
CM_SHORT = * - CM_LOGO
CM_CHARACTERS:
lda #14
sta BANKNO
lda #CM_CHRSET0
jsr COPYBLOCKOFCOMPACTEDCHRS
lda #>(144 * 16)
sta _VRAMADDR
lda #<(144 * 16)
sta _VRAMADDR
ldx #0
@_1:
lda CHR3,X
sta _VRAMDATA
inx
cpx #16
bne @_1
rts
CM_CHRSET:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/CMLOGO.PP1"
CM_TOTAL = * - CM_LOGO
SMILEY:
@TST_BYTE = 19
@BANK = 20
@PAGE = 21
@PAD1 = 22
@BANK_ON = 23
@FACE_MASK = 24
ldx #32
@_1:
lda @ROM_CHECK - 32,X
sta 0,X
inx
bne @_1
stx 8192
stx 8193
jsr @KEYPAD
sty @TST_BYTE
lda @PAD1
and #191
cmp #191
bne @NEXT_TST
lda #SMILEY_HIBANK
sta @BANK
lda @SMILEY_BANK
sta @BANK_ON
jsr 32
@NEXT_TST:
lda @PAD1
and #127
cmp #127
bne @NO_EQ
jsr @TST_2
@NO_EQ:
lda @TST_BYTE
beq @EXIT
and #4 + 8
bne @FAILED
jmp @GOOD_FACE
@FAILED:
jmp @BAD_FACE
@EXIT:
rts
@TST_2:
jsr @TST2_SET
@TST1A:
ldy #64
@TST1B:
stx 8199
inx
stx 8199
inx
stx 8199
inx
stx 8199
inx
dey
bne @TST1B
inx
sec
sbc #1
bne @TST1A
jsr @TST2_SET
ldy 8199
@TST2A:
ldy #64
@TST2B:
cpx 8199
bne @CRAM_FAIL
inx
cpx 8199
bne @CRAM_FAIL
inx
cpx 8199
bne @CRAM_FAIL
inx
cpx 8199
bne @CRAM_FAIL
inx
dey
bne @TST2B
inx
sec
sbc #1
bne @TST2A
jsr @TST2_SET
ldx #255 - 37
@TST3A:
ldy #64
@TST3B:
stx 8199
dex
stx 8199
dex
stx 8199
dex
stx 8199
dex
dey
bne @TST3B
dex
sec
sbc #1
bne @TST3A
jsr @TST2_SET
ldx #255 - 37
ldy 8199
@TST4A:
ldy #64
@TST4B:
cpx 8199
bne @CRAM_FAIL
dex
cpx 8199
bne @CRAM_FAIL
dex
cpx 8199
bne @CRAM_FAIL
dex
cpx 8199
bne @CRAM_FAIL
dex
dey
bne @TST4B
dex
sec
sbc #1
bne @TST4A
lda #2
bne @STORE_IT
@CRAM_FAIL:
lda #8
@STORE_IT:
ora @TST_BYTE
sta @TST_BYTE
rts
@TST2_SET:
lda #32
ldx #37
ldy #0
sty 8198
sty 8198
rts
@KEYPAD:
ldx #1
stx 16406
dex
stx 16406
ldy #8
@PAD:
lda 16406
lsr
rol @PAD1
dey
bne @PAD
rts
@ROM_CHECK:
ldy #0
@HERE2:
lda @BANK
jsr @SET_BANK
lda #64 / 4
sta @PAGE
lda #128
.byte $85
.byte <(@HERE + 2)
lda #144
.byte $85
.byte <(@HEREA + 2)
lda #160
.byte $85
.byte <(@HEREB + 2)
lda #176
.byte $85
.byte <(@HEREC + 2)
ldx #0
txa
clc
@HERE:
adc 32768,X
bcc @HEREA
iny
clc
@HEREA:
adc 36864,X
bcc @HEREB
iny
clc
@HEREB:
adc 40960,X
bcc @HEREC
iny
clc
@HEREC:
adc 45056,X
bcc @HERED
iny
clc
@HERED:
inx
bne @HERE
inc @HERE + 2
inc @HEREA + 2
inc @HEREB + 2
inc @HEREC + 2
dec @PAGE
bne @HERE
ldx @BANK
cmp @SMILEY_NAME,X
bne @FAIL_IT
lda @BANK
dec @BANK
cmp #SMILEY_LOBANK
bne @HERE2
lda #1
cpy @SMILEY_NAME + 16
beq @TST2_BALLS
@FAIL_IT:
lda #4
@TST2_BALLS:
sta @TST_BYTE
lda @BANK_ON
@SET_BANK:
tax
sta BANKTABLE,X
rts
.res 13, 234
.res 15, 234
@SMILEY_NAME:
@_0:
.byte $2A,$20,$53,$4D,$49,$4C,$45,$59,$20,$54,$45,$53,$54,$20,$56,$31,$2E,$33,$20
@SMILEY_BANK = * - 1
@GOOD_FACE:
ldx #85
lda #26
bne @SHOW_FACE
@BAD_FACE:
ldx #170
lda #22
@SHOW_FACE:
stx @FACE_MASK
ldx @TST_BYTE
stx 17408
ldy #0
sty 8193
ldx #63
stx 8198
sty 8198
jsr @STORE
ora #48
jsr @STORE
jsr @STORE
sty 8198
sty 8198
ldx #16
dey
@_1Q:
sty 8199
dex
bne @_1Q
lda #32
sta 8198
stx 8198
txa
ldy #4
@L1:
sta 8199
inx
bne @L1
dey
bne @L1
lda #35
sta 8198
lda #200
sta 8198
ldy #0
@L2:
lda @FACE_DATA,Y
and @FACE_MASK
sta 8199
iny
cpy #48
bcc @L2
ldx #0
stx 8192
stx 8198
stx 8198
stx 8197
stx 8197
lda #14
sta 8193
ldy #10
@WAIT:
dec TEMP1
bne @WAIT
dex
bne @WAIT
dey
bne @WAIT
sty 8193
rts
@STORE:
sta 8199
sta 8199
sta 8199
sta 8199
rts
@FACE_DATA:
.byte $00,$C0,$FC,$FF,$FF,$F0,$00,$00
.byte $40,$FF,$87,$FF,$B7,$CF,$73,$00
.byte $44,$FF,$FE,$B7,$FF,$FE,$77,$00
.byte $44,$FF,$07,$F5,$35,$CF,$77,$00
.byte $00,$CF,$F9,$FA,$FA,$FD,$03,$00
.byte $00,$00,$0F,$0F,$0F,$03,$00,$00
SMILEY_SIZE = * - SMILEY
PP1ADDRESS = ZLIM
ZLIM .set ZLIM + 2
PP1ADDRESSL = PP1ADDRESS
PP1ADDRESSH = PP1ADDRESS + 1
PP1TEMP1 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP2 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP3 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP4 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP5 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP6 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP7 = ZLIM
ZLIM .set ZLIM + 1
PP1TEMP8 = ZLIM
ZLIM .set ZLIM + 1
