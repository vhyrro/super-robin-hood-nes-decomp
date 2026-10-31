COMPACTEDCHRSTABLE:
CM_CHRSET0 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(CM_CHRSET)
.byte >(CM_CHRSET)
.byte $00
.byte $0E
TITLETOPCHRS0_245 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(TITLETOPCHRS)
.byte >(TITLETOPCHRS)
.byte $00
.byte $8E
TITLEBOTCHRS0_245 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(TITLEBOTCHRS)
.byte >(TITLEBOTCHRS)
.byte $00
.byte $0E
HISCORECHRS0_43 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(HISCORECHRS)
.byte >(HISCORECHRS)
.byte $00
.byte $8E
HISCORECHRS0_43S = (* - COMPACTEDCHRSTABLE) / 4
.byte <(HISCORECHRS)
.byte >(HISCORECHRS)
.byte $00
.byte $0E
BASECHR0_157 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(BASECHR)
.byte >(BASECHR)
.byte $00
.byte $8E
BEADCHR157_23 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(BEADCHR)
.byte >(BEADCHR)
.byte $9D
.byte $8E
BOXCHR247_9 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(BOXCHR)
.byte >(BOXCHR)
.byte $F7
.byte $8E
ARCHCHR157_85 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(ARCHCHR)
.byte >(ARCHCHR)
.byte $9D
.byte $8E
ROCKCHR157_99 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(ROCKCHR)
.byte >(ROCKCHR)
.byte $9D
.byte $8E
BEDCHR180_66 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(BEDCHR)
.byte >(BEDCHR)
.byte $B4
.byte $8E
DOORCHR180_73 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(DOORCHR)
.byte >(DOORCHR)
.byte $B4
.byte $8E
ROBINCHRS0_255 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(ROBINCHRS)
.byte >(ROBINCHRS)
.byte $00
.byte $0E
OKCHR0_1 = (* - COMPACTEDCHRSTABLE) / 4
.byte <(OKCHR)
.byte >(OKCHR)
.byte $00
.byte $0E
COPYBLOCKOFCOMPACTEDCHRS:
asl
asl
tay
lda BANKNO
pha
lda COMPACTEDCHRSTABLE + 3,Y
and #15
jsr CHANGEBANKROU
lda COMPACTEDCHRSTABLE + 2,Y
sta TEMP
lda COMPACTEDCHRSTABLE + 3,Y
asl
lda #0
adc #0
asl TEMP
rol
asl TEMP
rol
asl TEMP
rol
asl TEMP
rol
sta _VRAMADDR
lda TEMP
sta _VRAMADDR
lda COMPACTEDCHRSTABLE + 0,Y
sta ADR1L
lda COMPACTEDCHRSTABLE + 1,Y
sta ADR1H
jsr PP1_UNPACK
pla
jmp CHANGEBANKROU
PP1_ZBUF = TOPLEVVAR1
PP1_TYPES = ADDRESS2
PP1_FOL1 = PP1_TYPES + 4
PP1_FOL2 = PP1_TYPES + 8
PP1_FOL3 = PP1_TYPES + 12
ADR1 = ADDRESS1
ADR1L = ADDRESS1
ADR1H = ADDRESS1 + 1
PP1_DOWNLOAD3:
stx ADR1L
sty ADR1H
txa
lda BANKNO
pha
txa
jsr CHANGEBANKROU
jsr PP1_UNPACK
pla
jmp CHANGEBANKROU
PP1_DOWNLOAD2:
stx ADR1L
sty ADR1H
PP1_DOWNLOAD:
ldx #13
PP1_UNPACK:
ldy #0
lda (ADR1),Y
sta TEMP1
sta TEMP8
iny
lda #128
sta TEMP2
PP1_CHRLOOP:
jsr PP1_GETC
bcs PP1_GOTHEADER
ldx #3
@HL:
jsr PP1_GET2
sta PP1_TYPES,X
beq @T0
lsr
beq @T1
bcc @T2
@T3:
jsr PP1_T3
sta PP1_FOL3,X
jmp @T0
@T2:
jsr PP1_T3
sta TEMP3
jsr PP1_GETC
bcc @T0
lda TEMP3
sta PP1_FOL2,X
jmp @T0
@T1:
jsr PP1_T1
sta PP1_FOL1,X
@T0:
dex
bpl @HL
PP1_GOTHEADER:
ldx #7
PP1_GETLINE:
stx TEMP3
asl TEMP2
bcc @Q10
bne PP1_GOTLINE
jsr PP1_GETQ
bcs PP1_GOTLINE
@Q10:
jsr PP1_GET2
tax
sta TEMP4
lsr
ora #2
sta TEMP5
@NEXT:
lda PP1_TYPES,X
beq @T0
asl TEMP2
bcc @Q11
bne @T0
jsr PP1_GETQ
bcs @T0
@Q11:
lda PP1_TYPES,X
lsr
beq @T1
bcc @T2
@T3:
asl TEMP2
bcc @Q12
bne @T1
jsr PP1_GETQ
bcs @T1
@Q12:
asl TEMP2
bcc @T2B
bne @Q13
jsr PP1_GETQ
bcc @T2B
@Q13:
lda PP1_FOL3,X
tax
jmp @P
@T2:
asl TEMP2
bcc @T1
bne @Q14
jsr PP1_GETQ
bcc @T1
@Q14:
@T2B:
lda PP1_FOL2,X
tax
jmp @P
@T1:
lda PP1_FOL1,X
tax
@T0:
txa
@P:
lsr
rol TEMP4
lsr
rol TEMP5
bcc @NEXT
PP1_GOTLINE:
lda TEMP4
sta 8199
ldx TEMP3
lda TEMP5
sta PP1_ZBUF,X
dex
bpl PP1_GETLINE
ldx #7
@BPL1:
lda PP1_ZBUF,X
sta 8199
dex
bpl @BPL1
dec TEMP1
beq @DONE
jmp PP1_CHRLOOP
@DONE:
rts
PP1_GETC:
asl TEMP2
beq @H0
rts
@H0:
PP1_GETQ:
lda (ADR1),Y
iny
bne @H2
inc ADR1H
@H2:
rol
sta TEMP2
rts
PP1_GET2:
asl TEMP2
bne @_20
lda (ADR1),Y
iny
bne @_22
inc ADR1H
@_22:
rol
sta TEMP2
@_20:
rol
and #1
asl TEMP2
beq @_21
rol
rts
@_21:
pha
lda (ADR1),Y
iny
bne @_23
inc ADR1H
@_23:
rol
sta TEMP2
pla
rol
rts
PP1_T1:
jsr PP1_GETC
bcc @T1B
lda PP1_FC1,X
rts
@T1B:
jsr PP1_GETC
bcs @T1C
lda PP1_FC2,X
rts
@T1C:
lda PP1_FC3,X
rts
PP1_T3:
jsr PP1_T1
sta PP1_FOL1,X
beq @T3_0
cmp #2
bcc @T3_1
beq @T3_2
@T3_3:
lda PP1_F3L,X
sta PP1_FOL2,X
lda PP1_F3H,X
rts
@T3_2:
lda PP1_F2L,X
sta PP1_FOL2,X
lda PP1_F2H,X
rts
@T3_1:
lda PP1_F1L,X
sta PP1_FOL2,X
lda PP1_F1H,X
rts
@T3_0:
lda PP1_F0L,X
sta PP1_FOL2,X
lda PP1_F0H,X
rts
PP1_FC3:
.byte $03,$03,$03
PP1_FC2:
.byte $02,$02,$01
PP1_FC1:
.byte $01,$00,$00,$00
PP1_F0L = PP1_FC2
PP1_F0H = PP1_FC3
PP1_F1L:
.byte $02,$FF,$00,$00
PP1_F1H = PP1_FC3
PP1_F2L = PP1_FC1
PP1_F2H:
.byte $03,$03,$FF,$01
PP1_F3L = PP1_FC1
PP1_F3H = PP1_FC2
PP1_SIZE = * - PP1_DOWNLOAD3
