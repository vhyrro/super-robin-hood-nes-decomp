BUTTON_A_MASK = 128
BUTTON_B_MASK = 64
BUTTON_SELECT_MASK = 32
BUTTON_START_MASK = 16
BUTTON_UP_MASK = 8
BUTTON_DOWN_MASK = 4
BUTTON_LEFT_MASK = 2
BUTTON_RIGHT_MASK = 1
readkeypads:
ldx #1
stx JOYPAD_1_REGISTER
dex
stx JOYPAD_1_REGISTER
padloop1:
lda JOYPAD_STATE
sta JOYPAD_DEBOUNCE
ldy #8
padloop2:
lda JOYPAD_1_REGISTER
lsr A
rol JOYPAD_STATE
dey
bne padloop2
rts
random:
lda FRAME_COUNTER
ror A
eor RANDOM_SEED + 1
eor RANDOM_SEED
rol A
ror RANDOM_SEED + 2
sta RANDOM_SEED + 1
eor #255
rol A
eor RANDOM_SEED
sta RANDOM_SEED
rts
teststartkey:
lda #BUTTON_START_MASK
bne generalkeytest
testselectkey:
lda #BUTTON_SELECT_MASK
bne generalkeytest
testanykey:
lda #255
generalkeytest:
sta TEMP_BYTE
lda JOYPAD_STATE
and TEMP_BYTE
beq @generalkeytest_skip_if_equal
lda JOYPAD_DEBOUNCE
and TEMP_BYTE_1
beq @generalkeytest_skip_if_equal_2
lda #0
@generalkeytest_skip_if_equal:
rts
@generalkeytest_skip_if_equal_2:
lda #1
rts
checkforpausekey:
lda PAUSE_DISABLED
bne @checkforpausekey_skip_if_not_equal
@checkforpausekey_body:
lda JOYPAD_STATE
and #BUTTON_START_MASK
beq @checkforpausekey_skip_if_equal_2
lda JOYPAD_DEBOUNCE
and #BUTTON_START_MASK
bne @checkforpausekey_skip_if_equal_2
lda GAME_PAUSED
@checkforpausekey_skip_if_not_equal:
eor #1
sta GAME_PAUSED
beq @checkforpausekey_skip_if_equal
lda #0
sta APU_STATUS_REGISTER
rts
@checkforpausekey_skip_if_equal:
lda #15
sta APU_STATUS_REGISTER
@checkforpausekey_skip_if_equal_2:
rts
clearfullspriteblock:
ldx #0
jsr clearspriteblock1
sendspriteblock:
lda #0
sta OAM_ADDRESS_REGISTER
lda #>(SPRITE_BLOCK_ADDRESS)
sta OAM_DMA_REGISTER
rts
turnofftune:
lda #0
starttune:
tay
lda CURRENT_BANK
pha
jsr change_bank1_routine
lda #0
sta APU_STATUS_REGISTER
tya
jsr start_music
pla
jmp change_bank_routine
soundfx:
sta SFX_FREQUENCY_ADDRESS_1_LOW
txa
pha
tya
pha
lda CURRENT_BANK
pha
jsr change_bank1_routine
lda SFX_FREQUENCY_ADDRESS_1_LOW
jsr fx_setup
pla
jsr change_bank_routine
pla
tay
pla
tax
rts
change_bank_routine:
sta CURRENT_BANK
change_bank_routine_1:
tax
sta bank_table,X
rts
clearscr:
.byte $A0
.byte $00
.byte $FB
.byte $40
.byte $FB
.byte $20
.byte $00
.byte $FA
.byte $FA
.byte $FF
clearspriteblock:
ldx #4
clearspriteblock1:
stx SPRITE_BLOCK_POINTER
@clearspriteblock1_loop:
lda #254
sta SPRITE_BLOCK_ADDRESS,X
lda #0
sta SPRITE_BLOCK_ADDRESS + 3,X
sta SPRITE_BLOCK_ADDRESS + 2,X
sta SPRITE_BLOCK_ADDRESS + 1,X
inx
inx
inx
inx
bne @clearspriteblock1_loop
rts
turninteron1:
asl VBLANK_FLAG
@turninteron1_wait_vblank:
bit VBLANK_FLAG
bpl @turninteron1_wait_vblank
jsr sendspriteblock
turninteron:
lda #255
sta JOYPAD_DEBOUNCE
ldx SCROLL_X
ldy SCROLL_Y
stx PPU_SCROLL_REGISTER
sty PPU_SCROLL_REGISTER
lda PPU_CONTROL_SHADOW
ldy PPU_MASK_SHADOW
sta PPU_CONTROL_REGISTER
sty PPU_MASK_REGISTER
lda #255
sta INTERRUPT_ENABLED
rts
turninterofffade:
lda #0
sta FRAME_FINISHED
lda #252
sta FADE_COUNTER
fadeoffscreen:
asl VBLANK_FLAG
@fadeoffscreen_wait_vblank:
bit VBLANK_FLAG
bpl @fadeoffscreen_wait_vblank
lda FADE_COUNTER
cmp #255
bne fadeoffscreen
jmp turninteroff1
turninteroff:
asl VBLANK_FLAG
@turninteroff_wait_vblank:
bit VBLANK_FLAG
bpl @turninteroff_wait_vblank
turninteroff1:
lda #0
sta FRAME_FINISHED
sta INTERRUPT_ENABLED
sta PPU_MASK_REGISTER
sta SCROLL_X
sta SCROLL_Y
sta PPU_SCROLL_REGISTER
sta PPU_SCROLL_REGISTER
sta VRAM_WRITE_POINTER
sta GAME_PAUSED
lda #30
sta PPU_MASK_SHADOW
lda #144
sta PPU_CONTROL_SHADOW
sta PPU_CONTROL_REGISTER
jmp clearfullspriteblock
addtolives:
inc PLAYER_LIVES
rts
high_bit_add_table:
.byte $FF
.byte $00
.byte $00
printlives:
lda PLAYER_LIVES
beq @printlives_skip_if_equal
bmi @printlives_skip_if_equal
cmp #3
bcc @printlives_skip_if_no_carry
lda #3
@printlives_skip_if_no_carry:
sta TEMP_BYTE_9
lda #0 + 64
sta TEMP_BYTE
lda #32 - SPRITE_Y_DISPLACE
sta TEMP_POINTER_5
@printlives_loop:
ldy TEMP_POINTER_5
ldx #240
lda #1
jsr pokesprite2by2
lda TEMP_POINTER_5
clc
adc #24
sta TEMP_POINTER_5
dec TEMP_BYTE_9
bne @printlives_loop
@printlives_skip_if_equal:
rts
printscore:
lda #128 - 10 * 3 - 4
ldy #0
@printscore_loop:
ldx PLAYER_SCORE,Y
bne @printscore_skip_if_not_equal
clc
adc #5
iny
cpy #3
bne @printscore_loop
@printscore_skip_if_not_equal:
sta TEMP_BYTE
@printscore_loop_2:
lda PLAYER_SCORE,Y
clc
adc #128
ldx SPRITE_BLOCK_POINTER
beq @printscore_skip_if_equal
sta SPRITE_BLOCK_ADDRESS + 1,X
lda TEMP_BYTE_1
lda #2
sta SPRITE_BLOCK_ADDRESS + 2,X
lda TEMP_BYTE
sta SPRITE_BLOCK_ADDRESS + 3,X
clc
adc #10
sta TEMP_BYTE
lda #16
sta SPRITE_BLOCK_ADDRESS + 0,X
txa
clc
adc #4
sta SPRITE_BLOCK_POINTER
iny
cpy #6
bne @printscore_loop_2
@printscore_skip_if_equal:
rts
addtoscore:
sty TEMP_Y
pha
lsr
lsr
lsr
lsr
tay
pla
and #15
add_to_score_loop:
clc
adc PLAYER_SCORE,Y
sta PLAYER_SCORE,Y
cmp #10
bcc endupdatescore
sec
sbc #10
sta PLAYER_SCORE,Y
lda #1
dey
bpl add_to_score_loop
endupdatescore:
ldy TEMP_Y
rts
resetscore:
ldy #6
@resetscore_loop:
lda #0
sta PLAYER_SCORE,Y
lda #8
sta TREASURE_FLAGS,Y
dey
bpl @resetscore_loop
rts
addtohearts:
lda PLAYER_HEARTS
clc
adc #1
sta PLAYER_HEARTS
cmp #5
bcc @addtohearts_skip_if_no_carry
inc PLAYER_LIVES
clc
adc #($FD)
sta PLAYER_HEARTS
lda #SFX_EXTRA_LIFE
jsr soundfx
@addtohearts_skip_if_no_carry:
rts
subfromhearts:
ldy PLAYER_INVINCIBILITY_TIMER
beq @subfromhearts_skip_if_equal
rts
@subfromhearts_skip_if_equal:
subfromhearts1:
eor #255
clc
adc #1
clc
adc PLAYER_HEARTS
sta PLAYER_HEARTS
ldy #150
sty PLAYER_INVINCIBILITY_TIMER
cmp #0
beq killyou1
bpl littlekill
killyoutotally:
lda #0
sta PLAYER_HEARTS
killyou1:
lda #100
sta PLAYER_KILLED
lda #1
sta TEMP_BYTE_2
lda #0
sta HEART_TABLE + 0
sta HEART_TABLE + 16
sta HEART_TABLE + 32
ldx #32
jsr gotstarsx
lda #SFX_KILL_YOU_TOTALLY
jmp soundfx
littlekill:
lda #0
jsr startstars
lda #SFX_KILL_YOU
jmp soundfx
printhearts:
lda #24
sta TEMP_BYTE
ldy PLAYER_HEARTS
bmi @printhearts_skip_if_negative
beq @printhearts_skip_if_negative
lda HEART_COUNTER
bit GAME_PAUSED
bne @printhearts_skip_if_not_equal
clc
adc heartbeat - 1,Y
sta HEART_COUNTER
@printhearts_skip_if_not_equal:
lda HEART_COUNTER
lsr
lsr
lsr
lsr
lsr
lsr
tax
lda heartsdefs,X
sta TEMP_BYTE_1
@printhearts_loop:
ldx SPRITE_BLOCK_POINTER
beq @printhearts_skip_if_negative
lda TEMP_BYTE_1
sta SPRITE_BLOCK_ADDRESS + 1,X
lda #3
sta SPRITE_BLOCK_ADDRESS + 2,X
sta SPRITE_BLOCK_ADDRESS + 2 + 4,X
lda #16
sta SPRITE_BLOCK_ADDRESS + 3,X
lda TEMP_BYTE
sta SPRITE_BLOCK_ADDRESS + 0,X
clc
adc #24
sta TEMP_BYTE
txa
clc
adc #4
sta SPRITE_BLOCK_POINTER
dey
bne @printhearts_loop
@printhearts_skip_if_negative:
rts
heartsdefs:
.byte $8A
.byte $8B
.byte $8C
.byte $8B
heartbeat:
.byte $12
.byte $0E
.byte $0A
.byte $08
.byte $06
.byte $04
.byte $02
treaspal:
.byte $01
.byte $01
.byte $02
.byte $01
.byte $01
.byte $03
waitforstartkey:
lda FADE_COUNTER
cmp #255
beq @waitforstartkey_skip_if_equal
cmp #0
bne @waitforstartkey_skip_if_not_equal
lda JOYPAD_STATE
and #BUTTON_START_MASK
beq @waitforstartkey_skip_if_equal_2
lda JOYPAD_DEBOUNCE
and #BUTTON_START_MASK
bne @waitforstartkey_skip_if_not_equal
lda SOLID_TILE_FOUND
clc
adc #128
sta SOLID_TILE_FOUND
@waitforstartkey_body:
lda #251
sta FADE_COUNTER
bne @waitforstartkey_skip_if_not_equal
@waitforstartkey_skip_if_equal:
jsr turninteroff1
lda #1
rts
@waitforstartkey_skip_if_not_equal:
lda #0
@waitforstartkey_skip_if_equal_2:
rts
