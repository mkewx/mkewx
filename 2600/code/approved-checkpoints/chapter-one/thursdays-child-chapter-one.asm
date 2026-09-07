        processor 6502

; ---------------------------------------------------------------------------
; FLOATING IN A MOST PECULIAR WAY
; THURSDAY'S CHILD — CHAPTER ONE INTEGRATED VERTICAL SLICE
;
; This is not a revision of the legacy gradient project.  It is an independent
; 32K F4 production branch with the approved gravity engine in Bank 0, the
; approved black-space renderer in fixed Bank 7, four additional independent
; room banks in Banks 6-3, and Banks 1-2 reserved for later chapter systems.
;
; Proof commitments:
;   * black background and stationary amethyst-gradient terrain
;   * a compact one-player Major Tom with an enclosed black visor opening
;   * one locked neutral astronaut pose; animation budget belongs to objects
;   * terrain collision, side reflection, ceiling reflection and moon bounce
;   * independently authored left/right terrain, with no mirrored-stage rule
;   * three real P1 satellite-dish sprites at unrelated X/Y coordinates
;   * seven carefully authored logical rows doubled into a stable 8x14 suit
;   * only the ready dish emits a slow blue pulse; collectibles shimmer faster
;   * three circular capture tiers and tangent release
;   * a full-height extraction gate revealed by the three required objects
;   * five ordered Chapter One stages, each with independent terrain/palette
;   * score and HUD state persist while every new room resets objectives
;
; Exact NTSC frame:
;   3 VSYNC + 37 VBLANK + 192 visible + 30 overscan = 262 scanlines
; Visible picture:
;   16 HUD / status lines + 176 room lines
; ---------------------------------------------------------------------------

; TIA write registers
VSYNC   = $00
VBLANK  = $01
WSYNC   = $02
NUSIZ0  = $04
NUSIZ1  = $05
COLUP0  = $06
COLUP1  = $07
COLUPF  = $08
COLUBK  = $09
CTRLPF  = $0A
REFP0   = $0B
REFP1   = $0C
PF0     = $0D
PF1     = $0E
PF2     = $0F
RESP0   = $10
RESP1   = $11
RESM0   = $12
RESM1   = $13
RESBL   = $14
GRP0    = $1B
GRP1    = $1C
ENAM0   = $1D
ENAM1   = $1E
ENABL   = $1F
HMP0    = $20
HMP1    = $21
HMM0    = $22
HMM1    = $23
HMBL    = $24
VDELP0  = $25
VDELP1  = $26
HMOVE   = $2A
HMCLR   = $2B
CXCLR   = $2C
AUDC0   = $15
AUDC1   = $16
AUDF0   = $17
AUDF1   = $18
AUDV0   = $19
AUDV1   = $1A

; TIA read registers
CXP0FB  = $02
CXP1FB  = $03
INPT4   = $0C

; RIOT
SWCHB   = $0282
INTIM   = $0284
TIM64T  = $0296

; Display
HUD_LINES       = 16
ROOM_LINES      = 176
ASTRONAUT_H     = 14
ASTRONAUT_LAST  = 13
ASTRONAUT_HALF_W = 4
ASTRONAUT_HALF_H = 7
SUIT_COLOR      = $0E
SIGNAL_COLOR        = $8C
DISH_DIM_COLOR      = $86
REQUIRED_COLOR      = $2E
REQUIRED_DIM_COLOR  = $28
OPTIONAL_COLOR      = $CE
OPTIONAL_DIM_COLOR  = $C8
EXIT_GLOW_DIM       = $12
EXIT_GLOW_LOW       = $16
EXIT_GLOW_HIGH      = $1C
EXIT_DONE_COLOR     = $0E
HUD_DIM_COLOR   = $16
HUD_LIVE_COLOR  = $2E
HUD_DONE_COLOR  = $C8
HUD_TEXT_COLOR  = $0E
HUD_ICON_COLOR  = $2C

; One-channel production sound vocabulary. Music remains deliberately absent
; in 0.8A so each gameplay event can be judged without masking or contention.
SFX_NONE          = 0
SFX_CAPTURE       = 1
SFX_RELEASE       = 2
SFX_REQUIRED      = 3
SFX_OPTIONAL      = 4
SFX_EXIT_READY    = 5
SFX_STAGE_COMPLETE = 6
MUSIC_REST         = $FF

; Production stage vocabulary. The engine uses structure-of-arrays descriptors
; because indexed byte loads are cheaper than multiplying a stage record size.
STAGE_COUNT          = 5
NO_NEXT_STAGE        = $FF
TERRAIN_AMETHYST     = 0
TERRAIN_COBALT       = 1
TERRAIN_EMERALD      = 2
TERRAIN_CRIMSON      = 3
TERRAIN_VOID_VIOLET  = 4
PALETTE_AMETHYST     = 0
PALETTE_COBALT       = 1
PALETTE_EMERALD      = 2
PALETTE_CRIMSON      = 3
PALETTE_VOID_VIOLET  = 4
BEHAVIOR_NORMAL_ROCK = 0
MUSIC_CHAPTER_ONE    = 0
ROOM_BANK_STAGE1     = 7
ROOM_BANK_STAGE2     = 6
ROOM_BANK_STAGE3     = 5
ROOM_BANK_STAGE4     = 4
ROOM_BANK_STAGE5     = 3

; Motion: signed 8.8
GRAVITY          = 4
MAX_FALL_LO      = $E0
MOON_RETURN      = $FF40
ROCK_REBOUND_UP  = $FEC0
ROCK_REBOUND_DN  = $00C0
SIDE_RETURN      = $0080
LEFT_LIMIT       = 16        ; PF0's four bits occupy sixteen color clocks
RIGHT_LIMIT      = 136       ; eight clocks wide; right edge ends at 143
POSITION_BIAS    = 49        ; exact RESP/HMOVE origin for this instruction path
TOP_LIMIT        = 8         ; immediately below the eight-line ceiling
BOTTOM_LIMIT     = 154       ; fourteen lines tall; bottom edge ends at 167
SPAWN_X          = 50        ; revised launch lane clears automatic pickups
SPAWN_Y          = 16

; Gravity installations. Their coordinates are independent stage data. The
; renderer multiplexes one satellite sprite through three vertical zones, so
; none of these positions is inferred or mirrored from another.
STATE_FREE       = 0
STATE_ORBIT      = 1
BEACON_AX        = 100
BEACON_AY        = 36
BEACON_BX        = 106
BEACON_BY        = 84
BEACON_CX        = 100
BEACON_CY        = 130       ; ordinary floor bounce intersects this field
OPTIONAL_LEFT    = 130       ; positioned normally during VBLANK
DISH_A_LEFT      = 96        ; visible service strobes are cycle calibrated
COLLECT_0_LEFT   = 102
DISH_B_LEFT      = 102
COLLECT_1_LEFT   = 75
DISH_C_LEFT      = 96
COLLECT_2_LEFT   = 81        ; assembled RESP1 service position
OPTIONAL_TOP     = 9
COLLECT_0_TOP    = 49
COLLECT_1_TOP    = 97
COLLECT_2_TOP    = 145
COLLECT_W        = 8
COLLECT_H        = 14
EXIT_LEFT        = 78        ; calibrated by the seventh P1 service strobe
EXIT_TOP         = 161
EXIT_W           = 8
EXIT_H           = 14

; Stage 2 — an independently authored cobalt/teal chamber in Bank 6.
STAGE2_SPAWN_X    = 40
STAGE2_SPAWN_Y    = 16
STAGE2_BEACON_AX  = 79
STAGE2_BEACON_AY  = 36
STAGE2_BEACON_BX  = 109
STAGE2_BEACON_BY  = 84
STAGE2_BEACON_CX  = 79
STAGE2_BEACON_CY  = 130
STAGE2_DISH_A_LEFT = 75
STAGE2_DISH_B_LEFT = 105
STAGE2_DISH_C_LEFT = 75
STAGE2_OPTIONAL_LEFT  = 30
STAGE2_COLLECT_0_LEFT = 114
STAGE2_COLLECT_1_LEFT = 78
STAGE2_COLLECT_2_LEFT = 102
STAGE2_EXIT_LEFT      = 90

; Stages 3 and 4 retain the proven seven-object vertical service schedule,
; but use independently timed X strobes, terrain, launches and routes.
STAGE3_SPAWN_X         = 114
STAGE3_SPAWN_Y         = 18
STAGE3_DISH_A_LEFT     = 81
STAGE3_DISH_B_LEFT     = 111
STAGE3_DISH_C_LEFT     = 81
STAGE3_BEACON_AX       = 85
STAGE3_BEACON_AY       = 36
STAGE3_BEACON_BX       = 115
STAGE3_BEACON_BY       = 84
STAGE3_BEACON_CX       = 85
STAGE3_BEACON_CY       = 130
STAGE3_OPTIONAL_LEFT   = 30
STAGE3_COLLECT_0_LEFT  = 108
STAGE3_COLLECT_1_LEFT  = 84
STAGE3_COLLECT_2_LEFT  = 96
STAGE3_EXIT_LEFT       = 96

STAGE4_SPAWN_X         = 50
STAGE4_SPAWN_Y         = 18
STAGE4_DISH_A_LEFT     = 87
STAGE4_DISH_B_LEFT     = 99
STAGE4_DISH_C_LEFT     = 87
STAGE4_BEACON_AX       = 91
STAGE4_BEACON_AY       = 36
STAGE4_BEACON_BX       = 103
STAGE4_BEACON_BY       = 84
STAGE4_BEACON_CX       = 91
STAGE4_BEACON_CY       = 130
STAGE4_OPTIONAL_LEFT   = 30
STAGE4_COLLECT_0_LEFT  = 114
STAGE4_COLLECT_1_LEFT  = 72
STAGE4_COLLECT_2_LEFT  = 108
STAGE4_EXIT_LEFT       = 84

STAGE5_SPAWN_X         = 120
STAGE5_SPAWN_Y         = 18
STAGE5_DISH_A_LEFT     = 75
STAGE5_DISH_B_LEFT     = 105
STAGE5_DISH_C_LEFT     = 75
STAGE5_BEACON_AX       = 79
STAGE5_BEACON_AY       = 36
STAGE5_BEACON_BX       = 109
STAGE5_BEACON_BY       = 84
STAGE5_BEACON_CX       = 79
STAGE5_BEACON_CY       = 130
STAGE5_OPTIONAL_LEFT   = 30
STAGE5_COLLECT_0_LEFT  = 114
STAGE5_COLLECT_1_LEFT  = 78
STAGE5_COLLECT_2_LEFT  = 102
STAGE5_EXIT_LEFT       = 90

CAPTURE_RANGE    = 20        ; outer field hugs the radius-19 wide orbit
TIER_NEAR_MAX    = 15
TIER_MID_MAX     = 22        ; preserves useful medium and wide entry bands
ORBIT_STEP_NEAR  = 2         ; 32 distinct positions per revolution
ORBIT_STEP_MID   = 1         ; 64 positions
ORBIT_STEP_FAR   = 1         ; 64 positions, each held for two frames
NO_BEACON        = $FF

; ---------------------------------------------------------------------------
; Shared 128-byte RAM. Both banks use these exact symbols.
; ---------------------------------------------------------------------------
        SEG.U RAM
        ORG $80
tomXHi          ds 1
tomXLo          ds 1
tomYHi          ds 1
tomYLo          ds 1
velXHi          ds 1
velXLo          ds 1
velYHi          ds 1
velYLo          ds 1
safeXHi         ds 1
safeXLo         ds 1
safeYHi         ds 1
safeYLo         ds 1
frameCounter    ds 1
gameState       ds 1
fireWasDown     ds 1
readyBeacon     ds 1         ; $FF none; otherwise 0=A, 1=B, 2=C
activeBeacon    ds 1
beaconX         ds 1
beaconY         ds 1
captureDistance ds 1
orbitAngle      ds 1         ; 0..63
orbitRadius     ds 1         ; 0=tight, 1=medium, 2=wide
orbitStep       ds 1
orbitDirection  ds 1         ; 0=clockwise, $FF=counterclockwise
orbitHalfStep   ds 1         ; wide tier midpoint: 0=ring point, 1=halfway
terrainHit      ds 1
collectMask     ds 1         ; bits 0..2 required, bit 3 optional
requiredCount   ds 1         ; low 2=count 0..3; bits 7..5=music phrase 0..7
collectDraw0    ds 1         ; $FF visible, $00 collected
collectDraw1    ds 1
collectDraw2    ds 1
collectDraw3    ds 1
currentP1Mask  ds 1
currentP1Color ds 1
dishColorA     ds 1
dishColorB     ds 1
dishColorC     ds 1
requiredP1Color ds 1
optionalP1Color ds 1
exitDraw        ds 1
exitP1Color     ds 1
objectiveDone   ds 1
stageComplete   ds 1
suitPtr         ds 2
renderTomY      ds 1         ; one line early for VDEL player graphics
visorEnable     ds 1         ; delayed Missile-1 state for the next scanline
temp            ds 1
temp2           ds 1
delta           ds 1
bestDistance    ds 1
bestBeacon      ds 1
hudIcon0        ds 6         ; only displayed rows 1..5 are buffered
hudIcon1        ds 6
hudIcon2        ds 6
hudIcon3        ds 6
hudIcon4        ds 6
hudIcon5        ds 6
hudStageGlyph   ds 8         ; VBLANK copies preserve approved visible timing
hudHundredsGlyph ds 8
soundState      ds 1         ; effect in bits 7..5, remaining frames in 4..0
hudScorePtr     ds 2         ; changing tens digit: 0,1,2,3 or 5
tomFineMotion   ds 1         ; precomputed HMP0 value for visible restoration
currentStage    ds 1         ; zero-based production stage index
stageOffset     ds 1         ; 0 or 3, selecting one of two beacon triplets
transitionTimer ds 1         ; frozen extraction hold before the next stage
stageSetupPending ds 1       ; bit 7 setup request; low nibble last HUD mask
scoreTens      ds 1         ; persistent score in units of ten points
hudStagePtr    ds 2         ; Stage 1 or Stage 2 numeral
hudHundredsPtr ds 2         ; 0 until scoreTens reaches ten
dirAccumHi      ds 1         ; BeginCapture gravity-spin cross-product, high byte

; ---------------------------------------------------------------------------
; BANK 0 — gravity, collision and mission state.
; Thursday's Child 0.7B uses the commercial 32K F4 map. Every reset entry
; selects fixed engine Bank 7; Bank 7 calls this physics bank through $FFF4.
; ---------------------------------------------------------------------------
        SEG BANK0
        ORG $0000
        RORG $F000
Bank0Boot:
        lda $FFFB
        jmp $F006

        ORG $0006
        RORG $F006
UpdatePhysics:
        ; Presentation Bank 2 marks the first gameplay frame with $40. Build
        ; Stage 1 from its descriptors before any motion or collision occurs.
        lda stageSetupPending
        cmp #$40
        bne .ordinaryPhysics
        lda #0
        sta currentStage
        sta scoreTens
        jsr LoadCurrentStage
        rts
.ordinaryPhysics:
        ; Hardware collision latches are cleared but never used for movement.
        ; Both free flight and orbit now test the authored terrain geometry,
        ; so JavaTari, Stellerator and hardware receive identical answers.
        lda #0
        sta CXCLR

        ; The current legal position becomes the rollback point for the frame
        ; that is about to be rendered.
        lda tomXHi
        sta safeXHi
        lda tomXLo
        sta safeXLo
        lda tomYHi
        sta safeYHi
        lda tomYLo
        sta safeYLo

        jsr UpdateGame
        lda gameState
        bne .collisionReady      ; orbit already checked its candidate point
        jsr CheckTerrainSoftware
        bcc .collisionReady
        jsr ResolveFreeTerrainCollision
.collisionReady:
        jsr CheckCollectibles
        ; The renderer consumes this scratch byte only after all physics and
        ; collision work is complete. One step lasts four NTSC frames.
        lda frameCounter
        lsr
        lsr
        and #3
        sta bestBeacon
        nop                     ; preserve the approved Bank 0 audio layout
        jsr CheckMissionContact
        jsr UpdateSound
        rts

ResolveFreeTerrainCollision:
        ; Preserve the rejected candidate coordinates while testing each axis
        ; independently against the preceding legal position.
        lda tomXHi
        sta captureDistance
        lda tomYHi
        sta bestDistance
        lda #0
        sta terrainHit          ; bit 0=X contact, bit 1=Y contact

        ; Candidate X with the old Y: a hit is a genuine side impact.
        lda safeYHi
        sta tomYHi
        jsr CheckTerrainSoftware
        bcc .freeXClear
        lda #1
        sta terrainHit
