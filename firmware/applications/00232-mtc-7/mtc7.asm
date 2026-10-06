;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------
;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

COUNTEMP        .DS     1       ;temporary counter value
AUTOPLAY	.DS	1	;autoplay mode flag (1=autoplay)
TSFVAL		.DS	1	;TSF value
BSETVAL		.DS	1	;Beat set value
STARTVAL	.DS	1	;Start event value
STOPVAL		.DS	1	;Stop event value
BEATVAL		.DS	1	;Beat event value
CLKBEAT		.DS	1	;Clocks per beat
CLKBEAT1	.DS	1	;Clocks per beat minus 1
CLKBEAT2	.DS	1	;Clocks per beat div 2
PARNUM		.DS	1	;parameter number (programming mode)
TTEMP		.DS	1	;temporary tempo storage variable
MIDICHAN        .DS     1       ;MIDI chan for sustain/note messages

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StStop		EQU	0
StPlay		EQU	1
StProg		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvStart 	EQU	EV_SW1_ON
EvTSF		EQU	EV_SW2_ON
EvSetB		EQU	EV_SW3_ON
EvBeat		EQU	EV_SW4_ON
EvStop		EQU	EV_SW5_ON
EvDown	 	EQU	EV_SW6_ON
EvUp		EQU	EV_SW7_ON
EvAuto		EQU	EV_SW8_ON
EvValue         EQU     EV_FDR_MOVE
EvMsgIn		EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StStop  State 1:StPlay State 2:StProg	         Not
;	 Event	  NextSt,Act	  NextSt,Act     NextSt,Act	        Used
;	 -------------------------------------------------------------------
 STM_ROW EvIdle,  StStop,IDLE,	  StPlay,IDLE,   StProg,IDLE,    StStop,IDLE
 STM_ROW EvStart, StPlay,START,	  StPlay,IDLE,   StProg,STARTEV, StStop,IDLE
 STM_ROW EvTSF,   StStop,TSFSET,  StPlay,IDLE,   StProg,SAVE,    StStop,IDLE
 STM_ROW EvSetB,  StStop,BEATSET, StPlay,IDLE,   StProg,BEATEV,  StStop,IDLE
 STM_ROW EvBeat,  StProg,PDISP,	  StPlay,CLKGO,  StStop,DISP,    StStop,IDLE
 STM_ROW EvStop,  StPlay,CONT,	  StStop,STOP,   StProg,STOPEV,  StStop,IDLE
 STM_ROW EvDown,  StStop,TEMDEC,  StPlay,TEMDEC, StProg,VALDEC,  StStop,IDLE
 STM_ROW EvUp,    StStop,TEMINC,  StPlay,TEMINC, StProg,VALINC,  StStop,IDLE
 STM_ROW EvAuto,  StStop,AUTTOG,  StPlay,AUTOPL, StProg,CHEV,    StStop,IDLE
 STM_ROW EvValue, StStop,TEMFDR,  StPlay,IDLE,   StProg,VALFDR,  StStop,IDLE
 STM_ROW EvMsgIn, StStop,MPROCS,  StPlay,MPROCP, StProg,MPROG,   StStop,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	clr	AUTOPLAY	;default to manual mode
	clr	COUNTEMP	;clear counter
	clr	M_PLAY		;clear flag
        lda     #0
        sta     MIDICHAN

;--- Initialize MIDI

	lda	#$11		;buffer notes and controller (64 only)
	sta	M_RX_Q_XPT	;
	lda	#$40		;enable timer interrupts
	sta	TCR		;

;--- Initialize display

	jsr	LCD_CLEAR
        LCD_PUT_S "   MIDItools   "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
        LCD_PUT_S "Tempo Controller"
	jsr	DELAY_1SEC
	jsr	LCD_CLEAR

	jsr	LOAD		;get all paramters
	jsr	DISP		;update display
	lda	M_TEMPO		;get tempo
	jsr	MIDI_TEMPO	;set it up

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment tempo

TEMINC: lda	M_PLAY		;are we playing?
	beq	TIA		;no? branch...
	lda	AUTOPLAY	;yes? are we in manual mode?
	beq	TIDUN		;yes? ignore...

TIA:	lda	M_TEMPO		;fetch M_TEMPO
	inca			;increment
	cmp	#19		;<20 ("above" 255)?
	bhi	TIB		;no? branch...
	lda	#20		;yes? wrap to 20

TIB:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
TIDUN:	rts

;--- Decrement tempo

