RIGHT_EDGE_OFFSET = 18
attributemasks:
.byte $FC
.byte $F3
.byte $CF
.byte $3F
attributeands:
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
setxscroll:
lda SCREEN_X_LOW
sta TEMP_POINTER_2
lda SCREEN_X_LOW + 1
sta TEMP_POINTER_2 + 1
lda PLAYER_X_LOW
sec
sbc #120
sta TEMP_POINTER_2
lda PLAYER_X_HIGH
sbc #0
cmp #255
bne @setxscroll_skip_if_not_equal
lda #0
sta TEMP_POINTER_2
@setxscroll_skip_if_not_equal:
sta TEMP_POINTER_2 + 1
lda TEMP_POINTER_2 + 1
sta TEMP_BYTE
lda TEMP_POINTER_2
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
sta MAP_STRIP
cmp #0
bcc mapnotmoved
cmp MAX_MAP
bcc printmapdownside
lda MAX_MAP
sta MAP_STRIP
ldx #0
stx TEMP_POINTER_2 + 1
asl
rol TEMP_POINTER_2 + 1
asl
rol TEMP_POINTER_2 + 1
asl
rol TEMP_POINTER_2 + 1
asl
rol TEMP_POINTER_2 + 1
sta TEMP_POINTER_2
@setxscroll_body:
printmapdownside:
lda SCREEN_X_LOW + 1
cmp TEMP_POINTER_2 + 1
bne @printmapdownside_skip_if_not_equal
lda SCREEN_X_LOW
cmp TEMP_POINTER_2
@printmapdownside_skip_if_not_equal:
beq mapnotmoved
bcs decmapset
printmapdownside1:
ldx #255
inc SCREEN_X_LOW
bne @printmapdownside1_skip_if_not_equal
inc SCREEN_X_LOW + 1
@printmapdownside1_skip_if_not_equal:
jmp setmapset
decmapset:
dec SCREEN_X_LOW
pha
lda #255
cmp SCREEN_X_LOW
bne @decmapset_skip_if_not_equal
dec SCREEN_X_LOW + 1
@decmapset_skip_if_not_equal:
pla
ldx #0
setmapset:
stx SCROLL_DIRECTION
lda SCREEN_X_HIGH
sta TEMP_BYTE
lda SCREEN_X_LOW
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
sta MAP_STRIP
jsr bringonmap
lda INTERRUPT_ENABLED
bne printmapdownside
jsr empty_block_buffer
jmp printmapdownside
mapnotmoved:
@mapnotmoved_body:
lsr PPU_CONTROL_SHADOW
lda SCREEN_X_LOW
clc
adc #16
sta SCROLL_X
lda SCREEN_X_HIGH
adc #0
lsr
rol PPU_CONTROL_SHADOW
rts
times14tablelo:
TABLE_OFFSET .set 0
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $38
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $46
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $54
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $62
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $70
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $18
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $26
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $34
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $42
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $50
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $88
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $96
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $14
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $22
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $30
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $68
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $76
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $84
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $92
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $10
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $48
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $56
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $64
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $72
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $80
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $28
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $36
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $44
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $52
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $60
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $98
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $16
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $24
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $32
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $40
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $78
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $86
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $94
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $12
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $20
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $58
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $66
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $74
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $82
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $90
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $38
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $46
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $54
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $62
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $70
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $18
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $26
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $34
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $42
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $50
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $88
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $96
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $14
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $22
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $30
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $68
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $76
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $84
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $92
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $10
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $48
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $56
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $64
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $72
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $80
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $1A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $28
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $36
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $44
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $52
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $60
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $7C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $8A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $98
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $EC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $FA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $16
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $24
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $32
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $40
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $5C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $6A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $78
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $86
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $94
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $A2
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $B0
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BE
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $CC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $DA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $12
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $20
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $2E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $3C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $4A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $58
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $66
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $74
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $82
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $90
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $9E
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $AC
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $BA
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $C8
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $D6
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $E4
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $F2
TABLE_OFFSET .set TABLE_OFFSET + 14
times14tablehi:
TABLE_OFFSET .set 0
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $00
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $01
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $02
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $03
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $04
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $05
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $06
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $07
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $08
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $09
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0A
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0B
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0C
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
.byte $0D
TABLE_OFFSET .set TABLE_OFFSET + 14
findsolid:
@findsolid_skip:
cpy #14 * 16
bcc @findsolid_skip_if_no_carry
pha
lda PLAYER_Y
bpl @findsolid_skip_if_positive
tya
clc
adc #($F0)
tay
pla
jmp @findsolid_skip
@findsolid_skip_if_positive:
tya
clc
adc #16
tay
pla
jmp @findsolid_skip
@findsolid_skip_if_no_carry:
jsr findblock
tax
lda #0
lsr TEMP_BYTE
rol
lsr TEMP_BYTE_1
rol
tay
lda solidchrs,X
and solidchrmasks,Y
dey
beq shift_by_4
dey
beq shift_by_2
dey
beq shift_by_0
shift_by_6:
lsr
lsr
shift_by_4:
lsr
lsr
shift_by_2:
lsr
lsr
shift_by_0:
sta SOLID_TILE_FOUND
cmp #0
rts
solidchrmasks:
.byte $C0
.byte $30
.byte $0C
.byte $03
findblock:
stx TEMP_BYTE
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
lsr TEMP_BYTE
ror
tax
rol TEMP_BYTE_1
lda MAP_POINTER
clc
adc times14tablelo + 1,X
sta TEMP_POINTER
lda MAP_POINTER + 1
adc times14tablehi + 1,X
sta TEMP_POINTER + 1
tya
lsr
lsr
lsr
lsr
tay
rol TEMP_BYTE
lda (TEMP_POINTER),Y
sta BLOCK_FOUND
stx BLOCK_X
sty BLOCK_Y
jsr checkchangedblock
lda BLOCK_FOUND
rts
findchr:
jsr findblock
findchrpart:
tay
lsr TEMP_BYTE
bcs bottompart
lsr TEMP_BYTE_1
bcs rightside
lda block_strip_top_left,Y
sta CHARACTER_FOUND
rts
rightside:
lda block_strip_top_right,Y
sta CHARACTER_FOUND
rts
bottompart:
lsr TEMP_BYTE_1
bcs rightside1
lda block_strip_bottom_left,Y
sta CHARACTER_FOUND
rts
rightside1:
lda block_strip_bottom_right,Y
sta CHARACTER_FOUND
noblocksneeded:
rts
bringonmap:
lda SCREEN_X_LOW
and #15
cmp #14
bcs noblocksneeded
tay
sta BLOCK_Y
ldx MAP_STRIP
bit SCROLL_DIRECTION
bpl @bringonmap_skip_if_positive
txa
clc
adc #RIGHT_EDGE_OFFSET
sta BLOCK_X
tax
@bringonmap_skip_if_positive:
stx BLOCK_X
jsr getblockbit
sta TEMP_POINTER_9
tay
lda blockrous,Y
ldy BLOCK_Y
cmp #0
bpl @bringonmap_skip_if_positive_2
dex
jsr getblockbit
@bringonmap_skip_if_positive_2:
jsr checkchangedblock1
lda BLOCK_FOUND
jsr printblocktoscreen
jmp checkaddflamesetc
getblockbit:
lda MAP_POINTER
clc
adc times14tablelo,X
sta TEMP_POINTER
lda MAP_POINTER + 1
adc times14tablehi,X
sta TEMP_POINTER + 1
lda (TEMP_POINTER),Y
sta BLOCK_FOUND
rts
checkchangedblock:
inc BLOCK_X
checkchangedblock1:
ldx CHANGED_BLOCKS_POINTER
beq @checkchangedblock1_skip_if_equal
ldx #0
@checkchangedblock1_loop:
lda BLOCK_X
cmp CHANGED_BLOCKS,X
bne @checkchangedblock1_skip_if_not_equal
lda CHANGED_BLOCKS + 1,X
cmp BLOCK_Y
bne @checkchangedblock1_skip_if_not_equal
lda CHANGED_BLOCKS + 2,X
sta BLOCK_FOUND
ldx BLOCK_X
rts
@checkchangedblock1_skip_if_not_equal:
inx
inx
inx
cpx CHANGED_BLOCKS_POINTER
bne @checkchangedblock1_loop
@checkchangedblock1_skip_if_equal:
ldx BLOCK_X
rts
addachangedblock:
stx SCRATCH_BYTE_1
sty SCRATCH_BYTE_2
sta SCRATCH_BYTE_3
addachangedblock1:
lda #3
ldx CHANGED_BLOCKS_POINTER
beq @addachangedblock1_skip_if_equal
ldx #0
@addachangedblock1_loop:
lda CHANGED_BLOCKS + 0,X
cmp SCRATCH_BYTE_1
bne @addachangedblock1_skip_if_not_equal
lda CHANGED_BLOCKS + 1,X
cmp SCRATCH_BYTE_2
bne @addachangedblock1_skip_if_not_equal
lda #0
beq @addachangedblock1_skip_if_equal
@addachangedblock1_skip_if_not_equal:
inx
inx
inx
cpx CHANGED_BLOCKS_POINTER
bne @addachangedblock1_loop
lda #3
@addachangedblock1_skip_if_equal:
clc
adc CHANGED_BLOCKS_POINTER
sta CHANGED_BLOCKS_POINTER
cmp #3 * MAX_CHANGED_BLOCKS
bne @addachangedblock1_skip_if_not_equal_2
jsr turninteron
@addachangedblock1_skip:
php
pha
lda PPU_MASK_SHADOW
and #30
clc
adc #1
sta PPU_MASK_REGISTER
pla
plp
lda PPU_MASK_SHADOW
and #30
sta PPU_MASK_REGISTER
jmp @addachangedblock1_skip
@addachangedblock1_skip_if_not_equal_2:
lda SCRATCH_BYTE_2
sta CHANGED_BLOCKS + 1,X
lda SCRATCH_BYTE_1
sta CHANGED_BLOCKS + 0,X
lda SCRATCH_BYTE_3
sta CHANGED_BLOCKS + 2,X
ldx SCRATCH_BYTE_1
bit INTERRUPT_ENABLED
bpl @addachangedblock1_skip_if_positive
ldy SCRATCH_BYTE_2
jmp printblocktoscreencheck
@addachangedblock1_skip_if_positive:
rts
deleteachangedblock:
stx SCRATCH_BYTE_1
sty SCRATCH_BYTE_2
deleteachangedblock1:
lda CHANGED_BLOCKS_POINTER
beq @deleteachangedblock1_skip_if_equal
ldx #0
@deleteachangedblock1_loop:
lda CHANGED_BLOCKS + 0,X
cmp SCRATCH_BYTE_1
bne @deleteachangedblock1_skip_if_not_equal
lda CHANGED_BLOCKS + 1,X
cmp SCRATCH_BYTE_2
bne @deleteachangedblock1_skip_if_not_equal
@deleteachangedblock1_loop_2:
lda CHANGED_BLOCKS + 3,X
sta CHANGED_BLOCKS + 0,X
inx
cpx CHANGED_BLOCKS_POINTER
bne @deleteachangedblock1_loop_2
txa
clc
adc #($FD)
sta CHANGED_BLOCKS_POINTER
ldx SCRATCH_BYTE_1
lda MAP_POINTER
clc
adc times14tablelo,X
sta TEMP_POINTER
lda MAP_POINTER + 1
adc times14tablehi,X
sta TEMP_POINTER + 1
ldy SCRATCH_BYTE_2
lda (TEMP_POINTER),Y
jmp printblocktoscreencheck
@deleteachangedblock1_skip_if_not_equal:
inx
inx
inx
cpx CHANGED_BLOCKS_POINTER
bne @deleteachangedblock1_loop
@deleteachangedblock1_body:
ldx SCRATCH_BYTE_1
@deleteachangedblock1_skip_if_equal:
rts
blocknotonscreen:
rts
printblocktoscreencheck:
stx BLOCK_X
sty BLOCK_Y
sta BLOCK_FOUND
txa
sec
sbc MAP_STRIP
bmi blocknotonscreen
cmp #RIGHT_EDGE_OFFSET + 1
bcs blocknotonscreen
printblocktoscreen:
ldy BLOCK_Y
lda BLOCK_X
lsr
and #15
cmp #8
bcc @printblocktoscreen_skip_if_no_carry
clc
adc #7 * 8 - 8
@printblocktoscreen_skip_if_no_carry:
clc
adc attrytable,Y
sta ATTRIBUTE_POINTER
@printblocktoscreen_skip:
ldx MAP_BLOCK_POINTER
cpx #11 * NUMBER_OF_BLOCKS
bne @printblocktoscreen_skip_if_not_equal
lda #0
sta FILLED_BLOCK_BUFFER
asl VBLANK_FLAG
@printblocktoscreen_wait_vblank:
bit VBLANK_FLAG
bpl @printblocktoscreen_wait_vblank
lda #1
sta FILLED_BLOCK_BUFFER
jmp @printblocktoscreen_skip
@printblocktoscreen_skip_if_not_equal:
ldy BLOCK_FOUND
lda block_strip_top_left,Y
sta BLOCK_BUFFER_ADDRESS + 2,X
lda block_strip_top_right,Y
sta BLOCK_BUFFER_ADDRESS + 3,X
lda block_strip_bottom_left,Y
sta BLOCK_BUFFER_ADDRESS + 6,X
lda block_strip_bottom_right,Y
sta BLOCK_BUFFER_ADDRESS + 7,X
lda block_strip_attributes,Y
sta BLOCK_ATTRIBUTE
lda BLOCK_X
lsr
lda BLOCK_Y
rol
and #3
tay
clc
adc BLOCK_ATTRIBUTE
sta BLOCK_ATTRIBUTE
ldx ATTRIBUTE_POINTER
lda ATTRIBUTE_MAP,X
and attributemasks,Y
ldy BLOCK_ATTRIBUTE
ora attributeands,Y
sta ATTRIBUTE_MAP,X
ldx MAP_BLOCK_POINTER
sta BLOCK_BUFFER_ADDRESS + 10,X
txa
clc
adc #11
sta MAP_BLOCK_POINTER
lda BLOCK_X
and #31
asl
sta TEMP_BYTE
and #32
beq @printblocktoscreen_skip_if_equal
clc
adc #($E4)
@printblocktoscreen_skip_if_equal:
sta TEMP_BYTE_1
ldy BLOCK_Y
lda TEMP_BYTE
and #31
clc
adc multiply_by_32_lo,Y
sta BLOCK_BUFFER_ADDRESS + 1,X
lda TEMP_BYTE_1
adc multiply_by_32_hi,Y
sta BLOCK_BUFFER_ADDRESS + 0,X
lda BLOCK_BUFFER_ADDRESS + 1,X
clc
adc #32
sta BLOCK_BUFFER_ADDRESS + 5,X
lda BLOCK_BUFFER_ADDRESS + 0,X
adc #0
sta BLOCK_BUFFER_ADDRESS + 4,X
@printblocktoscreen_body:
now_attribute:
ldy #35
lda ATTRIBUTE_POINTER
cmp #8 * 7
bcc @now_attribute_skip_if_no_carry
sec
sbc #8 * 7
iny
iny
iny
iny
@now_attribute_skip_if_no_carry:
clc
adc #192
sta BLOCK_BUFFER_ADDRESS + 9,X
tya
sta BLOCK_BUFFER_ADDRESS + 8,X
rts
attrytable:
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
gointonewmap:
lda MAP_NUMBER
asl
asl
clc
adc MAP_NUMBER
clc
adc MAP_NUMBER
tax
lda mapinfo,X
sta MAP_POINTER
lda mapinfo + 1,X
sta MAP_POINTER + 1
stx TEMP_BYTE_1
lda INTERRUPT_ENABLED
beq interrupt_not_on
jsr turninterofffade
interrupt_not_on:
jsr setfade
ldx TEMP_BYTE_1
ldy #0
lda MIN_MAP
cmp mapinfo + 2,X
bcs @interrupt_not_on_skip_if_carry
ldy #255
@interrupt_not_on_skip_if_carry:
sec
sbc mapinfo + 2,X
@interrupt_not_on_body:
sty TEMP_POINTER + 1
asl
rol TEMP_POINTER + 1
asl
rol TEMP_POINTER + 1
asl
rol TEMP_POINTER + 1
asl
rol TEMP_POINTER + 1
clc
adc PLAYER_X_LOW
sta PLAYER_X_LOW
lda TEMP_POINTER + 1
adc PLAYER_X_HIGH
sta PLAYER_X_HIGH
lda mapinfo + 2,X
sta MIN_MAP
lda mapinfo + 3,X
clc
adc #($F0)
sta MAX_MAP
lda PLAYER_X_LOW
clc
adc #<(256 + 32)
sta SCREEN_X_LOW
lda PLAYER_X_LOW + 1
adc #>(256 + 32)
sta SCREEN_X_LOW + 1
stx TEMP_BYTE
ldy mapinfo + 4,X
ldx #0
@interrupt_not_on_loop:
lda gamepallettes,Y
sta FADE_COLOURS,X
lda spritecolours,X
sta FADE_COLOURS + 16,X
iny
inx
cpx #16
bne @interrupt_not_on_loop
ldx TEMP_BYTE
lda mapinfo + 5,X
tax
makeupchrset:
stx HIGH_SCORE_POSITION
lda mapchrsdefs,X
bmi nomorechrsformap
jsr copyblockofcompactedchrs
ldx HIGH_SCORE_POSITION
inx
jmp makeupchrset
nomorechrsformap:
lda #0
sta FRAME_COUNTER
sta ANIMATED_DOOR
sta CHANGED_BLOCKS_POINTER
jsr resetdoorsintomap
jsr doallsecrets
jsr resetextravars
jsr storeoutoldrobin
jsr setxscroll
lda PLAYER_X_LOW
sec
sbc SCREEN_X_LOW
sta PLAYER_ONSCREEN_X
ldx MAP_NUMBER
lda tuneforstrip,X
cmp MUSIC_TUNE
beq playingsametune
jsr starttune
playingsametune:
lda #239 - 12
sta SCROLL_Y
jmp turninteron
checkoffscreen:
ldx MAP_NUMBER
lda mapheights,X
sta TEMP_BYTE
lda PLAYER_KILLED
bne @checkoffscreen_skip_if_not_equal
lda PLAYER_Y
sta TEMP_BYTE_8
cmp #32
bcc goingofftop
cmp #216
bcc @checkoffscreen_skip_if_not_equal
cmp #240
bcs goingoffbottom
jsr setonladdervars
@checkoffscreen_skip_if_not_equal:
rts
goingofftop:
lda PLAYER_Y
clc
adc #208
sta PLAYER_Y
inc TEMP_BYTE
bne changingscreen
goingoffbottom:
lda PLAYER_Y
sec
sbc #208
sta PLAYER_Y
dec TEMP_BYTE
changingscreen:
lda MAP_NUMBER
asl
asl
clc
adc MAP_NUMBER
clc
adc MAP_NUMBER
tay
ldx mapinfo + 2,Y
lda PLAYER_X_LOW
clc
adc multiply_by_16_lo,X
sta TEMP_POINTER
lda PLAYER_X_HIGH
adc multiply_by_16_hi,X
sta TEMP_POINTER + 1
ldx #12
stx TEMP_BYTE_9
doeachmap:
lda mapheights,X
cmp TEMP_BYTE
beq possiblemap
trynextmap:
dec TEMP_BYTE_9
ldx TEMP_BYTE_9
bpl doeachmap
lda TEMP_BYTE_8
cmp #8
bcs @trynextmap_skip_if_carry
lda #8
bne @trynextmap_skip_if_not_equal
@trynextmap_skip_if_carry:
cmp #248
bcc @trynextmap_skip_if_not_equal
lda 247
@trynextmap_skip_if_not_equal:
sta PLAYER_Y
rts
possiblemap:
txa
asl
asl
clc
adc TEMP_BYTE_9
clc
adc TEMP_BYTE_9
tay
ldx mapinfo + 2,Y
lda multiply_by_16_hi,X
cmp TEMP_POINTER + 1
bne @possiblemap_skip_if_not_equal
lda multiply_by_16_lo,X
cmp TEMP_POINTER
@possiblemap_skip_if_not_equal:
bcs trynextmap
lda mapinfo + 2,Y
clc
adc mapinfo + 3,Y
tax
lda multiply_by_16_hi,X
cmp TEMP_POINTER + 1
bne @possiblemap_skip_if_not_equal_2
lda multiply_by_16_lo,X
cmp TEMP_POINTER
@possiblemap_skip_if_not_equal_2:
bcc trynextmap
jsr setonladdervars
lda #0
sta MUSIC_VOICE_1
sta MUSIC_VOICE_2
sta MUSIC_VOICE_3
sta MUSIC_VOICE_4
lda TEMP_BYTE_9
sta MAP_NUMBER
jmp gointonewmap
mapinfo:
.byte <(map_b - 14)
.byte >(map_b - 14)
.byte $58
.byte $48
.byte <(PALETTE_LAVA)
.byte <(CHARSET_DUNGEON)
.byte <(map_c - 14)
.byte >(map_c - 14)
.byte $20
.byte $20
.byte <(PALETTE_WATER)
.byte <(CHARSET_DUNGEON)
.byte <(map_d - 14)
.byte >(map_d - 14)
.byte $50
.byte $10
.byte <(PALETTE_WATER)
.byte <(CHARSET_DUNGEON)
.byte <(map_e - 14)
.byte >(map_e - 14)
.byte $80
.byte $40
.byte <(PALETTE_WATER)
.byte <(CHARSET_DUNGEON)
.byte <(map_f - 14)
.byte >(map_f - 14)
.byte $00
.byte $D0
.byte <(PALETTE_DUNGEON)
.byte <(CHARSET_DUNGEON)
.byte <(map_g - 14)
.byte >(map_g - 14)
.byte $00
.byte $B0
.byte <(PALETTE_KITCHEN)
.byte <(CHARSET_HALL)
.byte <(map_h - 14)
.byte >(map_h - 14)
.byte $00
.byte $B0
.byte <(PALETTE_HALL)
.byte <(CHARSET_CHURCH)
.byte <(map_i - 14)
.byte >(map_i - 14)
.byte $10
.byte $A0
.byte <(PALETTE_CHURCH)
.byte <(CHARSET_SKY)
.byte <(map_j - 14)
.byte >(map_j - 14)
.byte $10
.byte $28
.byte <(PALETTE_BEDROOM)
.byte <(CHARSET_CHURCH)
.byte <(map_l - 14)
.byte >(map_l - 14)
.byte $90
.byte $20
.byte <(PALETTE_SKY)
.byte <(CHARSET_SKY)
.byte <(map_m - 14)
.byte >(map_m - 14)
.byte $18
.byte $18
.byte <(PALETTE_SKY)
.byte <(CHARSET_SKY)
.byte <(map_n - 14)
.byte >(map_n - 14)
.byte $58
.byte $20
.byte <(PALETTE_CHURCH)
.byte <(CHARSET_CHURCH)
.byte <(map_o - 14)
.byte >(map_o - 14)
.byte $6A
.byte $10
.byte <(PALETTE_SKY)
.byte <(CHARSET_SKY)
tuneforstrip:
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
