        processor 6502
; THURSDAY'S CHILD -- POST-ZONE NASA MANIFEST LAB

VSYNC=$00
VBLANK=$01
WSYNC=$02
COLUPF=$08
COLUBK=$09
CTRLPF=$0A
PF0=$0D
PF1=$0E
PF2=$0F
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
frameCounter ds 1
flowPhase ds 1
rowEnd ds 1
headerColor ds 1
relicColor ds 1
flowBuffer ds 15
musicStep ds 1
musicFrame ds 1
kickEnvelope ds 1
snareEnvelope ds 1

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
        ; Step 31 lasts 18 frames. Beginning on its final frame makes the
        ; first visible manifest frame trigger step 0 and its opening kick.
        lda #31
        sta musicStep
        lda #17
        sta musicFrame

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

        inc frameCounter
        lda frameCounter
        lsr
        lsr
        lsr
        and #$03
        tax
        lda ManifestHeaderColors,x
        sta headerColor
        lda ManifestRelicColors,x
        sta relicColor

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
        lda ManifestFlow,x
        sta flowBuffer,y
        iny
        cpy #15
        bne .prepareFlow
        jsr UpdateManifestBeat

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
        lda ManifestBackground,x
        sta COLUBK
        inx
        cpx #16
        bne .top

        ; Keep the report body on one stable sheet color. Loading a new
        ; background shade inside the asymmetric text kernel delays PF0/PF1
        ; and visibly fragments the left-hand lettering.
        lda #$0C
        sta COLUBK
        ldy #0
        lda #$84
        sta COLUPF
        lda #7
        sta rowEnd
        jsr DrawRows
        lda headerColor
        sta COLUPF
        lda #23
        sta rowEnd
        jsr DrawRows
        lda #$84
        sta COLUPF
        lda #29
        sta rowEnd
        jsr DrawRows
        lda #$00
        sta COLUPF
        lda #45
        sta rowEnd
        jsr DrawRows
        lda #$84
        sta COLUPF
        lda #51
        sta rowEnd
        jsr DrawRows
        lda #$00
        sta COLUPF
        lda #67
        sta rowEnd
        jsr DrawRows
        lda #$84
        sta COLUPF
        lda #73
        sta rowEnd
        jsr DrawRows
        lda relicColor
        sta COLUPF
        lda #89
        sta rowEnd
        jsr DrawRows
        lda #$84
        sta COLUPF
        lda #95
        sta rowEnd
        jsr DrawRows
        lda #$00
        sta COLUPF
        lda #111
        sta rowEnd
        jsr DrawRows
        lda #$84
        sta COLUPF
        lda #126
        sta rowEnd
        jsr DrawRows

        jmp TextDone

; Exact timing inherited from the approved terminal kernel. Color changes occur
; only between row groups, so they cannot steal cycles from either PF half.
DrawRows:
.textRow:
        sta WSYNC
        lda ManifestPF0L,y
        sta PF0
        lda ManifestPF1L,y
        sta PF1
        lda ManifestPF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda ManifestPF0R,y
        sta PF0
        lda ManifestPF1R,y
        sta PF1
        lda ManifestPF2R,y
        sta PF2
        iny
        cpy rowEnd
        bne .textRow
        rts

TextDone:
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #142
.middle:
        sta WSYNC
        lda ManifestBackground,x
        sta COLUBK
        inx
        cpx #170
        bne .middle

        lda #$0E
        sta COLUPF
        ldy #0
.transitRow:
        lda flowBuffer,y
        sta WSYNC
        sta COLUBK
        lda ManifestTransitPF0L,y
        sta PF0
        lda ManifestTransitPF1L,y
        sta PF1
        lda ManifestTransitPF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        lda ManifestTransitPF0R,y
        sta PF0
        lda ManifestTransitPF1R,y
        sta PF1
        lda ManifestTransitPF2R,y
        sta PF2
        iny
        cpy #15
        bne .transitRow

        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #185
.bottom:
        sta WSYNC
        lda ManifestBackground,x
        sta COLUBK
        inx
        cpx #192
        bne .bottom

        lda #2
        sta VBLANK
        ; Ten between-group returns plus the final return consume one otherwise
        ; blank scanline apiece; reclaim all eleven so NTSC stays at 262 lines.
        ldx #19
.overscan:
        sta WSYNC
        dex
        bne .overscan
        jmp Frame

; Four bars at exactly 96 BPM on NTSC hardware. Thirty-two eighth-note steps
; follow a 19,19,19,18-frame rhythm: 75 frames per two beats and 600 frames per
; 16-beat loop. Channel 0 is the kick; channel 1 is the snare.
UpdateManifestBeat:
        inc musicFrame
        ldx musicStep
        lda musicFrame
        cmp ManifestStepDurations,x
        bcc .renderEnvelopes
        lda #0
        sta musicFrame
        inx
        txa
        and #31
        sta musicStep
        tax
        lda ManifestKickPattern,x
        beq .noKick
        lda #6
        sta kickEnvelope
.noKick:
        lda ManifestSnarePattern,x
        beq .renderEnvelopes
        lda #5
        sta snareEnvelope

.renderEnvelopes:
        lda #8
        sta AUDC0
        sta AUDC1
        lda #24
        sta AUDF0
        lda #5
        sta AUDF1

        ldx kickEnvelope
        beq .muteKick
        lda ManifestKickVolumes-1,x
        sta AUDV0
        dec kickEnvelope
        jmp .snare
.muteKick:
        lda #0
        sta AUDV0

.snare:
        ldx snareEnvelope
        beq .muteSnare
        lda ManifestSnareVolumes-1,x
        sta AUDV1
        dec snareEnvelope
        rts
.muteSnare:
        lda #0
        sta AUDV1
        rts

ManifestStepDurations:
        byte 19,19,19,18,19,19,19,18
        byte 19,19,19,18,19,19,19,18
        byte 19,19,19,18,19,19,19,18
        byte 19,19,19,18,19,19,19,18
ManifestKickPattern:
        byte 1,0,1,0,1,0,1,0
        byte 1,0,1,0,1,0,1,0
        byte 1,0,1,0,1,0,1,0
        byte 1,0,1,0,1,0,1,0
ManifestSnarePattern:
        ; Bars 1-3: backbeat on beats 2 and 4.
        byte 0,0,1,0,0,0,1,0
        byte 0,0,1,0,0,0,1,0
        byte 0,0,1,0,0,0,1,0
        ; Bar 4: beat 2, then an eighth-note fill across beats 3 and 4.
        byte 0,0,1,0,1,1,1,1
ManifestKickVolumes:
        byte 1,2,3,4,6,8
ManifestSnareVolumes:
        byte 1,2,3,5,7

        include "thursdays-child-zone-manifest-lab.inc"
        ORG $FFFA
        word Reset,Reset,Reset
