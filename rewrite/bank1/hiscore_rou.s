MESSAGE_SIZE = 17
NUMBER_OF_ENTRIES = 10
SCORE_SIZE = 7
NAME_SIZE = 9
NAME_TRAILING_ZERO_COUNT = 0
NAME_NUMBER_AFTER = 1
HIGH_SCORE_TABLE = HIGH_SCORES_IN_RAM
try_high_score:
lda #<(HIGH_SCORE_TABLE + NUMBER_OF_ENTRIES * MESSAGE_SIZE - SCORE_SIZE - NAME_NUMBER_AFTER)
sta TEMP_POINTER
lda #>(HIGH_SCORE_TABLE + NUMBER_OF_ENTRIES * MESSAGE_SIZE - SCORE_SIZE - NAME_NUMBER_AFTER)
sta TEMP_POINTER + 1
lda #0
sta HIGH_SCORE_POSITION
ldx #NUMBER_OF_ENTRIES
compare_entries_loop:
ldy #0
compare_digits_loop:
lda (TEMP_POINTER),Y
cmp #32
bne normalize_space_digit
lda #33 + 0
normalize_space_digit:
cmp PLAYER_SCORE,Y
beq digits_equal
bcc current_score_wins
jmp high_score_wins
digits_equal:
iny
cpy #SCORE_SIZE
bne compare_digits_loop
jmp current_score_wins
high_score_wins:
jmp entries_checked
current_score_wins:
lda TEMP_POINTER
sta TEMP_POINTER_2
lda TEMP_POINTER + 1
sta TEMP_POINTER_2 + 1
inc HIGH_SCORE_POSITION
previous_entry_loop:
lda TEMP_POINTER
clc
adc #<((-MESSAGE_SIZE))
sta TEMP_POINTER
lda TEMP_POINTER + 1
adc #>((-MESSAGE_SIZE))
sta TEMP_POINTER + 1
dex
bne compare_entries_loop
entries_checked:
lda HIGH_SCORE_POSITION
bne found_position
jmp not_a_high_score
found_position:
cmp #1
beq insert_new_entry
lda #<(HIGH_SCORE_TABLE + (NUMBER_OF_ENTRIES - 1) * MESSAGE_SIZE + NAME_TRAILING_ZERO_COUNT)
sta TEMP_POINTER
lda #>(HIGH_SCORE_TABLE + (NUMBER_OF_ENTRIES - 1) * MESSAGE_SIZE + NAME_TRAILING_ZERO_COUNT)
sta TEMP_POINTER + 1
ldx HIGH_SCORE_POSITION
dex
stx TEMP_BYTE
shift_entries_loop:
lda TEMP_POINTER
clc
adc #<((-MESSAGE_SIZE))
sta TEMP_POINTER_3
lda TEMP_POINTER + 1
adc #>((-MESSAGE_SIZE))
sta TEMP_POINTER_3 + 1
ldy #MESSAGE_SIZE - NAME_TRAILING_ZERO_COUNT - NAME_NUMBER_AFTER - 1
@shift_entries_copy_loop:
lda (TEMP_POINTER_3),Y
sta (TEMP_POINTER),Y
dey
bpl @shift_entries_copy_loop
lda TEMP_POINTER_3
sta TEMP_POINTER
lda TEMP_POINTER_3 + 1
sta TEMP_POINTER + 1
dec TEMP_BYTE
bne shift_entries_loop
insert_new_entry:
copy_score_across:
ldy #0
@copy_score_across_loop:
lda PLAYER_SCORE,Y
sta (TEMP_POINTER_2),Y
iny
cpy #SCORE_SIZE
bne @copy_score_across_loop
copy_name_across:
lda TEMP_POINTER_2
clc
adc #<((-NAME_SIZE))
sta MAP_POINTER
lda TEMP_POINTER_2 + 1
adc #>((-NAME_SIZE))
sta MAP_POINTER + 1
ldy #NAME_SIZE - 1
@copy_name_across_loop:
lda player_name,Y
sta (MAP_POINTER),Y
dey
bpl @copy_name_across_loop
lda #NUMBER_OF_ENTRIES
sec
sbc HIGH_SCORE_POSITION
sta HIGH_SCORE_POSITION
rts
not_a_high_score:
lda #255
sta HIGH_SCORE_POSITION
rts
NAME_LENGTH = TEMP_BYTE_9
CURRENT_LETTER = TEMP_BYTE_8
try_to_enter_name:
ldx #<(clearscr)
ldy #>(clearscr)
jsr prtmessage
strip_leading_zeros:
ldy #0
sty TEMP_BYTE
@strip_leading_zeros_loop:
lda PLAYER_SCORE,Y
bit TEMP_BYTE
bmi @strip_leading_zeros_skip_if_negative
cmp #0
beq @strip_leading_zeros_skip_if_equal
dec TEMP_BYTE
bne @strip_leading_zeros_skip_if_negative
@strip_leading_zeros_skip_if_equal:
lda #($FD)
@strip_leading_zeros_skip_if_negative:
sta PLAYER_SCORE,Y
iny
cpy #6
bne @strip_leading_zeros_loop
put_in_comma:
ldx #5
ldy #6
@put_in_comma_loop:
lda PLAYER_SCORE,X
clc
adc #33
sta PLAYER_SCORE,Y
cpx #3
bne @put_in_comma_skip_if_not_equal
dey
lda #29
sta PLAYER_SCORE,Y
@put_in_comma_skip_if_not_equal:
dey
dex
bpl @put_in_comma_loop
jsr try_high_score
display_high_scores:
jsr setup_high_scores
lda MUSIC_TUNE
cmp #1
beq @display_high_scores_skip_if_equal
lda #3
jsr starttune
@display_high_scores_skip_if_equal:
jsr turninteron
lda #0
sta NAME_LENGTH
lda #1
sta CURRENT_LETTER
looking_at_high_scores:
asl VBLANK_FLAG
@looking_at_high_scores_wait_vblank:
bit VBLANK_FLAG
bpl @looking_at_high_scores_wait_vblank
bit HIGH_SCORE_POSITION
bmi @looking_at_high_scores_skip_if_negative
jsr enter_name
jmp @looking_at_high_scores_skip
@looking_at_high_scores_skip_if_negative:
ldx #13
jsr pulsecolour
@looking_at_high_scores_skip:
lda JOYPAD_STATE
and #BUTTON_START_MASK
beq looking_at_high_scores
lda JOYPAD_DEBOUNCE
and #BUTTON_START_MASK
bne looking_at_high_scores
jmp turninterofffade
setup_high_scores:
lda #CHARSET_HIGH_SCORE
jsr copyblockofcompactedchrs
lda #CHARSET_HIGH_SCORE_2
jsr copyblockofcompactedchrs
lda #CHARSET_OK
jsr copyblockofcompactedchrs
ldx #<(high_score_screen)
ldy #>(high_score_screen)
jsr prtmessage
lda #100
sta PLAYER_Y
lda HIGH_SCORE_POSITION
cmp #254
beq show_credits
ldx #<(high_score_message)
ldy #>(high_score_message)
jsr prtmessage
lda HIGH_SCORE_POSITION
bmi @setup_high_scores_skip_if_negative
ldx #<(enter_name_message)
ldy #>(enter_name_message)
jmp printed_enter_name
@setup_high_scores_skip_if_negative:
ldx #<(high_score_press_start)
ldy #>(high_score_press_start)
jmp printed_enter_name
show_credits:
ldx #<(credits)
ldy #>(credits)
printed_enter_name:
jsr prtmessage
jsr clearspriteblock
ldx #<(high_score_screen_colours)
ldy #>(high_score_screen_colours)
jmp setfade
enter_name:
lda FRAME_COUNTER
and #7
bne choose_letter
lda JOYPAD_STATE
and #BUTTON_UP_MASK + BUTTON_RIGHT_MASK
beq @enter_name_skip_if_equal
inc CURRENT_LETTER
lda #SFX_LEFT_RIGHT_LETTER
jsr soundfx
@enter_name_skip_if_equal:
lda JOYPAD_STATE
and #BUTTON_DOWN_MASK + BUTTON_LEFT_MASK
beq @enter_name_skip_if_equal_2
dec CURRENT_LETTER
lda #SFX_LEFT_RIGHT_LETTER
jsr soundfx
@enter_name_skip_if_equal_2:
lda CURRENT_LETTER
and #31
sta CURRENT_LETTER
choose_letter:
lda JOYPAD_STATE
and #BUTTON_A_MASK
beq @choose_letter_skip_if_equal
lda JOYPAD_DEBOUNCE
and #BUTTON_A_MASK
bne @choose_letter_skip_if_equal
lda CURRENT_LETTER
bne @choose_letter_skip_if_not_equal
lda #BUTTON_START_MASK
sta JOYPAD_STATE
jmp @choose_letter_skip_if_equal
@choose_letter_skip_if_not_equal:
lda NAME_LENGTH
cmp #8
beq @choose_letter_skip_if_equal
lda CURRENT_LETTER
jsr print_a_chr
lda CURRENT_LETTER
ldy NAME_LENGTH
sta (MAP_POINTER),Y
inc NAME_LENGTH
lda #SFX_CHOOSE_LETTER
jsr soundfx
lda CURRENT_LETTER
jmp flash_letter
@choose_letter_skip_if_equal:
delete_letter:
lda JOYPAD_STATE
and #BUTTON_B_MASK
beq @delete_letter_skip_if_equal
lda JOYPAD_DEBOUNCE
and #BUTTON_B_MASK
bne @delete_letter_skip_if_equal
ldy NAME_LENGTH
beq @delete_letter_skip_if_equal
dec NAME_LENGTH
lda #30
dey
sta (MAP_POINTER),Y
jsr print_a_chr
lda #SFX_DELETE_LETTER
jsr soundfx
@delete_letter_skip_if_equal:
flash_letter:
lda #0
sta TEMP_BYTE
lda NAME_LENGTH
asl
asl
asl
clc
adc #64
tax
lda HIGH_SCORE_POSITION
asl
asl
asl
clc
adc #63 + 32
tay
lda CURRENT_LETTER
jsr pokesprite
ldx #14
jsr pulsecolour
ldx #17
jmp pulsecolour
print_a_chr:
tax
lda #<(8584 - 32)
sta TEMP_POINTER
lda #>(8584 - 32)
sta TEMP_POINTER + 1
ldy HIGH_SCORE_POSITION
@print_a_chr_loop:
lda TEMP_POINTER
clc
adc #<(32)
sta TEMP_POINTER
bcc @print_a_chr_skip_if_no_carry
inc TEMP_POINTER + 1
@print_a_chr_skip_if_no_carry:
dey
bpl @print_a_chr_loop
ldy VRAM_WRITE_POINTER
lda TEMP_POINTER + 1
sta VRAM_BUFFER_ADDRESS,Y
lda TEMP_POINTER
clc
adc NAME_LENGTH
sta VRAM_BUFFER_ADDRESS + 1,Y
lda #1
sta VRAM_BUFFER_ADDRESS + 2,Y
txa
sta VRAM_BUFFER_ADDRESS + 3,Y
tya
clc
adc #4
sta VRAM_WRITE_POINTER
rts
high_score_screen:
.byte <(MESSAGE_GOSUB)
.word clearscr
.byte <(MESSAGE_ADDRESS + 32)
.byte $20
.byte $2B,$2C,$00,$00,$00,$32
.byte <(MESSAGE_DOWN_LINE)
.byte $2D,$2E,$2F,$30,$33,$34,$35,$36
.byte <(MESSAGE_LOOP)
.byte $12
.byte $3A
.byte <(MESSAGE_END_LOOP)
.byte $3B,$3C,$3A,$3A,$3A,$3A
.byte $20,$20,$20,$31,$37,$38
.byte <(MESSAGE_LOOP)
.byte $14
.byte $39
.byte <(MESSAGE_END_LOOP)
.byte $3D,$3E,$39,$39,$39,$39
.byte $3F,$40,$41,$42,$4E,$4F
.byte <(MESSAGE_LOOP)
.byte $14
.byte $50
.byte <(MESSAGE_END_LOOP)
.byte $5C,$5D,$50,$50,$50,$50
.byte $43,$44,$45,$46,$51,$52,$53,$54
.byte <(MESSAGE_LOOP)
.byte $12
.byte $5B
.byte <(MESSAGE_END_LOOP)
.byte $5E,$5F,$5B,$5B,$5B,$5B
.byte $47,$48,$49,$4A,$55,$56
.byte <(MESSAGE_LOOP)
.byte $14
.byte $57
.byte <(MESSAGE_END_LOOP)
.byte $60,$55,$63,$64,$65,$00
.byte $00,$4B,$4C,$4D,$58,$59
.byte <(MESSAGE_LOOP)
.byte $14
.byte $5A
.byte <(MESSAGE_END_LOOP)
.byte $61,$62,$66,$67,$68,$00
.byte <(MESSAGE_ADDRESS + 33)
.byte $03
.byte <(MESSAGE_LOOP)
.byte $12
.byte $00
.byte $69
.byte $6A
.byte <(MESSAGE_LOOP)
.byte $14
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $02
.byte $89
.byte $8A
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_JUMP)
.word high_score_screen_4
high_score_screen_4:
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $00,$96,$97
.byte <(MESSAGE_LOOP)
.byte $14
.byte <(MESSAGE_LENGTH)
.byte $01
.byte $20
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $02
.byte $B4
.byte $B5
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $93,$98,$99
.byte <(MESSAGE_LOOP)
.byte $0A
.byte <(MESSAGE_LENGTH)
.byte $02
.byte $9A
.byte $9B
.byte <(MESSAGE_END_LOOP)
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $B6,$B7,$B8
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $1A
.byte $B9,$BB,$BC,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$BD,$BE,$C2,$C3,$BA
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $17
.byte $00,$BF,$00,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1,$C0,$C1
.byte <(MESSAGE_ADDRESS + 35)
.byte $C0
.byte <(MESSAGE_LENGTH)
.byte $40
.byte $50,$50,$50,$50,$50,$50,$50,$50,$55,$25,$05,$05,$05,$05,$85,$55,$00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$00
.byte $00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$00,$00,$22,$00,$00,$00,$00,$88,$20,$00,$02,$00,$00,$00,$00,$08,$02
.byte <(MESSAGE_END)
high_score_fancy_bits:
.byte <(MESSAGE_GOSUB)
.word high_score_bit
do_fleur:
.byte <(MESSAGE_ADDRESS + 34)
.byte $E7
.byte <(MESSAGE_GOSUB)
.word fleur_delays
.byte <(MESSAGE_ADDRESS + 34)
.byte $F7
fleur_delays:
.byte <(MESSAGE_LENGTH)
.byte $02
.byte $8B
.byte $8C
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $9C
.byte $9D
.byte $9E
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $03
.byte $9F
.byte $A0
.byte $A1
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $02
.byte $A2
.byte $A3
.byte <(MESSAGE_END)
high_score_bit:
.byte <(MESSAGE_ADDRESS + 33)
.byte $08
.byte $6B,$20,$6C
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $10
.byte $6D,$6E,$6F,$70,$75,$76,$77,$78,$7D,$7E,$7F,$80,$85,$86,$75,$76
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_LENGTH)
.byte $10
.byte $71,$72,$73,$74,$79,$7A,$7B,$7C,$81,$82,$83,$84,$87,$88,$79,$7A
.byte <(MESSAGE_END)
high_score_press_start:
.byte <(MESSAGE_ADDRESS + 35)
.byte $0E
.byte MESSAGE_TEXT
.word text_press_start
.byte <(MESSAGE_JUMP)
.word flashing_bit
enter_name_message:
.byte <(MESSAGE_ADDRESS + 35)
.byte $0A
.byte MESSAGE_TEXT
.word text_please_enter_name
flashing_bit:
.byte <(MESSAGE_GOSUB)
.word high_score_fancy_bits
.byte <(MESSAGE_ADDRESS + 35)
.byte $F2
.byte <(MESSAGE_LENGTH)
.byte $04
.byte $0C
.byte $0F
.byte $0F
.byte $03
.byte <(MESSAGE_END)
credits:
.byte <(MESSAGE_ADDRESS + 33)
.byte $07
.byte MESSAGE_TEXT
.word text_credits_1
.byte MESSAGE_TEXT
.word text_credits_2
.byte <(MESSAGE_END)
high_score_screen_colours:
.byte $21,$27,$16,$09
.byte $21,$20,$27,$0E
.byte $21,$27,$16,$0E
.byte $21,$37,$27,$09
.byte $21,$27,$11,$09
.byte $21,$20,$15,$0E
.byte $21,$00,$00,$00
.byte $21,$0E,$0E,$0E
high_score_message:
.byte <(MESSAGE_ADDRESS + 33)
.byte $88
.byte <(MESSAGE_GOSUB)
.word HIGH_SCORES_IN_RAM
.byte <(MESSAGE_END)
copy_high_scores_to_ram:
cpx #HIGH_SCORES_MAGIC
beq dont_copy_in_scores
copy_hiscore_entry:
ldx #17 * 10 + 1
copy_hiscore_loop:
lda init_names - 1,X
sta HIGH_SCORES_IN_RAM - 1,X
dex
bne copy_hiscore_loop
rts
dont_copy_in_scores:
ldx #0
@dont_copy_in_scores_loop:
ldy #0
@dont_copy_in_scores_loop_2:
lda check_high_scores,Y
bpl @dont_copy_in_scores_skip_if_positive
cmp #131
bcs @dont_copy_in_scores_skip_if_positive
cmp #128
bne @dont_copy_in_scores_skip_if_not_equal
lda HIGH_SCORES_IN_RAM,X
cmp #33
bcs copy_hiscore_entry
jmp @dont_copy_in_scores_skip
@dont_copy_in_scores_skip_if_not_equal:
lda HIGH_SCORES_IN_RAM,X
cmp #30
beq @dont_copy_in_scores_skip
cmp #32
bcc copy_hiscore_entry
cmp #43
bcs copy_hiscore_entry
jmp @dont_copy_in_scores_skip
@dont_copy_in_scores_skip_if_positive:
cmp HIGH_SCORES_IN_RAM,X
bne copy_hiscore_entry
@dont_copy_in_scores_skip:
inx
iny
cpy #17
bne @dont_copy_in_scores_loop_2
cpx #10 * 17
bne @dont_copy_in_scores_loop
lda HIGH_SCORES_IN_RAM + 17 * 10
cmp #255
bne copy_hiscore_entry
rts
init_names:
.byte $06,$09,$12,$13,$14,$1E,$1E,$1E,$1E
.byte $1E
.byte $23
.byte $21
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $13,$05,$03,$0F,$0E,$04,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $29
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $14,$08,$09,$12,$04,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $27
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $06,$0F,$15,$12,$14,$08,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $25
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $06,$09,$06,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $23
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $13,$09,$18,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $22
.byte $21
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $13,$05,$16,$05,$0E,$14,$08,$1E,$1E
.byte $1E
.byte $1E
.byte $29
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $05,$09,$07,$08,$14,$08,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $27
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $0E,$09,$0E,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $25
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte $14,$05,$0E,$14,$08,$1E,$1E,$1E,$1E
.byte $1E
.byte $1E
.byte $23
.byte $1D
.byte $21
.byte $21
.byte $21
.byte <(MESSAGE_DOWN_LINE)
.byte <(MESSAGE_END)
player_name:
.byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E
check_high_scores:
.res 9, 128
.byte $81
.byte $81
.byte $81
.byte $1D
.byte $81
.byte $81
.byte $81
.byte <(MESSAGE_DOWN_LINE)