TEMDEC: lda     M_PLAY          ;are we playing?
	beq	TDA		;no? branch...
	lda	AUTOPLAY	;yes? are we in manual mode?
	beq	TDDUN		;yes? ignore...

TDA:	lda	M_TEMPO		;fetch M_TEMPO
	deca			;decrement
	cmp	#19		;<20? ("above" 255)?
	bhi	TDB		;no? branch...
	lda	#255		;yes? wrap to 255

TDB:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
TDDUN:	rts

;--- Set tempo with fader

TEMFDR: lda	FDR		;fetch fader value
	cmp	#19		;>19?
	bhi	TFA		;yes? branch...
	lda	#20		;no? stay at 20

TFA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
	rts

;--- Set the note that gets the beat

BEATSET:
	lda	#9		;prepare cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BSETVAL		;get value
	inca			;increment it
	cmp	#5		;compare to 5
	blo	BSA		;<5? branch...
	lda	#0		;no? reset to 0...

BSA:	sta	BSETVAL		;save new value
	beq	BSB		;=0? branch...
	cmp	#1		;=1? branch...
	beq	BSC		;
	cmp	#2		;=2? branch...
	beq	BSD		;
	cmp	#3		;=3? branch...
	beq	BSE		;
	LCD_PUT_S "-3-"         ;
	lda	#8		;get value
	jmp	BSDUN

BSB:	LCD_PUT_S "1/2"         ;
	lda	#48		;get value
	jmp	BSDUN

BSC:	LCD_PUT_S "1/4"         ;
	lda	#24		;get value
	jmp	BSDUN

BSD:	LCD_PUT_S "1/8"         ;
	lda	#12		;get value
	jmp	BSDUN

BSE:	LCD_PUT_S "16T"         ;
	lda	#6		;get value

BSDUN:	sta	CLKBEAT		;save new value
	lsra			;divide by 2
	sta	CLKBEAT2	;save value
	lda	CLKBEAT		;get original value
	deca			;subtract 1
	sta	CLKBEAT1	;save value
	rts

;--- Set Tempo Smoothing Function value

TSFSET: lda	TSFVAL		;fetch smoothing value
	cmp	#8		;is it at 8?
	bne	TSFA		;not=8? branch...
	clr	TSFVAL		;=8? reset TSF
	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OFF"         ;
	rts

TSFA:	lda	#0		;clear OFF
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "         ;
	lda	#1		;set up cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	TSFVAL		;check value
	bne	TSFB		;not=0? branch...
	inca			;increment if =0
	jmp	TSFC		;jump

TSFB:	lsla			;shift left

TSFC:	sta	TSFVAL		;save new value
	jsr	LCD_PUT_I	;display it
	rts

;--- Set autoplay mode

AUTOPL: lda	#1		;set autoplay flag
	sta	AUTOPLAY	;
	jsr	MDISP		;update display
	lda	TSFVAL		;
	bne	APLDUN		;smoothing play? return...
	lda	TTEMP		;load saved value
	sta	M_TEMPO		;save new value
	jsr	MIDI_TEMPO	;set it free...
	jsr	TDISP		;update display
APLDUN:	rts

;--- Toggle playback mode status

AUTTOG: lda	AUTOPLAY	;fetch autoplay flag
	eor	#$01		;toggle
	sta	AUTOPLAY	;save new value
	jsr	MDISP		;update display
	rts

;--- Select Start Event

STARTEV:
	jsr	ARWCLR		;clear arrow
	lda	#0		;put arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	lda	#0		;
	sta	PARNUM		;save new value
	rts

;--- Select Stop/Cont Event

STOPEV:	jsr	ARWCLR		;clear arrow
        lda     #4              ;put arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	lda	#1		;
	sta	PARNUM		;save new value
	rts

;--- Select Beat Event

BEATEV:	jsr	ARWCLR		;clear arrow
        lda     #8              ;put arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	lda	#2		;
	sta	PARNUM		;save new value
	rts

;--- Select Chan Event

CHEV:   jsr     ARWCLR          ;clear arrow
        lda     #13             ;put arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
        lda     #3              ;
	sta	PARNUM		;save new value
	rts

;--- Increment parameter value

VALINC:	lda	PARNUM		;check parameter number
	cmp	#1		;=1? branch...
	beq	VIB		;
	cmp	#2		;=2? branch...
	FAR_BEQ	VID		;
        cmp     #3              ;CHAN?
        FAR_BEQ VICH
        lda     STARTVAL        ;get value
	inca			;increment
	and	#$7F		;constrain 0-127
	sta	STARTVAL	;save new value
	bne	VIA		;
        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "         ;
	rts