.freeXClear:
        ; Candidate Y with the old X: a hit is floor/ceiling contact.
        lda safeXHi
        sta tomXHi
        lda bestDistance
        sta tomYHi
        jsr CheckTerrainSoftware
        bcc .freeYClear
        lda terrainHit
        ora #2
        sta terrainHit
.freeYClear:
        jsr RestoreSafePosition

        lda terrainHit
        bne .resolvedAxes
        ; A diagonal corner can require both components before intersecting.
        ; Reflect both axes rather than leaving Major Tom embedded or stopped.
        lda #3
        sta terrainHit
.resolvedAxes:
        lda terrainHit
        and #1
        beq .freeVertical
        jsr NegateHorizontalVelocity

.freeVertical:
        lda terrainHit
        and #2
        beq .freeCollisionReady
        lda velYHi
        bmi .bounceDownFromCeiling
        lda #>MOON_RETURN
        sta velYHi
        lda #<MOON_RETURN
        sta velYLo
        bne .freeCollisionReady
.bounceDownFromCeiling:
        lda #0
        sta velYHi
        lda #$80                ; +0.50 pixel/frame
        sta velYLo
.freeCollisionReady:
        jsr EnsureHorizontalMotion
        rts

NegateHorizontalVelocity:
        sec
        lda #0
        sbc velXLo
        sta velXLo
        lda #0
        sbc velXHi
        sta velXHi
        rts

RestoreSafePosition:
        lda safeXHi
        sta tomXHi
        lda safeXLo
        sta tomXLo
        lda safeYHi
        sta tomYHi
        lda safeYLo
        sta tomYLo
        rts

UpdateGame:
        inc frameCounter
        lda stageComplete
        beq .stageRunning

        ; Extraction is a quiet, deterministic pause. StageNextByStage owns
        ; progression; the engine no longer contains a Stage-2-specific test.
        ldx currentStage
        lda StageNextByStage,x
        cmp #NO_NEXT_STAGE
        beq .completedBuild
        inc transitionTimer
        lda transitionTimer
        cmp #48
        bcc .completedBuild
        jsr AdvanceStage
.completedBuild:
        rts

.stageRunning:
        jsr CheckBeaconRange
        ; Mission contact remains visible in the proof HUD, but it never
        ; freezes motion. A production room will transition only after its
        ; extraction animation has completed.
        lda INPT4
        bmi .fireReleased
        lda #1
        sta fireWasDown
        lda gameState
        bne .continueOrbit
        lda readyBeacon
        cmp #NO_BEACON
        beq .freeWhileHeld
        jsr BeginCapture
        rts                     ; render the nearest entry point before moving
.continueOrbit:
        jsr UpdateOrbit
        rts
.freeWhileHeld:
        jsr UpdateFreeFlight
        rts

.fireReleased:
        lda fireWasDown
        beq .freeWithFireUp
        lda #0
        sta fireWasDown
        lda gameState
        beq .freeWithFireUp
        jsr ReleaseOrbit
        rts
.freeWithFireUp:
        lda gameState
        beq .ordinaryFree
        jsr UpdateOrbit
        rts
.ordinaryFree:
        jsr UpdateFreeFlight
        rts

AdvanceStage:
        ldx currentStage
        lda StageNextByStage,x
        sta currentStage
        jmp LoadCurrentStage

; Load every mutable field required to begin the selected stage. Score is
; deliberately absent and therefore persists. Stage 1's reset seed is checked
; against descriptor row zero; all later entries use this routine directly.
LoadCurrentStage:
        lda #$80
        sta stageSetupPending
        ldx currentStage
        lda StageBeaconOffset,x
        sta stageOffset
        lda #0
        sta transitionTimer
        sta stageComplete
        sta objectiveDone
        sta requiredCount
        sta frameCounter
        sta collectMask
        sta gameState
        sta fireWasDown
        sta tomXLo
        sta tomYLo
        lda #NO_BEACON
        sta readyBeacon
        sta activeBeacon
        lda #$FF
        sta collectDraw0
        sta collectDraw1
        sta collectDraw2
        sta collectDraw3
        ldx currentStage
        lda StageSpawnX,x
        sta tomXHi
        sta safeXHi
        lda StageSpawnY,x
        sta tomYHi
        sta safeYHi
        lda StageVelocityXHi,x
        sta velXHi
        lda StageVelocityXLo,x
        sta velXLo
        lda StageVelocityYHi,x
        sta velYHi
        lda StageVelocityYLo,x
        sta velYLo
        rts

; Select the closest of three installations inside the compact Manhattan
; capture field. Its axis and combined-distance limits closely surround the
; widest visible orbit instead of activating across a large part of the room.
CheckBeaconRange:
        lda gameState
        beq .measureInstallations
        lda activeBeacon
        sta readyBeacon
        tax
        txa
        clc
        adc stageOffset
        tay
        lda BeaconXTable,y
        sta beaconX
        lda BeaconYTable,y
        sta beaconY
        rts

.measureInstallations:
        lda #NO_BEACON
        sta bestBeacon
        sta bestDistance
        ldx #2
.measureLoop:
        stx temp2
        txa
        clc
        adc stageOffset
        tay
        lda BeaconXTable,y
        sta temp
        lda BeaconYTable,y
        sta delta
        jsr MeasureBeaconDistance
        bcs .nextInstallation
        cmp bestDistance
        bcs .nextInstallation
        sta bestDistance
        ldx temp2
        stx bestBeacon
.nextInstallation:
        ldx temp2
        dex
        bpl .measureLoop

        lda bestBeacon
        sta readyBeacon
        cmp #NO_BEACON
        beq .noInstallation
        tax
        txa
        clc
        adc stageOffset
        tay
        lda BeaconXTable,y
        sta beaconX
        lda BeaconYTable,y
        sta beaconY
        lda bestDistance
        sta captureDistance
        rts
.noInstallation:
        lda #$FE
        sta beaconY
        rts

; A=Manhattan distance, carry clear when inside the capture field.
MeasureBeaconDistance:
        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W   ; center of the astronaut
        sec
        sbc temp
        bcs .absXReady
        eor #$FF
        adc #1
.absXReady:
        cmp #CAPTURE_RANGE
        bcs .outsideRange
        sta captureDistance     ; scratch until the closest installation wins

        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        sec
        sbc delta
        bcs .absYReady
        eor #$FF
        adc #1
.absYReady:
        cmp #CAPTURE_RANGE
        bcs .outsideRange
        clc
        adc captureDistance
        cmp #CAPTURE_RANGE+10
        bcs .outsideRange
        clc
        rts
.outsideRange:
        sec
        rts

; Signed 8x8->16 multiply used only by BeginCapture's gravity-spin direction
; math. In: A=multiplicand, Y=multiplier (both signed, -128..127). Out:
; delta:temp = signed 16-bit product (delta=low byte, temp=high byte).
; Reuses the shared bestDistance/bestBeacon/temp/delta scratch, which
; CheckBeaconRange already resets every frame before BeginCapture can run,
; instead of adding new persistent RAM. Clobbers A, X, Y, bestDistance,
; bestBeacon, temp, delta.
Multiply8x8Signed:
        sta bestDistance        ; abs(multiplicand)
        sty bestBeacon          ; abs(multiplier)
        ldy #0                   ; Y = sign flag (0=positive, 1=negate result)
        lda bestDistance
        bpl .aNonNeg
        eor #$FF
        clc
        adc #1
        sta bestDistance
        iny
.aNonNeg:
        lda bestBeacon
        bpl .bNonNeg
        eor #$FF
        clc
        adc #1
        sta bestBeacon
        tya
        eor #1
        tay
.bNonNeg:
        lda #0
        sta delta                ; product low byte
        sta temp                 ; product high byte
        ldx #8
.mulLoop:
        lsr bestBeacon
        bcc .noAdd
        lda temp
        clc
        adc bestDistance
        sta temp
.noAdd:
        ror temp
        ror delta
        dex
        bne .mulLoop

        cpy #0
        beq .signDone
        sec
        lda #0
        sbc delta
        sta delta
        lda #0
        sbc temp
        sta temp
.signDone:
        rts

BeginCapture:
        lda #STATE_ORBIT
        sta gameState
        lda readyBeacon
        sta activeBeacon

        lda captureDistance
        cmp #TIER_NEAR_MAX
        bcc .nearTier
        cmp #TIER_MID_MAX
        bcc .midTier
        lda #2
        sta orbitRadius
        lda #ORBIT_STEP_FAR
        sta orbitStep
        bne .chooseEntry
.midTier:
        lda #1
        sta orbitRadius
        lda #ORBIT_STEP_MID
        sta orbitStep
        bne .chooseEntry
.nearTier:
        lda #0
        sta orbitRadius
        lda #ORBIT_STEP_NEAR
        sta orbitStep

.chooseEntry:
        lda #0
        sta orbitDirection
        sta orbitHalfStep

        ; Gravity spin direction now follows Major Tom's actual approach
        ; velocity, not just his static side of the beacon. Sign of the
        ; angular-momentum cross product L = relX*velY - relY*velX gives the
        ; physically-continuous spin direction (screen Y increases downward,
        ; so positive L is clockwise here rather than the usual math
        ; convention). relX/relY are Tom's center relative to the beacon
        ; center, both always inside CAPTURE_RANGE, so they fit signed bytes.
        ; L accumulates in temp2 (low) / dirAccumHi (high) across both terms;
        ; Multiply8x8Signed itself returns each term in delta (low) / temp
        ; (high), reusing scratch rather than adding new persistent RAM.
        lda #0
        sta temp2
        sta dirAccumHi

        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W
        sec
        sbc beaconX
        ldy velYHi
        jsr Multiply8x8Signed
        lda temp2
        clc
        adc delta
        sta temp2
        lda dirAccumHi
        adc temp
        sta dirAccumHi

        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        sec
        sbc beaconY
        ldy velXHi
        jsr Multiply8x8Signed
        lda temp2
        sec
        sbc delta
        sta temp2               ; L low byte
        lda dirAccumHi
        sbc temp                ; A = L high byte
        bmi .setCounterclockwise
        bne .directionChosen
        lda temp2
        bne .directionChosen

        ; L == 0: Tom's velocity points directly at (or away from) the
        ; beacon, so angular momentum can't pick a side. Fall back to the
        ; original static approach-side rule for this degenerate case only.
        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W
        cmp beaconX
        bcc .directionChosen
        beq .directionChosen
.setCounterclockwise:
        lda #$FF
        sta orbitDirection
.directionChosen:
        ; Compare sixteen points around the chosen ring. This preserves the
        ; approach angle much more closely than snapping to eight sectors.
        jsr SelectClosestOrbitAngle
        jsr PlaceOrbitAtCurrentAngle
        jsr CheckTerrainSoftware
        bcc .captureReady
        jsr RestoreSafePosition
.captureReady:
        lda #SFX_CAPTURE
        jsr StartSound
        rts

SelectClosestOrbitAngle:
        ; First select the nearest 45-degree sector using the approach vector.
        ; Only that sector and its two 22.5-degree neighbors can possibly be
        ; the closest of the sixteen entry positions.
        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W
        sec
        sbc beaconX
        bcs .coarseAbsX
        eor #$FF
        adc #1
.coarseAbsX:
        sta temp
        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        sec
        sbc beaconY
        bcs .coarseAbsY
        eor #$FF
        adc #1
.coarseAbsY:
        sta temp2

        lda temp
        lsr
        cmp temp2
        bcs .coarseHorizontal
        lda temp2
        lsr
        cmp temp
        bcs .coarseVertical

        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W
        cmp beaconX
        bcc .coarseLeftDiagonal
        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        cmp beaconY
        bcc .coarseUpperRight
        lda #8
        bne .coarseReady
.coarseUpperRight:
        lda #56
        bne .coarseReady
.coarseLeftDiagonal:
        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        cmp beaconY
        bcc .coarseUpperLeft
        lda #24
        bne .coarseReady
.coarseUpperLeft:
        lda #40
        bne .coarseReady
.coarseHorizontal:
        lda tomXHi
        clc
        adc #ASTRONAUT_HALF_W
        cmp beaconX
        bcc .coarseLeft
        lda #0
        beq .coarseReady
.coarseLeft:
        lda #32
        bne .coarseReady
.coarseVertical:
        lda tomYHi
        clc
        adc #ASTRONAUT_HALF_H
        cmp beaconY
        bcc .coarseUp
        lda #16
        bne .coarseReady
.coarseUp:
        lda #48

.coarseReady:
        ; Search coarse-22.5, coarse, and coarse+22.5 degrees only.
        sec
        sbc #4
        and #63
        sta temp
        lda #3
        sta delta
        lda #$FF
        sta bestDistance
.candidateLoop:
        ldx temp
        lda orbitRadius
        beq .candidateNear
        cmp #1
        beq .candidateMid
        lda OrbitXFar,x
        ldy OrbitYFar,x
        jmp .candidateReady
.candidateMid:
        lda OrbitXMid,x
        ldy OrbitYMid,x
        jmp .candidateReady
.candidateNear:
        lda OrbitXNear,x
        ldy OrbitYNear,x
.candidateReady:
        clc
        adc beaconX
        sec
        sbc #ASTRONAUT_HALF_W
        sec
        sbc tomXHi
        bcs .candidateXReady
        eor #$FF
        clc
        adc #1
.candidateXReady:
        sta captureDistance

        tya
        clc
        adc beaconY
        sec
        sbc #ASTRONAUT_HALF_H
        sec
        sbc tomYHi
        bcs .candidateYReady
        eor #$FF
        clc
        adc #1
.candidateYReady:
        clc
        adc captureDistance
        cmp bestDistance
        bcs .nextCandidate
        sta bestDistance
        lda temp
        sta bestBeacon
.nextCandidate:
        lda temp
        clc
        adc #4
        and #63
        sta temp
        dec delta
        bne .candidateLoop
        lda bestBeacon
        sta orbitAngle
        rts

UpdateOrbit:
        lda orbitAngle
        sta bestBeacon           ; preceding legal angle for rollback
        lda orbitHalfStep
        sta bestDistance         ; preceding wide-tier substep for rollback

        ; The wide tier remains deliberately slow, but its former two-frame
        ; holds are replaced by calculated midpoints. Major Tom now receives
        ; a fresh rendered position on every 60 Hz frame.
        lda orbitRadius
        cmp #2
        bne .advanceOrbit
        lda orbitHalfStep
        bne .finishWideStep
        jsr CalculateOrbitFarHalf
        bcs .advanceOrbit        ; no distinct lattice point between endpoints
        lda #1
        sta orbitHalfStep
        lda temp2
        jsr PlaceOrbitOffsets
        jmp .checkOrbitCandidate
.finishWideStep:
        lda #0
        sta orbitHalfStep
.advanceOrbit:
        lda orbitAngle
        ldy orbitDirection
        bmi .counterClockwise
        clc
        adc orbitStep
        bne .angleReady
.counterClockwise:
        sec
        sbc orbitStep
.angleReady:
        and #63
        sta orbitAngle
.placeCurrentOrbit:
        jsr PlaceOrbitAtCurrentAngle
.checkOrbitCandidate:
        jsr CheckTerrainSoftware
        bcc .orbitReady

        ; Never render an intersecting orbit point. Return to the preceding
        ; legal angle and reverse exactly once, independent of TIA latches.
        lda bestBeacon
        sta orbitAngle
        lda bestDistance
        sta orbitHalfStep
        lda orbitDirection
        eor #$FF
        sta orbitDirection
        jsr RestoreSafePosition
.orbitReady:
        rts

PlaceOrbitAtCurrentAngle:
        ldx orbitAngle
        lda orbitRadius
        beq .placeNear
        cmp #1
        beq .placeMid
        lda OrbitYFar,x
        sta temp
        lda OrbitXFar,x
        jmp PlaceOrbitOffsets
.placeMid:
        lda OrbitYMid,x
        sta temp
        lda OrbitXMid,x
        jmp PlaceOrbitOffsets
.placeNear:
        lda OrbitYNear,x
        sta temp
        lda OrbitXNear,x
PlaceOrbitOffsets:
        clc
        adc beaconX
        sec
        sbc #ASTRONAUT_HALF_W
        sta tomXHi
        lda temp
        clc
        adc beaconY
        sec
        sbc #ASTRONAUT_HALF_H
        sta tomYHi
        lda #0
        sta tomXLo
        sta tomYLo
        rts

; Render the midpoint between two neighboring wide-ring entries. Adding 32
; converts every signed -19..19 offset to an unsigned value before averaging;
; subtracting 32 restores the signed result. This costs only overscan time and
; avoids a second 128-entry pair of ROM tables.
CalculateOrbitFarHalf:
        lda orbitAngle
        ldy orbitDirection
        bmi .halfCounterClockwise
        clc
        adc #1
        bne .halfAngleReady
