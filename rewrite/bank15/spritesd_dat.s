spritetable:
SPRITE_ROBIN_HEADS = (* - spritetable) / 2
.word head0
.word head1
.word head2
.word head3
SPRITE_ROBIN_BODIES = (* - spritetable) / 2
.word robinbody0
.word robinbody1
.word robinbody2
.word robinbody3
.word robinbody4
.word robinbody5
.word robinbody6
.word robinbody3
SPRITE_BODY_FIRING = (* - spritetable) / 2
.word robinstanding
.word bodyfire0
.word bodyfire1
.word bodyfire2
.word bodyfire3
SPRITE_LEGS_RUNNING = (* - spritetable) / 2
.word legsrunning0
.word legsrunning1
.word legsrunning2
.word legsrunning3
.word legsrunning4
.word legsrunning5
.word legsrunning6
.word legsrunning3
SPRITE_MORE_LEGS = (* - spritetable) / 2
.word legsstanding
.word legshalfcrouch
.word bodyfullcrouch
.word legsfullcrouch
.word legsjumping
.word bodyonladder
.word legsonladder
SPRITE_BARRELS = (* - spritetable) / 2
.word barrel0
.word barrel1
.word barrel2
.word barrel1
SPRITE_CANNON = (* - spritetable) / 2
.word canons
SPRITE_PLATFORM = (* - spritetable) / 2
.word platformspr
SPRITE_TITLE_LOGOS = (* - spritetable) / 2
.word codemasters_logo
.word camerica_logo
.word press_start
SPRITE_DEAD_ARROWS = (* - spritetable) / 2
.word deadarrow1
.word deadarrow2
.word deadarrow3
.word deadarrow4
SPRITE_TRAMPOLINE = (* - spritetable) / 2
.word trampet1
.word trampet2
SPRITE_SPIDER = (* - spritetable) / 2
.word spiderspr
.word spiderspr1
SPRITE_BAT = (* - spritetable) / 2
.word bat1
.word bat2
SPRITE_EYES = (* - spritetable) / 2
.word eye1
.word eye2
.word eye3
.word eye4
SPRITE_GUARD = (* - spritetable) / 2
.word guardlow
.word guardhigh
.word guardlow1
.word guardhigh1
SPRITE_FIRE = (* - spritetable) / 2
.word fire1
.word fire2
.word fire3
.word fire4
.word fire5
SPRITE_MARIONETTE = (* - spritetable) / 2
.word marions
SPRITE_PAUSE = (* - spritetable) / 2
.word pauses
spritedefs:
codemasters_logo:
.byte $07
.byte $00
.byte <(codemasters_logo_data_0)
.byte >(codemasters_logo_data_0)
.byte $20
.byte $FD
.byte $08
.byte <(codemasters_logo_data_1)
.byte >(codemasters_logo_data_1)
.byte $20
.byte $F8
.byte $10
.byte <(codemasters_logo_data_2)
.byte >(codemasters_logo_data_2)
.byte $20
.byte $F8
.byte $18
.byte <(codemasters_logo_data_3)
.byte >(codemasters_logo_data_3)
.byte $20
.byte $FB
.byte $20
.byte <(codemasters_logo_data_4)
.byte >(codemasters_logo_data_4)
.byte $20
.byte $05
.byte $28
.byte <(codemasters_logo_data_5)
.byte >(codemasters_logo_data_5)
.byte $30
.byte $F8
.byte $24
.byte $F2
codemasters_logo_data_0:
.byte $41
.byte $D5,$D6,$D7,$D8
codemasters_logo_data_1:
.byte $51
.byte $D9,$DA,$DB,$DC,$DD
codemasters_logo_data_2:
.byte $61
.byte $DE,$DF,$E0,$E1,$E2,$E3
codemasters_logo_data_3:
.byte $61
.byte $E4,$E5,$E6,$E7,$E8,$E9
codemasters_logo_data_4:
.byte $51
.byte $EA,$EB,$EC,$ED,$EE
codemasters_logo_data_5:
.byte $31
.byte $EF,$F0,$F1
camerica_logo:
.byte $02
.byte $01
.byte <(camerica_logo_data_0)
.byte >(camerica_logo_data_0)
.byte $21
.byte $06
.byte $10
.byte <(camerica_logo_data_1)
.byte >(camerica_logo_data_1)
camerica_logo_data_0:
.byte $82
.byte $DC,$DD,$DE,$DF,$E0,$E1,$E2,$E3
.byte $E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB
camerica_logo_data_1:
.byte $61
.byte $EC,$ED,$ED,$ED,$ED,$EE
press_start:
.byte $02
.byte $02
.byte <(press_start_data)
.byte >(press_start_data)
.byte $22
.byte $00
.byte $0A
.byte <(press_start_data_1)
.byte >(press_start_data_1)
press_start_data:
.byte $51
.byte $EF,$F0,$F1,$F2,$F2
press_start_data_1:
.byte $51
.byte $F2,$F3,$F4,$F0,$F3
head0:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $01
head1:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $05
head2:
.byte $01
.byte $3C
.byte $FB
.byte $F1
.byte $09
head3:
.byte $01
.byte $7C
.byte $F8
.byte $F1
.byte $0D
robinbody0:
.byte $01
.byte $24
.byte $F9
.byte $F2
.byte <(body0data)
.byte >(body0data)
robinbody1:
.byte $01
.byte $24
.byte $F7
.byte $F1
.byte <(body1data)
.byte >(body1data)
robinbody2:
.byte $01
.byte $24
.byte $F8
.byte $F3
.byte <(body2data)
.byte >(body2data)
robinbody3:
.byte $01
.byte $3C
.byte $FA
.byte $F4
.byte $23
robinbody4:
.byte $01
.byte $3C
.byte $FA
.byte $F5
.byte $27
robinbody5:
.byte $01
.byte $24
.byte $F8
.byte $F3
.byte <(body5data)
.byte >(body5data)
robinbody6:
.byte $01
.byte $3C
.byte $F9
.byte $F3
.byte $31
body0data:
.byte $32
.byte $11,$12,$13,$14,$15,$16
body1data:
.byte $32
.byte $17,$18,$19,$1A,$1B,$1C
body2data:
.byte $32
.byte $1D,$1E,$1F,$20,$21,$22
body5data:
.byte $32
.byte $2B,$2C,$2D,$2E,$2F,$30
robinstanding:
.byte $01
.byte $24
.byte $F8
.byte $F1
.byte <(robstanddata)
.byte >(robstanddata)
robstanddata:
.byte $23
.byte $35,$36,$37,$38,$39,$3A
bodyfire0:
.byte $03
.byte $24
.byte $F8
.byte $F1
.byte <(bodyfire0data0)
.byte >(bodyfire0data0)
.byte $24
.byte $00
.byte $F1
.byte <(bodyfire0data1)
.byte >(bodyfire0data1)
.byte $24
.byte $08
.byte $F5
.byte <(bodyfire0data2)
.byte >(bodyfire0data2)
bodyfire0data0:
.byte $12
.byte $35,$3B
bodyfire0data1:
.byte $13
.byte $36,$3C,$3D
bodyfire0data2:
.byte $12
.byte $3E,$3F
bodyfire1:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(bodyfire1data)
.byte >(bodyfire1data)
.byte $34
.byte $08
.byte $01
.byte $44
bodyfire1data:
.byte $32
.byte $35,$36,$40,$41,$42,$43
bodyfire2:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(bodyfire2data)
.byte >(bodyfire2data)
.byte $34
.byte $08
.byte $01
.byte $49
bodyfire2data:
.byte $32
.byte $35,$45,$46,$41,$47,$48
bodyfire3:
.byte $02
.byte $24
.byte $F8
.byte $F1
.byte <(bodyfire3data)
.byte >(bodyfire3data)
.byte $34
.byte $08
.byte $01
.byte $4E
bodyfire3data:
.byte $32
.byte $35,$4A,$4B,$41,$4C,$4D
legsrunning0:
.byte $02
.byte $24
.byte $FA
.byte $F2
.byte <(legsrunning0data0)
.byte >(legsrunning0data0)
.byte $24
.byte $F8
.byte $FA
.byte <(legsrunning0data1)
.byte >(legsrunning0data1)
legsrunning0data0:
.byte $21
.byte $4F,$50
legsrunning0data1:
.byte $21
.byte $51,$52
legsrunning1:
.byte $02
.byte $24
.byte $F3
.byte $F3
.byte <(legsrunning1data)
.byte >(legsrunning1data)
.byte $34
.byte $03
.byte $FB
.byte $56
legsrunning1data:
.byte $31
.byte $53,$54,$55
legsrunning2:
.byte $01
.byte $3C
.byte $F6
.byte $F2
.byte $57
legsrunning3:
.byte $02
.byte $24
.byte $FA
.byte $F2
.byte <(legsrunning3data)
.byte >(legsrunning3data)
.byte $34
.byte $FA
.byte $FA
.byte $5D
legsrunning3data:
.byte $21
.byte $5B,$5C
legsrunning4:
.byte $02
.byte $24
.byte $F9
.byte $F2
.byte <(legsrunning4data0)
.byte >(legsrunning4data0)
.byte $24
.byte $F8
.byte $FA
.byte <(legsrunning4data1)
.byte >(legsrunning4data1)
legsrunning4data0:
.byte $21
.byte $5E,$5F
legsrunning4data1:
.byte $21
.byte $51,$52
legsrunning5:
.byte $02
.byte $24
.byte $F4
.byte $F3
.byte <(legsrunning5data)
.byte >(legsrunning5data)
.byte $34
.byte $04
.byte $FB
.byte $56
legsrunning5data:
.byte $31
.byte $53,$60,$55
legsrunning6:
.byte $01
.byte $24
.byte $F7
.byte $F2
.byte <(legsrunning6data)
.byte >(legsrunning6data)
legsrunning6data:
.byte $22
.byte $57,$61,$59,$5A
legsstanding:
.byte $01
.byte $3C
.byte $FC
.byte $F2
.byte $62
legshalfcrouch:
.byte $02
.byte $24
.byte $F9
.byte $F3
.byte <(legshalfcrouchdata0)
.byte >(legshalfcrouchdata0)
.byte $24
.byte $F8
.byte $FB
.byte <(legshalfcrouchdata1)
.byte >(legshalfcrouchdata1)
legshalfcrouchdata0:
.byte $21
.byte $66,$67
legshalfcrouchdata1:
.byte $21
.byte $68,$69
bodyfullcrouch:
.byte $01
.byte $24
.byte $FB
.byte $F9
.byte <(bodyfullcrouchdata)
.byte >(bodyfullcrouchdata)
bodyfullcrouchdata:
.byte $21
.byte $6A,$6B
legsfullcrouch:
.byte $01
.byte $24
.byte $F7
.byte $F9
.byte <(legsfullcrouchdata)
.byte >(legsfullcrouchdata)
legsfullcrouchdata:
.byte $31
.byte $6C,$6D,$6E
legsjumping:
.byte $03
.byte $24
.byte $F3
.byte $F6
.byte <(legsjumpdata)
.byte >(legsjumpdata)
.byte $34
.byte $03
.byte $F5
.byte $71
.byte $34
.byte $05
.byte $FB
.byte $56
legsjumpdata:
.byte $21
.byte $6F,$70
bodyonladder:
.byte $01
.byte $3C
.byte $F7
.byte $F1
.byte $72
legsonladder:
.byte $02
.byte $24
.byte $FB
.byte $F4
.byte <(legsladderdata)
.byte >(legsladderdata)
.byte $34
.byte $FB
.byte $FC
.byte $78
legsladderdata:
.byte $21
.byte $76,$77
barrel0:
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
barrel1:
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
barrel2:
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
canons:
.byte $01
.byte $22
.byte $F4
.byte $00
.byte <(canondata)
.byte >(canondata)
platformspr:
.byte $01
.byte $21
.byte $F4
.byte $01
.byte <(platdata)
.byte >(platdata)
trampet1:
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
trampet2:
.byte $02
.byte $32
.byte $F8
.byte $08
.byte $A1
.byte $72
.byte $00
.byte $08
.byte $A1
spiderspr:
.byte $02
.byte $21
.byte $F8
.byte $F8
.byte <(spider1)
.byte >(spider1)
.byte $61
.byte $00
.byte $F8
.byte <(spider1)
.byte >(spider1)
spiderspr1:
.byte $02
.byte $21
.byte $F8
.byte $F8
.byte <(spider2)
.byte >(spider2)
.byte $61
.byte $00
.byte $F8
.byte <(spider2)
.byte >(spider2)
spider1:
.byte $12,$A4,$A5
spider2:
.byte $12,$A6,$A7
bat1:
.byte $02
.byte $31
.byte $F8
.byte $FC
.byte $9F
.byte $71
.byte $00
.byte $FC
.byte $9F
bat2:
.byte $02
.byte $31
.byte $F8
.byte $FB
.byte $A0
.byte $71
.byte $00
.byte $FB
.byte $A0
coindata:
.byte $12,$B3,$B4
canondata:
.byte $32,$B7,$B8,$B9,$BA,$BB,$BC
platdata:
.byte $31,$AC,$AD,$AE
deadarrow1:
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
deadarrow2:
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
deadarrow3:
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
deadarrow4:
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
eye1:
.byte $02
.byte $31
.byte $FC
.byte $00
.byte $C5
.byte $71
.byte $04
.byte $00
.byte $C5
eye2:
.byte $02
.byte $31
.byte $FD
.byte $00
.byte $C6
.byte $31
.byte $02
.byte $00
.byte $C6
eye3:
.byte $02
.byte $F1
.byte $FD
.byte $F8
.byte $C6
.byte $F1
.byte $03
.byte $F8
.byte $C6
eye4:
.byte $02
.byte $F1
.byte $FE
.byte $F8
.byte $C6
.byte $F1
.byte $04
.byte $F8
.byte $C6
guardlow:
.byte $02
.byte $34
.byte $08
.byte $EE
.byte $EC
.byte $24
.byte $F8
.byte $E0
.byte <(guardbody)
.byte >(guardbody)
guardbody:
.byte $24,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB
guardhigh:
.byte $02
.byte $34
.byte $08
.byte $E8
.byte $F1
.byte $24
.byte $F8
.byte $E0
.byte <(guardbody1)
.byte >(guardbody1)
guardbody1:
.byte $24,$E4,$E5,$ED,$EE,$EF,$F0,$EA,$EB
guardlow1:
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
guardhigh1:
.byte $03
.byte $34
.byte $06
.byte $E8
.byte $F1
.byte $24
.byte $F7
.byte $E0
.byte <(guardbody2)
.byte >(guardbody2)
.byte $24
.byte $F8
.byte $F0
.byte <(guardbody3)
.byte >(guardbody3)
guardbody2:
.byte $22,$E4,$E5,$ED,$EE
guardbody3:
.byte $22,$EF,$F0,$EA,$EB
fire1:
.byte $01
.byte $B3
.byte $FC
.byte $08
.byte $95
fire2:
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
fire3:
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
fire4:
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
fire5:
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
marions:
.byte $04
.byte $23
.byte $00
.byte $00
.byte <(marion1)
.byte >(marion1)
.byte $23
.byte $02
.byte $08
.byte <(marion2)
.byte >(marion2)
.byte $3B
.byte $03
.byte $10
.byte $FA
.byte $23
.byte $02
.byte $20
.byte <(marion3)
.byte >(marion3)
marion1:
.byte $21,$F6,$F7
marion2:
.byte $21,$F8,$F9
marion3:
.byte $21,$FE,$FF
pauses:
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