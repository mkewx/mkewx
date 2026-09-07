; Integrated compact rendering of the approved power-on credits screen.
CreditsInit:
        lda #1
        sta fireWasDown
        lda #0
        sta AUDV0
        sta AUDV1
        jmp CreditsFrame

CreditsFrame:
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
        jsr CreditsReadControls
.cr_waitVB:
        lda INTIM
        bne .cr_waitVB
        sta WSYNC
        lda #0
        sta VBLANK
        sta COLUBK
        sta CTRLPF
        sta PF0
        sta PF1
        sta PF2
        lda #$0E
        sta COLUPF

        ; Thirteen blank lines place the first approved line at Y=13.
        ldx #13
.cr_topBlank:
        sta WSYNC
        dex
        bne .cr_topBlank

        ldy #0                 ; thirty compact logical glyph rows
        lda #6
        sta orbitRadius        ; six credit lines
.cr_textLine:
        lda #5
        sta orbitStep          ; five logical rows per line
.cr_glyphRow:
        ldx #3                 ; exact approved 3x vertical scale
.cr_repeatRow:
        lda CreditsCompactPF0L,y
        sta WSYNC
        sta PF0
        lda CreditsCompactPF1L,y
        sta PF1
        lda CreditsCompactPF2L,y
        sta PF2
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda CreditsCompactPF0R,y
        sta PF0
        lda CreditsCompactPF1R,y
        sta PF1
        lda CreditsCompactPF2R,y
        sta PF2
        dex
        bne .cr_repeatRow
        iny
        dec orbitStep
        bne .cr_glyphRow

        lda #0
        sta PF0
        sta PF1
        sta PF2
        ldx #12                ; approved 27-line baseline spacing
.cr_lineGap:
        sta WSYNC
        dex
        bne .cr_lineGap
        dec orbitRadius
        bne .cr_textLine

        ; Twelve lines above are part of the 29-line final lower margin.
        ldx #17
.cr_bottomBlank:
        sta WSYNC
        dex
        bne .cr_bottomBlank

        lda #2
        sta VBLANK
        ldx #30
.cr_overscan:
        sta WSYNC
        dex
        bne .cr_overscan
        jmp CreditsFrame

CreditsReadControls:
        lda SWCHB
        lsr
        bcc .cr_consoleReset
        lda INPT4
        bmi .cr_released
        lda fireWasDown
        bne .cr_done
        lda #1
        sta fireWasDown
        jmp $FFB0              ; Bank 2 switch stub enters title Bank 1
.cr_released:
        lda #0
        sta fireWasDown
.cr_done:
        rts
.cr_consoleReset:
        jmp $FFE8
