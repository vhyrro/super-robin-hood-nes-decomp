flashblock:
lda EXTRA_VARS,X
bne endflashblock
newflashblock:
lda (TEMP_POINTER_9),Y
sta SCRATCH_BYTE_1
sec
sbc MAP_STRIP
clc
adc #16
cmp #48
bcs endflashblock
iny
lda (TEMP_POINTER_9),Y
and #31
sta SCRATCH_BYTE_2
lda (TEMP_POINTER_9),Y
rol
iny
lda (TEMP_POINTER_9),Y
sta SCRATCH_BYTE_3
sty TEMP_Y
lda EXTRA_VARS + 1,X
adc #0
and #1
bne turnblockoff
jsr addachangedblock1
jmp endflashblock
turnblockoff:
jsr deleteachangedblock1
endflashblock:
ldy #4
jsr dectiming
lda #2
jmp backfromrou
standguard:
jsr checkifextraon
bne @standguard_skip_if_not_equal
jmp guardturnedoff
@standguard_skip_if_not_equal:
ldy #3
lda (TEMP_POINTER_9),Y
sec
sbc MAP_STRIP
clc
adc #8
cmp #34
bcc @standguard_skip_if_no_carry
jmp veryendstandguard
@standguard_skip_if_no_carry:
lda (TEMP_POINTER_9),Y
jsr multiply_strip_by_16
sta TEMP_POINTER_7
ldx EXTRA_VAR_POINTER
lda EXTRA_VARS,X
bne endstandguard
ldy #6
lda (TEMP_POINTER_9),Y
sta TEMP_BYTE
ldy #4
lda (TEMP_POINTER_9),Y
clc
adc #($EA)
bit TEMP_BYTE
bpl @standguard_skip_if_positive
clc
adc #($F9)
@standguard_skip_if_positive:
iny
jsr shootarrow
lda #SFX_THEM_FIRING
jsr soundfx
ldx EXTRA_VAR_POINTER
lda EXTRA_VARS + 2,X
clc
adc #64
sta EXTRA_VARS + 2,X
endstandguard:
printtheguard:
lda TEMP_POINTER_7
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_8
lda TEMP_POINTER_7 + 1
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
bne @printtheguard_loop
jsr pickupcollision1
bcs @printtheguard_loop
lda PLAYER_INVINCIBILITY_TIMER
bne @printtheguard_loop
lda #1
sta EXTRA_VARS + 2,X
lda #3
jsr subfromhearts
jmp @printtheguard_skip
@printtheguard_loop:
lda EXTRA_VARS + 2,X
and #15
tay
bne @printtheguard_skip_if_not_equal
ldy #6
lda (TEMP_POINTER_9),Y
and #15
sta EXTRA_VARS + 2,X
bne @printtheguard_loop
@printtheguard_skip_if_not_equal:
lda guardcolours,Y
sta SPRITE_COLOUR
lda ARROW_COUNTER
beq @printtheguard_skip_if_equal
jsr collidewitharrow
bcs @printtheguard_skip_if_equal
ldx #0
jsr takearrowoffrou
@printtheguard_skip:
ldx EXTRA_VAR_POINTER
dec EXTRA_VARS + 2,X
@printtheguard_body:
ldy #4
lda (TEMP_POINTER_9),Y
sta TEMP_POINTER_8 + 1
lda EXTRA_VARS + 2,X
and #15
bne @printtheguard_skip_if_not_equal_2
jsr turnoffextra
lda #5
jsr startstars
lda #SFX_KILL_THEM_TOTALLY
jsr soundfx
lda #69
jsr addtoscore
jmp @printtheguard_skip_if_equal
@printtheguard_skip_if_not_equal_2:
lda #4
jsr startstars
lda #66
jsr addtoscore
lda #SFX_KILL_THEM
jsr soundfx
@printtheguard_skip_if_equal:
ldx EXTRA_VAR_POINTER
lda EXTRA_VARS + 2,X
and #240
beq @printtheguard_skip_if_equal_2
lda EXTRA_VARS + 2,X
clc
adc #($F0)
sta EXTRA_VARS + 2,X
lda #2
@printtheguard_skip_if_equal_2:
sta TEMP_BYTE_2
ldy #4
lda (TEMP_POINTER_9),Y
sta TEMP_BYTE
iny
lda (TEMP_POINTER_9),Y
asl
php
iny
lda (TEMP_POINTER_9),Y
asl
lda #SPRITE_GUARD
adc #0
clc
adc TEMP_BYTE_2
plp
ldx TEMP_POINTER_8
ldy TEMP_BYTE
jsr winprintspriteposrev
veryendstandguard:
ldy #6
jsr dectiming
guardturnedoff:
lda #3
jmp backfromrou
guardcolours:
.byte $FF
.byte $03
.byte $01
.byte $00
.byte $02
.byte $02
.byte $02
.byte $02
.byte $02
collidewitharrow:
ldy #4
lda (TEMP_POINTER_9),Y
sec
sbc ARROW_Y
cmp #32
bcs notcollidewitharrow
collidebatwitharrow:
lda TEMP_POINTER_7
sec
sbc ARROW_X_LOW
sta TEMP_BYTE
lda TEMP_POINTER_7 + 1
sbc ARROW_X_HIGH
tax
lda TEMP_BYTE
clc
adc #12
bcc @collidebatwitharrow_skip_if_no_carry
inx
@collidebatwitharrow_skip_if_no_carry:
cpx #0
bne @collidebatwitharrow_skip_if_not_equal
cmp #24
@collidebatwitharrow_skip_if_not_equal:
notcollidewitharrow:
rts
platformh:
iny
lda (TEMP_POINTER_9),Y
sec
sbc SCREEN_X_LOW
iny
lda (TEMP_POINTER_9),Y
sbc SCREEN_X_HIGH
clc
adc #1
bmi endplatformh
iny
lda (TEMP_POINTER_9),Y
sec
sbc SCREEN_X_LOW
iny
lda (TEMP_POINTER_9),Y
sbc SCREEN_X_HIGH
cmp #3
bcs endplatformh
jsr moveplatformh
ldx EXTRA_VAR_POINTER
collideplatwithrobin:
lda SPRITE_X_COORD_HIGH
bne endplatformh
jsr collplatwithrob
bcs endplatformh
lda EXTRA_VARS + 3,X
beq @collideplatwithrobin_skip_if_equal
bmi @collideplatwithrobin_skip_if_negative
inc PLAYER_X_LOW
bne @collideplatwithrobin_skip_if_not_equal
inc PLAYER_X_LOW + 1
@collideplatwithrobin_skip_if_not_equal:
jmp @collideplatwithrobin_skip_if_equal
@collideplatwithrobin_skip_if_negative:
dec PLAYER_X_LOW
pha
lda #255
cmp PLAYER_X_LOW
bne @collideplatwithrobin_skip_if_not_equal_2
dec PLAYER_X_LOW + 1
@collideplatwithrobin_skip_if_not_equal_2:
pla
@collideplatwithrobin_skip_if_equal:
lda PREVIOUS_PLAYER_X_LOW
cmp PLAYER_X_LOW
beq platnotmoving
bcc platmovingright
jsr findwallleft
beq platnotmoving
jsr restorex
beq platnotmoving
platmovingright:
jsr findwallright
beq platnotmoving
jsr restorex
platnotmoving:
jsr robinjumpoffplatform
endplatformh:
lda #4
jmp backfromrou
collplatwithrob:
lda EXTRA_VARS + 2,X
sec
sbc PLAYER_Y
clc
adc #4
cmp #6
bcs @collplatwithrob_skip_if_carry
lda TEMP_POINTER_7
sec
sbc PLAYER_ONSCREEN_X
clc
adc #14
cmp #28
@collplatwithrob_skip_if_carry:
rts
checkifplaton:
lda EXTRA_VARS + 3,X
bne @checkifplaton_skip_if_not_equal
ldy #3
lda (TEMP_POINTER_9),Y
sta EXTRA_VARS + 0,X
iny
lda (TEMP_POINTER_9),Y
sta EXTRA_VARS + 1,X
ldy #7
lda (TEMP_POINTER_9),Y
sta EXTRA_VARS + 2,X
ldy #2
jsr checkifextraon
ldx EXTRA_VAR_POINTER
cmp #0
bne @checkifplaton_skip_if_not_equal_2
lda #1
sta EXTRA_VARS + 3,X
@checkifplaton_skip_if_not_equal:
rts
@checkifplaton_skip_if_not_equal_2:
lda #0
rts
moveplatformh:
jsr checkifplaton
beq printplatform
@moveplatformh_body:
bmi platform_h_negative
ldy #5
inc EXTRA_VARS + 0,X
bne @moveplatformh_skip_if_not_equal
inc EXTRA_VARS + 1,X
@moveplatformh_skip_if_not_equal:
jmp platform_h_moved
platform_h_negative:
ldy #3
dec EXTRA_VARS + 0,X
lda EXTRA_VARS + 0,X
cmp #255
bne platform_h_moved
dec EXTRA_VARS + 1,X
platform_h_moved:
lda EXTRA_VARS + 0,X
cmp (TEMP_POINTER_9),Y
bne printplatform
iny
lda EXTRA_VARS + 1,X
cmp (TEMP_POINTER_9),Y
bne printplatform
reverseplatdir:
lda EXTRA_VARS + 3,X
eor #255
sta EXTRA_VARS + 3,X
printplatform:
lda EXTRA_VARS + 0,X
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_7
lda EXTRA_VARS + 1,X
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
ldy EXTRA_VARS + 2,X
sty TEMP_POINTER_7 + 1
ldx TEMP_POINTER_7
lda #SPRITE_PLATFORM
jmp winprintsprite
platformv:
iny
lda (TEMP_POINTER_9),Y
sec
sbc SCREEN_X_LOW
iny
lda (TEMP_POINTER_9),Y
sbc SCREEN_X_HIGH
clc
adc #1
cmp #3
bcs endplatformv
jsr moveplatformv
ldx EXTRA_VAR_POINTER
collideplatwithrobinv:
lda SPRITE_X_COORD_HIGH
bne endplatformv
jsr collplatwithrob
bcs endplatformv
jsr robinjumpoffplatform
endplatformv:
lda #4
jmp backfromrou
moveplatformv:
lda FRAME_COUNTER
and #1
bne printplatform
jsr checkifplaton
beq printplatform
@moveplatformv_body:
bmi platform_v_negative
ldy #6
inc EXTRA_VARS + 2,X
bne platform_v_moved
platform_v_negative:
ldy #7
dec EXTRA_VARS + 2,X
platform_v_moved:
lda EXTRA_VARS + 2,X
cmp (TEMP_POINTER_9),Y
beq reverseplatdir
bne printplatform
robinjumpoffplatform:
lda PLAYER_GRAVITY
cmp #128
beq @robinjumpoffplatform_skip_if_equal
cmp #0
bmi endjumpoffplatform
@robinjumpoffplatform_skip_if_equal:
lda #0
sta PLAYER_JUMPING
lda TEMP_POINTER_7 + 1
sta PLAYER_Y
lda #128
sta PLAYER_GRAVITY
lda JOYPAD_STATE
and #BUTTON_A_MASK
beq endjumpoffplatform
jmp jumpingok
endjumpoffplatform:
rts
key_routine:
jsr checkifextraon
beq @key_routine_skip_if_equal
ldy #3
lda (TEMP_POINTER_9),Y
sec
sbc MAP_STRIP
cmp #18
bcs @key_routine_skip_if_equal
lda (TEMP_POINTER_9),Y
jsr multiply_strip_by_16_sub
jsr pickupcollision1
bcs @key_routine_skip_if_carry_2
sty TEMP_POINTER_8 + 1
ldy #3
lda (TEMP_POINTER_9),Y
tay
lda multiply_by_16_lo,Y
sta TEMP_POINTER_7
lda multiply_by_16_hi,Y
sta TEMP_POINTER_7 + 1
lda #3
jsr startstars
lda #49
jsr addtoscore
lda #69
jsr addtoscore
jsr turnoffextra
lda #SFX_PICKUP_KEY
jsr soundfx
ldy #5
lda (TEMP_POINTER_9),Y
beq @key_routine_skip_if_equal
cmp #255 - NUMBER_OF_DOORS
bcs @key_routine_skip_if_carry
jsr turnoffdoor
jmp @key_routine_skip_if_equal
@key_routine_skip_if_carry:
jsr openadoor
jmp @key_routine_skip_if_equal
@key_routine_skip_if_carry_2:
lda SPRITE_X_COORD_HIGH
bne @key_routine_skip_if_equal
lda #1
sta TEMP_BYTE
lda FRAME_COUNTER
lsr
lsr
and #3
sta TEMP_BYTE
ldx TEMP_POINTER_8
lda #155
jsr pokesprite2by2
@key_routine_skip_if_equal:
jmp backfromrounovars
updatespitters:
lda FRAME_COUNTER
asl
asl
asl
asl
and #128 + 64
clc
adc #3
sta TEMP_BYTE
ldx #NUMBER_OF_SPITTERS - 1
loopspit:
stx TEMP_BYTE_8
lda SPITTER_Y,X
beq endloopspit
inc SPITTER_Y,X
inc SPITTER_Y,X
lda SPITTER_Y,X
cmp #220
bcs takespitoff1
ldy #2
lda SPITTER_DIRECTION,X
bpl @loopspit_skip_if_positive
ldy #($FE)
@loopspit_skip_if_positive:
tya
clc
adc SPITTER_X_LOW,X
sta SPITTER_X_LOW,X
lda SPITTER_X_HIGH,X
adc SPITTER_DIRECTION,X
sta SPITTER_X_HIGH,X
@loopspit_body:
lda SPITTER_X_LOW,X
sec
sbc SCREEN_X_LOW
sta TEMP_BYTE_9
lda SPITTER_X_HIGH,X
sbc SCREEN_X_HIGH
bne endloopspit
lda SPITTER_Y,X
sta TEMP_POINTER_7
clc
adc #SPRITE_Y_DISPLACE
tay
ldx TEMP_BYTE_9
lda #153
jsr pokesprite
ldy TEMP_POINTER_7
ldx TEMP_BYTE_9
jsr checkchrcollision
bcc endloopspit
takespitteroff:
ldx TEMP_BYTE_8
takespitoff1:
lda #0
sta SPITTER_Y,X
spitternothitrobin:
endloopspit:
ldx TEMP_BYTE_8
dex
bpl loopspit
rts
checkchrcollision:
txa
sec
sbc PLAYER_ONSCREEN_X
clc
adc #10
cmp #20
bcs spitnocollision
tya
nowchrchecky:
sec
sbc PLAYER_Y
bcs spitnocollision
tya
sec
sbc PLAYER_HEIGHT
bcc spitnocollision
lda PLAYER_INVINCIBILITY_TIMER
bne spitnocollision
lda #1
jsr subfromhearts
sec
rts
spitnocollision:
clc
rts
canonrou:
lda (TEMP_POINTER_9),Y
sec
sbc MAP_STRIP
clc
adc #8
cmp #34
bcs veryendcanon
@canonrou_body:
lda (TEMP_POINTER_9),Y
jsr multiply_strip_by_16
sta TEMP_POINTER_7
lda EXTRA_VARS,X
bne endcanon
ldy #3
lda (TEMP_POINTER_9),Y
iny
jsr shootarrow
lda #2
sta ARROW_CANNON,X
endcanon:
lda TEMP_POINTER_7
sec
sbc SCREEN_X_LOW
tax
lda TEMP_POINTER_7 + 1
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
ldy #3
lda (TEMP_POINTER_9),Y
sta TEMP_BYTE
iny
lda (TEMP_POINTER_9),Y
asl
lda #SPRITE_CANNON
ldy TEMP_BYTE
jsr winprintspriteposrev
veryendcanon:
ldy #4
jsr dectiming
lda #2
jmp backfromrou
secretrou:
jsr checkifextraon
beq @secretrou_skip_if_equal
ldy #3
lda (TEMP_POINTER_9),Y
sec
sbc MAP_STRIP
cmp #18
bcs @secretrou_skip_if_equal
lda (TEMP_POINTER_9),Y
jsr multiply_strip_by_16_sub
jsr pickupcollision1
bcs @secretrou_skip_if_carry
jsr turnoffextra
ldy #5
lda (TEMP_POINTER_9),Y
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda SECRET_TABLE,Y
eor bitpattern,X
sta SECRET_TABLE,Y
ldy #5
lda (TEMP_POINTER_9),Y
jsr turnonsecret
jmp @secretrou_skip_if_equal
@secretrou_skip_if_carry:
@secretrou_skip_if_equal:
jmp backfromrounovars
doallsecrets:
lda #23
secretloop:
pha
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda SECRET_TABLE,Y
and bitpattern,X
beq @secretloop_skip_if_equal
pla
pha
jsr turnonsecret
@secretloop_skip_if_equal:
pla
sec
sbc #1
bpl secretloop
rts
turnonsecret:
asl
tax
jsr change_bank13_routine
lda secret_table,X
sta TEMP_POINTER
lda secret_table + 1,X
sta TEMP_POINTER + 1
lda #0
dosecret:
pha
tay
jsr change_bank13_routine
lda (TEMP_POINTER),Y
bpl @dosecret_skip_if_positive
pla
jsr change_bank12_routine
rts
@dosecret_skip_if_positive:
cmp MAP_NUMBER
bne @dosecret_skip_if_not_equal
iny
lda (TEMP_POINTER),Y
sta SCRATCH_BYTE_1
iny
lda (TEMP_POINTER),Y
sta SCRATCH_BYTE_2
iny
lda (TEMP_POINTER),Y
sta SCRATCH_BYTE_3
jsr change_bank12_routine
jsr addachangedblock1
@dosecret_skip_if_not_equal:
pla
clc
adc #4
jmp dosecret
marionrou:
ldy #3
lda (TEMP_POINTER_9),Y
jsr multiply_strip_by_16_sub
@marionrou_body:
lda EXTRA_VARS,X
cmp #6 * 32 + 1
beq @marionrou_skip_if_equal
inc EXTRA_VARS,X
and #31
bne @marionrou_skip_if_equal
lda EXTRA_VARS,X
lsr
lsr
lsr
lsr
lsr
cmp #6
bne @marionrou_skip_if_not_equal
lda CHANGED_BLOCKS_POINTER
cmp #18
bne @marionrou_skip_if_equal
ldy #6
bne @marionrou_skip_if_not_equal_2
@marionrou_skip_if_not_equal:
tay
lda TREASURE_FLAGS,Y
bne @marionrou_skip_if_equal
@marionrou_skip_if_not_equal_2:
sty TEMP_BYTE
lda #12
sec
sbc TEMP_BYTE
tay
ldx #13
lda #32
jsr addachangedblock
@marionrou_skip_if_equal:
checkrobinanim:
ldx EXTRA_VAR_POINTER
lda EXTRA_VARS + 1,X
bne alreadyanim
lda PLAYER_Y
cmp #95
bne @checkrobinanim_skip_if_not_equal
lda #2
jsr starttune
ldx EXTRA_VAR_POINTER
ldy #NUMBER_OF_ONSCREEN_OBJECTS - 1
lda #0
sta EXTRAS_ON + 157 / 8
@checkrobinanim_loop:
sta ONSCREEN_ROUTINE,Y
dey
bpl @checkrobinanim_loop
inc EXTRA_VARS + 1,X
@checkrobinanim_skip_if_not_equal:
jmp printmarion
alreadyanim:
lda EXTRA_VARS + 1,X
cmp #150
bne @alreadyanim_skip_if_not_equal
jmp fireworkdisplay
@alreadyanim_skip_if_not_equal:
inc EXTRA_VARS + 1,X
printrobinend:
lda MIN_MAP
cmp #255
beq @printrobinend_skip_if_equal
lda #66
jsr addtoscore
lda #85
jsr addtoscore
@printrobinend_skip_if_equal:
lda #200
sta PLAYER_INVINCIBILITY_TIMER
lda #0
sta PLAYER_JUMPING
sta PLAYER_ON_LADDER
lda EXTRA_VARS + 1,X
bmi @printrobinend_skip_if_negative
lda #200
sec
sbc EXTRA_VARS + 1,X
bmi @printrobinend_skip_if_negative_2
@printrobinend_skip_if_negative:
lda #128
@printrobinend_skip_if_negative_2:
sta PLAYER_X_LOW
lda #($FF)
sta OLD_PLAYER_FACING
lda #0
sta PLAYER_FIRING
sta PLAYER_CROUCHING
lda EXTRA_VARS + 1,X
bmi @printrobinend_skip_if_negative_3
cmp #55
bcs @printrobinend_skip_if_carry
lda EXTRA_VARS + 1,X
lsr
lsr
lsr
and #7
sta PLAYER_ANIMATION
jmp @printrobinend_skip
@printrobinend_skip_if_carry:
jsr do_heart
lda #254
sta PLAYER_CROUCHING
@printrobinend_skip_if_negative_3:
lda #255
sta PLAYER_ANIMATION
@printrobinend_skip:
jsr change_bank13_routine
jsr printrobin1
jsr change_bank12_routine
lda PLAYER_X_LOW
sta PREVIOUS_PLAYER_X_LOW
printmarion:
ldx #128 - 32 + 10
ldy #56
lda #SPRITE_MARIONETTE
jsr printsprite
lda #3
jmp backfromrou
fireworkdisplay:
inc EXTRA_VARS + 2,X
lda EXTRA_VARS + 2,X
cmp #256 - 7
bne @fireworkdisplay_skip_if_not_equal
lda #253
sta FADE_COUNTER
sta GAME_COMPLETED
@fireworkdisplay_skip_if_not_equal:
lda FRAME_COUNTER
and #254
clc
adc #1
sta FRAME_COUNTER
ldy #4
lda HEART_TABLE
beq @fireworkdisplay_skip_if_equal
iny
lda HEART_TABLE + 16
bne @fireworkdisplay_skip_if_not_equal_2
@fireworkdisplay_skip_if_equal:
lda RANDOM_SEED + 1
and #127
clc
adc #64
sta TEMP_POINTER_8 + 1
lda #0
sta TEMP_POINTER_7 + 1
lda RANDOM_SEED + 2
and #127
clc
adc #64
sta TEMP_POINTER_7
tya
jsr startstars
ldx EXTRA_VAR_POINTER
@fireworkdisplay_skip_if_not_equal_2:
jmp printrobinend
do_heart:
lda #12
sta COIN_NUMBER
lda #8
sta COIN_NUMBER_X
lda #65
sta COIN_NUMBER_Y
lda #64
sta COIN_NUMBER_COUNT
rts
redefinewaterbank:
jsr change_bank13_routine
jsr redefine_water
jsr change_bank12_routine
jmp backfromrounovars
