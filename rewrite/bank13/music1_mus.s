MUSIC_IRQ_SETTING .set 15
MUSIC_ZERO_PAGE_START .set ZERO_PAGE_ALLOCATION
MUSIC_RAM_START .set RAM_ALLOCATION
ZP_VAR MUSIC_TEMP_A, 2
ZP_VAR MUSIC_TEMP_B, 2
ZP_VAR MUSIC_TEMP_C, 2
ZP_VAR MUSIC_TEMP_LOW
ZP_VAR MUSIC_TEMP_HIGH
ZP_VAR MUSIC_TEMP_Y, 2
RAM_VAR MUSIC_VARIABLES_START
MUSIC_COUNTER = MUSIC_VARIABLES_START
RAM_VAR MUSIC_VOICE_1
RAM_VAR MUSIC_VOICE_2
RAM_VAR MUSIC_VOICE_3
RAM_VAR MUSIC_VOICE_4
RAM_VAR MUSIC_DELAY_SMALL_1
RAM_VAR MUSIC_DELAY_SMALL_2
RAM_VAR MUSIC_DELAY_SMALL_3
RAM_VAR MUSIC_DELAY_SMALL_4
RAM_VAR MUSIC_REVERB_COUNT_1
RAM_VAR MUSIC_REVERB_COUNT_2
RAM_VAR MUSIC_REVERB_COUNT_3
RAM_VAR MUSIC_REVERB_COUNT_4
RAM_VAR MUSIC_ECHO_HOLD_1
RAM_VAR MUSIC_ECHO_HOLD_2
RAM_VAR MUSIC_ECHO_HOLD_3
RAM_VAR MUSIC_ECHO_HOLD_4
RAM_VAR MUSIC_WOBBLE_DELAY_1
RAM_VAR MUSIC_WOBBLE_DELAY_2
RAM_VAR MUSIC_WOBBLE_DELAY_3
RAM_VAR MUSIC_WOBBLE_DELAY_4
RAM_VAR MUSIC_WOBBLE_PROGRESS_1
RAM_VAR MUSIC_WOBBLE_PROGRESS_2
RAM_VAR MUSIC_WOBBLE_PROGRESS_3
RAM_VAR MUSIC_WOBBLE_PROGRESS_4
RAM_VAR MUSIC_WOBBLE_COUNT_1
RAM_VAR MUSIC_WOBBLE_COUNT_2
RAM_VAR MUSIC_WOBBLE_COUNT_3
RAM_VAR MUSIC_WOBBLE_COUNT_4
RAM_VAR MUSIC_WOBBLE_PHASE_1
RAM_VAR MUSIC_WOBBLE_PHASE_2
RAM_VAR MUSIC_WOBBLE_PHASE_3
RAM_VAR MUSIC_WOBBLE_PHASE_4
RAM_VAR MUSIC_WOBBLE_FREQUENCY_1
RAM_VAR MUSIC_WOBBLE_FREQUENCY_2
RAM_VAR MUSIC_WOBBLE_FREQUENCY_3
RAM_VAR MUSIC_WOBBLE_FREQUENCY_4
RAM_VAR MUSIC_WOBBLE_AMOUNT_1
RAM_VAR MUSIC_WOBBLE_AMOUNT_2
RAM_VAR MUSIC_WOBBLE_AMOUNT_3
RAM_VAR MUSIC_WOBBLE_AMOUNT_4
RAM_VAR MUSIC_SPECIAL_THUD_1
RAM_VAR MUSIC_SPECIAL_THUD_2
RAM_VAR MUSIC_SPECIAL_THUD_3
RAM_VAR MUSIC_SPECIAL_THUD_4
RAM_VAR MUSIC_VOLUME_1
RAM_VAR MUSIC_VOLUME_2
RAM_VAR MUSIC_VOLUME_3
RAM_VAR MUSIC_VOLUME_4
RAM_VAR MUSIC_NOTE_1
RAM_VAR MUSIC_NOTE_2
RAM_VAR MUSIC_NOTE_3
RAM_VAR MUSIC_NOTE_4
RAM_VAR MUSIC_OLD_NOTE_1
RAM_VAR MUSIC_OLD_NOTE_2
RAM_VAR MUSIC_OLD_NOTE_3
RAM_VAR MUSIC_OLD_NOTE_4
RAM_VAR MUSIC_LOW_PITCH_1
RAM_VAR MUSIC_LOW_PITCH_2
RAM_VAR MUSIC_LOW_PITCH_3
RAM_VAR MUSIC_LOW_PITCH_4
RAM_VAR MUSIC_HIGH_PITCH_1
RAM_VAR MUSIC_HIGH_PITCH_2
RAM_VAR MUSIC_HIGH_PITCH_3
RAM_VAR MUSIC_HIGH_PITCH_4
RAM_VAR MUSIC_PHASE_1
RAM_VAR MUSIC_PHASE_2
RAM_VAR MUSIC_PHASE_3
RAM_VAR MUSIC_PHASE_4
RAM_VAR MUSIC_INSTRUMENT_1
RAM_VAR MUSIC_INSTRUMENT_2
RAM_VAR MUSIC_INSTRUMENT_3
RAM_VAR MUSIC_INSTRUMENT_4
RAM_VAR MUSIC_TIN_TONE_1
RAM_VAR MUSIC_TIN_TONE_2
RAM_VAR MUSIC_TIN_TONE_3
RAM_VAR MUSIC_TIN_TONE_4
RAM_VAR MUSIC_TIN_DELAY_1
RAM_VAR MUSIC_TIN_DELAY_2
RAM_VAR MUSIC_TIN_DELAY_3
RAM_VAR MUSIC_TIN_DELAY_4
RAM_VAR MUSIC_MACRO_COUNT_1
RAM_VAR MUSIC_MACRO_COUNT_2
RAM_VAR MUSIC_MACRO_COUNT_3
RAM_VAR MUSIC_MACRO_COUNT_4
RAM_VAR MUSIC_CHORD_SHAPE_1
MUSIC_GLISSANDO_WAIT_1 = MUSIC_CHORD_SHAPE_1
RAM_VAR MUSIC_CHORD_SHAPE_2
MUSIC_GLISSANDO_WAIT_2 = MUSIC_CHORD_SHAPE_2
RAM_VAR MUSIC_CHORD_SHAPE_3
MUSIC_GLISSANDO_WAIT_3 = MUSIC_CHORD_SHAPE_3
RAM_VAR MUSIC_CHORD_SHAPE_4
MUSIC_GLISSANDO_WAIT_4 = MUSIC_CHORD_SHAPE_4
RAM_VAR MUSIC_GLISSANDO_NEW_NOTE_1
RAM_VAR MUSIC_GLISSANDO_NEW_NOTE_2
RAM_VAR MUSIC_GLISSANDO_NEW_NOTE_3
RAM_VAR MUSIC_GLISSANDO_NEW_NOTE_4
RAM_VAR MUSIC_GLISSANDO_RATE_1
RAM_VAR MUSIC_GLISSANDO_RATE_2
RAM_VAR MUSIC_GLISSANDO_RATE_3
RAM_VAR MUSIC_GLISSANDO_RATE_4
RAM_VAR MUSIC_CHORD_COUNTER
RAM_VAR MUSIC_MAIN_COUNTER, 2
MUSIC_VARIABLES_END = RAM_ALLOCATION
RAM_VAR MUSIC_MACRO_POINTER_1, 2
RAM_VAR MUSIC_MACRO_POINTER_2, 2
RAM_VAR MUSIC_MACRO_POINTER_3, 2
RAM_VAR MUSIC_MACRO_POINTER_4, 2
RAM_VAR MUSIC_SAVED_MACRO_POINTER_1, 2
RAM_VAR MUSIC_SAVED_MACRO_POINTER_2, 2
RAM_VAR MUSIC_SAVED_MACRO_POINTER_3, 2
RAM_VAR MUSIC_SAVED_MACRO_POINTER_4, 2
RAM_VAR MUSIC_TUNE
RAM_VAR MUSIC_TEMPO
RAM_VAR MUSIC_TRANSPOSE
RAM_VAR MUSIC_DELAY_MAIN
.byte $0D
jmp start_music
jmp play_music
start_music:
sta MUSIC_TUNE
sec
sbc #1
sta MUSIC_TEMP_A
asl
asl
adc MUSIC_TEMP_A
asl
tay
lda song_pointer_table
sta MUSIC_TEMP_A
lda song_pointer_table + 1
sta MUSIC_TEMP_A + 1
lda (MUSIC_TEMP_A),Y
sta MUSIC_TRANSPOSE
iny
lda (MUSIC_TEMP_A),Y
sta MUSIC_TEMPO
ldx #0
@loop:
iny
lda (MUSIC_TEMP_A),Y
sta MUSIC_MACRO_POINTER_1,X
sta MUSIC_SAVED_MACRO_POINTER_1,X
inx
cpx #8
bcc @loop
trigger:
ldy #MUSIC_VARIABLES_END - MUSIC_VARIABLES_START
lda #0
@loop2:
sta MUSIC_VARIABLES_START - 1,Y
dey
bne @loop2
lda #MUSIC_IRQ_SETTING
sta 16405
lda MUSIC_TEMPO
sec
sbc #1
sta MUSIC_DELAY_MAIN
ldx #0
jsr new_macro
ldx #1
jsr new_macro
ldx #2
jsr new_macro
ldx #3
jmp new_macro
play_music:
inc MUSIC_COUNTER
lda MUSIC_TUNE
bne @go
rts
@go:
lda MUSIC_VOICE_1
beq @skip_voice1_dec
dec MUSIC_VOICE_1
@skip_voice1_dec:
lda MUSIC_VOICE_2
beq @skip_voice2_dec
dec MUSIC_VOICE_2
@skip_voice2_dec:
lda MUSIC_VOICE_3
beq @skip_voice3_dec
dec MUSIC_VOICE_3
@skip_voice3_dec:
lda MUSIC_VOICE_4
beq @skip_voice4_dec
dec MUSIC_VOICE_4
@skip_voice4_dec:
inc MUSIC_MAIN_COUNTER
jsr delay_bit
lda MUSIC_MAIN_COUNTER
lsr
bcc @fx_only
jsr delay_bit
@fx_only:
jmp adsr
delay_bit:
inc MUSIC_DELAY_MAIN
lda MUSIC_DELAY_MAIN
cmp MUSIC_TEMPO
bne @no
lda #0
sta MUSIC_DELAY_MAIN
jmp do_voices
@no:
rts
adsr:
ldx #0
@loop:
lda MUSIC_INSTRUMENT_1,X
sta MUSIC_TEMP_Y + 1
txa
asl
asl
tay
sty MUSIC_TEMP_Y
cpx #2
beq @triangle
lda MUSIC_VOICE_1,X
bne @channel_is_off
lda MUSIC_VOLUME_1,X
lsr
lsr
lsr
lsr
ora #48
ora MUSIC_TIN_TONE_1,X
sta 16384,Y
@channel_is_off:
ldy MUSIC_TEMP_Y + 1
lda MUSIC_REVERB_COUNT_1,X
bne @skip_adsr
lda MUSIC_PHASE_1,X
beq @attack
cmp #1
beq @decay
bne @sustain
@attack:
lda MUSIC_VOLUME_1,X
clc
adc instruments + 1,Y
bcs @top
cmp instruments + 2,Y
bcc @no_top
@top:
lda instruments + 2,Y
inc MUSIC_PHASE_1,X
@no_top:
sta MUSIC_VOLUME_1,X
jmp @continue
@decay:
lda MUSIC_VOLUME_1,X
sec
sbc instruments + 3,Y
bcc @bot
cmp instruments + 4,Y
bcs @no_bot
@bot:
lda instruments + 4,Y
inc MUSIC_PHASE_1,X
@no_bot:
sta MUSIC_VOLUME_1,X
beq @jjj_it
jmp @continue
@sustain:
lda instruments + 4,Y
bne @neq
@jjj_it:
jmp @no_high
@neq:
sta MUSIC_VOLUME_1,X
@skip_adsr:
@triangle:
@continue:
cpx #2
bcs @special
@j_no_special:
jmp @no_special
@special:
lda MUSIC_SPECIAL_THUD_1,X
beq @j_no_special
cpx #3
bne @not_white_noise
ldy MUSIC_TEMP_Y
lda MUSIC_VOICE_1,X
bne @channel_is_off2
lda MUSIC_LOW_PITCH_1,X
clc
adc #199
sta MUSIC_LOW_PITCH_1,X
sta 16386,Y
@channel_is_off2:
dec MUSIC_SPECIAL_THUD_1,X
bne @get_y_bit
lda #0
sta MUSIC_VOLUME_1,X
lda #2
sta MUSIC_PHASE_1,X
bne @get_y_bit
@not_white_noise:
cmp #255
bne @n_doof
ldy MUSIC_TEMP_Y
lda #35
jsr sub_voice
lda MUSIC_HIGH_PITCH_1,X
cmp #2
bcc @get_y_bit
lda #0
sta MUSIC_SPECIAL_THUD_1,X
sta MUSIC_VOLUME_1,X
lda MUSIC_VOICE_1,X
bne @channel_is_off3
sta 16384,Y
lda #6
sta 16386,Y
lda #174
sta 16387,Y
bne @get_y_bit
@n_doof:
dec MUSIC_SPECIAL_THUD_1,X
bne @no_special
lda #255
sta MUSIC_SPECIAL_THUD_1,X
ldy MUSIC_TEMP_Y + 1
lda instruments + 11,Y
tay
lda frequency_table_lo,Y
sta MUSIC_LOW_PITCH_1,X
lda frequency_table_hi,Y
sta MUSIC_HIGH_PITCH_1,X
ldy MUSIC_TEMP_Y
lda MUSIC_VOICE_1,X
bne @channel_is_off4
lda MUSIC_LOW_PITCH_1,X
sta 16386,Y
lda MUSIC_HIGH_PITCH_1,X
sta 16387,Y
lda #32
sta 16384,Y
@channel_is_off3:
@channel_is_off4:
@get_y_bit:
ldy MUSIC_TEMP_Y + 1
@no_special:
lda instruments + 10,Y
beq @no_reverb
sta 255
lsr
sta 254
inc MUSIC_REVERB_COUNT_1,X
lda MUSIC_REVERB_COUNT_1,X
cmp 255
bne @n0
lda #0
sta MUSIC_REVERB_COUNT_1,X
@n0:
bne @n3
lda MUSIC_ECHO_HOLD_1,X
sta MUSIC_VOLUME_1,X
jmp @next
@n3:
cmp 254
beq @on1
bcs @on2
bcc @next
@on1:
lda MUSIC_VOLUME_1,X
sta MUSIC_ECHO_HOLD_1,X
@on2:
lda #0
sta MUSIC_VOLUME_1,X
@next:
ldy MUSIC_TEMP_Y + 1
@on:
@no_reverb:
ldy MUSIC_TEMP_Y + 1
lda instruments + 5,Y
and #240
beq @one_off
lsr
lsr
lsr
lsr
asl
sta MUSIC_TEMP_A
inc MUSIC_TIN_DELAY_1,X
lda MUSIC_TIN_DELAY_1,X
cmp MUSIC_TEMP_A
bcc @stoped
lda #0
sta MUSIC_TIN_DELAY_1,X
beq @inc_tinny
@one_off:
lda MUSIC_TIN_TONE_1,X
asl
rol
rol
sta MUSIC_TEMP_A
lda instruments + 5,Y
and #3
cmp MUSIC_TEMP_A
beq @stoped
@inc_tinny:
lda MUSIC_TIN_TONE_1,X
clc
adc #64
bcc @ok
lda #0
@ok:
sta MUSIC_TIN_TONE_1,X
@stoped:
lda MUSIC_CHORD_SHAPE_1,X
ora MUSIC_GLISSANDO_RATE_1,X
bne @no_wob
ldy MUSIC_TEMP_Y + 1
lda MUSIC_WOBBLE_DELAY_1,X
cmp instruments + 6,Y
beq @wobble_ready
inc MUSIC_WOBBLE_DELAY_1,X
bne @no_wob
@wobble_ready:
lda MUSIC_WOBBLE_AMOUNT_1,X
sta MUSIC_TEMP_A
ldy MUSIC_TEMP_Y
lda MUSIC_WOBBLE_PHASE_1,X
beq @up_wob
cmp #1
beq @down_wob
lda MUSIC_TEMP_A
jsr add_voice
lda MUSIC_WOBBLE_FREQUENCY_1,X
jsr do_wob_check
jmp @no_wob
@up_wob:
lda MUSIC_TEMP_A
jsr add_voice
lda MUSIC_WOBBLE_FREQUENCY_1,X
jsr do_wob_check
jmp @no_wob
@down_wob:
lda MUSIC_TEMP_A
jsr sub_voice
lda MUSIC_WOBBLE_FREQUENCY_1,X
asl
jsr do_wob_check
@no_wob:
lda MUSIC_GLISSANDO_RATE_1,X
bne @gliss
jmp @no_gliss
@gliss:
ldy MUSIC_GLISSANDO_WAIT_1,X
beq @eq
dec MUSIC_GLISSANDO_WAIT_1,X
jmp @no_chords
@eq:
lsr
sta MUSIC_TEMP_A
bcc @no_half
lda MUSIC_MAIN_COUNTER
and #1
beq @no_half
inc MUSIC_TEMP_A
@no_half:
ldy MUSIC_TEMP_Y
lda MUSIC_GLISSANDO_NEW_NOTE_1,X
cmp MUSIC_NOTE_1,X
bcs @go_up
lda MUSIC_TEMP_A
jsr sub_voice
ldy MUSIC_GLISSANDO_NEW_NOTE_1,X
lda frequency_table_lo,Y
sta MUSIC_TEMP_A
lda frequency_table_hi,Y
sta MUSIC_TEMP_A + 1
cmp MUSIC_HIGH_PITCH_1,X
beq @test_low
bcs @j_no
bcc @hit
@test_low:
lda MUSIC_TEMP_A
cmp MUSIC_LOW_PITCH_1,X
beq @hit
bcs @j_no
@hit:
lda #0
sta MUSIC_GLISSANDO_RATE_1,X
sta MUSIC_GLISSANDO_WAIT_1,X
ldy MUSIC_TEMP_Y
lda MUSIC_TEMP_A + 1
cmp MUSIC_HIGH_PITCH_1,X
beq @semi_rewrite
lda MUSIC_TEMP_A + 1
sta MUSIC_HIGH_PITCH_1,X
ldy MUSIC_VOICE_1,X
bne @channel_is_off5
sta 16387,Y
@channel_is_off5:
@semi_rewrite:
lda MUSIC_TEMP_A
sta MUSIC_LOW_PITCH_1,X
ldy MUSIC_VOICE_1,X
bne @channel_is_off6
sta 16386,Y
@channel_is_off6:
@j_no:
jmp @no_chords
@go_up:
lda MUSIC_TEMP_A
jsr add_voice
ldy MUSIC_GLISSANDO_NEW_NOTE_1,X
lda frequency_table_lo,Y
sta MUSIC_TEMP_A
lda frequency_table_hi,Y
sta MUSIC_TEMP_A + 1
cmp MUSIC_HIGH_PITCH_1,X
beq @test_low2
bcc @no_chords
bcs @hit
@test_low2:
lda MUSIC_TEMP_A
cmp MUSIC_LOW_PITCH_1,X
bcs @hit
jmp @no_chords
@no_gliss:
lda MUSIC_CHORD_SHAPE_1,X
beq @no_chords
lda MUSIC_CHORD_COUNTER
beq @chord1
cmp #1
beq @chord2
@chord3:
lda MUSIC_CHORD_SHAPE_1,X
and #15
clc
adc MUSIC_OLD_NOTE_1,X
jmp @blip_note
@chord1:
lda MUSIC_OLD_NOTE_1,X
jmp @blip_note
@chord2:
lda MUSIC_CHORD_SHAPE_1,X
lsr
lsr
lsr
lsr
clc
adc MUSIC_OLD_NOTE_1,X
@blip_note:
tay
lda frequency_table_lo,Y
sta MUSIC_LOW_PITCH_1,X
lda frequency_table_hi,Y
sta MUSIC_HIGH_PITCH_1,X
ldy MUSIC_TEMP_Y
lda MUSIC_VOICE_1,X
bne @voice_off
lda MUSIC_LOW_PITCH_1,X
sta 16386,Y
lda MUSIC_HIGH_PITCH_1,X
sta 16387,Y
@voice_off:
@no_chords:
@no_high:
inx
cpx #4
bcs @no_loop
jmp @loop
@no_loop:
inc MUSIC_CHORD_COUNTER
lda MUSIC_CHORD_COUNTER
cmp #3
bcc @no_ch
lda #0
sta MUSIC_CHORD_COUNTER
@no_ch:
rts
do_wob_check:
ldy MUSIC_TEMP_Y + 1
sta MUSIC_TEMP_B
inc MUSIC_WOBBLE_COUNT_1,X
lda MUSIC_WOBBLE_COUNT_1,X
cmp MUSIC_TEMP_B
bcc @no
lda #0
sta MUSIC_WOBBLE_COUNT_1,X
inc MUSIC_WOBBLE_PHASE_1,X
lda MUSIC_WOBBLE_PHASE_1,X
cmp #3
bcc @no
lda #0
sta MUSIC_WOBBLE_PHASE_1,X
lda MUSIC_WOBBLE_AMOUNT_1,X
cmp instruments + 9,Y
bcs @no
adc instruments + 8,Y
sta MUSIC_WOBBLE_AMOUNT_1,X
cmp instruments + 9,Y
bcc @no
lda instruments + 9,Y
sta MUSIC_WOBBLE_AMOUNT_1,X
@no:
rts
sub_voice:
clc
adc MUSIC_LOW_PITCH_1,X
sta MUSIC_LOW_PITCH_1,X
bcc @store_low
inc MUSIC_HIGH_PITCH_1,X
lda MUSIC_VOICE_1,X
bne @channel_is_off8
lda MUSIC_HIGH_PITCH_1,X
sta 16387,Y
@store_low:
lda MUSIC_VOICE_1,X
bne @channel_is_off8
lda MUSIC_LOW_PITCH_1,X
sta 16386,Y
@channel_is_off8:
rts
add_voice:
sta MUSIC_TEMP_B
lda MUSIC_LOW_PITCH_1,X
sec
sbc MUSIC_TEMP_B
sta MUSIC_LOW_PITCH_1,X
bcs @store_low
dec MUSIC_HIGH_PITCH_1,X
lda MUSIC_VOICE_1,X
bne @channel_is_off7
lda MUSIC_HIGH_PITCH_1,X
sta 16387,Y
@store_low:
lda MUSIC_VOICE_1,X
bne @channel_is_off7
lda MUSIC_LOW_PITCH_1,X
sta 16386,Y
@channel_is_off7:
rts
new_macro:
txa
asl
tay
lda MUSIC_MACRO_POINTER_1,Y
clc
adc #2
sta MUSIC_MACRO_POINTER_1,Y
bcc @no_high
lda MUSIC_MACRO_POINTER_1 + 1,Y
adc #0
sta MUSIC_MACRO_POINTER_1 + 1,Y
@no_high:
lda MUSIC_MACRO_POINTER_1 + 1,Y
sta MUSIC_TEMP_HIGH
lda MUSIC_MACRO_POINTER_1,Y
sta MUSIC_TEMP_LOW
ldy #1
lda (MUSIC_TEMP_LOW),Y
bne @no_stop_tune
cpx #0
bne @no_channel_0
dey
lda (MUSIC_TEMP_LOW),Y
beq @stop_tune
sec
sbc #1
asl
sta MUSIC_TEMP_A
ldx #0
@loop1:
lda MUSIC_SAVED_MACRO_POINTER_1 + 1,X
sta MUSIC_MACRO_POINTER_1 + 1,X
lda MUSIC_SAVED_MACRO_POINTER_1,X
clc
adc MUSIC_TEMP_A
sta MUSIC_MACRO_POINTER_1,X
bcc @no_high_2
inc MUSIC_MACRO_POINTER_1 + 1,X
@no_high_2:
inx
inx
cpx #8
bcc @loop1
jsr trigger
pla
pla
rts
@stop_tune:
lda #0
sta 16405
sta MUSIC_TUNE
sec
rts
@no_channel_0:
@no_stop_tune:
ldy #0
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_TEMP_B
iny
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_TEMP_B + 1
dey
lda (MUSIC_TEMP_B),Y
sta MUSIC_INSTRUMENT_1,X
lda #1
sta MUSIC_MACRO_COUNT_1,X
lda #32
cpx #2
bcs @not_on_wn
clc
adc MUSIC_TRANSPOSE
@not_on_wn:
sta MUSIC_NOTE_1,X
lda #0
sta MUSIC_DELAY_SMALL_1,X
clc
rts
do_voices:
ldx #0
@loop:
dec MUSIC_DELAY_SMALL_1,X
bmi @yes
jmp @next_voice
@yes:
txa
asl
tay
lda MUSIC_MACRO_POINTER_1,Y
sta MUSIC_TEMP_LOW
lda MUSIC_MACRO_POINTER_1 + 1,Y
sta MUSIC_TEMP_HIGH
lda #0
sta MUSIC_CHORD_SHAPE_1,X
sta MUSIC_CHORD_COUNTER
sta MUSIC_GLISSANDO_RATE_1,X
sta MUSIC_SPECIAL_THUD_1,X
tay
lda (MUSIC_TEMP_LOW),Y
pha
iny
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_TEMP_HIGH
pla
sta MUSIC_TEMP_LOW
ldy MUSIC_MACRO_COUNT_1,X
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
cmp #1
bne @no_new
jsr new_macro
bcc @yes
jmp @no_loop
@no_new:
pha
lsr
lsr
lsr
sta MUSIC_TEMP_A
pla
and #7
sec
sbc #1
sta MUSIC_DELAY_SMALL_1,X
bcs @n_large_delaynote
lda MUSIC_TEMP_A
sta MUSIC_DELAY_SMALL_1,X
@new_instrument_reloop:
iny
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
pha
and #63
sta MUSIC_TEMP_C
clc
adc #9
cpx #3
beq @not_on_wn
adc MUSIC_TRANSPOSE
@not_on_wn:
sta MUSIC_NOTE_1,X
sta MUSIC_OLD_NOTE_1,X
pla
asl
rol
rol
and #3
beq @no_chord
cmp #2
beq @chords_on
cmp #1
beq @glissando
lda MUSIC_TEMP_C
asl
clc
adc MUSIC_TEMP_C
asl
asl
sta MUSIC_INSTRUMENT_1,X
jmp @new_instrument_reloop
@glissando:
iny
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
clc
adc MUSIC_TRANSPOSE
sta MUSIC_GLISSANDO_NEW_NOTE_1,X
iny
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_GLISSANDO_WAIT_1,X
iny
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_GLISSANDO_RATE_1,X
jmp @no_chord
@chords_on:
iny
inc MUSIC_MACRO_COUNT_1,X
lda (MUSIC_TEMP_LOW),Y
sta MUSIC_CHORD_SHAPE_1,X
@no_chord:
jmp @sort_delay
@n_large_delaynote:
lda MUSIC_TEMP_A
sec
sbc #16
clc
adc MUSIC_NOTE_1,X
sta MUSIC_NOTE_1,X
sta MUSIC_OLD_NOTE_1,X
@sort_delay:
lda #0
sta MUSIC_REVERB_COUNT_1,X
sta MUSIC_WOBBLE_DELAY_1,X
sta MUSIC_WOBBLE_PHASE_1,X
sta MUSIC_WOBBLE_COUNT_1,X
lda #1
sta MUSIC_WOBBLE_AMOUNT_1,X
ldy MUSIC_INSTRUMENT_1,X
lda instruments + 7,Y
sta MUSIC_WOBBLE_FREQUENCY_1,X
lda instruments + 6,Y
bne @del_wob
lda instruments + 9,Y
sta MUSIC_WOBBLE_AMOUNT_1,X
@del_wob:
ldy MUSIC_INSTRUMENT_1,X
lda instruments + 11,Y
beq @no_thud
cpx #3
beq @white_noise
lda #2
@white_noise:
sta MUSIC_SPECIAL_THUD_1,X
@no_thud:
lda instruments + 5,Y
and #12
asl
asl
asl
asl
sta MUSIC_TIN_TONE_1,X
lda #0
sta MUSIC_TIN_DELAY_1,X
ldy MUSIC_INSTRUMENT_1,X
lda instruments,Y
sta MUSIC_VOLUME_1,X
ldy MUSIC_NOTE_1,X
lda frequency_table_lo,Y
sta MUSIC_LOW_PITCH_1,X
lda frequency_table_hi,Y
sta MUSIC_HIGH_PITCH_1,X
lda #0
sta MUSIC_PHASE_1,X
txa
asl
asl
tay
lda MUSIC_VOICE_1,X
bne @channel_is_off
lda #1
sta 16385,Y
lda MUSIC_LOW_PITCH_1,X
sta 16386,Y
lda MUSIC_HIGH_PITCH_1,X
sta 16387,Y
cpx #2
bne @no_triangle
ldy MUSIC_INSTRUMENT_1,X
lda instruments + 1,Y
pha
txa
asl
asl
tay
pla
sta 16384,Y
@channel_is_off:
@no_triangle:
@next_voice:
inx
cpx #4
bcs @no_loop
jmp @loop
@no_loop:
rts
frequency_table_lo:
.byte <(1710)
.byte <(1614)
.byte <(1523)
.byte <(1438)
.byte <(1357)
.byte <(1281)
.byte <(1209)
.byte <(1141)
.byte <(1077)
.byte <(1016)
.byte <(959)
.byte <(905)
.byte <(1710 / 2)
.byte <(1614 / 2)
.byte <(1523 / 2)
.byte <(1438 / 2)
.byte <(1357 / 2)
.byte <(1281 / 2)
.byte <(1209 / 2)
.byte <(1141 / 2)
.byte <(1077 / 2)
.byte <(1016 / 2)
.byte <(959 / 2)
.byte <(905 / 2)
.byte <(1710 / 4)
.byte <(1614 / 4)
.byte <(1523 / 4)
.byte <(1438 / 4)
.byte <(1357 / 4)
.byte <(1281 / 4)
.byte <(1209 / 4)
.byte <(1141 / 4)
.byte <(1077 / 4)
.byte <(1016 / 4)
.byte <(959 / 4)
.byte <(905 / 4)
.byte <(1710 / 8)
.byte <(1614 / 8)
.byte <(1523 / 8)
.byte <(1438 / 8)
.byte <(1357 / 8)
.byte <(1281 / 8)
.byte <(1209 / 8)
.byte <(1141 / 8)
.byte <(1077 / 8)
.byte <(1016 / 8)
.byte <(959 / 8)
.byte <(905 / 8)
.byte <(1710 / 16)
.byte <(1614 / 16)
.byte <(1523 / 16)
.byte <(1438 / 16)
.byte <(1357 / 16)
.byte <(1281 / 16)
.byte <(1209 / 16)
.byte <(1141 / 16)
.byte <(1077 / 16)
.byte <(1016 / 16)
.byte <(959 / 16)
.byte <(905 / 16)
.byte <(1710 / 32)
.byte <(1614 / 32)
.byte <(1523 / 32)
.byte <(1438 / 32)
.byte <(1357 / 32)
.byte <(1281 / 32)
.byte <(1209 / 32)
.byte <(1141 / 32)
.byte <(1077 / 32)
.byte <(1016 / 32)
.byte <(959 / 32)
.byte <(905 / 32)
.byte <(1710 / 64)
.byte <(1614 / 64)
.byte <(1523 / 64)
.byte <(1438 / 64)
.byte <(1357 / 64)
.byte <(1281 / 64)
.byte <(1209 / 64)
.byte <(1141 / 64)
.byte <(1077 / 64)
.byte <(1016 / 64)
.byte <(959 / 64)
.byte <(905 / 64)
.byte <(1710 / 128)
.byte <(1614 / 128)
.byte <(1523 / 128)
.byte <(1438 / 128)
.byte <(1357 / 128)
.byte <(1281 / 128)
.byte <(1209 / 128)
.byte <(1141 / 128)
.byte <(1077 / 128)
.byte <(1016 / 128)
.byte <(959 / 128)
.byte <(905 / 128)
frequency_table_hi:
.byte >(1710)
.byte >(1614)
.byte >(1523)
.byte >(1438)
.byte >(1357)
.byte >(1281)
.byte >(1209)
.byte >(1141)
.byte >(1077)
.byte >(1016)
.byte >(959)
.byte >(905)
.byte >(1710 / 2)
.byte >(1614 / 2)
.byte >(1523 / 2)
.byte >(1438 / 2)
.byte >(1357 / 2)
.byte >(1281 / 2)
.byte >(1209 / 2)
.byte >(1141 / 2)
.byte >(1077 / 2)
.byte >(1016 / 2)
.byte >(959 / 2)
.byte >(905 / 2)
.byte >(1710 / 4)
.byte >(1614 / 4)
.byte >(1523 / 4)
.byte >(1438 / 4)
.byte >(1357 / 4)
.byte >(1281 / 4)
.byte >(1209 / 4)
.byte >(1141 / 4)
.byte >(1077 / 4)
.byte >(1016 / 4)
.byte >(959 / 4)
.byte >(905 / 4)
.byte >(1710 / 8)
.byte >(1614 / 8)
.byte >(1523 / 8)
.byte >(1438 / 8)
.byte >(1357 / 8)
.byte >(1281 / 8)
.byte >(1209 / 8)
.byte >(1141 / 8)
.byte >(1077 / 8)
.byte >(1016 / 8)
.byte >(959 / 8)
.byte >(905 / 8)
.byte >(1710 / 16)
.byte >(1614 / 16)
.byte >(1523 / 16)
.byte >(1438 / 16)
.byte >(1357 / 16)
.byte >(1281 / 16)
.byte >(1209 / 16)
.byte >(1141 / 16)
.byte >(1077 / 16)
.byte >(1016 / 16)
.byte >(959 / 16)
.byte >(905 / 16)
.byte >(1710 / 32)
.byte >(1614 / 32)
.byte >(1523 / 32)
.byte >(1438 / 32)
.byte >(1357 / 32)
.byte >(1281 / 32)
.byte >(1209 / 32)
.byte >(1141 / 32)
.byte >(1077 / 32)
.byte >(1016 / 32)
.byte >(959 / 32)
.byte >(905 / 32)
.byte >(1710 / 64)
.byte >(1614 / 64)
.byte >(1523 / 64)
.byte >(1438 / 64)
.byte >(1357 / 64)
.byte >(1281 / 64)
.byte >(1209 / 64)
.byte >(1141 / 64)
.byte >(1077 / 64)
.byte >(1016 / 64)
.byte >(959 / 64)
.byte >(905 / 64)
.byte >(1710 / 128)
.byte >(1614 / 128)
.byte >(1523 / 128)
.byte >(1438 / 128)
.byte >(1357 / 128)
.byte >(1281 / 128)
.byte >(1209 / 128)
.byte >(1141 / 128)
.byte >(1077 / 128)
.byte >(1016 / 128)
.byte >(959 / 128)
.byte >(905 / 128)
end_of_music_code:
song_pointer_table:
.word 34774
.segment "PRG13B"
instruments:
instruments_alias:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/DATA3"
MUSIC_DATA_SIZE = * - 32769
MUSIC_PDS_BREAKPOINT_ADDRESS .set 65517