        processor 6502
; FLOATING IN A MOST PECULIAR WAY -- power-on credits laboratory

VSYNC=$00
VBLANK=$01
WSYNC=$02
COLUPF=$08
COLUBK=$09
CTRLPF=$0A
PF0=$0D
PF1=$0E
PF2=$0F
INTIM=$0284
TIM64T=$0296

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
.waitVB:
        lda INTIM
        bne .waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta COLUBK
        sta CTRLPF
        lda #$0E
        sta COLUPF
        ldy #0
.visible:
        sta WSYNC
        lda CreditsPF0L,y
        sta PF0
        lda CreditsPF1L,y
        sta PF1
        lda CreditsPF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda CreditsPF0R,y
        sta PF0
        lda CreditsPF1R,y
        sta PF1
        lda CreditsPF2R,y
        sta PF2
        iny
        cpy #192
        bne .visible
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

        include "thursdays-child-credits-lab.inc"
        ORG $FFFA
        word Reset,Reset,Reset
