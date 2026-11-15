SFX_PICKUP_HEART = 1
SFX_PICKUP_TREASURE = 1
SFX_PICKUP_KEY = 17
SFX_KILL_YOU_TOTALLY = 30
SFX_KILL_YOU = 28
SFX_KILL_THEM_TOTALLY = 29
SFX_KILL_THEM = 27
SFX_DOOR_LIFTING = 4
SFX_ARROW_HIT_WALL = 32
SFX_SPIT = 33
SFX_BAT_HIT = 26
SFX_TRAMPOLINE = 21
SFX_THEM_FIRING = 11
SFX_BREATHING_FIRE = 8
SFX_BALL_BOUNCE = 16
SFX_BAT_SQUEAL = 15
SFX_RAT_SQUEAL = 34
SFX_FIRST_APPEAR = 2
SFX_EXTRA_LIFE = 36
SFX_CHOOSE_LETTER = 35
SFX_DELETE_LETTER = 6
SFX_LEFT_RIGHT_LETTER = 5
SFX_YOU_FIRING = 11
ZP_VAR SFX_TEMP
ZP_VAR SFX_ADDRESS_1_LOW
ZP_VAR SFX_ADDRESS_1_HIGH
SFX_ADDRESS_1 = SFX_ADDRESS_1_LOW
ZP_VAR SFX_FREQUENCY_ADDRESS_1_LOW
ZP_VAR SFX_FREQUENCY_ADDRESS_1_HIGH
SFX_FREQUENCY_ADDRESS_1 = SFX_FREQUENCY_ADDRESS_1_LOW
ZP_VAR SFX_ADDRESS_2_LOW
ZP_VAR SFX_ADDRESS_2_HIGH
SFX_ADDRESS_2 = SFX_ADDRESS_2_LOW
ZP_VAR SFX_FREQUENCY_ADDRESS_2_LOW
ZP_VAR SFX_FREQUENCY_ADDRESS_2_HIGH
SFX_FREQUENCY_ADDRESS_2 = SFX_FREQUENCY_ADDRESS_2_LOW
RAM_VAR SFX_COUNTER
RAM_VAR SFX_TEMP_RAM, 2
RAM_VAR SFX_VOLUME_1, 4
RAM_VAR SFX_VOLUME_2, 4
RAM_VAR SFX_VOLUME, 4
RAM_VAR SFX_ATTACK, 4
RAM_VAR SFX_DELAY, 4
RAM_VAR SFX_TIME, 4
RAM_VAR SFX_PULSE, 4
RAM_VAR SFX_ON, 4
RAM_VAR SFX_DATA_1, 4
RAM_VAR SFX_POSITION, 4
RAM_VAR SFX_POINTER_LOW, 4
RAM_VAR SFX_POINTER_HIGH, 4
RAM_VAR SFX_CYCLES, 4
RAM_VAR SFX_PRIORITY, 4
RAM_VAR SFX_VOICES, 16
RAM_VAR SFX_REAL_SAVE
SFX_TO_DO .set 23
fx_table:
.word @tap
.word @ping
.word @whoosh
.word @click2
.word @click
.word @blip
.word @delete
.word @thud
.word @breath
.word @siren
.word @sirenb
.word @bang1
.word @bang2
.word @thud2
.word @bang3
.word @bat_squeak
.word @bounce
.word @pinga
.word @pingb
.word @haha
.word @hoho
.word @boing
.word @metal2
.word @drop_em
.word @splash
.word @explode1
.word @explode3
.word @explode2
.word @explode4
.word @major
.word @very_major
.word @biggie
.word @arrow
.word @spit
.word @rat_squeak
.word @choose_letter
.word @extra_life
.word @metal_ball
@tap:
.byte $0A
.byte $03
.byte $01
.byte $C0
.byte $0F
.byte $54
.byte $01
.byte $03
.byte $02
.byte $00
@ping:
.byte $0A
.byte $02
.byte $0A
.byte $80
.byte $0D
.byte $30
.byte $04
.byte $00
.byte $05
.byte $03
.byte $34
.byte $01
.byte $04
.byte $00
.byte $05
.byte $03
.byte $37
.byte $01
.byte $04
.byte $00
.byte $05
.byte $03
.byte $3C
.byte $01
.byte $04
.byte $00
.byte $05
.byte $00
@ping2:
.byte $0A
.byte $01
.byte $0D
.byte $80
.byte $04
.byte $28
.byte $04
.byte $00
.byte $14
.byte $00
@whoosh:
.byte $28
.byte $03
.byte $4F
.byte $00
.byte $0A
.byte $1B
.byte $06
.byte $01
.byte $28
.byte $00
@click:
.byte $0A
.byte $02
.byte $00
.byte $00
.byte $0F
.byte $43
.byte $07
.byte $03
.byte $01
.byte $02
.byte $48
.byte $02
.byte $00
@click2:
.byte $0A
.byte $03
.byte $0F
.byte $00
.byte $0F
.byte $22
.byte $04
.byte $00
.byte $04
.byte $00
@blip:
.byte $0A
.byte $02
.byte $01
.byte $C0
.byte $0A
.byte $3E
.byte $04
.byte $00
.byte $01
.byte $00
@delete:
.byte $0A
.byte $01
.byte $0D
.byte $80
.byte $0F
.byte $24
.byte $02
.byte $87
.byte $03
.byte $00
@thud:
.byte $0A
.byte $02
.byte $00
.byte $00
.byte $0F
.byte $23
.byte $02
.byte $50
.byte $01
.byte $00
@arrow:
.byte $0A
.byte $03
.byte $00
.byte $00
.byte $0F
.byte $3C
.byte $03
.byte $3A
.byte $01
.byte $00
@spit:
.byte $0A
.byte $03
.byte $01
.byte $00
.byte $0F
.byte $31
.byte $02
.byte $64
.byte $05
.byte $00
@breath:
.byte $0A
.byte $03
.byte $6F
.byte $00
.byte $0F
.byte $21
.byte $04
.byte $00
.byte $1E
.byte $00
@siren:
.byte $0A
.byte $00
.byte $0F
.byte $00
.byte $88
.byte $18
.byte $07
.byte $0A
.byte $01
.byte $01
.byte $06
.byte $1E
.byte $00
@sirenb:
.byte $0A
.byte $01
.byte $0F
.byte $00
.byte $88
.byte $18
.byte $01
.byte $07
.byte $1E
.byte $03
.byte $18
.byte $01
.byte $00
@bang1:
.byte $0A
.byte $03
.byte $0B
.byte $00
.byte $0F
.byte $0C
.byte $02
.byte $04
.byte $03
.byte $00
@bang2:
.byte $0A
.byte $03
.byte $04
.byte $00
.byte $06
.byte $0C
.byte $01
.byte $14
.byte $04
.byte $00
@thud2:
.byte $0A
.byte $00
.byte $0F
.byte $80
.byte $0F
.byte $18
.byte $02
.byte $3C
.byte $0A
.byte $00
@bang3:
.byte $0A
.byte $03
.byte $0C
.byte $80
.byte $0F
.byte $22
.byte $07
.byte $07
.byte $01
.byte $04
.byte $00
.byte $14
.byte $00
@bat_squeak:
.byte $0A
.byte $01
.byte $0F
.byte $80
.byte $06
.byte $3C
.byte $01
.byte $08
.byte $03
.byte $03
.byte $00
.byte $01
.byte $04
.byte $00
.byte $04
.byte $03
.byte $3C
.byte $01
.byte $01
.byte $08
.byte $03
.byte $00
@rat_squeak:
.byte $0A
.byte $01
.byte $0F
.byte $80
.byte $08
.byte $36
.byte $01
.byte $08
.byte $02
.byte $00
@choose_letter:
.byte $0A
.byte $02
.byte $01
.byte $C0
.byte $0F
.byte $46
.byte $02
.byte $28
.byte $03
.byte $00
@extra_life:
.byte $0C
.byte $02
.byte $01
.byte $C0
.byte $0A
.byte $41
.byte $04
.byte $00
.byte $03
.byte $03
.byte $00
.byte $01
.byte $04
.byte $00
.byte $03
.byte $03
.byte $41
.byte $01
.byte $04
.byte $00
.byte $03
.byte $03
.byte $00
.byte $01
.byte $04
.byte $00
.byte $03
.byte $03
.byte $3F
.byte $01
.byte $04
.byte $00
.byte $03
.byte $03
.byte $00
.byte $01
.byte $04
.byte $00
.byte $03
.byte $03
.byte $41
.byte $01
.byte $04
.byte $00
.byte $06
.byte $00
@bounce:
.byte $0A
.byte $02
.byte $0F
.byte $00
.byte $0F
.byte $1A
.byte $07
.byte $25
.byte $01
.byte $01
.byte $20
.byte $03
.byte $00
@metal_ball:
.byte $0A
.byte $03
.byte $0A
.byte $00
.byte $0A
.byte $22
.byte $01
.byte $4B
.byte $04
.byte $00
@pingb:
.byte $0A
.byte $00
.byte $0C
.byte $80
.byte $0D
.byte $24
.byte $04
.byte $00
.byte $14
.byte $00
@pinga:
.byte $0A
.byte $02
.byte $0C
.byte $40
.byte $0D
.byte $30
.byte $04
.byte $00
.byte $06
.byte $03
.byte $33
.byte $01
.byte $04
.byte $00
.byte $06
.byte $03
.byte $37
.byte $01
.byte $04
.byte $00
.byte $06
.byte $03
.byte $33
.byte $01
.byte $04
.byte $00
.byte $06
.byte $03
.byte $37
.byte $01
.byte $04
.byte $00
.byte $06
.byte $03
.byte $3C
.byte $01
.byte $04
.byte $00
.byte $06
.byte $00
@haha:
.byte $0A
.byte $03
.byte $04
.byte $00
.byte $06
.byte $0D
.byte $01
.byte $01
.byte $01
.byte $00
@hoho:
.byte $0A
.byte $02
.byte $04
.byte $00
.byte $06
.byte $1F
.byte $02
.byte $0C
.byte $03
.byte $00
@boing:
.byte $0C
.byte $01
.byte $0F
.byte $80
.byte $0F
.byte $18
.byte $01
.byte $04
.byte $18
.byte $00
@metal2:
.byte $0A
.byte $02
.byte $01
.byte $00
.byte $0F
.byte $4D
.byte $06
.byte $24
.byte $02
.byte $00
@drop_em:
.byte $0A
.byte $01
.byte $0F
.byte $80
.byte $05
.byte $1F
.byte $06
.byte $10
.byte $2D
.byte $00
@splash:
.byte $0A
.byte $03
.byte $0B
.byte $00
.byte $0F
.byte $35
.byte $06
.byte $01
.byte $28
.byte $00
@explode1:
.byte $0A
.byte $03
.byte $0D
.byte $00
.byte $0F
.byte $0A
.byte $04
.byte $00
.byte $28
.byte $00
@explode2:
.byte $0A
.byte $03
.byte $0D
.byte $00
.byte $0F
.byte $12
.byte $02
.byte $81
.byte $0A
.byte $00
@explode3:
.byte $0A
.byte $00
.byte $0F
.byte $00
.byte $0F
.byte $30
.byte $04
.byte $00
.byte $03
.byte $01
.byte $0E
.byte $03
.byte $00
@explode4:
.byte $0A
.byte $03
.byte $0D
.byte $00
.byte $0F
.byte $16
.byte $02
.byte $28
.byte $28
.byte $00
@major:
.byte $0A
.byte $03
.byte $0E
.byte $00
.byte $0F
.byte $0D
.byte $07
.byte $0D
.byte $01
.byte $06
.byte $5B
.byte $1E
.byte $00
@very_major:
.byte $0A
.byte $03
.byte $0F
.byte $00
.byte $0F
.byte $12
.byte $07
.byte $0D
.byte $01
.byte $07
.byte $1F
.byte $01
.byte $06
.byte $01
.byte $20
.byte $00
@biggie:
.byte $0A
.byte $01
.byte $0F
.byte $80
.byte $0F
.byte $11
.byte $02
.byte $04
.byte $28
.byte $00
fx_envelopes:
lda SFX_ATTACK,X
beq fx_decay
jsr fx_realspeed
beq @skp
lda SFX_VOLUME,X
clc
adc SFX_TEMP + 1
cmp SFX_VOLUME_2,X
bcc @ok
lda #0
sta SFX_ATTACK,X
lda SFX_VOLUME_2,X
@ok:
sta SFX_VOLUME,X
@skp:
rts
fx_decay:
lda SFX_DELAY,X
beq @skp2
jsr fx_realspeed
beq @skp
lda SFX_VOLUME,X
sec
sbc SFX_TEMP + 1
bcc @bot
cmp SFX_VOLUME_1,X
bcs @ok
@bot:
lda #0
sta SFX_DELAY,X
lda SFX_VOLUME_1,X
@ok:
sta SFX_VOLUME,X
@skp:
rts
@skp2:
lda SFX_VOLUME_1,X
sta SFX_VOLUME,X
rts
fx_setup:
stx SFX_FREQUENCY_ADDRESS_1_LOW
asl
tax
lda fx_table,X
sta SFX_FREQUENCY_ADDRESS_1_LOW
lda fx_table + 1,X
sta SFX_FREQUENCY_ADDRESS_1_HIGH
ldy #1
lda (SFX_FREQUENCY_ADDRESS_1),Y
tax
ldy #0
lda (SFX_FREQUENCY_ADDRESS_1),Y
cmp SFX_PRIORITY,X
bcs @high
rts
@high:
sta SFX_PRIORITY,X
lda SFX_FREQUENCY_ADDRESS_1_LOW
sta SFX_POINTER_LOW,X
lda SFX_FREQUENCY_ADDRESS_1_HIGH
sta SFX_POINTER_HIGH,X
stx SFX_FREQUENCY_ADDRESS_2_LOW
txa
asl
asl
tax
stx SFX_FREQUENCY_ADDRESS_2_HIGH
ldx SFX_FREQUENCY_ADDRESS_2_LOW
lda #255
sta SFX_TIME,X
sta MUSIC_VOICE_1,X
lda #6
sta SFX_POSITION,X
ldy #3
lda (SFX_FREQUENCY_ADDRESS_1),Y
sta SFX_PULSE,X
ldy #2
lda (SFX_FREQUENCY_ADDRESS_1),Y
pha
and #240
lsr
lsr
lsr
lsr
beq @eeq
sec
sbc #1
eor #15
@eeq:
sta SFX_ATTACK,X
pla
and #15
beq @eeq2
sec
sbc #1
eor #15
@eeq2:
sta SFX_DELAY,X
ldy #4
lda (SFX_FREQUENCY_ADDRESS_1),Y
pha
and #240
lsr
lsr
lsr
lsr
sta SFX_VOLUME_1,X
pla
and #15
sta SFX_VOLUME_2,X
lda #0
sta SFX_VOLUME,X
lda #1
sta SFX_CYCLES,X
lda SFX_ATTACK,X
bne @atk_on
lda SFX_VOLUME_2,X
sta SFX_VOLUME,X
@atk_on:
ldx SFX_FREQUENCY_ADDRESS_2_HIGH
lda #48
sta SFX_VOICES + 0,X
ldy #5
lda (SFX_FREQUENCY_ADDRESS_1),Y
tay
lda frequency_table_lo,Y
sta SFX_VOICES + 2,X
lda frequency_table_hi,Y
sta SFX_VOICES + 3,X
@too_low:
rts
fx_play:
inc SFX_COUNTER
lda #3
sta SFX_TEMP
@again:
ldx SFX_TEMP
lda SFX_PRIORITY,X
beq @no_fx2
txa
asl
asl
tay
lda SFX_VOICES,Y
ora SFX_VOLUME,X
ora SFX_PULSE,X
sta APU_PULSE_1_CONTROL,Y
lda SFX_TIME,X
cmp #255
bne @nsetup
dec SFX_TIME,X
lda SFX_VOICES + 2,Y
sta APU_PULSE_1_TIMER_LOW,Y
lda SFX_VOICES + 3,Y
sta APU_PULSE_1_LENGTH,Y
@nsetup:
@no_fx:
jsr fx_envelopes
dec SFX_CYCLES,X
bne @no_fx1
jsr fx_next
@no_fx1:
jsr fx_do
@no_fx2:
dec SFX_TEMP
bpl @again
rts
fx_next:
lda SFX_POINTER_LOW,X
sta SFX_ADDRESS_1_LOW
lda SFX_POINTER_HIGH,X
sta SFX_ADDRESS_1_HIGH
ldy SFX_POSITION,X
lda (SFX_ADDRESS_1),Y
beq @quit
sta SFX_ON,X
iny
lda (SFX_ADDRESS_1),Y
sta SFX_DATA_1,X
iny
lda (SFX_ADDRESS_1),Y
sta SFX_CYCLES,X
inc SFX_POSITION,X
inc SFX_POSITION,X
inc SFX_POSITION,X
rts
@quit:
lda #0
sta SFX_ON,X
sta SFX_PRIORITY,X
sta MUSIC_VOICE_1,X
ldy MUSIC_NOTE_1,X
lda frequency_table_hi,Y
pha
lda frequency_table_lo,Y
pha
txa
asl
asl
tay
pla
sta APU_PULSE_1_TIMER_LOW,Y
pla
sta APU_PULSE_1_LENGTH,Y
cpx #2
beq @triangle
lda #48
sta APU_PULSE_1_CONTROL,Y
rts
@triangle:
lda #0
sta APU_PULSE_1_CONTROL,Y
rts
fx_do:
lda SFX_ON,X
cmp #1
bne @nfx1
txa
asl
asl
tay
lda SFX_VOICES + 2,Y
sec
sbc SFX_DATA_1,X
sta SFX_VOICES + 2,Y
bcs @store_low
lda SFX_VOICES + 3,Y
sbc #0
sta SFX_VOICES + 3,Y
@store_high:
lda SFX_VOICES + 3,Y
sta APU_PULSE_1_LENGTH,Y
@store_low:
lda SFX_VOICES + 2,Y
sta APU_PULSE_1_TIMER_LOW,Y
rts
@nfx1:
cmp #2
bne @nfx2
txa
asl
asl
tay
lda SFX_VOICES + 2,Y
clc
adc SFX_DATA_1,X
sta SFX_VOICES + 2,Y
bcc @store_low
lda SFX_VOICES + 3,Y
adc #0
sta SFX_VOICES + 3,Y
jmp @store_high
@nfx2:
cmp #3
bne @nfx3
ldy SFX_DATA_1,X
lda frequency_table_hi,Y
pha
lda frequency_table_lo,Y
pha
txa
asl
asl
tay
pla
sta SFX_VOICES + 2,Y
pla
sta SFX_VOICES + 3,Y
jmp @store_high
@nfx3:
@nfx4:
cmp #5
bne @nfx5
txa
asl
asl
tay
lda SFX_DATA_1,X
jsr fx_realspeed
lda SFX_VOICES + 2,Y
sec
sbc SFX_TEMP + 1
sta SFX_VOICES + 2,Y
bcs @store_low
lda SFX_VOICES + 3,Y
sbc #0
sta SFX_VOICES + 3,Y
jmp @store_high
@nfx5:
cmp #6
bne @nfx6
txa
asl
asl
tay
lda SFX_DATA_1,X
jsr fx_realspeed
lda SFX_VOICES + 2,Y
clc
adc SFX_TEMP + 1
sta SFX_VOICES + 2,Y
bcc @jstore_low
lda SFX_VOICES + 3,Y
adc #0
sta SFX_VOICES + 3,Y
jmp @store_high
@jstore_low:
jmp @store_low
@nfx6:
cmp #7
bne @nfx7
lda SFX_DATA_1,X
jsr fx_setup
@nfx7:
rts
fx_realspeed:
bmi @real2
sty SFX_REAL_SAVE
sta SFX_TEMP + 1
lsr SFX_TEMP + 1
lsr SFX_TEMP + 1
and #3
tay
lda SFX_COUNTER
and #3
cmp @re,Y
bcc @fx_realspeed_skip_if_no_carry
inc SFX_TEMP + 1
@fx_realspeed_skip_if_no_carry:
ldy SFX_REAL_SAVE
lda SFX_TEMP + 1
rts
@re:
.byte $04
.byte $03
.byte $02
.byte $01
@real2:
sty SFX_REAL_SAVE
eor #255
clc
adc #1
sta SFX_TEMP + 1
lsr SFX_TEMP + 1
lsr SFX_TEMP + 1
and #3
tay
lda SFX_COUNTER
and #3
cmp @re,Y
bcc @fx_realspeed_skip_if_no_carry_2
inc SFX_TEMP + 1
@fx_realspeed_skip_if_no_carry_2:
lda SFX_TEMP + 1
eor #255
clc
adc #1
ldy SFX_REAL_SAVE
sta SFX_TEMP + 1
rts
