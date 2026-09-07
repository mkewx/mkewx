; Integrated Bank 1 title. Presentation state reuses gameplay RAM only before
; LoadCurrentStage rebuilds a new run; the approved renderer and motion values
; remain identical to the standalone title checkpoint.
TITLE_GRAVITY = 4
TITLE_MAX_FALL = $E0
TITLE_FLOOR_Y = 138

TitleInit:
        lda #32
        sta tomXHi
        lda #0
        sta tomXLo
        sta tomYLo
        sta velXHi
        sta frameCounter
        sta bestDistance
        sta bestBeacon
        lda #$80
        sta velXLo
        lda #120
        sta tomYHi
        lda #$FF
        sta velYHi
        lda #$A0
        sta velYLo
        lda #1
        sta fireWasDown
        jmp TitleFrame

TitleFrame:
        inc frameCounter
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
        jsr TitleReadControls
        jsr TitleSelectColorPhase
        jsr TitleUpdateTom
        jsr UpdateTitleMusic
        lda tomXHi
        ldx #0
        jsr TitlePositionObject
        sta WSYNC
        sta HMOVE
.ti_waitVB:
        lda INTIM
        bne .ti_waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta COLUBK
        sta CTRLPF
        sta GRP0
        lda #0
        sta NUSIZ0

        ldy #0
.ti_titleRow:
        lda (suitPtr),y
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
        bne .ti_titleRow

        ; The lower vignette uses reflected terrain, leaving deterministic
        ; time for the independently moving Major Tom player object.  P0 is
        ; delayed by one scanline so its bitmap is transferred during HBLANK;
        ; rewriting GRP0 while the beam is visible caused a vertical tear when
        ; Tom crossed the kernel's write position near the screen center.
        lda #1
        sta CTRLPF
        sta VDELP0
        lda tomYHi
        sec
        sbc #1
        sta renderTomY
        lda #$0E
        sta COLUP0
        lda #0
        sta GRP0
        sta GRP1
.ti_stageRow:
        lda #0
        sta WSYNC
        ; Any GRP1 write transfers the previously prepared delayed P0 value.
        ; This happens safely in horizontal blank, before visible pixels begin.
        sta GRP1
        lda (suitPtr),y
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
        bcs .ti_noTom
        lsr
        tax
        lda TitleTom,x
        sta GRP0
        jmp .ti_stageNext
.ti_noTom:
        lda #0
        sta GRP0
.ti_stageNext:
        iny
        cpy #160
        bne .ti_stageRow

        ; The footer returns to the title's proven asymmetric playfield text.
        ; Its 3x5 glyphs retain the same vertical proportions as the headline.
        lda #0
        sta GRP0
        sta GRP1
        sta VDELP0
        sta CTRLPF
.ti_creditRow:
        lda (suitPtr),y
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
        bne .ti_creditRow

        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #30
.ti_overscan:
        sta WSYNC
        dex
        bne .ti_overscan
        jmp TitleFrame

TitleReadControls:
        lda SWCHB
        lsr
        bcc .ti_consoleReset
        lda INPT4
        bmi .ti_released
        lda fireWasDown
        bne .ti_controlDone
        lda #1
        sta fireWasDown
        jmp $FFC0              ; Bank 1 switch stub enters terminal Bank 2
.ti_released:
        lda #0
        sta fireWasDown
.ti_controlDone:
        rts
.ti_consoleReset:
        jmp $FFE8              ; shared presentation reset stub

TitleSelectColorPhase:
        lda frameCounter
        lsr
        lsr
        lsr
        and #3
        tax
        lda ColorLow,x
        sta suitPtr
        lda ColorHigh,x
        sta suitPtr+1
        rts

TitleUpdateTom:
        ; Same signed 8.8 free-flight integration used by production stages.
        clc
        lda velYLo
        adc #TITLE_GRAVITY
        sta velYLo
        lda velYHi
        adc #0
        sta velYHi
        bmi .ti_fallReady
        bne .ti_capFall
        lda velYLo
        cmp #TITLE_MAX_FALL
        bcc .ti_fallReady
