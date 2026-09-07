        processor 6502
; FLOATING IN A MOST PECULIAR WAY -- stage-rendered title laboratory

VSYNC=$00
VBLANK=$01
WSYNC=$02
NUSIZ0=$04
COLUP0=$06
COLUPF=$08
COLUBK=$09
CTRLPF=$0A
PF0=$0D
PF1=$0E
PF2=$0F
RESP0=$10
GRP0=$1B
GRP1=$1C
HMP0=$20
VDELP0=$25
HMOVE=$2A
AUDC0=$15
AUDC1=$16
AUDF0=$17
AUDF1=$18
AUDV0=$19
AUDV1=$1A
INTIM=$0284
TIM64T=$0296
POSITION_BIAS=49
TITLE_GRAVITY=4
TITLE_MAX_FALL=$E0
TITLE_FLOOR_Y=138

        SEG.U RAM
        ORG $80
titleFrame ds 1
colorPtr ds 2
tomX ds 1
tomXLo ds 1
tomY ds 1
tomYLo ds 1
tomVelXHi ds 1
tomVelXLo ds 1
tomVelYHi ds 1
tomVelYLo ds 1
wallLeft ds 1
wallRight ds 1
renderTomY ds 1
musicFrame ds 1
musicStep ds 1

        SEG CODE
        ORG $F000
Reset:
        sei
        cld
        ldx #$FF
        txs
        lda #0
.clear:
        sta $00,x
        dex
        bne .clear
        lda #32
        sta tomX
        lda #0
        sta tomXLo
        sta tomYLo
        sta tomVelXHi
        lda #$80
        sta tomVelXLo
        lda #120
        sta tomY
        lda #$FF
        sta tomVelYHi
        lda #$A0
        sta tomVelYLo

Frame:
        inc titleFrame
        lda #2
        sta VBLANK
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #43
        sta TIM64T
        jsr SelectColorPhase
        jsr UpdateTom
        jsr UpdateTitleMusic
        lda tomX
        ldx #0
        jsr PositionObject
        sta WSYNC
        sta HMOVE
.waitVB:
        lda INTIM
        bne .waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta COLUBK
        sta CTRLPF
        sta GRP0
        lda #0
        sta NUSIZ0

        ldy #0
.titleRow:
        lda (colorPtr),y
        sta WSYNC
        sta COLUPF
        lda TitlePF0L,y
        sta PF0
        lda TitlePF1L,y
        sta PF1
        lda TitlePF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TitlePF0R,y
        sta PF0
        lda TitlePF1R,y
        sta PF1
        lda TitlePF2R,y
        sta PF2
        iny
        cpy #96
        bne .titleRow

        ; The lower vignette uses reflected terrain, leaving deterministic
        ; time for the independently moving Major Tom player object.  P0 is
        ; delayed by one scanline so its bitmap is transferred during HBLANK;
        ; rewriting GRP0 while the beam is visible caused a vertical tear when
        ; Tom crossed the kernel's write position near the screen center.
        lda #1
        sta CTRLPF
        sta VDELP0
        lda tomY
        sec
        sbc #1
        sta renderTomY
        lda #$0E
        sta COLUP0
        lda #0
        sta GRP0
        sta GRP1
.stageRow:
        lda #0
        sta WSYNC
        ; Any GRP1 write transfers the previously prepared delayed P0 value.
        ; This happens safely in horizontal blank, before visible pixels begin.
        sta GRP1
        lda (colorPtr),y
        sta COLUPF
        lda TitlePF0L,y
        sta PF0
        lda TitlePF1L,y
        sta PF1
        lda TitlePF2L,y
        sta PF2
        tya
        sec
        sbc renderTomY
        cmp #14
        bcs .noTom
        lsr
        tax
        lda TitleTom,x
        sta GRP0
        jmp .stageNext
.noTom:
        lda #0
        sta GRP0
.stageNext:
        iny
        cpy #160
        bne .stageRow

        ; The footer returns to the title's proven asymmetric playfield text.
        ; Its 3x5 glyphs retain the same vertical proportions as the headline.
        lda #0
        sta GRP0
        sta GRP1
        sta VDELP0
        sta CTRLPF
.creditRow:
        lda (colorPtr),y
        sta WSYNC
        sta COLUPF
        lda TitlePF0L,y
        sta PF0
        lda TitlePF1L,y
        sta PF1
        lda TitlePF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TitlePF0R,y
        sta PF0
        lda TitlePF1R,y
        sta PF1
        lda TitlePF2R,y
        sta PF2
        iny
        cpy #192
        bne .creditRow

        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #30
.overscan:
        sta WSYNC
        dex
        bne .overscan
        jmp Frame

SelectColorPhase:
        lda titleFrame
        lsr
        lsr
        lsr
        and #3
        tax
        lda ColorLow,x
        sta colorPtr
        lda ColorHigh,x
        sta colorPtr+1
        rts

UpdateTom:
        ; Same signed 8.8 free-flight integration used by production stages.
        clc
        lda tomVelYLo
        adc #TITLE_GRAVITY
        sta tomVelYLo
        lda tomVelYHi
        adc #0
        sta tomVelYHi
        bmi .fallReady
        bne .capFall
        lda tomVelYLo
        cmp #TITLE_MAX_FALL
        bcc .fallReady
