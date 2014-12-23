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

; Variables
CurrentSong = $1EE0

; Called during attract
org $C03C43
	jsl MSU_Main
	
; Entering area
org $C01B8B
	jsl MSU_Main
	
; Exiting area
org $C22F49
	jsl MSU_Main
	
; Overworld music change
org $C223F9
	jsl MSU_Main

; Entering battle
org $C01BCE
	jsl MSU_Main
	
; Exiting battle
org $C01C3A
	jsl MSU_Main
	
; Opening a black chest
org $C03CB4
	jsl MSU_Main
	
; Restore music after opening a black chest
org $C03C43
	jsl MSU_Main
	
org $C5F364
MSU_Main:
	php
; Backup A and Y in 16bit mode
	rep #$20
	pha
	
	sep #$20 ; Set all registers to 8 bit mode
	
	; Check if MSU-1 is present
	lda MSU_ID
	cmp #'S'
	bne .CallOriginalRoutine
	
.MSUFound:
	lda $1E00
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
	bra .CallOriginalRoutine
+
; Call original routine if MSU-1 is not found
.CallOriginalRoutine:
	rep #$20
	pla
	plp
	
	jsl $C70004
	rtl
	
.DoNotCallSPCRoutine
	rep #$20
	pla
	plp
	rtl

MSU_PlayMusic:
	lda $1E01
	beq .StopMSUMusic
	cmp CurrentSong
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
	lda #$03
	sta MSU_AUDIO_CONTROL
	
	; Set volume
	lda.b #FULL_VOLUME
	sta.w MSU_AUDIO_VOLUME
	
	; Only store current song if we were able to play the song
	lda $1E01
	sta CurrentSong
	
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
	sta CurrentSong
	sec
	bra .Exit
	
MSU_ResumeMusic:
	lda $1E01
	sta CurrentSong
	lda #$03
	sta MSU_AUDIO_CONTROL
	clc
	rts
	
MSU_PauseMusic:
	lda #$00
	sta MSU_AUDIO_CONTROL
	sta CurrentSong
	sec
	rts