VIA:    lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #3              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STARTVAL	;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VIB:	lda	STOPVAL		;get value
	inca			;increment
	and	#$7F		;constrain 0-127
	sta	STOPVAL		;save new value
	bne	VIC		;
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VIC:    lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #7              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STOPVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VID:	lda	BEATVAL		;get value
	inca			;increment
	and	#$7F		;constrain 0-127
	sta	BEATVAL		;save new value
	bne	VIE		;
        lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VIE:    lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #11             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BEATVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VICH:   lda     MIDICHAN        ;get value
	inca			;increment
        and     #$0F            ;constrain 0-15
        sta     MIDICHAN        ;save new value
        lda     #15             ;update display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MIDICHAN        ;
	inca			;increment to display as 1-16
        jsr     LCD_PUT_RJ2_I   ;
	rts

;--- Decrement parameter value

VALDEC:	lda	PARNUM		;check parameter number
	cmp	#1		;=1? branch...
	beq	VDB		;
	cmp	#2		;=2? branch...
        FAR_BEQ VDD             ;
        cmp     #3              ;chan?
        FAR_BEQ VDCH
        lda     STARTVAL        ;get value
	deca			;decrement
	and	#$7F		;constrain 0-127
	sta	STARTVAL	;save new value
	bne	VDA		;
        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VDA:    lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #3              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STARTVAL	;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VDB:	lda	STOPVAL		;get value
	deca			;decrement
	and	#$7F		;constrain 0-127
	sta	STOPVAL		;save new value
	bne	VDC		;
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VDC:    lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #7             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STOPVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VDD:	lda	BEATVAL		;get value
	deca			;decrement
	and	#$7F		;constrain 0-127
	sta	BEATVAL		;save new value
	bne	VDE		;
        lda     #9             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VDE:    lda     #9             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #11             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BEATVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VDCH:   lda     MIDICHAN        ;get value
        deca                    ;decrement
        and     #$0F            ;constrain 0-15
        sta     MIDICHAN        ;save new value
        lda     #15             ;update display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MIDICHAN        ;
	inca			;increment to display as 1-16
        jsr     LCD_PUT_RJ2_I   ;
	rts

;--- Set parameter value with fader

VALFDR:	lda	PARNUM		;check parameter number
	cmp	#1		;=1? branch...
	beq	VFB		;
	cmp	#2		;=2? branch...
	FAR_BEQ	VFD		;
        cmp     #3              ;chan?
        FAR_BEQ VFCH
	lda	FDR		;get value
	lsra			;constrain 0-127
	sta	STARTVAL	;save new value
	bne	VFA		;
        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VFA:    lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #3              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STARTVAL	;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VFB:	lda	FDR		;get value
	lsra			;constrain 0-127
	sta	STOPVAL		;save new value
	bne	VFC		;
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VFC:    lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #7             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STOPVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VFD:	lda	FDR		;get value
	lsra			;constrain 0-127
	sta	BEATVAL		;save new value
	bne	VFE		;
        lda     #9             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

VFE:    lda     #9             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #11             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BEATVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

VFCH:   lda     FDR             ;get fader
        lsra                    ;divide by 16
        lsra                    ;divide by 16
        lsra                    ;divide by 16
        lsra                    ;divide by 16
        sta     MIDICHAN        ;save new value
        lda     #15             ;update display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MIDICHAN        ;
	inca			;increment to display as 1-16
        jsr     LCD_PUT_RJ2_I   ;
	rts

;--- Send Start message

START:	clr	TCR		;disable timer interrupts
	inc	M_PLAY		;flag playing status
	lda	#$FA		;send Start message
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	lda	#$F8		;send one MIDI clock (per MIDI spec)
	jsr	MIDI_PUT	;
	jsr	LEDPLY		;update display
	clr	M_CLK_CNTR	;reset counter

	;--- setup timer registers for first time-out

	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;
	lda	#$40		;enable timer interrupts
	sta	TCR		;
	rts

;--- Send Continue message

CONT:	clr	TCR		;disable timer interrupts
	inc	M_PLAY		;flag playing status
	lda	#$FB		;send Continue message
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	lda	#$F8		;send one MIDI clock
	jsr	MIDI_PUT	;
	lda	#$F8		;send another MIDI clock (to
	jsr	MIDI_PUT	; finish at the end of a beat)
	jsr	LEDPLY		;update display
	clr	M_CLK_CNTR	;continue from measure beginning

	;--- setup timer registers for first time-out

	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;
	lda	#$40		;enable timer interrupts
	sta	TCR		;
	rts