.ti_capFall:
        lda #0
        sta velYHi
        lda #TITLE_MAX_FALL
        sta velYLo
.ti_fallReady:
        clc
        lda tomXLo
        adc velXLo
        sta tomXLo
        lda tomXHi
        adc velXHi
        sta tomXHi
        clc
        lda tomYLo
        adc velYLo
        sta tomYLo
        lda tomYHi
        adc velYHi
        sta tomYHi

        lda velYHi
        bmi .ti_checkSides
        lda tomYHi
        cmp #TITLE_FLOOR_Y+1
        bcc .ti_checkSides
        lda #TITLE_FLOOR_Y
        sta tomYHi
        lda #0
        sta tomYLo
        lda #$FF
        sta velYHi
        lda #$40
        sta velYLo
.ti_checkSides:
        ; Match the complete 8x14 astronaut rectangle to the generated rock
        ; contour at his present height. Right limit = 160 - wall - 8.
        lda tomYHi
        sec
        sbc #96
        tax
        lda TitleWallLimit,x
        ; RESP0/HMOVE places the visible left edge one color clock inside the
        ; logical playfield coordinate. Compensate on this side only so Tom's
        ; suit reaches the rock with no apparent invisible one-pixel wall.
        sec
        sbc #1
        sta temp
        lda #152
        sec
        sbc temp
        sta temp2
        lda velXHi
        bmi .ti_movingLeft
        lda tomXHi
        cmp temp2
        bcc .ti_done
        beq .ti_done
        lda temp2
        sta tomXHi
        lda #0
        sta tomXLo
        lda #$FF
        sta velXHi
        lda #$80
        sta velXLo
        rts
.ti_movingLeft:
        lda tomXHi
        cmp #160
        bcs .ti_hitLeft
        cmp temp
        bcs .ti_done
.ti_hitLeft:
        lda temp
        sta tomXHi
        lda #0
        sta tomXLo
        sta velXHi
        lda #$80
        sta velXLo
.ti_done:
        rts

TitlePositionObject:
        clc
        adc #POSITION_BIAS
        sec
        sta WSYNC
.ti_divide15:
        sbc #15
        bcs .ti_divide15
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
        inc bestDistance
        lda bestDistance
        cmp #21
        bcc .ti_renderLead
        lda #0
        sta bestDistance
        inc bestBeacon
        lda bestBeacon
        and #$3F
        sta bestBeacon
.ti_renderLead:
        ldx bestBeacon
        lda TitleArpeggio,x
        sta AUDF0
        lda #12
        sta AUDC0
        lda bestDistance
        cmp #3
        bcc .ti_leadAttack
        cmp #12
        bcc .ti_leadBody
        cmp #16
        bcc .ti_leadRelease
        lda #0
        beq .ti_storeLead
.ti_leadAttack:
        lda #1
        bne .ti_storeLead
.ti_leadBody:
        lda #2
        bne .ti_storeLead
.ti_leadRelease:
        lda #1
.ti_storeLead:
        sta AUDV0

        ; A soft supporting tone sounds only on beats one and three. Its
        ; timbre is lower and quieter than the arpeggio, never a percussion
        ; substitute or a continuous drone.
        ldx bestBeacon
        txa
        and #3
        bne .ti_muteBass
        txa
        lsr
        lsr
        lsr
        tax
        lda TitleBassNotes,x
        sta AUDF1
        lda #6
        sta AUDC1
        lda bestDistance
        cmp #10
        bcs .ti_muteBass
        lda #1
        sta AUDV1
        rts
.ti_muteBass:
        lda #0
        sta AUDV1
        rts

ColorLow:
        byte <TitleColors0,<TitleColors1,<TitleColors2,<TitleColors3
ColorHigh:
        byte >TitleColors0,>TitleColors1,>TitleColors2,>TitleColors3
TitleTom:
        ; Exact approved production silhouette from thursdays-child.ti_asm.
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
