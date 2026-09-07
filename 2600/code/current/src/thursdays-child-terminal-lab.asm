        processor 6502
; THURSDAY'S CHILD -- NASA TERMINAL BRIEFING LAB

VSYNC=$00
VBLANK=$01
WSYNC=$02
COLUPF=$08
COLUBK=$09
CTRLPF=$0A
PF0=$0D
PF1=$0E
PF2=$0F
INPT4=$0C
AUDC0=$15
AUDC1=$16
AUDF0=$17
AUDF1=$18
AUDV0=$19
AUDV1=$1A
INTIM=$0284
TIM64T=$0296

        SEG.U RAM
        ORG $80
page ds 1
fireLatch ds 1
frameCounter ds 1
flowPhase ds 1
flowBuffer ds 15
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

Frame:
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
        jsr ReadFire
        inc frameCounter
        lda frameCounter
        lsr
        lsr
        lsr
        and #$0F
        sta flowPhase
        ldy #0
.prepareFlow:
        tya
        clc
        adc flowPhase
        and #$0F
        tax
        lda TerminalFlow,x
        sta flowBuffer,y
        iny
        cpy #15
        bne .prepareFlow
        jsr UpdateMusic
.waitVB:
        lda INTIM
        bne .waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta CTRLPF
        sta PF0
        sta PF1
        sta PF2
        ldx #0
.top:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #16
        bne .top
        lda #$2E
        sta COLUPF
        lda page
        beq Page0
        cmp #1
        beq Page1
        jmp Page2

; Each fixed page uses the same conservative asymmetric-playfield timing.
Page0:
        ldy #0
.page0Row:
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
        bne .page0Row
        jmp TextDone

Page1:
        ldy #0
.page1Row:
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
        bne .page1Row
        jmp TextDone

Page2:
        ldy #0
.page2Row:
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
        bne .page2Row

TextDone:
        lda #0
        sta PF0
        sta PF1
        sta PF2
.middle:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #170
        bne .middle
        lda #$0E
        sta COLUPF
        lda page
        cmp #2
        beq FirePrompt

MorePrompt:
        ldy #0
.moreRow:
        lda flowBuffer,y
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
        bne .moreRow
        jmp PromptDone

FirePrompt:
        ldy #0
.fireRow:
        lda flowBuffer,y
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
        bne .fireRow

PromptDone:
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #185
.bottom:
        sta WSYNC
        lda TerminalBackground,x
        sta COLUBK
        inx
        cpx #192
        bne .bottom
        lda #2
        sta VBLANK
        ldx #30
.overscan:
        sta WSYNC
        dex
        bne .overscan
        jmp Frame

ReadFire:
        lda INPT4
        bmi .released
        lda fireLatch
        bne .done
        lda #1
        sta fireLatch
        inc page
        lda page
        cmp #3
        bcc .done
        lda #0
        sta page
        rts
.released:
        lda #0
        sta fireLatch
.done:
        rts

; Original two-voice terminal cue. Fifteen NTSC frames per eighth note gives
; 120 BPM. Both voices breathe for three frames between notes, avoiding the
; harsh continuous buzz that plagued the earliest gameplay-audio experiment.
UpdateMusic:
        inc musicFrame
        lda musicFrame
        cmp #15
        bcc .stepReady
        lda #0
        sta musicFrame
        inc musicStep
        lda musicStep
        and #$0F
        sta musicStep
.stepReady:
        ldx musicStep
        lda TerminalLeadNotes,x
        sta AUDF0
        lda TerminalBassNotes,x
        sta AUDF1
        lda #12
        sta AUDC0
        lda #6
        sta AUDC1
        lda musicFrame
        cmp #12
        bcs .rest
        cmp #3
        bcs .sustain
        lda #3
        sta AUDV0
        lda #2
        sta AUDV1
        rts
.sustain:
        lda #2
        sta AUDV0
        lda #1
        sta AUDV1
        rts
.rest:
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

        IFCONST CHAPTER_TWO_TERMINAL
        include "thursdays-child-chapter-two-terminal.inc"
        ELSE
        include "thursdays-child-terminal-lab.inc"
        ENDIF
        ORG $FFFA
        word Reset,Reset,Reset