;--- Send Stop message

STOP:	lda	M_CLK_CNTR	;wait for end of beat
	cmp	CLKBEAT		;
	blo	STOP		;
	jsr	MIDI_STOP	;stop the sequencer
	jsr	LEDSTP		;update display
	lda	AUTOPLAY	;check flag
	bne	STPDUN		;auto mode? return...
	lda	TSFVAL		;check TSF
	bne	STPDUN		;smoothing play? return...
	lda	TTEMP		;nonsmoothing manual play? load value
	sta	M_TEMPO		;save new value
	jsr	MIDI_TEMPO	;set it free...
	jsr	TDISP		;update display
STPDUN:	rts

;--- Process MIDI message input when stopped

MPROCS:	lda	MP_RSTAT	;get status byte

        ;!!!--- added MIDI chan Bob 5/16/96

        and     #$0F
        cmp     MIDICHAN
        beq     OKCHS
        rts
OKCHS:	lda     MP_RSTAT

        ;!!!---

        and     #$F0            ;erase channel
	cmp	#$B0		;is it a controller?
	beq	MPA		;yes? branch...
	cmp	#$90		;is it a note on?
	beq	MPB		;yes? branch...
	rts			;return; must be note off

	;it is a Controller message

MPA:	lda	MP_DATA1	;load data byte
	cmp	#64		;is it sustain?
	bne	MPDUN		;no? return...
	lda	MP_DATA2	;look at data value (pedal on or off)
	cmp	#127		;footpedal on (127)?
	bne	MPDUN		;footpedal off (0)? return...
	lda	STARTVAL	;footpedal is on; get Start value
	bne	MPAA		;
	lda	#EvStart	;load replacement event
	sta	EVENT		;save as latest event
	jsr	START		;=0? start
	rts

MPAA:	lda	STOPVAL		;get Stop value
	bne	MPDUN		;
	lda	#EvStop		;load replacement event
	sta	EVENT		;save as latest event
	jsr	CONT		;=0? continue
	rts

	;it is a Note On message

MPB:    ;!!! added to fix note off problem 5/3/96 - bob moses

        lda     MP_DATA2        ;make sure this isn't a NOTE OFF
        bne     MPBOK
        rts
MPBOK:
        ;!!!

        lda     MP_DATA1        ;load data byte
	cmp	STARTVAL	;is it our StartVal?
	beq	MPC		;yes? branch...
	cmp	STOPVAL		;is it our StopVal?
	beq	MPD		;yes? branch...
	rts			;ignore leftovers

MPC:	lda	#EvStart	;load replacement event
	sta	EVENT		;save as latest event
	jsr	START		;go start
	rts

MPD:	lda	#EvStop		;load replacement event
	sta	EVENT		;save as latest event
	jsr	CONT		;go continue
MPDUN:	rts

;--- Process MIDI message input when playing

MPROCP:	lda	MP_RSTAT	;get status byte

        ;!!!--- added MIDI chan Bob 5/16/96

        and     #$0F
        cmp     MIDICHAN
        beq     OKCHP
        rts
OKCHP:	lda     MP_RSTAT

        ;!!!---

	and	#$F0		;erase channel
	cmp	#$B0		;is it a controller?
	beq	MPPA		;yes? branch...
	cmp	#$90		;is it a note on?
	beq	MPPB		;yes? branch...
	rts			;return; must be note off

	;it is a Controller message

MPPA:	lda	MP_DATA1	;load data byte
	cmp	#64		;is it sustain?
	bne	MPPDUN		;no? return...
	lda	MP_DATA2	;look at data value (pedal on or off)
	cmp	#127		;footpedal on (127)?
	bne	MPPDUN		;footpedal off (0)? return...
	lda	STARTVAL	;get Start value
	bne	MPPAA		;
	lda	#EvStart	;load replacement event
	sta	EVENT		;save as latest event
	rts			;be idle...

MPPAA:	lda	STOPVAL		;get Stop value
	bne	MPPAB		;
	lda	#EvStop		;load replacement event
	sta	EVENT		;save as latest event
	jsr	STOP		;=0? stop
	rts

MPPAB:	lda	BEATVAL		;get Beat value
	bne	MPPDUN		;
	lda	#EvBeat		;load replacement event
	sta	EVENT		;save as latest event
	jsr	CLKGO		;go BEAT key!
	rts

	;is it a note on?

