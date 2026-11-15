robinhearts:
lda PLAYER_Y
clc
adc #($EE)
sta HEART_TABLE + 2,X
lda PLAYER_X_LOW
sec
sbc #4
sta HEART_TABLE + 0,X
lda PLAYER_X_HIGH
sbc #0
sta HEART_TABLE + 1,X
rts
updatehearts:
ldx #0
morehearts:
stx HEIGHT_TEMP_X_REGISTER
lda HEART_TABLE,X
ora HEART_TABLE + 1,X
beq endhearts
updateheartslp:
lda HEART_TABLE + 5,X
bpl @updateheartslp_skip_if_positive
jsr robinhearts
@updateheartslp_skip_if_positive:
lda HEART_TABLE,X
sec
sbc SCREEN_X_LOW
sta HEART_X_LOW
lda HEART_TABLE + 1,X
sbc SCREEN_X_HIGH
sta HEART_X_HIGH
lda HEART_TABLE + 2,X
sta HEART_Y
lda HEART_TABLE + 3,X
sta HEIGHT_TEMP_CHARACTER
lda HEART_TABLE + 4,X
lsr
lsr
lsr
lsr
sta HEIGHT_TEMP_COLOUR
lda HEART_TABLE + 4,X
and #15
sta HEART_PIECE_COUNT
lda HEART_TABLE + 5,X
and #31
sta HEIGHT_TEMP_ROUTINE
doeachheart:
ldy HEIGHT_TEMP_ROUTINE
lda exploderoubitsl,Y
sta TEMP_POINTER
lda exploderoubitsh,Y
sta TEMP_POINTER + 1
jmp (TEMP_POINTER)
backfromheartrou:
@backfromheartrou_body:
jsr printcircleofhearts
backfromheartrou1:
inx
inx
dec HEART_PIECE_COUNT
bne doeachheart
endhearts:
lda HEIGHT_TEMP_X_REGISTER
clc
adc #16
tax
cmp #48
bne morehearts
rts
spinandinc:
dec HEART_TABLE + 7,X
just_increment:
jsr inchearts4
finhearts1:
bne backfromheartrou
finhearts:
ldy HEIGHT_TEMP_X_REGISTER
lda #0
sta HEART_TABLE,Y
sta HEART_TABLE + 1,Y
jmp backfromheartrou1
largeexpforguard:
jsr inchearts4
bpl backfromheartrou
bmi finhearts
smallexpforguard:
jsr inchearts3
lda HEART_TABLE + 6,X
cmp #64
bcc backfromheartrou
bcs finhearts
explodehearts:
ldy HEART_PIECE_COUNT
lda expsizetable,Y
clc
adc HEART_TABLE + 6,X
sta HEART_TABLE + 6,X
bcc backfromheartrou
bcs finhearts
expsizetable:
.byte $01
.byte $02
.byte $03
.byte $04
.byte $05
.byte $06
spininstars:
dec HEART_TABLE + 7,X
lda HEART_TABLE + 6,X
clc
adc #($FA)
sta HEART_TABLE + 6,X
jmp finhearts1
explodeheartsl:
dec HEART_TABLE + 7,X
ldy HEART_PIECE_COUNT
lda PLAYER_INVINCIBILITY_TIMER
cmp #170 - 50
bcc @explodeheartsl_skip_if_no_carry
lda expsizetable,Y
clc
adc HEART_TABLE + 6,X
sta HEART_TABLE + 6,X
jmp backfromheartrou
@explodeheartsl_skip_if_no_carry:
lda HEART_TABLE + 6,X
sec
sbc expsizetable,Y
sta HEART_TABLE + 6,X
bmi finhearts
jmp backfromheartrou
inchearts4:
inc HEART_TABLE + 6,X
inchearts3:
inc HEART_TABLE + 6,X
inchearts2:
inc HEART_TABLE + 6,X
inchearts1:
inc HEART_TABLE + 6,X
rts
getvalue:
and #63
tay
lda sincostable,Y
bit HEIGHT_TEMP_ANGLE
bvc sine_times_size
jsr sine_times_size
eor #255
clc
adc #1
dey
rts
sine_times_size:
sta TEMP_BYTE
lda HEIGHT_TEMP_SIZE
sta TEMP_POINTER
ldy #8
lda #0
sta TEMP_POINTER + 1
sta TEMP_POINTER_1
sta TEMP_POINTER_1 + 1
multiply_loop:
lsr TEMP_BYTE
bcc multiply_no_add
lda TEMP_POINTER_1
clc
adc TEMP_POINTER
sta TEMP_POINTER_1
lda TEMP_POINTER_1 + 1
adc TEMP_POINTER + 1
sta TEMP_POINTER_1 + 1
multiply_no_add:
asl TEMP_POINTER
rol TEMP_POINTER + 1
dey
bne multiply_loop
lda TEMP_POINTER_1 + 1
rts
putspinheart:
lda HEIGHT_TEMP_PRINT_Y
sta SPRITE_BLOCK_ADDRESS + 0,Y
lda HEIGHT_TEMP_CHARACTER
sta SPRITE_BLOCK_ADDRESS + 1,Y
lda HEIGHT_TEMP_COLOUR
sta SPRITE_BLOCK_ADDRESS + 2,Y
iny
iny
iny
iny
rts
printcircleofhearts:
lda HEART_TABLE + 6,X
sta HEIGHT_TEMP_SIZE
lda HEART_TABLE + 7,X
and #127
sta HEIGHT_TEMP_ANGLE
jsr getvalue
sty X_MINUS
asl
sta HEIGHT_TEMP_X
lda HEIGHT_TEMP_ANGLE
clc
adc #32
and #127
sta HEIGHT_TEMP_ANGLE
jsr getvalue
sty Y_MINUS
asl
sta HEIGHT_TEMP_Y
ldy SPRITE_BLOCK_POINTER
bne @printcircleofhearts_skip_if_not_equal
rts
@printcircleofhearts_skip_if_not_equal:
lda HEART_X_LOW
clc
adc HEIGHT_TEMP_X
sta SPRITE_BLOCK_ADDRESS + 3,Y
lda HEART_X_HIGH
adc X_MINUS
bne @printcircleofhearts_skip_if_not_equal_2
lda HEART_Y
clc
adc HEIGHT_TEMP_Y
sta HEIGHT_TEMP_PRINT_Y
lda #0
adc Y_MINUS
bne @printcircleofhearts_skip_if_not_equal_2
jsr putspinheart
beq nomorehearts
@printcircleofhearts_skip_if_not_equal_2:
lda HEART_X_LOW
clc
adc HEIGHT_TEMP_Y
sta SPRITE_BLOCK_ADDRESS + 3,Y
lda HEART_X_HIGH
adc Y_MINUS
bne @printcircleofhearts_skip_if_not_equal_3
lda HEART_Y
sec
sbc HEIGHT_TEMP_X
sta HEIGHT_TEMP_PRINT_Y
lda #0
sbc X_MINUS
bne @printcircleofhearts_skip_if_not_equal_3
jsr putspinheart
beq nomorehearts
@printcircleofhearts_skip_if_not_equal_3:
lda HEART_X_LOW
sec
sbc HEIGHT_TEMP_Y
sta SPRITE_BLOCK_ADDRESS + 3,Y
lda HEART_X_HIGH
sbc Y_MINUS
bne @printcircleofhearts_skip_if_not_equal_4
lda HEART_Y
clc
adc HEIGHT_TEMP_X
sta HEIGHT_TEMP_PRINT_Y
lda #0
adc X_MINUS
bne @printcircleofhearts_skip_if_not_equal_4
jsr putspinheart
beq nomorehearts
@printcircleofhearts_skip_if_not_equal_4:
lda HEART_X_LOW
sec
sbc HEIGHT_TEMP_X
sta SPRITE_BLOCK_ADDRESS + 3,Y
lda HEART_X_HIGH
sbc X_MINUS
bne @printcircleofhearts_skip_if_not_equal_5
lda HEART_Y
sec
sbc HEIGHT_TEMP_Y
sta HEIGHT_TEMP_PRINT_Y
lda #0
sbc Y_MINUS
bne @printcircleofhearts_skip_if_not_equal_5
jsr putspinheart
@printcircleofhearts_skip_if_not_equal_5:
nomorehearts:
sty SPRITE_BLOCK_POINTER
rts
sincostable:
.byte $00
.byte $03
.byte $06
.byte $09
.byte $0C
.byte $0F
.byte $12
.byte $15
.byte $18
.byte $1B
.byte $1E
.byte $21
.byte $24
.byte $26
.byte $29
.byte $2B
.byte $2D
.byte $2F
.byte $31
.byte $33
.byte $35
.byte $37
.byte $38
.byte $3A
.byte $3B
.byte $3C
.byte $3D
.byte $3E
.byte $3E
.byte $3F
.byte $3F
.byte $40
.byte $40
.byte $40
.byte $3F
.byte $3F
.byte $3E
.byte $3E
.byte $3D
.byte $3C
.byte $3B
.byte $3A
.byte $38
.byte $37
.byte $35
.byte $33
.byte $31
.byte $2F
.byte $2D
.byte $2B
.byte $29
.byte $26
.byte $24
.byte $21
.byte $1E
.byte $1B
.byte $18
.byte $15
.byte $12
.byte $0F
.byte $0C
.byte $09
.byte $06
.byte $03
.byte $00
exploderoubitsl:
.byte <(explodeheartsl)
.byte <(explodehearts)
.byte <(spinandinc)
.byte <(spininstars)
.byte <(just_increment)
.byte <(smallexpforguard)
.byte <(largeexpforguard)
exploderoubitsh:
.byte >(explodeheartsl)
.byte >(explodehearts)
.byte >(spinandinc)
.byte >(spininstars)
.byte >(just_increment)
.byte >(smallexpforguard)
.byte >(largeexpforguard)
