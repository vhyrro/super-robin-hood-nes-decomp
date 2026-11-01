flashrobin:
.byte $04
.byte $02
.byte $02
.byte $02
.byte $02
.byte $02
printrobin:
lda PLAYER_KILLED
beq @printrobin_skip_if_equal
rts
@printrobin_skip_if_equal:
jsr checkrobinbehind
lda #0
sta SPRITE_COLOUR
lda PLAYER_INVINCIBILITY_TIMER
beq printrobin1
dec PLAYER_INVINCIBILITY_TIMER
lda PLAYER_INVINCIBILITY_TIMER
cmp #150
bcc @printrobin_skip_if_no_carry
rts
@printrobin_skip_if_no_carry:
lsr
lsr
lsr
lsr
lsr
tax
lda flashrobin,X
and FRAME_COUNTER
bne printrobin1
lda #2
sta SPRITE_COLOUR
printrobin1:
lda OLD_PLAYER_FACING
pha
lda PLAYER_ON_LADDER
beq @printrobin1_skip_if_equal
jmp printrobinonladder
@printrobin1_skip_if_equal:
lda PLAYER_X_LOW
sec
sbc SCREEN_X_LOW
tax
sta PLAYER_ONSCREEN_X
sta TEMP_POINTER_5
ldy PLAYER_Y
sty TEMP_BYTE_9
lda PLAYER_ANIMATION
clc
adc #SPRITE_LEGS_RUNNING
cmp #SPRITE_LEGS_RUNNING - 1
bne normalrun
lda #SPRITE_MORE_LEGS
normalrun:
sta TEMP_POINTER_5 + 1
sta TEMP_POINTER_7 + 1
stx TEMP_POINTER_8
sty TEMP_POINTER_8 + 1
ldx #SPRITE_MORE_LEGS + 3
lda PLAYER_CROUCHING
beq workoutbody
cmp #($FC)
beq @normalrun_skip_if_equal
cmp #($FD)
beq @normalrun_skip_if_equal
cmp #($FB)
beq @normalrun_skip_if_equal
dex
dex
@normalrun_skip_if_equal:
stx TEMP_POINTER_5 + 1
stx TEMP_POINTER_7 + 1
cpx #SPRITE_MORE_LEGS + 1
beq workoutbody
jsr subtract_height_of_sprite
lda TEMP_POINTER_5
tax
clc
adc #4
bit OLD_PLAYER_FACING
bpl @normalrun_skip_if_positive
sec
sbc #8
@normalrun_skip_if_positive:
sta TEMP_POINTER_5
lda #SPRITE_MORE_LEGS + 2
sta TEMP_POINTER_5 + 1
asl OLD_PLAYER_FACING
jsr printspriteposrev
jmp workouthead
workoutbody:
jsr subtract_height_of_sprite
lda PLAYER_FIRING
beq @workoutbody_skip_if_equal
jmp printrobinshooting
@workoutbody_skip_if_equal:
ldx TEMP_POINTER_5
lda PLAYER_ANIMATION
bmi @workoutbody_skip_if_negative
and #7
@workoutbody_skip_if_negative:
clc
adc #SPRITE_ROBIN_BODIES
cmp #SPRITE_ROBIN_BODIES - 1
bne @workoutbody_skip_if_not_equal
lda #SPRITE_ROBIN_BODIES + 8
@workoutbody_skip_if_not_equal:
sta TEMP_POINTER_5 + 1
asl OLD_PLAYER_FACING
jsr printspriteposrev
workouthead:
jsr workoutheadrou
nowprintlegs:
lda TEMP_POINTER_7 + 1
ldx TEMP_POINTER_8
ldy TEMP_POINTER_8 + 1
asl OLD_PLAYER_FACING
jsr printspriteposrev
pla
sta OLD_PLAYER_FACING
lda #0
sta SPRITE_BEHIND
rts
robin_point_table:
.byte $FF
.byte $00
.byte $00
robin_look_table:
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $02
.byte $03
spriteheights:
.byte $F1
.byte $F1
.byte $F1
.byte $F1
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F9
.byte $F1
.byte $F2
.byte $F1
.byte $F1
.byte $F1
.byte $F2
.byte $F1
.byte $F1
.byte $F1
.byte $F6
.byte $FF
.byte $F8
.byte $F5
.byte $F6
.byte $F3
workoutheadrou:
jsr subtract_height_of_sprite
clc
adc #($F2)
sta PLAYER_HEIGHT
lda #SPRITE_ROBIN_HEADS
@workoutheadrou_body:
lda PLAYER_ON_LADDER
bne @workoutheadrou_skip_if_not_equal
lda FRAME_COUNTER
clc
adc #1
and #31
bne @workoutheadrou_skip_if_not_equal
lda RANDOM_SEED
and #3
clc
adc PLAYER_LOOK_DIRECTION
and #7
sta PLAYER_LOOK_DIRECTION
@workoutheadrou_skip_if_not_equal:
ldx PLAYER_LOOK_DIRECTION
lda robin_look_table,X
clc
adc #SPRITE_ROBIN_HEADS
ldx TEMP_POINTER_5
sta TEMP_POINTER_5 + 1
asl OLD_PLAYER_FACING
jmp printspriteposrev
printrobinonladder:
ldy #8
ldx #0
lda PLAYER_Y
and #8
beq @printrobinonladder_skip_if_equal
ldx #96
@printrobinonladder_skip_if_equal:
lda JOYPAD_STATE
and #BUTTON_RIGHT_MASK
beq @printrobinonladder_skip_if_equal_2
ldy #4
@printrobinonladder_skip_if_equal_2:
lda JOYPAD_STATE
and #BUTTON_LEFT_MASK
beq @printrobinonladder_skip_if_equal_3
ldy #4
txa
clc
adc #128
tax
@printrobinonladder_skip_if_equal_3:
stx OLD_PLAYER_FACING
sty PLAYER_LOOK_DIRECTION
lda PLAYER_X_LOW
sec
sbc SCREEN_X_LOW
tax
sta TEMP_POINTER_5
ldy PLAYER_Y
sty TEMP_BYTE_9
lda #SPRITE_MORE_LEGS + 6
sta TEMP_POINTER_5 + 1
sta TEMP_POINTER_7 + 1
stx TEMP_POINTER_8
sty TEMP_POINTER_8 + 1
jsr subtract_height_of_sprite
ldx TEMP_POINTER_5
stx TEMP_POINTER_6
sty TEMP_POINTER_6 + 1
lda #SPRITE_MORE_LEGS + 5
sta TEMP_POINTER_5 + 1
sta TEMP_POINTER_7
jsr workoutheadrou
ldx TEMP_POINTER_6
ldy TEMP_POINTER_6 + 1
lda TEMP_POINTER_7
asl OLD_PLAYER_FACING
jsr printspriteposrev
jmp nowprintlegs
printrobinshooting:
lsr
lsr
tax
lda shooting_frames,X
ldx TEMP_POINTER_5
@printrobinshooting_body:
sta TEMP_POINTER_5 + 1
asl OLD_PLAYER_FACING
jsr printspriteposrev
lda #0
sta PLAYER_LOOK_DIRECTION
jmp workouthead
shooting_frames:
.byte <(SPRITE_BODY_FIRING + 1)
.byte <(SPRITE_BODY_FIRING + 2)
.byte <(SPRITE_BODY_FIRING + 3)
.byte <(SPRITE_BODY_FIRING + 4)
.byte <(SPRITE_BODY_FIRING + 3)
.byte <(SPRITE_BODY_FIRING + 3)
.byte <(SPRITE_BODY_FIRING + 2)
.byte <(SPRITE_BODY_FIRING + 2)
.byte <(SPRITE_BODY_FIRING + 1)
.byte <(SPRITE_BODY_FIRING + 1)
subtract_height_of_sprite:
ldx TEMP_POINTER_5 + 1
lda TEMP_BYTE_9
clc
adc spriteheights,X
sta TEMP_BYTE_9
tay
rts