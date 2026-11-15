SPRITE_FRAME_WIDTH = SCRATCH_BYTE_1
SPRITE_FRAME_HEIGHT = SCRATCH_BYTE_2
SPRITE_TEMP_WIDTH = SCRATCH_BYTE_3
SPRITE_TEMP_HEIGHT = SCRATCH_BYTE_4
SPRITE_X_COORD_1 = SCRATCH_BYTE_5
SPRITE_Y_COORD_1 = SCRATCH_BYTE_6
SPRITE_ADD_X = SCRATCH_BYTE_7
SPRITE_ADD_Y = SCRATCH_BYTE_8
SPRITE_TEMP_ATTRIBUTE = SCRATCH_BYTE_9
SPRITE_TEMP_CHARACTER = SCRATCH_BYTE_10
SPRITE_REVERSE = TEMP_BYTE_1
SPRITE_X_COORD = TEMP_BYTE_2
SPRITE_Y_COORD = TEMP_BYTE_3
SPRITE_INDEX = TEMP_BYTE_4
SPRITE_FRAME_COUNT = TEMP_BYTE_5
SPRITE_X_COORD_HIGH_1 = TEMP_BYTE_6
SPRITE_TEMP_X_HIGH = TEMP_BYTE_8
SPRITE_CHARACTERS = TEMP_POINTER_3
SPRITE_ALLOW_BEHIND = 1
ZP_VAR SPRITE_TEMP_X
SPRITE_WINDOW_EDGE = 30 * 8
printspriterev:
sec
bcs printspriteposrev
printsprite:
clc
printspriteposrev:
stx SPRITE_X_COORD
ldx #0
stx SPRITE_REVERSE
ror SPRITE_REVERSE
sty SPRITE_Y_COORD
asl
tay
bcs @printspriteposrev_skip_if_carry
lda spritetable,Y
sta TEMP_POINTER_2
lda spritetable + 1,Y
sta TEMP_POINTER_2 + 1
jmp @printspriteposrev_skip
@printspriteposrev_skip_if_carry:
lda spritetable + 256,Y
sta TEMP_POINTER_2
lda spritetable + 1 + 256,Y
sta TEMP_POINTER_2 + 1
@printspriteposrev_skip:
ldy #0
lda (TEMP_POINTER_2),Y
sta SPRITE_FRAME_COUNT
lda SPRITE_Y_COORD
clc
adc #SPRITE_Y_DISPLACE
sta SPRITE_Y_COORD
iny
eachfrminspritelp:
lda (TEMP_POINTER_2),Y
ldx SPRITE_REVERSE
bpl @eachfrminspritelp_skip_if_positive
eor #64
@eachfrminspritelp_skip_if_positive:
sta TEMP_BYTE
bit playermask
beq @eachfrminspritelp_skip_if_equal
clc
adc SPRITE_COLOUR
@eachfrminspritelp_skip_if_equal:
and #195
sta SPRITE_TEMP_ATTRIBUTE
lda #8
asl TEMP_BYTE
bcc notvert
lda #($F8)
notvert:
sta SPRITE_ADD_Y
lda #8
asl TEMP_BYTE
bcc nothor
lda #($F8)
nothor:
sta SPRITE_ADD_X
iny
lda #0
tax
asl TEMP_BYTE
bcc nodisplacements
lda (TEMP_POINTER_2),Y
tax
iny
lda (TEMP_POINTER_2),Y
iny
nodisplacements:
stx SPRITE_X_COORD_1
sta SPRITE_Y_COORD_1
dothesprite:
lda (TEMP_POINTER_2),Y
asl TEMP_BYTE
bcc mustbespr
tax
sta SPRITE_CHARACTERS + 0
lda #1
asl TEMP_BYTE
bcc nottwobytwo
asl
inx
stx SPRITE_CHARACTERS + 1
inx
stx SPRITE_CHARACTERS + 2
inx
stx SPRITE_CHARACTERS + 3
nottwobytwo:
sta SPRITE_FRAME_WIDTH
sta SPRITE_FRAME_HEIGHT
sty SPRITE_INDEX
lda #<(SPRITE_CHARACTERS)
sta TEMP_POINTER_1
lda #>(SPRITE_CHARACTERS)
sta TEMP_POINTER_1 + 1
ldy #0
jmp mustbejustchr
mustbespr:
sta TEMP_POINTER_1
iny
sty SPRITE_INDEX
lda (TEMP_POINTER_2),Y
sta TEMP_POINTER_1 + 1
ldy #0
lda (TEMP_POINTER_1),Y
lsr
lsr
lsr
lsr
sta SPRITE_FRAME_WIDTH
lda (TEMP_POINTER_1),Y
and #15
sta SPRITE_FRAME_HEIGHT
iny
mustbejustchr:
lda SPRITE_X_COORD_1
bit SPRITE_REVERSE
bmi @mustbejustchr_skip_if_negative
bit SPRITE_ADD_X
bpl @mustbejustchr_skip_if_positive
ldx SPRITE_FRAME_WIDTH
clc
adc frmtimes8,X
jmp @mustbejustchr_skip_if_positive
@mustbejustchr_skip_if_negative:
bit SPRITE_ADD_X
bmi @mustbejustchr_skip_if_negative_2
ldx SPRITE_FRAME_WIDTH
clc
adc frmtimes8,X
@mustbejustchr_skip_if_negative_2:
eor #255
clc
adc #($F9)
@mustbejustchr_skip_if_positive:
clc
adc SPRITE_X_COORD
sta SPRITE_X_COORD_1
lda SPRITE_ADD_Y
bpl notflippedover
sec
sbc SPRITE_Y_COORD_1
sta SPRITE_Y_COORD_1
notflippedover:
lda SPRITE_Y_COORD
clc
adc SPRITE_Y_COORD_1
sta SPRITE_Y_COORD_1
ldx SPRITE_BLOCK_POINTER
beq nomorespritechrsleft
yspritelp:
lda SPRITE_FRAME_WIDTH
sta SPRITE_TEMP_WIDTH
lda SPRITE_X_COORD_1
sta SPRITE_TEMP_X
xspritelp:
lda SPRITE_Y_COORD_1
sta SPRITE_BLOCK_ADDRESS,X
lda (TEMP_POINTER_1),Y
iny
inx
sta SPRITE_BLOCK_ADDRESS,X
lda SPRITE_TEMP_ATTRIBUTE
ora SPRITE_BEHIND
inx
sta SPRITE_BLOCK_ADDRESS,X
inx
lda SPRITE_TEMP_X
sta SPRITE_BLOCK_ADDRESS,X
inx
beq nomorespritechrsleft
@xspritelp_body:
clc
adc SPRITE_ADD_X
sta SPRITE_TEMP_X
dec SPRITE_TEMP_WIDTH
bne xspritelp
lda SPRITE_Y_COORD_1
clc
adc SPRITE_ADD_Y
sta SPRITE_Y_COORD_1
dec SPRITE_FRAME_HEIGHT
bne yspritelp
nomorespritechrsleft:
stx SPRITE_BLOCK_POINTER
dec SPRITE_FRAME_COUNT
beq @nomorespritechrsleft_skip_if_equal
ldy SPRITE_INDEX
iny
jmp eachfrminspritelp
@nomorespritechrsleft_skip_if_equal:
rts
frmtimes8:
.byte $00
.byte $00
.byte $08
.byte $10
.byte $18
.byte $20
.byte $28
.byte $30
.byte $38
.byte $40
playermask:
.byte $04
winprintspritereversed:
sec
bcs winprintspriteposrev
winprintsprite:
clc
winprintspriteposrev:
stx SPRITE_X_COORD
ldx #0
sta SPRITE_REVERSE
ror SPRITE_REVERSE
ldx SPRITE_X_COORD_HIGH
inx
cpx #3
bcc @winprintspriteposrev_skip_if_no_carry
@winprintspriteposrev_loop:
rts
@winprintspriteposrev_skip_if_no_carry:
cpx #1
beq @winprintspriteposrev_skip_if_equal
bcc @winprintspriteposrev_skip_if_no_carry_2
ldx SPRITE_X_COORD
cpx #($E8)
bcc @winprintspriteposrev_skip_if_equal
rts
@winprintspriteposrev_skip_if_no_carry_2:
ldx SPRITE_X_COORD
cpx #24
bcs @winprintspriteposrev_loop
@winprintspriteposrev_skip_if_equal:
sty SPRITE_Y_COORD
asl
tay
bcs @winprintspriteposrev_skip_if_carry
lda spritetable,Y
sta TEMP_POINTER_2
lda spritetable + 1,Y
sta TEMP_POINTER_2 + 1
jmp @winprintspriteposrev_skip
@winprintspriteposrev_skip_if_carry:
lda spritetable + 256,Y
sta TEMP_POINTER_2
lda spritetable + 1 + 256,Y
sta TEMP_POINTER_2 + 1
@winprintspriteposrev_skip:
ldy #0
lda (TEMP_POINTER_2),Y
sta SPRITE_FRAME_COUNT
lda SPRITE_Y_COORD
clc
adc #SPRITE_Y_DISPLACE
sta SPRITE_Y_COORD
iny
wineachfrminspritelp:
lda SPRITE_X_COORD_HIGH
sta SPRITE_X_COORD_HIGH_1
lda (TEMP_POINTER_2),Y
bit SPRITE_REVERSE
bpl @wineachfrminspritelp_skip_if_positive
eor #64
@wineachfrminspritelp_skip_if_positive:
sta TEMP_BYTE
bit playermask
beq @wineachfrminspritelp_skip_if_equal
clc
adc SPRITE_COLOUR
@wineachfrminspritelp_skip_if_equal:
and #195
sta SPRITE_TEMP_ATTRIBUTE
lda #8
asl TEMP_BYTE
bcc winnotvert
lda #($F8)
winnotvert:
sta SPRITE_ADD_Y
lda #8
asl TEMP_BYTE
bcc winnothor
lda #($F8)
winnothor:
sta SPRITE_ADD_X
iny
lda #0
tax
asl TEMP_BYTE
bcc winnodisplacements
lda (TEMP_POINTER_2),Y
tax
iny
lda (TEMP_POINTER_2),Y
iny
winnodisplacements:
stx SPRITE_X_COORD_1
sta SPRITE_Y_COORD_1
windothesprite:
lda (TEMP_POINTER_2),Y
asl TEMP_BYTE
bcc winmustbespr
tax
sta SPRITE_CHARACTERS + 0
lda #1
asl TEMP_BYTE
bcc winnottwobytwo
asl
inx
stx SPRITE_CHARACTERS + 1
inx
stx SPRITE_CHARACTERS + 2
inx
stx SPRITE_CHARACTERS + 3
winnottwobytwo:
sta SPRITE_FRAME_WIDTH
sta SPRITE_FRAME_HEIGHT
sty SPRITE_INDEX
lda #<(SPRITE_CHARACTERS)
sta TEMP_POINTER_1
lda #>(SPRITE_CHARACTERS)
sta TEMP_POINTER_1 + 1
ldy #0
jmp winmustbejustchr
winmustbespr:
sta TEMP_POINTER_1
iny
sty SPRITE_INDEX
lda (TEMP_POINTER_2),Y
sta TEMP_POINTER_1 + 1
ldy #0
lda (TEMP_POINTER_1),Y
lsr
lsr
lsr
lsr
sta SPRITE_FRAME_WIDTH
lda (TEMP_POINTER_1),Y
and #15
sta SPRITE_FRAME_HEIGHT
iny
winmustbejustchr:
bit SPRITE_REVERSE
bmi @winmustbejustchr_skip_if_negative_2
lda SPRITE_X_COORD_1
bmi @winmustbejustchr_skip_if_negative
inc SPRITE_X_COORD_HIGH_1
@winmustbejustchr_skip_if_negative:
bit SPRITE_ADD_X
bpl @winmustbejustchr_skip_if_positive
ldx SPRITE_FRAME_WIDTH
clc
adc frmtimes8,X
bcs @winmustbejustchr_skip_if_carry_2
@winmustbejustchr_skip_if_positive:
dec SPRITE_X_COORD_HIGH_1
jmp @winmustbejustchr_skip_if_carry_2
@winmustbejustchr_skip_if_negative_2:
lda SPRITE_X_COORD_1
bmi @winmustbejustchr_skip_if_negative_3
dec SPRITE_X_COORD_HIGH_1
@winmustbejustchr_skip_if_negative_3:
bit SPRITE_ADD_X
bmi @winmustbejustchr_skip_if_negative_4
ldx SPRITE_FRAME_WIDTH
clc
adc frmtimes8,X
bcc @winmustbejustchr_skip_if_negative_4
dec SPRITE_X_COORD_HIGH_1
@winmustbejustchr_skip_if_negative_4:
eor #255
clc
adc #($F9)
bcs @winmustbejustchr_skip_if_carry
dec SPRITE_X_COORD_HIGH_1
@winmustbejustchr_skip_if_carry:
@winmustbejustchr_skip_if_carry_2:
clc
adc SPRITE_X_COORD
sta SPRITE_X_COORD_1
bcc @winmustbejustchr_skip_if_no_carry
inc SPRITE_X_COORD_HIGH_1
@winmustbejustchr_skip_if_no_carry:
aroundaddx:
lda SPRITE_ADD_Y
bpl winnotflippedover
sec
sbc SPRITE_Y_COORD_1
sta SPRITE_Y_COORD_1
winnotflippedover:
lda SPRITE_Y_COORD
clc
adc SPRITE_Y_COORD_1
sta SPRITE_Y_COORD_1
ldx SPRITE_BLOCK_POINTER
beq winnomorespritechrsleft
winyspritelp:
lda SPRITE_FRAME_WIDTH
sta SPRITE_TEMP_WIDTH
lda SPRITE_X_COORD_1
sta SPRITE_TEMP_X
lda SPRITE_X_COORD_HIGH_1
sta SPRITE_TEMP_X_HIGH
winxspritelp:
lda SPRITE_TEMP_X_HIGH
bne winthischrnotonscreen
lda SPRITE_Y_COORD_1
cmp #SPRITE_WINDOW_EDGE
bcs winthischrnotonscreen
sta SPRITE_BLOCK_ADDRESS,X
lda (TEMP_POINTER_1),Y
inx
sta SPRITE_BLOCK_ADDRESS,X
lda SPRITE_TEMP_ATTRIBUTE
ora SPRITE_BEHIND
inx
sta SPRITE_BLOCK_ADDRESS,X
inx
lda SPRITE_TEMP_X
sta SPRITE_BLOCK_ADDRESS,X
inx
beq winnomorespritechrsleft
winthischrnotonscreen:
iny
lda SPRITE_ADD_X
bmi @winthischrnotonscreen_skip_if_negative
lda SPRITE_TEMP_X
clc
adc SPRITE_ADD_X
sta SPRITE_TEMP_X
bcc @winthischrnotonscreen_skip_if_no_carry
inc SPRITE_TEMP_X_HIGH
jmp @winthischrnotonscreen_skip_if_no_carry
@winthischrnotonscreen_skip_if_negative:
clc
adc SPRITE_TEMP_X
sta SPRITE_TEMP_X
bcs @winthischrnotonscreen_skip_if_no_carry
dec SPRITE_TEMP_X_HIGH
@winthischrnotonscreen_skip_if_no_carry:
dec SPRITE_TEMP_WIDTH
bne winxspritelp
lda SPRITE_Y_COORD_1
clc
adc SPRITE_ADD_Y
sta SPRITE_Y_COORD_1
dec SPRITE_FRAME_HEIGHT
bne winyspritelp
winnomorespritechrsleft:
stx SPRITE_BLOCK_POINTER
dec SPRITE_FRAME_COUNT
beq @winnomorespritechrsleft_skip_if_equal
ldy SPRITE_INDEX
iny
jmp wineachfrminspritelp
@winnomorespritechrsleft_skip_if_equal:
rts
pokesprite:
stx SCRATCH_BYTE_1
ldx SPRITE_BLOCK_POINTER
beq nomorespriteplaces
sta SPRITE_BLOCK_ADDRESS + 1,X
lda SCRATCH_BYTE_1
sta SPRITE_BLOCK_ADDRESS + 3,X
tya
sta SPRITE_BLOCK_ADDRESS + 0,X
lda TEMP_BYTE
sta SPRITE_BLOCK_ADDRESS + 2,X
txa
clc
adc #4
sta SPRITE_BLOCK_POINTER
nomorespriteplaces:
rts
pokesprite2by2:
stx SCRATCH_BYTE_1
ldx SPRITE_BLOCK_POINTER
bne @pokesprite2by2_skip_if_not_equal
@pokesprite2by2_loop:
rts
@pokesprite2by2_skip_if_not_equal:
cpx #240
bcs @pokesprite2by2_loop
sta SPRITE_BLOCK_ADDRESS + 1,X
adc #1
sta SPRITE_BLOCK_ADDRESS + 1 + 4,X
adc #1
sta SPRITE_BLOCK_ADDRESS + 1 + 8,X
adc #1
sta SPRITE_BLOCK_ADDRESS + 1 + 12,X
lda TEMP_BYTE
sta SPRITE_BLOCK_ADDRESS + 2,X
sta SPRITE_BLOCK_ADDRESS + 2 + 4,X
sta SPRITE_BLOCK_ADDRESS + 2 + 8,X
sta SPRITE_BLOCK_ADDRESS + 2 + 12,X
and #128
bne flippedvert
tya
clc
adc #SPRITE_Y_DISPLACE
sta SPRITE_BLOCK_ADDRESS + 8,X
sta SPRITE_BLOCK_ADDRESS + 12,X
clc
adc #($F8)
sta SPRITE_BLOCK_ADDRESS + 0,X
sta SPRITE_BLOCK_ADDRESS + 4,X
jmp nowhor
flippedvert:
tya
clc
adc #SPRITE_Y_DISPLACE
sta SPRITE_BLOCK_ADDRESS + 0,X
sta SPRITE_BLOCK_ADDRESS + 4,X
clc
adc #($F8)
sta SPRITE_BLOCK_ADDRESS + 8,X
sta SPRITE_BLOCK_ADDRESS + 12,X
nowhor:
lda SCRATCH_BYTE_1
bit TEMP_BYTE
bvs flippedhor
sta SPRITE_BLOCK_ADDRESS + 3 + 4,X
sta SPRITE_BLOCK_ADDRESS + 3 + 12,X
clc
adc #($F8)
bcs @nowhor_skip_if_carry
lda #245
sta SPRITE_BLOCK_ADDRESS + 0 + 0,X
sta SPRITE_BLOCK_ADDRESS + 0 + 8,X
@nowhor_skip_if_carry:
sta SPRITE_BLOCK_ADDRESS + 3 + 0,X
sta SPRITE_BLOCK_ADDRESS + 3 + 8,X
jmp done2by2
flippedhor:
sta SPRITE_BLOCK_ADDRESS + 3 + 0,X
sta SPRITE_BLOCK_ADDRESS + 3 + 8,X
clc
adc #($F8)
bcs @flippedhor_skip_if_carry
lda #245
sta SPRITE_BLOCK_ADDRESS + 0 + 4,X
sta SPRITE_BLOCK_ADDRESS + 0 + 12,X
@flippedhor_skip_if_carry:
sta SPRITE_BLOCK_ADDRESS + 3 + 4,X
sta SPRITE_BLOCK_ADDRESS + 3 + 12,X
done2by2:
txa
clc
adc #16
sta SPRITE_BLOCK_POINTER
nomore2by2:
rts
