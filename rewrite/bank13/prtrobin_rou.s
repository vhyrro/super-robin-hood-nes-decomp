FLASHROBIN:
.byte $04
.byte $02
.byte $02
.byte $02
.byte $02
.byte $02
PRINTROBIN:
lda KILLED
beq @_1
rts
@_1:
jsr CHECKROBINBEHIND
lda #0
sta SPRITECOLOUR
lda ROBININVINC
beq PRINTROBIN1
dec ROBININVINC
lda ROBININVINC
cmp #150
bcc @_2
rts
@_2:
lsr
lsr
lsr
lsr
lsr
tax
lda FLASHROBIN,X
and COUNTER
bne PRINTROBIN1
lda #2
sta SPRITECOLOUR
PRINTROBIN1:
lda OLEFTRIGHT
pha
lda ROBINLADDER
beq @_1
jmp PRINTROBINONLADDER
@_1:
lda ROBINXL
sec
sbc SCRXL
tax
sta ROBINONSCRX
sta ADDRESS5
ldy ROBINY
sty TEMP9
lda ROBINANIM
clc
adc #LEGSRUNNING
cmp #LEGSRUNNING - 1
bne NORMALRUN
lda #MORELEGS
NORMALRUN:
sta ADDRESS5 + 1
sta ADDRESS7 + 1
stx ADDRESS8
sty ADDRESS8 + 1
ldx #MORELEGS + 3
lda ROBINCROUCH
beq WORKOUTBODY
cmp #($FC)
beq @_1
cmp #($FD)
beq @_1
cmp #($FB)
beq @_1
dex
dex
@_1:
stx ADDRESS5 + 1
stx ADDRESS7 + 1
cpx #MORELEGS + 1
beq WORKOUTBODY
jsr SUBTRACKHEIGHTOFSPRITE
lda ADDRESS5
tax
clc
adc #4
bit OLEFTRIGHT
bpl @_2
sec
sbc #8
@_2:
sta ADDRESS5
lda #MORELEGS + 2
sta ADDRESS5 + 1
asl OLEFTRIGHT
jsr PRINTSPRITEPOSREV
jmp WORKOUTHEAD
WORKOUTBODY:
jsr SUBTRACKHEIGHTOFSPRITE
lda ROBINFIRING
beq @_3
jmp PRINTROBINSHOOTING
@_3:
ldx ADDRESS5
lda ROBINANIM
bmi @_2
and #7
@_2:
clc
adc #ROBINBODIES
cmp #ROBINBODIES - 1
bne @_1
lda #ROBINBODIES + 8
@_1:
sta ADDRESS5 + 1
asl OLEFTRIGHT
jsr PRINTSPRITEPOSREV
WORKOUTHEAD:
jsr WORKOUTHEADROU
NOWPRINTLEGS:
lda ADDRESS7 + 1
ldx ADDRESS8
ldy ADDRESS8 + 1
asl OLEFTRIGHT
jsr PRINTSPRITEPOSREV
pla
sta OLEFTRIGHT
lda #0
sta SPRITEBEHIND
rts
ROBPOINTTABLE:
.byte $FF
.byte $00
.byte $00
ROBINLOOKTAB:
.byte $00
.byte $00
.byte $00
.byte $00
.byte $01
.byte $00
.byte $00
.byte $02
.byte $03
SPRITEHEIGHTS:
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
WORKOUTHEADROU:
jsr SUBTRACKHEIGHTOFSPRITE
clc
adc #($F2)
sta ROBINHEIGHT
lda #ROBINHEADS
@_1:
lda ROBINLADDER
bne @_2
lda COUNTER
clc
adc #1
and #31
bne @_2
lda SEED
and #3
clc
adc ROBINLOOK
and #7
sta ROBINLOOK
@_2:
ldx ROBINLOOK
lda ROBINLOOKTAB,X
clc
adc #ROBINHEADS
ldx ADDRESS5
sta ADDRESS5 + 1
asl OLEFTRIGHT
jmp PRINTSPRITEPOSREV
PRINTROBINONLADDER:
ldy #8
ldx #0
lda ROBINY
and #8
beq @_1
ldx #96
@_1:
lda PAD
and #RMASK
beq @_2
ldy #4
@_2:
lda PAD
and #LMASK
beq @_3
ldy #4
txa
clc
adc #128
tax
@_3:
stx OLEFTRIGHT
sty ROBINLOOK
lda ROBINXL
sec
sbc SCRXL
tax
sta ADDRESS5
ldy ROBINY
sty TEMP9
lda #MORELEGS + 6
sta ADDRESS5 + 1
sta ADDRESS7 + 1
stx ADDRESS8
sty ADDRESS8 + 1
jsr SUBTRACKHEIGHTOFSPRITE
ldx ADDRESS5
stx ADDRESS6
sty ADDRESS6 + 1
lda #MORELEGS + 5
sta ADDRESS5 + 1
sta ADDRESS7
jsr WORKOUTHEADROU
ldx ADDRESS6
ldy ADDRESS6 + 1
lda ADDRESS7
asl OLEFTRIGHT
jsr PRINTSPRITEPOSREV
jmp NOWPRINTLEGS
PRINTROBINSHOOTING:
lsr
lsr
tax
lda SHOOTINGFRMS,X
ldx ADDRESS5
@_1:
sta ADDRESS5 + 1
asl OLEFTRIGHT
jsr PRINTSPRITEPOSREV
lda #0
sta ROBINLOOK
jmp WORKOUTHEAD
SHOOTINGFRMS:
.byte <(BODYFIRING + 1)
.byte <(BODYFIRING + 2)
.byte <(BODYFIRING + 3)
.byte <(BODYFIRING + 4)
.byte <(BODYFIRING + 3)
.byte <(BODYFIRING + 3)
.byte <(BODYFIRING + 2)
.byte <(BODYFIRING + 2)
.byte <(BODYFIRING + 1)
.byte <(BODYFIRING + 1)
SUBTRACKHEIGHTOFSPRITE:
ldx ADDRESS5 + 1
lda TEMP9
clc
adc SPRITEHEIGHTS,X
sta TEMP9
tay
rts