.halfCounterClockwise:
        sec
        sbc #1
.halfAngleReady:
        and #63
        sta delta

        ldx orbitAngle
        lda OrbitXFar,x
        clc
        adc #32
        sta temp2
        ldx delta
        lda OrbitXFar,x
        clc
        adc #32
        clc
        adc temp2
        lsr
        sec
        sbc #32
        sta temp2

        ldx orbitAngle
        lda OrbitYFar,x
        clc
        adc #32
        sta temp
        ldx delta
        lda OrbitYFar,x
        clc
        adc #32
        clc
        adc temp
        lsr
        sec
        sbc #32
        sta temp

        ; A radius-19 circle has twelve one-clock segments with no distinct
        ; integer midpoint. Skip those substeps instead of repeating either
        ; endpoint; the resulting 116-frame revolution changes position on
        ; every frame while retaining the deliberately slow wide-tier feel.
        ldx orbitAngle
        lda temp2
        cmp OrbitXFar,x
        bne .halfCheckNext
        lda temp
        cmp OrbitYFar,x
        beq .halfCollapsed
.halfCheckNext:
        ldx delta
        lda temp2
        cmp OrbitXFar,x
        bne .halfDistinct
        lda temp
        cmp OrbitYFar,x
        beq .halfCollapsed
.halfDistinct:
        clc
        rts
.halfCollapsed:
        sec
        rts

; Test the complete 8x14 astronaut rectangle against independently authored
; left and right terrain. Carry set means collision. The renderer and these
; two tables use the same eight-line bands.
CheckTerrainSoftware:
        lda tomYHi
        cmp #8
        bcs .softwareTopClear
        jmp .softwareHit
.softwareTopClear:
        clc
        adc #ASTRONAUT_LAST
        cmp #168
        bcc .softwareBottomClear
        jmp .softwareHit
.softwareBottomClear:

        lda tomYHi
        lsr
        lsr
        lsr
        sta temp
        lda tomYHi
        clc
        adc #ASTRONAUT_LAST
        lsr
        lsr
        lsr
        sta temp2
        lda #0
        sta delta               ; greatest left-side inset
        sta captureDistance     ; greatest right-side inset
        ldx temp
.insetLoop:
        ldy currentStage
        lda StageTerrainId,y
        beq .stage1LeftInset
        cmp #TERRAIN_COBALT
        beq .stage2LeftInset
        cmp #TERRAIN_EMERALD
        beq .stage3LeftInset
        cmp #TERRAIN_CRIMSON
        beq .stage4LeftInset
        lda Stage5LeftInsetByBand,x
        jmp .leftInsetReady
.stage4LeftInset:
        lda Stage4LeftInsetByBand,x
        jmp .leftInsetReady
.stage3LeftInset:
        lda Stage3LeftInsetByBand,x
        jmp .leftInsetReady
.stage2LeftInset:
        lda Stage2LeftInsetByBand,x
        jmp .leftInsetReady
.stage1LeftInset:
        lda TerrainLeftInsetByBand,x
.leftInsetReady:
        cmp delta
        bcc .nextLeftInset
        sta delta
.nextLeftInset:
        ldy currentStage
        lda StageTerrainId,y
        beq .stage1RightInset
        cmp #TERRAIN_COBALT
        beq .stage2RightInset
        cmp #TERRAIN_EMERALD
        beq .stage3RightInset
        cmp #TERRAIN_CRIMSON
        beq .stage4RightInset
        lda Stage5RightInsetByBand,x
        jmp .rightInsetReady
.stage4RightInset:
        lda Stage4RightInsetByBand,x
        jmp .rightInsetReady
.stage3RightInset:
        lda Stage3RightInsetByBand,x
        jmp .rightInsetReady
.stage2RightInset:
        lda Stage2RightInsetByBand,x
        jmp .rightInsetReady
.stage1RightInset:
        lda TerrainRightInsetByBand,x
.rightInsetReady:
        cmp captureDistance
        bcc .nextRightInset
        sta captureDistance
.nextRightInset:
        cpx temp2
        beq .checkSoftwareSides
        inx
        bne .insetLoop

.checkSoftwareSides:
        lda tomXHi
        cmp delta
        bcc .softwareHit
        lda #152
        sec
        sbc captureDistance
        cmp tomXHi
        bcc .softwareHit
        clc
        rts
.softwareHit:
        sec
        rts

ReleaseOrbit:
        lda #STATE_FREE
        sta gameState
        lda #NO_BEACON
        sta readyBeacon
        lda orbitAngle
        lsr
        lsr
        and #15
        tax
        lda orbitDirection
        bpl .releaseIndexReady
        txa
        clc
        adc #8
        and #15
        tax
.releaseIndexReady:
        lda orbitRadius
        beq .releaseNear
        cmp #1
        beq .releaseMid
        lda ReleaseFarXHi,x
        sta velXHi
        lda ReleaseFarXLo,x
        sta velXLo
        lda ReleaseFarYHi,x
        sta velYHi
        lda ReleaseFarYLo,x
        sta velYLo
        jmp .releaseReady
.releaseMid:
        lda ReleaseMidXHi,x
        sta velXHi
        lda ReleaseMidXLo,x
        sta velXLo
        lda ReleaseMidYHi,x
        sta velYHi
        lda ReleaseMidYLo,x
        sta velYLo
        jmp .releaseReady
.releaseNear:
        lda ReleaseNearXHi,x
        sta velXHi
        lda ReleaseNearXLo,x
        sta velXLo
        lda ReleaseNearYHi,x
        sta velYHi
        lda ReleaseNearYLo,x
        sta velYLo
.releaseReady:
        ; Give upward releases a small 0.125-pixel/frame advantage against
        ; ambient gravity. Horizontal and downward release components remain
        ; exactly as authored in the tangent tables.
        lda velYHi
        bpl .releaseBoostReady
        sec
        lda velYLo
        sbc #$20
        sta velYLo
        lda velYHi
        sbc #0
        sta velYHi
.releaseBoostReady:
        jsr EnsureHorizontalMotion
        lda #SFX_RELEASE
        jsr StartSound
        rts

UpdateFreeFlight:
        clc
        lda velYLo
        adc #GRAVITY
        sta velYLo
        lda velYHi
        adc #0
        sta velYHi
        bmi .fallReady
        bne .capFall
        lda velYLo
        cmp #MAX_FALL_LO
        bcc .fallReady
.capFall:
        lda #0
        sta velYHi
        lda #MAX_FALL_LO
        sta velYLo
.fallReady:
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
        bmi .checkTop
        lda tomYHi
        cmp #BOTTOM_LIMIT+1
        bcc .checkTop
        lda #BOTTOM_LIMIT
        sta tomYHi
        lda #0
        sta tomYLo
        lda #>MOON_RETURN
        sta velYHi
        lda #<MOON_RETURN
        sta velYLo
.checkTop:
        lda velYHi
        bpl .checkSides
        lda tomYHi
        cmp #240
        bcs .hitTop
        cmp #TOP_LIMIT
        bcs .checkSides
.hitTop:
        lda #TOP_LIMIT
        sta tomYHi
        lda #0
        sta tomYLo
        sta velYHi
        lda #$80
        sta velYLo
.checkSides:
        lda velXHi
        bmi .movingLeft
        lda tomXHi
        cmp #RIGHT_LIMIT+1
        bcc .motionSafe
        lda #RIGHT_LIMIT
        sta tomXHi
        lda #0
        sta tomXLo
        lda #$FF
        sta velXHi
        lda #$80
        sta velXLo
        jmp .motionSafe
.movingLeft:
        lda tomXHi
        cmp #160
        bcs .hitLeft
        cmp #LEFT_LIMIT+1
        bcs .motionSafe
.hitLeft:
        lda #LEFT_LIMIT
        sta tomXHi
        lda #0
        sta tomXLo
        lda #>SIDE_RETURN
        sta velXHi
        lda #<SIDE_RETURN
        sta velXLo
.motionSafe:
        jsr EnsureHorizontalMotion
        rts

EnsureHorizontalMotion:
        lda velXHi
        bne .moving
        lda velXLo
        bne .moving
        lda tomXHi
        cmp #80
        bcc .pushRight
        lda #$FF
        sta velXHi
        lda #$80
        sta velXLo
        rts
.pushRight:
        lda #0
        sta velXHi
        lda #$80
        sta velXLo
.moving:
        rts

; Four independent mission objects. The first three are required; the high
; object is optional. Rendering masks are separate from the bitfield so the
; visible kernel can erase a collected P1 object with one three-cycle AND.
CheckCollectibles:
        lda collectMask
        and #1
        bne .checkCollect1
        ldx currentStage
        lda Collect0XByStage,x
        sta temp
        lda Collect0YByStage,x
        sta temp2
        jsr CheckCollectibleOverlap
        bcc .checkCollect1
        lda collectMask
        ora #1
        sta collectMask
        lda #0
        sta collectDraw0
        inc requiredCount
        inc scoreTens
        lda #SFX_REQUIRED
        jsr StartSound

.checkCollect1:
        lda collectMask
        and #2
        bne .checkCollect2
        ldx currentStage
        lda Collect1XByStage,x
        sta temp
        lda Collect1YByStage,x
        sta temp2
        jsr CheckCollectibleOverlap
        bcc .checkCollect2
        lda collectMask
        ora #2
        sta collectMask
        lda #0
        sta collectDraw1
        inc requiredCount
        inc scoreTens
        lda #SFX_REQUIRED
        jsr StartSound

.checkCollect2:
        lda collectMask
        and #4
        bne .checkOptional
        ldx currentStage
        lda Collect2XByStage,x
        sta temp
        lda Collect2YByStage,x
        sta temp2
        jsr CheckCollectibleOverlap
        bcc .checkOptional
        lda collectMask
        ora #4
        sta collectMask
        lda #0
        sta collectDraw2
        inc requiredCount
        inc scoreTens
        lda #SFX_REQUIRED
        jsr StartSound

.checkOptional:
        lda collectMask
        and #8
        bne .checkRequiredTotal
        ldx currentStage
        lda OptionalXByStage,x
        sta temp
        lda OptionalYByStage,x
        sta temp2
        jsr CheckCollectibleOverlap
        bcc .checkRequiredTotal
        lda collectMask
        ora #8
        sta collectMask
        lda #0
        sta collectDraw3
        inc scoreTens
        inc scoreTens
        lda #SFX_OPTIONAL
        jsr StartSound

.checkRequiredTotal:
        lda requiredCount
        and #3
        cmp #3
        bcc .collectiblesReady
        lda objectiveDone
        bne .collectiblesReady
        lda #1
        sta objectiveDone
        lda #SFX_EXIT_READY
        jsr StartSound
.collectiblesReady:
        rts

; Carry set when Major Tom's complete 8x14 rectangle overlaps the selected
; collectible rectangle at temp/temp2.
CheckCollectibleOverlap:
        lda tomXHi
        clc
        adc #8
        cmp temp
        bcc .noCollectibleOverlap
        beq .noCollectibleOverlap
        lda temp
        clc
        adc #COLLECT_W
        cmp tomXHi
        bcc .noCollectibleOverlap
        beq .noCollectibleOverlap
        lda tomYHi
        clc
        adc #ASTRONAUT_H
        cmp temp2
        bcc .noCollectibleOverlap
        beq .noCollectibleOverlap
        lda temp2
        clc
        adc #COLLECT_H
        cmp tomYHi
        bcc .noCollectibleOverlap
        beq .noCollectibleOverlap
        sec
        rts
.noCollectibleOverlap:
        clc
        rts

CheckMissionContact:
        lda objectiveDone
        beq .missionReady

        ; The same complete-rectangle rule used by collectibles makes contact
        ; with the visible 8x15 gate deterministic in every emulator.
        ldx currentStage
        lda ExitXByStage,x
        sta temp
        lda ExitYByStage,x
        sta temp2
        lda tomXHi
        clc
        adc #8
        cmp temp
        bcc .missionReady
        beq .missionReady
        lda temp
        clc
        adc #EXIT_W
        cmp tomXHi
        bcc .missionReady
        beq .missionReady
        lda tomYHi
        clc
        adc #ASTRONAUT_H
        cmp temp2
        bcc .missionReady
        beq .missionReady
        lda temp2
        clc
        adc #EXIT_H
        cmp tomYHi
        bcc .missionReady
        beq .missionReady
        lda #1
        sta stageComplete
        lda #SFX_STAGE_COMPLETE
        jsr StartSound
.missionReady:
        rts

; ---------------------------------------------------------------------------
; Sound effects — updated once per frame after gameplay and before Bank 7's
; visible kernel. No audio branch, table lookup, or register write occurs on a
; displayed scanline. Starting a newer event intentionally replaces an older
; one; the exit-ready cue therefore supersedes the ordinary third pickup.
; ---------------------------------------------------------------------------
StartSound:
        tax
        lda SoundDuration,x
        sta temp
        txa
        asl
        asl
        asl
        asl
        asl
        ora temp
        sta soundState
        rts

UpdateSound:
        lda soundState
        and #$1F
        bne .soundPlaying
        lda #0
        sta AUDV1
        sta soundState
        lda stageComplete
        beq UpdateMusic
        lda #0
        sta AUDV0
        rts

.soundPlaying:
        lda #0
        sta AUDV0
        lda soundState
        sec
        sbc #1
        sta soundState
        and #$1F
        sta temp
        lda soundState
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda SoundControl,x
        sta AUDC1
        cpx #SFX_CAPTURE
        beq .captureSound
        cpx #SFX_RELEASE
        beq .releaseSound
        cpx #SFX_REQUIRED
        beq .requiredSound
        cpx #SFX_OPTIONAL
        beq .optionalSound
        cpx #SFX_EXIT_READY
        beq .exitReadySound

        ; A quiet low-register rise and fall replaces the former loud beep.
        ; Completion owns a dedicated volume-four envelope instead of the
        ; general effect envelope, which deliberately reaches volume nine.
        lda temp
        lsr
        lsr
        tax
        lda CompletionFrequency,x
        sta AUDF1
        lda temp
        cmp #5
        bcc .storeCompletionVolume
        lda #4
.storeCompletionVolume:
        sta AUDV1
        rts

.captureSound:
        ; A short rising lock-on tone.
        lda temp
        clc
        adc #3
        bne .storeFrequency

.releaseSound:
        ; A restrained descending noise sweep.
        lda #18
        sec
        sbc temp
        bne .storeFrequency

.requiredSound:
        ; Quick alternating crystalline chirp.
        lda temp
        and #3
        asl
        clc
        adc #5
        bne .storeFrequency

.optionalSound:
        ; Warmer, higher two-note reward for optional salvage.
        lda temp
        and #4
        lsr
        clc
        adc #3
        bne .storeFrequency

.exitReadySound:
        ; Longer rising confirmation that extraction is now available.
        lda temp
        lsr
        clc
        adc #3

.storeFrequency:
        sta AUDF1
        lda temp
        cmp #9
        bcc .storeVolume
        lda #9
.storeVolume:
        sta AUDV1
        rts

; The Chapter One score is an eight-phrase A-minor/F/C/G composition lasting
; about thirty-four seconds. Channel 0 alone performs each main note, its
; silence, the lower-octave ghost, and a longer rest in sequence. Channel 1 is
; silent during music and reserved exclusively for gameplay sound effects.
UpdateMusic:
        lda frameCounter
        bne .musicPhraseReady
        lda stageSetupPending
        bmi .musicPhraseReady       ; first Stage 2 frame starts at phrase 0
        lda requiredCount
        and #$E0
        cmp #$E0
        beq .wrapMusicPhrase
        lda requiredCount
        clc
        adc #$20
        sta requiredCount
        bne .musicPhraseReady
.wrapMusicPhrase:
        lda requiredCount
        and #3
        sta requiredCount

.musicPhraseReady:
        lda requiredCount
        and #$E0
        lsr
        lsr
        sta temp                    ; phrase * 8
        lda frameCounter
        lsr
        lsr
        lsr
        lsr
        lsr
        ora temp
        tay                         ; 0..63 score position

        lda MusicMonoNotes,y
        cmp #MUSIC_REST
        beq .muteMusic
        sta AUDF0
        lda #12
        sta AUDC0
        tya
        and #7
        cmp #1
        beq .playGhost
        cmp #4
        beq .playGhost
        cmp #7
        beq .playGhost

        ; Principal notes use the soft volume-two swell.
        lda frameCounter
        and #$1F
        tax
        lda MusicLeadEnvelope,x
        sta AUDV0
        rts
.playGhost:
        ; The following position answers at the lower octave and volume one.
        lda frameCounter
        and #$1F
        tax
        lda MusicEchoEnvelope,x
        sta AUDV0
        rts
