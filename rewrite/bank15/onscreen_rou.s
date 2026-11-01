checkaddflamesetc:
ldy TEMP_POINTER_9
lda blockrous,Y
beq putinnowt
sta TEMP_BYTE_1
and #63
sta TEMP_BYTE
tax
lda ablockrous,X
sta TEMP_POINTER
lda ablockrous + 1,X
sta TEMP_POINTER + 1
ldx #NUMBER_OF_ONSCREEN_OBJECTS - 1
findaspace:
lda ONSCREEN_ROUTINE,X
beq gotspaceonscreen
findaspace1:
dex
bpl findaspace
putinnowt:
rts
gotspaceonscreen:
bit TEMP_BYTE_1
bvc @gotspaceonscreen_skip_if_no_overflow
cpx #NUMBER_OF_ONSCREEN_OBJECTS - 1
beq findaspace1
lda ONSCREEN_ROUTINE + 1,X
bne findaspace1
@gotspaceonscreen_skip_if_no_overflow:
lda TEMP_BYTE
sta ONSCREEN_ROUTINE,X
lda #0
sta ONSCREEN_COUNTER_1,X
sta ONSCREEN_COUNTER_2,X
jmp (TEMP_POINTER)
ablockrous:
BLOCK_TYPE_NONE = 0
.word putinnowt
BLOCK_TYPE_FLAME = 2
.word putinflames
BLOCK_TYPE_SPITTER = 4
.word putinspit
BLOCK_TYPE_EYES = 6
.word putineyes
BLOCK_TYPE_DRIP = 8
.word putindrip
BLOCK_TYPE_TRAMPOLINE = 10
.word putintramp
BLOCK_TYPE_DRILL_DOWN = 12 + 128
.word putindrilldown
BLOCK_TYPE_DRILL_UP = 14 + 128
.word putindrillup
BLOCK_TYPE_BAT = 16 + 128 + 64
.word putinbat
BLOCK_TYPE_RAT = 18 + 128
.word putinrat
BLOCK_TYPE_SPIDER = 20 + 128
.word putinspider
BLOCK_TYPE_HEART = 22 + 128
.word putinheart
BLOCK_TYPE_BARREL = 24 + 64
.word putinbarrel
BLOCK_TYPE_BLOCK = 26 + 128
.word putinblock
BLOCK_TYPE_COIN = 28 + 128
.word putincoin
blockrous:
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $02
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $04
.byte $04
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $02
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $02
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $06
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $94
.byte $96
.byte $58
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $8C
.byte $8E
.byte $0A
.byte $00
.byte $D0
.byte $92
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $08
.byte $9C
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $02
.byte $00
updateonscreens:
ldy #NUMBER_OF_ONSCREEN_OBJECTS - 1
doupdates:
ldx ONSCREEN_ROUTINE,Y
beq backfromscreenrou1
cpx #255
beq backfromscreenrou1
sty TEMP_POINTER_9
lda updatescrrous - 2,X
sta TEMP_POINTER
lda updatescrrous + 1 - 2,X
sta TEMP_POINTER + 1
jmp (TEMP_POINTER)
backfromscreenrou:
ldy TEMP_POINTER_9
backfromscreenrou1:
dey
bpl doupdates
rts
updatescrrous:
.word updateflames
.word updatespit
.word updateeyes
.word updatedrips
.word updatetramp
.word updatedrilldown
.word updatedrillup
.word updatebat
.word updaterat
.word updatespider
.word updateheart
.word updatebarrel
.word updateblock
.word updatecoin
onscrxandy0:
lda #0
onscrxandy:
ldy BLOCK_X
clc
adc multiply_by_16_lo - 1,Y
sta ONSCREEN_X_LOW,X
lda multiply_by_16_hi - 1,Y
adc #0
sta ONSCREEN_X_HIGH,X
ldy BLOCK_Y
lda multiply_by_16_lo,Y
sta ONSCREEN_Y,X
ldy #NUMBER_OF_ONSCREEN_OBJECTS - 1
@onscrxandy_loop:
sty TEMP_BYTE
cpx TEMP_BYTE
beq @onscrxandy_skip_if_equal
lda ONSCREEN_ROUTINE,Y
beq @onscrxandy_skip_if_equal
cmp ONSCREEN_ROUTINE,X
bne @onscrxandy_skip_if_equal
lda ONSCREEN_X_LOW,X
cmp ONSCREEN_X_LOW,Y
bne @onscrxandy_skip_if_equal
lda ONSCREEN_X_HIGH,X
cmp ONSCREEN_X_HIGH,Y
bne @onscrxandy_skip_if_equal
lda ONSCREEN_Y,X
cmp ONSCREEN_Y,Y
bne @onscrxandy_skip_if_equal
lda #0
sta ONSCREEN_ROUTINE,X
rts
@onscrxandy_skip_if_equal:
dey
bpl @onscrxandy_loop
return_from_put_in_onscreen:
rts
putinflames:
lda #4
cpy #10
beq addflame
cpy #254
beq addflame
lda #12
cpy #68
bne addflame
jsr onscrxandy
lda ONSCREEN_Y,X
clc
adc #($F8)
sta ONSCREEN_Y,X
rts
addflame:
jmp onscrxandy
putinspit:
lda #0
cpy #52
beq @putinspit_skip_if_equal
lda #($FF)
@putinspit_skip_if_equal:
sta ONSCREEN_COUNTER_1,X
lda BLOCK_X
and #7
sta ONSCREEN_COUNTER_2,X
lda #4
jmp onscrxandy
putineyes:
lda RANDOM_SEED + 2
cmp #30
bcs dontputinonscreen
and #3
sta ONSCREEN_COUNTER_2,X
lda RANDOM_SEED + 1
sta ONSCREEN_COUNTER_1,X
jmp onscrxandy0
dontputinonscreen:
lda #0
sta ONSCREEN_ROUTINE,X
jmp random
putindrip:
lda BLOCK_X
and #3
tay
lda firestable,Y
sta ONSCREEN_COUNTER_2,X
lda #8
jsr onscrxandy
lda ONSCREEN_Y,X
clc
adc #16 + 4
sta ONSCREEN_Y,X
rts
firestable:
.byte $FF
.byte $7F
.byte $3F
.byte $7F
putintramp:
lda #8
jmp onscrxandy
putindrillup:
lda #4
jsr onscrxandy
lda ONSCREEN_Y,X
clc
adc #16
putindriller:
sta ONSCREEN_Y,X
sta ONSCREEN_COUNTER_1,X
lda BLOCK_X
and #7
clc
adc #128 + 64
sta ONSCREEN_COUNTER_2,X
rts
putindrilldown:
lda #4
jsr onscrxandy
lda ONSCREEN_Y,X
clc
adc #($F6)
jmp putindriller
putinbat:
ldy #NUMBER_OF_ONSCREEN_OBJECTS - 1
morebats:
lda ONSCREEN_ROUTINE,Y
cmp #BLOCK_TYPE_BAT - 64 - 128
bne batok
lda ONSCREEN_X_LOW + 1,Y
cmp BLOCK_X
bne batok
lda ONSCREEN_Y + 1,Y
cmp BLOCK_Y
bne batok
putincanceldouble:
lda #0
sta ONSCREEN_ROUTINE,X
sta ONSCREEN_ROUTINE + 1,X
rts
batok:
dey
bpl morebats
lda #255
sta ONSCREEN_ROUTINE + 1,X
lda BLOCK_X
and #1
bne @batok_skip_if_not_equal
lda #($FF)
@batok_skip_if_not_equal:
sta ONSCREEN_COUNTER_1,X
lda #1
sta ONSCREEN_COUNTER_2,X
sta ONSCREEN_COUNTER_2 + 1,X
lda #10
sta ONSCREEN_COUNTER_1 + 1,X
lda BLOCK_X
sta ONSCREEN_X_LOW + 1,X
lda BLOCK_Y
sta ONSCREEN_Y + 1,X
jmp onscrxandy0
putinrat:
lda #128
sta ONSCREEN_COUNTER_1,X
lda BLOCK_X
and #3
tay
lda rattable,Y
sta ONSCREEN_COUNTER_2,X
jmp onscrxandy0
rattable:
.byte $03
.byte $83
.byte $01
.byte $81
putinspider:
lda BLOCK_X
and #1
sta ONSCREEN_COUNTER_2,X
lda #9
jmp onscrxandy
putinbarrel:
lda #255
sta ONSCREEN_ROUTINE + 1,X
lda #0
sta ONSCREEN_Y + 1,X
lda BLOCK_X
and #1
bne @putinbarrel_skip_if_not_equal
lda #255
@putinbarrel_skip_if_not_equal:
sta ONSCREEN_COUNTER_2 + 1,X
lda BLOCK_X
lsr
and #1
sta ONSCREEN_COUNTER_2,X
lda #8
jsr onscrxandy
bne @putinbarrel_skip_if_not_equal_2
jmp putincanceldouble
@putinbarrel_skip_if_not_equal_2:
rts
putinblock:
jmp onscrxandy0
putinheart:
jsr change_bank13_routine
ldy #8 * 6 * 2
bne putinheartbit
putincoin:
jsr change_bank13_routine
ldy #0
putinheartbit:
jsr putinheartbank
jsr change_bank12_routine
rts
calconscreenx:
lda ONSCREEN_X_LOW,Y
sec
sbc SCREEN_X_LOW
tax
lda ONSCREEN_X_HIGH,Y
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
bne outofscreen
rts
outofscreen:
bpl @outofscreen_skip_if_positive
cpx #256 - 32
bcs @outofscreen_skip_if_carry
bcc @outofscreen_skip_if_no_carry
@outofscreen_skip_if_positive:
cpx #32
bcc @outofscreen_skip_if_carry
@outofscreen_skip_if_no_carry:
lda #0
sta ONSCREEN_ROUTINE,Y
pla
pla
jmp backfromscreenrou
@outofscreen_skip_if_carry:
rts
updateflames:
jsr calconscreenx
lda SPRITE_X_COORD_HIGH
bne @updateflames_skip_if_not_equal_2
sty TEMP_BYTE_1
ldy #3
lda FRAME_COUNTER
and #4
bne @updateflames_skip_if_not_equal
dex
ldy #3 + 64
@updateflames_skip_if_not_equal:
sty TEMP_BYTE
ldy TEMP_BYTE_1
lda ONSCREEN_Y,Y
clc
adc #SPRITE_Y_DISPLACE
tay
lda #149
jsr pokesprite
@updateflames_skip_if_not_equal_2:
jmp backfromscreenrou
updatespit:
ldx ONSCREEN_COUNTER_2,Y
lda spitdelay,X
and FRAME_COUNTER
bne endspitter
jsr calconscreenx
ldx #NUMBER_OF_SPITTERS - 1
findspitterslot:
lda SPITTER_Y,X
beq gotspitter
dex
bpl findspitterslot
beq endspitter
gotspitter:
lda ONSCREEN_X_LOW,Y
sta SPITTER_X_LOW,X
lda ONSCREEN_X_HIGH,Y
sta SPITTER_X_HIGH,X
lda ONSCREEN_Y,Y
clc
adc #8
sta SPITTER_Y,X
lda ONSCREEN_COUNTER_1,Y
sta SPITTER_DIRECTION,X
lda #SFX_SPIT
jsr soundfx
endspitter:
jmp backfromscreenrou
spitdelay:
.byte $FF
.byte $7F
.byte $FF
.byte $FF
.byte $7F
.byte $FF
.byte $FF
.byte $7F
updateeyes:
lda FRAME_COUNTER
and #3
bne @updateeyes_skip_if_not_equal
lda ONSCREEN_COUNTER_1,Y
sec
sbc #1
sta ONSCREEN_COUNTER_1,Y
bne @updateeyes_skip_if_not_equal
lda RANDOM_SEED
sta ONSCREEN_COUNTER_1,Y
lda ONSCREEN_COUNTER_2,Y
eor #255
sta ONSCREEN_COUNTER_2,Y
@updateeyes_skip_if_not_equal:
lda ONSCREEN_COUNTER_2,Y
bmi @updateeyes_skip_if_negative
jsr calconscreenx
lda ONSCREEN_COUNTER_2,Y
sta TEMP_BYTE
lda ONSCREEN_Y,Y
tay
lda TEMP_BYTE
clc
adc #SPRITE_EYES
jsr winprintsprite
@updateeyes_skip_if_negative:
backfromscr:
jmp backfromscreenrou
updatedrips:
lda ONSCREEN_COUNTER_1,Y
bne firehappening
lda FRAME_COUNTER
clc
adc ONSCREEN_X_LOW,Y
and ONSCREEN_COUNTER_2,Y
bne enddrips
lda #SFX_BREATHING_FIRE
jsr soundfx
ldy TEMP_POINTER_9
lda #64
firehappening:
sec
sbc #1
sta ONSCREEN_COUNTER_1,Y
jsr calconscreenx
stx TEMP_POINTER_8
lda ONSCREEN_Y,Y
jsr pickupcollision
bcs @firehappening_skip_if_carry
tya
pha
lda #1
jsr subfromhearts
pla
tay
@firehappening_skip_if_carry:
lda ONSCREEN_Y,Y
sta TEMP_BYTE
lda ONSCREEN_COUNTER_1,Y
lsr
lsr
sta TEMP_BYTE_1
lsr
and #7
tay
lda firetable,Y
ldy TEMP_BYTE
lsr TEMP_BYTE_1
jsr winprintspriteposrev
enddrips:
jmp backfromscreenrou
firetable:
.byte <(SPRITE_FIRE)
.byte <(SPRITE_FIRE + 1)
.byte <(SPRITE_FIRE + 2)
.byte <(SPRITE_FIRE + 3)
.byte <(SPRITE_FIRE + 4)
.byte <(SPRITE_FIRE + 3)
.byte <(SPRITE_FIRE + 2)
.byte <(SPRITE_FIRE + 1)
updatetramp:
jsr calconscreenx
stx TEMP_POINTER_8
lda SPRITE_X_COORD_HIGH
bne endtramp
lda PLAYER_GRAVITY
clc
adc #2
bmi endtramp
lda ONSCREEN_Y,Y
clc
adc #16
jsr pickupcollision
bcs endtramp
lda #0
sec
sbc PLAYER_GRAVITY
cmp #($E8)
bcc @updatetramp_skip_if_no_carry
sta PLAYER_GRAVITY
@updatetramp_skip_if_no_carry:
jsr checkleftrightkeys
jsr addleftright1
lda PREVIOUS_PLAYER_X_LOW
sta PLAYER_X_LOW
lda PREVIOUS_PLAYER_X_LOW + 1
sta PLAYER_X_LOW + 1
lda #SFX_TRAMPOLINE
jsr soundfx
ldy TEMP_POINTER_9
lda #1
sta PLAYER_JUMPING
lda #($FA)
sta ONSCREEN_COUNTER_1,Y
endtramp:
lda ONSCREEN_Y,Y
sta TEMP_POINTER_8 + 1
lda ONSCREEN_COUNTER_1,Y
bpl @endtramp_skip_if_positive
ldx TEMP_POINTER_9
inc ONSCREEN_COUNTER_1,X
lda #SPRITE_TRAMPOLINE + 1
bne @endtramp_skip_if_not_equal
@endtramp_skip_if_positive:
lda #SPRITE_TRAMPOLINE
@endtramp_skip_if_not_equal:
ldx TEMP_POINTER_8
ldy TEMP_POINTER_8 + 1
jsr winprintsprite
jmp backfromscreenrou
updatedrilldown:
jsr calconscreenx
lda #128
sta TEMP_POINTER_7 + 1
lda #($FF)
jsr standarddrill
ldx SPRITE_X_COORD_HIGH
bne enddrilldown
cpy TEMP_POINTER_8 + 1
bcc enddrilldown
@updatedrilldown_loop:
ldx TEMP_POINTER_8
jsr pokesprite
tya
clc
adc #($F8)
tay
lda #190
cpy TEMP_POINTER_8 + 1
bcs @updatedrilldown_loop
enddrilldown:
jmp backfromscreenrou
updatedrillup:
jsr calconscreenx
lda #0
sta TEMP_POINTER_7 + 1
lda #1
jsr standarddrill
ldx SPRITE_X_COORD_HIGH
bne enddrillup
@updatedrillup_loop:
ldx TEMP_POINTER_8
jsr pokesprite
tya
clc
adc #8
tay
lda #190
cpy TEMP_POINTER_8 + 1
bcc @updatedrillup_loop
enddrillup:
jmp backfromscreenrou
standarddrill:
sta TEMP_POINTER_7
stx TEMP_POINTER_8
lda ONSCREEN_COUNTER_2,Y
and #64
beq @standarddrill_skip_if_equal
lda FRAME_COUNTER
bne printdrillup
@standarddrill_body:
lda ONSCREEN_COUNTER_2,Y
and #255 - 64
sta ONSCREEN_COUNTER_2,Y
@standarddrill_skip_if_equal:
lda ONSCREEN_COUNTER_2,Y
and #7
sta TEMP_BYTE
asl
clc
adc TEMP_BYTE
tax
lda drillerpatterns + 1,X
sta TEMP_POINTER_6 + 1
lda drillerpatterns + 2,X
eor FRAME_COUNTER
sta TEMP_POINTER_6
lda ONSCREEN_COUNTER_2,Y
bpl movingdrill
lda TEMP_POINTER_6
cmp drillerpatterns,X
bne contdrill
lda ONSCREEN_COUNTER_2,Y
eor #128
sta ONSCREEN_COUNTER_2,Y
movingdrill:
lda TEMP_POINTER_6
bmi drillcomingdown
and TEMP_POINTER_6 + 1
bne contdrill
lda ONSCREEN_COUNTER_1,Y
sec
sbc TEMP_POINTER_7
sta ONSCREEN_COUNTER_1,Y
jmp contdrill
drillcomingdown:
and TEMP_POINTER_6 + 1
bne contdrill
lda ONSCREEN_COUNTER_1,Y
clc
adc TEMP_POINTER_7
sta ONSCREEN_COUNTER_1,Y
cmp ONSCREEN_Y,Y
bne contdrill
lda ONSCREEN_COUNTER_2,Y
eor #128
sta ONSCREEN_COUNTER_2,Y
contdrill:
ldx TEMP_POINTER_8
lda ONSCREEN_COUNTER_1,Y
tay
jsr checkchrcollision
ldy TEMP_POINTER_9
printdrillup:
lda SPRITE_X_COORD_HIGH
bne @printdrillup_skip_if_not_equal
lda #1 + 32
clc
adc TEMP_POINTER_7 + 1
sta TEMP_BYTE
lda ONSCREEN_Y,Y
clc
adc #SPRITE_Y_DISPLACE
sta TEMP_POINTER_8 + 1
tay
ldx TEMP_POINTER_8
lda #127
jsr pokesprite
@printdrillup_skip_if_not_equal:
ldy TEMP_POINTER_9
lda TEMP_POINTER_6
asl
asl
asl
asl
and #64
clc
adc #2
clc
adc TEMP_POINTER_7 + 1
sta TEMP_BYTE
lda ONSCREEN_COUNTER_1,Y
clc
adc #SPRITE_Y_DISPLACE
tay
lda #189
rts
drillerpatterns:
.byte $40
.byte $01
.byte $00
.byte $20
.byte $01
.byte $FF
.byte $40
.byte $03
.byte $00
.byte $28
.byte $03
.byte $FF
.byte $28
.byte $01
.byte $00
.byte $40
.byte $01
.byte $FF
.byte $20
.byte $03
.byte $00
.byte $40
.byte $03
.byte $FF
updatebat:
lda FRAME_COUNTER
and #1
bne @updatebat_skip_if_not_equal
jsr movebat
@updatebat_skip_if_not_equal:
batnotmoving:
lda ONSCREEN_Y,Y
sta TEMP_POINTER_8 + 1
lda ONSCREEN_X_LOW,Y
sta TEMP_POINTER_7
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_8
lda ONSCREEN_X_HIGH,Y
sta TEMP_POINTER_7 + 1
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
lda ONSCREEN_Y,Y
sec
sbc ARROW_Y
clc
adc #4
cmp #16
bcs missedbat
jsr collidebatwitharrow
bcs missedbat
ldx #0
jsr takearrowoffrou
lda #SFX_BAT_HIT
jsr soundfx
turnoffbat:
ldy TEMP_POINTER_9
lda #4
jsr startstars
lda #65
jsr addtoscore
ldy TEMP_POINTER_9
jmp turnoffdouble
missedbat:
ldx TEMP_POINTER_8
lda SPRITE_X_COORD_HIGH
bne @missedbat_skip_if_not_equal
ldy TEMP_POINTER_8 + 1
jsr checkchrcollision
bcs turnoffbat
bcc @missedbat_skip_if_no_carry
@missedbat_skip_if_not_equal:
clc
adc #1
cmp #3
bcc @missedbat_skip_if_no_carry
jmp turnoffdouble
@missedbat_skip_if_no_carry:
ldy TEMP_POINTER_8 + 1
ldx TEMP_POINTER_8
lda FRAME_COUNTER
lsr
lsr
and #1
batonwall:
clc
adc #SPRITE_BAT
jsr winprintsprite
jmp backfromscreenrou
movebat:
@movebat_body:
lda ONSCREEN_X_LOW,Y
and #7
bne bat_x_ok
lda ONSCREEN_Y,Y
sta TEMP_POINTER_7
lda ONSCREEN_X_HIGH,Y
tax
lda ONSCREEN_COUNTER_1,Y
beq now_bat_y
bmi bat_negative_x
lda ONSCREEN_X_LOW,Y
clc
adc #8
bcc apply_bat_x_delta
inx
jmp apply_bat_x_delta
bat_negative_x:
lda ONSCREEN_X_LOW,Y
sec
sbc #8
bcs apply_bat_x_delta
dex
apply_bat_x_delta:
ldy TEMP_POINTER_7
jsr findsolid
ldy TEMP_POINTER_9
cmp #3
bne bat_x_ok
lda #0
sec
sbc ONSCREEN_COUNTER_1,Y
sta ONSCREEN_COUNTER_1,Y
bat_x_ok:
ldx #0
lda ONSCREEN_COUNTER_1,Y
bpl @bat_x_ok_skip_if_positive
ldx #255
@bat_x_ok_skip_if_positive:
clc
adc ONSCREEN_X_LOW,Y
sta ONSCREEN_X_LOW,Y
txa
adc ONSCREEN_X_HIGH,Y
sta ONSCREEN_X_HIGH,Y
now_bat_y:
lda ONSCREEN_Y,Y
clc
adc #($F8)
ldx ONSCREEN_COUNTER_2,Y
cpx #0
beq bat_y_ok
bmi bat_negative_y
clc
adc #16
bat_negative_y:
sta TEMP_POINTER_7
lda ONSCREEN_X_LOW,Y
ldx ONSCREEN_X_HIGH,Y
ldy TEMP_POINTER_7
jsr findsolid
ldy TEMP_POINTER_9
cmp #3
bne bat_y_ok
lda #0
sec
sbc ONSCREEN_COUNTER_2,Y
sta ONSCREEN_COUNTER_2,Y
bat_y_ok:
lda ONSCREEN_COUNTER_2 + 1,Y
clc
adc #1
sta ONSCREEN_COUNTER_2 + 1,Y
lsr
lsr
lsr
and #7
tax
lda batwobble,X
@bat_y_ok_body:
clc
adc ONSCREEN_COUNTER_2,Y
clc
adc ONSCREEN_Y,Y
sta ONSCREEN_Y,Y
done_bat_y:
@return_from_done_bat_y:
rts
batwobble:
.byte $00
.byte $01
.byte $01
.byte $00
.byte $00
.byte $FF
.byte $FF
.byte $00
updaterat:
lda ONSCREEN_X_HIGH,Y
sec
sbc SCREEN_X_HIGH
clc
adc #2
cmp #5
bcc @updaterat_skip_if_no_carry
lda #0
sta ONSCREEN_ROUTINE,Y
jmp backfromscreenrou
@updaterat_skip_if_no_carry:
lda ONSCREEN_COUNTER_2,Y
and #7
and FRAME_COUNTER
bne @updaterat_skip_if_not_equal_2
lda ONSCREEN_COUNTER_2,Y
bmi @updaterat_skip_if_negative
lda ONSCREEN_COUNTER_1,Y
clc
adc #1
bne @updaterat_skip_if_not_equal
@updaterat_loop:
lda ONSCREEN_COUNTER_2,Y
eor #128
sta ONSCREEN_COUNTER_2,Y
jmp @updaterat_skip_if_not_equal_2
@updaterat_skip_if_negative:
lda ONSCREEN_COUNTER_1,Y
clc
adc #($FF)
beq @updaterat_loop
@updaterat_skip_if_not_equal:
sta ONSCREEN_COUNTER_1,Y
@updaterat_skip_if_not_equal_2:
movedrat:
@movedrat_body:
lda ONSCREEN_COUNTER_1,Y
sta TEMP_BYTE_9
sec
sbc #128
php
clc
adc ONSCREEN_X_LOW,Y
sta TEMP_POINTER_8
lda ONSCREEN_X_HIGH,Y
adc #0
plp
sbc #0
sta TEMP_POINTER_8 + 1
tax
lda ONSCREEN_Y,Y
sta TEMP_BYTE_8
lda TEMP_POINTER_8
and #7
bne ratnothitwall
lda ONSCREEN_COUNTER_2,Y
and #128
eor #128
bpl @movedrat_skip_if_positive
lda #24
@movedrat_skip_if_positive:
clc
adc TEMP_POINTER_8
bcc @movedrat_skip_if_no_carry
inx
@movedrat_skip_if_no_carry:
sec
sbc #16
bcs @movedrat_skip_if_carry
dex
@movedrat_skip_if_carry:
stx TEMP_POINTER_7 + 1
sta TEMP_POINTER_7
ldy TEMP_BYTE_8
jsr findsolid
ldy TEMP_POINTER_9
cmp #3
beq rathitwall
ldx TEMP_POINTER_7 + 1
lda TEMP_BYTE_8
clc
adc #16
tay
lda TEMP_POINTER_7
jsr findsolid
ldy TEMP_POINTER_9
cmp #0
bne ratnothitwall
rathitwall:
lda ONSCREEN_COUNTER_2,Y
eor #128
sta ONSCREEN_COUNTER_2,Y
ratnothitwall:
lda ONSCREEN_COUNTER_2,Y
lsr
and #64
clc
adc #1
sta TEMP_BYTE
lda TEMP_POINTER_8
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_7
tax
lda TEMP_POINTER_8 + 1
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
lda ONSCREEN_Y,Y
sta TEMP_POINTER_7 + 1
clc
adc #4
tay
ldx TEMP_POINTER_7
lda SPRITE_X_COORD_HIGH
bne @ratnothitwall_skip_if_not_equal
jsr checkchrcollision
ldx TEMP_POINTER_7
lda TEMP_POINTER_7 + 1
clc
adc #8
tay
lda TEMP_BYTE_9
asl
and #4
clc
adc #144
cmp #144
beq @ratnothitwall_skip_if_equal
lda #200
@ratnothitwall_skip_if_equal:
jsr pokesprite2by2
@ratnothitwall_skip_if_not_equal:
jmp backfromscreenrou
updatespider:
jsr calconscreenx
stx TEMP_POINTER_8
lda ONSCREEN_COUNTER_1,Y
sta TEMP_BYTE_1
clc
adc ONSCREEN_Y,Y
clc
adc #8
sta TEMP_BYTE_9
lda ONSCREEN_Y,Y
clc
adc #SPRITE_Y_DISPLACE
sta TEMP_POINTER_8 + 1
lda ONSCREEN_COUNTER_2,Y
bpl spidergoingdown
lda FRAME_COUNTER
and #3
bne movedspider
lda ONSCREEN_COUNTER_1,Y
clc
adc #($FF)
sta ONSCREEN_COUNTER_1,Y
beq spiderchange
lda ONSCREEN_COUNTER_2,Y
and #1
beq movedspider
lda FRAME_COUNTER
beq spiderchange
bne movedspider
spidergoingdown:
lda ONSCREEN_COUNTER_1,Y
clc
adc #1
sta ONSCREEN_COUNTER_1,Y
and #7
bne movedspider
lda TEMP_BYTE_9
clc
adc #16
sta TEMP_BYTE
ldx ONSCREEN_X_HIGH,Y
lda ONSCREEN_X_LOW,Y
ldy TEMP_BYTE
jsr findsolid
ldy TEMP_POINTER_9
cmp #0
beq movedspider
spiderchange:
lda ONSCREEN_COUNTER_2,Y
eor #128
sta ONSCREEN_COUNTER_2,Y
movedspider:
lda TEMP_BYTE_9
jsr pickupcollision
bcs printspider
lda #1
jsr subfromhearts
ldy TEMP_POINTER_9
printspider:
lda ONSCREEN_COUNTER_2,Y
and #1
bne @printspider_skip_if_not_equal
lda #152
sta TEMP_POINTER_7
ldx #2
lda #179
bne @printspider_skip_if_not_equal_2
@printspider_skip_if_not_equal:
lda #148
sta TEMP_POINTER_7
ldx #1
lda ONSCREEN_COUNTER_1,Y
and #2
clc
adc #164
cmp #164
beq @printspider_skip_if_not_equal_2
lda #242
@printspider_skip_if_not_equal_2:
stx TEMP_POINTER_7 + 1
stx TEMP_BYTE
ldy TEMP_BYTE_9
ldx SPRITE_X_COORD_HIGH
bne @printspider_skip_if_not_equal_3
ldx TEMP_POINTER_8
jsr pokesprite2by2
@printspider_skip_if_not_equal_3:
lda TEMP_POINTER_8
clc
adc #($FC)
sta TEMP_POINTER_8
bcs @printspider_skip_if_carry
dec SPRITE_X_COORD_HIGH
@printspider_skip_if_carry:
lda SPRITE_X_COORD_HIGH
bne endspider
lda TEMP_POINTER_7 + 1
sta TEMP_BYTE
lda TEMP_BYTE_9
clc
adc #($FC)
tay
cmp #8
bcc endspider
drawchain:
ldx TEMP_POINTER_8
lda TEMP_POINTER_7
jsr pokesprite
tya
sec
sbc #8
tay
cmp TEMP_POINTER_8 + 1
bcs drawchain
lda TEMP_POINTER_7 + 1
clc
adc #32
sta TEMP_BYTE
ldx TEMP_POINTER_8
lda TEMP_POINTER_7
jsr pokesprite
endspider:
jmp backfromscreenrou
updatebarrel:
lda ONSCREEN_Y + 1,Y
bne barrelmoving
lda ONSCREEN_X_LOW,Y
sec
sbc SCREEN_X_LOW
lda ONSCREEN_X_HIGH,Y
sbc SCREEN_X_HIGH
clc
adc #1
cmp #3
bcc dontturnoffbarrel
turnoffdouble:
lda #0
sta ONSCREEN_ROUTINE,Y
sta ONSCREEN_ROUTINE + 1,Y
jmp backfromscreenrou
dontturnoffbarrel:
lda ONSCREEN_Y,Y
clc
adc #1
sta ONSCREEN_Y + 1,Y
lda ONSCREEN_X_LOW,Y
sta ONSCREEN_X_LOW + 1,Y
lda ONSCREEN_X_HIGH,Y
sta ONSCREEN_X_HIGH + 1,Y
lda ONSCREEN_COUNTER_2 + 1,Y
sta ONSCREEN_COUNTER_1,Y
lda #0
sta ONSCREEN_COUNTER_1 + 1,Y
barrelmoving:
lda ONSCREEN_X_LOW + 1,Y
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_7
lda ONSCREEN_X_HIGH + 1,Y
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
jsr movebarrel
lda ONSCREEN_Y + 1,Y
sta TEMP_POINTER_7 + 1
ldx TEMP_POINTER_7
lda ONSCREEN_COUNTER_2,Y
bne @barrelmoving_skip_if_not_equal
lda SPRITE_X_COORD_HIGH
bne endbarrel
lda #2
sta TEMP_BYTE
lda #175
ldy TEMP_POINTER_7 + 1
beq endbarrel
jsr pokesprite2by2
jmp backfromscreenrou
@barrelmoving_skip_if_not_equal:
lda TEMP_POINTER_7
lsr
lsr
and #3
clc
adc #SPRITE_BARRELS
@barrelmoving_body:
ldy TEMP_POINTER_7 + 1
beq endbarrel
jsr winprintsprite
endbarrel:
jmp backfromscreenrou
movebarrel:
ldx ONSCREEN_COUNTER_1,Y
stx TEMP_BYTE_9
inx
lda ONSCREEN_X_LOW + 1,Y
clc
adc ONSCREEN_COUNTER_1,Y
sta ONSCREEN_X_LOW + 1,Y
lda ONSCREEN_X_HIGH + 1,Y
adc high_bit_add_table,X
sta ONSCREEN_X_HIGH + 1,Y
lda ONSCREEN_COUNTER_1 + 1,Y
beq @movebarrel_skip_if_equal
bmi @movebarrel_skip_if_negative
lsr
lsr
jmp @movebarrel_skip
@movebarrel_skip_if_negative:
eor #255
clc
adc #1
lsr
lsr
eor #255
clc
adc #1
@movebarrel_skip:
clc
adc ONSCREEN_Y + 1,Y
sta ONSCREEN_Y + 1,Y
tax
cpx #192
bcc @movebarrel_skip_if_equal
lda ONSCREEN_COUNTER_1 + 1,Y
clc
adc #1
sta ONSCREEN_COUNTER_1 + 1,Y
cpx #232
bcc @movebarrel_skip_if_no_carry
lda #0
sta ONSCREEN_Y + 1,Y
@movebarrel_skip_if_no_carry:
rts
@movebarrel_skip_if_equal:
ldx ONSCREEN_X_HIGH + 1,Y
lda ONSCREEN_COUNTER_1,Y
bne @movebarrel_skip_if_not_equal
lda ONSCREEN_X_LOW + 1,Y
and #7
bne barrelonfloor
@movebarrel_skip_if_not_equal:
lda ONSCREEN_Y + 1,Y
clc
adc #9
sta TEMP_BYTE
lda ONSCREEN_X_LOW + 1,Y
ldy TEMP_BYTE
jsr findsolid
ldy TEMP_POINTER_9
cmp #3
beq barrelonfloor
barrelfalling:
lda FRAME_COUNTER
and #1
bne donegrav
barreladdgrav:
lda ONSCREEN_COUNTER_1 + 1,Y
clc
adc #1
cmp #17
bne storegrav
lda #16
bne storegrav
barrelonfloor:
lda ONSCREEN_COUNTER_1 + 1,Y
bmi donegrav
cmp #4
bcc @barrelonfloor_skip_if_no_carry
lda SPRITE_X_COORD_HIGH
bne @barrelonfloor_skip_if_no_carry
lda #SFX_BALL_BOUNCE
jsr soundfx
@barrelonfloor_skip_if_no_carry:
lda ONSCREEN_COUNTER_1 + 1,Y
bmi donegrav
lsr
eor #255
clc
adc #1
storegrav:
sta ONSCREEN_COUNTER_1 + 1,Y
donegrav:
lda ONSCREEN_X_LOW + 1,Y
asl TEMP_BYTE_9
adc #0
and #3
bne barrelnothitwall
lda ONSCREEN_X_LOW + 1,Y
ldx ONSCREEN_COUNTER_1,Y
bmi @donegrav_skip_if_negative
clc
adc #8
jmp @donegrav_skip
@donegrav_skip_if_negative:
clc
adc #($F8)
@donegrav_skip:
sta TEMP_BYTE
inx
lda ONSCREEN_X_HIGH + 1,Y
adc high_bit_add_table,X
tax
lda ONSCREEN_Y + 1,Y
clc
adc #6
tay
lda TEMP_BYTE
jsr findsolid
ldy TEMP_POINTER_9
lda SOLID_TILE_FOUND
cmp #3
bne barrelnothitwall
barrelhitwall:
lda #0
sec
sbc ONSCREEN_COUNTER_1,Y
sta ONSCREEN_COUNTER_1,Y
jmp pastbarrelwall
barrelnothitwall:
pastbarrelwall:
nowcollidebarrelwithrobin:
lda SPRITE_X_COORD_HIGH
bne endbarrelmove
lda TEMP_POINTER_7
sec
sbc PLAYER_ONSCREEN_X
clc
adc #12
cmp #24
bcs endbarrelmove
lda ONSCREEN_Y + 1,Y
sec
sbc PLAYER_Y
clc
adc #32
cmp #30
bcc barrelhitrobin
ldx PLAYER_ON_LADDER
bne endbarrelmove
cmp #44
bcs endbarrelmove
@nowcollidebarrelwithrobin_body:
lda ONSCREEN_Y + 1,Y
clc
adc #($F7)
sta TEMP_POINTER_7 + 1
jsr robinjumpoffplatform
ldy TEMP_POINTER_9
rts
barrelhitrobin:
lda PLAYER_INVINCIBILITY_TIMER
bne endbarrelmove
lda #1
jsr subfromhearts
ldy TEMP_POINTER_9
endbarrelmove:
rts
updateblock:
jsr calconscreenx
jmp backfromscreenrou
updateheart:
updatecoin:
jsr calconscreenx
jsr change_bank13_routine
jsr restupdatecoin
jsr change_bank12_routine
jmp backfromscreenrou
