putextrason:
lda #0
sta EXTRA_VAR_POINTER
lda MAP_NUMBER
asl
tax
lda maprouspointer,X
sta TEMP_POINTER_9
lda maprouspointer + 1,X
sta TEMP_POINTER_9 + 1
anotherrou:
ldy #0
lda (TEMP_POINTER_9),Y
asl
tax
lda routinepointers,X
sta TEMP_POINTER_8
lda routinepointers + 1,X
sta TEMP_POINTER_8 + 1
iny
lda (TEMP_POINTER_9),Y
sta NUMBER_OF_PARAMETERS
iny
ldx EXTRA_VAR_POINTER
jmp (TEMP_POINTER_8)
backfromrou:
clc
adc EXTRA_VAR_POINTER
sta EXTRA_VAR_POINTER
backfromrounovars:
lda NUMBER_OF_PARAMETERS
clc
adc TEMP_POINTER_9
sta TEMP_POINTER_9
bcc @backfromrounovars_skip_if_no_carry
inc TEMP_POINTER_9 + 1
@backfromrounovars_skip_if_no_carry:
jmp anotherrou
endofrous:
cpx #NUMBER_OF_EXTRA_VARS
bcc @endofrous_skip_if_no_carry
jsr turninteron
@endofrous_skip:
php
pha
lda PPU_MASK_SHADOW
and #30
clc
adc #1
sta PPU_MASK_REGISTER
pla
plp
lda PPU_MASK_SHADOW
and #30
sta PPU_MASK_REGISTER
jmp @endofrous_skip
@endofrous_skip_if_no_carry:
rts
maprouspointer:
.word map1rous
.word map2rous
.word map3rous
.word map4rous
.word map5rous
.word map6rous
.word map7rous
.word map8rous
.word map9rous
.word map11rous
.word map12rous
.word map13rous
.word map14rous
EXTRA_TYPE_END = 0
EXTRA_TYPE_FLASH_BLOCK = 1
EXTRA_TYPE_STANDING_GUARD = 2
EXTRA_TYPE_PLATFORM_HORIZONTAL = 3
EXTRA_TYPE_PLATFORM_VERTICAL = 4
EXTRA_TYPE_KEY = 5
EXTRA_TYPE_CANNON = 6
EXTRA_TYPE_SECRET = 7
EXTRA_TYPE_MARIONETTE = 8
EXTRA_TYPE_WATER = 9
routinepointers:
.word endofrous
.word flashblock
.word standguard
.word platformh
.word platformv
.word key_routine
.word canonrou
.word secretrou
.word marionrou
.word redefinewaterbank
.include "build/objects.s"

