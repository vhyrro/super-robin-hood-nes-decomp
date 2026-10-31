PUTEXTRASON:
lda #0
sta EXTRAVARPOINTER
lda MAPNO
asl
tax
lda MAPROUSPOINTER,X
sta ADDRESS9
lda MAPROUSPOINTER + 1,X
sta ADDRESS9 + 1
ANOTHERROU:
ldy #0
lda (ADDRESS9),Y
asl
tax
lda ROUTINEPOINTERS,X
sta ADDRESS8
lda ROUTINEPOINTERS + 1,X
sta ADDRESS8 + 1
iny
lda (ADDRESS9),Y
sta NOOFPARAS
iny
ldx EXTRAVARPOINTER
jmp (ADDRESS8)
BACKFROMROU:
clc
adc EXTRAVARPOINTER
sta EXTRAVARPOINTER
BACKFROMROUNOVARS:
lda NOOFPARAS
clc
adc ADDRESS9
sta ADDRESS9
bcc @_1
inc ADDRESS9 + 1
@_1:
jmp ANOTHERROU
ENDOFROUS:
cpx #NOOFEXTRAVARS
bcc @_1
jsr TURNINTERON
@M787__1:
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
jmp @M787__1
@_1:
rts
MAPROUSPOINTER:
.word MAP1ROUS
.word MAP2ROUS
.word MAP3ROUS
.word MAP4ROUS
.word MAP5ROUS
.word MAP6ROUS
.word MAP7ROUS
.word MAP8ROUS
.word MAP9ROUS
.word MAP11ROUS
.word MAP12ROUS
.word MAP13ROUS
.word MAP14ROUS
XENDROUS = 0
XFLASHBLOCK = 1
XSTANDGUARD = 2
XPLATFORMH = 3
XPLATFORMV = 4
XKEY = 5
XCANON = 6
XSECRET = 7
XMARION = 8
XWATER = 9
ROUTINEPOINTERS:
.word ENDOFROUS
.word FLASHBLOCK
.word STANDGUARD
.word PLATFORMH
.word PLATFORMV
.word KEYROU
.word CANONROU
.word SECRETROU
.word MARIONROU
.word REDEFINEWATERBANK
MAP1ROUS:
.byte $05
.byte $06
.byte $15
.byte $25
.byte $38
.byte $F9
.byte $06
.byte $06
.byte $04
.byte $30
.byte $03
.byte $19
.byte $03
.byte $08
.byte $17
.byte $CC
.byte $02
.byte $34
.byte $03
.byte $9F
.byte $05
.byte $06
.byte $18
.byte $37
.byte $B8
.byte $F8
.byte $05
.byte $06
.byte $1F
.byte $3E
.byte $78
.byte $20
.byte $01
.byte $07
.byte $44
.byte $88
.byte $1B
.byte $0A
.byte $0A
.byte $01
.byte $07
.byte $43
.byte $06
.byte $1B
.byte $0A
.byte $0A
.byte $01
.byte $07
.byte $3B
.byte $88
.byte $1B
.byte $08
.byte $08
.byte $02
.byte $09
.byte $88
.byte $02
.byte $A0
.byte $03
.byte $63
.byte $05
.byte $0A
.byte $01
.byte $07
.byte $0B
.byte $89
.byte $1B
.byte $0C
.byte $06
.byte $02
.byte $0A
.byte $89
.byte $37
.byte $A0
.byte $FE
.byte $84
.byte $06
.byte $06
.byte $10
.byte $02
.byte $09
.byte $8C
.byte $46
.byte $A0
.byte $FE
.byte $02
.byte $08
.byte $08
.byte $07
.byte $06
.byte $43
.byte $01
.byte $88
.byte $0A
.byte $09
.byte $02
.byte $00
MAP2ROUS:
.byte $03
.byte $08
.byte $0C
.byte $5C
.byte $00
.byte $D4
.byte $00
.byte $9F
.byte $01
.byte $07
.byte $08
.byte $86
.byte $FC
.byte $0A
.byte $0A
.byte $01
.byte $07
.byte $09
.byte $86
.byte $FD
.byte $0A
.byte $0A
.byte $02
.byte $0B
.byte $86
.byte $0E
.byte $40
.byte $02
.byte $A3
.byte $05
.byte $05
.byte $05
.byte $0F
.byte $02
.byte $09
.byte $87
.byte $1D
.byte $A0
.byte $FE
.byte $63
.byte $05
.byte $0A
.byte $05
.byte $06
.byte $0D
.byte $0D
.byte $18
.byte $FB
.byte $07
.byte $06
.byte $40
.byte $1D
.byte $68
.byte $08
.byte $09
.byte $02
.byte $00
MAP3ROUS:
.byte $05
.byte $06
.byte $0F
.byte $02
.byte $A8
.byte $10
.byte $02
.byte $09
.byte $8A
.byte $02
.byte $90
.byte $02
.byte $62
.byte $03
.byte $0A
.byte $05
.byte $06
.byte $42
.byte $0A
.byte $B8
.byte $17
.byte $09
.byte $02
.byte $00
MAP4ROUS:
.byte $05
.byte $06
.byte $13
.byte $03
.byte $48
.byte $14
.byte $05
.byte $06
.byte $19
.byte $03
.byte $A8
.byte $F7
.byte $05
.byte $06
.byte $1A
.byte $17
.byte $48
.byte $F6
.byte $05
.byte $06
.byte $1B
.byte $31
.byte $48
.byte $1C
.byte $03
.byte $08
.byte $1C
.byte $7C
.byte $03
.byte $C4
.byte $03
.byte $7F
.byte $04
.byte $08
.byte $20
.byte $34
.byte $02
.byte $00
.byte $B8
.byte $5F
.byte $02
.byte $09
.byte $91
.byte $12
.byte $C0
.byte $02
.byte $05
.byte $03
.byte $0A
.byte $02
.byte $09
.byte $92
.byte $1B
.byte $60
.byte $FE
.byte $03
.byte $03
.byte $11
.byte $06
.byte $06
.byte $1E
.byte $40
.byte $03
.byte $0B
.byte $02
.byte $0B
.byte $93
.byte $27
.byte $C0
.byte $FE
.byte $04
.byte $04
.byte $04
.byte $08
.byte $0E
.byte $09
.byte $02
.byte $00
MAP5ROUS:
.byte $05
.byte $06
.byte $07
.byte $3D
.byte $48
.byte $FC
.byte $07
.byte $06
.byte $08
.byte $1F
.byte $98
.byte $00
.byte $05
.byte $06
.byte $09
.byte $1F
.byte $98
.byte $00
.byte $02
.byte $08
.byte $85
.byte $04
.byte $40
.byte $02
.byte $C5
.byte $14
.byte $07
.byte $06
.byte $0A
.byte $02
.byte $B8
.byte $01
.byte $05
.byte $06
.byte $0B
.byte $02
.byte $B8
.byte $0C
.byte $05
.byte $06
.byte $0E
.byte $4D
.byte $28
.byte $FA
.byte $04
.byte $08
.byte $10
.byte $2C
.byte $05
.byte $00
.byte $84
.byte $3F
.byte $05
.byte $06
.byte $11
.byte $78
.byte $68
.byte $EF
.byte $03
.byte $08
.byte $14
.byte $2C
.byte $06
.byte $C4
.byte $06
.byte $AF
.byte $05
.byte $06
.byte $1D
.byte $BE
.byte $78
.byte $1E
.byte $04
.byte $08
.byte $1E
.byte $9C
.byte $0C
.byte $00
.byte $C8
.byte $3F
.byte $05
.byte $06
.byte $21
.byte $B0
.byte $38
.byte $F5
.byte $05
.byte $06
.byte $22
.byte $9A
.byte $70
.byte $23
.byte $03
.byte $08
.byte $23
.byte $FC
.byte $08
.byte $54
.byte $09
.byte $4F
.byte $02
.byte $08
.byte $8B
.byte $51
.byte $40
.byte $02
.byte $43
.byte $0D
.byte $02
.byte $09
.byte $8D
.byte $43
.byte $70
.byte $02
.byte $43
.byte $04
.byte $0A
.byte $02
.byte $0A
.byte $8E
.byte $59
.byte $D0
.byte $02
.byte $02
.byte $04
.byte $04
.byte $0C
.byte $06
.byte $07
.byte $84
.byte $60
.byte $FD
.byte $07
.byte $0D
.byte $02
.byte $08
.byte $8F
.byte $8B
.byte $90
.byte $02
.byte $03
.byte $0A
.byte $01
.byte $07
.byte $83
.byte $8B
.byte $CD
.byte $08
.byte $08
.byte $01
.byte $07
.byte $84
.byte $8B
.byte $CD
.byte $08
.byte $08
.byte $07
.byte $06
.byte $90
.byte $BD
.byte $38
.byte $07
.byte $02
.byte $09
.byte $96
.byte $C0
.byte $90
.byte $FE
.byte $82
.byte $05
.byte $0C
.byte $07
.byte $06
.byte $4A
.byte $2D
.byte $A8
.byte $0F
.byte $07
.byte $06
.byte $4B
.byte $0B
.byte $B8
.byte $10
.byte $02
.byte $09
.byte $AC
.byte $CA
.byte $D0
.byte $FE
.byte $83
.byte $04
.byte $0C
.byte $07
.byte $06
.byte $51
.byte $04
.byte $58
.byte $16
.byte $09
.byte $02
.byte $00
MAP6ROUS:
.byte $05
.byte $06
.byte $00
.byte $08
.byte $A8
.byte $01
.byte $03
.byte $08
.byte $01
.byte $4C
.byte $00
.byte $A4
.byte $00
.byte $5F
.byte $05
.byte $06
.byte $02
.byte $03
.byte $58
.byte $FF
.byte $05
.byte $06
.byte $03
.byte $26
.byte $98
.byte $04
.byte $03
.byte $08
.byte $04
.byte $1C
.byte $03
.byte $92
.byte $03
.byte $6F
.byte $02
.byte $09
.byte $80
.byte $03
.byte $A0
.byte $02
.byte $01
.byte $0E
.byte $05
.byte $05
.byte $06
.byte $05
.byte $56
.byte $28
.byte $FE
.byte $05
.byte $06
.byte $06
.byte $4C
.byte $78
.byte $FD
.byte $02
.byte $08
.byte $81
.byte $21
.byte $D0
.byte $FE
.byte $E2
.byte $1E
.byte $02
.byte $08
.byte $82
.byte $44
.byte $60
.byte $FE
.byte $82
.byte $0D
.byte $02
.byte $08
.byte $83
.byte $54
.byte $60
.byte $FE
.byte $02
.byte $14
.byte $02
.byte $09
.byte $84
.byte $4E
.byte $90
.byte $01
.byte $43
.byte $0F
.byte $14
.byte $02
.byte $09
.byte $12
.byte $73
.byte $80
.byte $FE
.byte $41
.byte $05
.byte $14
.byte $05
.byte $06
.byte $16
.byte $63
.byte $38
.byte $00
.byte $07
.byte $06
.byte $41
.byte $63
.byte $38
.byte $09
.byte $05
.byte $06
.byte $24
.byte $A6
.byte $58
.byte $25
.byte $04
.byte $08
.byte $25
.byte $D0
.byte $0A
.byte $00
.byte $A6
.byte $4F
.byte $06
.byte $06
.byte $A8
.byte $40
.byte $FC
.byte $09
.byte $02
.byte $0A
.byte $94
.byte $8C
.byte $90
.byte $02
.byte $83
.byte $05
.byte $05
.byte $14
.byte $02
.byte $09
.byte $9E
.byte $5F
.byte $A0
.byte $02
.byte $02
.byte $05
.byte $14
.byte $07
.byte $06
.byte $44
.byte $5D
.byte $78
.byte $0B
.byte $07
.byte $06
.byte $49
.byte $17
.byte $18
.byte $0E
.byte $07
.byte $06
.byte $52
.byte $AD
.byte $28
.byte $17
.byte $00
MAP7ROUS:
.byte $05
.byte $06
.byte $26
.byte $95
.byte $C8
.byte $27
.byte $03
.byte $08
.byte $27
.byte $4C
.byte $09
.byte $B4
.byte $09
.byte $6F
.byte $01
.byte $07
.byte $AB
.byte $89
.byte $F8
.byte $14
.byte $14
.byte $05
.byte $06
.byte $30
.byte $6C
.byte $C8
.byte $31
.byte $05
.byte $06
.byte $34
.byte $0A
.byte $A8
.byte $35
.byte $03
.byte $08
.byte $35
.byte $AC
.byte $02
.byte $44
.byte $03
.byte $3F
.byte $05
.byte $06
.byte $36
.byte $49
.byte $28
.byte $F1
.byte $06
.byte $06
.byte $71
.byte $60
.byte $03
.byte $0A
.byte $02
.byte $08
.byte $95
.byte $A6
.byte $40
.byte $FE
.byte $82
.byte $0D
.byte $06
.byte $06
.byte $47
.byte $60
.byte $03
.byte $18
.byte $02
.byte $09
.byte $98
.byte $11
.byte $A0
.byte $02
.byte $04
.byte $0A
.byte $04
.byte $02
.byte $0A
.byte $99
.byte $21
.byte $A0
.byte $02
.byte $02
.byte $04
.byte $04
.byte $08
.byte $02
.byte $0B
.byte $9A
.byte $0E
.byte $D0
.byte $FE
.byte $04
.byte $04
.byte $04
.byte $08
.byte $08
.byte $02
.byte $08
.byte $A6
.byte $36
.byte $40
.byte $FE
.byte $82
.byte $0C
.byte $07
.byte $06
.byte $4C
.byte $1D
.byte $A0
.byte $11
.byte $07
.byte $06
.byte $4D
.byte $44
.byte $40
.byte $12
.byte $02
.byte $09
.byte $A7
.byte $68
.byte $D0
.byte $FE
.byte $01
.byte $07
.byte $0E
.byte $07
.byte $06
.byte $4E
.byte $8C
.byte $18
.byte $13
.byte $00
MAP8ROUS:
.byte $07
.byte $06
.byte $28
.byte $90
.byte $D0
.byte $02
.byte $05
.byte $06
.byte $29
.byte $93
.byte $88
.byte $00
.byte $07
.byte $06
.byte $2B
.byte $93
.byte $88
.byte $03
.byte $05
.byte $06
.byte $2A
.byte $98
.byte $48
.byte $F4
.byte $01
.byte $07
.byte $9C
.byte $85
.byte $FD
.byte $0A
.byte $23
.byte $01
.byte $07
.byte $9E
.byte $87
.byte $FD
.byte $0F
.byte $1E
.byte $01
.byte $07
.byte $9C
.byte $89
.byte $FD
.byte $14
.byte $19
.byte $01
.byte $07
.byte $9E
.byte $8B
.byte $FD
.byte $19
.byte $14
.byte $05
.byte $06
.byte $2E
.byte $68
.byte $B8
.byte $00
.byte $07
.byte $06
.byte $2F
.byte $68
.byte $B8
.byte $05
.byte $03
.byte $08
.byte $31
.byte $2C
.byte $05
.byte $74
.byte $05
.byte $7F
.byte $01
.byte $07
.byte $55
.byte $04
.byte $1B
.byte $0A
.byte $0A
.byte $01
.byte $07
.byte $58
.byte $04
.byte $1B
.byte $0A
.byte $0A
.byte $05
.byte $06
.byte $37
.byte $30
.byte $68
.byte $38
.byte $03
.byte $08
.byte $38
.byte $FC
.byte $00
.byte $54
.byte $01
.byte $3F
.byte $03
.byte $08
.byte $3A
.byte $7C
.byte $01
.byte $C4
.byte $01
.byte $3F
.byte $03
.byte $08
.byte $3C
.byte $4C
.byte $02
.byte $C4
.byte $02
.byte $3F
.byte $02
.byte $09
.byte $97
.byte $96
.byte $50
.byte $02
.byte $83
.byte $14
.byte $19
.byte $06
.byte $06
.byte $89
.byte $C0
.byte $03
.byte $12
.byte $02
.byte $0A
.byte $9B
.byte $7F
.byte $D0
.byte $FE
.byte $83
.byte $03
.byte $03
.byte $0A
.byte $06
.byte $07
.byte $76
.byte $50
.byte $03
.byte $10
.byte $16
.byte $05
.byte $06
.byte $45
.byte $78
.byte $88
.byte $46
.byte $03
.byte $08
.byte $46
.byte $9C
.byte $07
.byte $34
.byte $08
.byte $5F
.byte $02
.byte $0A
.byte $A2
.byte $3C
.byte $D0
.byte $FE
.byte $05
.byte $05
.byte $05
.byte $0A
.byte $02
.byte $0B
.byte $A3
.byte $44
.byte $70
.byte $FE
.byte $83
.byte $04
.byte $04
.byte $08
.byte $08
.byte $02
.byte $0A
.byte $A4
.byte $19
.byte $D0
.byte $02
.byte $83
.byte $05
.byte $05
.byte $0A
.byte $02
.byte $09
.byte $A5
.byte $12
.byte $D0
.byte $02
.byte $05
.byte $0A
.byte $0A
.byte $07
.byte $06
.byte $48
.byte $16
.byte $58
.byte $0D
.byte $02
.byte $0A
.byte $A9
.byte $03
.byte $70
.byte $02
.byte $05
.byte $04
.byte $03
.byte $08
.byte $02
.byte $0A
.byte $AD
.byte $5B
.byte $40
.byte $02
.byte $03
.byte $04
.byte $03
.byte $08
.byte $07
.byte $06
.byte $50
.byte $95
.byte $18
.byte $15
.byte $00
MAP9ROUS:
.byte $05
.byte $06
.byte $39
.byte $1E
.byte $B8
.byte $3A
.byte $05
.byte $06
.byte $3F
.byte $04
.byte $38
.byte $F0
.byte $02
.byte $08
.byte $A1
.byte $1A
.byte $60
.byte $FE
.byte $04
.byte $0C
.byte $07
.byte $06
.byte $47
.byte $18
.byte $88
.byte $0C
.byte $02
.byte $0C
.byte $AA
.byte $0A
.byte $D0
.byte $FE
.byte $82
.byte $03
.byte $03
.byte $03
.byte $03
.byte $09
.byte $00
MAP11ROUS:
.byte $05
.byte $06
.byte $2C
.byte $04
.byte $28
.byte $00
.byte $07
.byte $06
.byte $2D
.byte $04
.byte $28
.byte $04
.byte $02
.byte $0B
.byte $9F
.byte $1D
.byte $D0
.byte $FE
.byte $84
.byte $03
.byte $03
.byte $07
.byte $07
.byte $02
.byte $08
.byte $A0
.byte $0C
.byte $90
.byte $02
.byte $02
.byte $07
.byte $07
.byte $06
.byte $4F
.byte $1C
.byte $20
.byte $14
.byte $00
MAP12ROUS:
.byte $05
.byte $06
.byte $3B
.byte $01
.byte $88
.byte $3C
.byte $05
.byte $06
.byte $3D
.byte $13
.byte $18
.byte $00
.byte $07
.byte $06
.byte $3E
.byte $13
.byte $18
.byte $06
.byte $02
.byte $08
.byte $AB
.byte $0A
.byte $D0
.byte $FE
.byte $04
.byte $05
.byte $00
MAP13ROUS:
.byte $05
.byte $06
.byte $32
.byte $1D
.byte $58
.byte $F3
.byte $05
.byte $06
.byte $33
.byte $03
.byte $68
.byte $F2
.byte $02
.byte $0A
.byte $9C
.byte $15
.byte $D0
.byte $FE
.byte $04
.byte $04
.byte $04
.byte $0C
.byte $00
MAP14ROUS:
.byte $08
.byte $05
.byte $00
.byte $0E
.byte $30
.byte $02
.byte $08
.byte $9D
.byte $02
.byte $D0
.byte $02
.byte $05
.byte $09
.byte $00
NOOFEXTRAS = 255
EXTRASON = VARLIM
VARLIM .set VARLIM + 32
SECRET = VARLIM
VARLIM .set VARLIM + 3 + 6 + 6
DOORDATA:
.byte $05
.byte $0E
.byte $45
.byte $05
.byte $4F
.byte $2C
.byte $05
.byte $37
.byte $2C
.byte $04
.byte $1D
.byte $25
.byte $04
.byte $4A
.byte $23
.byte $04
.byte $4C
.byte $2B
.byte $00
.byte $1F
.byte $2B
.byte $00
.byte $31
.byte $24
.byte $03
.byte $0F
.byte $35
.byte $03
.byte $2F
.byte $3B
.byte $04
.byte $92
.byte $2C
.byte $07
.byte $92
.byte $28
.byte $07
.byte $4A
.byte $3C
.byte $0B
.byte $11
.byte $4C
.byte $06
.byte $61
.byte $4C
.byte $0B
.byte $17
.byte $23
.byte $05
.byte $80
.byte $1C
ENDOFDOORDATA:
NOOFDOORS = (ENDOFDOORDATA - DOORDATA) / 3 + 1
RESETEXTRAVARS:
lda #>(RESETVARS)
sta ADDRESS + 1
lda #0
sta ADDRESS
ldy #<(RESETVARS)
@_1:
sta (ADDRESS),Y
iny
bne @_2
inc ADDRESS + 1
@_2:
cpy #<(ENDOFRESETVARS)
bne @_1
ldx #>(ENDOFRESETVARS)
cpx ADDRESS + 1
bne @_1
rts
RESETEXTRAS:
lda #255
ldx #NOOFEXTRAS / 8 + 1
@_1:
sta EXTRASON,X
dex
bpl @_1
lda #0
ldx #3 + 6 + 6 - 1
@_2:
sta SECRET,X
dex
bpl @_2
rts
PICKUPCOLLISION1:
ldy #4
lda (ADDRESS9),Y
tay
PICKUPCOLLISION:
bit ROBINCROUCH
bmi CROUCHCOLLIDE
sec
sbc ROBINY
clc
adc #32 + 2
cmp #40 + 2
bcs NOPICKCOLL
bcc NOWTHEX
CROUCHCOLLIDE:
sec
sbc ROBINY
clc
adc #32 + 8 - 16
cmp #40 + 8 - 16
bcs NOPICKCOLL
NOWTHEX:
lda ADDRESS8
sec
sbc ROBINONSCRX
clc
adc #12
cmp #24
NOPICKCOLL:
rts
BITPATTERN:
.byte $80
.byte $40
.byte $20
.byte $10
.byte $08
.byte $04
.byte $02
.byte $01
CHECKIFEXTRAON:
lda (ADDRESS9),Y
CHECKIFDOORON:
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda EXTRASON,Y
and BITPATTERN,X
rts
TURNOFFEXTRA:
ldy #2
lda (ADDRESS9),Y
TURNOFFDOOR:
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda EXTRASON,Y
eor BITPATTERN,X
sta EXTRASON,Y
rts
CHECKONSCREENSIDES:
ldy #3
CHECKONSCREENSIDES1:
lda (ADDRESS9),Y
sec
sbc SCRXL
sta ADDRESS7
iny
lda (ADDRESS9),Y
sbc SCRXH
sta XCOORDH
clc
adc #1
cmp #3
rts
HTEMPY = TEMP1
HTEMPX = TEMP2
YMINUS = TEMP3
HTEMPCHR = TEMP4
HTEMPPRTX = TEMP5
HTEMPPRTY = TEMP6
HTEMPANGLE = TEMP7
HTEMPCOL = TEMP8
HTEMPSIZE = TEMP9
XMINUS = ADDRESS5 + 1
NOOFHPARAS = ADDRESS7
HTEMPROU = ADDRESS6
HTEMPXREG = ADDRESS6 + 1
STARTSTARSTABLE:
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $33
.byte $80
.byte $04
.byte $00
.byte $10
.byte $10
.byte $04
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $35
.byte $81
.byte $00
.byte $00
.byte $04
.byte $1A
.byte $08
.byte $0D
.byte $04
.byte $13
.byte $00
.byte $06
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $32
.byte $83
.byte $FC
.byte $00
.byte $FC
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $9A
.byte $11
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $97
.byte $23
.byte $05
.byte $04
.byte $00
.byte $04
.byte $10
.byte $04
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $97
.byte $25
.byte $06
.byte $04
.byte $00
.byte $04
.byte $1A
.byte $04
.byte $0D
.byte $04
.byte $13
.byte $04
.byte $06
.byte $01
.byte $00
.byte $00
.byte $96
.byte $11
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $31
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
STARTSTARS:
sta TEMP2
ldx #0
lda HEARTSTABLE,X
beq GOTSTARSX
ldx #16
lda HEARTSTABLE,X
beq GOTSTARSX
ldx #32
lda HEARTSTABLE,X
beq GOTSTARSX
ldx #0
GOTSTARSX:
stx TEMP1
lda TEMP2
asl
asl
asl
asl
tay
lda #16
sta TEMP2
@_2:
lda STARTSTARSTABLE,Y
sta HEARTSTABLE,X
iny
inx
dec TEMP2
bne @_2
ldx TEMP1
lda ADDRESS8 + 1
sta HEARTSTABLE + 2,X
lda ADDRESS7
sta HEARTSTABLE + 0,X
lda ADDRESS7 + 1
sta HEARTSTABLE + 1,X
rts
DOORROU:
lda ANIMATEDOOR
beq ENDDOOR
and #7
bne DONEDOOR
lda #DOORLIFTINGFX
jsr SOUNDFX
lda ANIMATEDOOR
cmp #8
beq FINISHDOOR
and #15
beq OVERBOUNDRY
ldx DOORX
ldy DOORY
lda #1
jsr ADDACHANGEDBLOCK
jmp DONEDOOR
OVERBOUNDRY:
ldx DOORX
ldy DOORY
dey
lda #2
jsr ADDACHANGEDBLOCK
FINISHDOOR:
ldx DOORX
ldy DOORY
jsr DELETEACHANGEDBLOCK
dec DOORY
DONEDOOR:
dec ANIMATEDOOR
ENDDOOR:
rts
CLOSEDOOR:
ldx DOORX
ldy DOORY
lda #2
jsr ADDACHANGEDBLOCK
dec DOORY
@_2:
ldx DOORX
ldy DOORY
lda #3
jsr ADDACHANGEDBLOCK
dec DOORY
lda ANIMATEDOOR
clc
adc #($F0)
sta ANIMATEDOOR
cmp #8
bne @_2
@_1:
rts
OPENADOOR:
sta TEMP
jsr TURNOFFDOOR
OPENADOOR1:
lda #255
sec
sbc TEMP
sta TEMP1
asl
clc
adc TEMP1
tax
lda DOORDATA,X
cmp MAPNO
bne @_1
lda DOORDATA + 2,X
and #15
sta DOORY
lda DOORDATA + 2,X
and #240
clc
adc #8
sta ANIMATEDOOR
lda DOORDATA + 1,X
sta DOORX
lda #0
@_1:
rts
RESETDOORSINTOMAP:
lda #255
@_1:
sta TEMP
jsr CHECKIFDOORON
beq @_2
jsr OPENADOOR1
bne @_2
@_3:
lda TEMP
pha
jsr CLOSEDOOR
pla
sta TEMP
@_2:
dec TEMP
lda TEMP
cmp #255 - NOOFDOORS
bne @_1
rts
ROBINSHOOTARROW:
lda ROBINXL
sta ARROWXL
lda ROBINXH
sta ARROWXH
lda ROBINY
clc
adc #($E8)
sta ARROWY
ldx #4
lda OLEFTRIGHT
bpl @_1
ldx #($FC)
lda ARROWXL
sec
sbc #8
sta ARROWXL
bcs @_1
dec ARROWXH
@_1:
stx ARROWDIR
lda #40
sta ARROWCOUNTER
rts
SHOOTARROW:
sta TEMP
ldx #1
@_1:
lda ARROWCOUNTER,X
beq GOTARROWPOS
inx
cpx #NOOFARROWS
bne @_1
rts
GOTARROWPOS:
lda (ADDRESS9),Y
ldy #0
sta ARROWDIR,X
cmp #0
bpl @_1
ldy #255
@_1:
lda #100
sta ARROWCOUNTER,X
lda #0
sta ARROWCANON,X
lda ARROWDIR,X
asl
asl
clc
adc ADDRESS7
sta ARROWXL,X
tya
adc ADDRESS7 + 1
sta ARROWXH,X
lda TEMP
sta ARROWY,X
rts
ADDARROWDIR:
lda ARROWDIR,X
bpl @_3
lda ARROWXL,X
clc
adc ARROWDIR,X
sta ARROWXL,X
bcs @_4
dec ARROWXH,X
@_4:
jmp @_5
@_3:
lda ARROWXL,X
clc
adc ARROWDIR,X
sta ARROWXL,X
bcc @_5
inc ARROWXH,X
@_5:
rts
UPDATEARROWS:
ldx #0
DOEACHARROW:
lda ARROWCOUNTER,X
beq @_2
bpl @_1
@_2:
jmp NEXTARROW
@_1:
dec ARROWCOUNTER,X
CONTARROW:
jsr ADDARROWDIR
PRINTARROW:
stx TEMPX
lda ARROWXH,X
sta TEMP
lda ARROWXL,X
clc
adc #4
bcc @_2
inc TEMP
@_2:
ldy ARROWY,X
iny
iny
iny
iny
iny
iny
ldx TEMP
jsr FINDSOLID
cmp #3
bne ARROWNOTHITWALL
TAKEARROWOFF:
lda #ARROWHITWALLFX
jsr SOUNDFX
TAKEARROWOFF1:
ldx TEMPX
jsr TAKEARROWOFFROU
jmp NEXTARROW
ARROWNOTHITWALL:
ldx TEMPX
lda ARROWXL,X
sec
sbc SCRXL
sta TEMPY
lda ARROWXH,X
sbc SCRXH
bne NEXTARROW
lda ARROWDIR,X
and #64
eor ARROWCANON,X
sta TEMP
lda ARROWY,X
clc
adc #YDISPLACE
tay
lda ARROWCANON,X
beq ISANARROW
lda #150 - 121
ISANARROW:
clc
adc #121
ldx TEMPY
jsr POKESPRITE
ldx TEMPX
beq NEXTARROW
lda ARROWY,X
clc
adc #6
sec
sbc ROBINY
bcs ARROWNOTHITROBIN
lda ARROWY,X
clc
adc #2
sec
sbc ROBINHEIGHT
bcc ARROWNOTHITROBIN
lda TEMPY
sec
sbc ROBINONSCRX
clc
adc #12
cmp #24
bcs ARROWNOTHITROBIN
lda ROBININVINC
bne ARROWNOTHITROBIN
lda #1
jsr SUBFROMHEARTS
jmp TAKEARROWOFF1
ARROWNOTHITROBIN:
NEXTARROW:
inx
cpx #NOOFARROWS
beq @_1
jmp DOEACHARROW
@_1:
lda DEADARROWCOUNT
beq @_2
dec DEADARROWCOUNT
lda DEADARROWX
sec
sbc SCRXL
tax
lda DEADARROWX + 1
sbc SCRXH
sta XCOORDH
ldy DEADARROWY
lda DEADARROWCOUNT
lsr
clc
adc #DEADARROWS
jsr WINPRINTSPRITE
@_2:
rts
TAKEARROWOFFROU:
lda ARROWXL,X
sta DEADARROWX
lda ARROWXH,X
sta DEADARROWX + 1
lda ARROWY,X
sta DEADARROWY
lda #8
sta DEADARROWCOUNT
lda #0
sta ARROWY,X
sta ARROWCOUNTER,X
rts
DECTIMING:
ldx EXTRAVARPOINTER
lda EXTRAVARS,X
beq DOTIMINGPROBLEM
lda COUNTER
and #7
bne @_1
dec EXTRAVARS,X
@_1:
rts
DOTIMINGPROBLEM:
tya
eor #255
clc
adc NOOFPARAS
sta TEMP
ldx EXTRAVARPOINTER
inc EXTRAVARS + 1,X
lda EXTRAVARS + 1,X
cmp TEMP
bne @_1
lda #0
sta EXTRAVARS + 1,X
@_1:
sta TEMP
inc TEMP
@_2:
iny
dec TEMP
bne @_2
lda (ADDRESS9),Y
sta EXTRAVARS,X
rts
