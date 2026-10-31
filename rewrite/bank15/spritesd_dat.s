SPRITETABLE:
ROBINHEADS = (* - SPRITETABLE) / 2
.word HEAD0
.word HEAD1
.word HEAD2
.word HEAD3
ROBINBODIES = (* - SPRITETABLE) / 2
.word ROBINBODY0
.word ROBINBODY1
.word ROBINBODY2
.word ROBINBODY3
.word ROBINBODY4
.word ROBINBODY5
.word ROBINBODY6
.word ROBINBODY3
BODYFIRING = (* - SPRITETABLE) / 2
.word ROBINSTANDING
.word BODYFIRE0
.word BODYFIRE1
.word BODYFIRE2
.word BODYFIRE3
LEGSRUNNING = (* - SPRITETABLE) / 2
.word LEGSRUNNING0
.word LEGSRUNNING1
.word LEGSRUNNING2
.word LEGSRUNNING3
.word LEGSRUNNING4
.word LEGSRUNNING5
.word LEGSRUNNING6
.word LEGSRUNNING3
MORELEGS = (* - SPRITETABLE) / 2
.word LEGSSTANDING
.word LEGSHALFCROUCH
.word BODYFULLCROUCH
.word LEGSFULLCROUCH
.word LEGSJUMPING
.word BODYONLADDER
.word LEGSONLADDER
BARRELS = (* - SPRITETABLE) / 2
.word BARREL0
.word BARREL1
.word BARREL2
.word BARREL1
CANON = (* - SPRITETABLE) / 2
.word CANONS
PLATFORM = (* - SPRITETABLE) / 2
.word PLATFORMSPR
TITLELOGOS = (* - SPRITETABLE) / 2
.word CODEMASTERLOGO
.word CAMERICALOGO
.word PRESSSTART
DEADARROWS = (* - SPRITETABLE) / 2
.word DEADARROW1
.word DEADARROW2
.word DEADARROW3
.word DEADARROW4
TRAMPET = (* - SPRITETABLE) / 2
.word TRAMPET1
.word TRAMPET2
SPIDER = (* - SPRITETABLE) / 2
.word SPIDERSPR
.word SPIDERSPR1
BAT = (* - SPRITETABLE) / 2
.word BAT1
.word BAT2
EYES = (* - SPRITETABLE) / 2
.word EYE1
.word EYE2
.word EYE3
.word EYE4
GUARD = (* - SPRITETABLE) / 2
.word GUARDLOW
.word GUARDHIGH
.word GUARDLOW1
.word GUARDHIGH1
FIRE = (* - SPRITETABLE) / 2
.word FIRE1
.word FIRE2
.word FIRE3
.word FIRE4
.word FIRE5
MARION = (* - SPRITETABLE) / 2
.word MARIONS
PAUSESPR = (* - SPRITETABLE) / 2
.word PAUSES
SPRITEDEFS:
CODEMASTERLOGO:
.byte $07
.byte $00
.byte <(CMDATA0)
.byte >(CMDATA0)
.byte $20
.byte $FD
.byte $08
.byte <(CMDATA1)
.byte >(CMDATA1)
.byte $20
.byte $F8
.byte $10
.byte <(CMDATA2)
.byte >(CMDATA2)
.byte $20
.byte $F8
.byte $18
.byte <(CMDATA3)
.byte >(CMDATA3)
.byte $20
.byte $FB
.byte $20
.byte <(CMDATA4)
.byte >(CMDATA4)
.byte $20
.byte $05
.byte $28
.byte <(CMDATA5)
.byte >(CMDATA5)
.byte $30
.byte $F8
.byte $24
.byte $F2
CMDATA0:
.byte $41
.byte $D5,$D6,$D7,$D8
CMDATA1:
.byte $51
.byte $D9,$DA,$DB,$DC,$DD
CMDATA2:
.byte $61
.byte $DE,$DF,$E0,$E1,$E2,$E3
CMDATA3:
.byte $61
.byte $E4,$E5,$E6,$E7,$E8,$E9
CMDATA4:
.byte $51
.byte $EA,$EB,$EC,$ED,$EE
CMDATA5:
.byte $31
.byte $EF,$F0,$F1
CAMERICALOGO:
.byte $02
.byte $01
.byte <(CAMDATA0)
.byte >(CAMDATA0)
.byte $21
.byte $06
.byte $10
.byte <(CAMDATA1)
.byte >(CAMDATA1)
CAMDATA0:
.byte $82
.byte $DC,$DD,$DE,$DF,$E0,$E1,$E2,$E3
.byte $E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB
CAMDATA1:
.byte $61
.byte $EC,$ED,$ED,$ED,$ED,$EE
PRESSSTART:
.byte $02
.byte $02
.byte <(PSDATA)
.byte >(PSDATA)
.byte $22
.byte $00
.byte $0A
.byte <(PSDATA1)
.byte >(PSDATA1)
PSDATA:
.byte $51
.byte $EF,$F0,$F1,$F2,$F2
PSDATA1:
.byte $51
.byte $F2,$F3,$F4,$F0,$F3
HEAD0:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $01
HEAD1:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $05
HEAD2:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $09
HEAD3:
.byte $01
.byte $7C
.byte $F8
.byte $F1
.byte $0D
ROBINBODY0:
.byte $01
.byte $24
.byte $F9
.byte $F2
.byte <(BODY0DATA)
.byte >(BODY0DATA)
ROBINBODY1:
.byte $01
.byte $24
.byte $F7
.byte $F1
.byte <(BODY1DATA)
.byte >(BODY1DATA)
ROBINBODY2:
.byte $01
.byte $24
.byte $F8
.byte $F3
.byte <(BODY2DATA)
.byte >(BODY2DATA)
ROBINBODY3:
.byte $01
.byte $3C
.byte $FA
.byte $F4
.byte $23
ROBINBODY4:
.byte $01
.byte $3C
.byte $FA
.byte $F5
.byte $27
ROBINBODY5:
.byte $01
.byte $24
.byte $F8
.byte $F3
.byte <(BODY5DATA)
.byte >(BODY5DATA)
ROBINBODY6:
.byte $01
.byte $3C
.byte $F9
.byte $F3
.byte $31
BODY0DATA:
.byte $32
.byte $11,$12,$13,$14,$15,$16
BODY1DATA:
.byte $32
.byte $17,$18,$19,$1A,$1B,$1C
BODY2DATA:
.byte $32
.byte $1D,$1E,$1F,$20,$21,$22
BODY5DATA:
.byte $32
.byte $2B,$2C,$2D,$2E,$2F,$30
ROBINSTANDING:
.byte $01
.byte $24
.byte $F8
.byte $F1
.byte <(ROBSTANDDATA)
.byte >(ROBSTANDDATA)
ROBSTANDDATA:
.byte $23
.byte $35,$36,$37,$38,$39,$3A
BODYFIRE0:
.byte $03
.byte $24
.byte $F8
.byte $F1
.byte <(BODYFIRE0DATA0)
.byte >(BODYFIRE0DATA0)
.byte $24
.byte $00
.byte $F1
.byte <(BODYFIRE0DATA1)
.byte >(BODYFIRE0DATA1)
.byte $24
.byte $08
.byte $F5
.byte <(BODYFIRE0DATA2)
.byte >(BODYFIRE0DATA2)
BODYFIRE0DATA0:
.byte $12
.byte $35,$3B
BODYFIRE0DATA1:
.byte $13
.byte $36,$3C,$3D
BODYFIRE0DATA2:
.byte $12
.byte $3E,$3F
BODYFIRE1:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(BODYFIRE1DATA)
.byte >(BODYFIRE1DATA)
.byte $34
.byte $08
.byte $01
.byte $44
BODYFIRE1DATA:
.byte $32
.byte $35,$36,$40,$41,$42,$43
BODYFIRE2:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(BODYFIRE2DATA)
.byte >(BODYFIRE2DATA)
.byte $34
.byte $08
.byte $01
.byte $49
BODYFIRE2DATA:
.byte $32
.byte $35,$45,$46,$41,$47,$48
BODYFIRE3:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(BODYFIRE3DATA)
.byte >(BODYFIRE3DATA)
.byte $34
.byte $08
.byte $01
.byte $4E
BODYFIRE3DATA:
.byte $32
.byte $35,$4A,$4B,$41,$4C,$4D
LEGSRUNNING0:
.byte $02
.byte $24
.byte $FA
.byte $F2
.byte <(LEGSRUNNING0DATA0)
.byte >(LEGSRUNNING0DATA0)
.byte $24
.byte $F8
.byte $FA
.byte <(LEGSRUNNING0DATA1)
.byte >(LEGSRUNNING0DATA1)
LEGSRUNNING0DATA0:
.byte $21
.byte $4F,$50
LEGSRUNNING0DATA1:
.byte $21
.byte $51,$52
LEGSRUNNING1:
.byte $02
.byte $24
.byte $F3
.byte $F3
.byte <(LEGSRUNNING1DATA)
.byte >(LEGSRUNNING1DATA)
.byte $34
.byte $03
.byte $FB
.byte $56
LEGSRUNNING1DATA:
.byte $31
.byte $53,$54,$55
LEGSRUNNING2:
.byte $01
.byte $3C
.byte $F6
.byte $F2
.byte $57
LEGSRUNNING3:
.byte $02
.byte $24
.byte $FA
.byte $F2
.byte <(LEGSRUNNING3DATA)
.byte >(LEGSRUNNING3DATA)
.byte $34
.byte $FA
.byte $FA
.byte $5D
LEGSRUNNING3DATA:
.byte $21
.byte $5B,$5C
LEGSRUNNING4:
.byte $02
.byte $24
.byte $F9
.byte $F2
.byte <(LEGSRUNNING4DATA0)
.byte >(LEGSRUNNING4DATA0)
.byte $24
.byte $F8
.byte $FA
.byte <(LEGSRUNNING4DATA1)
.byte >(LEGSRUNNING4DATA1)
LEGSRUNNING4DATA0:
.byte $21
.byte $5E,$5F
LEGSRUNNING4DATA1:
.byte $21
.byte $51,$52
LEGSRUNNING5:
.byte $02
.byte $24
.byte $F4
.byte $F3
.byte <(LEGSRUNNING5DATA)
.byte >(LEGSRUNNING5DATA)
.byte $34
.byte $04
.byte $FB
.byte $56
LEGSRUNNING5DATA:
.byte $31
.byte $53,$60,$55
LEGSRUNNING6:
.byte $01
.byte $24
.byte $F7
.byte $F2
.byte <(LEGSRUNNING6DATA)
.byte >(LEGSRUNNING6DATA)
LEGSRUNNING6DATA:
.byte $22
.byte $57,$61,$59,$5A
LEGSSTANDING:
.byte $01
.byte $3C
.byte $FC
.byte $F2
.byte $62
LEGSHALFCROUCH:
.byte $02
.byte $24
.byte $F9
.byte $F3
.byte <(LEGSHALFCROUCHDATA0)
.byte >(LEGSHALFCROUCHDATA0)
.byte $24
.byte $F8
.byte $FB
.byte <(LEGSHALFCROUCHDATA1)
.byte >(LEGSHALFCROUCHDATA1)
LEGSHALFCROUCHDATA0:
.byte $21
.byte $66,$67
LEGSHALFCROUCHDATA1:
.byte $21
.byte $68,$69
BODYFULLCROUCH:
.byte $01
.byte $24
.byte $FB
.byte $F9
.byte <(BODYFULLCROUCHDATA)
.byte >(BODYFULLCROUCHDATA)
BODYFULLCROUCHDATA:
.byte $21
.byte $6A,$6B
LEGSFULLCROUCH:
.byte $01
.byte $24
.byte $F7
.byte $F9
.byte <(LEGSFULLCROUCHDATA)
.byte >(LEGSFULLCROUCHDATA)
LEGSFULLCROUCHDATA:
.byte $31
.byte $6C,$6D,$6E
LEGSJUMPING:
.byte $03
.byte $24
.byte $F3
.byte $F6
.byte <(LEGSJUMPDATA)
.byte >(LEGSJUMPDATA)
.byte $34
.byte $03
.byte $F5
.byte $71
.byte $34
.byte $05
.byte $FB
.byte $56
LEGSJUMPDATA:
.byte $21
.byte $6F,$70
BODYONLADDER:
.byte $01
.byte $3C
.byte $F7
.byte $F1
.byte $72
LEGSONLADDER:
.byte $02
.byte $24
.byte $FB
.byte $F4
.byte <(LEGSLADDERDATA)
.byte >(LEGSLADDERDATA)
.byte $34
.byte $FB
.byte $FC
.byte $78
LEGSLADDERDATA:
.byte $21
.byte $76,$77
BARREL0:
.byte $04
.byte $31
.byte $F8
.byte $F8
.byte $A8
.byte $71
.byte $00
.byte $F8
.byte $A8
.byte $B1
.byte $F8
.byte $F8
.byte $A8
.byte $F1
.byte $00
.byte $F8
.byte $A8
BARREL1:
.byte $04
.byte $31
.byte $F8
.byte $F8
.byte $AA
.byte $31
.byte $00
.byte $F8
.byte $AB
.byte $F1
.byte $F8
.byte $F8
.byte $AB
.byte $F1
.byte $00
.byte $F8
.byte $AA
BARREL2:
.byte $04
.byte $31
.byte $F8
.byte $F8
.byte $A9
.byte $71
.byte $00
.byte $F8
.byte $A9
.byte $B1
.byte $F8
.byte $F8
.byte $A9
.byte $F1
.byte $00
.byte $F8
.byte $A9
CANONS:
.byte $01
.byte $22
.byte $F4
.byte $00
.byte <(CANONDATA)
.byte >(CANONDATA)
PLATFORMSPR:
.byte $01
.byte $21
.byte $F4
.byte $01
.byte <(PLATDATA)
.byte >(PLATDATA)
TRAMPET1:
.byte $04
.byte $32
.byte $F8
.byte $00
.byte $A2
.byte $72
.byte $00
.byte $00
.byte $A2
.byte $32
.byte $F8
.byte $08
.byte $A3
.byte $72
.byte $00
.byte $08
.byte $A3
TRAMPET2:
.byte $02
.byte $32
.byte $F8
.byte $08
.byte $A1
.byte $72
.byte $00
.byte $08
.byte $A1
SPIDERSPR:
.byte $02
.byte $21
.byte $F8
.byte $F8
.byte <(SPIDER1)
.byte >(SPIDER1)
.byte $61
.byte $00
.byte $F8
.byte <(SPIDER1)
.byte >(SPIDER1)
SPIDERSPR1:
.byte $02
.byte $21
.byte $F8
.byte $F8
.byte <(SPIDER2)
.byte >(SPIDER2)
.byte $61
.byte $00
.byte $F8
.byte <(SPIDER2)
.byte >(SPIDER2)
SPIDER1:
.byte $12,$A4,$A5
SPIDER2:
.byte $12,$A6,$A7
BAT1:
.byte $02
.byte $31
.byte $F8
.byte $FC
.byte $9F
.byte $71
.byte $00
.byte $FC
.byte $9F
BAT2:
.byte $02
.byte $31
.byte $F8
.byte $FB
.byte $A0
.byte $71
.byte $00
.byte $FB
.byte $A0
COINDATA:
.byte $12,$B3,$B4
CANONDATA:
.byte $32,$B7,$B8,$B9,$BA,$BB,$BC
PLATDATA:
.byte $31,$AC,$AD,$AE
DEADARROW1:
.byte $04
.byte $31
.byte $F0
.byte $10
.byte $C7
.byte $71
.byte $10
.byte $10
.byte $C7
.byte $F1
.byte $10
.byte $F0
.byte $C7
.byte $B1
.byte $F0
.byte $F0
.byte $C7
DEADARROW2:
.byte $04
.byte $31
.byte $F4
.byte $0C
.byte $C7
.byte $71
.byte $0C
.byte $0C
.byte $C7
.byte $F1
.byte $0C
.byte $F4
.byte $C7
.byte $B1
.byte $F4
.byte $F4
.byte $C7
DEADARROW3:
.byte $04
.byte $31
.byte $F8
.byte $08
.byte $C7
.byte $71
.byte $08
.byte $08
.byte $C7
.byte $F1
.byte $08
.byte $F8
.byte $C7
.byte $B1
.byte $F8
.byte $F8
.byte $C7
DEADARROW4:
.byte $04
.byte $31
.byte $FC
.byte $04
.byte $C7
.byte $71
.byte $04
.byte $04
.byte $C7
.byte $F1
.byte $04
.byte $FC
.byte $C7
.byte $B1
.byte $FC
.byte $FC
.byte $C7
EYE1:
.byte $02
.byte $31
.byte $FC
.byte $00
.byte $C5
.byte $71
.byte $04
.byte $00
.byte $C5
EYE2:
.byte $02
.byte $31
.byte $FD
.byte $00
.byte $C6
.byte $31
.byte $02
.byte $00
.byte $C6
EYE3:
.byte $02
.byte $F1
.byte $FD
.byte $F8
.byte $C6
.byte $F1
.byte $03
.byte $F8
.byte $C6
EYE4:
.byte $02
.byte $F1
.byte $FE
.byte $F8
.byte $C6
.byte $F1
.byte $04
.byte $F8
.byte $C6
GUARDLOW:
.byte $02
.byte $34
.byte $08
.byte $EE
.byte $EC
.byte $24
.byte $F8
.byte $E0
.byte <(GUARDBODY)
.byte >(GUARDBODY)
GUARDBODY:
.byte $24,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB
GUARDHIGH:
.byte $02
.byte $34
.byte $08
.byte $E8
.byte $F1
.byte $24
.byte $F8
.byte $E0
.byte <(GUARDBODY1)
.byte >(GUARDBODY1)
GUARDBODY1:
.byte $24,$E4,$E5,$ED,$EE,$EF,$F0,$EA,$EB
GUARDLOW1:
.byte $03
.byte $34
.byte $06
.byte $EE
.byte $EC
.byte $3C
.byte $F7
.byte $E0
.byte $E4
.byte $3C
.byte $F8
.byte $F0
.byte $E8
GUARDHIGH1:
.byte $03
.byte $34
.byte $06
.byte $E8
.byte $F1
.byte $24
.byte $F7
.byte $E0
.byte <(GUARDBODY2)
.byte >(GUARDBODY2)
.byte $24
.byte $F8
.byte $F0
.byte <(GUARDBODY3)
.byte >(GUARDBODY3)
GUARDBODY2:
.byte $22,$E4,$E5,$ED,$EE
GUARDBODY3:
.byte $22,$EF,$F0,$EA,$EB
FIRE1:
.byte $01
.byte $B3
.byte $FC
.byte $08
.byte $95
FIRE2:
.byte $04
.byte $33
.byte $FB
.byte $F0
.byte $BF
.byte $33
.byte $FE
.byte $F0
.byte $C0
.byte $33
.byte $FB
.byte $F4
.byte $C1
.byte $33
.byte $FE
.byte $F4
.byte $C2
FIRE3:
.byte $04
.byte $33
.byte $F9
.byte $F0
.byte $BF
.byte $33
.byte $FF
.byte $F0
.byte $C0
.byte $33
.byte $F9
.byte $F6
.byte $C1
.byte $33
.byte $FF
.byte $F6
.byte $C2
FIRE4:
.byte $03
.byte $3B
.byte $F8
.byte $F0
.byte $BF
.byte $33
.byte $F8
.byte $FC
.byte $C3
.byte $33
.byte $00
.byte $FC
.byte $C4
FIRE5:
.byte $03
.byte $3B
.byte $F8
.byte $F0
.byte $BF
.byte $33
.byte $F8
.byte $00
.byte $C3
.byte $33
.byte $00
.byte $00
.byte $C4
MARIONS:
.byte $04
.byte $23
.byte $00
.byte $00
.byte <(MARION1)
.byte >(MARION1)
.byte $23
.byte $02
.byte $08
.byte <(MARION2)
.byte >(MARION2)
.byte $3B
.byte $03
.byte $10
.byte $FA
.byte $23
.byte $02
.byte $20
.byte <(MARION3)
.byte >(MARION3)
MARION1:
.byte $21,$F6,$F7
MARION2:
.byte $21,$F8,$F9
MARION3:
.byte $21,$FE,$FF
PAUSES:
.byte $05
.byte $32
.byte $00
.byte $00
.byte $7A
.byte $32
.byte $0A
.byte $00
.byte $7B
.byte $32
.byte $14
.byte $00
.byte $7C
.byte $32
.byte $1E
.byte $00
.byte $7D
.byte $32
.byte $28
.byte $00
.byte $7E
.byte $32
.byte $32
.byte $00
.byte $7F