.muteMusic:
        lda #0
        sta AUDV0
        rts

SoundDuration:
        byte 0,10,10,14,18,20,31
SoundControl:
        byte 0,4,8,6,4,4,12
; Read from index 7 down to 0: low A-minor rise, then a soft return.
CompletionFrequency:
        byte 23,23,19,15,11,15,19,23

; Rounded two-step lead envelope with a long breath before the next position.
MusicLeadEnvelope:
        byte 0,1,1,1,2,2,2,2
        byte 2,2,2,2,1,1,1,1
        byte 1,1,1,1,0,0,0,0
        byte 0,0,0,0,0,0,0,0

; The echo is quieter and shorter, producing distance rather than a duet.
MusicEchoEnvelope:
        byte 0,0,0,1,1,1,1,1
        byte 1,0,0,0,0,0,0,0
        byte 0,0,0,0,0,0,0,0
        byte 0,0,0,0,0,0,0,0

; A minor, F major, C major, G major. Every pair is main then lower-octave
; ghost, followed by a completely silent position before the next statement.
; The second phrase of each chord changes note order without adding chromatic
; pitches. No two music tones can ever overlap because this is one TIA voice.
MusicMonoNotes:
        byte 11,23,MUSIC_REST,9,19,MUSIC_REST,7,15
        byte 11,23,MUSIC_REST,7,15,MUSIC_REST,9,19
        byte 14,29,MUSIC_REST,11,23,MUSIC_REST,9,19
        byte 14,29,MUSIC_REST,9,19,MUSIC_REST,11,23
        byte 9,19,MUSIC_REST,7,15,MUSIC_REST,6,13
        byte 9,19,MUSIC_REST,6,13,MUSIC_REST,7,15
        byte 12,25,MUSIC_REST,10,21,MUSIC_REST,8,17
        byte 12,25,MUSIC_REST,8,17,MUSIC_REST,10,21

; ---------------------------------------------------------------------------
; Production stage descriptors. Parallel arrays are intentional: the 6502 can
; select any field with one LDX/LDA abs,X pair, and later stages can reuse a
; terrain, palette, behavior, or chapter theme without duplicating that asset.
; ---------------------------------------------------------------------------
StageSpawnX:
        byte SPAWN_X,STAGE2_SPAWN_X,STAGE3_SPAWN_X,STAGE4_SPAWN_X,STAGE5_SPAWN_X
StageSpawnY:
        byte SPAWN_Y,STAGE2_SPAWN_Y,STAGE3_SPAWN_Y,STAGE4_SPAWN_Y,STAGE5_SPAWN_Y
StageVelocityXHi:
        byte $00,$00,$FF,$00,$FF
StageVelocityXLo:
        byte $60,$60,$A0,$70,$90
StageVelocityYHi:
        byte $FF,$FF,$FF,$FF,$FF
StageVelocityYLo:
        byte $A0,$A0,$B0,$90,$A0
StageBeaconOffset:
        byte 0,3,6,9,12
StageTerrainId:
        byte TERRAIN_AMETHYST,TERRAIN_COBALT,TERRAIN_EMERALD,TERRAIN_CRIMSON
        byte TERRAIN_VOID_VIOLET
StagePaletteId:
        byte PALETTE_AMETHYST,PALETTE_COBALT,PALETTE_EMERALD,PALETTE_CRIMSON
        byte PALETTE_VOID_VIOLET
StageBehaviorId:
        byte BEHAVIOR_NORMAL_ROCK,BEHAVIOR_NORMAL_ROCK
        byte BEHAVIOR_NORMAL_ROCK,BEHAVIOR_NORMAL_ROCK
        byte BEHAVIOR_NORMAL_ROCK
StageMusicId:
        byte MUSIC_CHAPTER_ONE,MUSIC_CHAPTER_ONE
        byte MUSIC_CHAPTER_ONE,MUSIC_CHAPTER_ONE
        byte MUSIC_CHAPTER_ONE
StageRoomBank:
        byte ROOM_BANK_STAGE1,ROOM_BANK_STAGE2,ROOM_BANK_STAGE3,ROOM_BANK_STAGE4
        byte ROOM_BANK_STAGE5
StageNextByStage:
        byte 1,2,3,4,NO_NEXT_STAGE

; Three satellite installations per stage. Dish coordinates describe visible
; art; the corresponding Beacon tables below describe their exact centers.
Dish0XByStage:
        byte DISH_A_LEFT,STAGE2_DISH_A_LEFT,STAGE3_DISH_A_LEFT,STAGE4_DISH_A_LEFT
        byte STAGE5_DISH_A_LEFT
Dish0YByStage:
        byte 29,29,29,29,29
Dish1XByStage:
        byte DISH_B_LEFT,STAGE2_DISH_B_LEFT,STAGE3_DISH_B_LEFT,STAGE4_DISH_B_LEFT
        byte STAGE5_DISH_B_LEFT
Dish1YByStage:
        byte 77,77,77,77,77
Dish2XByStage:
        byte DISH_C_LEFT,STAGE2_DISH_C_LEFT,STAGE3_DISH_C_LEFT,STAGE4_DISH_C_LEFT
        byte STAGE5_DISH_C_LEFT
Dish2YByStage:
        byte 123,123,123,123,123

BeaconXTable:
        byte BEACON_AX,BEACON_BX,BEACON_CX
        byte STAGE2_BEACON_AX,STAGE2_BEACON_BX,STAGE2_BEACON_CX
        byte STAGE3_BEACON_AX,STAGE3_BEACON_BX,STAGE3_BEACON_CX
        byte STAGE4_BEACON_AX,STAGE4_BEACON_BX,STAGE4_BEACON_CX
        byte STAGE5_BEACON_AX,STAGE5_BEACON_BX,STAGE5_BEACON_CX
BeaconYTable:
        byte BEACON_AY,BEACON_BY,BEACON_CY
        byte STAGE2_BEACON_AY,STAGE2_BEACON_BY,STAGE2_BEACON_CY
        byte STAGE3_BEACON_AY,STAGE3_BEACON_BY,STAGE3_BEACON_CY
        byte STAGE4_BEACON_AY,STAGE4_BEACON_BY,STAGE4_BEACON_CY
        byte STAGE5_BEACON_AY,STAGE5_BEACON_BY,STAGE5_BEACON_CY

Collect0XByStage:
        byte COLLECT_0_LEFT,STAGE2_COLLECT_0_LEFT,STAGE3_COLLECT_0_LEFT,STAGE4_COLLECT_0_LEFT
        byte STAGE5_COLLECT_0_LEFT
Collect0YByStage:
        byte COLLECT_0_TOP,COLLECT_0_TOP,COLLECT_0_TOP,COLLECT_0_TOP,COLLECT_0_TOP
Collect1XByStage:
        byte COLLECT_1_LEFT,STAGE2_COLLECT_1_LEFT,STAGE3_COLLECT_1_LEFT,STAGE4_COLLECT_1_LEFT
        byte STAGE5_COLLECT_1_LEFT
Collect1YByStage:
        byte COLLECT_1_TOP,COLLECT_1_TOP,COLLECT_1_TOP,COLLECT_1_TOP,COLLECT_1_TOP
Collect2XByStage:
        byte COLLECT_2_LEFT,STAGE2_COLLECT_2_LEFT,STAGE3_COLLECT_2_LEFT,STAGE4_COLLECT_2_LEFT
        byte STAGE5_COLLECT_2_LEFT
Collect2YByStage:
        byte COLLECT_2_TOP,COLLECT_2_TOP,COLLECT_2_TOP,COLLECT_2_TOP,COLLECT_2_TOP
OptionalXByStage:
        byte OPTIONAL_LEFT,STAGE2_OPTIONAL_LEFT,STAGE3_OPTIONAL_LEFT,STAGE4_OPTIONAL_LEFT
        byte STAGE5_OPTIONAL_LEFT
OptionalYByStage:
        byte OPTIONAL_TOP,OPTIONAL_TOP,OPTIONAL_TOP,OPTIONAL_TOP,OPTIONAL_TOP
ExitXByStage:
        byte EXIT_LEFT,STAGE2_EXIT_LEFT,STAGE3_EXIT_LEFT,STAGE4_EXIT_LEFT,STAGE5_EXIT_LEFT
ExitYByStage:
        byte EXIT_TOP,EXIT_TOP,EXIT_TOP,EXIT_TOP,EXIT_TOP

; Exact solid depths, in color clocks, for the independent terrain halves.
TerrainLeftInsetByBand:
        byte 80,32,28,24,20,16,16,20,24,20,16
        byte 16,16,20,24,20,16,20,24,28,32,80
TerrainRightInsetByBand:
        byte 80,20,16,16,16,20,24,28,24,20,16
        byte 16,20,28,32,24,16,16,20,24,28,80
Stage2LeftInsetByBand:
        byte 80,16,20,32,44,48,36,24,16,20,36
        byte 48,40,28,16,20,28,36,44,48,40,80
Stage2RightInsetByBand:
        byte 80,48,40,32,24,20,16,24,36,40,36
        byte 28,20,16,20,28,40,48,40,32,24,80
Stage3LeftInsetByBand:
        byte 80,24,20,16,20,28,36,28,20,16,24
        byte 36,44,32,24,16,20,28,36,28,20,80
Stage3RightInsetByBand:
        byte 80,20,28,36,44,48,36,24,20,24,32
        byte 28,20,16,20,28,40,48,36,24,20,80
Stage4LeftInsetByBand:
        byte 80,24,28,24,20,16,20,28,40,48,36
        byte 24,16,20,28,40,48,36,28,20,16,80
Stage4RightInsetByBand:
        byte 80,16,20,24,32,40,36,36,24,16,20
        byte 28,40,48,36,24,16,20,28,40,32,80
Stage5LeftInsetByBand:
        byte 80,24,28,28,20,16,24,36,48,32,20
        byte 16,28,44,36,24,16,28,40,48,32,80
Stage5RightInsetByBand:
        byte 80,20,16,24,36,48,36,28,16,24,40
        byte 44,32,20,16,28,44,36,24,16,28,80

; 64-position circular paths: tight radius 8, medium 13, wide 19.
        ALIGN 256
OrbitXNear:
        byte 8,8,8,8,7,7,6,6,6,5,5,4,3,2,2,1
        byte 0,-1,-2,-2,-3,-4,-5,-5,-6,-6,-6,-7,-7,-8,-8,-8
        byte -8,-8,-8,-8,-7,-7,-6,-6,-6,-5,-5,-4,-3,-2,-2,-1
        byte 0,1,2,2,3,4,5,5,6,6,6,7,7,8,8,8
OrbitYNear:
        byte 0,1,2,2,3,4,5,5,6,6,6,7,7,8,8,8
        byte 8,8,8,8,7,7,6,6,6,5,5,4,3,2,2,1
        byte 0,-1,-2,-2,-3,-4,-5,-5,-6,-6,-6,-7,-7,-8,-8,-8
        byte -8,-8,-8,-8,-7,-7,-6,-6,-6,-5,-5,-4,-3,-2,-2,-1
OrbitXMid:
        byte 13,13,13,12,12,11,11,10,9,8,7,6,5,4,3,1
        byte 0,-1,-3,-4,-5,-6,-7,-8,-9,-10,-11,-11,-12,-12,-13,-13
        byte -13,-13,-13,-12,-12,-11,-11,-10,-9,-8,-7,-6,-5,-4,-3,-1
        byte 0,1,3,4,5,6,7,8,9,10,11,11,12,12,13,13
OrbitYMid:
        byte 0,1,3,4,5,6,7,8,9,10,11,11,12,12,13,13
        byte 13,13,13,12,12,11,11,10,9,8,7,6,5,4,3,1
        byte 0,-1,-3,-4,-5,-6,-7,-8,-9,-10,-11,-11,-12,-12,-13,-13
        byte -13,-13,-13,-12,-12,-11,-11,-10,-9,-8,-7,-6,-5,-4,-3,-1
OrbitXFar:
        byte 19,19,19,18,17,17,16,14,14,12,11,9,8,5,4,2
        byte 0,-2,-4,-5,-8,-9,-11,-12,-14,-14,-16,-17,-17,-18,-19,-19
        byte -19,-19,-19,-18,-17,-17,-16,-14,-14,-12,-11,-9,-8,-5,-4,-2
        byte 0,2,4,5,8,9,11,12,14,14,16,17,17,18,19,19
OrbitYFar:
        byte 0,2,4,5,8,9,11,12,14,14,16,17,17,18,19,19
        byte 19,19,19,18,17,17,16,14,14,12,11,9,8,5,4,2
        byte 0,-2,-4,-5,-8,-9,-11,-12,-14,-14,-16,-17,-17,-18,-19,-19
        byte -19,-19,-19,-18,-17,-17,-16,-14,-14,-12,-11,-9,-8,-5,-4,-2

; Sixteen equal-magnitude tangent release directions per tier.
        ALIGN 256
ReleaseNearXHi:
        byte $00,$FF,$FF,$FE,$FE,$FE,$FF,$FF,$00,$00,$00,$01,$01,$01,$00,$00
ReleaseNearXLo:
        byte $00,$80,$12,$CA,$B0,$CA,$12,$80,$00,$80,$EE,$36,$50,$36,$EE,$80
ReleaseNearYHi:
        byte $01,$01,$01,$00,$00,$FF,$FE,$FE,$FE,$FE,$FE,$FF,$00,$00,$01,$01
ReleaseNearYLo:
        byte $C0,$9E,$3D,$AB,$00,$55,$C3,$62,$40,$62,$C3,$55,$00,$AB,$3D,$9E
ReleaseMidXHi:
        byte $00,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$00,$00,$00,$00,$01,$00,$00,$00
ReleaseMidXLo:
        byte $00,$9B,$45,$0C,$F8,$0C,$45,$9B,$00,$65,$BB,$F4,$08,$F4,$BB,$65
ReleaseMidYHi:
        byte $01,$01,$00,$00,$00,$FF,$FF,$FE,$FE,$FE,$FF,$FF,$00,$00,$00,$01
ReleaseMidYLo:
        byte $60,$45,$F9,$87,$00,$79,$07,$BB,$A0,$BB,$07,$79,$00,$87,$F9,$45
ReleaseFarXHi:
        byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
ReleaseFarXLo:
        byte $00,$B6,$78,$4E,$40,$4E,$78,$B6,$00,$4A,$88,$B2,$C0,$B2,$88,$4A
ReleaseFarYHi:
        byte $01,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00
ReleaseFarYLo:
        byte $00,$ED,$B5,$62,$00,$9E,$4B,$13,$00,$13,$4B,$9E,$00,$62,$B5,$ED

; Fixed cross-bank continuation. Bank 1 switches at $FFD0; execution arrives
; here at $FFD3, performs physics, then selects bank 1 and lands on its RTS.
        ORG $0FD3
        RORG $FFD3
PhysicsBankEntry:
        jsr UpdatePhysics
        lda $FFFB

        ORG $0FFA
        RORG $FFFA
        word $F000,$F000,$F000

; ---------------------------------------------------------------------------
; BANK 1 — approved title presentation and Chapter One completion card.
; ---------------------------------------------------------------------------
        SEG BANK1
        ORG $1000
        RORG $F000
Bank1Boot:
        lda $FFFB
        jmp $F006

        ORG $1006
        RORG $F006
        include "thursdays-child-title-bank.inc"

        ; Bank 2's credits screen selects Bank 1 at $FFB0; instruction fetch
        ; continues here after the hotspot read.
        ORG $1FB3
        RORG $FFB3
TitleEntryLanding:
        jmp TitleInit

        ; Title Fire advances to the NASA terminal in Bank 2.
        ORG $1FC0
        RORG $FFC0
TitleToTerminalGate:
        lda $FFF6

        ; RESET from any Bank 1 presentation returns through fixed Bank 7.
        ORG $1FE8
        RORG $FFE8
Bank1ResetGate:
        lda $FFFB

        ORG $1FFA
        RORG $FFFA
        word $F000,$F000,$F000

; BANK 2 — power-on credits and approved three-page NASA terminal briefing.
        SEG BANK2
        ORG $2000
        RORG $F000
Bank2Boot:
        lda $FFFB
        jmp $F006

        ORG $2006
        RORG $F006
        include "thursdays-child-credits-bank.inc"
        include "thursdays-child-terminal-bank.inc"
        include "thursdays-child-credits-compact.inc"

        ; Power-on entry from fixed Bank 7.
    ORG $2FA3
    RORG $FFA3
CreditsEntryLanding:
    jmp CreditsInit

        ; Credits Fire advances to title Bank 1.
        ORG $2FB0
        RORG $FFB0
CreditsToTitleGate:
        lda $FFF5

        ; Landing after title Bank 1 selects this bank.
        ORG $2FC3
        RORG $FFC3
