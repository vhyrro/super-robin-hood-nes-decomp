RESTUPDATECOIN:
stx ADDRESS8
lda ONSCREENCOUNT2,Y
and #15
sta TEMP1
cmp #6
bcs NOSPARKLE
lda ONSCREENCOUNT2,Y
and #240
bne @_3
lda SEED + 1
bne NOSPARKLE
@_3:
lda ONSCREENCOUNT2,Y
clc
adc #16
sta ONSCREENCOUNT2,Y
lsr
lsr
lsr
lsr
lsr
sta TEMP2
txa
ldx XCOORDH
sec
sbc #7
bcs @_1
dex
@_1:
cpx #0
bne @_2
sta TEMP3
lda ONSCREENY,Y
clc
adc #4
tay
lda #2
sta TEMP
ldx TEMP2
lda SPARKLE,X
ldx TEMP3
jsr POKESPRITE
@_2:
NOSPARKLE:
ldy ADDRESS9
lda ONSCREENY,Y
sta ADDRESS8 + 1
jsr PICKUPCOLLISION
bcs ENDCOIN
jsr STOREOUTOLDROBIN
ldy ADDRESS9
lda ONSCREENXL,Y
sta ADDRESS7
lda ONSCREENXH,Y
sta ADDRESS7 + 1
lda #0
sta ONSCREENROU,Y
lda ONSCREENCOUNT1,Y
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda SECRET + 3,Y
and BITPATTERN,X
bne @_3
lda SECRET + 3,Y
eor BITPATTERN,X
sta SECRET + 3,Y
ldy ADDRESS9
lda ONSCREENCOUNT2,Y
and #15
cmp #6
bcc @_1
jsr ADDTOHEARTS
lda #7
jsr STARTSTARS
lda #PICKUPHEARTFX
jsr SOUNDFX
lda #72
jsr ADDTOSCORE
jmp @_2
@_1:
jsr STARTFLOATUPNUMBER
lda #6
jsr STARTSTARS
lda #PICKUPTREASUREFX
jsr SOUNDFX
lda #50
jsr ADDTOSCORE
@_2:
@_3:
rts
ENDCOIN:
ldy ADDRESS9
lda XCOORDH
bne @_1
lda ONSCREENY,Y
tay
lda TEMP1
cmp #6
bcs PULSINGHEART
tax
lda TREASPAL,X
sta TEMP
lda COUNTER
lsr
lsr
and #3
sta TEMP
lda TEMP1
asl
asl
clc
adc #204
ldx ADDRESS8
jmp POKESPRITE2BY2
@_1:
rts
PULSINGHEART:
lda #3
sta TEMP
tya
clc
adc #12
tay
lda COUNTER
lsr
lsr
lsr
and #3
tax
lda HEARTSDEFS,X
ldx ADDRESS8
dex
dex
dex
dex
jmp POKESPRITE
SPARKLE:
.byte $8D
.byte $8D
.byte $8E
.byte $8E
.byte $8F
.byte $8E
.byte $8D
.byte $8D
PUTINHEARTBANK:
lda MAPNO
FINDINITCOIN:
cmp COINCO + 1,Y
bne @_2
lda COINCO,Y
cmp BLOCKX
beq GOTRIGHTCOIN
lda MAPNO
@_2:
iny
iny
cpy #(8 * 6 + 24) * 2
bne FINDINITCOIN
dey
dey
GOTRIGHTCOIN:
tya
lsr
sta ONSCREENCOUNT1,X
lsr
lsr
lsr
sta ONSCREENCOUNT2,X
GOTCOIN:
tya
lsr
stx TEMP
tax
and #7
tay
txa
lsr
lsr
lsr
tax
lda SECRET + 3,X
ldx TEMP
and BITPATTERN,Y
beq @_1
lda #0
sta ONSCREENROU,X
rts
@_1:
lda #8
jsr ONSCRXANDY
lda ONSCREENY,X
clc
adc #8
sta ONSCREENY,X
rts
COINCO:
.byte $11
.byte $05
.byte $2C
.byte $05
.byte $59
.byte $05
.byte $32
.byte $04
.byte $2A
.byte $04
.byte $16
.byte $04
.byte $0A
.byte $04
.byte $19
.byte $01
.byte $44
.byte $04
.byte $62
.byte $04
.byte $76
.byte $05
.byte $7B
.byte $04
.byte $0E
.byte $02
.byte $1C
.byte $00
.byte $2C
.byte $00
.byte $34
.byte $00
.byte $11
.byte $03
.byte $41
.byte $00
.byte $26
.byte $03
.byte $3E
.byte $03
.byte $CC
.byte $04
.byte $B3
.byte $04
.byte $95
.byte $04
.byte $A6
.byte $04
.byte $9D
.byte $05
.byte $89
.byte $05
.byte $A9
.byte $06
.byte $9D
.byte $07
.byte $91
.byte $06
.byte $83
.byte $07
.byte $1F
.byte $09
.byte $03
.byte $09
.byte $76
.byte $07
.byte $62
.byte $06
.byte $4C
.byte $06
.byte $62
.byte $07
.byte $1B
.byte $0B
.byte $44
.byte $07
.byte $41
.byte $06
.byte $07
.byte $06
.byte $20
.byte $07
.byte $0B
.byte $07
.byte $0D
.byte $08
.byte $09
.byte $0A
.byte $17
.byte $0A
.byte $26
.byte $08
.byte $35
.byte $07
.byte $08
.byte $0B
.byte $39
.byte $05
.byte $29
.byte $04
.byte $10
.byte $01
.byte $49
.byte $04
.byte $05
.byte $02
.byte $6C
.byte $04
.byte $67
.byte $05
.byte $83
.byte $05
.byte $11
.byte $00
.byte $44
.byte $00
.byte $C7
.byte $04
.byte $8C
.byte $04
.byte $AB
.byte $05
.byte $AE
.byte $06
.byte $88
.byte $06
.byte $90
.byte $07
.byte $13
.byte $09
.byte $56
.byte $07
.byte $65
.byte $06
.byte $26
.byte $06
.byte $25
.byte $07
.byte $05
.byte $07
.byte $13
.byte $08
.byte $0C
.byte $0B
STARTFLOATUPNUMBER:
lda ONSCREENCOUNT2,Y
and #15
tax
dec TREASURES,X
lda TREASURES,X
sta COINNUM
@_1:
lda ONSCREENCOUNT1,Y
asl
tax
lda COINCO,X
sta COINNUMX
lda ONSCREENY,Y
sta COINNUMY
lda #64
sta COINNUMCOUNT
rts
FLOATUPNUMBER:
lda COINNUMY
beq @END
lda COINNUMCOUNT
beq @END
lda COUNTER
lsr
lsr
and #3
sta TEMP
lda COUNTER
and #1
bne @_3
dec COINNUMCOUNT
dec COINNUMY
@_3:
ldy COINNUMY
ldx COINNUMX
lda TIMES16LO - 1,X
clc
adc #6
sec
sbc SCRXL
sta TEMP1
lda TIMES16HI - 1,X
sbc SCRXH
bne @END
lda COINNUM
clc
adc #128
ldx TEMP1
jsr POKESPRITE
@END:
rts
PRINTLIVESINFOMESS:
.byte <(MGOSUB)
.word CLEARSCR
.byte <(MADDR + 35)
.byte $C0
.byte <(MLOOP)
.byte $40
.byte <(MLEN)
.byte $01
.byte $FF
.byte <(MENDLOOP)
.byte <(MADDR + 32)
.byte $8D
.byte $13,$03,$0F,$12,$05
.byte <(MADDR + 33)
.byte $4E
.byte $0C,$09,$16,$05,$13
.byte <(MADDR + 34)
.byte $46
.byte $14,$12,$05,$01,$13,$15,$12,$05,$20,$14,$0F,$20,$03,$0F,$0C,$0C,$05,$03,$14
.byte <(MADDR + 35)
.byte $D2
.byte <(MLEN)
.byte $03
.byte $AA
.byte $AA
.byte $AA
.byte <(MEND)
LIVESBIT:
.byte <(GAMEOVERBIT - LIFE1MESS)
.byte $00
.byte <(LIVES2MESS - LIFE1MESS)
.byte <(LIVES3MESS - LIFE1MESS)
.byte <(LIVES4MESS - LIFE1MESS)
.byte <(LIVES5MESS - LIFE1MESS)
.byte <(LIVES6MESS - LIFE1MESS)
LIFE1MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $22
.byte $20,$0C,$09,$06,$05,$20
.byte <(MEND)
LIVES2MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $23
.byte <(MEND)
LIVES3MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $24
.byte <(MEND)
LIVES4MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $25
.byte <(MEND)
LIVES5MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $26
.byte <(MEND)
LIVES6MESS:
.byte <(MADDR + 33)
.byte $4C
.byte $27
.byte <(MEND)
GAMEOVERBIT:
.byte <(MADDR + 33)
.byte $4B
.byte $07,$01,$0D,$05,$20,$0F,$16,$05,$12
.byte <(MEND)
COMPLETEDGAMEMESSAGE:
.byte <(MADDR + 33)
.byte $4B
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20
.byte <(MADDR + 32)
.byte $EC
.byte $14,$08,$05,$20,$05,$0E,$04
.byte <(MADDR + 33)
.byte $C8
.byte $03,$0F,$0E,$07,$12,$01,$14,$15,$0C,$01,$14,$09,$0F,$0E,$13
.byte $1B
.byte <(MADDR + 34)
.byte $01
.byte $20,$01,$06,$14,$05,$12,$20,$05,$18,$10,$0C,$0F,$12,$09,$0E,$07,$20,$01,$0E,$04,$20,$06,$09,$07,$08,$14,$09,$0E,$07
.byte <(MDOWNLINE)
.byte $20,$19,$0F,$15,$12,$20,$17,$01,$19,$20,$08,$05,$12,$0F,$09,$03,$01,$0C,$0C,$19,$20,$14,$08,$12,$0F,$15,$07,$08
.byte <(MDOWNLINE)
.byte $20,$14,$08,$05,$20,$04,$05,$01,$04,$0C,$19,$20,$0E,$0F,$14,$14,$09,$0E,$07,$08,$01,$0D,$20,$03,$01,$13,$14,$0C,$05
.byte <(MDOWNLINE)
.byte $20,$19,$0F,$15,$20,$08,$01,$16,$05,$20,$05,$16,$05,$0E,$14,$15,$01,$0C,$0C,$19,$20,$12,$05,$13,$03,$15,$05,$04
.byte <(MDOWNLINE)
.byte <(MJUMP)
.word COMPLETED2
COMPLETED2:
.byte $20,$19,$0F,$15,$12,$20,$14,$12,$15,$05,$20,$0C,$0F,$16,$05,$20,$0D,$01,$09,$04,$20,$0D,$01,$12,$09,$0F,$0E
.byte $1B
.byte <(MDOWNLINE)
.byte <(MLOOP)
.byte $1C
.byte $20
.byte <(MENDLOOP)
.byte <(MDOWNLINE)
.byte $20,$20,$20,$19,$0F,$15,$20,$08,$01,$16,$05,$20,$01,$0C,$13,$0F,$20,$12,$05,$03,$0F,$16,$05,$12,$05,$04
.byte <(MDOWNLINE)
.byte $20,$20,$20,$01,$0C,$0C,$20,$14,$08,$05,$20,$13,$14,$0F,$0C,$05,$0E,$20,$14,$12,$05,$01,$13,$15,$12,$05
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $0B,$09,$0E,$07,$20,$12,$09,$03,$08,$01,$12,$04,$20,$17,$09,$0C,$0C,$20,$12,$05,$14,$15,$12,$0E,$20,$13,$0F,$0F,$0E,$1E
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $20,$20,$20,$20,$20,$0C,$0F,$0E,$07,$20,$0C,$09,$16,$05,$20,$14,$08,$05,$20,$0B,$09,$0E,$07
.byte $1B
.byte <(MEND)
TREASURELEFTMESS:
.byte $22
.byte $A8
.byte $01
.byte $00
.byte $22
.byte $B0
.byte $01
.byte $00
.byte $22
.byte $B8
.byte $01
.byte $00
.byte $23
.byte $28
.byte $01
.byte $00
.byte $23
.byte $30
.byte $01
.byte $00
.byte $23
.byte $38
.byte $01
.byte $00
PRINT6TREASURES:
jsr ADDSPARKLETOTREASURES
ldx #5
@_2:
stx ADDRESS9
lda TREASPAL,X
sta TEMP
ldy SHOWALLTREASURE + 6,X
lda SHOWALLTREASURE,X
tax
lda ADDRESS9
asl
asl
clc
adc #204
jsr POKESPRITE2BY2
dec ADDRESS9
ldx ADDRESS9
bpl @_2
rts
SHOWALLTREASURE:
.byte $30
.byte $70
.byte $B0
.byte $30
.byte $70
.byte $B0
.byte $A0
.byte $A0
.byte $A0
.byte $C0
.byte $C0
.byte $C0
ADDSPARKLETOTREASURES:
ldx #1
DONEXTSPARKLE:
lda HEARTSTABLE + 8,X
bne ALREADYGOTSPARKLE
lsr SEED
bcc NEXTSPARKLE
lda SEED + 2
and #7
cmp #6
bcs NEXTSPARKLE
tay
lda SEED + 1
and #7
clc
adc #($FC)
clc
adc SHOWALLTREASURE,Y
sta HEARTSTABLE,X
lda SEED + 1
and #7
clc
adc #2
clc
adc SHOWALLTREASURE + 6,Y
sta HEARTSTABLE + 4,X
lda #7 * 4
sta HEARTSTABLE + 8,X
ALREADYGOTSPARKLE:
dec HEARTSTABLE + 8,X
lda HEARTSTABLE + 8,X
lsr
lsr
tay
lda #2
sta TEMP
lda HEARTSTABLE,X
sta TEMP1
stx TEMP2
lda SPARKLE,Y
ldy HEARTSTABLE + 4,X
ldx TEMP1
jsr POKESPRITE
ldx TEMP2
NEXTSPARKLE:
dex
bpl DONEXTSPARKLE
rts
REDEFINEWATER:
lda MAPNO
cmp #5
bcs @_1
ldy VRAMPOINTER
lda COUNTER
lsr
lsr
and #6
tax
lda #>(254 * 16 + 4104)
sta VRAMBUFFER,Y
lda #<(254 * 16 + 4104)
sta VRAMBUFFER + 1,Y
lda #2
sta VRAMBUFFER + 2,Y
lda WATERCHRS,X
sta VRAMBUFFER + 3,Y
lda WATERCHRS + 1,X
sta VRAMBUFFER + 4,Y
lda COUNTER
lsr
and #6
tax
lda #>(255 * 16 + 4096)
sta VRAMBUFFER + 5,Y
lda #<(255 * 16 + 4096)
sta VRAMBUFFER + 6,Y
lda #2
sta VRAMBUFFER + 7,Y
lda WATERCHRS + 8,X
sta VRAMBUFFER + 8,Y
lda WATERCHRS + 9,X
sta VRAMBUFFER + 9,Y
lda #>(255 * 16 + 4104)
sta VRAMBUFFER + 10,Y
lda #<(255 * 16 + 4104)
sta VRAMBUFFER + 11,Y
lda #2
sta VRAMBUFFER + 12,Y
lda WATERCHRS + 8,X
sta VRAMBUFFER + 13,Y
lda WATERCHRS + 9,X
sta VRAMBUFFER + 14,Y
tya
clc
adc #15
sta VRAMPOINTER
@_1:
rts
SECRETTABLE:
.word SECRET0
.word SECRET1
.word SECRET2
.word SECRET3
.word SECRET4
.word SECRET5
.word SECRET6
.word SECRET7
.word SECRET8
.word SECRET9
.word SECRET10
.word SECRET11
.word SECRET12
.word SECRET13
.word SECRET14
.word SECRET15
.word SECRET16
.word SECRET17
.word SECRET18
.word SECRET19
.word SECRET20
.word SECRET21
.word SECRET22
.word SECRET23
SECRET0:
.byte $04
.byte $26
.byte $06
.byte $20
.byte $FF
SECRET1:
.byte $04
.byte $04
.byte $0A
.byte $00
.byte $04
.byte $04
.byte $0B
.byte $00
.byte $FF
SECRET2:
.byte $07
.byte $99
.byte $0C
.byte $AD
.byte $07
.byte $9A
.byte $0C
.byte $AB
.byte $FF
SECRET3:
.byte $06
.byte $AE
.byte $08
.byte $F8
.byte $FF
SECRET4:
.byte $09
.byte $0A
.byte $0B
.byte $00
.byte $09
.byte $0B
.byte $0B
.byte $00
.byte $09
.byte $0A
.byte $0C
.byte $00
.byte $09
.byte $0B
.byte $0C
.byte $00
.byte $FF
SECRET5:
.byte $07
.byte $66
.byte $00
.byte $20
.byte $07
.byte $66
.byte $01
.byte $20
.byte $07
.byte $66
.byte $02
.byte $20
.byte $07
.byte $66
.byte $03
.byte $AD
.byte $FF
SECRET6:
.byte $0A
.byte $16
.byte $0C
.byte $20
.byte $0A
.byte $16
.byte $0D
.byte $20
.byte $FF
SECRET7:
.byte $04
.byte $BD
.byte $04
.byte $4A
.byte $04
.byte $BE
.byte $04
.byte $49
.byte $FF
SECRET8:
.byte $01
.byte $19
.byte $04
.byte $20
.byte $01
.byte $19
.byte $05
.byte $20
.byte $01
.byte $19
.byte $06
.byte $20
.byte $01
.byte $19
.byte $07
.byte $20
.byte $01
.byte $19
.byte $08
.byte $20
.byte $01
.byte $19
.byte $09
.byte $20
.byte $FF
SECRET9:
.byte $05
.byte $71
.byte $00
.byte $24
.byte $FF
SECRET10:
.byte $00
.byte $02
.byte $07
.byte $20
.byte $00
.byte $02
.byte $06
.byte $20
.byte $00
.byte $02
.byte $05
.byte $20
.byte $00
.byte $02
.byte $04
.byte $20
.byte $00
.byte $02
.byte $03
.byte $20
.byte $00
.byte $02
.byte $02
.byte $20
.byte $00
.byte $02
.byte $01
.byte $20
.byte $00
.byte $02
.byte $00
.byte $20
.byte $FF
SECRET11:
.byte $05
.byte $77
.byte $06
.byte $00
.byte $05
.byte $77
.byte $07
.byte $00
.byte $FF
SECRET12:
.byte $08
.byte $19
.byte $0C
.byte $11
.byte $08
.byte $24
.byte $0A
.byte $2B
.byte $FF
SECRET13:
.byte $07
.byte $07
.byte $0C
.byte $AD
.byte $FF
SECRET14:
.byte $05
.byte $23
.byte $0C
.byte $00
.byte $05
.byte $24
.byte $0C
.byte $00
.byte $05
.byte $25
.byte $0C
.byte $00
.byte $FF
SECRET15:
.byte $04
.byte $02
.byte $02
.byte $04
.byte $FF
SECRET16:
.byte $04
.byte $26
.byte $0C
.byte $20
.byte $04
.byte $26
.byte $0B
.byte $20
.byte $04
.byte $25
.byte $0C
.byte $4B
.byte $FF
SECRET17:
.byte $06
.byte $10
.byte $0B
.byte $4B
.byte $06
.byte $10
.byte $0C
.byte $49
.byte $FF
SECRET18:
.byte $06
.byte $28
.byte $0A
.byte $49
.byte $06
.byte $29
.byte $0A
.byte $49
.byte $06
.byte $2A
.byte $0A
.byte $49
.byte $FF
SECRET19:
.byte $06
.byte $85
.byte $07
.byte $20
.byte $06
.byte $85
.byte $08
.byte $20
.byte $FF
SECRET20:
.byte $09
.byte $0E
.byte $08
.byte $F8
.byte $FF
SECRET21:
.byte $07
.byte $96
.byte $05
.byte $AB
.byte $FF
SECRET22:
.byte $05
.byte $01
.byte $0B
.byte $00
.byte $05
.byte $02
.byte $0B
.byte $00
.byte $05
.byte $01
.byte $0C
.byte $00
.byte $05
.byte $02
.byte $0C
.byte $00
.byte $FF
SECRET23:
.byte $05
.byte $8A
.byte $0C
.byte $25
.byte $05
.byte $8A
.byte $0B
.byte $25
.byte $FF
.byte $FF