.capFall:
        lda #0
        sta tomVelYHi
        lda #TITLE_MAX_FALL
        sta tomVelYLo
.fallReady:
        clc
        lda tomXLo
        adc tomVelXLo
        sta tomXLo
        lda tomX
        adc tomVelXHi
        sta tomX
        clc
        lda tomYLo
        adc tomVelYLo
        sta tomYLo
        lda tomY
        adc tomVelYHi
        sta tomY

        lda tomVelYHi
        bmi .checkSides
        lda tomY
        cmp #TITLE_FLOOR_Y+1
        bcc .checkSides
        lda #TITLE_FLOOR_Y
        sta tomY
        lda #0
        sta tomYLo
        lda #$FF
        sta tomVelYHi
        lda #$40
        sta tomVelYLo
.checkSides:
        ; Match the complete 8x14 astronaut rectangle to the generated rock
        ; contour at his present height. Right limit = 160 - wall - 8.
        lda tomY
        sec
        sbc #96
        tax
        lda TitleWallLimit,x
        ; RESP0/HMOVE places the visible left edge one color clock inside the
        ; logical playfield coordinate. Compensate on this side only so Tom's
        ; suit reaches the rock with no apparent invisible one-pixel wall.
        sec
        sbc #1
        sta wallLeft
        lda #152
        sec
        sbc wallLeft
        sta wallRight
        lda tomVelXHi
        bmi .movingLeft
        lda tomX
        cmp wallRight
        bcc .done
        beq .done
        lda wallRight
        sta tomX
        lda #0
        sta tomXLo
        lda #$FF
        sta tomVelXHi
        lda #$80
        sta tomVelXLo
        rts
.movingLeft:
        lda tomX
        cmp #160
        bcs .hitLeft
        cmp wallLeft
        bcs .done
.hitLeft:
        lda wallLeft
        sta tomX
        lda #0
        sta tomXLo
        sta tomVelXHi
        lda #$80
        sta tomVelXLo
.done:
        rts

PositionObject:
        clc
        adc #POSITION_BIAS
        sec
        sta WSYNC
.divide15:
        sbc #15
        bcs .divide15
        sta RESP0,x
        eor #$FF
        adc #$F9
        asl
        asl
        asl
        asl
        sta HMP0,x
        rts

; Eight 4/4 bars at 21 NTSC frames per eighth note: 85.7 BPM, effectively the
; requested 86 BPM. Channel 0 plays a breathing mid-register arpeggio while
; Channel 1 adds two quiet low supports per bar. Both voices include silence
; between attacks, and the divider range avoids the TIA's abrasive extremes.
UpdateTitleMusic:
        inc musicFrame
        lda musicFrame
        cmp #21
        bcc .renderLead
        lda #0
        sta musicFrame
        inc musicStep
        lda musicStep
        and #$3F
        sta musicStep
.renderLead:
        ldx musicStep
        lda TitleArpeggio,x
        sta AUDF0
        lda #12
        sta AUDC0
        lda musicFrame
        cmp #3
        bcc .leadAttack
        cmp #12
        bcc .leadBody
        cmp #16
        bcc .leadRelease
        lda #0
        beq .storeLead
.leadAttack:
        lda #1
        bne .storeLead
.leadBody:
        lda #2
        bne .storeLead
.leadRelease:
        lda #1
.storeLead:
        sta AUDV0

        ; A soft supporting tone sounds only on beats one and three. Its
        ; timbre is lower and quieter than the arpeggio, never a percussion
        ; substitute or a continuous drone.
        ldx musicStep
        txa
        and #3
        bne .muteBass
        txa
        lsr
        lsr
        lsr
        tax
        lda TitleBassNotes,x
        sta AUDF1
        lda #6
        sta AUDC1
        lda musicFrame
        cmp #10
        bcs .muteBass
        lda #1
        sta AUDV1
        rts
.muteBass:
        lda #0
        sta AUDV1
        rts

ColorLow:
        byte <TitleColors0,<TitleColors1,<TitleColors2,<TitleColors3
ColorHigh:
        byte >TitleColors0,>TitleColors1,>TitleColors2,>TitleColors3
TitleTom:
        ; Exact approved production silhouette from thursdays-child.asm.
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

; A - E - D - Bm - Em - F#m - G - B. Coarse TIA tuning makes a few thirds
; approximate, so the voicings emphasize clean roots and fifths while still
; distinguishing the minor chords. All lead dividers stay between 10 and 25.
TitleArpeggio:
        byte 23,18,15,11,15,18,15,18 ; A
        byte 15,10,15,10,12,10,15,10 ; E
        byte 17,13,11,13,17,13,11,13 ; D
        byte 20,17,13,10,13,17,13,17 ; Bm
        byte 15,12,10,12,15,12,10,12 ; Em
        byte 13,11,18,11,13,11,18,11 ; F#m
        byte 25,20,17,12,17,20,17,20 ; G
        byte 20,16,13,10,13,16,13,16 ; B

; One safe low-register support per chord. E and D use their fifths because
; their roots would fall beyond the clean divider range in this bass timbre.
TitleBassNotes:
        byte 23,21,23,21,21,27,25,21

        include "thursdays-child-title-lab.inc"
        ORG $FFFA
        word Reset,Reset,Reset