TerminalEntryLanding:
        jmp TerminalInit

        ; Final terminal Fire enters gameplay in fixed Bank 7.
        ORG $2FE0
        RORG $FFE0
TerminalToGameplayGate:
        lda $FFFB

        ORG $2FE8
        RORG $FFE8
Bank2ResetGate:
        lda $FFFB

        ORG $2FFA
        RORG $FFFA
        word $F000,$F000,$F000

        SEG BANK3
        ORG $3000
        RORG $F000
Bank3Boot:
        lda $FFFB
        jmp $F006

; ---------------------------------------------------------------------------
; STAGE 5 ROOM BANK
;
; Bank 6 owns a complete, scanline-stable room kernel and its own terrain
; pages.  No bank switch occurs while the beam is drawing the room.  The
; astronaut art is repeated at the same virtual addresses used by Bank 7, so
; SelectPose can prepare one pointer format for both stages.
; ---------------------------------------------------------------------------
        ORG $3100
        RORG $F100
Stage5RoomStart:
        lda TerrainColor
        sta COLUPF
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        ldx #0
        sta WSYNC
        lda #$F0
        sta PF0

Stage5RoomKernel:
        lda TerrainColor,x
        sta COLUPF
        lda TerrainLeftPF1,x
        sta PF1
        lda TerrainPF2,x
        sta PF2
        lda TerrainRightPF1,x
        sta PF1

        txa
        sec
        sbc renderTomY
        cmp #ASTRONAUT_H
        bcc Stage5DrawTom
        lda StarEnable,x
        and visorEnable
        sta ENAM0
        lda #0
        sta GRP0
        beq Stage5StarEvenReady
Stage5DrawTom:
        lsr
        tay
        lda (suitPtr),y
        sta GRP0
        lda #0
        sta ENAM0
        beq Stage5EvenReady
Stage5StarEvenReady:
        sta ENAM0             ; shut the point off before the following line
Stage5EvenReady:
        sta WSYNC
        inx

        lda WorldGraphics,x
        and currentP1Mask
        sta GRP1
        lda currentP1Color
        sta COLUP1
        lda TerrainLeftPF1,x
        sta PF1
        lda ServiceCode,x
        beq Stage5OrdinaryOdd
        cmp #4
        bcs Stage5ServiceHigh
        cmp #2
        bcc Stage5JumpDishA
        beq Stage5JumpCollect0
        jmp Stage5ServiceDishB
Stage5JumpDishA:
        jmp Stage5ServiceDishA
Stage5JumpCollect0:
        jmp Stage5ServiceCollect0

Stage5ServiceHigh:
        beq Stage5JumpCollect1
        cmp #6
        bcc Stage5ServiceDishC
        beq Stage5ServiceCollect2

Stage5ServiceExit:
        nop
        nop
        sta RESP1
        lda #$00
        sta PF1
        lda exitDraw
        sta currentP1Mask
        lda exitP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5ServiceDishC:
        sta RESP1
        sta RESM0
        lda #$00
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorC
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5ServiceCollect2:
        lda #$F8
        sta PF1
        nop
        sta RESP1
        sta RESM0
        lda collectDraw2
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5JumpCollect1:
        jmp Stage5ServiceCollect1

Stage5OrdinaryOdd:
        jmp Stage5StarOddControl

; Stage 5's authored X positions differ from Stage 1.  These handlers retain
; the identical state and WSYNC structure while moving only the RESP1 strobe.
Stage5ServiceDishA:
        sta RESP1
        sta RESM0
        lda #$00
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorA
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5ServiceCollect0:
        lda #$FF
        sta PF1
        nop
        nop
        nop
        sta RESP1
        lda collectDraw0
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5ServiceDishB:
        lda #$00
        sta PF1
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorB
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5ServiceCollect1:
        nop
        sta RESP1
        sta RESM0
        lda #$FE
        sta PF1
        lda collectDraw1
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage5OddNext

Stage5OddNext:
        inx
        cpx #ROOM_LINES
        beq Stage5OddDone
        jmp Stage5RoomKernel
Stage5OddDone:
        jmp Stage5RoomDone

Stage5RoomDone:
        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM1
        sta ENABL
        ldx #30
Stage5OverscanLoop:
        sta WSYNC
        dex
        bne Stage5OverscanLoop
        jmp Stage5ReturnGate

        ORG $3587
        RORG $F587
Stage5SuitUp:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage5SuitUpRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage5SuitRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage5SuitDownRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage5SuitDown:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

Stage5VisorEnable:
        byte 0,0,0,0,0,0,0

        ORG $3600
        RORG $F600
Stage5WorldGraphics:
        ds 9,0
        byte %00010000
        ds 1,0
        byte %00011000
        ds 1,0
        byte %01111100
        ds 1,0
        byte %11111110
        ds 1,0
        byte %01111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00010000
        ds 7,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 15,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 13,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 7,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 3,0
        byte %00111100
        ds 1,0
        byte %01111110
        ds 1,0
        byte %11000011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11000011
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00000000

        ORG $3700
        RORG $F700
Stage5ServiceCode:
        ds 23,0
        byte 1
        ds 21,0
        byte 2
        ds 19,0
        byte 3
        ds 27,0
        byte 4
        ds 21,0
        byte 5
        ds 23,0
        byte 6
        ds 19,0
        byte 7
        ds 16,0

        ORG $3800
        RORG $F800
Stage5TerrainColor:
        ; Deep-violet mastery room: the darkest member of Chapter One.
        byte $9E,$9C,$9A,$98,$96,$98,$9A,$9C
        ds 8,$72
        ds 8,$74
        ds 8,$76
        ds 8,$78
        ds 8,$7A
        ds 8,$7C
        ds 8,$7E
        ds 8,$7C
        ds 8,$7A
        ds 8,$78
        ds 8,$76
        ds 8,$74
        ds 8,$72
        ds 8,$82
        ds 8,$84
        ds 8,$86
        ds 8,$88
        ds 8,$8A
        ds 8,$88
        ds 8,$86
        ds 8,$84
        ds 8,$82

        ORG $3900
        RORG $F900
Stage5TerrainLeftPF1:
        ds 8,$FF
        ds 8,$C0
        ds 8,$E0
        ds 8,$E0
        ds 8,$80
        ds 8,$00
        ds 8,$C0
        ds 8,$F8
        ds 8,$FF
        ds 8,$F0
        ds 8,$80
        ds 8,$00
        ds 8,$E0
        ds 8,$FE
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$E0
        ds 8,$FC
        ds 8,$FF
        ds 8,$F0
        ds 8,$FF

        ORG $3A00
        RORG $FA00
Stage5TerrainRightPF1:
        ds 8,$FF
        ds 8,$80
        ds 8,$00
        ds 8,$C0
        ds 8,$F8
        ds 8,$FF
        ds 8,$F8
        ds 8,$E0
        ds 8,$00
        ds 8,$C0
        ds 8,$FC
        ds 8,$FE
        ds 8,$F0
        ds 8,$80
        ds 8,$00
        ds 8,$E0
        ds 8,$FE
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$E0
        ds 8,$FF

        ORG $3B00
        RORG $FB00
Stage5TerrainPF2:
        ds 8,$FF
        ds 160,$00
        ds 8,$FF

        ORG $3BD3
        RORG $FBD3
Stage5EntryLanding:
        jmp Stage5RoomStart

        ORG $3BD8
        RORG $FBD8
Stage5ReturnGate:
        lda $FFFB

        ORG $3C00
        RORG $FC00
Stage5StarEnable:
        IFCONST STARFIELD_LAB
        ds 16,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 21,0
        byte $02
        ds 13,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 9,0
        byte $02
        ds 15,0
        byte $02
        ds 17,0
        byte $02
        ds 7,0
        ELSE
        ds 176,0
        ENDIF

        ORG $3D00
        RORG $FD00
Stage5StarControl:
        IFCONST STARFIELD_LAB
        ds 15,0
        byte $10,0,$80
        ds 13,0
        byte $11,0,$80
        ds 17,0
        byte $12,0,$80
        ds 19,0
        byte $13,0,$80
        ds 11,0
        byte $11,0,$80
        ds 13,0
        byte $10,0,$80
        ds 17,0
        byte $13,0,$80
        ds 7,0
        byte $12,0,$80
        ds 13,0
        byte $10,0,$80
        ds 15,0
        byte $12,0,$80
        ds 6,0
        ELSE
        ds 176,0
        ENDIF
Stage5StarFadeColors:
        byte $02,$02,$02,$00
Stage5StarOddControl:
        lda TerrainRightPF1,x
        sta PF1
        lda Stage5StarControl,x
        beq .sync
        bmi .restore
        eor bestBeacon
        and #3
        tay
        lda Stage5StarFadeColors,y
        sta visorEnable
        sta ENAM0              ; pre-stage the next even scanline's point
        jmp .sync
.restore:
        lda #0
        sta visorEnable
        sta ENAM0
.sync:
        sta WSYNC
        jmp Stage5OddNext

        ORG $3FFA
        RORG $FFFA
        word $F000,$F000,$F000

; ---------------------------------------------------------------------------
; BANK 7 — fixed reset, frame, renderer, room and astronaut art.
; Its virtual addresses are unchanged from the approved F8 display bank.
; ---------------------------------------------------------------------------

        SEG BANK4
        ORG $4000
        RORG $F000
Bank4Boot:
        lda $FFFB
        jmp $F006

; ---------------------------------------------------------------------------
; STAGE 4 ROOM BANK
;
; Bank 6 owns a complete, scanline-stable room kernel and its own terrain
; pages.  No bank switch occurs while the beam is drawing the room.  The
; astronaut art is repeated at the same virtual addresses used by Bank 7, so
; SelectPose can prepare one pointer format for both stages.
; ---------------------------------------------------------------------------
        ORG $4100
        RORG $F100
Stage4RoomStart:
        lda TerrainColor
        sta COLUPF
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        ldx #0
        sta WSYNC
        lda #$F0
        sta PF0

Stage4RoomKernel:
        lda TerrainColor,x
        sta COLUPF
        lda TerrainLeftPF1,x
        sta PF1
        lda TerrainPF2,x
        sta PF2
        lda TerrainRightPF1,x
        sta PF1

        txa
        sec
        sbc renderTomY
        cmp #ASTRONAUT_H
        bcc Stage4DrawTom
        lda StarEnable,x
        and visorEnable
        sta ENAM0
        lda #0
        sta GRP0
        beq Stage4StarEvenReady
Stage4DrawTom:
        lsr
        tay
        lda (suitPtr),y
        sta GRP0
        lda #0
        sta ENAM0
        beq Stage4EvenReady
Stage4StarEvenReady:
        sta ENAM0
Stage4EvenReady:
        sta WSYNC
        inx

        lda WorldGraphics,x
        and currentP1Mask
        sta GRP1
        lda currentP1Color
        sta COLUP1
        lda TerrainLeftPF1,x
        sta PF1
        lda ServiceCode,x
        beq Stage4OrdinaryOdd
        cmp #4
        bcs Stage4ServiceHigh
        cmp #2
        bcc Stage4JumpDishA
        beq Stage4JumpCollect0
        jmp Stage4ServiceDishB
Stage4JumpDishA:
        jmp Stage4ServiceDishA
Stage4JumpCollect0:
        jmp Stage4ServiceCollect0

Stage4ServiceHigh:
        beq Stage4JumpCollect1
        cmp #6
        bcc Stage4ServiceDishC
        beq Stage4ServiceCollect2

Stage4ServiceExit:
        nop
        sta RESP1
        lda #$FC
        sta PF1
        lda exitDraw
        sta currentP1Mask
        lda exitP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4ServiceDishC:
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$F8
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorC
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4ServiceCollect2:
        lda #$80
        sta PF1
        nop
        nop
        sta RESP1
        sta RESM0
        lda collectDraw2
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4JumpCollect1:
        jmp Stage4ServiceCollect1

Stage4OrdinaryOdd:
        jmp Stage4StarOddControl

; Stage 4's authored X positions differ from Stage 1.  These handlers retain
; the identical state and WSYNC structure while moving only the RESP1 strobe.
Stage4ServiceDishA:
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$80
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorA
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4ServiceCollect0:
        lda #$FC
        sta PF1
        nop
        nop
        nop
        sta RESP1
        lda collectDraw0
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4ServiceDishB:
        lda #$C0
        sta PF1
        nop
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorB
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4ServiceCollect1:
        sta RESP1
        sta RESM0
        lda #$E0
        sta PF1
        lda collectDraw1
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage4OddNext

Stage4OddNext:
        inx
        cpx #ROOM_LINES
        beq Stage4OddDone
        jmp Stage4RoomKernel
Stage4OddDone:
        jmp Stage4RoomDone

Stage4RoomDone:
        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM1
        sta ENABL
        ldx #30
Stage4OverscanLoop:
        sta WSYNC
        dex
        bne Stage4OverscanLoop
        jmp Stage4ReturnGate

        ORG $4587
        RORG $F587
Stage4SuitUp:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage4SuitUpRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage4SuitRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage4SuitDownRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage4SuitDown:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

Stage4VisorEnable:
        byte 0,0,0,0,0,0,0

        ORG $4600
        RORG $F600
Stage4WorldGraphics:
        ds 9,0
        byte %00010000
        ds 1,0
        byte %00011000
        ds 1,0
        byte %01111100
        ds 1,0
        byte %11111110
        ds 1,0
        byte %01111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00010000
        ds 7,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 15,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 13,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 7,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 3,0
        byte %00111100
        ds 1,0
        byte %01111110
        ds 1,0
        byte %11000011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11000011
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00000000

        ORG $4700
        RORG $F700
Stage4ServiceCode:
        ds 23,0
        byte 1
        ds 21,0
        byte 2
        ds 19,0
        byte 3
        ds 27,0
        byte 4
        ds 21,0
        byte 5
        ds 23,0
        byte 6
        ds 19,0
        byte 7
        ds 16,0

        ORG $4800
        RORG $F800
Stage4TerrainColor:
        ; Mauve/blue variation four: brighter walls around a dark middle.
        byte $6E,$6C,$6A,$68,$66,$68,$6A,$6C
        ds 8,$82
        ds 8,$84
        ds 8,$86
        ds 8,$88
        ds 8,$8A
        ds 8,$8C
        ds 8,$8E
        ds 8,$8C
        ds 8,$8A
        ds 8,$88
        ds 8,$86
        ds 8,$84
        ds 8,$82
        ds 8,$92
        ds 8,$94
        ds 8,$96
        ds 8,$98
        ds 8,$9A
        ds 8,$98
        ds 8,$96
        ds 8,$94
        ds 8,$92

        ORG $4900
        RORG $F900
Stage4TerrainLeftPF1:
        ds 8,$FF
        ds 8,$C0
        ds 8,$E0
        ds 8,$C0
        ds 8,$80
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$FF
        ds 8,$F8
        ds 8,$E0
        ds 8,$80
        ds 8,$00
        ds 8,$FF

        ORG $4A00
        RORG $FA00
Stage4TerrainRightPF1:
        ds 8,$FF
        ds 8,$00
        ds 8,$80
        ds 8,$C0
        ds 8,$F0
        ds 8,$FC
        ds 8,$F8
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$FF
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$F0
        ds 8,$FF

        ORG $4B00
        RORG $FB00
Stage4TerrainPF2:
        ds 8,$FF
        ds 160,$00
        ds 8,$FF

        ORG $4BB3
        RORG $FBB3
Stage4EntryLanding:
        jmp Stage4RoomStart

        ORG $4BB8
        RORG $FBB8
Stage4ReturnGate:
        lda $FFFB

        ORG $4C00
        RORG $FC00
Stage4StarEnable:
        IFCONST STARFIELD_LAB
        ds 16,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 21,0
        byte $02
        ds 13,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 9,0
        byte $02
        ds 15,0
        byte $02
        ds 17,0
        byte $02
        ds 7,0
        ELSE
        ds 176,0
        ENDIF

        ORG $4D00
        RORG $FD00
Stage4StarControl:
        IFCONST STARFIELD_LAB
        ds 15,0
        byte $10,0,$80
        ds 13,0
        byte $11,0,$80
        ds 17,0
        byte $12,0,$80
        ds 19,0
        byte $13,0,$80
        ds 11,0
        byte $11,0,$80
        ds 13,0
        byte $10,0,$80
        ds 17,0
        byte $13,0,$80
        ds 7,0
        byte $12,0,$80
        ds 13,0
        byte $10,0,$80
        ds 15,0
        byte $12,0,$80
        ds 6,0
        ELSE
        ds 176,0
        ENDIF
Stage4StarFadeColors:
        byte $02,$02,$02,$00