MPPB:   ;!!! added to fix note off problem 5/3/96 - bobm

        lda     MP_DATA2        ;make sure this isn't a NOTE OFF
        bne     MPPBOK
        rts
MPPBOK:
        ;!!!

        lda     MP_DATA1        ;load data byte
	cmp	STARTVAL	;is it our StartVal?
	beq	MPPC		;yes? branch...
	cmp	STOPVAL		;is it our StopVal?
	beq	MPPD		;yes? branch...
	cmp	BEATVAL		;is it our BeatVal?
	beq	MPPE		;yes? branch...
	rts			;ignore leftovers

MPPC:	lda	#EvStart	;load replacement event
	sta	EVENT		;save as latest event
	rts			;be idle...

MPPD:	lda	#EvStop		;load replacement event
	sta	EVENT		;save as latest event
	jsr	STOP		;go stop
	rts

MPPE:	lda	#EvBeat		;load replacement event
	sta	EVENT		;save as latest event
	jsr	CLKGO		;go beat
MPPDUN:	rts

;--- Program via MIDI message input

MPROG:	lda	MP_RSTAT	;get status byte

        ;!!!--- added MIDI chan Bob 5/16/96

        and     #$0F
        cmp     MIDICHAN
        beq     OKCHG
        rts
OKCHG:	lda     MP_RSTAT

        ;!!!---

	and	#$F0		;erase channel
	cmp	#$B0		;is it a controller?
	beq	MGA		;yes? branch...
	cmp	#$90		;is it a note on?
	beq	MGD		;yes? branch...
	rts			;return; must be note off

	;it is a Controller message

MGA:	lda	MP_DATA1	;load data byte
	cmp	#64		;is it sustain?
	FAR_BNE	MGDUN		;no? return...
	lda	PARNUM		;get parameter number
	beq	MGB		;go if 0
	cmp	#1		;
	beq	MGC		;go if 1
	clr	BEATVAL		;must be 2; reset value to 0 (FOOT)
        lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

MGB:	clr	STARTVAL	;reset value
        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

MGC:	clr	STOPVAL		;reset value
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	rts

	;it is a Note On message

MGD:    ;!!! added to fix note off problem 5/3/96 - bobm

        lda     MP_DATA2        ;make sure this isn't a NOTE OFF
        bne     MGDOK
        rts
MGDOK:
        ;!!!

        lda     PARNUM          ;get parameter number
	beq	MGE		;go if 0
	cmp	#1		;
	beq	MGF		;go if 1
	lda	MP_DATA1	;must=2; get note number
	sta	BEATVAL		;save new value
        lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #11             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BEATVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

MGE:	lda	MP_DATA1	;get note number
	sta	STARTVAL	;save new value
        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #3              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STARTVAL	;get new value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

MGF:	lda	MP_DATA1	;get note number
	sta	STOPVAL		;save new value
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;
        lda     #7              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STOPVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it
MGDUN:	rts

;--- Transmit clocks for one beat and calculate QPM

CLKGO:	clr	TCR		;stop clock
	lda	AUTOPLAY	;are we autoplaying?
	beq	CGOTST		;no? branch...

	;we are in auto mode (switch to manual mode on the fly)

	clr	AUTOPLAY	;yes? clear autoplay flag
	jsr	MDISP		;update display

	;now in manual mode (debounce beat key by 50%)

CGOTST:	lda	M_CLK_CNTR	;fetch counter
	cmp	CLKBEAT2	;are we in the 2nd half beat?
	bhi	CGO		;yes? go on...
	lda	#$40		;1st half? finish beat (ignore key hit)
	sta	TCR		;enable timer interrupts
	rts			;return

	;process valid beat key hit

CGO:	lda	M_CLK_CNTR	;fetch counter
	sta	COUNTEMP	;save value
	cmp	CLKBEAT		;limit or more clocks counted?
	bhs	CALCTEM 	;yes? branch...

CSPIT:	lda	#$F8		;no? send a MIDI clock
	jsr	MIDI_PUT	;
	lda	M_CLK_CNTR	;fetch counter
	cmp	CLKBEAT1	;finished?
	beq	CALCTEM 	;yes? branch...
	inc	M_CLK_CNTR	;no? increment counter value
	jmp	CSPIT		;loop

CALCTEM:
	lda	TSFVAL		;fetch TSF value
	bne	STEM		;not=0(on)? branch...

;
; NORMAL FORMULA:   NEW M_TEMPO= [(OLD M_TEMPO)*(K)]/128
;		    where K=(24/COUNTEMP)*128
;

