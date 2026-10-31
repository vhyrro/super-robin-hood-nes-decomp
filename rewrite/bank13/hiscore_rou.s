SIZEOFMESSAGE = 17
NUMBERENTRIES = 10
SIZEOFSCORE = 7
SIZEOFNAME = 9
NAMETRAILNO = 0
NAMENUMAFTER = 1
HIGHSCORES = HISCORESINRAM
TRYHISCORE:
lda #<(HIGHSCORES + NUMBERENTRIES * SIZEOFMESSAGE - SIZEOFSCORE - NAMENUMAFTER)
sta ADDRESS
lda #>(HIGHSCORES + NUMBERENTRIES * SIZEOFMESSAGE - SIZEOFSCORE - NAMENUMAFTER)
sta ADDRESS + 1
lda #0
sta HIPOS
ldx #NUMBERENTRIES
AAS:
ldy #0
IAS2:
lda (ADDRESS),Y
cmp #32
bne SDF
lda #33 + 0
SDF:
cmp SCORE,Y
beq INGE2
bcc HIRE2
jmp ENBL2
INGE2:
iny
cpy #SIZEOFSCORE
bne IAS2
jmp HIRE2
ENBL2:
jmp OVHI2
HIRE2:
lda ADDRESS
sta ADDRESS2
lda ADDRESS + 1
sta ADDRESS2 + 1
inc HIPOS
LIDY:
lda ADDRESS
clc
adc #<((-SIZEOFMESSAGE))
sta ADDRESS
lda ADDRESS + 1
adc #>((-SIZEOFMESSAGE))
sta ADDRESS + 1
dex
bne AAS
OVHI2:
lda HIPOS
bne OCH1
jmp NOTAHIGH
OCH1:
cmp #1
beq NUFR
lda #<(HIGHSCORES + (NUMBERENTRIES - 1) * SIZEOFMESSAGE + NAMETRAILNO)
sta ADDRESS
lda #>(HIGHSCORES + (NUMBERENTRIES - 1) * SIZEOFMESSAGE + NAMETRAILNO)
sta ADDRESS + 1
ldx HIPOS
dex
stx TEMP
MOVV:
lda ADDRESS
clc
adc #<((-SIZEOFMESSAGE))
sta ADDRESS3
lda ADDRESS + 1
adc #>((-SIZEOFMESSAGE))
sta ADDRESS3 + 1
ldy #SIZEOFMESSAGE - NAMETRAILNO - NAMENUMAFTER - 1
@M274__1:
lda (ADDRESS3),Y
sta (ADDRESS),Y
dey
bpl @M274__1
lda ADDRESS3
sta ADDRESS
lda ADDRESS3 + 1
sta ADDRESS + 1
dec TEMP
bne MOVV
NUFR:
COPYSCOREACROSS:
ldy #0
@_1:
lda SCORE,Y
sta (ADDRESS2),Y
iny
cpy #SIZEOFSCORE
bne @_1
COPYNAMEACROSS:
lda ADDRESS2
clc
adc #<((-SIZEOFNAME))
sta MAPPOINTER
lda ADDRESS2 + 1
adc #>((-SIZEOFNAME))
sta MAPPOINTER + 1
ldy #SIZEOFNAME - 1
@_1:
lda NAME,Y
sta (MAPPOINTER),Y
dey
bpl @_1
lda #NUMBERENTRIES
sec
sbc HIPOS
sta HIPOS
rts
NOTAHIGH:
lda #255
sta HIPOS
rts
NAMELEN = TEMP9
LETTER = TEMP8
TRYTOENTERNAME:
ldx #<(CLEARSCR)
ldy #>(CLEARSCR)
jsr PRTMESSAGE
MISSLEADINGNOUGHTS:
ldy #0
sty TEMP
@_1:
lda SCORE,Y
bit TEMP
bmi @_2
cmp #0
beq @_3
dec TEMP
bne @_2
@_3:
lda #($FD)
@_2:
sta SCORE,Y
iny
cpy #6
bne @_1
PUTINCOMMER:
ldx #5
ldy #6
@_2:
lda SCORE,X
clc
adc #33
sta SCORE,Y
cpx #3
bne @_3
dey
lda #29
sta SCORE,Y
@_3:
dey
dex
bpl @_2
jsr TRYHISCORE
DISPLAYHISCORES:
jsr SETUPHISCORES
lda TUNE
cmp #1
beq @_1
lda #3
jsr STARTTUNE
@_1:
jsr TURNINTERON
lda #0
sta NAMELEN
lda #1
sta LETTER
LOOKINGATHISCORES:
asl FLYFLAG
@M280__1:
bit FLYFLAG
bpl @M280__1
bit HIPOS
bmi @_1
jsr ENTERNAME
jmp @_2
@_1:
ldx #13
jsr PULSECOLOUR
@_2:
lda PAD
and #STMASK
beq LOOKINGATHISCORES
lda DEBOUNCE
and #STMASK
bne LOOKINGATHISCORES
jmp TURNINTEROFFFADE
SETUPHISCORES:
lda #HISCORECHRS0_43
jsr COPYBLOCKOFCOMPACTEDCHRS
lda #HISCORECHRS0_43S
jsr COPYBLOCKOFCOMPACTEDCHRS
lda #OKCHR0_1
jsr COPYBLOCKOFCOMPACTEDCHRS
ldx #<(HISCORESCREEN)
ldy #>(HISCORESCREEN)
jsr PRTMESSAGE
lda #100
sta ROBINY
lda HIPOS
cmp #254
beq SHOWCREDITS
ldx #<(HISCOREMESS)
ldy #>(HISCOREMESS)
jsr PRTMESSAGE
lda HIPOS
bmi @_1
ldx #<(ENTERNAMEMESS)
ldy #>(ENTERNAMEMESS)
jmp PRINTEDENTERNAME
@_1:
ldx #<(HISCOREPRESSSTART)
ldy #>(HISCOREPRESSSTART)
jmp PRINTEDENTERNAME
SHOWCREDITS:
ldx #<(CREDITS)
ldy #>(CREDITS)
PRINTEDENTERNAME:
jsr PRTMESSAGE
jsr CLEARSPRITEBLOCK
ldx #<(HISCORESCREENCOLOURS)
ldy #>(HISCORESCREENCOLOURS)
jmp SETFADE
ENTERNAME:
lda COUNTER
and #7
bne CHOOSELETTER
lda PAD
and #UMASK + RMASK
beq @_1
inc LETTER
lda #LEFTRIGHTLETTERFX
jsr SOUNDFX
@_1:
lda PAD
and #DMASK + LMASK
beq @_2
dec LETTER
lda #LEFTRIGHTLETTERFX
jsr SOUNDFX
@_2:
lda LETTER
and #31
sta LETTER
CHOOSELETTER:
lda PAD
and #AMASK
beq @_1
lda DEBOUNCE
and #AMASK
bne @_1
lda LETTER
bne @_2
lda #STMASK
sta PAD
jmp @_1
@_2:
lda NAMELEN
cmp #8
beq @_1
lda LETTER
jsr PRINTACHR
lda LETTER
ldy NAMELEN
sta (MAPPOINTER),Y
inc NAMELEN
lda #CHOOSELETTERFX
jsr SOUNDFX
lda LETTER
jmp FLASHLETTER
@_1:
DELETELETTER:
lda PAD
and #BMASK
beq @_1
lda DEBOUNCE
and #BMASK
bne @_1
ldy NAMELEN
beq @_1
dec NAMELEN
lda #30
dey
sta (MAPPOINTER),Y
jsr PRINTACHR
lda #DELETELETTERFX
jsr SOUNDFX
@_1:
FLASHLETTER:
lda #0
sta TEMP
lda NAMELEN
asl
asl
asl
clc
adc #64
tax
lda HIPOS
asl
asl
asl
clc
adc #63 + 32
tay
lda LETTER
jsr POKESPRITE
ldx #14
jsr PULSECOLOUR
ldx #17
jmp PULSECOLOUR
PRINTACHR:
tax
lda #<(8584 - 32)
sta ADDRESS
lda #>(8584 - 32)
sta ADDRESS + 1
ldy HIPOS
@_1:
lda ADDRESS
clc
adc #<(32)
sta ADDRESS
bcc @M290__1
inc ADDRESS + 1
@M290__1:
dey
bpl @_1
ldy VRAMPOINTER
lda ADDRESS + 1
sta VRAMBUFFER,Y
lda ADDRESS
clc
adc NAMELEN
sta VRAMBUFFER + 1,Y
lda #1
sta VRAMBUFFER + 2,Y
txa
sta VRAMBUFFER + 3,Y
tya
clc
adc #4
sta VRAMPOINTER
rts
HISCORESCREEN:
.byte <(MGOSUB)
.word CLEARSCR
.byte <(MADDR + 32)
.byte $20
.byte $2B,$2C,$00,$00,$00,$32
.byte <(MDOWNLINE)
.byte $2D,$2E,$2F,$30,$33,$34,$35,$36
.byte <(MLOOP)
.byte $12
.byte $3A
.byte <(MENDLOOP)
.byte $3B,$3C,$3A,$3A,$3A,$3A
.byte $20,$20,$20,$31,$37,$38
.byte <(MLOOP)
.byte $14
.byte $39
.byte <(MENDLOOP)
.byte $3D,$3E,$39,$39,$39,$39
.byte $3F,$40,$41,$42,$4E,$4F
.byte <(MLOOP)
.byte $14
.byte $50
.byte <(MENDLOOP)
.byte $5C,$5D,$50,$50,$50,$50
.byte $43,$44,$45,$46,$51,$52,$53,$54
.byte <(MLOOP)
.byte $12
.byte $5B
.byte <(MENDLOOP)
.byte $5E,$5F,$5B,$5B,$5B,$5B
.byte $47,$48,$49,$4A,$55,$56
.byte <(MLOOP)
.byte $14
.byte $57
.byte <(MENDLOOP)
.byte $60,$55,$63,$64,$65,$00
.byte $00,$4B,$4C,$4D,$58,$59
.byte <(MLOOP)
.byte $14
.byte $5A
.byte <(MENDLOOP)
.byte $61,$62,$66,$67,$68,$00
.byte <(MADDR + 33)
.byte $03
.byte <(MLOOP)
.byte $12
.byte $00
.byte $69
.byte $6A
.byte <(MLOOP)
.byte $14
.byte $20
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $02
.byte $89
.byte $8A
.byte <(MDOWNLINE)
.byte <(MENDLOOP)
.byte <(MJUMP)
.word HISCORESCR4
HISCORESCR4:
.byte <(MLEN)
.byte $03
.byte $00,$96,$97
.byte <(MLOOP)
.byte $14
.byte <(MLEN)
.byte $01
.byte $20
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $02
.byte $B4
.byte $B5
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $03
.byte $93,$98,$99
.byte <(MLOOP)
.byte $0A
.byte <(MLEN)
.byte $02
.byte $9A
.byte $9B
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $03
.byte $B6,$B7,$B8
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $B9,$BB,$BC,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$C2,$C3,$BA
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $17
.byte $00,$BF,$00,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1
.byte <(MADDR + 35)
.byte $C0
.byte <(MLEN)
.byte $40
.byte $50,$50,$50,$50,$50,$50,$50,$50,$55,$25,$05,$05,$05,$05,$85,$55,$00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$00
.byte $00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$20,$00,$02,$00,$00,$00,$00,$08,$02
.byte <(MEND)
HISCOREFANCYBITS:
.byte <(MGOSUB)
.word HISCOREBIT
DOFLEUR:
.byte <(MADDR + 34)
.byte $E7
.byte <(MGOSUB)
.word FLEURDLYS
.byte <(MADDR + 34)
.byte $F7
FLEURDLYS:
.byte <(MLEN)
.byte $02
.byte $8B
.byte $8C
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $03
.byte $9C
.byte $9D
.byte $9E
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $03
.byte $9F
.byte $A0
.byte $A1
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $02
.byte $A2
.byte $A3
.byte <(MEND)
HISCOREBIT:
.byte <(MADDR + 33)
.byte $08
.byte $6B,$20,$6C
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $10
.byte $6D,$6E,$6F,$70,$75,$76,$77,$78,$7D,$7E,$7F,$80,$85,$86,$75,$76
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $10
.byte $71,$72,$73,$74,$79,$7A,$7B,$7C,$81,$82,$83,$84,$87,$88,$79,$7A
.byte <(MEND)
HISCOREPRESSSTART:
.byte <(MADDR + 35)
.byte $0E
.byte $10,$12,$05,$13,$13
.byte <(MDOWNLINE)
.byte $13,$14,$01,$12,$14
.byte <(MJUMP)
.word FLASHINGBIT
ENTERNAMEMESS:
.byte <(MADDR + 35)
.byte $0A
.byte $10,$0C,$05,$01,$13,$05,$20,$05,$0E,$14,$05,$12
.byte <(MDOWNLINE)
.byte $20,$19,$0F,$15,$12,$20,$0E,$01,$0D,$05
FLASHINGBIT:
.byte <(MGOSUB)
.word HISCOREFANCYBITS
.byte <(MADDR + 35)
.byte $F2
.byte <(MLEN)
.byte $04
.byte $0C
.byte $0F
.byte $0F
.byte $03
.byte <(MEND)
CREDITS:
.byte <(MADDR + 33)
.byte $07
.byte $20,$20,$20,$20,$20,$03,$12,$05,$04,$09,$14,$13
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $04,$05,$13,$09,$07,$0E,$05,$04,$20,$02,$19,$1E,$1E
.byte <(MDOWNLINE)
.byte $20,$20,$14,$08,$05,$20,$0F,$0C,$09,$16,$05,$12,$20,$14,$17,$09,$0E,$13
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $07,$12,$01,$10,$08,$09,$03,$13,$20,$02,$19,$1E,$1E
.byte <(MDOWNLINE)
.byte $20,$20,$20,$20,$20,$20,$20,$20,$10,$01,$15,$0C,$20,$01,$04,$01,$0D,$13
.byte <(MDOWNLINE)
.byte $0D,$15,$13,$09,$03,$20,$06,$18,$20,$02,$19,$1E,$1E
.byte <(MDOWNLINE)
.byte $20,$20,$20,$20,$20,$07,$01,$16,$09,$0E,$20,$12,$01,$05,$02,$15,$12,$0E
.byte <(MDOWNLINE)
.byte $0C,$09,$03,$05,$0E,$13,$05,$04,$20,$02,$19,$1E,$1E
.byte <(MDOWNLINE)
.byte $20,$20,$20,$03,$0F,$04,$05,$0D,$01,$13,$14,$05,$12,$13,$20,$0C,$14,$04
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $0F,$14,$08,$05,$12,$20,$07,$01,$0D,$05,$13,$20,$02,$19
.byte <(MDOWNLINE)
.byte $14,$08,$05,$20,$0F,$0C,$09,$16,$05,$12,$20,$14,$17,$09,$0E,$13,$1E,$1E
.byte <(MDOWNLINE)
.byte <(MDOWNLINE)
.byte $14,$08,$05,$20,$06,$1E,$20,$01,$1E,$20,$0F,$06,$20,$04,$09,$1A,$1A,$19
.byte <(MDOWNLINE)
.byte $20,$20,$02,$0D,$18,$20,$13,$09,$0D,$15,$0C,$01,$14,$0F,$12
.byte <(MDOWNLINE)
.byte $20,$20,$20,$20,$20,$06,$09,$12,$05,$08,$01,$17,$0B
.byte <(MDOWNLINE)
.byte $20,$20,$07,$0F
.byte $1B
.byte $20,$04,$09,$1A,$1A,$19,$20,$07,$0F
.byte $1B
.byte <(MEND)
HISCORESCREENCOLOURS:
.byte $21,$27,$16,$09
.byte $21,$20,$27,$0E
.byte $21,$27,$16,$0E
.byte $21,$37,$27,$09
.byte $21,$27,$11,$09
.byte $21,$20,$15,$0E
.byte $21,$00,$00,$00
.byte $21,$0E,$0E,$0E
HISCOREMESS:
.byte <(MADDR + 33)
.byte $88
.byte <(MGOSUB)
.word HISCORESINRAM
.byte <(MEND)
COPYHISCORESTORAM:
cpx #151
beq DONTCOPYINSCORES
COPYHIS:
ldx #17 * 10 + 1
COPYHISCORES:
lda INITNAMES - 1,X
sta HISCORESINRAM - 1,X
dex
bne COPYHISCORES
rts
DONTCOPYINSCORES:
ldx #0
@_1:
ldy #0
@_3:
lda CHECKHISCORES,Y
bpl @_2
cmp #131
bcs @_2
cmp #128
bne @_5
lda HISCORESINRAM,X
cmp #33
bcs COPYHIS
jmp @_4
@_5:
lda HISCORESINRAM,X
cmp #30
beq @_4
cmp #32
bcc COPYHIS
cmp #43
bcs COPYHIS
jmp @_4
@_2:
cmp HISCORESINRAM,X
bne COPYHIS
@_4:
inx
iny
cpy #17
bne @_3
cpx #10 * 17
bne @_1
lda HISCORESINRAM + 17 * 10
cmp #255
bne COPYHIS
rts
INITNAMES:
.byte $06,$09,$12,$13,$14,$1E,$1E,$1E,$1E
.byte $1E
.byte $23
.byte $21
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $13,$05,$03,$0F,$0E,$04,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $29
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $14,$08,$09,$12,$04,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $27
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $06,$0F,$15,$12,$14,$08,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $25
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $06,$09,$06,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $23
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $13,$09,$18,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $21
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $13,$05,$16,$05,$0E,$14,$08,$1E,$1E
.byte $1E
.byte $1E
.byte $29
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $05,$09,$07,$08,$14,$08,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $27
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $0E,$09,$0E,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $25
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte $14,$05,$0E,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $23
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MDOWNLINE)
.byte <(MEND)
NAME:
.byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E
CHECKHISCORES:
.res 9, 128
.byte $81
.byte $81
.byte $81
.byte $1D
.byte $81
.byte $81
.byte $81
.byte <(MDOWNLINE)