Stage4StarOddControl:
        lda TerrainRightPF1,x
        sta PF1
        lda Stage4StarControl,x
        beq .sync
        bmi .restore
        eor bestBeacon
        and #3
        tay
        lda Stage4StarFadeColors,y
        sta visorEnable
        sta ENAM0
        jmp .sync
.restore:
        lda #0
        sta visorEnable
        sta ENAM0
.sync:
        sta WSYNC
        jmp Stage4OddNext

        ORG $4FFA
        RORG $FFFA
        word $F000,$F000,$F000

; ---------------------------------------------------------------------------
; BANK 7 — fixed reset, frame, renderer, room and astronaut art.
; Its virtual addresses are unchanged from the approved F8 display bank.
; ---------------------------------------------------------------------------

        SEG BANK5
        ORG $5000
        RORG $F000
Bank5Boot:
        lda $FFFB
        jmp $F006

; ---------------------------------------------------------------------------
; STAGE 3 ROOM BANK
;
; Bank 6 owns a complete, scanline-stable room kernel and its own terrain
; pages.  No bank switch occurs while the beam is drawing the room.  The
; astronaut art is repeated at the same virtual addresses used by Bank 7, so
; SelectPose can prepare one pointer format for both stages.
; ---------------------------------------------------------------------------
        ORG $5100
        RORG $F100
Stage3RoomStart:
        lda TerrainColor
        sta COLUPF
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        ldx #0
        sta WSYNC
        lda #$F0
        sta PF0

Stage3RoomKernel:
        lda TerrainColor,x
        sta COLUPF
        lda TerrainLeftPF1,x
        sta PF1
        lda TerrainPF2,x
        sta PF2
        lda TerrainRightPF1,x
        sta PF1

        txa
        sec
        sbc renderTomY
        cmp #ASTRONAUT_H
        bcc Stage3DrawTom
        lda StarEnable,x
        and visorEnable
        sta ENAM0
        lda #0
        sta GRP0
        beq Stage3StarEvenReady
Stage3DrawTom:
        lsr
        tay
        lda (suitPtr),y
        sta GRP0
        lda #0
        sta ENAM0
        beq Stage3EvenReady
Stage3StarEvenReady:
        sta ENAM0
Stage3EvenReady:
        sta WSYNC
        inx

        lda WorldGraphics,x
        and currentP1Mask
        sta GRP1
        lda currentP1Color
        sta COLUP1
        lda TerrainLeftPF1,x
        sta PF1
        lda ServiceCode,x
        beq Stage3OrdinaryOdd
        cmp #4
        bcs Stage3ServiceHigh
        cmp #2
        bcc Stage3JumpDishA
        beq Stage3JumpCollect0
        jmp Stage3ServiceDishB
Stage3JumpDishA:
        jmp Stage3ServiceDishA
Stage3JumpCollect0:
        jmp Stage3ServiceCollect0

Stage3ServiceHigh:
        beq Stage3JumpCollect1
        cmp #6
        bcc Stage3ServiceDishC
        beq Stage3ServiceCollect2

Stage3ServiceExit:
        nop
        nop
        nop
        sta RESP1
        lda #$C0
        sta PF1
        lda exitDraw
        sta currentP1Mask
        lda exitP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3ServiceDishC:
        nop
        sta RESP1
        sta RESM0
        lda #$80
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorC
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3ServiceCollect2:
        lda #$FF
        sta PF1
        sta RESP1
        sta RESM0
        lda collectDraw2
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3JumpCollect1:
        jmp Stage3ServiceCollect1

Stage3OrdinaryOdd:
        jmp Stage3StarOddControl

; Stage 3's authored X positions differ from Stage 1.  These handlers retain
; the identical state and WSYNC structure while moving only the RESP1 strobe.
Stage3ServiceDishA:
        nop
        sta RESP1
        sta RESM0
        lda #$E0
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorA
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3ServiceCollect0:
        lda #$FF
        sta PF1
        nop
        nop
        sta RESP1
        lda collectDraw0
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3ServiceDishB:
        lda #$80
        sta PF1
        nop
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorB
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3ServiceCollect1:
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$E0
        sta PF1
        lda collectDraw1
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage3OddNext

Stage3OddNext:
        inx
        cpx #ROOM_LINES
        beq Stage3OddDone
        jmp Stage3RoomKernel
Stage3OddDone:
        jmp Stage3RoomDone

Stage3RoomDone:
        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM1
        sta ENABL
        ldx #30
Stage3OverscanLoop:
        sta WSYNC
        dex
        bne Stage3OverscanLoop
        jmp Stage3ReturnGate

        ORG $5587
        RORG $F587
Stage3SuitUp:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage3SuitUpRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage3SuitRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage3SuitDownRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage3SuitDown:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

Stage3VisorEnable:
        byte 0,0,0,0,0,0,0

        ORG $5600
        RORG $F600
Stage3WorldGraphics:
        ds 9,0
        byte %00010000
        ds 1,0
        byte %00011000
        ds 1,0
        byte %01111100
        ds 1,0
        byte %11111110
        ds 1,0
        byte %01111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00010000
        ds 7,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 15,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 13,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 7,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 3,0
        byte %00111100
        ds 1,0
        byte %01111110
        ds 1,0
        byte %11000011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11000011
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00000000

        ORG $5700
        RORG $F700
Stage3ServiceCode:
        ds 23,0
        byte 1
        ds 21,0
        byte 2
        ds 19,0
        byte 3
        ds 27,0
        byte 4
        ds 21,0
        byte 5
        ds 23,0
        byte 6
        ds 19,0
        byte 7
        ds 16,0

        ORG $5800
        RORG $F800
Stage3TerrainColor:
        ; Lavender/indigo variation three, with a darker hourglass center.
        byte $8E,$8C,$8A,$88,$86,$88,$8A,$8C
        ds 8,$72
        ds 8,$74
        ds 8,$76
        ds 8,$78
        ds 8,$7A
        ds 8,$7C
        ds 8,$7E
        ds 8,$7C
        ds 8,$7A
        ds 8,$78
        ds 8,$76
        ds 8,$74
        ds 8,$72
        ds 8,$82
        ds 8,$84
        ds 8,$86
        ds 8,$88
        ds 8,$8A
        ds 8,$88
        ds 8,$86
        ds 8,$84
        ds 8,$82

        ORG $5900
        RORG $F900
Stage3TerrainLeftPF1:
        ds 8,$FF
        ds 8,$80
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$F8
        ds 8,$E0
        ds 8,$C0
        ds 8,$00
        ds 8,$C0
        ds 8,$F8
        ds 8,$FE
        ds 8,$F0
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$F8
        ds 8,$E0
        ds 8,$C0
        ds 8,$FF

        ORG $5A00
        RORG $FA00
Stage3TerrainRightPF1:
        ds 8,$FF
        ds 8,$80
        ds 8,$E0
        ds 8,$F8
        ds 8,$FE
        ds 8,$FF
        ds 8,$F8
        ds 8,$C0
        ds 8,$80
        ds 8,$C0
        ds 8,$F0
        ds 8,$E0
        ds 8,$80
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$FF
        ds 8,$F8
        ds 8,$C0
        ds 8,$80
        ds 8,$FF

        ORG $5B00
        RORG $FB00
Stage3TerrainPF2:
        ds 8,$FF
        ds 160,$00
        ds 8,$FF

        ORG $5BC3
        RORG $FBC3
Stage3EntryLanding:
        jmp Stage3RoomStart

        ORG $5BC8
        RORG $FBC8
Stage3ReturnGate:
        lda $FFFB

        ORG $5C00
        RORG $FC00
Stage3StarEnable:
        IFCONST STARFIELD_LAB
        ds 16,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 21,0
        byte $02
        ds 13,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 9,0
        byte $02
        ds 15,0
        byte $02
        ds 17,0
        byte $02
        ds 7,0
        ELSE
        ds 176,0
        ENDIF

        ORG $5D00
        RORG $FD00
Stage3StarControl:
        IFCONST STARFIELD_LAB
        ds 15,0
        byte $10,0,$80
        ds 13,0
        byte $11,0,$80
        ds 17,0
        byte $12,0,$80
        ds 19,0
        byte $13,0,$80
        ds 11,0
        byte $11,0,$80
        ds 13,0
        byte $10,0,$80
        ds 17,0
        byte $13,0,$80
        ds 7,0
        byte $12,0,$80
        ds 13,0
        byte $10,0,$80
        ds 15,0
        byte $12,0,$80
        ds 6,0
        ELSE
        ds 176,0
        ENDIF
Stage3StarFadeColors:
        byte $02,$02,$02,$00
Stage3StarOddControl:
        lda TerrainRightPF1,x
        sta PF1
        lda Stage3StarControl,x
        beq .sync
        bmi .restore
        eor bestBeacon
        and #3
        tay
        lda Stage3StarFadeColors,y
        sta visorEnable
        sta ENAM0
        jmp .sync
.restore:
        lda #0
        sta visorEnable
        sta ENAM0
.sync:
        sta WSYNC
        jmp Stage3OddNext

        ORG $5FFA
        RORG $FFFA
        word $F000,$F000,$F000

; ---------------------------------------------------------------------------
; BANK 7 — fixed reset, frame, renderer, room and astronaut art.
; Its virtual addresses are unchanged from the approved F8 display bank.
; ---------------------------------------------------------------------------

        SEG BANK6
        ORG $6000
        RORG $F000
Bank6Boot:
        lda $FFFB
        jmp $F006

; ---------------------------------------------------------------------------
; STAGE 2 ROOM BANK
;
; Bank 6 owns a complete, scanline-stable room kernel and its own terrain
; pages.  No bank switch occurs while the beam is drawing the room.  The
; astronaut art is repeated at the same virtual addresses used by Bank 7, so
; SelectPose can prepare one pointer format for both stages.
; ---------------------------------------------------------------------------
        ORG $6100
        RORG $F100
Stage2RoomStart:
        lda TerrainColor
        sta COLUPF
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        ldx #0
        sta WSYNC
        lda #$F0
        sta PF0

Stage2RoomKernel:
        lda TerrainColor,x
        sta COLUPF
        lda TerrainLeftPF1,x
        sta PF1
        lda TerrainPF2,x
        sta PF2
        lda TerrainRightPF1,x
        sta PF1

        txa
        sec
        sbc renderTomY
        cmp #ASTRONAUT_H
        bcc Stage2DrawTom
        lda StarEnable,x
        and visorEnable
        sta ENAM0
        lda #0
        sta GRP0
        beq Stage2StarEvenReady
Stage2DrawTom:
        lsr
        tay
        lda (suitPtr),y
        sta GRP0
        lda #0
        sta ENAM0
        beq Stage2EvenReady
Stage2StarEvenReady:
        sta ENAM0
Stage2EvenReady:
        sta WSYNC
        inx

        lda WorldGraphics,x
        and currentP1Mask
        sta GRP1
        lda currentP1Color
        sta COLUP1
        lda TerrainLeftPF1,x
        sta PF1
        lda ServiceCode,x
        beq Stage2OrdinaryOdd
        cmp #4
        bcs Stage2ServiceHigh
        cmp #2
        bcc Stage2JumpDishA
        beq Stage2JumpCollect0
        jmp Stage2ServiceDishB
Stage2JumpDishA:
        jmp Stage2ServiceDishA
Stage2JumpCollect0:
        jmp Stage2ServiceCollect0

Stage2ServiceHigh:
        beq Stage2JumpCollect1
        cmp #6
        bcc Stage2ServiceDishC
        beq Stage2ServiceCollect2

Stage2ServiceExit:
        nop
        nop
        sta RESP1
        lda #$F0
        sta PF1
        lda exitDraw
        sta currentP1Mask
        lda exitP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2ServiceDishC:
        sta RESP1
        sta RESM0
        lda #$80
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorC
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2ServiceCollect2:
        lda #$FF
        sta PF1
        nop
        sta RESP1
        sta RESM0
        lda collectDraw2
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2JumpCollect1:
        jmp Stage2ServiceCollect1

Stage2OrdinaryOdd:
        jmp Stage2StarOddControl

; Stage 2's authored X positions differ from Stage 1.  These handlers retain
; the identical state and WSYNC structure while moving only the RESP1 strobe.
Stage2ServiceDishA:
        sta RESP1
        sta RESM0
        lda #$FC
        sta PF1
        lda #$FF
        sta currentP1Mask
        lda dishColorA
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2ServiceCollect0:
        lda #$80
        sta PF1
        nop
        nop
        nop
        sta RESP1
        lda collectDraw0
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2ServiceDishB:
        lda #$F8
        sta PF1
        nop
        nop
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorB
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2ServiceCollect1:
        nop
        sta RESP1
        sta RESM0
        lda #$E0
        sta PF1
        lda collectDraw1
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp Stage2OddNext

Stage2OddNext:
        inx
        cpx #ROOM_LINES
        beq Stage2OddDone
        jmp Stage2RoomKernel
Stage2OddDone:
        jmp Stage2RoomDone

Stage2RoomDone:
        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM1
        sta ENABL
        ldx #30
Stage2OverscanLoop:
        sta WSYNC
        dex
        bne Stage2OverscanLoop
        jmp Stage2ReturnGate

        ORG $6587
        RORG $F587
Stage2SuitUp:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage2SuitUpRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage2SuitRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage2SuitDownRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
Stage2SuitDown:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

Stage2VisorEnable:
        byte 0,0,0,0,0,0,0

        ORG $6600
        RORG $F600
Stage2WorldGraphics:
        ds 9,0
        byte %00010000
        ds 1,0
        byte %00011000
        ds 1,0
        byte %01111100
        ds 1,0
        byte %11111110
        ds 1,0
        byte %01111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00010000
        ds 7,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 15,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 13,0
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 7,0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 3,0
        byte %00111100
        ds 1,0
        byte %01111110
        ds 1,0
        byte %11000011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11000011
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00000000

        ORG $6700
        RORG $F700
Stage2ServiceCode:
        ds 23,0
        byte 1
        ds 21,0
        byte 2
        ds 19,0
        byte 3
        ds 27,0
        byte 4
        ds 21,0
        byte 5
        ds 23,0
        byte 6
        ds 19,0
        byte 7
        ds 16,0

        ORG $6800
        RORG $F800
Stage2TerrainColor:
        ; Blue-violet variation two: related to Stage 1, never identical.
        byte $7E,$7C,$7A,$78,$76,$78,$7A,$7C
        ds 8,$62
        ds 8,$64
        ds 8,$66
        ds 8,$68
        ds 8,$6A
        ds 8,$6C
        ds 8,$6E
        ds 8,$6C
        ds 8,$6A
        ds 8,$68
        ds 8,$66
        ds 8,$64
        ds 8,$62
        ds 8,$72
        ds 8,$74
        ds 8,$76
        ds 8,$78
        ds 8,$7A
        ds 8,$78
        ds 8,$76
        ds 8,$74
        ds 8,$72

        ORG $6900
        RORG $F900
Stage2TerrainLeftPF1:
        ds 8,$FF
        ds 8,$00
        ds 8,$80
        ds 8,$F0
        ds 8,$FE
        ds 8,$FF
        ds 8,$F8
        ds 8,$C0
        ds 8,$00
        ds 8,$80
        ds 8,$F8
        ds 8,$FF
        ds 8,$FC
        ds 8,$E0
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$F8
        ds 8,$FE
        ds 8,$FF
        ds 8,$FC
        ds 8,$FF

        ORG $6A00
        RORG $FA00
Stage2TerrainRightPF1:
        ds 8,$FF
        ds 8,$FF
        ds 8,$FC
        ds 8,$F0
        ds 8,$C0
        ds 8,$80
        ds 8,$00
        ds 8,$C0
        ds 8,$F8
        ds 8,$FC
        ds 8,$F8
        ds 8,$E0
        ds 8,$80
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$FC
        ds 8,$FF
        ds 8,$FC
        ds 8,$F0
        ds 8,$C0
        ds 8,$FF

        ORG $6B00
        RORG $FB00
Stage2TerrainPF2:
        ds 8,$FF
        ds 160,$00
        ds 8,$FF

        ORG $6BE3
        RORG $FBE3
Stage2EntryLanding:
        jmp Stage2RoomStart

        ORG $6BF0
        RORG $FBF0
Stage2ReturnGate:
        lda $FFFB

        ORG $6C00
        RORG $FC00
Stage2StarEnable:
        IFCONST STARFIELD_LAB
        ds 16,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 21,0
        byte $02
        ds 13,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 9,0
        byte $02
        ds 15,0
        byte $02
        ds 17,0
        byte $02
        ds 7,0
        ELSE
        ds 176,0
        ENDIF

        ORG $6D00
        RORG $FD00
