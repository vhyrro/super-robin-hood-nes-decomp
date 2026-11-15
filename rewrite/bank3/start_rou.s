start:
sei
cld
ldx #255
txs
lda HIGH_SCORES_VALID
pha
lda #2
sta CURRENT_BANK
sta bank_table + 2
jsr cm_logo
jsr change_bank0_routine
pla
tax
ldy #0
sty PPU_CONTROL_REGISTER
sty PPU_MASK_REGISTER
sty TEMP_POINTER
sty TEMP_POINTER + 1
clear_ram:
@clear_ram_loop:
lda #0
@clear_ram_loop_2:
sta (TEMP_POINTER),Y
iny
bne @clear_ram_loop_2
@clear_ram_loop_3:
inc TEMP_POINTER + 1
lda TEMP_POINTER + 1
cmp #1
beq @clear_ram_loop_3
cmp #7
bne @clear_ram_loop
jsr change_bank1_routine
jsr copy_high_scores_to_ram
jsr change_bank0_routine
lda #144
sta PPU_CONTROL_SHADOW
sta PPU_CONTROL_REGISTER
sta RANDOM_SEED
lda #30
sta PPU_MASK_SHADOW
sta RANDOM_SEED + 1
jsr turninteroff1
jsr change_bank0_routine
lda #10
jsr starttune
