restupdatecoin:
stx TEMP_POINTER_8
lda ONSCREEN_COUNTER_2,Y
and #15
sta TEMP_BYTE_1
cmp #6
bcs nosparkle
lda ONSCREEN_COUNTER_2,Y
and #240
bne @restupdatecoin_skip_if_not_equal
lda RANDOM_SEED + 1
bne nosparkle
@restupdatecoin_skip_if_not_equal:
lda ONSCREEN_COUNTER_2,Y
clc
adc #16
sta ONSCREEN_COUNTER_2,Y
lsr
lsr
lsr
lsr
lsr
sta TEMP_BYTE_2
txa
ldx SPRITE_X_COORD_HIGH
sec
sbc #7
bcs @restupdatecoin_skip_if_carry
dex
@restupdatecoin_skip_if_carry:
cpx #0
bne @restupdatecoin_skip_if_not_equal_2
sta TEMP_BYTE_3
lda ONSCREEN_Y,Y
clc
adc #4
tay
lda #2
sta TEMP_BYTE
ldx TEMP_BYTE_2
lda sparkle,X
ldx TEMP_BYTE_3
jsr pokesprite
@restupdatecoin_skip_if_not_equal_2:
nosparkle:
ldy TEMP_POINTER_9
lda ONSCREEN_Y,Y
sta TEMP_POINTER_8 + 1
jsr pickupcollision
bcs endcoin
jsr storeoutoldrobin
ldy TEMP_POINTER_9
lda ONSCREEN_X_LOW,Y
sta TEMP_POINTER_7
lda ONSCREEN_X_HIGH,Y
sta TEMP_POINTER_7 + 1
lda #0
sta ONSCREEN_ROUTINE,Y
lda ONSCREEN_COUNTER_1,Y
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda SECRET_TABLE + 3,Y
and bitpattern,X
bne @nosparkle_skip_if_not_equal
lda SECRET_TABLE + 3,Y
eor bitpattern,X
sta SECRET_TABLE + 3,Y
ldy TEMP_POINTER_9
lda ONSCREEN_COUNTER_2,Y
and #15
cmp #6
bcc @nosparkle_skip_if_no_carry
jsr addtohearts
lda #7
jsr startstars
lda #SFX_PICKUP_HEART
jsr soundfx
lda #72
jsr addtoscore
jmp @nosparkle_skip
@nosparkle_skip_if_no_carry:
jsr start_float_up_number
lda #6
jsr startstars
lda #SFX_PICKUP_TREASURE
jsr soundfx
lda #50
jsr addtoscore
@nosparkle_skip:
@nosparkle_skip_if_not_equal:
rts
endcoin:
ldy TEMP_POINTER_9
lda SPRITE_X_COORD_HIGH
bne @endcoin_skip_if_not_equal
lda ONSCREEN_Y,Y
tay
lda TEMP_BYTE_1
cmp #6
bcs pulsing_heart
tax
lda treaspal,X
sta TEMP_BYTE
lda FRAME_COUNTER
lsr
lsr
and #3
sta TEMP_BYTE
lda TEMP_BYTE_1
asl
asl
clc
adc #204
ldx TEMP_POINTER_8
jmp pokesprite2by2
@endcoin_skip_if_not_equal:
rts
pulsing_heart:
lda #3
sta TEMP_BYTE
tya
clc
adc #12
tay
lda FRAME_COUNTER
lsr
lsr
lsr
and #3
tax
lda heartsdefs,X
ldx TEMP_POINTER_8
dex
dex
dex
dex
jmp pokesprite
sparkle:
.byte $8D
.byte $8D
.byte $8E
.byte $8E
.byte $8F
.byte $8E
.byte $8D
.byte $8D
putinheartbank:
lda MAP_NUMBER
findinitcoin:
cmp initial_coin_table + 1,Y
bne @findinitcoin_skip_if_not_equal
lda initial_coin_table,Y
cmp BLOCK_X
beq gotrightcoin
lda MAP_NUMBER
@findinitcoin_skip_if_not_equal:
iny
iny
cpy #(8 * 6 + 24) * 2
bne findinitcoin
dey
dey
gotrightcoin:
tya
lsr
sta ONSCREEN_COUNTER_1,X
lsr
lsr
lsr
sta ONSCREEN_COUNTER_2,X
gotcoin:
tya
lsr
stx TEMP_BYTE
tax
and #7
tay
txa
lsr
lsr
lsr
tax
lda SECRET_TABLE + 3,X
ldx TEMP_BYTE
and bitpattern,Y
beq @gotcoin_skip_if_equal
lda #0
sta ONSCREEN_ROUTINE,X
rts
@gotcoin_skip_if_equal:
lda #8
jsr onscrxandy
lda ONSCREEN_Y,X
clc
adc #8
sta ONSCREEN_Y,X
rts
initial_coin_table:
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
start_float_up_number:
lda ONSCREEN_COUNTER_2,Y
and #15
tax
dec TREASURE_FLAGS,X
lda TREASURE_FLAGS,X
sta COIN_NUMBER
@set_coin_position:
lda ONSCREEN_COUNTER_1,Y
asl
tax
lda initial_coin_table,X
sta COIN_NUMBER_X
lda ONSCREEN_Y,Y
sta COIN_NUMBER_Y
lda #64
sta COIN_NUMBER_COUNT
rts
float_up_number:
lda COIN_NUMBER_Y
beq @end
lda COIN_NUMBER_COUNT
beq @end
lda FRAME_COUNTER
lsr
lsr
and #3
sta TEMP_BYTE
lda FRAME_COUNTER
and #1
bne @float_up_number_skip_if_not_equal
dec COIN_NUMBER_COUNT
dec COIN_NUMBER_Y
@float_up_number_skip_if_not_equal:
ldy COIN_NUMBER_Y
ldx COIN_NUMBER_X
lda multiply_by_16_lo - 1,X
clc
adc #6
sec
sbc SCREEN_X_LOW
sta TEMP_BYTE_1
lda multiply_by_16_hi - 1,X
sbc SCREEN_X_HIGH
bne @end
lda COIN_NUMBER
clc
adc #128
ldx TEMP_BYTE_1
jsr pokesprite
@end:
rts
print_lives_info_message:
.byte <(MESSAGE_GOSUB)
.word clearscr
.byte <(MESSAGE_ADDRESS + 35)
.byte $C0
.byte <(MESSAGE_LOOP)
.byte $40
.byte <(MESSAGE_LENGTH)
.byte $01
.byte $FF
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_ADDRESS + 32)
.byte $8D
.byte MESSAGE_TEXT
.word text_score
.byte <(MESSAGE_ADDRESS + 33)
.byte $4E
.byte MESSAGE_TEXT
.word text_lives
.byte <(MESSAGE_ADDRESS + 34)
.byte $46
.byte MESSAGE_TEXT
.word text_treasure_to_collect
.byte <(MESSAGE_ADDRESS + 35)
.byte $D2
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $AA
.byte $AA
.byte $AA
.byte <(MESSAGE_END)
lives_bit_table:
.byte <(game_over_bit - life1mess)
.byte $00
.byte <(lives2mess - life1mess)
.byte <(lives3mess - life1mess)
.byte <(lives4mess - life1mess)
.byte <(lives5mess - life1mess)
.byte <(lives6mess - life1mess)
life1mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $22
.byte MESSAGE_TEXT
.word text_life
.byte <(MESSAGE_END)
lives2mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $23
.byte <(MESSAGE_END)
lives3mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $24
.byte <(MESSAGE_END)
lives4mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $25
.byte <(MESSAGE_END)
lives5mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $26
.byte <(MESSAGE_END)
lives6mess:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4C
.byte $27
.byte <(MESSAGE_END)
game_over_bit:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4B
.byte MESSAGE_TEXT
.word text_game_over
.byte <(MESSAGE_END)
completed_game_message:
.byte <(MESSAGE_ADDRESS + 33)
.byte $4B
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20
.byte <(MESSAGE_ADDRESS + 32)
.byte $EC
.byte MESSAGE_TEXT
.word text_the_end
.byte <(MESSAGE_ADDRESS + 33)
.byte $C8
.byte MESSAGE_TEXT
.word text_congratulations
.byte <(MESSAGE_ADDRESS + 34)
.byte $01
.byte MESSAGE_TEXT
.word text_completion_1
.byte <(MESSAGE_JUMP)
.word completed_game_message_2
completed_game_message_2:
.byte MESSAGE_TEXT
.word text_completion_2
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LOOP)
.byte $1C
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_DOWN_LINE)
.byte MESSAGE_TEXT
.word text_completion_3
.byte <(MESSAGE_END)
treasure_left_message:
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
print_6_treasures:
jsr add_sparkle_to_treasures
ldx #5
@print_6_treasures_loop:
stx TEMP_POINTER_9
lda treaspal,X
sta TEMP_BYTE
ldy show_all_treasure + 6,X
lda show_all_treasure,X
tax
lda TEMP_POINTER_9
asl
asl
clc
adc #204
jsr pokesprite2by2
dec TEMP_POINTER_9
ldx TEMP_POINTER_9
bpl @print_6_treasures_loop
rts
show_all_treasure:
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
add_sparkle_to_treasures:
ldx #1
do_next_sparkle:
lda HEART_TABLE + 8,X
bne already_got_sparkle
lsr RANDOM_SEED
bcc next_sparkle
lda RANDOM_SEED + 2
and #7
cmp #6
bcs next_sparkle
tay
lda RANDOM_SEED + 1
and #7
clc
adc #($FC)
clc
adc show_all_treasure,Y
sta HEART_TABLE,X
lda RANDOM_SEED + 1
and #7
clc
adc #2
clc
adc show_all_treasure + 6,Y
sta HEART_TABLE + 4,X
lda #7 * 4
sta HEART_TABLE + 8,X
already_got_sparkle:
dec HEART_TABLE + 8,X
lda HEART_TABLE + 8,X
lsr
lsr
tay
lda #2
sta TEMP_BYTE
lda HEART_TABLE,X
sta TEMP_BYTE_1
stx TEMP_BYTE_2
lda sparkle,Y
ldy HEART_TABLE + 4,X
ldx TEMP_BYTE_1
jsr pokesprite
ldx TEMP_BYTE_2
next_sparkle:
dex
bpl do_next_sparkle
rts
redefine_water:
lda MAP_NUMBER
cmp #5
bcs @redefine_water_skip_if_carry
ldy VRAM_WRITE_POINTER
lda FRAME_COUNTER
lsr
lsr
and #6
tax
lda #>(254 * 16 + 4104)
sta VRAM_BUFFER_ADDRESS,Y
lda #<(254 * 16 + 4104)
sta VRAM_BUFFER_ADDRESS + 1,Y
lda #2
sta VRAM_BUFFER_ADDRESS + 2,Y
lda water_chrs,X
sta VRAM_BUFFER_ADDRESS + 3,Y
lda water_chrs + 1,X
sta VRAM_BUFFER_ADDRESS + 4,Y
lda FRAME_COUNTER
lsr
and #6
tax
lda #>(255 * 16 + 4096)
sta VRAM_BUFFER_ADDRESS + 5,Y
lda #<(255 * 16 + 4096)
sta VRAM_BUFFER_ADDRESS + 6,Y
lda #2
sta VRAM_BUFFER_ADDRESS + 7,Y
lda water_chrs + 8,X
sta VRAM_BUFFER_ADDRESS + 8,Y
lda water_chrs + 9,X
sta VRAM_BUFFER_ADDRESS + 9,Y
lda #>(255 * 16 + 4104)
sta VRAM_BUFFER_ADDRESS + 10,Y
lda #<(255 * 16 + 4104)
sta VRAM_BUFFER_ADDRESS + 11,Y
lda #2
sta VRAM_BUFFER_ADDRESS + 12,Y
lda water_chrs + 8,X
sta VRAM_BUFFER_ADDRESS + 13,Y
lda water_chrs + 9,X
sta VRAM_BUFFER_ADDRESS + 14,Y
tya
clc
adc #15
sta VRAM_WRITE_POINTER
@redefine_water_skip_if_carry:
rts
secret_table:
.word secret_0
.word secret_1
.word secret_2
.word secret_3
.word secret_4
.word secret_5
.word secret_6
.word secret_7
.word secret_8
.word secret_9
.word secret_10
.word secret_11
.word secret_12
.word secret_13
.word secret_14
.word secret_15
.word secret_16
.word secret_17
.word secret_18
.word secret_19
.word secret_20
.word secret_21
.word secret_22
.word secret_23
secret_0:
.byte $04
.byte $26
.byte $06
.byte $20
.byte $FF
secret_1:
.byte $04
.byte $04
.byte $0A
.byte $00
.byte $04
.byte $04
.byte $0B
.byte $00
.byte $FF
secret_2:
.byte $07
.byte $99
.byte $0C
.byte $AD
.byte $07
.byte $9A
.byte $0C
.byte $AB
.byte $FF
secret_3:
.byte $06
.byte $AE
.byte $08
.byte $F8
.byte $FF
secret_4:
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
secret_5:
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
secret_6:
.byte $0A
.byte $16
.byte $0C
.byte $20
.byte $0A
.byte $16
.byte $0D
.byte $20
.byte $FF
secret_7:
.byte $04
.byte $BD
.byte $04
.byte $4A
.byte $04
.byte $BE
.byte $04
.byte $49
.byte $FF
secret_8:
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
secret_9:
.byte $05
.byte $71
.byte $00
.byte $24
.byte $FF
secret_10:
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
secret_11:
.byte $05
.byte $77
.byte $06
.byte $00
.byte $05
.byte $77
.byte $07
.byte $00
.byte $FF
secret_12:
.byte $08
.byte $19
.byte $0C
.byte $11
.byte $08
.byte $24
.byte $0A
.byte $2B
.byte $FF
secret_13:
.byte $07
.byte $07
.byte $0C
.byte $AD
.byte $FF
secret_14:
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
secret_15:
.byte $04
.byte $02
.byte $02
.byte $04
.byte $FF
secret_16:
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
secret_17:
.byte $06
.byte $10
.byte $0B
.byte $4B
.byte $06
.byte $10
.byte $0C
.byte $49
.byte $FF
secret_18:
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
secret_19:
.byte $06
.byte $85
.byte $07
.byte $20
.byte $06
.byte $85
.byte $08
.byte $20
.byte $FF
secret_20:
.byte $09
.byte $0E
.byte $08
.byte $F8
.byte $FF
secret_21:
.byte $07
.byte $96
.byte $05
.byte $AB
.byte $FF
secret_22:
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
secret_23:
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