NTEM:	ldx	COUNTEMP	;fetch counter value
	lda	KTBL,X		;index into table to get K
	ldx	M_TEMPO		;fetch M_TEMPO
	mul			;multiply (LSB->acca,MSB->x)
	asla			;this is a shortcut for dividing
	rolx			; by 128, result is in x
	bcs	CMAX		;if M_TEMPO>255, force it to 255
	txa			;transfer new M_TEMPO to acca
	cmp	#20		;is it 20 or greater?
	bhs	CT20		;yes? branch...
	lda	#20		;no? new M_TEMPO=20
CT20:   jsr     MIDI_TEMPO      ;save new M_TEMPO
	jsr	TCDISP		;update display
	jmp	C2END		;jump...
CMAX:	lda	#255		;new M_TEMPO=255
        jsr     MIDI_TEMPO      ;save new M_TEMPO
	jsr	TCDISP		;update display
	jmp	C2END		;jump...

;
; SMOOTH FORMULA:   K=CLKBEAT-(COUNTEMP)
;		    --> if K<0, decrement M_TEMPO
;		    --> if K>0, increment M_TEMPO
;		    --> if K=0, M_TEMPO is unchanged
;

STEM:	lda	COUNTEMP	;fetch clock counter
	cmp	CLKBEAT		;compare to CLKBEAT
	blo	SCINC		;less than CLKBEAT? branch...
	bhi	SCDEC		;greater than CLKBEAT? branch...
	jmp	CEND		;equal to CLKBEAT? jump...
SCINC:	lda	M_TEMPO		;fetch current tempo
	cmp	#255		;is it =255?
	beq	CEND		;yes? branch...
	add	TSFVAL		;add TSF value
	bcc	SCZZ1		;no carry (<255)? go on...
	lda	#255		;fix at 255
SCZZ1:	jsr     MIDI_TEMPO      ;save new M_TEMPO
	jmp	CEND		;jump...
SCDEC:	lda	M_TEMPO		;fetch current M_TEMPO
	cmp	#20		;is it =20?
	beq	CEND		;yes? branch...
	sub	TSFVAL		;no? subtract TSF value
	cmp	#20		;compare to 20
	bhs	SCZZ2		;branch if >20
	lda	#20		;fix at 20
SCZZ2:	jsr     MIDI_TEMPO      ;save new M_TEMPO
CEND:	jsr	TDISP		;update display
C2END:	clr	M_CLK_CNTR	;reset clock counter

	;--- setup timer registers for first time-out

	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;
	lda	#$40		;enable timer interrupts
	sta	TCR		;
	rts

KTBL:
.DW	$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFEC,$DBCD
.DW	$C0B5,$ABA2,$9A92,$8C86,$807B,$7672,$6E6A,$6663
.DW	$605D,$5A58,$5553,$514F,$4D4B,$4947,$4644,$4341
.DW	$403F,$3D3C,$3B3A,$3938,$3736,$3534,$3332,$3231
.DW	$302F,$2F2E,$2D2D,$2C2B,$2B2A,$2A29,$2828,$2727
.DW	$2626,$2525,$2524,$2423,$2323,$2222,$2121,$2120
.DW	$2020,$1F1F,$1F1E,$1E1E,$1E1D,$1D1D,$1C1C,$1C1C
.DW	$1B1B,$1B1B,$1A1A,$1A1A,$1A19,$1919,$1919,$1818
.DW	$1818,$1817,$1717,$1717,$1716,$1616,$1616,$1615
.DW	$1515,$1515,$1515,$1414,$1414,$1414,$1414,$1313
.DW	$1313,$1313,$1313,$1312,$1212,$1212,$1212,$1212
.DW	$1211,$1111,$1111,$1111,$1111,$1110,$1010,$1010
.DW	$1010,$1010,$1010,$100F,$0F0F,$0F0F,$0F0F,$0F0F
.DW	$0F0F,$0F0F,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E
.DW	$0E0E,$0E0E,$0D0D,$0D0D,$0D0D,$0D0D,$0D0D,$0D0D
.DW	$0D0D,$0D0D,$0D0D,$0C0C,$0C0C,$0C0C,$0C0C,$0C0C

;--- Control STOPPED LED

LEDSTP: lda     #13             ;turn PLAYING LED off
	jsr	LED_OFF 	;
	rts

;--- Control PLAYING LED

LEDPLY: lda     #13             ;turn PLAYING LED on
	jsr	LED_ON		;
	rts

;--- Update display with normal values

