MESSAGE_END = 255
MESSAGE_GOSUB = 254
MESSAGE_HORIZONTAL_VERTICAL = 253
MESSAGE_LENGTH = 252
MESSAGE_LOOP = 251
MESSAGE_END_LOOP = 250
MESSAGE_DOWN_LINE = 249
MESSAGE_JUMP = 248
MESSAGE_DOWN_ATTRIBUTE = 247
MESSAGE_TEXT = 246
MESSAGE_ADDRESS = 128
MESSAGE_BUFFER_HORIZONTAL_VERTICAL = 1
MESSAGE_POINTER = SCRATCH_BYTE_1
LAST_ADDRESS = SCRATCH_BYTE_3
TEMP_STORE = SCRATCH_BYTE_5
TEXT_POINTER = TEMP_POINTER_4
prtmessagefly:
asl VBLANK_FLAG
@prtmessagefly_wait_vblank:
bit VBLANK_FLAG
bpl @prtmessagefly_wait_vblank
prtmessage:
stx MESSAGE_POINTER
sty MESSAGE_POINTER + 1
printwhatataddress:
ldy #0
printwhatataddress1:
lda (MESSAGE_POINTER),Y
notendyet:
iny
cmp #128
bcs notchr
sta PPU_DATA_REGISTER
bcc printwhatataddress1
notchr:
cmp #240
bcc mustbeaddress
cmp #MESSAGE_END
bne @notchr_skip_if_not_equal
rts
@notchr_skip_if_not_equal:
cmp #MESSAGE_LENGTH
beq setstringlen
cmp #MESSAGE_GOSUB
beq gosub
cmp #MESSAGE_LOOP
beq startloop
cmp #MESSAGE_END_LOOP
beq endloop
cmp #MESSAGE_DOWN_LINE
beq downlinerou
cmp #MESSAGE_DOWN_ATTRIBUTE
beq attrdownrou
cmp #MESSAGE_TEXT
beq printtext
jmp jumpnewmessagejump
printwhatataddress2:
iny
bne printwhatataddress1
mustbeaddress:
and #127
sta LAST_ADDRESS + 1
sta PPU_ADDRESS_REGISTER
lda (MESSAGE_POINTER),Y
sta LAST_ADDRESS
sta PPU_ADDRESS_REGISTER
jmp printwhatataddress2
setstringlen:
lda (MESSAGE_POINTER),Y
iny
tax
stringlen1:
lda (MESSAGE_POINTER),Y
iny
sta PPU_DATA_REGISTER
dex
bne stringlen1
beq printwhatataddress1
startloop:
lda (MESSAGE_POINTER),Y
iny
repeatingloop:
pha
tya
pha
jmp printwhatataddress1
endloop:
sty TEMP_STORE
pla
tay
pla
sec
sbc #1
bne repeatingloop
ldy TEMP_STORE
jmp printwhatataddress1
gosub:
lda MESSAGE_POINTER
pha
lda MESSAGE_POINTER + 1
pha
lda (MESSAGE_POINTER),Y
tax
iny
lda (MESSAGE_POINTER),Y
iny
sta MESSAGE_POINTER + 1
stx MESSAGE_POINTER
tya
pha
jsr printwhatataddress
pla
tay
pla
sta MESSAGE_POINTER + 1
pla
sta MESSAGE_POINTER
jmp printwhatataddress1
downlinerou:
lda #32
joindownline:
clc
adc LAST_ADDRESS
sta LAST_ADDRESS
tax
bcc @joindownline_skip_if_no_carry
inc LAST_ADDRESS + 1
@joindownline_skip_if_no_carry:
lda LAST_ADDRESS + 1
sta PPU_ADDRESS_REGISTER
stx PPU_ADDRESS_REGISTER
jmp printwhatataddress1
attrdownrou:
lda #8
bne joindownline
printtext:
lda (MESSAGE_POINTER),Y
sta TEXT_POINTER
iny
lda (MESSAGE_POINTER),Y
sta TEXT_POINTER + 1
iny
tya
pha
ldy #0
@printtext_loop:
lda (TEXT_POINTER),Y
beq @printtext_done
cmp #MESSAGE_DOWN_LINE
beq @printtext_newline
sta PPU_DATA_REGISTER
iny
bne @printtext_loop
@printtext_newline:
lda #32
clc
adc LAST_ADDRESS
sta LAST_ADDRESS
tax
bcc @printtext_skip_carry
inc LAST_ADDRESS + 1
@printtext_skip_carry:
lda LAST_ADDRESS + 1
sta PPU_ADDRESS_REGISTER
stx PPU_ADDRESS_REGISTER
iny
jmp @printtext_loop
@printtext_done:
pla
tay
jmp printwhatataddress1
jumpnewmessagejump:
lda (MESSAGE_POINTER),Y
tax
iny
lda (MESSAGE_POINTER),Y
sta MESSAGE_POINTER + 1
stx MESSAGE_POINTER
jmp printwhatataddress
addtoprintbuffer:
stx MESSAGE_POINTER
sty MESSAGE_POINTER + 1
ldy #0
ldx VRAM_WRITE_POINTER
contaddtobuffer:
lda (MESSAGE_POINTER),Y
sta VRAM_BUFFER_ADDRESS,X
iny
inx
lda (MESSAGE_POINTER),Y
sta VRAM_BUFFER_ADDRESS,X
iny
inx
lda (MESSAGE_POINTER),Y
sta VRAM_BUFFER_ADDRESS,X
inx
sta TEMP_STORE
iny
addtoprintbufferlp:
lda (MESSAGE_POINTER),Y
sta VRAM_BUFFER_ADDRESS,X
iny
inx
dec TEMP_STORE
bne addtoprintbufferlp
stx VRAM_WRITE_POINTER
rts
emptyprintbufferflyadd:
jsr addtoprintbuffer
emptyprintbufferfly:
asl VBLANK_FLAG
@emptyprintbufferfly_wait_vblank:
bit VBLANK_FLAG
bpl @emptyprintbufferfly_wait_vblank
emptyprintbuffer:
lda VRAM_WRITE_POINTER
beq retmessage
ldy #0
veryfastprintout:
lda VRAM_BUFFER_ADDRESS,Y
and #127
sta PPU_ADDRESS_REGISTER
iny
lda VRAM_BUFFER_ADDRESS,Y
sta PPU_ADDRESS_REGISTER
iny
ldx VRAM_BUFFER_ADDRESS,Y
iny
stringlen:
lda VRAM_BUFFER_ADDRESS,Y
sta PPU_DATA_REGISTER
iny
dex
bne stringlen
cpy VRAM_WRITE_POINTER
bne veryfastprintout
nomoremessage:
lda #0
sta VRAM_WRITE_POINTER
retmessage:
rts