Stage2StarControl:
        IFCONST STARFIELD_LAB
        ds 15,0
        byte $10,0,$80
        ds 13,0
        byte $11,0,$80
        ds 17,0
        byte $12,0,$80
        ds 19,0
        byte $13,0,$80
        ds 11,0
        byte $11,0,$80
        ds 13,0
        byte $10,0,$80
        ds 17,0
        byte $13,0,$80
        ds 7,0
        byte $12,0,$80
        ds 13,0
        byte $10,0,$80
        ds 15,0
        byte $12,0,$80
        ds 6,0
        ELSE
        ds 176,0
        ENDIF
Stage2StarFadeColors:
        byte $02,$02,$02,$00
Stage2StarOddControl:
        lda TerrainRightPF1,x
        sta PF1
        lda Stage2StarControl,x
        beq .sync
        bmi .restore
        eor bestBeacon
        and #3
        tay
        lda Stage2StarFadeColors,y
        sta visorEnable
        sta ENAM0
        jmp .sync
.restore:
        lda #0
        sta visorEnable
        sta ENAM0
.sync:
        sta WSYNC
        jmp Stage2OddNext

        ORG $6FFA
        RORG $FFFA
        word $F000,$F000,$F000

; ---------------------------------------------------------------------------
; BANK 7 — fixed reset, frame, renderer, room and astronaut art.
; Its virtual addresses are unchanged from the approved F8 display bank.
; ---------------------------------------------------------------------------
        SEG BANK7
        ORG $7000
        RORG $F000
Bank7Boot:
        lda $FFFB
        jmp Reset

        ORG $7006
        RORG $F006
Reset:
        sei
        cld
        ldx #$FF
        txs
        lda #0
.clearRAM:
        sta $00,x
        dex
        bne .clearRAM

        lda #SPAWN_X
        sta tomXHi
        sta safeXHi
        lda #SPAWN_Y
        sta tomYHi
        sta safeYHi
        lda #$60
        sta velXLo
        lda #$FF
        sta velYHi
        lda #$A0
        sta velYLo
        lda #NO_BEACON
        sta readyBeacon
        lda #$FF
        sta collectDraw0
        sta collectDraw1
        sta collectDraw2
        sta collectDraw3

        ; P0 alone draws Major Tom. The enclosed center of the helmet remains
        ; black, giving P1 exclusive color ownership for mission objects.
        lda #$00               ; single P0 copy; one-color-clock Missile 0
        sta NUSIZ0
        lda #$20
        sta NUSIZ1
        lda #1
        sta VDELP0
        lda #0
        sta VDELP1
        lda #SUIT_COLOR
        sta COLUP0
        lda #SIGNAL_COLOR
        sta COLUP1
        lda #$01                ; reflected order; halves are rewritten apart
        sta CTRLPF
        lda #0
        sta COLUBK
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta ENABL

        ; Static HUD outlines are prepared once, outside all frame timing.
        jsr InitHudBuffers
        jmp $FFA0              ; power-on presentation begins in credits Bank 2

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

        lda SWCHB
        lsr
        bcs .noReset
        jmp Reset
.noReset:
        jsr CallPhysics
        lda stageSetupPending
        bpl .presentationReady
        lda #0
        sta stageSetupPending
        jsr InitHudBuffers
.presentationReady:
        jsr SelectPose

        ; Objects now have distinct animation roles. Collectibles shimmer at
        ; the familiar four-frame cadence by changing luminance. Satellite
        ; silhouettes never flip; only the dish in capture range breathes at
        ; a much slower sixteen-frame cadence.
        lda #0
        sta REFP1
        lda #REQUIRED_DIM_COLOR
        sta requiredP1Color
        lda frameCounter
        and #4
        beq .requiredColorReady
        lda #REQUIRED_COLOR
        sta requiredP1Color
.requiredColorReady:
        ; Optional salvage uses a separate, slower sixteen-frame cycle, offset
        ; from the required-object shimmer so it reads as a special pickup.
        lda #OPTIONAL_COLOR
        sta optionalP1Color
        lda frameCounter
        and #8
        beq .collectibleColorsReady
        lda #OPTIONAL_DIM_COLOR
        sta optionalP1Color
.collectibleColorsReady:
        lda #DISH_DIM_COLOR
        sta dishColorA
        sta dishColorB
        sta dishColorC
        lda readyBeacon
        cmp #NO_BEACON
        beq .dishColorsReady
        tax
        lda frameCounter
        and #$10
        beq .dishColorsReady
        lda #SIGNAL_COLOR
        sta dishColorA,x
.dishColorsReady:
        ; The extraction gate is a separate final P1 object. It is completely
        ; absent until all three required objects are secured, then breathes
        ; through a four-step blue luminance ramp. Completion turns it white.
        lda #0
        sta exitDraw
        lda objectiveDone
        beq .exitMaskReady
        lda #$FF
        sta exitDraw
.exitMaskReady:
        lda frameCounter
        lsr
        lsr
        lsr
        and #3
        tax
        lda ExitColorTable,x
        sta exitP1Color
        lda stageComplete
        beq .exitColorReady
        lda #EXIT_DONE_COLOR
        sta exitP1Color
.exitColorReady:
        lda collectDraw3
        sta currentP1Mask
        lda optionalP1Color
        sta currentP1Color

        ; P0 uses one-line vertical delay. Odd room lines latch the row prepared
        ; on the preceding even line, eliminating center-screen tearing.
        lda tomYHi
        sec
        sbc #1
        sta renderTomY

        ; A normal frame performs only a mask comparison. When collection
        ; changes, at most five visible icon bytes and one pointer are updated.
        jsr UpdateHudState
        jsr PrepareTomFineMotion

        ; Position P0/P1 for the approved interleaved 48-pixel HUD. After the
        ; two information bands, the final four HUD/setup lines restore their
        ; unrelated gameplay positions before the 176-line room begins.
        lda #0
        sta REFP0
        sta REFP1
        sta WSYNC
        lda #3
        sta NUSIZ0
        sta NUSIZ1
        lda #HUD_TEXT_COLOR
        bit temp
        sta COLUP0
        sta COLUP1
        sta HMCLR
        lda #$80
        sta HMP0
        lda #$90
        sta HMP1
        nop
        sta RESP0
        sta RESP1
        sta WSYNC
        sta HMOVE

.waitVBlank:
        lda INTIM
        bne .waitVBlank
        sta WSYNC
        sta HMCLR

        lda #0
        sta VBLANK
        sta COLUBK
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta ENABL

        ; Keep RoomKernel in the exact ROM-page phase approved in 0.5A-R5.
        ; The first HUD WSYNC absorbs this entry jump; the skipped bytes are
        ; layout padding only and never execute.
        jmp HudEntry
HudEntry:

        ; Keep the timing-critical room kernel in its approved ROM-page phase.
        ; The complete 16-line status renderer lives after RoomDone.
        jsr DrawHud

        ; Preserve the approved Stage 1 kernel's exact ROM-page phase. Later
        ; room selection continues in a non-visible dispatch routine.
        lda currentStage
        beq .drawStage1Room
        jmp DispatchOtherRooms
.drawStage1Room:

        ; ---------------------------------------------------------------
        ; One two-line kernel renders all 176 room lines. The room's first
        ; full-width violet terrain band now doubles as the material divider
        ; beneath the black status deck—depth without an extra scanline.
        ; ---------------------------------------------------------------
        lda TerrainColor
        sta COLUPF
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        ldx #0
        ; The sixteenth HUD/setup line remains completely black.
        sta WSYNC
        lda #$F0
        sta PF0

RoomKernel:
        lda TerrainColor,x
        sta COLUPF
        lda TerrainLeftPF1,x
        sta PF1
        lda TerrainPF2,x
        sta PF2
        lda TerrainRightPF1,x
        sta PF1

        txa
        sec
        sbc renderTomY
        cmp #ASTRONAUT_H
        bcc RoomDrawTom
        lda StarEnable,x
        and visorEnable
        sta ENAM0
        lda #0
        sta GRP0
        beq RoomStarEvenReady
RoomDrawTom:
        lsr
        tay
        lda (suitPtr),y
        sta GRP0
        lda #0
        sta ENAM0
        beq RoomEvenReady
RoomStarEvenReady:
        sta ENAM0
RoomEvenReady:
        sta WSYNC
        inx

        ; With Missile 1 retired, the real P1 row can be written during
        ; horizontal blank. This one early GRP1 write both transfers Major
        ; Tom's delayed P0 row before visibility and preserves every mission
        ; object's pixels. The path reaches PF1 at its approved cycle 25.
        lda WorldGraphics,x
        and currentP1Mask
        sta GRP1
        lda currentP1Color
        sta COLUP1
        lda TerrainLeftPF1,x
        sta PF1

        ; A zero is an ordinary odd line. Codes 1..6 identify the blank
        ; service lines between vertically adjacent P1 objects.
        lda ServiceCode,x
        beq RoomOrdinaryOdd
        cmp #4
        bcs RoomServiceHigh
RoomServiceLow:
        cmp #2
        bcc RoomJumpDishA
        beq RoomJumpCollect0
        jmp ServiceDishB
RoomJumpDishA:
        jmp ServiceDishA
RoomJumpCollect0:
        jmp ServiceCollect0

RoomServiceHigh:
        beq RoomJumpCollect1
        cmp #6
        bcc ServiceDishC
        beq ServiceCollect2

ServiceExit:
        ; Code 7 is deliberately handled inline. Avoiding another JMP keeps
        ; the final repositioning line inside one NTSC scanline.
        sta RESP1
        lda #$C0               ; fixed right PF1 on room line 159
        sta PF1
        lda exitDraw
        sta currentP1Mask
        lda exitP1Color
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

ServiceDishC:
        lda #$F0               ; fixed right PF1 on room line 115
        sta PF1
        nop
        sta RESP1
        sta RESM0
        jmp Stage1ServiceDishCFinish

; Keep the timing-sensitive entry on the branch's original ROM page. The
; remainder may live in the star laboratory's spare page without moving P1.
ServiceCollect2:
        sta RESP1
        sta RESM0
        ; Room line 139 is authored with a zero right PF1. Loading that known
        ; value immediately saves the two cycles needed by the eighth object.
        lda #0
        sta PF1
        lda collectDraw2
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

RoomJumpCollect1:
        jmp ServiceCollect1

RoomOrdinaryOdd:
        ; PF2 was written on the preceding even line. Stage data is authored
        ; in two-line pairs, so retaining it here buys the exact cycles needed
        ; for stable color ownership without altering any visible pixel.
        jmp StarOddControl

; RESP1 timing gives every service band a different authored horizontal
; coordinate.  Crucially, every handler restores the right-hand PF1 value no
; later than cycle 59.  The old 0.4 handlers performed this write after their
; state work, producing the photographed black cuts through the terrain.
ServiceDishA:
        lda #0                 ; fixed right PF1 on room line 23
        sta PF1
        nop
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorA
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

ServiceCollect0:
        lda #$80               ; fixed right PF1 on room line 45
        sta PF1
        nop
        sta RESP1
        lda collectDraw0
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

ServiceDishB:
        lda #$C0               ; fixed right PF1 on room line 65
        sta PF1
        bit temp
        sta RESP1
        sta RESM0
        lda #$FF
        sta currentP1Mask
        lda dishColorB
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

ServiceCollect1:
        sta RESP1
        sta RESM0
        lda #0                 ; fixed right PF1 on room line 93
        sta PF1
        lda collectDraw1
        sta currentP1Mask
        lda requiredP1Color
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

; Every odd scanline—ordinary or service—takes this identical twelve-cycle
; route into the next even scanline.  That removes the former two-cycle phase
; change that distorted Major Tom whenever he crossed a service band.
RoomOddNext:
        inx
        cpx #ROOM_LINES
        beq RoomOddDone
        jmp RoomKernel
RoomOddDone:
        jmp RoomDone

RoomDone:
        ; Overscan: exactly thirty lines.
        lda #2
        sta VBLANK
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM1
        sta ENABL
        ldx #30
Stage1OverscanLoop:
        sta WSYNC
        dex
        bne Stage1OverscanLoop
        jmp Frame

; Production HUD: five compact icon lines followed immediately by the
; approved seven-line "1 0000" numeric face. Its final four lines restore
; P0 and P1 to their gameplay positions and preserve the 16-line allocation.
DrawHud:
        lda #HUD_ICON_COLOR
        sta COLUP0
        sta COLUP1
        lda #1
        sta VDELP0
        sta VDELP1
        lda #5
        sta temp
.iconRow:
        ldy temp
        lda hudIcon0,y
        sta WSYNC
        sta GRP0
        lda hudIcon1,y
        sta GRP1
        lda hudIcon2,y
        sta GRP0
        lda hudIcon3,y
        sta temp2
        lda hudIcon4,y
        tax
        lda hudIcon5,y
        ldy temp2
        nop
        cpx $80
        sty GRP1
        stx GRP0
        sta GRP1
        sta GRP0
        dec temp
        bne .iconRow

        lda #HUD_TEXT_COLOR
        sta COLUP0
        sta COLUP1
        lda #7
        sta temp
.numericRow:
        ldy temp
        lda hudStageGlyph,y
        sta WSYNC
        sta GRP0
        lda HudSpacer,y
        sta GRP1
        lda HudZeroA,y
        sta GRP0
        lda hudHundredsGlyph,y
        sta temp2
        lda (hudScorePtr),y
        tax
        lda HudZeroD,y
        ldy temp2
        cmp HudBlank,x
        sty GRP1
        stx GRP0
        sta GRP1
        sta GRP0
        dec temp
        bne .numericRow

        lda #0
        sta GRP0
        sta GRP1
        sta VDELP0
        sta VDELP1
        sta PF0
        sta PF1
        sta PF2

        ; The HUD is always unreflected. Restore Major Tom's gameplay-facing
        ; direction before his P0 position is applied to the room.
        ; All production horizontal speeds use $00/$01 when moving right and
        ; $FE/$FF when moving left, so bit 3 is a branchless REFP0 value.
        ; Both directions now consume exactly the same cycles before WSYNC.
        lda velXHi
        and #8
        sta REFP0
        lda #0
        sta REFP1

        lda #$10
        sta NUSIZ0
        lda #$20
        sta NUSIZ1
        lda #1
        sta VDELP0
        lda #0
        sta VDELP1
        lda #SUIT_COLOR
        sta COLUP0
        lda currentP1Color
        sta COLUP1
        jsr PositionGameplayObjects
        rts

; Reset-time construction is deliberately outside the 262-line frame. The two
; unused display cells remain zero for the life of the stage.
InitHudBuffers:
        ldx #5
.initOutlines:
        lda HudRequiredOutline,x
        sta hudIcon0,x
        sta hudIcon1,x
        sta hudIcon2,x
        lda HudOptionalOutline,x
        sta hudIcon3,x
        lda HudBlank,x
        sta hudIcon4,x
        sta hudIcon5,x
        dex
        bpl .initOutlines
        lda #0
        sta stageSetupPending
        jsr UpdateHudPointers
        rts

UpdateHudPointers:
        ldx currentStage
        lda HudStageDigitLow,x
        sta hudStagePtr
        lda #>HudDigit0
        sta hudStagePtr+1

        lda #<HudDigit0
        sta hudHundredsPtr
        lda #>HudDigit0
        sta hudHundredsPtr+1

        lda scoreTens
        cmp #10
        bcc .scoreBelowHundred
        lda #<HudDigit1
        sta hudHundredsPtr
        lda #0
.scoreBelowHundred:
        tax
        lda HudScoreDigitLow,x
        sta hudScorePtr
        lda #>HudDigit0
        sta hudScorePtr+1
        ldy #7
.copyChangingGlyphs:
        lda (hudStagePtr),y
        sta hudStageGlyph,y
        lda (hudHundredsPtr),y
        sta hudHundredsGlyph,y
        dey
        bpl .copyChangingGlyphs
        rts

; Ordinary frames take only the compare/return path. A newly collected object
; copies five displayed rows once; score changes by selecting an existing ROM
; digit rather than rebuilding another eight-byte graphic every frame.
UpdateHudState:
        lda collectMask
        cmp stageSetupPending
        bne .stateChanged
        rts
.stateChanged:
        eor stageSetupPending
        sta temp2
        lda collectMask
        sta stageSetupPending

        lda temp2
        and #1
        beq .checkRequired2
        ldx #5
.fillRequired1:
        lda HudRequiredFilled,x
        sta hudIcon0,x
        dex
        bne .fillRequired1
.checkRequired2:
        lda temp2
        and #2
        beq .checkRequired3
        ldx #5
.fillRequired2:
        lda HudRequiredFilled,x
        sta hudIcon1,x
        dex
        bne .fillRequired2
.checkRequired3:
        lda temp2
        and #4
        beq HudUpdateCheckOptional
        ldx #5
