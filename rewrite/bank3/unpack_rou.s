compactedchrstable:
CHARSET_CODEMASTERS = (* - compactedchrstable) / 4
.byte <(cm_chrset)
.byte >(cm_chrset)
.byte $00
.byte $02
CHARSET_TITLE_TOP = (* - compactedchrstable) / 4
.byte <(titletopchrs)
.byte >(titletopchrs)
.byte $00
.byte $82
CHARSET_TITLE_BOTTOM = (* - compactedchrstable) / 4
.byte <(titlebotchrs)
.byte >(titlebotchrs)
.byte $00
.byte $02
CHARSET_HIGH_SCORE = (* - compactedchrstable) / 4
.byte <(hiscorechrs)
.byte >(hiscorechrs)
.byte $00
.byte $82
CHARSET_HIGH_SCORE_2 = (* - compactedchrstable) / 4
.byte <(hiscorechrs)
.byte >(hiscorechrs)
.byte $00
.byte $02
CHARSET_BASE = (* - compactedchrstable) / 4
.byte <(basechr)
.byte >(basechr)
.byte $00
.byte $82
CHARSET_BEAD = (* - compactedchrstable) / 4
.byte <(beadchr)
.byte >(beadchr)
.byte $9D
.byte $82
CHARSET_BOX = (* - compactedchrstable) / 4
.byte <(boxchr)
.byte >(boxchr)
.byte $F7
.byte $82
CHARSET_ARCH = (* - compactedchrstable) / 4
.byte <(archchr)
.byte >(archchr)
.byte $9D
.byte $82
CHARSET_ROCK = (* - compactedchrstable) / 4
.byte <(rockchr)
.byte >(rockchr)
.byte $9D
.byte $82
CHARSET_BED = (* - compactedchrstable) / 4
.byte <(bedchr)
.byte >(bedchr)
.byte $B4
.byte $82
CHARSET_DOOR = (* - compactedchrstable) / 4
.byte <(doorchr)
.byte >(doorchr)
.byte $B4
.byte $82
CHARSET_ROBIN = (* - compactedchrstable) / 4
.byte <(robinchrs)
.byte >(robinchrs)
.byte $00
.byte $02
CHARSET_OK = (* - compactedchrstable) / 4
.byte <(okchr)
.byte >(okchr)
.byte $00
.byte $02
PP1_ADDRESS = TEMP_POINTER_1
PP1_ADDRESS_LOW = TEMP_POINTER_1
PP1_ADDRESS_HIGH = TEMP_POINTER_1 + 1
copyblockofcompactedchrs:
asl
asl
tay
lda CURRENT_BANK
pha
lda compactedchrstable + 3,Y
and #15
jsr change_bank_routine
lda compactedchrstable + 2,Y
sta TEMP_BYTE
lda compactedchrstable + 3,Y
asl
lda #0
adc #0
asl TEMP_BYTE
rol
asl TEMP_BYTE
rol
asl TEMP_BYTE
rol
asl TEMP_BYTE
rol
sta PPU_ADDRESS_REGISTER
lda TEMP_BYTE
sta PPU_ADDRESS_REGISTER
lda compactedchrstable + 0,Y
sta PP1_ADDRESS_LOW
lda compactedchrstable + 1,Y
sta PP1_ADDRESS_HIGH
jsr pp1_unpack
pla
jmp change_bank_routine
PP1_ZERO_BUFFER = SCRATCH_BYTE_1
PP1_TYPE_TABLE = TEMP_POINTER_2
PP1_FOLLOW_1 = PP1_TYPE_TABLE + 4
PP1_FOLLOW_2 = PP1_TYPE_TABLE + 8
PP1_FOLLOW_3 = PP1_TYPE_TABLE + 12
pp1_unpack:
ldy #0
lda (PP1_ADDRESS),Y
sta TEMP_BYTE_1
sta TEMP_BYTE_8
iny
lda #128
sta TEMP_BYTE_2
pp1_chrloop:
jsr pp1_getc
bcs pp1_gotheader
ldx #3
@hl:
jsr pp1_get2
sta PP1_TYPE_TABLE,X
beq @t0
lsr
beq @t1
bcc @t2
@t3:
jsr pp1_t3
sta PP1_FOLLOW_3,X
jmp @t0
@t2:
jsr pp1_t3
sta TEMP_BYTE_3
jsr pp1_getc
bcc @t0
lda TEMP_BYTE_3
sta PP1_FOLLOW_2,X
jmp @t0
@t1:
jsr pp1_t1
sta PP1_FOLLOW_1,X
@t0:
dex
bpl @hl
pp1_gotheader:
ldx #7
pp1_getline:
stx TEMP_BYTE_3
asl TEMP_BYTE_2
bcc @q10
bne pp1_gotline
jsr pp1_getq
bcs pp1_gotline
@q10:
jsr pp1_get2
tax
sta TEMP_BYTE_4
lsr
ora #2
sta TEMP_BYTE_5
@next:
lda PP1_TYPE_TABLE,X
beq @t0
asl TEMP_BYTE_2
bcc @q11
bne @t0
jsr pp1_getq
bcs @t0
@q11:
lda PP1_TYPE_TABLE,X
lsr
beq @t1
bcc @t2
@t3:
asl TEMP_BYTE_2
bcc @q12
bne @t1
jsr pp1_getq
bcs @t1
@q12:
asl TEMP_BYTE_2
bcc @t2b
bne @q13
jsr pp1_getq
bcc @t2b
@q13:
lda PP1_FOLLOW_3,X
tax
jmp @p
@t2:
asl TEMP_BYTE_2
bcc @t1
bne @q14
jsr pp1_getq
bcc @t1
@q14:
@t2b:
lda PP1_FOLLOW_2,X
tax
jmp @p
@t1:
lda PP1_FOLLOW_1,X
tax
@t0:
txa
@p:
lsr
rol TEMP_BYTE_4
lsr
rol TEMP_BYTE_5
bcc @next
pp1_gotline:
lda TEMP_BYTE_4
sta PPU_DATA_REGISTER
ldx TEMP_BYTE_3
lda TEMP_BYTE_5
sta PP1_ZERO_BUFFER,X
dex
bpl pp1_getline
ldx #7
@bpl1:
lda PP1_ZERO_BUFFER,X
sta PPU_DATA_REGISTER
dex
bpl @bpl1
dec TEMP_BYTE_1
beq @done
jmp pp1_chrloop
@done:
rts
pp1_getc:
asl TEMP_BYTE_2
beq @h0
rts
@h0:
pp1_getq:
lda (PP1_ADDRESS),Y
iny
bne @h2
inc PP1_ADDRESS_HIGH
@h2:
rol
sta TEMP_BYTE_2
rts
pp1_get2:
asl TEMP_BYTE_2
bne @pp1_get2_skip_if_not_equal_2
lda (PP1_ADDRESS),Y
iny
bne @pp1_get2_skip_if_not_equal
inc PP1_ADDRESS_HIGH
@pp1_get2_skip_if_not_equal:
rol
sta TEMP_BYTE_2
@pp1_get2_skip_if_not_equal_2:
rol
and #1
asl TEMP_BYTE_2
beq @pp1_get2_skip_if_equal
rol
rts
@pp1_get2_skip_if_equal:
pha
lda (PP1_ADDRESS),Y
iny
bne @pp1_get2_skip_if_not_equal_3
inc PP1_ADDRESS_HIGH
@pp1_get2_skip_if_not_equal_3:
rol
sta TEMP_BYTE_2
pla
rol
rts
pp1_t1:
jsr pp1_getc
bcc @t1b
lda pp1_fc1,X
rts
@t1b:
jsr pp1_getc
bcs @t1c
lda pp1_fc2,X
rts
@t1c:
lda pp1_fc3,X
rts
pp1_t3:
jsr pp1_t1
sta PP1_FOLLOW_1,X
beq @t3_0
cmp #2
bcc @t3_1
beq @t3_2
@t3_3:
lda PP1_FRAME_3_LOW,X
sta PP1_FOLLOW_2,X
lda PP1_FRAME_3_HIGH,X
rts
@t3_2:
lda PP1_FRAME_2_LOW,X
sta PP1_FOLLOW_2,X
lda pp1_f2h,X
rts
@t3_1:
lda pp1_f1l,X
sta PP1_FOLLOW_2,X
lda PP1_FRAME_1_HIGH,X
rts
@t3_0:
lda PP1_FRAME_0_LOW,X
sta PP1_FOLLOW_2,X
lda PP1_FRAME_0_HIGH,X
rts
pp1_fc3:
.byte $03,$03,$03
pp1_fc2:
.byte $02,$02,$01
pp1_fc1:
.byte $01,$00,$00,$00
PP1_FRAME_0_LOW = pp1_fc2
PP1_FRAME_0_HIGH = pp1_fc3
pp1_f1l:
.byte $02,$FF,$00,$00
PP1_FRAME_1_HIGH = pp1_fc3
PP1_FRAME_2_LOW = pp1_fc1
pp1_f2h:
.byte $03,$03,$FF,$01
PP1_FRAME_3_LOW = pp1_fc1
PP1_FRAME_3_HIGH = pp1_fc2
