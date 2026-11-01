CIC_LOCK_DELAY_LOW        = $0070
CIC_LOCK_DELAY_HIGH       = $0071
CIC_LOCK_ITERATION_COUNTER = $0072
CIC_LOCK_WRITE_COUNTER    = $07F0
CIC_LOCK_ADDRESS_1        = $FFF0
CIC_LOCK_ADDRESS_2        = $FFF1
CIC_LOCK_BIT_ADDRESS      = $00FF
CIC_LOCK_BASE_DELAY       = 1631
CIC_LOCK_WRITE_COUNT      = 4

start:
sei
cld
ldx #255
txs
LOCK_CHIP_ITERATIONS = 10
LOCK_CHIP_DELAY_STEP = 128
lda #LOCK_CHIP_ITERATIONS
sta CIC_LOCK_ITERATION_COUNTER
lda #<(CIC_LOCK_BASE_DELAY + LOCK_CHIP_ITERATIONS / 2 * LOCK_CHIP_DELAY_STEP)
sta CIC_LOCK_DELAY_LOW
lda #>(CIC_LOCK_BASE_DELAY + LOCK_CHIP_ITERATIONS / 2 * LOCK_CHIP_DELAY_STEP)
sta CIC_LOCK_DELAY_HIGH
lock_chip_retry:
lda #CIC_LOCK_WRITE_COUNT
sta CIC_LOCK_WRITE_COUNTER
lock_chip_write_loop:
sta CIC_LOCK_ADDRESS_1
jsr lock_chip_delay
sta CIC_LOCK_ADDRESS_2
jsr lock_chip_delay
dec CIC_LOCK_WRITE_COUNTER
bne lock_chip_write_loop
lda CIC_LOCK_DELAY_LOW
sec
sbc #LOCK_CHIP_DELAY_STEP
sta CIC_LOCK_DELAY_LOW
bcs @lock_chip_write_loop_skip_if_carry
dec CIC_LOCK_DELAY_HIGH
@lock_chip_write_loop_skip_if_carry:
dec CIC_LOCK_ITERATION_COUNTER
bne lock_chip_retry
sta CIC_LOCK_ADDRESS_1
jmp lock_chip_done
lock_chip_delay:
ldx CIC_LOCK_DELAY_LOW
ldy CIC_LOCK_DELAY_HIGH
bit CIC_LOCK_BIT_ADDRESS
lock_chip_delay_loop:
dex
bne lock_chip_delay_loop
dey
bne lock_chip_delay_loop
rts
lock_chip_done:
boot_delay_nops:
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
lda #14
sta CURRENT_BANK
sta bank_table + 14
jsr smiley
jsr change_bank12_routine
boot_delay_done:
lda CODEMASTERS_POWERUP
pha
lda #14
sta CURRENT_BANK
sta bank_table + 14
jsr cm_logo
jsr change_bank12_routine
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
jsr change_bank13_routine
jsr copy_high_scores_to_ram
jsr change_bank12_routine
lda #144
sta PPU_CONTROL_SHADOW
sta PPU_CONTROL_REGISTER
sta RANDOM_SEED
lda #30
sta PPU_MASK_SHADOW
sta RANDOM_SEED + 1
jsr turninteroff1
jsr change_bank12_routine
lda #10
jsr starttune