.fillRequired3:
        lda HudRequiredFilled,x
        sta hudIcon2,x
        dex
        bne .fillRequired3
HudUpdateCheckOptional:
        lda temp2
        and #8
        beq .chooseScore
        ldx #5
.fillOptional:
        lda HudOptionalFilled,x
        sta hudIcon3,x
        dex
        bne .fillOptional

.chooseScore:
        jsr UpdateHudPointers
        rts

; Choose one of five authored poses. Horizontal reflection supplies the three
; corresponding left-facing directions for eight readable travel directions.
SelectPose:
        lda #0
        sta REFP0
        lda velXHi
        bpl .poseFacingRight
        lda #8
        sta REFP0
.poseFacingRight:
        lda velYHi
        bmi .poseMovingUp
        bne .poseDown
        lda velYLo
        cmp #$70
        bcs .poseDownRight
        jmp .poseRight
.poseMovingUp:
        lda velXHi
        beq .poseUp
        lda velXLo
        cmp #$60
        bcs .poseUp
        jmp .poseUpRight
.poseUp:
        lda #<SuitUp
        sta suitPtr
        lda #>SuitUp
        sta suitPtr+1
        rts
.poseUpRight:
        lda #<SuitUpRight
        sta suitPtr
        lda #>SuitUpRight
        sta suitPtr+1
        rts
.poseRight:
        lda #<SuitRight
        sta suitPtr
        lda #>SuitRight
        sta suitPtr+1
        rts
.poseDownRight:
        lda #<SuitDownRight
        sta suitPtr
        lda #>SuitDownRight
        sta suitPtr+1
        rts
.poseDown:
        lda #<SuitDown
        sta suitPtr
        lda #>SuitDown
        sta suitPtr+1
        rts

; A=visible X, X=0 P0, 1 P1, 2 M0, 3 M1, 4 Ball.
PositionObject:
        cpx #2
        adc #0
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

; Calculate only the fine-motion nibble during timer-controlled VBLANK. The
; visible routine below never performs this variable-length work after RESP0.
PrepareTomFineMotion:
        lda tomXHi
        clc
        ; With this exact instruction schedule, a bias of 49 makes the RESP0
        ; coarse position plus HMOVE fine motion equal tomXHi at every X.
        ; Major Tom's rendered eight-pixel rectangle therefore matches the
        ; software collision rectangle at both walls and every terrain edge.
        adc #POSITION_BIAS
        sec
.fineDivide15:
        sbc #15
        bcs .fineDivide15
        eor #$FF
        adc #$F9
        asl
        asl
        asl
        asl
        sta tomFineMotion
        rts

; Restore P0 and the upper P1 object in exactly three synchronized HUD/setup
; lines. RIGHT_LIMIT guarantees P0's longest divide path reaches the trailing
; WSYNC by cycle 75; P1 uses its fixed precomputed coarse/fine constants.
PositionGameplayObjects:
        lda tomXHi
        clc
        adc #POSITION_BIAS
        sec
        sta WSYNC
.gameP0Divide15:
        sbc #15
        bcs .gameP0Divide15
        sta RESP0
        lda tomFineMotion
        sta HMP0
        ; End P0's longest right-edge path immediately.  No instruction may
        ; be inserted before this WSYNC: at RIGHT_LIMIT it arrives on cycle
        ; 73, leaving only the three-cycle WSYNC store inside the scanline.
        sta WSYNC

        ; Each stage has an independently authored upper optional object. The
        ; branch cost is included in both fixed delays, so RESP1 still lands
        ; on an exact authored color clock without a variable divide.
        lda currentStage
        bne .gameP1Stage2
        ldx #10
.gameP1Divide15:
        dex
        bne .gameP1Divide15
        bit temp
        sta RESP1
        lda #$90
        sta HMP1
        sta WSYNC
        sta HMOVE
        rts

.gameP1Stage2:
        ldx #4
.gameP1Stage2Delay:
        dex
        bne .gameP1Stage2Delay
        nop
        sta RESP1
        lda #$30
        sta HMP1
        sta WSYNC
        sta HMOVE
        rts

; This runs before a later room's first synchronizing WSYNC, so its branching
; cannot alter visible scanline timing. Stage 1 never enters this routine.
DispatchOtherRooms:
        lda currentStage
        cmp #1
        beq .dispatchStage2
        cmp #2
        beq .dispatchStage3
        cmp #3
        beq .dispatchStage4
        jmp Stage5RoomGate
.dispatchStage4:
        jmp Stage4RoomGate
.dispatchStage3:
        jmp Stage3RoomGate
.dispatchStage2:
        jmp Stage2RoomGate

; ---------------------------------------------------------------------------
; Major Tom production silhouette. Seven logical rows are doubled to fourteen
; physical lines. The visor row contains two white helmet-edge pixels around
; a black/transparent window, leaving Player 1 entirely to mission objects.
; All pose labels intentionally share this neutral art in Thursday's Child.
; ---------------------------------------------------------------------------
        ALIGN 256
; HUD cells share one page so both the visible absolute-indexed loads and the
; VBLANK score-pointer copy retain predictable timing.
HudBlank:
HudSpacer:
        byte $00,$00,$00,$00,$00,$00,$00,$00
HudStageOne:
HudDigit1:
        byte $00,$3C,$18,$18,$18,$18,$38,$18
HudZeroA:
HudZeroB:
HudZeroD:
HudDigit0:
        byte $00,$3C,$66,$66,$66,$66,$66,$3C
HudDigit2:
        byte $00,$7E,$40,$7E,$02,$42,$3C,$00
HudDigit3:
        byte $00,$7E,$02,$1E,$02,$42,$3C,$00
HudDigit4:
        byte $00,$04,$04,$7E,$44,$24,$14,$0C
HudDigit5:
        byte $00,$7E,$02,$3E,$40,$40,$7E,$00
HudDigit6:
        byte $00,$3C,$66,$7C,$60,$30,$1C,$00
HudDigit7:
        byte $00,$10,$10,$08,$04,$42,$7E,$00
HudDigit8:
        byte $00,$3C,$66,$3C,$66,$66,$3C,$00
HudDigit9:
        byte $00,$38,$0C,$3E,$66,$66,$3C,$00
HudRequiredOutline:
        byte $00,$18,$24,$42,$24,$18,$00,$00
HudRequiredFilled:
        byte $00,$18,$3C,$7E,$3C,$18,$00,$00
HudOptionalOutline:
        byte $00,$24,$18,$7E,$18,$24,$00,$00
HudOptionalFilled:
        byte $00,$24,$3C,$7E,$3C,$24,$00,$00

HudScoreDigitLow:
        byte <HudDigit0,<HudDigit1,<HudDigit2,<HudDigit3,<HudDigit4
        byte <HudDigit5,<HudDigit6,<HudDigit7,<HudDigit8,<HudDigit9
HudStageDigitLow:
        byte <HudDigit1,<HudDigit2,<HudDigit3,<HudDigit4,<HudDigit5

SuitUp:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
SuitUpRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
SuitRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
SuitDownRight:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110
SuitDown:
        byte %00111100,%01111110,%10000001,%01111110
        byte %11111111,%01111110,%01100110

VisorEnable:
        byte 0,0,0,0,0,0,0

; P1 is rewritten on odd scanlines. The optional cross occupies the first
; band; three required objects alternate with the three side-facing dishes.
; A final full-height gate occupies the lowest band after objective activation.
        ALIGN 256
WorldGraphics:
        ds 9,0
        byte %00010000
        ds 1,0
        byte %00011000
        ds 1,0
        byte %01111100
        ds 1,0
        byte %11111110
        ds 1,0
        byte %01111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00010000
        ds 7,0

        ; Satellite A
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0

        ; Required object 0
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 15,0

        ; Satellite B
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 5,0

        ; Required object 1
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 13,0

        ; Satellite C
        byte %00111100
        ds 1,0
        byte %01100000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %11000000
        ds 1,0
        byte %01100000
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00011000
        ds 1,0
        byte %00111100
        ds 7,0

        ; Required object 2
        byte %00111000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %11111000
        ds 1,0
        byte %11110000
        ds 1,0
        byte %01111000
        ds 1,0
        byte %00111000
        ds 3,0

        ; Extraction gate: eight logical rows fill the complete fifteen-line
        ; bottom band. The open center reads as a doorway rather than a pickup.
        byte %00111100
        ds 1,0
        byte %01111110
        ds 1,0
        byte %11000011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11011011
        ds 1,0
        byte %11000011
        ds 1,0
        byte %00111100
        ds 1,0
        byte %00000000

; Nonzero entries mark the odd service lines that reposition P1 for the next
; vertically scheduled object. Values select the six calibrated handlers.
        ALIGN 256
ServiceCode:
        ds 23,0
        byte 1
        ds 21,0
        byte 2
        ds 19,0
        byte 3
        ds 27,0
        byte 4
        ds 21,0
        byte 5
        ds 23,0
        byte 6
        ds 19,0
        byte 7
        ds 16,0

; The extraction ramp is its own stage-palette role. This yellow-amber hue is
; deliberately distinct from violet terrain, orange-gold required objects,
; green salvage, and blue satellite signaling.
ExitColorTable:
        byte EXIT_GLOW_DIM,EXIT_GLOW_LOW,EXIT_GLOW_HIGH,EXIT_GLOW_LOW
; ---------------------------------------------------------------------------
; Stationary stage data. Every run is exactly eight scanlines. The color ramp
; is light-dark-light inside one gold family; only terrain is colored.
;
; BLACKSTAR 0.8R rewrites PF1 between the screen halves. The left and right
; formations below are deliberately unrelated. PF2 is shared only for the
; solid ceiling and floor, preserving a large central maneuvering chamber.
; ---------------------------------------------------------------------------
        ALIGN 256
TerrainColor:
        ; The solid eight-line ceiling is also the HUD divider. Its stationary
        ; light-dark-light ramp gives that material real depth at no CPU cost.
        byte $AE,$AC,$AA,$A8,$A6,$A8,$AA,$AC
        ds 8,$6C
        ds 8,$6A
        ds 8,$68
        ds 8,$66
        ds 8,$64
        ds 8,$62          ; dark amethyst
        ds 8,$72          ; dark indigo turn
        ds 8,$74
        ds 8,$76
        ds 8,$78
        ds 8,$7A
        ds 8,$7C
        ds 8,$7E          ; pale blue-violet crest
        ds 8,$7C
        ds 8,$7A
        ds 8,$78
        ds 8,$76
        ds 8,$74
        ds 8,$72
        ds 8,$64
        ds 8,$66

        ALIGN 256
TerrainLeftPF1:
        ds 8,$FF
        ds 8,$F0          ; broad ceiling shoulder
        ds 8,$E0
        ds 8,$C0
        ds 8,$80          ; tapered stalactite tip
        ds 8,$00
        ds 8,$00
        ds 8,$80          ; upper side shelf
        ds 8,$C0
        ds 8,$80
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$80          ; independent lower-left shelf
        ds 8,$C0
        ds 8,$80
        ds 8,$00
        ds 8,$80          ; tapered stalagmite tip
        ds 8,$C0
        ds 8,$E0
        ds 8,$F0          ; broad floor shoulder
        ds 8,$FF

        ALIGN 256
TerrainRightPF1:
        ds 8,$FF
        ds 8,$80          ; short upper-right shoulder
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$80
        ds 8,$C0
        ds 8,$E0          ; deep upper-right outcrop
        ds 8,$C0
        ds 8,$80
        ds 8,$00
        ds 8,$00
        ds 8,$80
        ds 8,$E0
        ds 8,$F0          ; broad middle-right shelf
        ds 8,$C0
        ds 8,$00
        ds 8,$00
        ds 8,$80
        ds 8,$C0
        ds 8,$E0
        ds 8,$FF

        ALIGN 256
TerrainPF2:
        ds 8,$FF
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$00
        ds 8,$FF

; Room-bank gates occupy matching addresses in Banks 6 and 7. Reading the F4
; hotspot changes the bank; execution then continues at the next byte in the
; newly selected bank, where a conventional JMP provides an explicit landing.
        ORG $7BB0
        RORG $FBB0
Stage4RoomGate:
        lda $FFF8

        ORG $7BBB
        RORG $FBBB
Stage4ReturnLanding:
        jmp Frame

        ORG $7BC0
        RORG $FBC0
Stage3RoomGate:
        lda $FFF9

        ORG $7BCB
        RORG $FBCB
Stage3ReturnLanding:
        jmp Frame

        ORG $7BD0
        RORG $FBD0
Stage5RoomGate:
        lda $FFF7

        ORG $7BDB
        RORG $FBDB
Stage5ReturnLanding:
        jmp Frame

        ORG $7BE0
        RORG $FBE0
Stage2RoomGate:
        lda $FFFA

        ORG $7BF3
        RORG $FBF3
Stage2ReturnLanding:
        jmp Frame

        ORG $7C00
        RORG $FC00
StarEnable:
        IFCONST STARFIELD_LAB
        ds 16,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 21,0
        byte $02
        ds 13,0
        byte $02
        ds 15,0
        byte $02
        ds 19,0
        byte $02
        ds 9,0
        byte $02
        ds 15,0
        byte $02
        ds 17,0
        byte $02
        ds 7,0
        ELSE
        ds 176,0
        ENDIF

        ORG $7D00
        RORG $FD00
StarControl:
        IFCONST STARFIELD_LAB
        ds 15,0
        byte $10,0,$80
        ds 13,0
        byte $11,0,$80
        ds 17,0
        byte $12,0,$80
        ds 19,0
        byte $13,0,$80
        ds 11,0
        byte $11,0,$80
        ds 13,0
        byte $10,0,$80
        ds 17,0
        byte $13,0,$80
        ds 7,0
        byte $12,0,$80
        ds 13,0
        byte $10,0,$80
        ds 15,0
        byte $12,0,$80
        ds 6,0
        ELSE
        ds 176,0
        ENDIF
StarFadeColors:
        byte $02,$02,$02,$00
StarOddControl:
        lda TerrainRightPF1,x
        sta PF1
        lda StarControl,x
        beq .sync
        bmi .restore
        eor bestBeacon
        and #3
        tay
        lda StarFadeColors,y
        sta visorEnable
        sta ENAM0
        jmp .sync
.restore:
        lda #0
        sta visorEnable
        sta ENAM0
.sync:
        sta WSYNC
        jmp RoomOddNext

Stage1ServiceDishCFinish:
        lda #$FF
        sta currentP1Mask
        lda dishColorC
        sta currentP1Color
        sta WSYNC
        jmp RoomOddNext

        ; Restore the fixed gameplay TIA contract after the terminal bank.
        ; Stage data itself is initialized by Bank 0 on the first Frame call.
        ORG $7E00
        RORG $FE00
GameplayResume:
        ; The terminal's third-fire jump to this gameplay entry (see
        ; TerminalToGameplayGate) fires from inside a jsr'd subroutine via a
        ; plain jmp, never executing its matching rts. That orphans the
        ; jsr's return address on the hardware stack. Left uncorrected, once
        ; gameplay's own call depth unwinds back to that stack level, an rts
        ; pops the stale address instead of its real caller, sending
        ; execution into unmapped memory until a stray zero byte reads as
        ; BRK and every bank's identical interrupt vector redirects back
        ; through Reset into credits -- reproducibly, regardless of input
        ; method or emulator. Reset the stack here, the same defensive reset
        ; Reset itself performs, so no stale entry survives into gameplay.
        ldx #$FF
        txs
        lda #0
        sta AUDV0
        sta AUDV1
        sta NUSIZ0
        sta VDELP1
        sta COLUBK
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta ENABL
        sta currentStage
        sta scoreTens
        lda #$20
        sta NUSIZ1
        lda #1
        sta VDELP0
        sta CTRLPF
        lda #SUIT_COLOR
        sta COLUP0
        lda #SIGNAL_COLOR
        sta COLUP1
        lda #$40
        sta stageSetupPending
        jmp Frame

        ; Fixed presentation gates. Each hotspot read changes banks and the
        ; selected bank supplies a JMP at the following virtual address.
        ORG $7FA0
        RORG $FFA0
EnterCreditsGate:
        lda $FFF6

; Fixed bank-call gate. The hotspot switches to bank 0 at $FFD0. Bank 0 runs
; physics at $FFD3, switches back, and execution resumes at this RTS.
        ORG $7FD0
        RORG $FFD0
CallPhysics:
        lda $FFF4
        ds 6,$EA
PhysicsBankReturn:
        rts

        ORG $7FE3
        RORG $FFE3
GameplayEntryLanding:
        jmp GameplayResume

        ORG $7FEB
        RORG $FFEB
PresentationResetLanding:
        jmp Reset

        ORG $7FFA
        RORG $FFFA
        word $F000,$F000,$F000
