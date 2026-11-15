titlescreen:
lda #255
sta SOLID_TILE_FOUND
stillintitle:
inc SOLID_TILE_FOUND
lda SOLID_TILE_FOUND
and #3
sta SOLID_TILE_FOUND
and #1
beq showtitle
sethiscore:
lda SOLID_TILE_FOUND
and #127
lsr
eor #255
sta HIGH_SCORE_POSITION
jsr setup_high_scores
jmp turnonscreen
showtitle:
jsr setuptitlescreen
turnonscreen:
jsr turninteron
waitforstart:
asl VBLANK_FLAG
@waitforstart_wait_vblank:
bit VBLANK_FLAG
bpl @waitforstart_wait_vblank
lda SOLID_TILE_FOUND
and #1
bne notshowingtitle
jsr putontitlesprites
jmp conttitleloop
notshowingtitle:
ldx #13
jsr pulsecolour
conttitleloop:
lda MUSIC_TUNE
bne @conttitleloop_skip_if_not_equal
lda #1
jsr starttune
@conttitleloop_skip_if_not_equal:
lda FRAME_COUNTER
and #7
bne @conttitleloop_skip_if_not_equal_2
dec PLAYER_Y
bne @conttitleloop_skip_if_not_equal_2
lda #251
sta FADE_COUNTER
@conttitleloop_skip_if_not_equal_2:
jsr waitforstartkey
beq waitforstart
lda SOLID_TILE_FOUND
bpl stillintitle
rts
putontitlesprites:
lda PPU_CONTROL_SHADOW
eor #8 + 16
@putontitlesprites_wait_vblank:
bit PPU_STATUS_REGISTER
bvs @putontitlesprites_wait_vblank
@putontitlesprites_wait_vblank_2:
bit PPU_STATUS_REGISTER
bvc @putontitlesprites_wait_vblank_2
sta PPU_CONTROL_REGISTER
ldx #25
jsr pulsecolour
ldx #16
ldy #16 - SPRITE_Y_DISPLACE
lda #SPRITE_TITLE_LOGOS
jsr printsprite
ldx #128 - 8
ldy #24 * 8 - SPRITE_Y_DISPLACE
lda #SPRITE_TITLE_LOGOS + 2
jmp printsprite
setuptitlescreen:
lda #CHARSET_TITLE_TOP
jsr copyblockofcompactedchrs
lda #CHARSET_TITLE_BOTTOM
jsr copyblockofcompactedchrs
ldx #<(title_screen_message)
ldy #>(title_screen_message)
jsr prtmessage
jsr clearspriteblock
lda #16 * 8 - 1 - 8
sta SPRITE_BLOCK_ADDRESS
lda #243
sta SPRITE_BLOCK_ADDRESS + 1
lda #3
sta SPRITE_BLOCK_ADDRESS + 2
lda #225
sta SPRITE_BLOCK_ADDRESS + 3
lda #100
sta PLAYER_Y
ldx #<(titlescreencolours)
ldy #>(titlescreencolours)
jmp setfade
titlescreencolours:
.byte $0E,$09,$17,$27
.byte $0E,$21,$09,$19
.byte $0E,$21,$17,$38
.byte $0E,$21,$00,$20
.byte $0E,$27,$11,$0E
.byte $0E,$20,$15,$0E
.byte $0E,$00,$00,$00
.byte $0E,$0E,$0E,$0E
title_screen_message:
.byte <(MESSAGE_GOSUB)
.word clearscr
.byte <(MESSAGE_ADDRESS + 32)
.byte $0A
.byte $01,$02,$05,$07,$08,$02,$05,$07,$08,$12,$1E,$1F
.byte <(MESSAGE_LOOP)
.byte $0A
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_DOWN_LINE)
.byte $03,$04,$09,$0A,$0B,$04,$09,$13,$14,$15,$21,$22
.byte <(MESSAGE_LOOP)
.byte $0A
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_DOWN_LINE)
.byte $00,$05,$0C,$0D,$0E,$0F,$16,$17,$18,$19,$23,$24
.byte <(MESSAGE_LOOP)
.byte $0A
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_DOWN_LINE)
.byte $00,$06,$05,$03,$10,$11,$1A,$1B,$1C,$1D,$25,$26,$27,$28,$29,$2A
.byte <(MESSAGE_LOOP)
.byte $06
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_DOWN_LINE)
.byte $00,$00,$00,$00,$2D,$2E,$32,$33,$34,$35,$40,$41,$42,$43,$50,$51,$52,$53,$60,$61,$20,$20
.byte <(MESSAGE_DOWN_LINE)
.byte $00,$00,$06,$03,$2F,$05,$36,$37,$34,$38,$44,$45,$46,$47,$54,$55,$56,$57,$62,$63,$64,$20
.byte <(MESSAGE_ADDRESS + 32)
.byte $C6
.byte <(MESSAGE_LOOP)
.byte $05
.byte $00
.byte <(MESSAGE_END_LOOP)
.byte $06,$03,$30,$05,$01,$39,$3A,$34,$3B,$48,$49,$4A,$4B,$58,$59,$5A,$5B,$65,$66,$67,$20
.byte <(MESSAGE_DOWN_LINE)
.byte $00,$00,$2B,$2C,$00,$06,$30,$01,$31,$05,$3C,$3D,$3E,$3F,$4C,$4D,$4E,$4F,$5C,$5D,$5E,$5F,$34,$68,$69,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $00,$2C,$6F,$70,$71,$72,$02,$05,$07,$08,$7E,$7F,$80,$81,$83,$84,$85,$86,$8C,$8D,$8E,$8F,$34,$94,$20,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $2B,$6A,$6F,$70,$73,$74,$04,$09,$0A,$0B,$1F,$20,$20,$20,$20,$87,$88,$89,$90,$91,$92,$93,$95,$96,$20,$20
.byte <(MESSAGE_JUMP)
.word title_screen_message_2
title_screen_message_2:
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $6B,$6C,$70,$75,$76,$77,$79,$0C,$0D,$7A,$82,$20,$20,$20,$87,$20,$20,$20,$20,$20,$20,$20,$97,$98,$99,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $6D,$6E,$78,$00,$00,$2B,$2C,$7B,$7C,$7D,$20,$20,$20,$20,$8A,$8B,$87,$20,$20,$20,$20,$20,$9A,$9B,$20,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $00,$00,$00,$A6,$6A,$6F,$70,$B2,$20,$B3,$BC,$BD,$20,$BE,$C8,$C9,$CA,$CB,$D1,$D2,$20,$20,$20,$20,$20,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $00,$A0,$A7,$A8,$A9,$AA,$B4,$B5,$B6,$B7,$34,$BF,$C0,$C1,$CC,$CD,$CE,$CF,$34,$D3,$BD,$20,$20,$20,$20,$20
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $7A
.byte $A1,$A2,$AB,$AC,$AD,$AE,$B8,$34,$34,$34,$34,$34,$C2,$C3,$00,$00,$00,$D0,$D4,$D5,$BF,$D6,$DA,$20,$20,$20
.byte $9C,$9D,$9E,$9F,$A3,$A4,$A5,$20,$20,$AF,$B0,$B1,$B9,$BA,$BB,$34,$C4,$C5,$C6,$C7,$00,$00,$00,$00,$D7,$D8,$B0,$D9,$DB,$20,$20,$20
.byte $01,$02,$03,$04,$09,$0A,$0B,$0C,$11,$11,$11,$11,$11,$11,$16,$17,$18,$19,$1A,$00,$00,$00,$00,$00,$1C,$1D,$1E,$11,$11,$11,$11,$11
.byte $05,$06,$07,$08,$0D,$0E,$0F,$10,$12,$13,$14,$15,$15,$11,$11,$11,$11,$11,$1B,$00,$00,$00,$00,$00,$00,$1F,$11,$11,$11,$11,$11,$11
.byte <(MESSAGE_JUMP)
.word title_screen_message_3
title_screen_message_3:
.byte <(MESSAGE_LENGTH)
.byte $CF
.byte $20,$21,$22,$23,$28,$29,$2A,$2B,$30,$31,$32,$33,$35,$36,$37,$11,$11,$11,$3C,$00,$00,$00,$00,$00,$00,$40,$41,$42,$11,$45,$46,$47
.byte $24,$25,$26,$27,$2C,$2D,$2E,$2F,$34,$34,$34,$34,$38,$39,$3A,$3B,$3D,$3E,$3F,$00,$00,$00,$00,$00,$00,$00,$43,$44,$48,$49,$49,$49
.byte $4A,$4B,$4C,$4D,$5A,$5B,$5C,$5D,$11,$11,$11,$11,$11,$11,$6C,$6D,$6E,$6F,$70,$00,$00,$00,$00,$00,$00,$00,$00,$7D,$82,$83,$84,$85
.byte $4E,$4F,$50,$51,$5E,$5F,$60,$61,$11,$11,$11,$11,$11,$11,$34,$34,$71,$72,$73,$74,$76,$77,$78,$00,$00,$00,$00,$7E,$34,$34,$86,$87
.byte $52,$53,$54,$55,$62,$63,$64,$65,$6A,$11,$11,$11,$11,$11,$34,$34,$34,$34,$34,$75,$79,$7A,$7B,$7C,$7F,$7C,$80,$81,$88,$89,$8A,$8B
.byte $56,$57,$58,$59,$66,$67,$68,$69,$6B,$11,$11,$11,$11,$11,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$8C,$8D,$8E,$8F
.byte $90,$91,$92,$93,$9F,$A0,$A1,$A2,$AE,$AF,$B0,$11,$11,$BD,$BE
.byte <(MESSAGE_LOOP)
.byte $11
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $0F
.byte $94,$95,$96,$97,$00,$A3,$A4,$A5,$B1,$B2,$B3,$B4,$BF,$C0,$C1
.byte <(MESSAGE_LOOP)
.byte $11
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $0E
.byte $98,$99,$9A,$9B,$A6,$A7,$A8,$A9,$B5,$B6,$B7,$B8,$C2,$C3
.byte <(MESSAGE_JUMP)
.word title_screen_message_4
title_screen_message_4:
.byte <(MESSAGE_LOOP)
.byte $12
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $0C
.byte $34,$9C,$9D,$9E,$AA,$AB,$AC,$AD,$B9,$BA,$BB,$BC
.byte <(MESSAGE_LOOP)
.byte $14
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $09
.byte $C4,$C5,$C6,$C7,$CC,$CD,$CE,$CF,$D4
.byte <(MESSAGE_LOOP)
.byte $17
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $08
.byte $C8,$C9,$CA,$CB,$D0,$D1,$D2,$D3
.byte <(MESSAGE_LOOP)
.byte $18
.byte $11
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $30
.byte $00,$00,$C4,$99,$AA,$A6,$A5,$55,$00,$00,$F0,$9B,$AA,$AA,$AA,$AA
.byte $00,$CC,$FF,$FB,$FA,$FA,$FA,$AA,$00,$80,$FF,$FF,$FF,$CF,$FF,$F5
.byte $00,$04,$55,$5D,$5F,$00,$7F,$5F,$00,$00,$00,$44,$55,$55,$54,$55
.byte <(MESSAGE_END)
endtitle:
pulsecolour:
ldy VRAM_WRITE_POINTER
lda #63
sta VRAM_BUFFER_ADDRESS,Y
txa
sta VRAM_BUFFER_ADDRESS + 1,Y
lda #1
sta VRAM_BUFFER_ADDRESS + 2,Y
lda FRAME_COUNTER
and #31
lsr
tax
lda pulsetable,X
sta VRAM_BUFFER_ADDRESS + 3,Y
tya
clc
adc #4
sta VRAM_WRITE_POINTER
rts
pulsetable:
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