NUMBER_OF_EXTRAS = 255
RAM_VAR EXTRAS_ON, 32
RAM_VAR SECRET_TABLE, 3 + 6 + 6
doordata:
.byte $05
.byte $0E
.byte $45
.byte $05
.byte $4F
.byte $2C
.byte $05
.byte $37
.byte $2C
.byte $04
.byte $1D
.byte $25
.byte $04
.byte $4A
.byte $23
.byte $04
.byte $4C
.byte $2B
.byte $00
.byte $1F
.byte $2B
.byte $00
.byte $31
.byte $24
.byte $03
.byte $0F
.byte $35
.byte $03
.byte $2F
.byte $3B
.byte $04
.byte $92
.byte $2C
.byte $07
.byte $92
.byte $28
.byte $07
.byte $4A
.byte $3C
.byte $0B
.byte $11
.byte $4C
.byte $06
.byte $61
.byte $4C
.byte $0B
.byte $17
.byte $23
.byte $05
.byte $80
.byte $1C
endofdoordata:
NUMBER_OF_DOORS = (endofdoordata - doordata) / 3 + 1
resetextravars:
lda #>(RESET_VARIABLES_START)
sta TEMP_POINTER + 1
lda #0
sta TEMP_POINTER
ldy #<(RESET_VARIABLES_START)
@resetextravars_loop:
sta (TEMP_POINTER),Y
iny
bne @resetextravars_skip_if_not_equal
inc TEMP_POINTER + 1
@resetextravars_skip_if_not_equal:
cpy #<(END_OF_RESET_VARIABLES)
bne @resetextravars_loop
ldx #>(END_OF_RESET_VARIABLES)
cpx TEMP_POINTER + 1
bne @resetextravars_loop
rts
resetextras:
lda #255
ldx #NUMBER_OF_EXTRAS / 8 + 1
@resetextras_loop:
sta EXTRAS_ON,X
dex
bpl @resetextras_loop
lda #0
ldx #3 + 6 + 6 - 1
@resetextras_loop_2:
sta SECRET_TABLE,X
dex
bpl @resetextras_loop_2
rts
pickupcollision1:
ldy #4
lda (TEMP_POINTER_9),Y
tay
pickupcollision:
bit PLAYER_CROUCHING
bmi crouchcollide
sec
sbc PLAYER_Y
clc
adc #32 + 2
cmp #40 + 2
bcs nopickcoll
bcc now_check_x
crouchcollide:
sec
sbc PLAYER_Y
clc
adc #32 + 8 - 16
cmp #40 + 8 - 16
bcs nopickcoll
now_check_x:
lda TEMP_POINTER_8
sec
sbc PLAYER_ONSCREEN_X
clc
adc #12
cmp #24
nopickcoll:
rts
bitpattern:
.byte $80
.byte $40
.byte $20
.byte $10
.byte $08
.byte $04
.byte $02
.byte $01
checkifextraon:
lda (TEMP_POINTER_9),Y
checkifdooron:
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda EXTRAS_ON,Y
and bitpattern,X
rts
turnoffextra:
ldy #2
lda (TEMP_POINTER_9),Y
turnoffdoor:
tay
and #7
tax
tya
lsr
lsr
lsr
tay
lda EXTRAS_ON,Y
eor bitpattern,X
sta EXTRAS_ON,Y
rts
checkonscreensides:
ldy #3
checkonscreensides1:
lda (TEMP_POINTER_9),Y
sec
sbc SCREEN_X_LOW
sta TEMP_POINTER_7
iny
lda (TEMP_POINTER_9),Y
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
clc
adc #1
cmp #3
rts
startstarstable:
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $33
.byte $80
.byte $04
.byte $00
.byte $10
.byte $10
.byte $04
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $35
.byte $81
.byte $00
.byte $00
.byte $04
.byte $1A
.byte $08
.byte $0D
.byte $04
.byte $13
.byte $00
.byte $06
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $32
.byte $83
.byte $FC
.byte $00
.byte $FC
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $9A
.byte $11
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $97
.byte $23
.byte $05
.byte $04
.byte $00
.byte $04
.byte $10
.byte $04
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $97
.byte $25
.byte $06
.byte $04
.byte $00
.byte $04
.byte $1A
.byte $04
.byte $0D
.byte $04
.byte $13
.byte $04
.byte $06
.byte $01
.byte $00
.byte $00
.byte $96
.byte $11
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $8C
.byte $31
.byte $04
.byte $04
.byte $10
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00
startstars:
sta TEMP_BYTE_2
ldx #0
lda HEART_TABLE,X
beq gotstarsx
ldx #16
lda HEART_TABLE,X
beq gotstarsx
ldx #32
lda HEART_TABLE,X
beq gotstarsx
ldx #0
gotstarsx:
stx TEMP_BYTE_1
lda TEMP_BYTE_2
asl
asl
asl
asl
tay
lda #16
sta TEMP_BYTE_2
@gotstarsx_loop:
lda startstarstable,Y
sta HEART_TABLE,X
iny
inx
dec TEMP_BYTE_2
bne @gotstarsx_loop
ldx TEMP_BYTE_1
lda TEMP_POINTER_8 + 1
sta HEART_TABLE + 2,X
lda TEMP_POINTER_7
sta HEART_TABLE + 0,X
lda TEMP_POINTER_7 + 1
sta HEART_TABLE + 1,X
rts
doorrou:
lda ANIMATED_DOOR
beq enddoor
and #7
bne donedoor
lda #SFX_DOOR_LIFTING
jsr soundfx
lda ANIMATED_DOOR
cmp #8
beq finishdoor
and #15
beq over_boundary
ldx DOOR_X
ldy DOOR_Y
lda #1
jsr addachangedblock
jmp donedoor
over_boundary:
ldx DOOR_X
ldy DOOR_Y
dey
lda #2
jsr addachangedblock
finishdoor:
ldx DOOR_X
ldy DOOR_Y
jsr deleteachangedblock
dec DOOR_Y
donedoor:
dec ANIMATED_DOOR
enddoor:
rts
closedoor:
ldx DOOR_X
ldy DOOR_Y
lda #2
jsr addachangedblock
dec DOOR_Y
@closedoor_loop:
ldx DOOR_X
ldy DOOR_Y
lda #3
jsr addachangedblock
dec DOOR_Y
lda ANIMATED_DOOR
clc
adc #($F0)
sta ANIMATED_DOOR
cmp #8
bne @closedoor_loop
@closedoor_done:
rts
openadoor:
sta TEMP_BYTE
jsr turnoffdoor
openadoor1:
lda #255
sec
sbc TEMP_BYTE
sta TEMP_BYTE_1
asl
clc
adc TEMP_BYTE_1
tax
lda doordata,X
cmp MAP_NUMBER
bne @openadoor1_skip_if_not_equal
lda doordata + 2,X
and #15
sta DOOR_Y
lda doordata + 2,X
and #240
clc
adc #8
sta ANIMATED_DOOR
lda doordata + 1,X
sta DOOR_X
lda #0
@openadoor1_skip_if_not_equal:
rts
resetdoorsintomap:
lda #255
@resetdoorsintomap_loop:
sta TEMP_BYTE
jsr checkifdooron
beq @resetdoorsintomap_skip_if_equal
jsr openadoor1
bne @resetdoorsintomap_skip_if_equal
@resetdoorsintomap_body:
lda TEMP_BYTE
pha
jsr closedoor
pla
sta TEMP_BYTE
@resetdoorsintomap_skip_if_equal:
dec TEMP_BYTE
lda TEMP_BYTE
cmp #255 - NUMBER_OF_DOORS
bne @resetdoorsintomap_loop
rts
robinshootarrow:
lda PLAYER_X_LOW
sta ARROW_X_LOW
lda PLAYER_X_HIGH
sta ARROW_X_HIGH
lda PLAYER_Y
clc
adc #($E8)
sta ARROW_Y
ldx #4
lda OLD_PLAYER_FACING
bpl @robinshootarrow_skip_if_positive
ldx #($FC)
lda ARROW_X_LOW
sec
sbc #8
sta ARROW_X_LOW
bcs @robinshootarrow_skip_if_positive
dec ARROW_X_HIGH
@robinshootarrow_skip_if_positive:
stx ARROW_DIRECTION
lda #40
sta ARROW_COUNTER
rts
shootarrow:
sta TEMP_BYTE
ldx #1
@shootarrow_loop:
lda ARROW_COUNTER,X
beq gotarrowpos
inx
cpx #NUMBER_OF_ARROWS
bne @shootarrow_loop
rts
gotarrowpos:
lda (TEMP_POINTER_9),Y
ldy #0
sta ARROW_DIRECTION,X
cmp #0
bpl @gotarrowpos_skip_if_positive
ldy #255
@gotarrowpos_skip_if_positive:
lda #100
sta ARROW_COUNTER,X
lda #0
sta ARROW_CANNON,X
lda ARROW_DIRECTION,X
asl
asl
clc
adc TEMP_POINTER_7
sta ARROW_X_LOW,X
tya
adc TEMP_POINTER_7 + 1
sta ARROW_X_HIGH,X
lda TEMP_BYTE
sta ARROW_Y,X
rts
addarrowdir:
lda ARROW_DIRECTION,X
bpl @addarrowdir_skip_if_positive
lda ARROW_X_LOW,X
clc
adc ARROW_DIRECTION,X
sta ARROW_X_LOW,X
bcs @addarrowdir_skip_if_carry
dec ARROW_X_HIGH,X
@addarrowdir_skip_if_carry:
jmp @addarrowdir_skip
@addarrowdir_skip_if_positive:
lda ARROW_X_LOW,X
clc
adc ARROW_DIRECTION,X
sta ARROW_X_LOW,X
bcc @addarrowdir_skip
inc ARROW_X_HIGH,X
@addarrowdir_skip:
rts
updatearrows:
ldx #0
doeacharrow:
lda ARROW_COUNTER,X
beq @doeacharrow_skip_if_equal
bpl @doeacharrow_skip_if_positive
@doeacharrow_skip_if_equal:
jmp nextarrow
@doeacharrow_skip_if_positive:
dec ARROW_COUNTER,X
contarrow:
jsr addarrowdir
printarrow:
stx TEMP_X
lda ARROW_X_HIGH,X
sta TEMP_BYTE
lda ARROW_X_LOW,X
clc
adc #4
bcc @printarrow_skip_if_no_carry
inc TEMP_BYTE
@printarrow_skip_if_no_carry:
ldy ARROW_Y,X
iny
iny
iny
iny
iny
iny
ldx TEMP_BYTE
jsr findsolid
cmp #3
bne arrownothitwall
takearrowoff:
lda #SFX_ARROW_HIT_WALL
jsr soundfx
takearrowoff1:
ldx TEMP_X
jsr takearrowoffrou
jmp nextarrow
arrownothitwall:
ldx TEMP_X
lda ARROW_X_LOW,X
sec
sbc SCREEN_X_LOW
sta TEMP_Y
lda ARROW_X_HIGH,X
sbc SCREEN_X_HIGH
bne nextarrow
lda ARROW_DIRECTION,X
and #64
eor ARROW_CANNON,X
sta TEMP_BYTE
lda ARROW_Y,X
clc
adc #SPRITE_Y_DISPLACE
tay
lda ARROW_CANNON,X
beq isanarrow
lda #150 - 121
isanarrow:
clc
adc #121
ldx TEMP_Y
jsr pokesprite
ldx TEMP_X
beq nextarrow
lda ARROW_Y,X
clc
adc #6
sec
sbc PLAYER_Y
bcs arrownothitrobin
lda ARROW_Y,X
clc
adc #2
sec
sbc PLAYER_HEIGHT
bcc arrownothitrobin
lda TEMP_Y
sec
sbc PLAYER_ONSCREEN_X
clc
adc #12
cmp #24
bcs arrownothitrobin
lda PLAYER_INVINCIBILITY_TIMER
bne arrownothitrobin
lda #1
jsr subfromhearts
jmp takearrowoff1
arrownothitrobin:
nextarrow:
inx
cpx #NUMBER_OF_ARROWS
beq @nextarrow_skip_if_equal
jmp doeacharrow
@nextarrow_skip_if_equal:
lda DEAD_ARROW_COUNT
beq @nextarrow_skip_if_equal_2
dec DEAD_ARROW_COUNT
lda DEAD_ARROW_X
sec
sbc SCREEN_X_LOW
tax
lda DEAD_ARROW_X + 1
sbc SCREEN_X_HIGH
sta SPRITE_X_COORD_HIGH
ldy DEAD_ARROW_Y
lda DEAD_ARROW_COUNT
lsr
clc
adc #SPRITE_DEAD_ARROWS
jsr winprintsprite
@nextarrow_skip_if_equal_2:
rts
takearrowoffrou:
lda ARROW_X_LOW,X
sta DEAD_ARROW_X
lda ARROW_X_HIGH,X
sta DEAD_ARROW_X + 1
lda ARROW_Y,X
sta DEAD_ARROW_Y
lda #8
sta DEAD_ARROW_COUNT
lda #0
sta ARROW_Y,X
sta ARROW_COUNTER,X
rts
dectiming:
ldx EXTRA_VAR_POINTER
lda EXTRA_VARS,X
beq dotimingproblem
lda FRAME_COUNTER
and #7
bne @dectiming_skip_if_not_equal
dec EXTRA_VARS,X
@dectiming_skip_if_not_equal:
rts
dotimingproblem:
tya
eor #255
clc
adc NUMBER_OF_PARAMETERS
sta TEMP_BYTE
ldx EXTRA_VAR_POINTER
inc EXTRA_VARS + 1,X
lda EXTRA_VARS + 1,X
cmp TEMP_BYTE
bne @dotimingproblem_skip_if_not_equal
lda #0
sta EXTRA_VARS + 1,X
@dotimingproblem_skip_if_not_equal:
sta TEMP_BYTE
inc TEMP_BYTE
@dotimingproblem_loop:
iny
dec TEMP_BYTE
bne @dotimingproblem_loop
lda (TEMP_POINTER_9),Y
sta EXTRA_VARS,X
rts
