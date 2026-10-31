TITLESCREEN:
lda #255
sta SOLIDFOUND
STILLINTITLE:
inc SOLIDFOUND
lda SOLIDFOUND
and #3
sta SOLIDFOUND
and #1
beq SHOWTITLE
SETHISCORE:
lda SOLIDFOUND
and #127
lsr
eor #255
sta HIPOS
jsr SETUPHISCORES
jmp TURNONSCREEN
SHOWTITLE:
jsr SETUPTITLESCREEN
TURNONSCREEN:
jsr TURNINTERON
WAITFORSTART:
asl FLYFLAG
@M293__1:
bit FLYFLAG
bpl @M293__1
lda SOLIDFOUND
and #1
bne NOTSHOWINGTITLE
jsr PUTONTITLESPRITES
jmp CONTTITLELOOP
NOTSHOWINGTITLE:
ldx #13
jsr PULSECOLOUR
CONTTITLELOOP:
lda TUNE
bne @_2
lda #1
jsr STARTTUNE
@_2:
lda COUNTER
and #7
bne @_1
dec ROBINY
bne @_1
lda #251
sta FADECOUNTER
@_1:
jsr WAITFORSTARTKEY
beq WAITFORSTART
lda SOLIDFOUND
bpl STILLINTITLE
rts
PUTONTITLESPRITES:
lda CONTROL0
eor #8 + 16
@M294__2:
bit _STATUSREG
bvs @M294__2
@M294__1:
bit _STATUSREG
bvc @M294__1
sta _CONTROL0
ldx #25
jsr PULSECOLOUR
ldx #16
ldy #16 - YDISPLACE
lda #TITLELOGOS
jsr PRINTSPRITE
ldx #128 - 8
ldy #24 * 8 - YDISPLACE
lda #TITLELOGOS + 2
jmp PRINTSPRITE
SETUPTITLESCREEN:
lda #TITLETOPCHRS0_245
jsr COPYBLOCKOFCOMPACTEDCHRS
lda #TITLEBOTCHRS0_245
jsr COPYBLOCKOFCOMPACTEDCHRS
ldx #<(TITLESCREENMESS)
ldy #>(TITLESCREENMESS)
jsr PRTMESSAGE
jsr CLEARSPRITEBLOCK
lda #16 * 8 - 1 - 8
sta SPRITEBLOCK
lda #243
sta SPRITEBLOCK + 1
lda #3
sta SPRITEBLOCK + 2
lda #225
sta SPRITEBLOCK + 3
lda #100
sta ROBINY
ldx #<(TITLESCREENCOLOURS)
ldy #>(TITLESCREENCOLOURS)
jmp SETFADE
TITLESCREENCOLOURS:
.byte $0E,$09,$17,$27
.byte $0E,$21,$09,$19
.byte $0E,$21,$17,$38
.byte $0E,$21,$00,$20
.byte $0E,$27,$11,$0E
.byte $0E,$20,$15,$0E
.byte $0E,$00,$00,$00
.byte $0E,$0E,$0E,$0E
TITLESCREENMESS:
.byte <(MGOSUB)
.word CLEARSCR
.byte <(MADDR + 32)
.byte $0A
.byte $01,$02,$05,$07,$08,$02,$05,$07,$08,$12,$1E,$1F
.byte <(MLOOP)
.byte $0A
.byte $20
.byte <(MENDLOOP)
.byte <(MDOWNLINE)
.byte $03,$04,$09,$0A,$0B,$04,$09,$13,$14,$15,$21,$22
.byte <(MLOOP)
.byte $0A
.byte $20
.byte <(MENDLOOP)
.byte <(MDOWNLINE)
.byte $00,$05,$0C,$0D,$0E,$0F,$16,$17,$18,$19,$23,$24
.byte <(MLOOP)
.byte $0A
.byte $20
.byte <(MENDLOOP)
.byte <(MDOWNLINE)
.byte $00,$06,$05,$03,$10,$11,$1A,$1B,$1C,$1D,$25,$26,$27,$28,$29,$2A
.byte <(MLOOP)
.byte $06
.byte $20
.byte <(MENDLOOP)
.byte <(MDOWNLINE)
.byte $00,$00,$00,$00,$2D,$2E,$32,$33,$34,$35,$40,$41,$42,$43,$50,$51,$52,$53,$60,$61,$20,$20
.byte <(MDOWNLINE)
.byte $00,$00,$06,$03,$2F,$05,$36,$37,$34,$38,$44,$45,$46,$47,$54,$55,$56,$57,$62,$63,$64,$20
.byte <(MADDR + 32)
.byte $C6
.byte <(MLOOP)
.byte $05
.byte $00
.byte <(MENDLOOP)
.byte $06,$03,$30,$05,$01,$39,$3A,$34,$3B,$48,$49,$4A,$4B,$58,$59,$5A,$5B,$65,$66,$67,$20
.byte <(MDOWNLINE)
.byte $00,$00,$2B,$2C,$00,$06,$30,$01,$31,$05,$3C,$3D,$3E,$3F,$4C,$4D,$4E,$4F,$5C,$5D,$5E,$5F,$34,$68,$69,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $00,$2C,$6F,$70,$71,$72,$02,$05,$07,$08,$7E,$7F,$80,$81,$83,$84,$85,$86,$8C,$8D,$8E,$8F,$34,$94,$20,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $2B,$6A,$6F,$70,$73,$74,$04,$09,$0A,$0B,$1F,$20,$20,$20,$20,$87,$88,$89,$90,$91,$92,$93,$95,$96,$20,$20
.byte <(MJUMP)
.word TITLESCREENMESS2
TITLESCREENMESS2:
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $6B,$6C,$70,$75,$76,$77,$79,$0C,$0D,$7A,$82,$20,$20,$20,$87,$20,$20,$20,$20,$20,$20,$20,$97,$98,$99,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $6D,$6E,$78,$00,$00,$2B,$2C,$7B,$7C,$7D,$20,$20,$20,$20,$8A,$8B,$87,$20,$20,$20,$20,$20,$9A,$9B,$20,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $00,$00,$00,$A6,$6A,$6F,$70,$B2,$20,$B3,$BC,$BD,$20,$BE,$C8,$C9,$CA,$CB,$D1,$D2,$20,$20,$20,$20,$20,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $1A
.byte $00,$A0,$A7,$A8,$A9,$AA,$B4,$B5,$B6,$B7,$34,$BF,$C0,$C1,$CC,$CD,$CE,$CF,$34,$D3,$BD,$20,$20,$20,$20,$20
.byte <(MDOWNLINE)
.byte <(MLEN)
.byte $7A
.byte $A1,$A2,$AB,$AC,$AD,$AE,$B8,$34,$34,$34,$34,$34,$C2,$C3,$00,$00,$00,$D0,$D4,$D5,$BF,$D6,$DA,$20,$20,$20
.byte $9C,$9D,$9E,$9F,$A3,$A4,$A5,$20,$20,$AF,$B0,$B1,$B9,$BA,$BB,$34,$C4,$C5,$C6,$C7,$00,$00,$00,$00,$D7,$D8,$B0,$D9,$DB,$20,$20,$20
.byte $01,$02,$03,$04,$09,$0A,$0B,$0C,$11,$11,$11,$11,$11,$11,$16,$17,$18,$19,$1A,$00,$00,$00,$00,$00,$1C,$1D,$1E,$11,$11,$11,$11,$11
.byte $05,$06,$07,$08,$0D,$0E,$0F,$10,$12,$13,$14,$15,$15,$11,$11,$11,$11,$11,$1B,$00,$00,$00,$00,$00,$00,$1F,$11,$11,$11,$11,$11,$11
.byte <(MJUMP)
.word TITLESCREENMESS3
TITLESCREENMESS3:
.byte <(MLEN)
.byte $CF
.byte $20,$21,$22,$23,$28,$29,$2A,$2B,$30,$31,$32,$33,$35,$36,$37,$11,$11,$11,$3C,$00,$00,$00,$00,$00,$00,$40,$41,$42,$11,$45,$46,$47
.byte $24,$25,$26,$27,$2C,$2D,$2E,$2F,$34,$34,$34,$34,$38,$39,$3A,$3B,$3D,$3E,$3F,$00,$00,$00,$00,$00,$00,$00,$43,$44,$48,$49,$49,$49
.byte $4A,$4B,$4C,$4D,$5A,$5B,$5C,$5D,$11,$11,$11,$11,$11,$11,$6C,$6D,$6E,$6F,$70,$00,$00,$00,$00,$00,$00,$00,$00,$7D,$82,$83,$84,$85
.byte $4E,$4F,$50,$51,$5E,$5F,$60,$61,$11,$11,$11,$11,$11,$11,$34,$34,$71,$72,$73,$74,$76,$77,$78,$00,$00,$00,$00,$7E,$34,$34,$86,$87
.byte $52,$53,$54,$55,$62,$63,$64,$65,$6A,$11,$11,$11,$11,$11,$34,$34,$34,$34,$34,$75,$79,$7A,$7B,$7C,$7F,$7C,$80,$81,$88,$89,$8A,$8B
.byte $56,$57,$58,$59,$66,$67,$68,$69,$6B,$11,$11,$11,$11,$11,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$8C,$8D,$8E,$8F
.byte $90,$91,$92,$93,$9F,$A0,$A1,$A2,$AE,$AF,$B0,$11,$11,$BD,$BE
.byte <(MLOOP)
.byte $11
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $0F
.byte $94,$95,$96,$97,$00,$A3,$A4,$A5,$B1,$B2,$B3,$B4,$BF,$C0,$C1
.byte <(MLOOP)
.byte $11
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $0E
.byte $98,$99,$9A,$9B,$A6,$A7,$A8,$A9,$B5,$B6,$B7,$B8,$C2,$C3
.byte <(MJUMP)
.word TITLESCREENMESS4
TITLESCREENMESS4:
.byte <(MLOOP)
.byte $12
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $0C
.byte $34,$9C,$9D,$9E,$AA,$AB,$AC,$AD,$B9,$BA,$BB,$BC
.byte <(MLOOP)
.byte $14
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $09
.byte $C4,$C5,$C6,$C7,$CC,$CD,$CE,$CF,$D4
.byte <(MLOOP)
.byte $17
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $08
.byte $C8,$C9,$CA,$CB,$D0,$D1,$D2,$D3
.byte <(MLOOP)
.byte $18
.byte $11
.byte <(MENDLOOP)
.byte <(MLEN)
.byte $30
.byte $00,$00,$C4,$99,$AA,$A6,$A5,$55,$00,$00,$F0,$9B,$AA,$AA,$AA,$AA
.byte $00,$CC,$FF,$FB,$FA,$FA,$FA,$AA,$00,$80,$FF,$FF,$FF,$CF,$FF,$F5
.byte $00,$04,$55,$5D,$5F,$00,$7F,$5F,$00,$00,$00,$44,$55,$55,$54,$55
.byte <(MEND)
ENDTITLE:
PULSECOLOUR:
ldy VRAMPOINTER
lda #63
sta VRAMBUFFER,Y
txa
sta VRAMBUFFER + 1,Y
lda #1
sta VRAMBUFFER + 2,Y
lda COUNTER
and #31
lsr
tax
lda PULSETABLE,X
sta VRAMBUFFER + 3,Y
tya
clc
adc #4
sta VRAMPOINTER
rts
PULSETABLE:
.byte $17
.byte $26
.byte $27
.byte $36
.byte $37
.byte $38
.byte $30
.byte $30
.byte $30
.byte $38
.byte $37
.byte $36
.byte $27
.byte $26
.byte $17
.byte $17
