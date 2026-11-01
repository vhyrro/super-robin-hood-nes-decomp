CODEMASTERS_USE_NMI = 1
CODEMASTERS_SPRITE_PAGE = $0300
CODEMASTERS_YEAR = 1993
CODEMASTERS_SPRITE_Y_POSITION = CODEMASTERS_SPRITE_PAGE
CODEMASTERS_SPRITE_DATA = CODEMASTERS_SPRITE_PAGE + 1
CODEMASTERS_SPRITE_CONTROL = CODEMASTERS_SPRITE_PAGE + 2
CODEMASTERS_SPRITE_X_POSITION = CODEMASTERS_SPRITE_PAGE + 3
CODEMASTERS_SPRITE_TILE_INDEX = 1
CODEMASTERS_COLOUR_INDEX = 2
CODEMASTERS_Y_SCROLL_POSITION = 3
CODEMASTERS_TIME = 4
CODEMASTERS_SPRITE_TILE_ADDRESS_LOW = 5
CODEMASTERS_CODE_X_POSITION = 6
CODEMASTERS_CODE_Y_POSITION = 7
CODEMASTERS_TEMP_1 = 12
CODEMASTERS_TEMP_2 = 13
CODEMASTERS_TEMP_3 = 14
CODEMASTERS_TEMP_4 = 15
CODEMASTERS_ADDRESS_1 = 16
CODEMASTERS_ADDRESS_1_LOW = 16
CODEMASTERS_ADDRESS_1_HIGH = 17
CODEMASTERS_UNPACK_BUFFER = 18
cm_logo:
ldx #0
stx PPU_CONTROL_REGISTER
stx PPU_MASK_REGISTER
ldy #151
lda CODEMASTERS_FLAGS
and #63
cmp #4
ora #64
bcs @powerup
cpy CODEMASTERS_POWERUP
beq @reset
@powerup:
sty CODEMASTERS_POWERUP
lda #0
@reset:
sta CODEMASTERS_FLAGS
jsr cm_characters
ldx #0
@cm_clear_page_loop:
lda #0
sta 0,X
lda #255
sta CODEMASTERS_SPRITE_PAGE,X
inx
bne @cm_clear_page_loop
ldx #4
@in:
lda cm_inittab,X
sta CODEMASTERS_Y_SCROLL_POSITION,X
dex
bpl @in
lda #32
sta PPU_ADDRESS_REGISTER
ldx #0
stx PPU_ADDRESS_REGISTER
ldy #16
txa
@cv0:
sta PPU_DATA_REGISTER
dex
bne @cv0
dey
bne @cv0
@ab2:
lda cm_abmap,X
beq @abdone
sta PPU_ADDRESS_REGISTER
inx
lda cm_abmap,X
sta PPU_ADDRESS_REGISTER
inx
ldy cm_abmap,X
inx
@ab1:
lda cm_abmap,X
sta PPU_DATA_REGISTER
inx
dey
bne @ab1
beq @ab2
@abdone:
lda #35
sta PPU_ADDRESS_REGISTER
lda #232
sta PPU_ADDRESS_REGISTER
ldy #3
lda #80
@ab5:
ldx #8
@ab6:
sta PPU_DATA_REGISTER
dex
bne @ab6
lda #85
dey
bne @ab5
ldy #35
sty PPU_ADDRESS_REGISTER
ldx #194 + 8
stx PPU_ADDRESS_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sty PPU_ADDRESS_REGISTER
ldx #205 + 8
stx PPU_ADDRESS_REGISTER
lda #5
sta PPU_DATA_REGISTER
ldx #19
lda #0
@csfx:
sta APU_PULSE_1_CONTROL,X
dex
bpl @csfx
lda #128
sta PPU_CONTROL_REGISTER
cm_loop:
jsr cm_vblank
lda #15
sta APU_STATUS_REGISTER
ldx CODEMASTERS_FRAME_COUNTER
txa
and #1
sta CODEMASTERS_TEMP_1
cpx #CODEMASTERS_NOISE_START
bcs @n2
txa
lsr
bpl @n0
@n2:
txa
lsr
lsr
lsr
tay
lda cm_sfxnoise - 3,Y
cmp #2
bcs @n0
adc CODEMASTERS_TEMP_1
@n0:
sta APU_NOISE_PERIOD
ldy #0
sty APU_PULSE_1_LENGTH
dey
sty APU_PULSE_2_LENGTH
sty APU_NOISE_LENGTH
lda #21
sta APU_NOISE_CONTROL
cpx #CODEMASTERS_NOISE_START
bcc @cm_loop_skip_if_no_carry
lda #48
sta APU_PULSE_1_TIMER_LOW
txa
sec
sbc #CODEMASTERS_NOISE_START - 8
eor #255
lsr
lsr
cmp #48
bcs @cm_loop_skip_if_carry
lda #0
@cm_loop_skip_if_carry:
ora #16 + 128
sta APU_PULSE_1_CONTROL
cpx #CODEMASTERS_NOISE_LENGTH
bcc @cm_loop_skip_if_no_carry_2
lda #16
sta APU_NOISE_CONTROL
bne @cm_loop_skip_if_no_carry_2
@cm_loop_skip_if_no_carry:
txa
lsr
ora #16 + 128
sta APU_PULSE_1_CONTROL
sta APU_PULSE_2_CONTROL
txa
asl
asl
asl
sta APU_PULSE_1_TIMER_LOW
sta APU_PULSE_2_TIMER_LOW
lda #2
clc
adc CODEMASTERS_TEMP_1
sta APU_PULSE_1_LENGTH
sta APU_PULSE_2_LENGTH
@cm_loop_skip_if_no_carry_2:
lda CODEMASTERS_FRAME_COUNTER
beq @timeout
bit CODEMASTERS_FLAGS
bvc @cm_loop
cmp #64
bcc @cm_loop
ldy #1
sty JOYPAD_1_REGISTER
dey
sty JOYPAD_1_REGISTER
ldy #8
@j1:
lda JOYPAD_1_REGISTER
ora JOYPAD_2_REGISTER
lsr
bcs @timeout
dey
bne @j1
@cm_loop:
jmp cm_loop
@timeout:
lda #0
sta PPU_CONTROL_REGISTER
sta PPU_MASK_REGISTER
sta APU_STATUS_REGISTER
lda CODEMASTERS_FLAGS
ora #128
sta CODEMASTERS_FLAGS
rts
cm_vblank:
lda CODEMASTERS_FRAME_COUNTER
@cm_wait_frame_change:
cmp CODEMASTERS_FRAME_COUNTER
beq @cm_wait_frame_change
ldx #0
lda #63
sta PPU_ADDRESS_REGISTER
stx PPU_ADDRESS_REGISTER
ldy #4
@p2:
ldx #7
@p1:
lda cm_palette,X
sta PPU_DATA_REGISTER
dex
bpl @p1
dey
bne @p2
ldx CODEMASTERS_COLOUR_INDEX
ldy #63
sty PPU_ADDRESS_REGISTER
lda #17
sta PPU_ADDRESS_REGISTER
lda cm_colfade,X
bmi @eof
sta PPU_DATA_REGISTER
lda cm_colfade + 1,X
sta PPU_DATA_REGISTER
lda cm_colfade + 2,X
sta PPU_DATA_REGISTER
sty PPU_ADDRESS_REGISTER
ldy #3
sty PPU_ADDRESS_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
ldy #63
sty PPU_ADDRESS_REGISTER
ldy #27
sty PPU_ADDRESS_REGISTER
sta PPU_DATA_REGISTER
inx
inx
inx
dec CODEMASTERS_TIME
bne @eof
inc CODEMASTERS_TIME
stx CODEMASTERS_COLOUR_INDEX
@eof:
cm_strip:
lda #4
sta PPU_CONTROL_REGISTER
lda #33
sta PPU_ADDRESS_REGISTER
lda CODEMASTERS_SPRITE_TILE_ADDRESS_LOW
sta PPU_ADDRESS_REGISTER
inc CODEMASTERS_SPRITE_TILE_ADDRESS_LOW
ldx CODEMASTERS_SPRITE_TILE_INDEX
ldy cm_stdata,X
dey
bpl @done
@cm_strip_wait_vram:
lda PPU_DATA_REGISTER
dey
bmi @cm_strip_wait_vram
@cm_strip_read_loop:
inx
lda cm_stdata,X
bmi @cm_strip_skip_if_negative
sta PPU_DATA_REGISTER
bpl @cm_strip_read_loop
@cm_strip_skip_if_negative:
stx CODEMASTERS_SPRITE_TILE_INDEX
@done:
cm_codewrite:
lda CODEMASTERS_SPRITE_X_POSITION + 32
cmp #161
bne @nc
lda #33
sta PPU_ADDRESS_REGISTER
lda #76 + 64
sta PPU_ADDRESS_REGISTER
lda #8
sta PPU_DATA_REGISTER
lda #244 + 64 - 256
sta CODEMASTERS_ADDRESS_1_LOW
ldy #CODEMASTERS_CHARACTER_1
ldx #0
@loop2:
lda #32 + 1
sta PPU_ADDRESS_REGISTER
lda CODEMASTERS_ADDRESS_1_LOW
sta PPU_ADDRESS_REGISTER
dec CODEMASTERS_ADDRESS_1_LOW
lda cm_codemap,X
@cm_code_bit_loop:
asl
beq @next2
bcc @skip
sty PPU_DATA_REGISTER
iny
bne @cm_code_bit_loop
@skip:
bit PPU_DATA_REGISTER
bcc @cm_code_bit_loop
@next2:
inx
cpx #9
bne @loop2
@nc:
lda #32 + 1
sta PPU_CONTROL_REGISTER
sta PPU_ADDRESS_REGISTER
lda #244 + 64 - 256
sta PPU_ADDRESS_REGISTER
ldx #142
stx PPU_DATA_REGISTER
inx
stx PPU_DATA_REGISTER
lda #0
sta OAM_ADDRESS_REGISTER
lda #>(CODEMASTERS_SPRITE_PAGE)
sta OAM_DMA_REGISTER
lda #129
sta PPU_CONTROL_REGISTER
lda CODEMASTERS_Y_SCROLL_POSITION
beq @at_rest
sec
sbc #4
sta CODEMASTERS_Y_SCROLL_POSITION
@at_rest:
asl
eor #255
sta PPU_SCROLL_REGISTER
lda CODEMASTERS_Y_SCROLL_POSITION
sta PPU_SCROLL_REGISTER
lda #30
sta PPU_MASK_REGISTER
cm_code:
CODEMASTERS_CHARACTER_1 = 1
CODEMASTERS_CHARACTER_2 = 25
ldy #0
lda CODEMASTERS_CODE_X_POSITION
clc
adc #8
cmp #169
beq cm_quart
sta CODEMASTERS_CODE_X_POSITION
lda CODEMASTERS_CODE_Y_POSITION
sec
sbc #4
sta CODEMASTERS_CODE_Y_POSITION
ldx #10
lda #CODEMASTERS_CHARACTER_2
jsr @cm_codeplot
ldx #0
lda #CODEMASTERS_CHARACTER_1
@cm_codeplot:
sta CODEMASTERS_TEMP_4
lda CODEMASTERS_CODE_X_POSITION
sta CODEMASTERS_TEMP_1
@loop2:
lda CODEMASTERS_CODE_Y_POSITION
sta CODEMASTERS_TEMP_2
lda cm_codemap,X
beq @done
sta CODEMASTERS_TEMP_3
inx
@loop:
asl CODEMASTERS_TEMP_3
beq @next2
bcc @next
lda CODEMASTERS_TEMP_4
inc CODEMASTERS_TEMP_4
sta CODEMASTERS_SPRITE_DATA,Y
lda #2
sta CODEMASTERS_SPRITE_CONTROL,Y
lda CODEMASTERS_TEMP_1
cmp #224
bcs @done
sta CODEMASTERS_SPRITE_X_POSITION,Y
lda CODEMASTERS_TEMP_2
sta CODEMASTERS_SPRITE_Y_POSITION,Y
iny
iny
iny
iny
@next:
lda CODEMASTERS_TEMP_2
clc
adc #8
sta CODEMASTERS_TEMP_2
bne @loop
@next2:
lda CODEMASTERS_TEMP_1
sec
sbc #8
sta CODEMASTERS_TEMP_1
bne @loop2
@done:
rts
cm_quart:
CODEMASTERS_QUART_X = 89
CODEMASTERS_QUART_Y = 47 + 16
CODEMASTERS_QUART_CHARACTER = 33
lda #CODEMASTERS_QUART_CHARACTER
sta CODEMASTERS_TEMP_4
lda #CODEMASTERS_QUART_Y
sta CODEMASTERS_TEMP_2
ldx #0
ldy #32
@loop2:
lda #CODEMASTERS_QUART_X
sta CODEMASTERS_TEMP_1
lda cm_quartmap,X
sta CODEMASTERS_TEMP_3
inx
@loop:
asl CODEMASTERS_TEMP_3
bcc @next
lda CODEMASTERS_TEMP_4
inc CODEMASTERS_TEMP_4
sta CODEMASTERS_SPRITE_DATA,Y
sta CODEMASTERS_SPRITE_DATA + 4,Y
sta CODEMASTERS_SPRITE_DATA + 8,Y
sta CODEMASTERS_SPRITE_DATA + 12,Y
lda #32
sta CODEMASTERS_SPRITE_CONTROL,Y
lda #96
sta CODEMASTERS_SPRITE_CONTROL + 4,Y
lda #160
sta CODEMASTERS_SPRITE_CONTROL + 8,Y
lda #224
sta CODEMASTERS_SPRITE_CONTROL + 12,Y
lda CODEMASTERS_TEMP_1
sta CODEMASTERS_SPRITE_X_POSITION,Y
sta CODEMASTERS_SPRITE_X_POSITION + 8,Y
eor #255
sec
sbc #5
sta CODEMASTERS_SPRITE_X_POSITION + 4,Y
sta CODEMASTERS_SPRITE_X_POSITION + 12,Y
lda CODEMASTERS_TEMP_2
sta CODEMASTERS_SPRITE_Y_POSITION,Y
sta CODEMASTERS_SPRITE_Y_POSITION + 4,Y
eor #255
sec
sbc #167 - CODEMASTERS_QUART_Y * 2
sta CODEMASTERS_SPRITE_Y_POSITION + 8,Y
sta CODEMASTERS_SPRITE_Y_POSITION + 12,Y
tya
clc
adc #16
tay
@next:
lda CODEMASTERS_TEMP_1
clc
adc #8
sta CODEMASTERS_TEMP_1
cmp #CODEMASTERS_QUART_X + 8 * 5
bne @loop
lda CODEMASTERS_TEMP_2
clc
adc #8
sta CODEMASTERS_TEMP_2
cmp #CODEMASTERS_QUART_Y + 8 * 6
bne @loop2
rts
cm_sfxnoise:
.byte $04,$06,$01,$01
CODEMASTERS_NOISE_START = 24
CODEMASTERS_NOISE_LENGTH = 56
CODEMASTERS_TRIANGLE_LENGTH = 44
cm_inittab:
.byte $5C,$18,$49,$F1,$9F
cm_stdata:
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
cm_colfade:
.byte $04,$04,$04
.byte $04,$04,$03
.byte $04,$04,$13
.byte $03,$14,$12
.byte $02,$16,$11
.byte $01,$18,$11
.byte $80
cm_quartmap:
.byte $38
.byte $78
.byte $E0
.byte $C0
.byte $80
.byte $80
cm_codemap:
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
smiley_chr_data:
smiley_chr_data_alias:
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
cm_abmap:
.byte $22,$C5,$15,$5F,$60,$61,$62,$63,$64,$65,$66,$63,$67,$00,$60,$60,$68,$63,$63,$68,$5F,$69,$6A,$6B
.byte $22,$E5,$15,$6C,$6D,$6E,$6F,$70,$71,$63,$72,$70,$73,$00,$6D,$74,$75,$70,$70,$75,$6C,$76,$77,$78
.byte $23,$25,$15,$79,$7A,$7B,$90,$7D,$7E,$7F,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D
.byte $20,$AA,$0C,$91,$62,$92,$66,$93,$94,$95,$96,$65,$66,$60,$61
.byte $20,$CA,$0C,$97,$6F,$98,$72,$99,$9A,$9B,$9C,$63,$72,$74,$6E
.byte $00
cm_palette:
.byte $34,$24,$14,$04
.byte $11,$28,$1D,$04
CODEMASTERS_SHORT_SIZE = * - cm_logo
cm_characters:
lda #14
sta CURRENT_BANK
lda #CHARSET_CODEMASTERS
jsr copyblockofcompactedchrs
lda #>(144 * 16)
sta PPU_ADDRESS_REGISTER
lda #<(144 * 16)
sta PPU_ADDRESS_REGISTER
ldx #0
@cm_chr_copy_loop:
lda smiley_chr_data,X
sta PPU_DATA_REGISTER
inx
cpx #16
bne @cm_chr_copy_loop
rts
cm_chrset:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/CMLOGO.PP1"
CODEMASTERS_TOTAL_SIZE = * - cm_logo
smiley:
@tst_byte = 19
@bank = 20
@page = 21
@pad1 = 22
@bank_on = 23
@face_mask = 24
ldx #32
@smiley_copy_code_loop:
lda @rom_check - 32,X
sta 0,X
inx
bne @smiley_copy_code_loop
stx PPU_CONTROL_REGISTER
stx PPU_MASK_REGISTER
jsr @keypad
sty @tst_byte
lda @pad1
and #191
cmp #191
bne @next_tst
lda #SMILEY_HIGH_BANK
sta @bank
lda @smiley_bank
sta @bank_on
jsr 32
@next_tst:
lda @pad1
and #127
cmp #127
bne @no_eq
jsr @tst_2
@no_eq:
lda @tst_byte
beq @exit
and #4 + 8
bne @failed
jmp @good_face
@failed:
jmp @bad_face
@exit:
rts
@tst_2:
jsr @tst2_set
@tst1a:
ldy #64
@tst1b:
stx PPU_DATA_REGISTER
inx
stx PPU_DATA_REGISTER
inx
stx PPU_DATA_REGISTER
inx
stx PPU_DATA_REGISTER
inx
dey
bne @tst1b
inx
sec
sbc #1
bne @tst1a
jsr @tst2_set
ldy PPU_DATA_REGISTER
@tst2a:
ldy #64
@tst2b:
cpx PPU_DATA_REGISTER
bne @cram_fail
inx
cpx PPU_DATA_REGISTER
bne @cram_fail
inx
cpx PPU_DATA_REGISTER
bne @cram_fail
inx
cpx PPU_DATA_REGISTER
bne @cram_fail
inx
dey
bne @tst2b
inx
sec
sbc #1
bne @tst2a
jsr @tst2_set
ldx #255 - 37
@tst3a:
ldy #64
@tst3b:
stx PPU_DATA_REGISTER
dex
stx PPU_DATA_REGISTER
dex
stx PPU_DATA_REGISTER
dex
stx PPU_DATA_REGISTER
dex
dey
bne @tst3b
dex
sec
sbc #1
bne @tst3a
jsr @tst2_set
ldx #255 - 37
ldy PPU_DATA_REGISTER
@tst4a:
ldy #64
@tst4b:
cpx PPU_DATA_REGISTER
bne @cram_fail
dex
cpx PPU_DATA_REGISTER
bne @cram_fail
dex
cpx PPU_DATA_REGISTER
bne @cram_fail
dex
cpx PPU_DATA_REGISTER
bne @cram_fail
dex
dey
bne @tst4b
dex
sec
sbc #1
bne @tst4a
lda #2
bne @store_it
@cram_fail:
lda #8
@store_it:
ora @tst_byte
sta @tst_byte
rts
@tst2_set:
lda #32
ldx #37
ldy #0
sty PPU_ADDRESS_REGISTER
sty PPU_ADDRESS_REGISTER
rts
@keypad:
ldx #1
stx JOYPAD_1_REGISTER
dex
stx JOYPAD_1_REGISTER
ldy #8
@pad:
lda JOYPAD_1_REGISTER
lsr
rol @pad1
dey
bne @pad
rts
@rom_check:
ldy #0
@here2:
lda @bank
jsr @set_bank
lda #64 / 4
sta @page
lda #128
.byte $85
.byte <(@here + 2)
lda #144
.byte $85
.byte <(@herea + 2)
lda #160
.byte $85
.byte <(@hereb + 2)
lda #176
.byte $85
.byte <(@herec + 2)
ldx #0
txa
clc
@here:
adc 32768,X
bcc @herea
iny
clc
@herea:
adc 36864,X
bcc @hereb
iny
clc
@hereb:
adc 40960,X
bcc @herec
iny
clc
@herec:
adc 45056,X
bcc @hered
iny
clc
@hered:
inx
bne @here
inc @here + 2
inc @herea + 2
inc @hereb + 2
inc @herec + 2
dec @page
bne @here
ldx @bank
cmp @smiley_test_string_alias,X
bne @fail_it
lda @bank
dec @bank
cmp #SMILEY_LOW_BANK
bne @here2
lda #1
cpy @smiley_test_string_alias + 16
beq @tst2_balls
@fail_it:
lda #4
@tst2_balls:
sta @tst_byte
lda @bank_on
@set_bank:
tax
sta bank_table_alias2,X
rts
.res 13, 234
.res 15, 234
@smiley_test_string_alias:
@smiley_test_string:
.byte $2A,$20,$53,$4D,$49,$4C,$45,$59,$20,$54,$45,$53,$54,$20,$56,$31,$2E,$33,$20
@smiley_bank = * - 1
@good_face:
ldx #85
lda #26
bne @show_face
@bad_face:
ldx #170
lda #22
@show_face:
stx @face_mask
ldx @tst_byte
stx 17408
ldy #0
sty PPU_MASK_REGISTER
ldx #63
stx PPU_ADDRESS_REGISTER
sty PPU_ADDRESS_REGISTER
jsr @store
ora #48
jsr @store
jsr @store
sty PPU_ADDRESS_REGISTER
sty PPU_ADDRESS_REGISTER
ldx #16
dey
@delay_loop:
sty PPU_DATA_REGISTER
dex
bne @delay_loop
lda #32
sta PPU_ADDRESS_REGISTER
stx PPU_ADDRESS_REGISTER
txa
ldy #4
@l1:
sta PPU_DATA_REGISTER
inx
bne @l1
dey
bne @l1
lda #35
sta PPU_ADDRESS_REGISTER
lda #200
sta PPU_ADDRESS_REGISTER
ldy #0
@l2:
lda @face_data,Y
and @face_mask
sta PPU_DATA_REGISTER
iny
cpy #48
bcc @l2
ldx #0
stx PPU_CONTROL_REGISTER
stx PPU_ADDRESS_REGISTER
stx PPU_ADDRESS_REGISTER
stx PPU_SCROLL_REGISTER
stx PPU_SCROLL_REGISTER
lda #14
sta PPU_MASK_REGISTER
ldy #10
@wait:
dec TEMP_BYTE_1
bne @wait
dex
bne @wait
dey
bne @wait
sty PPU_MASK_REGISTER
rts
@store:
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
sta PPU_DATA_REGISTER
rts
@face_data:
.byte $00,$C0,$FC,$FF,$FF,$F0,$00,$00
.byte $40,$FF,$87,$FF,$B7,$CF,$73,$00
.byte $44,$FF,$FE,$B7,$FF,$FE,$77,$00
.byte $44,$FF,$07,$F5,$35,$CF,$77,$00
.byte $00,$CF,$F9,$FA,$FA,$FD,$03,$00
.byte $00,$00,$0F,$0F,$0F,$03,$00,$00
SMILEY_SIZE = * - smiley
ZP_VAR CODEMASTERS_PP1_ADDRESS, 2
CODEMASTERS_PP1_ADDRESS_LOW = CODEMASTERS_PP1_ADDRESS
CODEMASTERS_PP1_ADDRESS_HIGH = CODEMASTERS_PP1_ADDRESS + 1
ZP_VAR PP1_TEMP_1
ZP_VAR PP1_TEMP_2
ZP_VAR PP1_TEMP_3
ZP_VAR PP1_TEMP_4
ZP_VAR PP1_TEMP_5
ZP_VAR PP1_TEMP_6
ZP_VAR PP1_TEMP_7
ZP_VAR PP1_TEMP_8
