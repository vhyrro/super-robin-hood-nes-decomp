PICKUPHEARTFX = 1
PICKUPTREASUREFX = 1
PICKUPKEYFX = 17
KILLYOUTOTALLYFX = 30
KILLYOUFX = 28
KILLTHEMTOTALLYFX = 29
KILLTHEMFX = 27
DOORLIFTINGFX = 4
ARROWHITWALLFX = 32
SPITFX = 33
BATHITFX = 26
TRAMPFX = 21
THEMFIRINGFX = 11
BREATHINGFIREFX = 8
BALLBOUNCEFX = 16
BATSQUELFX = 15
RATSQUELFX = 34
FIRSTAPPEARFX = 2
EXTRALIFEFX = 36
CHOOSELETTERFX = 35
DELETELETTERFX = 6
LEFTRIGHTLETTERFX = 5
YOUFIRINGFX = 11
FX_TEMP = ZLIM
ZLIM .set ZLIM + 1
FX_AD1L = ZLIM
ZLIM .set ZLIM + 1
FX_AD1H = ZLIM
ZLIM .set ZLIM + 1
FX_AD1 = FX_AD1L
FFX_AD1L = ZLIM
ZLIM .set ZLIM + 1
FFX_AD1H = ZLIM
ZLIM .set ZLIM + 1
FFX_AD1 = FFX_AD1L
FX_AD2L = ZLIM
ZLIM .set ZLIM + 1
FX_AD2H = ZLIM
ZLIM .set ZLIM + 1
FX_AD2 = FX_AD2L
FFX_AD2L = ZLIM
ZLIM .set ZLIM + 1
FFX_AD2H = ZLIM
ZLIM .set ZLIM + 1
FFX_AD2 = FFX_AD2L
FX_COUNTERZ = VARLIM
VARLIM .set VARLIM + 1
FX_TEMPZ = VARLIM
VARLIM .set VARLIM + 2
FX_VOL1 = VARLIM
VARLIM .set VARLIM + 4
FX_VOL2 = VARLIM
VARLIM .set VARLIM + 4
FX_VOLUME = VARLIM
VARLIM .set VARLIM + 4
FX_ATCK = VARLIM
VARLIM .set VARLIM + 4
FX_DEL = VARLIM
VARLIM .set VARLIM + 4
FX_TIME = VARLIM
VARLIM .set VARLIM + 4
FX_PLS = VARLIM
VARLIM .set VARLIM + 4
FX_ON = VARLIM
VARLIM .set VARLIM + 4
FX_DATA1 = VARLIM
VARLIM .set VARLIM + 4
FX_POSITION = VARLIM
VARLIM .set VARLIM + 4
FX_POINTL = VARLIM
VARLIM .set VARLIM + 4
FX_POINTH = VARLIM
VARLIM .set VARLIM + 4
FX_CYCLES = VARLIM
VARLIM .set VARLIM + 4
FX_PRIORITY = VARLIM
VARLIM .set VARLIM + 4
FX_VOICES = VARLIM
VARLIM .set VARLIM + 16
FX_REAL_SAVE = VARLIM
VARLIM .set VARLIM + 1
FX_TO_DO .set 23
FX_TABLE:
.word @TAP
.word @PING
.word @WHOOSH
.word @CLICK2
.word @CLICK
.word @BLIP
.word @DELETE
.word @THUD
.word @BREATH
.word @SIREN
.word @SIRENB
.word @BANG1
.word @BANG2
.word @THUD2
.word @BANG3
.word @BAT_SQUEAK
.word @BOUNCE
.word @PINGA
.word @PINGB
.word @HAHA
.word @HOHO
.word @BOING
.word @METAL2
.word @DROP_EM
.word @SPLASH
.word @EXPLODE1
.word @EXPLODE3
.word @EXPLODE2
.word @EXPLODE4
.word @MAJOR
.word @VERY_MAJOR
.word @BIGGIE
.word @ARROW
.word @SPIT
.word @RAT_SQUEAK
.word @CHOOSE_LETTER
.word @EXTRA_LIFE
.word @METAL_BALL
@TAP:
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
@PING:
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
@PING2:
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
@WHOOSH:
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
@CLICK:
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
@CLICK2:
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
@BLIP:
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
@DELETE:
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
@THUD:
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
@ARROW:
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
@SPIT:
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
@BREATH:
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
@SIREN:
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
@SIRENB:
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
@BANG1:
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
@BANG2:
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
@THUD2:
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
@BANG3:
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
@BAT_SQUEAK:
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
@RAT_SQUEAK:
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
@CHOOSE_LETTER:
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
@EXTRA_LIFE:
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
@BOUNCE:
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
@METAL_BALL:
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
@PINGB:
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
@PINGA:
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
@HAHA:
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
@HOHO:
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
@BOING:
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
@METAL2:
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
@DROP_EM:
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
@SPLASH:
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
@EXPLODE1:
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
@EXPLODE2:
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
@EXPLODE3:
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
@EXPLODE4:
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
@MAJOR:
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
@VERY_MAJOR:
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
@BIGGIE:
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
FX_ENVELOPES:
lda FX_ATCK,X
beq FX_TRYD
jsr FX_REALSPEED
beq @SKP
lda FX_VOLUME,X
clc
adc FX_TEMP + 1
cmp FX_VOL2,X
bcc @OK
lda #0
sta FX_ATCK,X
lda FX_VOL2,X
@OK:
sta FX_VOLUME,X
@SKP:
rts
FX_TRYD:
lda FX_DEL,X
beq @SKP2
jsr FX_REALSPEED
beq @SKP
lda FX_VOLUME,X
sec
sbc FX_TEMP + 1
bcc @BOT
cmp FX_VOL1,X
bcs @OK
@BOT:
lda #0
sta FX_DEL,X
lda FX_VOL1,X
@OK:
sta FX_VOLUME,X
@SKP:
rts
@SKP2:
lda FX_VOL1,X
sta FX_VOLUME,X
rts
FX_SETUP:
stx FFX_AD1L
asl
tax
lda FX_TABLE,X
sta FFX_AD1L
lda FX_TABLE + 1,X
sta FFX_AD1H
ldy #1
lda (FFX_AD1),Y
tax
ldy #0
lda (FFX_AD1),Y
cmp FX_PRIORITY,X
bcs @HIGH
rts
@HIGH:
sta FX_PRIORITY,X
lda FFX_AD1L
sta FX_POINTL,X
lda FFX_AD1H
sta FX_POINTH,X
stx FFX_AD2L
txa
asl
asl
tax
stx FFX_AD2H
ldx FFX_AD2L
lda #255
sta FX_TIME,X
sta VOICE1,X
lda #6
sta FX_POSITION,X
ldy #3
lda (FFX_AD1),Y
sta FX_PLS,X
ldy #2
lda (FFX_AD1),Y
pha
and #240
lsr
lsr
lsr
lsr
beq @EEQ
sec
sbc #1
eor #15
@EEQ:
sta FX_ATCK,X
pla
and #15
beq @EEQ2
sec
sbc #1
eor #15
@EEQ2:
sta FX_DEL,X
ldy #4
lda (FFX_AD1),Y
pha
and #240
lsr
lsr
lsr
lsr
sta FX_VOL1,X
pla
and #15
sta FX_VOL2,X
lda #0
sta FX_VOLUME,X
lda #1
sta FX_CYCLES,X
lda FX_ATCK,X
bne @ATK_ON
lda FX_VOL2,X
sta FX_VOLUME,X
@ATK_ON:
ldx FFX_AD2H
lda #48
sta FX_VOICES + 0,X
ldy #5
lda (FFX_AD1),Y
tay
lda TABLO,Y
sta FX_VOICES + 2,X
lda TABHI,Y
sta FX_VOICES + 3,X
@TOO_LOW:
rts
FX_PLAY:
inc FX_COUNTERZ
lda #3
sta FX_TEMP
@AGAIN:
ldx FX_TEMP
lda FX_PRIORITY,X
beq @NO_FX2
txa
asl
asl
tay
lda FX_VOICES,Y
ora FX_VOLUME,X
ora FX_PLS,X
sta 16384,Y
lda FX_TIME,X
cmp #255
bne @NSETUP
dec FX_TIME,X
lda FX_VOICES + 2,Y
sta 16384 + 2,Y
lda FX_VOICES + 3,Y
sta 16384 + 3,Y
@NSETUP:
@NO_FX:
jsr FX_ENVELOPES
dec FX_CYCLES,X
bne @NO_FX1
jsr FX_NEXT
@NO_FX1:
jsr FX_DO
@NO_FX2:
dec FX_TEMP
bpl @AGAIN
rts
FX_NEXT:
lda FX_POINTL,X
sta FX_AD1L
lda FX_POINTH,X
sta FX_AD1H
ldy FX_POSITION,X
lda (FX_AD1),Y
beq @QUIT
sta FX_ON,X
iny
lda (FX_AD1),Y
sta FX_DATA1,X
iny
lda (FX_AD1),Y
sta FX_CYCLES,X
inc FX_POSITION,X
inc FX_POSITION,X
inc FX_POSITION,X
rts
@QUIT:
lda #0
sta FX_ON,X
sta FX_PRIORITY,X
sta VOICE1,X
ldy NOTE1,X
lda TABHI,Y
pha
lda TABLO,Y
pha
txa
asl
asl
tay
pla
sta 16386,Y
pla
sta 16387,Y
cpx #2
beq @TRIANGLE
lda #48
sta 16384,Y
rts
@TRIANGLE:
lda #0
sta 16384,Y
rts
FX_DO:
lda FX_ON,X
cmp #1
bne @NFX1
txa
asl
asl
tay
lda FX_VOICES + 2,Y
sec
sbc FX_DATA1,X
sta FX_VOICES + 2,Y
bcs @STORE_LOW
lda FX_VOICES + 3,Y
sbc #0
sta FX_VOICES + 3,Y
@STORE_HIGH:
lda FX_VOICES + 3,Y
sta 16384 + 3,Y
@STORE_LOW:
lda FX_VOICES + 2,Y
sta 16384 + 2,Y
rts
@NFX1:
cmp #2
bne @NFX2
txa
asl
asl
tay
lda FX_VOICES + 2,Y
clc
adc FX_DATA1,X
sta FX_VOICES + 2,Y
bcc @STORE_LOW
lda FX_VOICES + 3,Y
adc #0
sta FX_VOICES + 3,Y
jmp @STORE_HIGH
@NFX2:
cmp #3
bne @NFX3
ldy FX_DATA1,X
lda TABHI,Y
pha
lda TABLO,Y
pha
txa
asl
asl
tay
pla
sta FX_VOICES + 2,Y
pla
sta FX_VOICES + 3,Y
jmp @STORE_HIGH
@NFX3:
@NFX4:
cmp #5
bne @NFX5
txa
asl
asl
tay
lda FX_DATA1,X
jsr FX_REALSPEED
lda FX_VOICES + 2,Y
sec
sbc FX_TEMP + 1
sta FX_VOICES + 2,Y
bcs @STORE_LOW
lda FX_VOICES + 3,Y
sbc #0
sta FX_VOICES + 3,Y
jmp @STORE_HIGH
@NFX5:
cmp #6
bne @NFX6
txa
asl
asl
tay
lda FX_DATA1,X
jsr FX_REALSPEED
lda FX_VOICES + 2,Y
clc
adc FX_TEMP + 1
sta FX_VOICES + 2,Y
bcc @JSTORE_LOW
lda FX_VOICES + 3,Y
adc #0
sta FX_VOICES + 3,Y
jmp @STORE_HIGH
@JSTORE_LOW:
jmp @STORE_LOW
@NFX6:
cmp #7
bne @NFX7
lda FX_DATA1,X
jsr FX_SETUP
@NFX7:
rts
FX_REALSPEED:
bmi @REAL2
sty FX_REAL_SAVE
sta FX_TEMP + 1
lsr FX_TEMP + 1
lsr FX_TEMP + 1
and #3
tay
lda FX_COUNTERZ
and #3
cmp @RE,Y
bcc @_1
inc FX_TEMP + 1
@_1:
ldy FX_REAL_SAVE
lda FX_TEMP + 1
rts
@RE:
.byte $04
.byte $03
.byte $02
.byte $01
@REAL2:
sty FX_REAL_SAVE
eor #255
clc
adc #1
sta FX_TEMP + 1
lsr FX_TEMP + 1
lsr FX_TEMP + 1
and #3
tay
lda FX_COUNTERZ
and #3
cmp @RE,Y
bcc @_2
inc FX_TEMP + 1
@_2:
lda FX_TEMP + 1
eor #255
clc
adc #1
ldy FX_REAL_SAVE
sta FX_TEMP + 1
rts