DISP:	jsr	LCD_CLEAR	;clear display
	LCD_PUT_S "TSF MODE SET QPM"
	lda	TSFVAL		;get TSF value
	bne	DPA		;
	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OFF"         ;
	jmp	DPB		;move on...

DPA:	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "         ;
	lda	#1		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	TSFVAL		;get new value
	jsr	LCD_PUT_I	;display it

DPB:	jsr	MDISP		;display mode
	lda	#9		;set up cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BSETVAL		;get note value
	beq	DPBA		;=0? branch...
	cmp	#1		;=1? branch...
	beq	DPBB		;
	cmp	#2		;=2? branch...
	beq	DPBC		;
	cmp	#3		;=3? branch...
	beq	DPBD		;
	LCD_PUT_S "-3-"         ;must=4
	jmp	DPC		;move on...

DPBA:	LCD_PUT_S "1/2"         ;
	jmp	DPC		;move on...

DPBB:	LCD_PUT_S "1/4"         ;
	jmp	DPC		;move on...

DPBC:	LCD_PUT_S "1/8"         ;
	jmp	DPC		;move on...

DPBD:	LCD_PUT_S "16T"         ;

DPC:	jsr	TDISP		;display tempo
	rts

;--- Update display with playback mode

MDISP:	lda	#4		;prepare cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	AUTOPLAY	;fetch flag
	bne	ADON		;=1? branch...
	LCD_PUT_S "MAN "	;=0? display
	jmp	MDDUN		;finished...

ADON:	LCD_PUT_S "AUTO"        ;=1? display

MDDUN:	rts

;--- Update display with tempo value (user selected)

TDISP:	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_TEMPO		;fetch M_TEMPO
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display with tempo value (calculated; manual mode; TSF=OFF)

TCDISP:	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

TCDA:	lda	BSETVAL		;check note value
	beq	TCDB		;=half-note? branch...
	cmp	#1		;=quarter-note? branch...
	beq	TCDC		;
	cmp	#2		;=eighth-note? branch...
	FAR_BEQ	TCDD		;
	cmp	#3		;=sixteenth-note? branch...
	FAR_BEQ	TCDE		;
	lda	M_TEMPO		;must be triplet; fetch M_TEMPO
	lsra			;divide by 32
	lsra			;
	lsra			;
	lsra			;
	lsra			;
	ldx	#11		;multiply by 11
	mul			;   (11/32 is approx= 1/3)
	sta	TTEMP		;save adjusted value for later recall
	jsr	LCD_PUT_RJ3_I	;display it
	rts

TCDB:	lda	M_TEMPO		;fetch M_TEMPO
	cmp	#$7F		;compare to 127
	bls	TCDBB		;<=127? go on...
	lda	#255		;fix it at max display value
	jmp	TCDBBB		;

TCDBB:	lsla			;multiply by 2

TCDBBB:	sta	TTEMP		;save adjusted value for later recall
	jsr	LCD_PUT_RJ3_I	;display it
	rts

TCDC:	lda	M_TEMPO		;fetch M_TEMPO
	sta	TTEMP		;save adjusted value for later recall
	jsr	LCD_PUT_RJ3_I	;display it
	rts

TCDD:	lda	M_TEMPO		;fetch M_TEMPO
	lsra			;divide by 2
	sta	TTEMP		;save adjusted value for later recall
	jsr	LCD_PUT_RJ3_I	;display it
	rts

TCDE:	lda	M_TEMPO		;fetch M_TEMPO
	lsra			;divide by 4
	lsra			;
	sta	TTEMP		;save adjusted value for later recall
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for programming

PDISP:	jsr	LCD_CLEAR	;clear display
        LCD_PUT_S "STA STP BEAT  CH"

	lda	STARTVAL	;get Start event value
	bne	PDA		;

        lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	jmp	PDB		;move on...

PDA:    lda     #1              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;

        lda     #3              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STARTVAL	;get new value
	jsr	LCD_PUT_RJ3_I	;display it

PDB:	lda	STOPVAL		;get Stop event value
	bne	PDC		;
        lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	jmp	PDD		;move on...

PDC:    lda     #5              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;

        lda     #7              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STOPVAL		;get new value
	jsr	LCD_PUT_RJ3_I	;display it

PDD:	lda	BEATVAL		;get Beat event value
	bne	PDE		;
        lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "FT "        ;
	jmp	PDF		;move on...

PDE:    lda     #9              ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "   "        ;

        lda     #11             ;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     BEATVAL         ;get new value
	jsr	LCD_PUT_RJ3_I	;display it

