hirom

; MSU memory map I/O
MSU_STATUS = $002000
MSU_ID = $002002
MSU_AUDIO_TRACK_LO = $002004
MSU_AUDIO_TRACK_HI = $002005
MSU_AUDIO_VOLUME = $002006
MSU_AUDIO_CONTROL = $002007

; SPC communication ports
SPC_COMM_0 = $2140
SPC_COMM_1 = $2141
SPC_COMM_2 = $2142
SPC_COMM_3 = $2143

; MSU_STATUS possible values
MSU_STATUS_TRACK_MISSING = $8
MSU_STATUS_AUDIO_PLAYING = %00010000
MSU_STATUS_AUDIO_REPEAT  = %00100000
MSU_STATUS_AUDIO_BUSY    = $40
MSU_STATUS_DATA_BUSY     = %10000000

; Constants
FULL_VOLUME = $FF
DUCKED_VOLUME = $30

; =============
; = Variables =
; =============
; Game Variables
musicCommand = $1E00
musicRequested = $1E01
targetVolume = $1E02

; My own variables
currentSong = $1EE0
fadeState = $1EE1
fadeVolume = $1EE2
fadeTarget = $1EE4
fadeStep = $1EE6

; fadeState possibles values
FADE_STATE_IDLE = $00
FADE_STATE_FADEOUT = $01
FADE_STATE_FADEIN = $02

; ==========
; = Macros =
; ==========
macro CheckMSUPresence(labelToJump)
	lda MSU_ID
	cmp #'S'
	bne <labelToJump>
endmacro

; ========================
; = Original code hijack =
; ========================

; NMI hijack
org $00FF10
	jml MSU_UpdateLoop

; Wait for title screen fix
; This chunk of code is copied into RAM
; by the decompression routine, that's why
; it got a db $80 in the middle
org $C335AF
	nop
	db $80
	jsl TitleScreenWaitFix
	nop
	nop

; Relevant calls to $C70004
; Found via hex editor by searching for JSL $C70004

org $C01B73
	jsl MSU_Main
	
; Entering area
org $C01B8B
	jsl MSU_Main
	
; Entering battle
org $C01BCE
	jsl MSU_Main
	
org $C01C2A
	jsl MSU_Main
	
; Exiting battle
org $C01C3A
	jsl MSU_Main
	
org $C01C52
	jsl MSU_Main
	
org $C01CA9
	jsl MSU_Main
	
org $C01CB7
	jsl MSU_Main
	
org $C01CCF
	jsl MSU_Main
	
; Called during attract
org $C03C43
	jsl MSU_Main
	
org $C03C69
	jsl MSU_Main
	
org $C03CB4
	jsl MSU_Main
	
org $C161DF
	jsl MSU_Main
	
org $C20462
	jsl MSU_Main
	
org $C223F9
	jsl MSU_Main
	
org $C22F49
	jsl MSU_Main
	
org $C2CBF3
	jsl MSU_Main
	
org $C2CC09
	jsl MSU_Main
	
org $C309D1
	jsl MSU_Main
	
org $C30BE9
	jsl MSU_Main
	
; Title Screen
org $C31647
	jsl MSU_Main

org $CD03AB
	jsl MSU_Main
	
org $CD0D70
	jsl MSU_Main
	
org $CD0D81
	jsl MSU_Main
	
; ============
; = MSU Code =
; ============
org $C5F370
MSU_Main:
	php
; Backup A and Y in 16bit mode
	rep #$30
	pha
	phx
	phy
	phd
	phb
	
	sep #$20 ; Set all registers to 8 bit mode
	
	%CheckMSUPresence(.CallOriginalRoutine)
	
.MSUFound:
	lda.w musicCommand
	; Play Music
	cmp #$10
	bne +
	jsr MSU_PlayMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	; Resume
	cmp #$11
	bne +
	jsr MSU_ResumeMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	; Interrupt
	cmp #$14
	bne +
	jsr MSU_PauseMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	; Fade
	cmp #$81
	bne +
	jsr MSU_PrepareFade
+
; Call original routine
.CallOriginalRoutine:
	rep #$30
	plb
	pld
	ply
	plx
	pla
	plp
	
	jsl $C70004
	rtl
	
.DoNotCallSPCRoutine
	rep #$30
	plb
	pld
	ply
	plx
	pla
	plp
	rtl

MSU_PlayMusic:
	lda.w musicRequested
	beq .StopMSUMusic
	cmp #$FF
	beq .SongAlreadyPlaying
	cmp currentSong
	beq .SongAlreadyPlaying
	sta MSU_AUDIO_TRACK_LO
	lda #$00
	sta MSU_AUDIO_TRACK_HI

