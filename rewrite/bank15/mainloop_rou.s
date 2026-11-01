anewgame:
jsr change_bank13_routine
jsr titlescreen
jsr change_bank12_routine
jsr clearfullspriteblock
asl VBLANK_FLAG
@anewgame_wait_vblank:
bit VBLANK_FLAG
bpl @anewgame_wait_vblank
lda #0
sta GAME_COMPLETED
startlives:
ldx #3
lda JOYPAD_STATE
and #BUTTON_LEFT_MASK + BUTTON_A_MASK
cmp #BUTTON_LEFT_MASK + BUTTON_A_MASK
bne normal3lives
ldx #4
normal3lives:
stx PLAYER_LIVES
lda #0
sta PLAYER_HEARTS
jsr resetscore
jsr resetextras
lda #1
sta IN_GAME
lda #CHARSET_ROBIN
jsr copyblockofcompactedchrs
jsr resetrobinvars
jsr resetrobinvars1
lda #START_LEVEL
sta MAP_NUMBER
jsr gointonewmap
ingameloop:
lda #0
sta FRAME_FINISHED
sta FILLED_BLOCK_BUFFER
asl VBLANK_FLAG
@ingameloop_wait_vblank:
bit VBLANK_FLAG
bpl @ingameloop_wait_vblank
lda #1
sta FRAME_FINISHED
sta FILLED_BLOCK_BUFFER
lda JUST_STARTED_LIFE
beq @ingameloop_skip_if_equal
jsr zoominstars
@ingameloop_skip_if_equal:
lda GAME_PAUSED
beq @ingameloop_skip_if_equal_2
lda JOYPAD_STATE
and #BUTTON_START_MASK
bne @ingameloop_skip_if_not_equal
lda #256 - 4 * 6
sta SPRITE_BLOCK_POINTER
ldy #80
lda PLAYER_Y
cmp #124
bcs @ingameloop_skip_if_carry
ldy #128
@ingameloop_skip_if_carry:
ldx #128 - 25 - 4
lda #SPRITE_PAUSE
jsr printsprite
@ingameloop_skip_if_not_equal:
jmp endofmainloop
@ingameloop_skip_if_equal_2:
jsr doorrou
jsr printlives
jsr printscore
jsr printhearts
jsr moveman
jsr animatelegs
jsr setxscroll
jsr updatearrows
jsr change_bank13_routine
jsr printrobin
jsr float_up_number
jsr change_bank12_routine
jsr updatespitters
lda FRAME_COUNTER
and #1
bne @ingameloop_skip_if_not_equal_2
jsr updateonscreens
jsr putextrason
jsr change_bank13_routine
jsr updatehearts
jsr change_bank12_routine
jmp @ingameloop_skip
@ingameloop_skip_if_not_equal_2:
jsr change_bank13_routine
jsr updatehearts
jsr change_bank12_routine
jsr putextrason
jsr updateonscreens
@ingameloop_skip:
endofmainloop:
jsr checkforpausekey
jsr checkoffscreen
nearendofmainloop:
lda PLAYER_KILLED
beq @nearendofmainloop_skip_if_equal
cmp #1
bne @nearendofmainloop_skip_if_not_equal
lda #255
sta PLAYER_Y
@nearendofmainloop_skip_if_not_equal:
lda GAME_PAUSED
bne @nearendofmainloop_skip_if_equal
dec PLAYER_KILLED
bne @nearendofmainloop_skip_if_equal
@nearendofmainloop_body:
lda PLAYER_LIVES
beq theend
jsr resetrobinvars1
jsr restoreoldrobin
lda #190
sta PLAYER_INVINCIBILITY_TIMER
jsr gointonewmap
@nearendofmainloop_skip_if_equal:
lda FADE_COUNTER
cmp #255
beq @nearendofmainloop_skip_if_equal_2
jmp ingameloop
@nearendofmainloop_skip_if_equal_2:
theend:
lda GAME_COMPLETED
bne completedthegame
lda #255
sta PLAYER_HEARTS
completedthegame:
jsr resetrobinvars1
jsr turninteroff
lda #0
sta IN_GAME
jsr change_bank13_routine
jsr try_to_enter_name
jsr change_bank12_routine
jmp anewgame
zoominstars:
dec JUST_STARTED_LIFE
lda JUST_STARTED_LIFE
cmp #30
bcc @zoominstars_skip_if_no_carry
and #3
bne @zoominstars_skip_if_no_carry
lda #SFX_FIRST_APPEAR
jsr soundfx
lda #2
jmp startstars
@zoominstars_skip_if_no_carry:
rts