PDF:    lda     #15             ;update display w/channel
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MIDICHAN        ;
	inca			;increment to display as 1-16
        jsr     LCD_PUT_RJ2_I   ;

	lda	#0		;place arrow cursor
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	clr	PARNUM		;reset parameter number to Start event
	rts

;--- Clear LCD cursor arrow

ARWCLR: lda	#0		;1st possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
        lda     #4              ;2nd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
        lda     #8              ;3rd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
        lda     #13             ;4TH possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
        rts

;--- Save all parameters

SAVE:	lda	#0
	ldx	TSFVAL
        jsr     EE_WRITE        ;store it
	lda	#1
	ldx	BSETVAL
        jsr     EE_WRITE        ;store it
	lda	#2
	ldx	M_TEMPO
        jsr     EE_WRITE        ;store it
	lda	#3
	ldx	STARTVAL
        jsr     EE_WRITE        ;store it
	lda	#4
	ldx	STOPVAL
        jsr     EE_WRITE        ;store it
	lda	#5
	ldx	BEATVAL
        jsr     EE_WRITE        ;store it
	lda	#6
	ldx	CLKBEAT
        jsr     EE_WRITE        ;store it
	lda	#7
	ldx	CLKBEAT1
        jsr     EE_WRITE        ;store it
	lda	#8
	ldx	CLKBEAT2
        jsr     EE_WRITE        ;store it
        lda     #9
        ldx     MIDICHAN
        jsr     EE_WRITE        ;store it
        rts

;---Load all parameters

LOAD:	lda	#0		;
	jsr	EE_READ 	;fetch value
	sta	TSFVAL		;store value
	lda	#1		;
	jsr	EE_READ 	;fetch value
	sta	BSETVAL		;store value
	lda	#2		;
	jsr	EE_READ 	;fetch value
	sta	M_TEMPO		;store value
	lda	#3		;
	jsr	EE_READ 	;fetch value
	sta	STARTVAL	;store value
	lda	#4		;
	jsr	EE_READ 	;fetch value
	sta	STOPVAL		;store value
	lda	#5		;
	jsr	EE_READ 	;fetch value
	sta	BEATVAL		;store value
	lda	#6		;
	jsr	EE_READ 	;fetch value
	sta	CLKBEAT		;store value
	lda	#7		;
	jsr	EE_READ 	;fetch value
	sta	CLKBEAT1	;store value
	lda	#8		;
	jsr	EE_READ 	;fetch value
	sta	CLKBEAT2	;store value
        lda     #9              ;
	jsr	EE_READ 	;fetch value
        sta     MIDICHAN        ;store value
        rts

;----------------------------------------------------------------
;	Interrupt Call Backs
;----------------------------------------------------------------

        IGNORE_IRQ_SWI_SPI

TIMER_CBCK:

	;--- setup timer registers for next time-out

	lda	M_CLK_LSB	;compute and store next output
	add	OCRLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	OCRMSB		;
	sta	OCRMSB		;
	lda	TSR		;neccesary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;
	lda	M_PLAY		;are we playing?
	bne	THA		;yes? branch...
	lda	#$F8		;no? load MIDI clock
	jsr	MIDI_PUT	;send it
	rti

THA:	lda	AUTOPLAY	;autoplay mode?
	bne	THB		;yes? branch...
	lda	M_CLK_CNTR	;no? fetch counter
	cmp	CLKBEAT		;CLKBEAT or higher? do not transmit
	bhs	THD		; any more MIDI clocks

THB:	lda	M_CLK_CNTR	;fetch counter
	cmp	CLKBEAT		;
	blo	THE		;<CLKBEAT? branch...
	clr	M_CLK_CNTR	;=CLKBEAT? clear counter

THE:	lda	#$F8		;load MIDI clock
	jsr	MIDI_PUT	;send it

THD:	lda	M_CLK_CNTR	;fetch counter
	cmp	#255		;=255?
	beq	THEND		;yes? branch...
	inc	M_CLK_CNTR	;no? increment it
THEND:	rti			;return, bypass BIOS timer ISR

SCI_TX_CBCK:
        jmp     SCI_TX_CBCK_RET

SCI_RX_CBCK:
        jmp     SCI_RX_CBCK_RET

SCI_RX_CBCK_S:
        jmp     SCI_RX_CBCK_S_RET

SCI_RX_CBCK_D1:
        jmp     SCI_RX_CBCK_D1_RET

SCI_RX_CBCK_D2:
        jmp     SCI_RX_CBCK_D2_RET