.CheckAudioStatus
	lda MSU_STATUS
	
	and.b #MSU_STATUS_AUDIO_BUSY
	bne .CheckAudioStatus
	
	; Check if track is missing
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne .StopMSUMusic

	; Play the song
	lda.w musicRequested
	jsr TrackNeedLooping
	sta MSU_AUDIO_CONTROL
	
	; Set volume
	lda.b #FULL_VOLUME
	sta.w MSU_AUDIO_VOLUME
	sta.w fadeVolume
	
	; Only store current song if we were able to play the song
	lda.w musicRequested
	sta currentSong
	
	; Set SPC music to silence
	lda #$00
	sta $1E01
	sec
	bra .Exit

.SongAlreadyPlaying
	clc
.Exit
	rts
	
.StopMSUMusic
	lda #$00
	sta MSU_AUDIO_CONTROL
	sta MSU_AUDIO_VOLUME
	sta currentSong
	sec
	bra .Exit
	
MSU_ResumeMusic:
	lda.w musicRequested
	sta currentSong
	lda #$03
	sta MSU_AUDIO_CONTROL
	
	; Play silence after resuming music to
	; reload correct SFX samples
	lda #$10
	sta.w musicCommand
	lda #$00
	sta.w musicRequested
	sec
	rts
	
MSU_PauseMusic:
	lda #$00
	sta MSU_AUDIO_CONTROL
	sta currentSong
	sec
	rts
	
MSU_PrepareFade:
	rep #$20
	lda #$0000
	sep #$20
	; musicRequested = Fade Time
	lda musicRequested
	beq .SetVolumeImmediate
	
	; fadeStep = (targetVolume-fadeVolume)/fadeTime
	lda targetVolume
	sta fadeTarget
	
	rep #$20
	sec
	sbc fadeVolume
	; If carry is set, the result is a positive number
	bcs +
	
	; Reverse sign of the result (which in two-complements)
	; A negative result means a fade-out
	eor	#$FFFF
	inc a
	
	sep #$30
	ldx.b #FADE_STATE_FADEOUT
	stx.w fadeState
	bra .DoDivision
+
	sep #$30
	ldx.b #FADE_STATE_FADEIN
	stx.w fadeState
.DoDivision
	; Do division using SNES division support
	sta $4204 ; low
	stz $4205 ; high byte
	lda musicRequested ; fadeTime
	asl
	asl
	sta $4206
	
	; Wait 16 CPU cycles
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	; Result in 4214 / 4215
	lda $4214
	sta fadeStep
	bra .Exit

.SetVolumeImmediate
	lda targetVolume
	sta fadeVolume
	sta MSU_AUDIO_VOLUME
.Exit:
	rts
	
TrackNeedLooping:
	; 1.01 A Premonition
	cmp #48
	beq .noLooping
	; 1.10 Good Night
	cmp #43
	beq .noLooping
	; 1.14 Huh ?!
	cmp #37
	beq .noLooping
	; 1.16 A Prayer for the Wayfarer
	cmp #36
	beq .noLooping
	; 2.02 Mystery from the Past
	cmp #46
	beq .noLooping
	; 2.12 Fanfare 2
	cmp #28
	beq .noLooping
	; 2.15 Fanfare 3
	cmp #61
	beq .noLooping
	; 2.22 Fiedlord's Keep
	cmp #72
	beq .noLooping
	lda #$03
	rts
.noLooping
	lda #$01
	rts
	
MSU_UpdateLoop:
	php
	rep #$20
	pha
	
	sep #$20

	%CheckMSUPresence(.CallNMI)
	
	lda fadeState
	beq .CallNMI
	
	cmp.b #FADE_STATE_FADEOUT
	beq .FadeOutUpdate
	cmp.b #FADE_STATE_FADEIN
	beq .FadeInUpdate
	bra .CallNMI
	
.FadeOutUpdate:
	lda fadeVolume
	sec
	rep #$20
	sbc fadeStep
	cmp fadeTarget
	bpl +
	sep #$20
	lda fadeTarget
+
	sep #$20
	sta fadeVolume
	sta MSU_AUDIO_VOLUME
	cmp fadeTarget
	beq .SetToIdle
	bra .CallNMI

.FadeInUpdate
	lda fadeVolume
	clc
	adc fadeStep
	cmp fadeTarget
	bcc +
	lda fadeTarget
+
	sta fadeVolume
	sta MSU_AUDIO_VOLUME
	cmp fadeTarget
	beq .SetToIdle
	bra .CallNMI
	
.SetToIdle:
	lda.b #FADE_STATE_IDLE
	sta fadeState
	
.CallNMI
	rep #$20
	pla
	plp
	jml $000500
	
TitleScreenWaitFix:
	php
	rep #$20
	pha
	
	sep #$20

	%CheckMSUPresence(.OriginalCode)
	
	rep #$20
	pla
	plp
	rtl
	
.OriginalCode
	rep #$20
	pla
	plp
	
	; Original code
-
	lda $2143
	and #$0F
	beq -
	
	rtl