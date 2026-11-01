cm_nmi:
bit CODEMASTERS_FLAGS
bmi interrupt
inc CODEMASTERS_FRAME_COUNTER
bit 8194
rti
interrupt:
pha
txa
pha
tya
pha
lda INTERRUPT_ENABLED
beq dont_do_interrupt
lda FRAME_FINISHED
bne @interrupt_skip_if_not_equal
jsr fadeupcolours
jsr emptyprintbuffer
@interrupt_skip_if_not_equal:
jsr empty_block_buffer
lda SCROLL_X
sta PPU_SCROLL_REGISTER
lda SCROLL_Y
sta PPU_SCROLL_REGISTER
lda PPU_CONTROL_SHADOW
sta PPU_CONTROL_REGISTER
lda PPU_MASK_SHADOW
sta PPU_MASK_REGISTER
lda FRAME_FINISHED
bne @interrupt_skip_if_not_equal_2
jsr sendspriteblock
@interrupt_skip_if_not_equal_2:
jsr do_inter_pause
jsr readkeypads
lda #13
sta bank_table + 13
jsr fx_play
lda CURRENT_BANK
jsr change_bank_routine_1
dont_do_interrupt:
lda GAME_PAUSED
bne @dont_do_interrupt_skip_if_not_equal
lda #13
sta bank_table + 13
jsr play_music
lda CURRENT_BANK
jsr change_bank_routine_1
@dont_do_interrupt_skip_if_not_equal:
pla
tay
pla
tax
lda #128
sta VBLANK_FLAG
pla
rti
do_inter_pause:
lda GAME_PAUSED
bne inpausemode
pausenoton:
lda FRAME_FINISHED
bne @pausenoton_skip_if_not_equal
inc FRAME_COUNTER
@pausenoton_body:
jsr clearspriteblock
jsr random
@pausenoton_skip_if_not_equal:
inpausemode:
rts
setfade:
stx TEMP_POINTER
sty TEMP_POINTER + 1
lda #3
sta FADE_COUNTER
ldy #0
@setfade_loop:
lda (TEMP_POINTER),Y
sta FADE_COLOURS,Y
iny
cpy #32
bne @setfade_loop
ldy #0
jmp allblack
fadeupcolours:
lda FADE_COUNTER
beq endfade
ldx #63
stx PPU_ADDRESS_REGISTER
ldy #0
sty PPU_ADDRESS_REGISTER
cmp #0
bmi backtoblack
tax
lda fademasks,X
sta FADE_TEMP
lda FADE_COUNTER
beq dofadelp
dec FADE_COUNTER
dofadelp:
lda FADE_COLOURS,Y
and FADE_TEMP
sta PPU_DATA_REGISTER
iny
cpy #32
bne dofadelp
endfade:
rts
backtoblack:
inc FADE_COUNTER
lda FADE_COUNTER
cmp #255
beq allblack1
eor #255
clc
adc #1
tax
lda fade1masks,X
sta FADE_TEMP
jmp dofadelp
allblack:
asl VBLANK_FLAG
@allblack_wait_vblank:
bit VBLANK_FLAG
bpl @allblack_wait_vblank
ldx #63
stx PPU_ADDRESS_REGISTER
ldy #0
sty PPU_ADDRESS_REGISTER
allblack1:
lda #14
allblacklp:
sta PPU_DATA_REGISTER
iny
cpy #32
bne allblacklp
rts
fademasks:
.byte $FF
.byte $3F
.byte $1F
.byte $0F
fade1masks:
.byte $00
.byte $0F
.byte $1F
.byte $3F