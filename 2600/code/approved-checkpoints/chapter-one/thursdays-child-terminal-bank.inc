; Integrated Bank 2 form of the approved three-page NASA briefing.
TerminalInit:
        lda #0
        sta orbitRadius
        sta frameCounter
        sta orbitStep
        sta bestDistance
        sta bestBeacon
        lda #1
        sta fireWasDown
        jmp TerminalFrame

TerminalFrame:
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
        jsr TerminalReadFire
        inc frameCounter
        lda frameCounter
        lsr
        lsr
        lsr
        and #$0F
        sta orbitStep
        ldy #0
.te_prepareFlow:
        tya
        clc
        adc orbitStep
        and #$0F
        tax
        lda TerminalFlow,x
        sta hudIcon0,y
        iny
        cpy #15
        bne .te_prepareFlow
        jsr TerminalUpdateMusic
.te_waitVB:
        lda INTIM
        bne .te_waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta CTRLPF
        sta PF0
        sta PF1
        sta PF2
        ldx #0
.te_top:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #16
        bne .te_top
        lda #$2E
        sta COLUPF
        lda orbitRadius
        beq TerminalPage0
        cmp #1
        beq TerminalPage1
        jmp TerminalPage2

; Each fixed orbitRadius uses the same conservative asymmetric-playfield timing.
TerminalPage0:
        ldy #0
.te_page0Row:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        lda TerminalPage0PF0L,y
        sta PF0
        lda TerminalPage0PF1L,y
        sta PF1
        lda TerminalPage0PF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TerminalPage0PF0R,y
        sta PF0
        lda TerminalPage0PF1R,y
        sta PF1
        lda TerminalPage0PF2R,y
        sta PF2
        inx
        iny
        cpy #126
        bne .te_page0Row
        jmp TerminalTextDone

TerminalPage1:
        ldy #0
.te_page1Row:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        lda TerminalPage1PF0L,y
        sta PF0
        lda TerminalPage1PF1L,y
        sta PF1
        lda TerminalPage1PF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TerminalPage1PF0R,y
        sta PF0
        lda TerminalPage1PF1R,y
        sta PF1
        lda TerminalPage1PF2R,y
        sta PF2
        inx
        iny
        cpy #126
        bne .te_page1Row
        jmp TerminalTextDone

TerminalPage2:
        ldy #0
.te_page2Row:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        lda TerminalPage2PF0L,y
        sta PF0
        lda TerminalPage2PF1L,y
        sta PF1
        lda TerminalPage2PF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TerminalPage2PF0R,y
        sta PF0
        lda TerminalPage2PF1R,y
        sta PF1
        lda TerminalPage2PF2R,y
        sta PF2
        inx
        iny
        cpy #126
        bne .te_page2Row

TerminalTextDone:
        lda #0
        sta PF0
        sta PF1
        sta PF2
.te_middle:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #170
        bne .te_middle
        lda #$0E
        sta COLUPF
        lda orbitRadius
        cmp #2
        beq TerminalFirePrompt

TerminalMorePrompt:
        ldy #0
.te_moreRow:
        lda hudIcon0,y
        sta WSYNC
        sta COLUBK
        lda TerminalMorePF0L,y
        sta PF0
        lda TerminalMorePF1L,y
        sta PF1
        lda TerminalMorePF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TerminalMorePF0R,y
        sta PF0
        lda TerminalMorePF1R,y
        sta PF1
        lda TerminalMorePF2R,y
        sta PF2
        iny
        cpy #15
        bne .te_moreRow
        jmp TerminalPromptDone

TerminalFirePrompt:
        ldy #0
.te_fireRow:
        lda hudIcon0,y
        sta WSYNC
        sta COLUBK
        lda TerminalFirePF0L,y
        sta PF0
        lda TerminalFirePF1L,y
        sta PF1
        lda TerminalFirePF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda TerminalFirePF0R,y
        sta PF0
        lda TerminalFirePF1R,y
        sta PF1
        lda TerminalFirePF2R,y
        sta PF2
        iny
        cpy #15
        bne .te_fireRow

TerminalPromptDone:
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #185
.te_bottom:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #192
        bne .te_bottom
        lda #2
        sta VBLANK
        ldx #30
.te_overscan:
        sta WSYNC
        dex
        bne .te_overscan
        jmp TerminalFrame

TerminalReadFire:
        lda SWCHB
        lsr
        bcc .te_consoleReset
        lda INPT4
        bmi .te_released
        lda fireWasDown
        bne .te_done
        lda #1
        sta fireWasDown
        inc orbitRadius
        lda orbitRadius
        cmp #3
        bcc .te_done
        jmp $FFE0              ; Bank 2 switch stub enters gameplay Bank 7
.te_released:
        lda #0
        sta fireWasDown
.te_done:
        rts
.te_consoleReset:
        jmp $FFE8              ; shared presentation reset stub

; Original two-voice terminal cue. Fifteen NTSC frames per eighth note gives
; 120 BPM. Both voices breathe for three frames between notes, avoiding the
; harsh continuous buzz that plagued the earliest gameplay-audio experiment.
TerminalUpdateMusic:
        inc bestDistance
        lda bestDistance
        cmp #15
        bcc .te_stepReady
        lda #0
        sta bestDistance
        inc bestBeacon
        lda bestBeacon
        and #$0F
        sta bestBeacon
.te_stepReady:
        ldx bestBeacon
        lda TerminalLeadNotes,x
        sta AUDF0
        lda TerminalBassNotes,x
        sta AUDF1
        lda #12
        sta AUDC0
        lda #6
        sta AUDC1
        lda bestDistance
        cmp #12
        bcs .te_rest
        cmp #3
        bcs .te_sustain
        lda #3
        sta AUDV0
        lda #2
        sta AUDV1
        rts
.te_sustain:
        lda #2
        sta AUDV0
        lda #1
        sta AUDV1
        rts
.te_rest:
        lda #0
        sta AUDV0
        sta AUDV1
        rts

; A-minor-flavored arpeggio with a four-bar descending answer. Frequencies
; stay in the TIA's cleaner middle register; the bass changes once per beat.
TerminalLeadNotes:
        byte 11,9,7,9,14,11,9,11,9,7,8,7,12,10,8,10
TerminalBassNotes:
        byte 23,23,23,23,29,29,29,29,19,19,19,19,25,25,25,25

        include "thursdays-child-terminal-lab.inc"
