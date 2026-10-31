ADDRIGHTEDGE = 18
ATTRIBUTEMASKS:
.byte $FC
.byte $F3
.byte $CF
.byte $3F
ATTRIBUTEANDS:
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $04
.byte $10
.byte $40
.byte $02
.byte $08
.byte $20
.byte $80
.byte $03
.byte $0C
.byte $30
.byte $C0
SETXSCROLL:
lda SCRXL
sta ADDRESS2
lda SCRXL + 1
sta ADDRESS2 + 1
lda ROBINXL
sec
sbc #120
sta ADDRESS2
lda ROBINXH
sbc #0
cmp #255
bne @_1
lda #0
sta ADDRESS2
@_1:
sta ADDRESS2 + 1
lda ADDRESS2 + 1
sta TEMP
lda ADDRESS2
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
sta MAPSTRIP
cmp #0
bcc MAPNOTMOVED
cmp MAXMAP
bcc PRINTMAPDOWNSIDE
lda MAXMAP
sta MAPSTRIP
ldx #0
stx ADDRESS2 + 1
asl
rol ADDRESS2 + 1
asl
rol ADDRESS2 + 1
asl
rol ADDRESS2 + 1
asl
rol ADDRESS2 + 1
sta ADDRESS2
@_2:
PRINTMAPDOWNSIDE:
lda SCRXL + 1
cmp ADDRESS2 + 1
bne @M985__1
lda SCRXL
cmp ADDRESS2
@M985__1:
beq MAPNOTMOVED
bcs DECMAPSET
PRINTMAPDOWNSIDE1:
ldx #255
inc SCRXL
bne @M986__1
inc SCRXL + 1
@M986__1:
jmp SETMAPSET
DECMAPSET:
dec SCRXL
pha
lda #255
cmp SCRXL
bne @M987__1
dec SCRXL + 1
@M987__1:
pla
ldx #0
SETMAPSET:
stx SCROLLDIR
lda SCRXH
sta TEMP
lda SCRXL
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
sta MAPSTRIP
jsr BRINGONMAP
lda INTERON
bne PRINTMAPDOWNSIDE
jsr EMPTYBLOCKBUFFER
jmp PRINTMAPDOWNSIDE
MAPNOTMOVED:
@_1:
lsr CONTROL0
lda SCRXL
clc
adc #16
sta X_SCROLL
lda SCRXH
adc #0
lsr
rol CONTROL0
rts
TIMES14TABLELO:
XX .set 0
.byte $00
XX .set XX + 14
.byte $0E
XX .set XX + 14
.byte $1C
XX .set XX + 14
.byte $2A
XX .set XX + 14
.byte $38
XX .set XX + 14
.byte $46
XX .set XX + 14
.byte $54
XX .set XX + 14
.byte $62
XX .set XX + 14
.byte $70
XX .set XX + 14
.byte $7E
XX .set XX + 14
.byte $8C
XX .set XX + 14
.byte $9A
XX .set XX + 14
.byte $A8
XX .set XX + 14
.byte $B6
XX .set XX + 14
.byte $C4
XX .set XX + 14
.byte $D2
XX .set XX + 14
.byte $E0
XX .set XX + 14
.byte $EE
XX .set XX + 14
.byte $FC
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $18
XX .set XX + 14
.byte $26
XX .set XX + 14
.byte $34
XX .set XX + 14
.byte $42
XX .set XX + 14
.byte $50
XX .set XX + 14
.byte $5E
XX .set XX + 14
.byte $6C
XX .set XX + 14
.byte $7A
XX .set XX + 14
.byte $88
XX .set XX + 14
.byte $96
XX .set XX + 14
.byte $A4
XX .set XX + 14
.byte $B2
XX .set XX + 14
.byte $C0
XX .set XX + 14
.byte $CE
XX .set XX + 14
.byte $DC
XX .set XX + 14
.byte $EA
XX .set XX + 14
.byte $F8
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $14
XX .set XX + 14
.byte $22
XX .set XX + 14
.byte $30
XX .set XX + 14
.byte $3E
XX .set XX + 14
.byte $4C
XX .set XX + 14
.byte $5A
XX .set XX + 14
.byte $68
XX .set XX + 14
.byte $76
XX .set XX + 14
.byte $84
XX .set XX + 14
.byte $92
XX .set XX + 14
.byte $A0
XX .set XX + 14
.byte $AE
XX .set XX + 14
.byte $BC
XX .set XX + 14
.byte $CA
XX .set XX + 14
.byte $D8
XX .set XX + 14
.byte $E6
XX .set XX + 14
.byte $F4
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $10
XX .set XX + 14
.byte $1E
XX .set XX + 14
.byte $2C
XX .set XX + 14
.byte $3A
XX .set XX + 14
.byte $48
XX .set XX + 14
.byte $56
XX .set XX + 14
.byte $64
XX .set XX + 14
.byte $72
XX .set XX + 14
.byte $80
XX .set XX + 14
.byte $8E
XX .set XX + 14
.byte $9C
XX .set XX + 14
.byte $AA
XX .set XX + 14
.byte $B8
XX .set XX + 14
.byte $C6
XX .set XX + 14
.byte $D4
XX .set XX + 14
.byte $E2
XX .set XX + 14
.byte $F0
XX .set XX + 14
.byte $FE
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $1A
XX .set XX + 14
.byte $28
XX .set XX + 14
.byte $36
XX .set XX + 14
.byte $44
XX .set XX + 14
.byte $52
XX .set XX + 14
.byte $60
XX .set XX + 14
.byte $6E
XX .set XX + 14
.byte $7C
XX .set XX + 14
.byte $8A
XX .set XX + 14
.byte $98
XX .set XX + 14
.byte $A6
XX .set XX + 14
.byte $B4
XX .set XX + 14
.byte $C2
XX .set XX + 14
.byte $D0
XX .set XX + 14
.byte $DE
XX .set XX + 14
.byte $EC
XX .set XX + 14
.byte $FA
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $16
XX .set XX + 14
.byte $24
XX .set XX + 14
.byte $32
XX .set XX + 14
.byte $40
XX .set XX + 14
.byte $4E
XX .set XX + 14
.byte $5C
XX .set XX + 14
.byte $6A
XX .set XX + 14
.byte $78
XX .set XX + 14
.byte $86
XX .set XX + 14
.byte $94
XX .set XX + 14
.byte $A2
XX .set XX + 14
.byte $B0
XX .set XX + 14
.byte $BE
XX .set XX + 14
.byte $CC
XX .set XX + 14
.byte $DA
XX .set XX + 14
.byte $E8
XX .set XX + 14
.byte $F6
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $12
XX .set XX + 14
.byte $20
XX .set XX + 14
.byte $2E
XX .set XX + 14
.byte $3C
XX .set XX + 14
.byte $4A
XX .set XX + 14
.byte $58
XX .set XX + 14
.byte $66
XX .set XX + 14
.byte $74
XX .set XX + 14
.byte $82
XX .set XX + 14
.byte $90
XX .set XX + 14
.byte $9E
XX .set XX + 14
.byte $AC
XX .set XX + 14
.byte $BA
XX .set XX + 14
.byte $C8
XX .set XX + 14
.byte $D6
XX .set XX + 14
.byte $E4
XX .set XX + 14
.byte $F2
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $0E
XX .set XX + 14
.byte $1C
XX .set XX + 14
.byte $2A
XX .set XX + 14
.byte $38
XX .set XX + 14
.byte $46
XX .set XX + 14
.byte $54
XX .set XX + 14
.byte $62
XX .set XX + 14
.byte $70
XX .set XX + 14
.byte $7E
XX .set XX + 14
.byte $8C
XX .set XX + 14
.byte $9A
XX .set XX + 14
.byte $A8
XX .set XX + 14
.byte $B6
XX .set XX + 14
.byte $C4
XX .set XX + 14
.byte $D2
XX .set XX + 14
.byte $E0
XX .set XX + 14
.byte $EE
XX .set XX + 14
.byte $FC
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $18
XX .set XX + 14
.byte $26
XX .set XX + 14
.byte $34
XX .set XX + 14
.byte $42
XX .set XX + 14
.byte $50
XX .set XX + 14
.byte $5E
XX .set XX + 14
.byte $6C
XX .set XX + 14
.byte $7A
XX .set XX + 14
.byte $88
XX .set XX + 14
.byte $96
XX .set XX + 14
.byte $A4
XX .set XX + 14
.byte $B2
XX .set XX + 14
.byte $C0
XX .set XX + 14
.byte $CE
XX .set XX + 14
.byte $DC
XX .set XX + 14
.byte $EA
XX .set XX + 14
.byte $F8
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $14
XX .set XX + 14
.byte $22
XX .set XX + 14
.byte $30
XX .set XX + 14
.byte $3E
XX .set XX + 14
.byte $4C
XX .set XX + 14
.byte $5A
XX .set XX + 14
.byte $68
XX .set XX + 14
.byte $76
XX .set XX + 14
.byte $84
XX .set XX + 14
.byte $92
XX .set XX + 14
.byte $A0
XX .set XX + 14
.byte $AE
XX .set XX + 14
.byte $BC
XX .set XX + 14
.byte $CA
XX .set XX + 14
.byte $D8
XX .set XX + 14
.byte $E6
XX .set XX + 14
.byte $F4
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $10
XX .set XX + 14
.byte $1E
XX .set XX + 14
.byte $2C
XX .set XX + 14
.byte $3A
XX .set XX + 14
.byte $48
XX .set XX + 14
.byte $56
XX .set XX + 14
.byte $64
XX .set XX + 14
.byte $72
XX .set XX + 14
.byte $80
XX .set XX + 14
.byte $8E
XX .set XX + 14
.byte $9C
XX .set XX + 14
.byte $AA
XX .set XX + 14
.byte $B8
XX .set XX + 14
.byte $C6
XX .set XX + 14
.byte $D4
XX .set XX + 14
.byte $E2
XX .set XX + 14
.byte $F0
XX .set XX + 14
.byte $FE
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $1A
XX .set XX + 14
.byte $28
XX .set XX + 14
.byte $36
XX .set XX + 14
.byte $44
XX .set XX + 14
.byte $52
XX .set XX + 14
.byte $60
XX .set XX + 14
.byte $6E
XX .set XX + 14
.byte $7C
XX .set XX + 14
.byte $8A
XX .set XX + 14
.byte $98
XX .set XX + 14
.byte $A6
XX .set XX + 14
.byte $B4
XX .set XX + 14
.byte $C2
XX .set XX + 14
.byte $D0
XX .set XX + 14
.byte $DE
XX .set XX + 14
.byte $EC
XX .set XX + 14
.byte $FA
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $16
XX .set XX + 14
.byte $24
XX .set XX + 14
.byte $32
XX .set XX + 14
.byte $40
XX .set XX + 14
.byte $4E
XX .set XX + 14
.byte $5C
XX .set XX + 14
.byte $6A
XX .set XX + 14
.byte $78
XX .set XX + 14
.byte $86
XX .set XX + 14
.byte $94
XX .set XX + 14
.byte $A2
XX .set XX + 14
.byte $B0
XX .set XX + 14
.byte $BE
XX .set XX + 14
.byte $CC
XX .set XX + 14
.byte $DA
XX .set XX + 14
.byte $E8
XX .set XX + 14
.byte $F6
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $12
XX .set XX + 14
.byte $20
XX .set XX + 14
.byte $2E
XX .set XX + 14
.byte $3C
XX .set XX + 14
.byte $4A
XX .set XX + 14
.byte $58
XX .set XX + 14
.byte $66
XX .set XX + 14
.byte $74
XX .set XX + 14
.byte $82
XX .set XX + 14
.byte $90
XX .set XX + 14
.byte $9E
XX .set XX + 14
.byte $AC
XX .set XX + 14
.byte $BA
XX .set XX + 14
.byte $C8
XX .set XX + 14
.byte $D6
XX .set XX + 14
.byte $E4
XX .set XX + 14
.byte $F2
XX .set XX + 14
TIMES14TABLEHI:
XX .set 0
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $00
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $01
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $02
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $03
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $04
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $05
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $06
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $07
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $08
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $09
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0A
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0B
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0C
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
.byte $0D
XX .set XX + 14
FINDSOLID:
@_1:
cpy #14 * 16
bcc @_2
pha
lda ROBINY
bpl @_3
tya
clc
adc #($F0)
tay
pla
jmp @_1
@_3:
tya
clc
adc #16
tay
pla
jmp @_1
@_2:
jsr FINDBLOCK
tax
lda #0
lsr TEMP
rol
lsr TEMP1
rol
tay
lda SOLIDCHRS,X
and SOLIDCHRMASKS,Y
dey
beq SHIFTS4
dey
beq SHIFTS2
dey
beq SHIFTS0
SHIFTS6:
lsr
lsr
SHIFTS4:
lsr
lsr
SHIFTS2:
lsr
lsr
SHIFTS0:
sta SOLIDFOUND
cmp #0
rts
SOLIDCHRMASKS:
.byte $C0
.byte $30
.byte $0C
.byte $03
FINDBLOCK:
stx TEMP
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
lsr TEMP
ror
tax
rol TEMP1
lda MAPPOINTER
clc
adc TIMES14TABLELO + 1,X
sta ADDRESS
lda MAPPOINTER + 1
adc TIMES14TABLEHI + 1,X
sta ADDRESS + 1
tya
lsr
lsr
lsr
lsr
tay
rol TEMP
lda (ADDRESS),Y
sta BLOCKFOUND
stx BLOCKX
sty BLOCKY
jsr CHECKCHANGEDBLOCK
lda BLOCKFOUND
rts
FINDCHR:
jsr FINDBLOCK
FINDCHRPART:
tay
lsr TEMP
bcs BOTTOMPART
lsr TEMP1
bcs RIGHTSIDE
lda BLKSTL,Y
sta CHRFOUND
rts
RIGHTSIDE:
lda BLKSTR,Y
sta CHRFOUND
rts
BOTTOMPART:
lsr TEMP1
bcs RIGHTSIDE1
lda BLKSBL,Y
sta CHRFOUND
rts
RIGHTSIDE1:
lda BLKSBR,Y
sta CHRFOUND
NOBLOCKSNEEDED:
rts
BRINGONMAP:
lda SCRXL
and #15
cmp #14
bcs NOBLOCKSNEEDED
tay
sta BLOCKY
ldx MAPSTRIP
bit SCROLLDIR
bpl @_1
txa
clc
adc #ADDRIGHTEDGE
sta BLOCKX
tax
@_1:
stx BLOCKX
jsr GETBLOCKBIT
sta ADDRESS9
tay
lda BLOCKROUS,Y
ldy BLOCKY
cmp #0
bpl @_3
dex
jsr GETBLOCKBIT
@_3:
jsr CHECKCHANGEDBLOCK1
lda BLOCKFOUND
jsr PRINTBLOCKTOSCREEN
jmp CHECKADDFLAMESETC
GETBLOCKBIT:
lda MAPPOINTER
clc
adc TIMES14TABLELO,X
sta ADDRESS
lda MAPPOINTER + 1
adc TIMES14TABLEHI,X
sta ADDRESS + 1
lda (ADDRESS),Y
sta BLOCKFOUND
rts
CHECKCHANGEDBLOCK:
inc BLOCKX
CHECKCHANGEDBLOCK1:
ldx CHANGEDBLOCKSPOINTER
beq @_3
ldx #0
@_1:
lda BLOCKX
cmp CHANGEDBLOCKS,X
bne @_2
lda CHANGEDBLOCKS + 1,X
cmp BLOCKY
bne @_2
lda CHANGEDBLOCKS + 2,X
sta BLOCKFOUND
ldx BLOCKX
rts
@_2:
inx
inx
inx
cpx CHANGEDBLOCKSPOINTER
bne @_1
@_3:
ldx BLOCKX
rts
ADDACHANGEDBLOCK:
stx TOPLEVVAR1
sty TOPLEVVAR2
sta TOPLEVVAR3
ADDACHANGEDBLOCK1:
lda #3
ldx CHANGEDBLOCKSPOINTER
beq @_1
ldx #0
@_2:
lda CHANGEDBLOCKS + 0,X
cmp TOPLEVVAR1
bne @_3
lda CHANGEDBLOCKS + 1,X
cmp TOPLEVVAR2
bne @_3
lda #0
beq @_1
@_3:
inx
inx
inx
cpx CHANGEDBLOCKSPOINTER
bne @_2
lda #3
@_1:
clc
adc CHANGEDBLOCKSPOINTER
sta CHANGEDBLOCKSPOINTER
cmp #3 * MAXCHANGEDBLOCKS
bne @_8
jsr TURNINTERON
@M995__1:
php
pha
lda CONTROL1
and #30
clc
adc #1
sta _CONTROL1
pla
plp
lda CONTROL1
and #30
sta _CONTROL1
jmp @M995__1
@_8:
lda TOPLEVVAR2
sta CHANGEDBLOCKS + 1,X
lda TOPLEVVAR1
sta CHANGEDBLOCKS + 0,X
lda TOPLEVVAR3
sta CHANGEDBLOCKS + 2,X
ldx TOPLEVVAR1
bit INTERON
bpl @_4
ldy TOPLEVVAR2
jmp PRINTBLOCKTOSCREENCHECK
@_4:
rts
DELETEACHANGEDBLOCK:
stx TOPLEVVAR1
sty TOPLEVVAR2
DELETEACHANGEDBLOCK1:
lda CHANGEDBLOCKSPOINTER
beq @_4
ldx #0
@_1:
lda CHANGEDBLOCKS + 0,X
cmp TOPLEVVAR1
bne @_2
lda CHANGEDBLOCKS + 1,X
cmp TOPLEVVAR2
bne @_2
@_3:
lda CHANGEDBLOCKS + 3,X
sta CHANGEDBLOCKS + 0,X
inx
cpx CHANGEDBLOCKSPOINTER
bne @_3
txa
clc
adc #($FD)
sta CHANGEDBLOCKSPOINTER
ldx TOPLEVVAR1
lda MAPPOINTER
clc
adc TIMES14TABLELO,X
sta ADDRESS
lda MAPPOINTER + 1
adc TIMES14TABLEHI,X
sta ADDRESS + 1
ldy TOPLEVVAR2
lda (ADDRESS),Y
jmp PRINTBLOCKTOSCREENCHECK
@_2:
inx
inx
inx
cpx CHANGEDBLOCKSPOINTER
bne @_1
@_5:
ldx TOPLEVVAR1
@_4:
rts
BLOCKNOTONSCREEN:
rts
PRINTBLOCKTOSCREENCHECK:
stx BLOCKX
sty BLOCKY
sta BLOCKFOUND
txa
sec
sbc MAPSTRIP
bmi BLOCKNOTONSCREEN
cmp #ADDRIGHTEDGE + 1
bcs BLOCKNOTONSCREEN
PRINTBLOCKTOSCREEN:
ldy BLOCKY
lda BLOCKX
lsr
and #15
cmp #8
bcc @_1
clc
adc #7 * 8 - 8
@_1:
clc
adc ATTRYTABLE,Y
sta ATTRIPOINTER
@_12:
ldx BLOCKPOINTER
cpx #11 * NUMBEROFBLOCKS
bne @_11
lda #0
sta FILLEDBLOCKBUFFER
asl FLYFLAG
@M1002__1:
bit FLYFLAG
bpl @M1002__1
lda #1
sta FILLEDBLOCKBUFFER
jmp @_12
@_11:
ldy BLOCKFOUND
lda BLKSTL,Y
sta BLOCKBUFFER + 2,X
lda BLKSTR,Y
sta BLOCKBUFFER + 3,X
lda BLKSBL,Y
sta BLOCKBUFFER + 6,X
lda BLKSBR,Y
sta BLOCKBUFFER + 7,X
lda BLKSATTR,Y
sta BLOCKATTRI
lda BLOCKX
lsr
lda BLOCKY
rol
and #3
tay
clc
adc BLOCKATTRI
sta BLOCKATTRI
ldx ATTRIPOINTER
lda ATTRIBUTES,X
and ATTRIBUTEMASKS,Y
ldy BLOCKATTRI
ora ATTRIBUTEANDS,Y
sta ATTRIBUTES,X
ldx BLOCKPOINTER
sta BLOCKBUFFER + 10,X
txa
clc
adc #11
sta BLOCKPOINTER
lda BLOCKX
and #31
asl
sta TEMP
and #32
beq @_3
clc
adc #($E4)
@_3:
sta TEMP1
ldy BLOCKY
lda TEMP
and #31
clc
adc TIMES32TABLELO,Y
sta BLOCKBUFFER + 1,X
lda TEMP1
adc TIMES32TABLEHI,Y
sta BLOCKBUFFER + 0,X
lda BLOCKBUFFER + 1,X
clc
adc #32
sta BLOCKBUFFER + 5,X
lda BLOCKBUFFER + 0,X
adc #0
sta BLOCKBUFFER + 4,X
@_2:
NOWATTRI:
ldy #35
lda ATTRIPOINTER
cmp #8 * 7
bcc @_1
sec
sbc #8 * 7
iny
iny
iny
iny
@_1:
clc
adc #192
sta BLOCKBUFFER + 9,X
tya
sta BLOCKBUFFER + 8,X
rts
ATTRYTABLE:
.byte $00
.byte $00
.byte $08
.byte $08
.byte $10
.byte $10
.byte $18
.byte $18
.byte $20
.byte $20
.byte $28
.byte $28
.byte $30
.byte $30
.byte $38
.byte $38
GOINTONEWMAP:
lda MAPNO
asl
asl
clc
adc MAPNO
clc
adc MAPNO
tax
lda MAPINFO,X
sta MAPPOINTER
lda MAPINFO + 1,X
sta MAPPOINTER + 1
stx TEMP1
lda INTERON
beq INTERNOTON
jsr TURNINTEROFFFADE
INTERNOTON:
jsr SETFADE
ldx TEMP1
ldy #0
lda MINMAP
cmp MAPINFO + 2,X
bcs @_9
ldy #255
@_9:
sec
sbc MAPINFO + 2,X
@_1:
sty ADDRESS + 1
asl
rol ADDRESS + 1
asl
rol ADDRESS + 1
asl
rol ADDRESS + 1
asl
rol ADDRESS + 1
clc
adc ROBINXL
sta ROBINXL
lda ADDRESS + 1
adc ROBINXH
sta ROBINXH
lda MAPINFO + 2,X
sta MINMAP
lda MAPINFO + 3,X
clc
adc #($F0)
sta MAXMAP
lda ROBINXL
clc
adc #<(256 + 32)
sta SCRXL
lda ROBINXL + 1
adc #>(256 + 32)
sta SCRXL + 1
stx TEMP
ldy MAPINFO + 4,X
ldx #0
@_2:
lda GAMEPALLETTES,Y
sta FADECOLOURS,X
lda SPRITECOLOURS,X
sta FADECOLOURS + 16,X
iny
inx
cpx #16
bne @_2
ldx TEMP
lda MAPINFO + 5,X
tax
MAKEUPCHRSET:
stx HIPOS
lda MAPCHRSDEFS,X
bmi NOMORECHRSFORMAP
jsr COPYBLOCKOFCOMPACTEDCHRS
ldx HIPOS
inx
jmp MAKEUPCHRSET
NOMORECHRSFORMAP:
lda #0
sta COUNTER
sta ANIMATEDOOR
sta CHANGEDBLOCKSPOINTER
jsr RESETDOORSINTOMAP
jsr DOALLSECRETS
jsr RESETEXTRAVARS
jsr STOREOUTOLDROBIN
jsr SETXSCROLL
lda ROBINXL
sec
sbc SCRXL
sta ROBINONSCRX
ldx MAPNO
lda TUNEFORSTRIP,X
cmp TUNE
beq PLAYINGSAMETUNE
jsr STARTTUNE
PLAYINGSAMETUNE:
lda #239 - 12
sta Y_SCROLL
jmp TURNINTERON
CHECKOFFSCREEN:
ldx MAPNO
lda MAPHEIGHTS,X
sta TEMP
lda KILLED
bne @_1
lda ROBINY
sta TEMP8
cmp #32
bcc GOINGOFFTOP
cmp #216
bcc @_1
cmp #240
bcs GOINGOFFBOTTOM
jsr SETONLADDERVARS
@_1:
rts
GOINGOFFTOP:
lda ROBINY
clc
adc #208
sta ROBINY
inc TEMP
bne CHANGINGSCREEN
GOINGOFFBOTTOM:
lda ROBINY
sec
sbc #208
sta ROBINY
dec TEMP
CHANGINGSCREEN:
lda MAPNO
asl
asl
clc
adc MAPNO
clc
adc MAPNO
tay
ldx MAPINFO + 2,Y
lda ROBINXL
clc
adc TIMES16LO,X
sta ADDRESS
lda ROBINXH
adc TIMES16HI,X
sta ADDRESS + 1
ldx #12
stx TEMP9
DOEACHMAP:
lda MAPHEIGHTS,X
cmp TEMP
beq POSSIBLEMAP
TRYNEXTMAP:
dec TEMP9
ldx TEMP9
bpl DOEACHMAP
lda TEMP8
cmp #8
bcs @_1
lda #8
bne @_2
@_1:
cmp #248
bcc @_2
lda 247
@_2:
sta ROBINY
rts
POSSIBLEMAP:
txa
asl
asl
clc
adc TEMP9
clc
adc TEMP9
tay
ldx MAPINFO + 2,Y
lda TIMES16HI,X
cmp ADDRESS + 1
bne @_1
lda TIMES16LO,X
cmp ADDRESS
@_1:
bcs TRYNEXTMAP
lda MAPINFO + 2,Y
clc
adc MAPINFO + 3,Y
tax
lda TIMES16HI,X
cmp ADDRESS + 1
bne @_2
lda TIMES16LO,X
cmp ADDRESS
@_2:
bcc TRYNEXTMAP
jsr SETONLADDERVARS
lda #0
sta VOICE1
sta VOICE2
sta VOICE3
sta VOICE4
lda TEMP9
sta MAPNO
jmp GOINTONEWMAP
MAPINFO:
.byte <(MAPB - 14)
.byte >(MAPB - 14)
.byte $58
.byte $48
.byte <(LAVAPAL)
.byte <(DUNGEONSCHRS)
.byte <(MAPC - 14)
.byte >(MAPC - 14)
.byte $20
.byte $20
.byte <(WATERPAL)
.byte <(DUNGEONSCHRS)
.byte <(MAPD - 14)
.byte >(MAPD - 14)
.byte $50
.byte $10
.byte <(WATERPAL)
.byte <(DUNGEONSCHRS)
.byte <(MAPE - 14)
.byte >(MAPE - 14)
.byte $80
.byte $40
.byte <(WATERPAL)
.byte <(DUNGEONSCHRS)
.byte <(MAPF - 14)
.byte >(MAPF - 14)
.byte $00
.byte $D0
.byte <(DUNGEONSPAL)
.byte <(DUNGEONSCHRS)
.byte <(MAPG - 14)
.byte >(MAPG - 14)
.byte $00
.byte $B0
.byte <(KITCHENSPAL)
.byte <(HALLSCHRS)
.byte <(MAPH - 14)
.byte >(MAPH - 14)
.byte $00
.byte $B0
.byte <(HALLSPAL)
.byte <(CHURCHCHRS)
.byte <(MAPI - 14)
.byte >(MAPI - 14)
.byte $10
.byte $A0
.byte <(CHURCHPAL)
.byte <(SKYCHRS)
.byte <(MAPJ - 14)
.byte >(MAPJ - 14)
.byte $10
.byte $28
.byte <(BEDROOMSPAL)
.byte <(CHURCHCHRS)
.byte <(MAPL - 14)
.byte >(MAPL - 14)
.byte $90
.byte $20
.byte <(SKYPAL)
.byte <(SKYCHRS)
.byte <(MAPM - 14)
.byte >(MAPM - 14)
.byte $18
.byte $18
.byte <(SKYPAL)
.byte <(SKYCHRS)
.byte <(MAPN - 14)
.byte >(MAPN - 14)
.byte $58
.byte $20
.byte <(CHURCHPAL)
.byte <(CHURCHCHRS)
.byte <(MAPO - 14)
.byte >(MAPO - 14)
.byte $6A
.byte $10
.byte <(SKYPAL)
.byte <(SKYCHRS)
TUNEFORSTRIP:
.byte $06
.byte $08
.byte $08
.byte $08
.byte $06
.byte $07
.byte $09
.byte $09
.byte $07
.byte $07
.byte $08
.byte $08
.byte $08
