resetrobinvars:
lda #<(290)
sta PLAYER_X_LOW
lda #>(290)
sta PLAYER_X_LOW + 1
lda #208
sta PLAYER_Y
lda #0
sta MIN_MAP
rts
resetrobinvars1:
jsr turninteroff
lda MUSIC_TUNE
cmp #2
beq @resetrobinvars1_skip_if_equal
jsr turnofftune
@resetrobinvars1_skip_if_equal:
lda #5
sta HIGH_SCORE_POSITION
lda #40
sta JUST_STARTED_LIFE
lda #0
sta PLAYER_JUST_JUMPED
sta PLAYER_GRAVITY
sta PLAYER_CROUCHING
sta PLAYER_ON_LADDER
sta PLAYER_JUMPING
sta PLAYER_FIRING
sta PLAYER_LOOK_DIRECTION
sta PLAYER_KILLED
sta RUN_ANIMATION_COUNTER
sta PLAYER_BEHIND_BACKGROUND
lda #1
sta PLAYER_ANIMATION
lda #190
sta PLAYER_INVINCIBILITY_TIMER
lda #CHARSET_HIGH_SCORE
jsr copyblockofcompactedchrs
jsr change_bank1_routine
ldx #<(print_lives_info_message)
ldy #>(print_lives_info_message)
jsr prtmessage
ldx PLAYER_LIVES
lda PLAYER_HEARTS
bne display_lives
lose_life:
dec PLAYER_LIVES
dex
bpl @lose_life_skip_if_positive
jmp display_lives
@lose_life_skip_if_positive:
lda #3
sta PLAYER_HEARTS
inx
display_lives:
@display_lives_body:
cpx #6
bcc @display_lives_skip_if_no_carry
ldx #6
@display_lives_skip_if_no_carry:
cpx #0
bne @display_lives_skip_if_not_equal
lda #4
sta HIGH_SCORE_POSITION
@display_lives_skip_if_not_equal:
ldy #>(life1mess)
lda lives_bit_table,X
clc
adc #<(life1mess)
bcc @display_lives_skip_if_no_carry_2
iny
@display_lives_skip_if_no_carry_2:
tax
jsr prtmessage
ldy #0
ldx #0
copyintreasures:
lda #0
sta HEART_TABLE,Y
lda treasure_left_message,Y
sta VRAM_BUFFER_ADDRESS,Y
tya
and #3
cmp #3
bne @copyintreasures_skip_if_not_equal
lda TREASURE_FLAGS,X
clc
adc #33
sta VRAM_BUFFER_ADDRESS,Y
inx
@copyintreasures_skip_if_not_equal:
iny
cpy #6 * 4
sty VRAM_WRITE_POINTER
bne copyintreasures
jsr emptyprintbuffer
lda GAME_COMPLETED
beq @copyintreasures_skip_if_equal
ldx #<(completed_game_message)
ldy #>(completed_game_message)
jsr prtmessage
lda #255
sta MIN_MAP
sta HIGH_SCORE_POSITION
@copyintreasures_skip_if_equal:
jsr change_bank0_routine
ldx #<(SHOW_LIVES_COLOURS)
ldy #>(SHOW_LIVES_COLOURS)
jsr setfade
lda HIGH_SCORE_POSITION
bmi @copyintreasures_skip_if_negative
jsr starttune
@copyintreasures_skip_if_negative:
jsr turninteron
@copyintreasures_wait_vblank:
asl VBLANK_FLAG
@copyintreasures_wait_vblank_2:
bit VBLANK_FLAG
bpl @copyintreasures_wait_vblank_2
jsr printscore
jsr printhearts
jsr printlives
lda GAME_COMPLETED
beq @copyintreasures_skip_if_equal_2
jsr putextrason
lda #0
sta EXTRA_VARS + 2
jsr change_bank1_routine
jsr updatehearts
jsr change_bank0_routine
jmp @copyintreasures_skip
@copyintreasures_skip_if_equal_2:
jsr change_bank1_routine
jsr print_6_treasures
ldx #13 - 4
jsr pulsecolour
jsr change_bank0_routine
@copyintreasures_skip:
lda JOYPAD_STATE
and #BUTTON_START_MASK
beq @copyintreasures_wait_vblank
lda JOYPAD_DEBOUNCE
and #BUTTON_START_MASK
bne @copyintreasures_wait_vblank
jmp turninteroff
moveman:
lda PLAYER_KILLED
beq @moveman_skip_if_equal
@moveman_loop:
rts
@moveman_skip_if_equal:
lda JUST_STARTED_LIFE
bne @moveman_loop
lda PLAYER_X_LOW
sta PREVIOUS_PLAYER_X_LOW
lda PLAYER_X_LOW + 1
sta PREVIOUS_PLAYER_X_LOW + 1
lda PLAYER_Y
sta PREVIOUS_PLAYER_Y
lda PLAYER_JUST_JUMPED
beq @moveman_skip_if_equal_2
lda JOYPAD_STATE
and #BUTTON_A_MASK
bne @moveman_skip_if_equal_2
lda #0
sta PLAYER_JUST_JUMPED
@moveman_skip_if_equal_2:
lda PLAYER_LADDER_COUNTER
beq @moveman_skip_if_equal_3
dec PLAYER_LADDER_COUNTER
@moveman_skip_if_equal_3:
lda PLAYER_ON_LADDER
beq notladder
jmp onladder
notladder:
jsr dofiring
jsr dogravity
jsr docrouchstuff
jsr checkforladderup
lda PLAYER_JUMPING
beq robinnotjumping
jmp dorobinjumping
robinnotjumping:
jsr checkleftrightkeys
jsr addleftright
lda RUN_ANIMATION_COUNTER
bne @robinnotjumping_skip_if_not_equal
lda PLAYER_GRAVITY
cmp #128
bne @robinnotjumping_skip_if_not_equal
lda #255
sta PLAYER_ANIMATION
@robinnotjumping_skip_if_not_equal:
lda PLAYER_CROUCHING
bne nottryingtojump
lda JOYPAD_STATE
and #BUTTON_A_MASK
beq nottryingtojump
lda JOYPAD_DEBOUNCE
and #BUTTON_A_MASK
bne nottryingtojump
jsr findroof
beq nottryingtojump
inc PLAYER_Y
jsr findfloor
php
dec PLAYER_Y
plp
beq nottryingtojump1
jumpingok:
lda PLAYER_JUST_JUMPED
bne nottryingtojump
lda #1
sta PLAYER_JUMPING
sta PLAYER_JUST_JUMPED
@jumpingok_body:
lda RUN_ANIMATION_COUNTER
lsr
lsr
lsr
eor #255
clc
adc #($F3)
sta PLAYER_GRAVITY
jmp dorobinjumping
hitwall:
lda #0
sta PLAYER_ANIMATION
jsr restorex
jmp doneleftright
nottryingtojump:
lda JOYPAD_STATE
and #255 - BUTTON_A_MASK
sta JOYPAD_STATE
nottryingtojump1:
nowcheckifdirectionok:
lda PREVIOUS_PLAYER_X_LOW
cmp PLAYER_X_LOW
beq notmovingleftorright
bcc movingright
jsr findwallleft
bne hitwall
beq doneleftright
movingright:
jsr findwallright
bne hitwall
notmovingleftorright:
doneleftright:
jsr findfloor
lda BLOCK_FOUND
sta PLAYER_BEHIND_BACKGROUND
lda SOLID_TILE_FOUND
cmp #2
bcc @doneleftright_skip_if_no_carry
dec PLAYER_Y
inc RISE_UP_COUNTER
lda RISE_UP_COUNTER
cmp #15
bne @doneleftright_skip_if_not_equal
dec RISE_UP_COUNTER
inc PLAYER_Y
jmp @doneleftright_skip_if_not_equal
@doneleftright_skip_if_no_carry:
lda #0
sta RISE_UP_COUNTER
@doneleftright_skip_if_not_equal:
inc PLAYER_Y
jsr findfloor
dec PLAYER_Y
lda SOLID_TILE_FOUND
cmp #1
beq ontopofladder
cmp #2
beq semifloorfound
and #1
bne floorfound
fallthru:
lda PLAYER_GRAVITY
cmp #128
bne @fallthru_skip_if_not_equal
lda #0
sta PLAYER_GRAVITY
lda PLAYER_Y
clc
adc #6
sta PLAYER_Y
jsr findfloor
lda PLAYER_Y
clc
adc #($FA)
sta PLAYER_Y
lda SOLID_TILE_FOUND
and #1
beq @fallthru_skip_if_not_equal
lda #1
sta PLAYER_JUMPING
lda #8
sta PLAYER_GRAVITY
@fallthru_skip_if_not_equal:
rts
floorfound:
lda #128
sta PLAYER_GRAVITY
rts
semifloorfound:
lda PLAYER_CROUCHING
bne fallthru
jmp floorfound
ontopofladder:
lda PLAYER_GRAVITY
cmp #128
bne @ontopofladder_skip_if_not_equal
lda PLAYER_JUMPING
beq floorfound
@ontopofladder_skip_if_not_equal:
rts
checkleftrightkeys:
lda #0
sta PLAYER_FACING
lda PLAYER_CROUCHING
bne @checkleftrightkeys_skip_if_not_equal_2
lda JOYPAD_STATE
and #BUTTON_RIGHT_MASK
beq @checkleftrightkeys_skip_if_equal
lda #1
sta PLAYER_FACING
bne @checkleftrightkeys_skip_if_not_equal
@checkleftrightkeys_skip_if_equal:
lda JOYPAD_STATE
and #BUTTON_LEFT_MASK
beq @checkleftrightkeys_skip_if_not_equal_2
lda #($FF)
sta PLAYER_FACING
@checkleftrightkeys_skip_if_not_equal:
cmp OLD_PLAYER_FACING
beq @checkleftrightkeys_skip_if_equal_2
ldx #1
sta RUN_ANIMATION_COUNTER
@checkleftrightkeys_skip_if_equal_2:
sta OLD_PLAYER_FACING
@checkleftrightkeys_skip_if_not_equal_2:
rts
walkoffladder:
lda #128
bne restoffladd
jumpoffladderleft:
jumpoffladderright:
lda #1
sta PLAYER_JUMPING
lda #1
sta RUN_ANIMATION_COUNTER
lda #($F3)
restoffladd:
sta PLAYER_GRAVITY
lda #0
sta PLAYER_ON_LADDER
lda #12
sta PLAYER_LADDER_COUNTER
rts
onladder:
lda PLAYER_X_LOW
and #15
cmp #8
beq @onladder_skip_if_equal
bcs @onladder_skip_if_carry
inc PLAYER_X_LOW
jmp @bug
@onladder_skip_if_carry:
dec PLAYER_X_LOW
@bug:
ldy PLAYER_Y
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
cmp #1
beq @bugok
lda PLAYER_HEIGHT
clc
adc #4
tay
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
cmp #1
bne walkoffladder
@bugok:
jmp @onladder_skip
@onladder_skip_if_equal:
jsr checkleftrightkeys
lda JOYPAD_STATE
and #BUTTON_LEFT_MASK
beq @onladder_skip_if_equal_2
lda PLAYER_X_LOW
sec
sbc #PLAYER_WIDTH + 6
sta TEMP_BYTE_8
lda PLAYER_X_HIGH
sbc #0
jsr restwall
bne @onladder_skip_if_equal_2
lda JOYPAD_STATE
and #BUTTON_A_MASK
bne jumpoffladderleft
lda PLAYER_Y
clc
adc #6
tay
lda TEMP_BYTE_8
ldx TEMP_BYTE_9
jsr findsolid
beq @onladder_skip_if_equal_2
jmp walkoffladder
@onladder_skip_if_equal_2:
lda JOYPAD_STATE
and #BUTTON_RIGHT_MASK
beq @onladder_skip
jsr findwallright
bne @onladder_skip
lda JOYPAD_STATE
and #BUTTON_A_MASK
beq @onladder_skip_if_equal_3
jmp jumpoffladderright
@onladder_skip_if_equal_3:
lda PLAYER_Y
clc
adc #6
tay
lda TEMP_BYTE_8
ldx TEMP_BYTE_9
jsr findsolid
beq @onladder_skip_if_equal_4
jmp walkoffladder
@onladder_skip_if_equal_4:
@onladder_skip:
jsr checkifstillonladderup
@onladder_body:
lda JOYPAD_STATE
and #BUTTON_DOWN_MASK
beq @onladder_skip_if_equal_5
inc PLAYER_Y
jsr checkifstillonladderdown
@onladder_skip_if_equal_5:
rts
checkifstillonladderdown:
ldy PLAYER_Y
cpy #36
bcc @checkifstillonladderdown_skip_if_no_carry
iny
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
sta TEMP_BYTE_4
cmp #1
beq @checkifstillonladderdown_skip_if_no_carry
cmp #0
bne stepoffladderdown
lda PLAYER_HEIGHT
clc
adc #4
tay
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
cmp #1
bne stepoffladderdown
@checkifstillonladderdown_skip_if_no_carry:
rts
stepoffladderdown:
lda TEMP_BYTE_4
cmp #3
beq stepoff1
lda #1
sta PLAYER_GRAVITY
sta PLAYER_JUMPING
bne stepoff1
stepoffladderup:
lda #128
sta PLAYER_GRAVITY
lda #0
sta PLAYER_JUMPING
stepoff1:
lda #0
sta PLAYER_ON_LADDER
sta PLAYER_LOOK_DIRECTION
sta RUN_ANIMATION_COUNTER
lda #12
sta PLAYER_LADDER_COUNTER
rts
checkifstillonladderup:
lda PLAYER_HEIGHT
clc
adc #4
tay
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
lda SOLID_TILE_FOUND
sta TEMP_BYTE_5
cmp #1
beq @checkifstillonladderup_skip_if_equal
cmp #0
bne @checkifstillonladderup_skip_if_not_equal
ldy PLAYER_Y
cpy #36
bcc @checkifstillonladderup_skip_if_equal
dey
dey
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
lda SOLID_TILE_FOUND
cmp #1
beq @checkifstillonladderup_skip_if_equal
cmp #0
bne stepoffladderup
lda TEMP_BYTE_5
lda SOLID_TILE_FOUND
cmp #1
beq @checkifstillonladderup_skip_if_equal
dec PLAYER_Y
dec PLAYER_Y
jmp stepoffladderup
@checkifstillonladderup_skip_if_equal:
lda JOYPAD_STATE
and #BUTTON_UP_MASK
beq @checkifstillonladderup_skip_if_not_equal
dec PLAYER_Y
@checkifstillonladderup_skip_if_not_equal:
rts
checkforladderdown:
lda PLAYER_LADDER_COUNTER
bne @checkforladderdown_skip_if_not_equal
ldy PLAYER_Y
iny
iny
iny
iny
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
lda SOLID_TILE_FOUND
cmp #1
bne @checkforladderdown_skip_if_not_equal
inc PLAYER_Y
inc PLAYER_Y
inc PLAYER_Y
jmp setonladder
@checkforladderdown_skip_if_not_equal:
lda PLAYER_JUMPING
bne @checkforladderdown_skip_if_not_equal_2
lda #($F9)
sta PLAYER_CROUCHING
@checkforladderdown_skip_if_not_equal_2:
rts
checkforladderup:
lda JOYPAD_STATE
and #BUTTON_UP_MASK
beq checkladupend
lda PLAYER_LADDER_COUNTER
bne checkladupend
lda PLAYER_CROUCHING
bne checkladupend
lda PLAYER_HEIGHT
clc
adc #4
tay
lda PLAYER_X_LOW
ldx PLAYER_X_HIGH
jsr findsolid
cmp #1
bne checkladupend
dec PLAYER_Y
setonladder:
jsr setonladdervars
jmp onladder
checkladupend:
rts
setonladdervars:
lda #0
sta RUN_ANIMATION_COUNTER
sta PLAYER_JUMPING
lda #4
sta PLAYER_ON_LADDER
lda #1
sta PLAYER_GRAVITY
rts
docrouchstuff:
lda PLAYER_JUMPING
bne @docrouchstuff_skip_if_not_equal_3
lda PLAYER_CROUCHING
beq @docrouchstuff_skip_if_not_equal_3
ldx PLAYER_CROUCHING
cpx #($FC)
bne @docrouchstuff_skip_if_not_equal
lda JOYPAD_STATE
and #BUTTON_DOWN_MASK
bne @docrouchstuff_skip_if_not_equal_4
@docrouchstuff_skip_if_not_equal:
lda FRAME_COUNTER
and #3
bne @docrouchstuff_skip_if_not_equal_2
inc PLAYER_CROUCHING
@docrouchstuff_skip_if_not_equal_2:
lda PLAYER_HEIGHT
pha
lda PLAYER_Y
clc
adc #($F0)
sta PLAYER_HEIGHT
jsr movebackcrouchedunder
pla
sta PLAYER_HEIGHT
rts
@docrouchstuff_skip_if_not_equal_3:
lda JOYPAD_STATE
and #BUTTON_DOWN_MASK
beq @docrouchstuff_skip_if_not_equal_4
jsr checkforladderdown
@docrouchstuff_skip_if_not_equal_4:
rts
dofiring:
lda PLAYER_CROUCHING
bne @dofiring_skip_if_not_equal_3
lda PLAYER_FIRING
bne @dofiring_skip_if_not_equal
lda JOYPAD_STATE
and #BUTTON_B_MASK
beq @dofiring_skip_if_not_equal_3
lda #9 * 4 + 3
sta PLAYER_FIRING
rts
@dofiring_skip_if_not_equal:
cmp #3 * 4
bne @dofiring_skip_if_not_equal_2
@dofiring_body:
lda JOYPAD_STATE
and #BUTTON_B_MASK
bne @dofiring_skip_if_not_equal_3
@dofiring_skip_if_not_equal_2:
dec PLAYER_FIRING
lda PLAYER_FIRING
cmp #4 * 3 - 1
bne @dofiring_skip_if_not_equal_3
jsr robinshootarrow
lda #SFX_YOU_FIRING
jsr soundfx
@dofiring_skip_if_not_equal_3:
rts
animatelegs:
lda PLAYER_JUMPING
bne @animatelegs_skip_if_not_equal
lda PREVIOUS_PLAYER_X_LOW
lsr
lsr
sta TEMP_BYTE
lda PLAYER_X_LOW
lsr
lsr
cmp TEMP_BYTE
beq @animatelegs_skip_if_equal
and #1
bne @animatelegs_skip_if_equal
inc PLAYER_ANIMATION
lda PLAYER_ANIMATION
and #7
tax
@animatelegs_body:
stx PLAYER_ANIMATION
@animatelegs_skip_if_equal:
rts
@animatelegs_skip_if_not_equal:
ldx #2
lda RUN_ANIMATION_COUNTER
cmp #9
bcc @animatelegs_skip_if_no_carry
ldx #1
cmp #24
bcc @animatelegs_skip_if_no_carry
ldx #12
@animatelegs_skip_if_no_carry:
stx PLAYER_ANIMATION
rts
restorex:
lda #0
sta PLAYER_FACING
restorex1:
lda RUN_ANIMATION_COUNTER
cmp #1
bcc @restorex1_skip_if_no_carry
lda #1
sta RUN_ANIMATION_COUNTER
@restorex1_skip_if_no_carry:
lda PREVIOUS_PLAYER_X_LOW
sta PLAYER_X_LOW
lda PREVIOUS_PLAYER_X_LOW + 1
sta PLAYER_X_LOW + 1
rts
dogravity:
lda PLAYER_GRAVITY
cmp #128
bne @dogravity_skip_if_not_equal
rts
@dogravity_skip_if_not_equal:
lda PLAYER_GRAVITY
bmi @dogravity_skip_if_negative
cmp #24
bcs @dogravity_skip_if_carry
@dogravity_skip_if_negative:
inc PLAYER_GRAVITY
@dogravity_skip_if_carry:
lda PLAYER_GRAVITY
sta TEMP_BYTE
asl TEMP_BYTE
ror
asl TEMP_BYTE
ror
clc
adc PLAYER_Y
sta PLAYER_Y
lda PLAYER_GRAVITY
bmi @dogravity_skip_if_negative_4
lda #2
ldx PLAYER_CROUCHING
beq @dogravity_skip_if_equal
lda #3
@dogravity_skip_if_equal:
sta TEMP_BYTE_5
jsr findfloor
lda BLOCK_FOUND
sta PLAYER_BEHIND_BACKGROUND
lda SOLID_TILE_FOUND
cmp TEMP_BYTE_5
bcc @dogravity_skip_if_negative_4
lda PLAYER_Y
clc
adc #($F8)
sta PLAYER_Y
jsr findfloor
php
lda PLAYER_Y
clc
adc #8
sta PLAYER_Y
plp
beq @dogravity_loop
jsr restorex1
jmp @dogravity_skip_2
@dogravity_loop:
dec PLAYER_Y
jsr findfloor
beq @dogravity_skip_2
lda PLAYER_FACING
beq @dogravity_loop
bmi @dogravity_skip_if_negative_2
jsr findwallright
beq @dogravity_loop
jmp @dogravity_skip
@dogravity_skip_if_negative_2:
jsr findwallleft
beq @dogravity_loop
@dogravity_skip:
jsr restorex1
jmp @dogravity_loop
@dogravity_skip_2:
lda #0
sta PLAYER_JUMPING
lda JOYPAD_STATE
and #255 - BUTTON_DOWN_MASK
sta JOYPAD_STATE
lda PLAYER_GRAVITY
bmi @dogravity_skip_if_negative_3
cmp #22
bcc @dogravity_skip_if_negative_3
lda #($F9)
sta PLAYER_CROUCHING
@dogravity_skip_if_negative_3:
lda #128
sta PLAYER_GRAVITY
@dogravity_skip_if_negative_4:
rts
dorobinjumping:
lda PLAYER_GRAVITY
cmp #128
bne @bugwashere
lda #0
sta PLAYER_GRAVITY
@bugwashere:
lda PLAYER_CROUCHING
beq @dorobinjumping_skip_if_equal
inc PLAYER_CROUCHING
rts
@dorobinjumping_skip_if_equal:
jsr addleftright
bit PLAYER_GRAVITY
bpl @dorobinjumping_skip_if_positive
lda PLAYER_BEHIND_BACKGROUND
beq @dorobinjumping_skip_if_equal_2
ldy PLAYER_Y
ldx PLAYER_X_HIGH
lda PLAYER_X_LOW
jsr findblock
sta PLAYER_BEHIND_BACKGROUND
@dorobinjumping_skip_if_equal_2:
jsr findroof
bne @dorobinjumping_skip_if_positive
lda PREVIOUS_PLAYER_Y
sta PLAYER_Y
@dorobinjumping_skip_if_positive:
lda RUN_ANIMATION_COUNTER
beq notjumpingleftorright
lda PLAYER_FACING
bpl jumpingright
jsr findwallleft
beq notjumpingleftorright
lda PREVIOUS_PLAYER_X_LOW
and #248
sta PREVIOUS_PLAYER_X_LOW
jmp restorex1
jumpingright:
jsr findwallright
beq notjumpingleftorright
lda PREVIOUS_PLAYER_X_LOW
sec
sbc #1
and #248
clc
adc #7
sta PREVIOUS_PLAYER_X_LOW
jmp restorex1
notjumpingleftorright:
rts
addleftright:
lda PLAYER_JUMPING
bne restleftright
addleftright1:
lda PLAYER_FACING
beq @addleftright1_skip_if_equal
cmp OLD_PLAYER_FACING
bne @addleftright1_skip_if_equal
inc RUN_ANIMATION_COUNTER
lda RUN_ANIMATION_COUNTER
cmp #48
bne @addleftright1_skip_if_not_equal_2
lda #47
sta RUN_ANIMATION_COUNTER
@addleftright1_body:
jmp @addleftright1_skip_if_not_equal_2
@addleftright1_skip_if_equal:
lda RUN_ANIMATION_COUNTER
beq @addleftright1_skip_if_not_equal_2
lda PLAYER_CROUCHING
bne @addleftright1_skip_if_not_equal
lsr RUN_ANIMATION_COUNTER
jmp @addleftright1_skip_if_not_equal_2
@addleftright1_skip_if_not_equal:
lda FRAME_COUNTER
and #3
beq @addleftright1_skip_if_not_equal_2
dec RUN_ANIMATION_COUNTER
@addleftright1_skip_if_not_equal_2:
restleftright:
ldx RUN_ANIMATION_COUNTER
bne @restleftright_skip_if_not_equal
rts
@restleftright_skip_if_not_equal:
ldy #1
cpx #47
bne @restleftright_skip_if_not_equal_2
iny
@restleftright_skip_if_not_equal_2:
lda OLD_PLAYER_FACING
bmi @restleftright_skip_if_negative
@restleftright_body:
lda runtablelo,X
clc
adc PLAYER_X_DELTA
sta PLAYER_X_DELTA
tya
adc PLAYER_X_LOW
sta PLAYER_X_LOW
bcc @restleftright_skip_if_no_carry
inc PLAYER_X_HIGH
@restleftright_skip_if_no_carry:
rts
@restleftright_skip_if_negative:
sty TEMP_BYTE
lda PLAYER_X_DELTA
sec
sbc runtablelo,X
sta PLAYER_X_DELTA
lda PLAYER_X_LOW
sbc TEMP_BYTE
sta PLAYER_X_LOW
bcs @restleftright_skip_if_carry
dec PLAYER_X_HIGH
rts
@restleftright_skip_if_carry:
lda PLAYER_X_HIGH
bne @restleftright_skip_if_not_equal_4
lda #12
cmp PLAYER_X_LOW
bcc @restleftright_skip_if_not_equal_4
lda MAP_NUMBER
cmp #5
bne @restleftright_skip_if_not_equal_3
lda #5
sta MAP_NUMBER
lda #244
sta PLAYER_Y
lda #8
sta SCREEN_X_HIGH
sta PLAYER_X_HIGH
sta PREVIOUS_PLAYER_X_HIGH
lda #120
sta PLAYER_X_LOW
sta PREVIOUS_PLAYER_X_LOW
lda #0
sta SCREEN_X_LOW
sta TREASURE_FLAGS
sta TREASURE_FLAGS + 1
sta TREASURE_FLAGS + 2
rts
@restleftright_skip_if_not_equal_3:
jmp restorex
@restleftright_skip_if_not_equal_4:
rts
RUN_ACCELERATION .set 256 / 48
RUN_SPEED_ACCUMULATOR .set 0
runtablelo:
.byte $00
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $05
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $0A
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $0F
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $14
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $19
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $1E
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $23
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $28
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $2D
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $32
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $37
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $3C
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $41
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $46
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $4B
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $50
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $55
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $5A
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $5F
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $64
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $69
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $6E
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $73
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $78
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $7D
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $82
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $87
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $8C
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $91
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $96
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $9B
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $A0
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $A5
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $AA
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $AF
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $B4
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $B9
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $BE
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $C3
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $C8
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $CD
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $D2
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $D7
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $DC
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $E1
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $E6
RUN_SPEED_ACCUMULATOR .set RUN_SPEED_ACCUMULATOR + RUN_ACCELERATION
.byte $00
PLAYER_WIDTH = 8
findwallleft:
lda PLAYER_X_LOW
sec
sbc #PLAYER_WIDTH + 1
sta TEMP_BYTE_8
lda PLAYER_X_HIGH
sbc #0
restwall:
tax
stx TEMP_BYTE_9
lda PLAYER_Y
sec
sbc #8 - 2
clc
adc PLAYER_ON_LADDER
tay
lda TEMP_BYTE_8
jsr findsolid
cmp #3
beq @notequal
lda PLAYER_CROUCHING
bne @equal
ldx TEMP_BYTE_9
lda PLAYER_Y
sec
sbc #21
tay
lda TEMP_BYTE_8
jsr findsolid
cmp #3
bne @equal
@notequal:
lda #1
rts
@equal:
lda #0
rts
findwallright:
lda PLAYER_X_LOW
clc
adc #PLAYER_WIDTH + 1
sta TEMP_BYTE_8
lda PLAYER_X_HIGH
adc #0
jmp restwall
findfloor:
ldy PLAYER_Y
ldx PLAYER_X_HIGH
lda PLAYER_X_LOW
sec
sbc #4
bcs @findfloor_skip_if_carry
dex
@findfloor_skip_if_carry:
jsr findsolid
lda SOLID_TILE_FOUND
sta TEMP_BYTE_9
ldy PLAYER_Y
ldx PLAYER_X_HIGH
lda PLAYER_X_LOW
clc
adc #4
bcc @findfloor_skip_if_no_carry
inx
@findfloor_skip_if_no_carry:
jsr findsolid
lda TEMP_BYTE_9
cmp SOLID_TILE_FOUND
bcs @findfloor_skip_if_carry_2
lda SOLID_TILE_FOUND
@findfloor_skip_if_carry_2:
sta SOLID_TILE_FOUND
and #2
bne @findfloor_skip_if_not_equal_2
lda PLAYER_JUMPING
bne @findfloor_skip_if_not_equal
lda SOLID_TILE_FOUND
cmp #1
bne @findfloor_skip_if_not_equal
@findfloor_body:
lda #1
rts
@findfloor_skip_if_not_equal:
lda #0
@findfloor_skip_if_not_equal_2:
rts
findroof:
lda #($FB)
jsr findroofleft
beq @findroof_skip_if_equal
lda #PLAYER_WIDTH - 3
jmp findroofright
@findroof_skip_if_equal:
rts
findroofleft:
clc
adc PLAYER_X_LOW
ldy PLAYER_HEIGHT
ldx PLAYER_X_HIGH
bcs @findroofleft_skip_if_carry
dex
@findroofleft_skip_if_carry:
jsr findsolid
cmp #3
rts
findroofright:
clc
adc PLAYER_X_LOW
ldy PLAYER_HEIGHT
ldx PLAYER_X_HIGH
bcc @findroofright_skip_if_no_carry
inx
@findroofright_skip_if_no_carry:
jsr findsolid
cmp #3
rts
movebackcrouchedunder:
lda PLAYER_CROUCHING
cmp #($FC)
bcc endcrouch
bit OLD_PLAYER_FACING
bmi slidingneg
lda #PLAYER_WIDTH - 2
jsr findroofright
beq slidebackright
lda #($FA)
jsr findroofleft
bne @movebackcrouchedunder_skip_if_not_equal_2
inc PLAYER_X_LOW
bne @movebackcrouchedunder_skip_if_not_equal
inc PLAYER_X_LOW + 1
@movebackcrouchedunder_skip_if_not_equal:
jmp setcrouch
@movebackcrouchedunder_skip_if_not_equal_2:
lda #PLAYER_WIDTH - 2
jsr findroofright
bne endcrouch
slidebackright:
dec PLAYER_X_LOW
pha
lda #255
cmp PLAYER_X_LOW
bne @slidebackright_skip_if_not_equal
dec PLAYER_X_LOW + 1
@slidebackright_skip_if_not_equal:
pla
jmp setcrouch
slidingneg:
lda #($FA)
jsr findroofleft
beq slidebackleft
lda #PLAYER_WIDTH - 2
jsr findroofright
bne @slidingneg_skip_if_not_equal_2
dec PLAYER_X_LOW
pha
lda #255
cmp PLAYER_X_LOW
bne @slidingneg_skip_if_not_equal
dec PLAYER_X_LOW + 1
@slidingneg_skip_if_not_equal:
pla
jmp setcrouch
@slidingneg_skip_if_not_equal_2:
lda #($FA)
jsr findroofleft
bne endcrouch
slidebackleft:
inc PLAYER_X_LOW
bne @slidebackleft_skip_if_not_equal
inc PLAYER_X_LOW + 1
@slidebackleft_skip_if_not_equal:
setcrouch:
lda #($FC)
sta PLAYER_CROUCHING
endcrouch:
rts
storeoutoldrobin:
lda PLAYER_ON_LADDER
sta OLD_PLAYER_ON_LADDER
lda PLAYER_X_LOW
sta SAVED_PLAYER_X_LOW
lda PLAYER_X_HIGH
sta SAVED_PLAYER_X_HIGH
lda PLAYER_Y
sta SAVED_PLAYER_Y
dontstoreold:
rts
restoreoldrobin:
lda OLD_PLAYER_ON_LADDER
sta PLAYER_ON_LADDER
lda SAVED_PLAYER_X_LOW
sta PLAYER_X_LOW
lda SAVED_PLAYER_X_HIGH
sta PLAYER_X_HIGH
lda SAVED_PLAYER_Y
sta PLAYER_Y
lda #128
sta PLAYER_GRAVITY
rts
checkrobinbehind:
ldx #0
lda PLAYER_BEHIND_BACKGROUND
cmp #248
bcs @checkrobinbehind_skip_if_carry
cmp #244
bcc @checkrobinbehind_skip_if_carry
beq @checkrobinbehind_skip_if_equal
lda #0
sta PLAYER_INVINCIBILITY_TIMER
sta PLAYER_KILLED
@checkrobinbehind_body:
lda #3
jsr subfromhearts1
@checkrobinbehind_skip_if_equal:
lda RUN_ANIMATION_COUNTER
beq @checkrobinbehind_skip_if_equal_2
lda #1
sta RUN_ANIMATION_COUNTER
@checkrobinbehind_skip_if_equal_2:
ldx #32
@checkrobinbehind_skip_if_carry:
stx SPRITE_BEHIND
rts
