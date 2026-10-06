;===========================================================
;
;       sbeam2.asm	    Rev 0.7                 10/20/97
;
;	Rev. A of SbeamII f/w; Doc #000019
;===========================================================

;-----------------------------------------------------------
;	Variables
;-----------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CURBM	.DS	1	;current (displayed) Beam Number
CURST	.DS	1	;current (displayed) Status Type
CURNUM	.DS	1	;current (displayed) Data Value
CURCH	.DS	1	;current (displayed) Channel
VEL	.DS	1	;current global note velocity
TEMPST	.DS	1	;temporary status byte variable
TEMPNUM	.DS	1	;temporary Data Value variable
TEMPTOG	.DS	1	;temporary latch variable

KEYS	.DS	8	;image of key matrix
COL	.DS	1	;current column being read

BEAMNUM 	.DS	1	;active Beam Number
TEMP	.DS	1	;temporary variable
KEYCHG	.DS	1	;temporary image of A register
OLDCOL	.DS	1	;temporary image of X register

TFLAG	.DS	1	;flags that a timer interrupt occured
TLSB	.DS	1	;lsb of timer delta
TMSB	.DS	1	;msb of timer delta
TEMPOCRLSB	.DS	1

DUNSCROLL	.DS	1	;scrolling completion flag (1=finished, 0=continue scrolling)

ST0	.DS	1	;Status for Beam 0
ST1	.DS	1	;Status for Beam 1
ST2	.DS	1	;Status for Beam 2
ST3	.DS	1	;Status for Beam 3
ST4	.DS	1	;Status for Beam 4
ST5	.DS	1	;Status for Beam 5
ST6	.DS	1	;Status for Beam 6
ST7	.DS	1	;Status for Beam 7
ST8	.DS	1	;Status for Beam 8
ST9	.DS	1	;Status for Beam 9
ST10	.DS	1	;Status for Beam 10
ST11	.DS	1	;Status for Beam 11
ST12	.DS	1	;Status for Beam 12
ST13	.DS	1	;Status for Beam 13
ST14	.DS	1	;Status for Beam 14
ST15	.DS	1	;Status for Beam 15
ST16	.DS	1	;Status for Beam 16
ST17	.DS	1	;Status for Beam 17
ST18	.DS	1	;Status for Beam 18
ST19	.DS	1	;Status for Beam 19
ST20	.DS	1	;Status for Beam 20
ST21	.DS	1	;Status for Beam 21
ST22	.DS	1	;Status for Beam 22
ST23	.DS	1	;Status for Beam 23
ST24	.DS	1	;Status for Beam 24
ST25	.DS	1	;Status for Beam 25
ST26	.DS	1	;Status for Beam 26
ST27	.DS	1	;Status for Beam 27
ST28	.DS	1	;Status for Beam 28
ST29	.DS	1	;Status for Beam 29
ST30	.DS	1	;Status for Beam 30
ST31	.DS	1	;Status for Beam 31

NUM0	.DS	1	;Data Value for Beam 0
NUM1	.DS	1	;Data Value for Beam 1
NUM2	.DS	1	;Data Value for Beam 2
NUM3	.DS	1	;Data Value for Beam 3
NUM4	.DS	1	;Data Value for Beam 4
NUM5	.DS	1	;Data Value for Beam 5
NUM6	.DS	1	;Data Value for Beam 6
NUM7	.DS	1	;Data Value for Beam 7
NUM8	.DS	1	;Data Value for Beam 8
NUM9	.DS	1	;Data Value for Beam 9
NUM10	.DS	1	;Data Value for Beam 10
NUM11	.DS	1	;Data Value for Beam 11
NUM12	.DS	1	;Data Value for Beam 12
NUM13	.DS	1	;Data Value for Beam 13
NUM14	.DS	1	;Data Value for Beam 14
NUM15	.DS	1	;Data Value for Beam 15
NUM16	.DS	1	;Data Value for Beam 16
NUM17	.DS	1	;Data Value for Beam 17
NUM18	.DS	1	;Data Value for Beam 18
NUM19	.DS	1	;Data Value for Beam 19
NUM20	.DS	1	;Data Value for Beam 20
NUM21	.DS	1	;Data Value for Beam 21
NUM22	.DS	1	;Data Value for Beam 22
NUM23	.DS	1	;Data Value for Beam 23
NUM24	.DS	1	;Data Value for Beam 24
NUM25	.DS	1	;Data Value for Beam 25
NUM26	.DS	1	;Data Value for Beam 26
NUM27	.DS	1	;Data Value for Beam 27
NUM28	.DS	1	;Data Value for Beam 28
NUM29	.DS	1	;Data Value for Beam 29
NUM30	.DS	1	;Data Value for Beam 30
NUM31	.DS	1	;Data Value for Beam 31

	.APPL_RAM
	.ABSOLUTE

TOG0	.DS	1	;beam 0 state toggle flag
TOG1	.DS	1	;beam 1 state toggle flag
TOG2	.DS	1	;beam 2 state toggle flag
TOG3	.DS	1	;beam 3 state toggle flag
TOG4	.DS	1	;beam 4 state toggle flag
TOG5	.DS	1	;beam 5 state toggle flag
TOG6	.DS	1	;beam 6 state toggle flag
TOG7	.DS	1	;beam 7 state toggle flag
TOG8	.DS	1	;beam 8 state toggle flag
TOG9	.DS	1	;beam 9 state toggle flag
TOG10	.DS	1	;beam 10 state toggle flag
TOG11	.DS	1	;beam 11 state toggle flag
TOG12	.DS	1	;beam 12 state toggle flag
TOG13	.DS	1	;beam 13 state toggle flag
TOG14	.DS	1	;beam 14 state toggle flag
TOG15	.DS	1	;beam 15 state toggle flag
TOG16	.DS	1	;beam 16 state toggle flag
TOG17	.DS	1	;beam 17 state toggle flag
TOG18	.DS	1	;beam 18 state toggle flag
TOG19	.DS	1	;beam 19 state toggle flag
TOG20	.DS	1	;beam 20 state toggle flag
TOG21	.DS	1	;beam 21 state toggle flag
TOG22	.DS	1	;beam 22 state toggle flag
TOG23	.DS	1	;beam 23 state toggle flag
TOG24	.DS	1	;beam 24 state toggle flag
TOG25	.DS	1	;beam 25 state toggle flag
TOG26	.DS	1	;beam 26 state toggle flag
TOG27	.DS	1	;beam 27 state toggle flag
TOG28	.DS	1	;beam 28 state toggle flag
TOG29	.DS	1	;beam 29 state toggle flag
TOG30	.DS	1	;beam 30 state toggle flag
TOG31	.DS	1	;beam 31 state toggle flag

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StLock	EQU	0
StBm	EQU	1
StVel	EQU	2
StSt	EQU	3
StNum	EQU	4
StCh	EQU	5

;--- Map application events to BIOS events

EvIdle	EQU	EV_IDLE
EvMinus	EQU	EV_SW1_ON
EvSave	EQU	EV_SW2_ON
EvSel	EQU	EV_SW3_ON
EvPlus	EQU	EV_SW4_ON

;--- Build State Matrix

	STM_BEGIN

;                 State 0:StLock State 1:StBm  State 2:StVel State 3:StSt  State 4:StNum State 5:StCh                    Not
;        Event    NextSt,Act     NextSt,Act    NextSt,Act    NextSt,Act    NextSt,Act    NextSt,Act                     Used
;        -------------------------------------------------------------------------------------------------------------------
 STM_ROW EvIdle,  StLock,SCAN,   StBm,SCAN,    StVel,SCAN,   StSt,SCAN,    StNum,SCAN,   StCh,SCAN,     StBm,IDLE, StBm,IDLE
 STM_ROW EvPlus,  StLock,SCAN,   StBm,BMINC,   StVel,VELINC, StSt,STINC,   StNum,NUMINC, StCh,CHINC,    StBm,IDLE, StBm,IDLE
 STM_ROW EvMinus, StLock,SCAN,   StBm,BMDEC,   StVel,VELDEC, StSt,STDEC,   StNum,NUMDEC, StCh,CHDEC,    StBm,IDLE, StBm,IDLE
 STM_ROW EvSel,   StBm,BARROW,   StVel,VARROW, StSt,SARROW,  StNum,NARROW, StCh,CARROW,  StLock,ARWCLR, StBm,IDLE, StBm,IDLE
 STM_ROW EvSave,  StLock,SAVE,   StLock,SAVE,  StLock,SAVE,  StLock,SAVE,  StLock,SAVE,  StLock,SAVE,   StBm,IDLE, StBm,IDLE

	STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--------------------------------
; 	Initialization
;--------------------------------

;--- Initialize variables

	clr	COL	;default column
	X1_LO		;default latch strobe for expansion board

	lda	#$FF		;default key matrix to all off to avoid turn-on blast
	sta	KEYS		;	
	sta	(KEYS+1)	;
	sta	(KEYS+2)	;
	sta	(KEYS+3)	;
	sta	(KEYS+4)	;
	sta	(KEYS+5)	;
	sta	(KEYS+6)	;
	sta	(KEYS+7)	;	

	lda	#0	;
	sta	TOG0	;
	sta	TOG1	;
	sta	TOG2	;
	sta	TOG3	;
	sta	TOG4	;
	sta	TOG5	;
	sta	TOG6	;
	sta	TOG7	;
	sta	TOG8	;
	sta	TOG9	;
	sta	TOG10	;
	sta	TOG11	;
	sta	TOG12	;
	sta	TOG13	;
	sta	TOG14	;
	sta	TOG15	;
	sta	TOG16	;
	sta	TOG17	;
	sta	TOG18	;
	sta	TOG19	;
	sta	TOG20	;
	sta	TOG21	;
	sta	TOG22	;
	sta	TOG23	;
	sta	TOG24	;
	sta	TOG25	;
	sta	TOG26	;
	sta	TOG27	;
	sta	TOG28	;
	sta	TOG29	;
	sta	TOG30	;
	sta	TOG31	;

;--- Load presets

	jsr	SW_READ	;read switches
	and	#$04	;is the SAVE key being held down?
	FAR_BEQ	LOADREG	;no? jump

	;---load factory presets

	jsr	LCD_CLEAR	;notify the user
	lda	#0	;
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " Loading...     "	;
	lda	#0	;
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " Factory Presets"	;

	lda	#$90	;load factory preset status bytes
	sta	ST0
	sta	ST1
	sta	ST2
	sta	ST3
	sta	ST4
	sta	ST5
	sta	ST6
	sta	ST7
	sta	ST8
	sta	ST9
	sta	ST10
	sta	ST11
	sta	ST12
	sta	ST13
	sta	ST14
	sta	ST15
	sta	ST16
	sta	ST17
	sta	ST18
	sta	ST19
	sta	ST20
	sta	ST21
	sta	ST22
	sta	ST23
	sta	ST24
	sta	ST25
	sta	ST26
	sta	ST27
	sta	ST28
	sta	ST29
	sta	ST30
	sta	ST31

	lda	#36	;load factory preset Data Values
	sta	NUM0
	inca
	sta	NUM1
	inca
	sta	NUM2
	inca
	sta	NUM3
	inca
	sta	NUM4
	inca
	sta	NUM5
	inca
	sta	NUM6
	inca
	sta	NUM7
	inca
	sta	NUM8
	inca
	sta	NUM9
	inca
	sta	NUM10
	inca
	sta	NUM11
	inca
	sta	NUM12
	inca
	sta	NUM13
	inca
	sta	NUM14
	inca
	sta	NUM15
	inca
	sta	NUM16
	inca
	sta	NUM17
	inca
	sta	NUM18
	inca
	sta	NUM19
	inca
	sta	NUM20
	inca
	sta	NUM21
	inca
	sta	NUM22
	inca
	sta	NUM23
	inca
	sta	NUM24
	inca
	sta	NUM25
	inca
	sta	NUM26
	inca
	sta	NUM27
	inca
	sta	NUM28
	inca
	sta	NUM29
	inca
	sta	NUM30
	inca
	sta	NUM31

	lda	#$7F	;load factory preset global Velocity
	sta	VEL

	jsr	DELAY_1SEC	;pause for user notificaiton
	jmp	DINIT	;jump to initialize the display

	;---load user presets

LOADREG:	jsr	LOAD	;load stored parameters

;--- Initialize display

DINIT:
	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "Synth A Beam II "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S " v1.0  04/28/98 "

	jsr	DELAY_1SEC

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "Beam=   Gvel=   "

	;---initial display settings

	clr	CURBM	;set current Beam Number
	lda	ST0	;load current status byte
	sta	CURST	;
	and	#$0F	;load current Channel
	sta	CURCH	;
	lda	NUM0	;load current Data Value
	sta	CURNUM	;
	jsr	ARWCLR	;set cursor for Lock state
	jsr	BDISP	;refresh display
	jsr	VDISP	;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- See if INC switch is held

INCSCROLL:	lda	#0	;reset flag
	sta	TFLAG	;
	lda	#$40	;initialize timer interrupts
	sta	TCR	; for output compare
W84SIC:	jsr	SW_READ	;read switches
	and	#$02	;make sure INC switch is still pressed
	beq	NOSCROLL	;
	lda	TFLAG	;
	cmp	#5	;
	blo	W84SIC	;
	lda	#24	;
	sta	TMSB	;
	rts

;--- See if DEC switch is held

DECSCROLL:	lda	#0	;reset flag
	sta	TFLAG	;
	lda	#$40	;initialize timer interrupts
	sta	TCR	; for output compare
W84SDC:	jsr	SW_READ	;read switches
	and	#$08	;make sure DEC switch is still pressed
	beq	NOSCROLL	;
	lda	TFLAG	;
	cmp	#5	;
	blo	W84SDC	;
	lda	#24	;
	sta	TMSB	;
	rts

	;---no longer scrolling

NOSCROLL:	lda	#0	;turn timer off
	sta	TCR	;
	lda	#$FF	;be ready for next time
	sta	TLSB	;
	sta	TMSB	;
	lda	#1	;
	sta	DUNSCROLL	;
	rts

;--- Increment Beam Number

BMINC:	lda	CURBM	;get current value
	inca		;increment
	and	#$1F	;valid range: 0-31
	sta	CURBM	;store new value
	jsr	BDISP	;update display
	jsr	INCSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	BMINC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	rts
	
;--- Decrement Beam Number

BMDEC:	lda	CURBM	;get current value
	deca		;increment
	and	#$1F	;valid range: 0-31
	sta	CURBM	;store new value
	jsr	BDISP	;update display
	jsr	DECSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	BMDEC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	rts

;--- Increment Channel

CHINC:	lda	CURCH	;get current value
	inca		;increment
	and	#$0F	;valid range: 0-15
	sta	CURCH	;store new value
	lda	CURST	;update channel in status message
	and	#$F0	;mask off old channel
	add	CURCH	;add in new channel
	sta	CURST	;save new value
	jsr	CDISP	;update display
	jsr	INCSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	CHINC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new status byte
	rts

;--- Decrement Channel

CHDEC:	lda	CURCH	;get current value
	deca		;increment
	and	#$0F	;valid range: 0-15
	sta	CURCH	;store new value
	lda	CURST	;update channel in status message
	and	#$F0	;mask off old channel
	add	CURCH	;add in new channel
	sta	CURST	;save new value
	jsr	CDISP	;update display
	jsr	DECSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	CHDEC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new status byte
	rts

;--- Increment Status Type

STINC:	lda	CURST	;get current status
	cmp	#$FA	;branch according to value
	beq	SIAC	;
	cmp	#$FB	;
	beq	SIAC	;
	cmp	#$FC	;
	beq	SIAB	;
	and	#$F0	;
	cmp	#$D0	;
	beq	SIAA	;

	;---previous status was between $9n-$Cn

	lda	CURST	;get current status
	add	#$10	;otherwise, increment
	jmp	SIAD	;

	;---previous status was $Dn

SIAA:	lda	#$FA
	jmp	SIAD

	;---previous status was $FC

SIAB:	lda	#$90
	add	CURCH	;add in current channel
	jmp	SIAD

	;---previous status was $FA or $FB

SIAC:	inca		;increment status byte

	;---new status is now in acca

SIAD:	sta	CURST	;save new assignment
	jsr	SDISP	;update display
	jsr	INCSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	FAR_BEQ	STINC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new status byte
	rts

;--- Decrement Status Type

STDEC:	lda	CURST	;get current status
	cmp	#$FB	;branch according to value
	beq	SDAC	;
	cmp	#$FC	;
	beq	SDAC	;
	cmp	#$FA	;
	beq	SDAB	;
	and	#$F0	;
	cmp	#$90	;
	beq	SDAA	;

	;---previous status was between $An-$Dn

	lda	CURST	;get current status
	sub	#$10	;otherwise, increment
	jmp	SDAD	;

	;---previous status was $9n

SDAA:	lda	#$FC
	jmp	SDAD

	;---previous status was $FA

SDAB:	lda	#$D0
	add	CURCH	;add in current channel
	jmp	SDAD

	;---previous status was $FB or $FC

SDAC:	deca		;increment status byte

	;---new status is now in acca

SDAD:	sta	CURST	;save new assignment
	jsr	SDISP	;update display
	jsr	DECSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	FAR_BEQ	STDEC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new status byte
	rts

;--- Increment Data Value

NUMINC:	lda	CURNUM	;fetch current assignment
	inca		;increment
	and	#$7F	;constrain to 0-127
	sta	CURNUM	;save new value
	jsr	NDISP	;update display
	jsr	INCSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	FAR_BEQ	NUMINC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new Data Value
	rts

;--- Decrement Data Value

NUMDEC:	lda	CURNUM	;fetch current assignment
	deca		;increment
	and	#$7F	;constrain to 0-127
	sta	CURNUM	;save new value
	jsr	NDISP	;update display
	jsr	DECSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	FAR_BEQ	NUMDEC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	jsr	STICKIT	;save new Data Value
	rts
	
;--- Increment global Velocity Value

VELINC:	lda	VEL	;get current value
	inca		;increment
	and	#$7F	;valid range: 0-127
	sta	VEL	;store new value
	jsr	VDISP	;update display
	jsr	INCSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	VELINC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	rts
	
;--- Decrement global Velocity Value

VELDEC:	lda	VEL	;get current value
	deca		;increment
	and	#$7F	;valid range: 0-31
	sta	VEL	;store new value
	jsr	VDISP	;update display
	jsr	DECSCROLL	;administer scrolling
	lda	DUNSCROLL	;check flag
	beq	VELDEC	;continue incrementing (=0)? loop...
	lda	#0	;we are done, clear flag...
	sta	DUNSCROLL	;
	rts

;---Save current status byte and number for the associated beam

STICKIT:	lda	CURST	;load current status byte for later
	ldx	CURBM	;branch off current switch
	cpx	#0	;
	FAR_BEQ	SS0	;...if Beam 0
	cpx	#1	;
	FAR_BEQ	SS1	;...if Beam 1
	cpx	#2	;
	FAR_BEQ	SS2	;...if Beam 2
	cpx	#3	;
	FAR_BEQ	SS3	;...if Beam 3
	cpx	#4	;
	FAR_BEQ	SS4	;...if Beam 4
	cpx	#5	;
	FAR_BEQ	SS5	;...if Beam 5
	cpx	#6	;
	FAR_BEQ	SS6	;...if Beam 6
	cpx	#7	;
	FAR_BEQ	SS7	;...if Beam 7
	cpx	#8	;
	FAR_BEQ	SS8	;...if Beam 8
	cpx	#9	;
	FAR_BEQ	SS9	;...if Beam 9
	cpx	#10	;
	FAR_BEQ	SS10	;...if Beam 10
	cpx	#11	;
	FAR_BEQ	SS11	;...if Beam 11
	cpx	#12	;
	FAR_BEQ	SS12	;...if Beam 12
	cpx	#13	;
	FAR_BEQ	SS13	;...if Beam 13
	cpx	#14	;
	FAR_BEQ	SS14	;...if Beam 14
	cpx	#15	;
	FAR_BEQ	SS15	;...if Beam 15
	cpx	#16	;
	FAR_BEQ	SS16	;...if Beam 16
	cpx	#17	;
	FAR_BEQ	SS17	;...if Beam 17
	cpx	#18	;
	FAR_BEQ	SS18	;...if Beam 18
	cpx	#19	;
	FAR_BEQ	SS19	;...if Beam 19
	cpx	#20	;
	FAR_BEQ	SS20	;...if Beam 20
	cpx	#21	;
	FAR_BEQ	SS21	;...if Beam 21
	cpx	#22	;
	FAR_BEQ	SS22	;...if Beam 22
	cpx	#23	;
	FAR_BEQ	SS23	;...if Beam 23
	cpx	#24	;
	FAR_BEQ	SS24	;...if Beam 24
	cpx	#25	;
	FAR_BEQ	SS25	;...if Beam 25
	cpx	#26	;
	FAR_BEQ	SS26	;...if Beam 26
	cpx	#27	;
	FAR_BEQ	SS27	;...if Beam 27
	cpx	#28	;
	FAR_BEQ	SS28	;...if Beam 28
	cpx	#29	;
	FAR_BEQ	SS29	;...if Beam 29
	cpx	#30	;
	FAR_BEQ	SS30	;...if Beam 30

SS31:	sta	ST31	;save new assignment
	lda	CURNUM	;
	sta	NUM31	;
	lda	#0	;reset latching mode flag
	sta	TOG31	;
	rts

SS0:	sta	ST0	;save new assignments
	lda	CURNUM	;
	sta	NUM0	;
	lda	#0	;reset latching mode flag
	sta	TOG0	;
	rts

SS1:	sta	ST1	;save new assignment
	lda	CURNUM	;
	sta	NUM1	;
	lda	#0	;reset latching mode flag
	sta	TOG1	;
	rts

SS2:	sta	ST2	;save new assignment
	lda	CURNUM	;
	sta	NUM2	;
	lda	#0	;reset latching mode flag
	sta	TOG2	;
	rts

SS3:	sta	ST3	;save new assignment
	lda	CURNUM	;
	sta	NUM3	;
	lda	#0	;reset latching mode flag
	sta	TOG3	;
	rts

SS4:	sta	ST4	;save new assignment
	lda	CURNUM	;
	sta	NUM4	;
	lda	#0	;reset latching mode flag
	sta	TOG4	;
	rts

SS5:	sta	ST5	;save new assignment
	lda	CURNUM	;
	sta	NUM5	;
	lda	#0	;reset latching mode flag
	sta	TOG5	;
	rts

SS6:	sta	ST6	;save new assignment
	lda	CURNUM	;
	sta	NUM6	;
	lda	#0	;reset latching mode flag
	sta	TOG6	;
	rts

SS7:	sta	ST7	;save new assignment
	lda	CURNUM	;
	sta	NUM7	;
	lda	#0	;reset latching mode flag
	sta	TOG7	;
	rts

SS8:	sta	ST8	;save new assignment
	lda	CURNUM	;
	sta	NUM8	;
	lda	#0	;reset latching mode flag
	sta	TOG8	;
	rts

SS9:	sta	ST9	;save new assignment
	lda	CURNUM	;
	sta	NUM9	;
	lda	#0	;reset latching mode flag
	sta	TOG9	;
	rts

SS10:	sta	ST10	;save new assignment
	lda	CURNUM	;
	sta	NUM10	;
	lda	#0	;reset latching mode flag
	sta	TOG10	;
	rts

SS11:	sta	ST11	;save new assignment
	lda	CURNUM	;
	sta	NUM11	;
	lda	#0	;reset latching mode flag
	sta	TOG11	;
	rts

SS12:	sta	ST12	;save new assignment
	lda	CURNUM	;
	sta	NUM12	;
	lda	#0	;reset latching mode flag
	sta	TOG12	;
	rts

SS13:	sta	ST13	;save new assignment
	lda	CURNUM	;
	sta	NUM13	;
	lda	#0	;reset latching mode flag
	sta	TOG13	;
	rts

SS14:	sta	ST14	;save new assignment
	lda	CURNUM	;
	sta	NUM14	;
	lda	#0	;reset latching mode flag
	sta	TOG14	;
	rts

SS15:	sta	ST15	;save new assignment
	lda	CURNUM	;
	sta	NUM15	;
	lda	#0	;reset latching mode flag
	sta	TOG15	;
	rts

SS16:	sta	ST16	;save new assignment
	lda	CURNUM	;
	sta	NUM16	;
	lda	#0	;reset latching mode flag
	sta	TOG16	;
	rts

SS17:	sta	ST17	;save new assignment
	lda	CURNUM	;
	sta	NUM17	;
	lda	#0	;reset latching mode flag
	sta	TOG17	;
	rts

SS18:	sta	ST18	;save new assignment
	lda	CURNUM	;
	sta	NUM18	;
	lda	#0	;reset latching mode flag
	sta	TOG18	;
	rts

SS19:	sta	ST19	;save new assignment
	lda	CURNUM	;
	sta	NUM19	;
	lda	#0	;reset latching mode flag
	sta	TOG19	;
	rts

SS20:	sta	ST20	;save new assignment
	lda	CURNUM	;
	sta	NUM20	;
	lda	#0	;reset latching mode flag
	sta	TOG20	;
	rts

SS21:	sta	ST21	;save new assignment
	lda	CURNUM	;
	sta	NUM21	;
	lda	#0	;reset latching mode flag
	sta	TOG21	;
	rts

SS22:	sta	ST22	;save new assignment
	lda	CURNUM	;
	sta	NUM22	;
	lda	#0	;reset latching mode flag
	sta	TOG22	;
	rts

SS23:	sta	ST23	;save new assignment
	lda	CURNUM	;
	sta	NUM23	;
	lda	#0	;reset latching mode flag
	sta	TOG23	;
	rts

SS24:	sta	ST24	;save new assignment
	lda	CURNUM	;
	sta	NUM24	;
	lda	#0	;reset latching mode flag
	sta	TOG24	;
	rts

SS25:	sta	ST25	;save new assignment
	lda	CURNUM	;
	sta	NUM25	;
	lda	#0	;reset latching mode flag
	sta	TOG25	;
	rts

SS26:	sta	ST26	;save new assignment
	lda	CURNUM	;
	sta	NUM26	;
	lda	#0	;reset latching mode flag
	sta	TOG26	;
	rts

SS27:	sta	ST27	;save new assignment
	lda	CURNUM	;
	sta	NUM27	;
	lda	#0	;reset latching mode flag
	sta	TOG27	;
	rts

SS28:	sta	ST28	;save new assignment
	lda	CURNUM	;
	sta	NUM28	;
	lda	#0	;reset latching mode flag
	sta	TOG28	;
	rts

SS29:	sta	ST29	;save new assignment
	lda	CURNUM	;
	sta	NUM29	;
	lda	#0	;reset latching mode flag
	sta	TOG29	;
	rts

SS30:	sta	ST30	;save new assignment
	lda	CURNUM	;
	sta	NUM30	;
	lda	#0	;reset latching mode flag
	sta	TOG30	;
	rts

;--- Update cursor for Beam Number

BARROW:	jsr	ARWCLR	;clear arrow
	lda	#4	;place arrow
	ldx	#0	;
	jsr	LCD_PUT_ARROW	;
	rts
	
;--- Update display for changing beam

BDISP:	lda	#5	;display current Beam Number
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  "	;
	lda	#5	;
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	CURBM	;get value
	inca		;display range 1-32
	jsr	LCD_PUT_I	;display it

	lda	CURBM	;branch off current beam
	cmp	#0
	FAR_BEQ	BD0
	cmp	#1
	FAR_BEQ	BD1
	cmp	#2
	FAR_BEQ	BD2
	cmp	#3
	FAR_BEQ	BD3
	cmp	#4
	FAR_BEQ	BD4
	cmp	#5
	FAR_BEQ	BD5
	cmp	#6
	FAR_BEQ	BD6
	cmp	#7
	FAR_BEQ	BD7
	cmp	#8
	FAR_BEQ	BD8
	cmp	#9
	FAR_BEQ	BD9
	cmp	#10
	FAR_BEQ	BD10
	cmp	#11
	FAR_BEQ	BD11
	cmp	#12
	FAR_BEQ	BD12
	cmp	#13
	FAR_BEQ	BD13
	cmp	#14
	FAR_BEQ	BD14
	cmp	#15
	FAR_BEQ	BD15
	cmp	#16
	FAR_BEQ	BD16
	cmp	#17
	FAR_BEQ	BD17
	cmp	#18
	FAR_BEQ	BD18
	cmp	#19
	FAR_BEQ	BD19
	cmp	#20
	FAR_BEQ	BD20
	cmp	#21
	FAR_BEQ	BD21
	cmp	#22
	FAR_BEQ	BD22
	cmp	#23
	FAR_BEQ	BD23
	cmp	#24
	FAR_BEQ	BD24
	cmp	#25
	FAR_BEQ	BD25
	cmp	#26
	FAR_BEQ	BD26
	cmp	#27
	FAR_BEQ	BD27
	cmp	#28
	FAR_BEQ	BD28
	cmp	#29
	FAR_BEQ	BD29
	cmp	#30
	FAR_BEQ	BD30

BD31:	lda	ST31
	ldx	NUM31
	jmp	BDEND

BD0:	lda	ST0
	ldx	NUM0
	jmp	BDEND

BD1:	lda	ST1
	ldx	NUM1
	jmp	BDEND

BD2:	lda	ST2
	ldx	NUM2
	jmp	BDEND

BD3:	lda	ST3
	ldx	NUM3
	jmp	BDEND

BD4:	lda	ST4
	ldx	NUM4
	jmp	BDEND

BD5:	lda	ST5
	ldx	NUM5
	jmp	BDEND

BD6:	lda	ST6
	ldx	NUM6
	jmp	BDEND

BD7:	lda	ST7
	ldx	NUM7
	jmp	BDEND

BD8:	lda	ST8
	ldx	NUM8
	jmp	BDEND

BD9:	lda	ST9
	ldx	NUM9
	jmp	BDEND

BD10:	lda	ST10
	ldx	NUM10
	jmp	BDEND

BD11:	lda	ST11
	ldx	NUM11
	jmp	BDEND

BD12:	lda	ST12
	ldx	NUM12
	jmp	BDEND

BD13:	lda	ST13
	ldx	NUM13
	jmp	BDEND

BD14:	lda	ST14
	ldx	NUM14
	jmp	BDEND

BD15:	lda	ST15
	ldx	NUM15
	jmp	BDEND

BD16:	lda	ST16
	ldx	NUM16
	jmp	BDEND

BD17:	lda	ST17
	ldx	NUM17
	jmp	BDEND

BD18:	lda	ST18
	ldx	NUM18
	jmp	BDEND

BD19:	lda	ST19
	ldx	NUM19
	jmp	BDEND

BD20:	lda	ST20
	ldx	NUM20
	jmp	BDEND

BD21:	lda	ST21
	ldx	NUM21
	jmp	BDEND

BD22:	lda	ST22
	ldx	NUM22
	jmp	BDEND

BD23:	lda	ST23
	ldx	NUM23
	jmp	BDEND

BD24:	lda	ST24
	ldx	NUM24
	jmp	BDEND

BD25:	lda	ST25
	ldx	NUM25
	jmp	BDEND

BD26:	lda	ST26
	ldx	NUM26
	jmp	BDEND

BD27:	lda	ST27
	ldx	NUM27
	jmp	BDEND

BD28:	lda	ST28
	ldx	NUM28
	jmp	BDEND

BD29:	lda	ST29
	ldx	NUM29
	jmp	BDEND

BD30:	lda	ST30
	ldx	NUM30
	jmp	BDEND

	;---acca has status byte, index has Data Value

BDEND:	stx	CURNUM	;save values
	sta	CURST
	and	#$0F
	sta	CURCH
	jsr	SDISP	;update status line display
	rts

;--- Update cursor for Status Type

SARROW:	jsr	ARWCLR	;clear arrow
	lda	#0	;place arrow
	ldx	#1	;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with entire status line

SDISP:	lda	#1	;preset the display cursor for later
	ldx	#1	;
	jsr	LCD_GOTOXY	;

	lda	CURST	;branch off current status
	cmp	#$FA	;Start message?
	FAR_BEQ	SSTART	;
	cmp	#$FB	;Continue message?
	FAR_BEQ	SCONT	;
	cmp	#$FC	;Stop message?
	FAR_BEQ	SSTOP	;
	and	#$F0	;Channel message? get status nibble
	cmp	#$90	;Note message?
	beq	SNOTE	;
	cmp	#$A0	;Latching Note message (Status=$An)?
	beq	SLNOTE	;
	cmp	#$B0	;Controller message?
	beq	SCNTL	;
	cmp	#$C0           	;Program Change message?
	beq	SPROG	;
	cmp	#$D0	;Latching Controller message (Status=$Dn)?
	FAR_BEQ	SLCNTL	;

SNOTE:	LCD_PUT_S " Note=    Ch=  "
	jmp	SRESTORE

SLNOTE:	LCD_PUT_S "LNote=    Ch=  "
	jmp	SRESTORE

SCNTL:	LCD_PUT_S " Cntl=    Ch=  "
	jmp	SRESTORE

SPROG:	LCD_PUT_S "Prgrm=    Ch=  "
	jmp	SRESTORE

SLCNTL:	LCD_PUT_S "LCntl=    Ch=  "
	jmp	SRESTORE

SSTART:	LCD_PUT_S "Start Message  "
	rts

SCONT:	LCD_PUT_S "Cont Message   "
	rts

SSTOP:	LCD_PUT_S "Stop Message   "
	rts

SRESTORE:	jsr	NDISP	;restore Data Value display
	jsr	CDISP	;restore Channel display
	rts

;--- Update cursor for Data Value

NARROW:	lda	CURST	;look at status byte
	cmp	#$F0	;
	blo	NAA	;non-realtime message? branch...

	;---realtime message in display (force state change)

	lda	#5	;jump to Lock state
	sta	STATE	;
	jsr	ARWCLR	;clear cursor for Lock state
	rts

	;---non-realtime message in display

NAA:	jsr	ARWCLR	;clear arrow
	lda	#6	;place arrow
	ldx	#1	;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with Data Value

NDISP:	lda	#7	;display current Data Value
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "	;
	lda	#7	;
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	CURNUM	;get current value
	jsr	LCD_PUT_I	;display value
	rts

;--- Update cursor for Channel display

CARROW:	jsr	ARWCLR	;clear arrow
	lda	#13	;place arrow
	ldx	#1	;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with Channel

CDISP:	lda	#14	;display current Channel
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  "	;
	lda	#14	;
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	CURCH	;get current value
	inca		;display range 1-16
	jsr	LCD_PUT_I	;display value
	rts

;--- Update cursor for Velocity Value

VARROW:	jsr	ARWCLR	;clear arrow
	lda	#12	;place arrow
	ldx	#0	;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with global Velocity value

VDISP:	lda	#13	;display current Velocity value
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "
	lda	#13	;
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	VEL	;get value
	jsr	LCD_PUT_I	;display value
	rts

;--- Clear cursor arrow

ARWCLR:	lda	#4	;clear Beam Number position
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	#' '	;
	jsr	LCD_PUT_C	;
	lda	#4	;reinsert equal sign
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	#'='	;
	jsr	LCD_PUT_C	;
	lda	#12	;clear global Velocity position
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	#' '	;
	jsr	LCD_PUT_C	;
	lda	#12	;reinsert equal sign
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	lda	#'='	;
	jsr	LCD_PUT_C	;
	lda	#0	;clear Status Type position
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	#' '	;
	jsr	LCD_PUT_C	;

	lda	CURST	;look at status byte
	cmp	#$F0	;realtime message?
	bhs	AEND	;yes? jump to end...

	;---non-realtime message in display

ARWYES:	lda	#6	;clear Data Value position
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	#' '	;
	jsr	LCD_PUT_C	;
	lda	#6	;reinsert equal sign
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	#'='	;
	jsr	LCD_PUT_C	;
	lda	#13	;clear Channel position
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	#' '	;
	jsr	LCD_PUT_C	;
	lda	#13	;reinsert equal sign
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	lda	#'='	;
	jsr	LCD_PUT_C	;
AEND:	rts

;---Send data value of zero

SENDZERO:	lda	#$00	;load value of 0
	jsr	MIDI_PUT	;send it
	rts

;---Send data value of #$7F

SEND7F:	lda	#$7F	;load value of 127
	jsr	MIDI_PUT	;send it
	rts

;---Send global Velocity value

SENDVEL:	lda	VEL	;load global Velocity value
	jsr	MIDI_PUT	;send it
	rts

;---Shifts key into position

SHFTKY:	lda	KEYCHG	;shift this key into position
	lsla		;
	sta	KEYCHG	;
	lda	OLDCOL	;
	lsla		;
	sta	OLDCOL	;
	rts

;---Computes active Beam Number (just add bit number!)

COMPUBM:	lda	COL	;yes? compute note number
	lsla		; =(8*COL+bit#)
	lsla
	lsla
	rts

;--- Scan sensors and transmit messages

SCAN:	lda	COL	;fetch column pointer
	inca		;increment
	and	#$03	;constrain to 0-3 (only 32 beams available)	;!!!!!!!!!!!!!!
	sta	COL	;save new value
	tax		;transfer column pointer to x

	lda	COLMASK,X	;select this column
	jsr	SPI_IO	;
	X1_HI		;latch data
	X1_LO		;

	RD_DATA		;load rows
	coma		;complement, we want opposite of Custom Instrument
	sta	TEMP	;buffer this temporarily

	lda	#$FF	;turn off this column
	jsr	SPI_IO 	;
	X1_HI		;latch data
	X1_LO		;

	ldx	COL	;any changes?
	lda	TEMP	;
	eor	KEYS,X	;
	cmp	#$00	;
	FAR_BEQ	SDUN	;no? branch...
	sta	KEYCHG	;yes? changes-->KEYCHG

	lda	KEYS,X	;old column status-->OLDCOL
	sta	OLDCOL	;

	lda	TEMP	;fetch new column data
	sta	KEYS,X	;update history

	;---bit 7

S7:	tst	KEYCHG	;has this key changed?
	bpl	S6	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#7	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process message

	;--- bit 6

S6:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S5	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#6	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 5

S5:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S4	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#5	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 4

S4:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S3	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#4	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 3

S3:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S2	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#3	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 2

S2:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S1	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#2	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 1

S1:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	S0	;no? branch...
	jsr	COMPUBM	;calculate Beam Number
	add	#1	;
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

	;--- bit 0

S0:	jsr	SHFTKY	;shift key into position
	tst	KEYCHG	;has this key changed?
	bpl	SDUN	;no? branch...
	jsr	COMPUBM	;compute Beam Number
	sta	BEAMNUM 	;save Beam Number
	jsr	PROCBEAM	;process

SDUN:	rts

COLMASK:	.DB $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

;---Process message

PROCBEAM:	lda	BEAMNUM	;branch off Beam Number
	cmp	#0	;
	FAR_BEQ	PB0	;
	cmp	#1	;
	FAR_BEQ	PB1	;
	cmp	#2	;
	FAR_BEQ	PB2	;
	cmp	#3	;
	FAR_BEQ	PB3	;
	cmp	#4	;
	FAR_BEQ	PB4	;
	cmp	#5	;
	FAR_BEQ	PB5	;
	cmp	#6	;
	FAR_BEQ	PB6	;
	cmp	#7	;
	FAR_BEQ	PB7	;
	cmp	#8	;
	FAR_BEQ	PB8	;
	cmp	#9	;
	FAR_BEQ	PB9	;
	cmp	#10	;
	FAR_BEQ	PB10	;
	cmp	#11	;
	FAR_BEQ	PB11	;
	cmp	#12	;
	FAR_BEQ	PB12	;
	cmp	#13	;
	FAR_BEQ	PB13	;
	cmp	#14	;
	FAR_BEQ	PB14	;
	cmp	#15	;
	FAR_BEQ	PB15	;
	cmp	#16	;
	FAR_BEQ	PB16	;
	cmp	#17	;
	FAR_BEQ	PB17	;
	cmp	#18	;
	FAR_BEQ	PB18	;
	cmp	#19	;
	FAR_BEQ	PB19	;
	cmp	#20	;
	FAR_BEQ	PB20	;
	cmp	#21	;
	FAR_BEQ	PB21	;
	cmp	#22	;
	FAR_BEQ	PB22	;
	cmp	#23	;
	FAR_BEQ	PB23	;
	cmp	#24	;
	FAR_BEQ	PB24	;
	cmp	#25	;
	FAR_BEQ	PB25	;
	cmp	#26	;
	FAR_BEQ	PB26	;
	cmp	#27	;
	FAR_BEQ	PB27	;
	cmp	#28	;
	FAR_BEQ	PB28	;
	cmp	#29	;
	FAR_BEQ	PB29	;
	cmp	#30	;
	FAR_BEQ	PB30	;

	;---process beam 31

PB31:	lda	ST31	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM31	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG31	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG31	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 0

PB0:	lda	ST0	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM0	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG0	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG0	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 1

PB1:	lda	ST1	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM1	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG1	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG1	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 2

PB2:	lda	ST2	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM2	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG2	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG2	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 3

PB3:	lda	ST3	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM3	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG3	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG3	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 4

PB4:	lda	ST4	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM4	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG4	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG4	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 5

PB5:	lda	ST5	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM5	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG5	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG5	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 6

PB6:	lda	ST6	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM6	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG6	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG6	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 7

PB7:	lda	ST7	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM7	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG7	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG7	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 8

PB8:	lda	ST8	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM8	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG8	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG8	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 9

PB9:	lda	ST9	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM9	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG9	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG9	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 10

PB10:	lda	ST10	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM10	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG10	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG10	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 11

PB11:	lda	ST11	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM11	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG11	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG11	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 12

PB12:	lda	ST12	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM12	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG12	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG12	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 13

PB13:	lda	ST13	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM13	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG13	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG13	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 14

PB14:	lda	ST14	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM14	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG14	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG14	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 15

PB15:	lda	ST15	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM15	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG15	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG15	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 16

PB16:	lda	ST16	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM16	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG16	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG16	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 17

PB17:	lda	ST17	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM17	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG17	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG17	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 18

PB18:	lda	ST18	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM18	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG18	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG18	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 19

PB19:	lda	ST19	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM19	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG19	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG19	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 20

PB20:	lda	ST20	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM20	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG20	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG20	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 21

PB21:	lda	ST21	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM21	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG21	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG21	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 22

PB22:	lda	ST22	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM22	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG22	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG22	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 23

PB23:	lda	ST23	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM23	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG23	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG23	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 24

PB24:	lda	ST24	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM24	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG24	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG24	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 25

PB25:	lda	ST25	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM25	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	FAR_BPL	GMOFF	;on-to-off transition? jump...
	lda	TOG25	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG25	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 26

PB26:	lda	ST26	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM26	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	bpl	GMOFF	;on-to-off transition? jump...
	lda	TOG26	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG26	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 27

PB27:	lda	ST27	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM27	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	bpl	GMOFF	;on-to-off transition? jump...
	lda	TOG27	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG27	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 28

PB28:	lda	ST28	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM28	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	bpl	GMOFF	;on-to-off transition? jump...
	lda	TOG28	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG28	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 29

PB29:	lda	ST29	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM29	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	bpl	GMOFF	;on-to-off transition? jump...
	lda	TOG29	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG29	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

	;---process beam 30

PB30:	lda	ST30	;load status byte for this beam
	sta	TEMPST	;save for later
	lda	NUM30	;load Data Value for this beam
	sta	TEMPNUM	;save	for later
	tst	OLDCOL	;test the column
	bpl	GMOFF	;on-to-off transition? jump...
	lda	TOG30	;off-to-on? load variable
	eor	#$01	;toggle it
	sta	TOG30	;save new value
	sta	TEMPTOG	;save as temporary value
	jmp	GMON	;process on message

;---Send the message for on-to-off beam transition
;---(status byte is in TEMPST, Data Value is in TEMPNUM, latch status in TEMPTOG)

GMOFF:	lda	TEMPST	;get status byte
	and	#$F0	;mask off channel
	cmp	#$90	;is it a Note message?
	beq	GMOFFNOW	;if yes, branch...
	cmp	#$B0	;is it a Controller message?
	beq	GMOFFNOW	;if yes, branch...
	rts

GMOFFNOW:	lda	TEMPST	;get status byte
	jsr	MIDI_PUT	;send it
	lda	TEMPNUM	;get Data Value
	jsr	MIDI_PUT	;send it
	jsr	SENDZERO	;send value of 0
	rts

;---Send the message for off-to-on beam transition
;---(status byte is in TEMPST, Data Value is in TEMPNUM, latch status in TEMPTOG)

GMON:	lda	TEMPST	;get status byte
	and	#$F0	;mask off channel
	cmp	#$A0	;is it LNote?
	bne	GMONA	;no? branch...

	;---it is LNote

	lda	TEMPST	;get status byte
	sub	#$10	;shift it to Note on message
	jsr	MIDI_PUT	;send it
	jmp	GMONC	;jump to send Data Value

GMONA:	cmp	#$D0	;is it LCtl?
	bne	GMONB	;no? branch...

	;---it is LCtl

	lda	TEMPST	;get status byte
	sub	#$20	;shift it to a controller message
	jsr	MIDI_PUT	;send it
	jmp	GMONC	;jump to send data value

	;---it is not LNote or LCtl, send status byte as is

GMONB:	lda	TEMPST	;get status byte
	jsr	MIDI_PUT	;send it
	lda	TEMPST	;
	cmp	#$DF	;realtime message?
	FAR_BHI	GMDUN	;if yes, move on...

	;---send Data Value byte (second byte)

GMONC:	lda	TEMPNUM	;otherwise, load Data Value
	jsr	MIDI_PUT	;send it

	;---send third byte

	lda	TEMPST	;load status again
	and	#$F0	;mask off channel
	cmp	#$C0	;is it a program change message?
	FAR_BEQ	GMDUN	;if yes, move on...
	cmp	#$A0	;is it a LNote message?
	beq	TOGVAL0N	;if yes, process according to the beam state value
	cmp	#$D0	;is it a LCntl message?
	beq	TOGVAL0C	;if yes, process according to the beam state value
	cmp	#$B0	;is it a controller message?
	beq	GMCC	;
	jsr	SENDVEL	;otherwise, send global Velocity value
	rts		;move on...

GMCC:	jsr	SEND7F	;send value 127
	rts

TOGVAL0N:	lda	TEMPTOG	;get state value
	beq	TGVA	;time for an off value?
	jsr	SENDVEL	;time for an on value? send global Velocity value
	rts		;

TOGVAL0C:	lda	TEMPTOG	;get state value
	beq	TGVA	;time for an off value?
	jsr	SEND7F	;time for an on value? send max value of 127
	rts		;move on...

TGVA:	jsr	SENDZERO	;jump if state is now off
GMDUN:	rts

;--- Save all parameters

SAVE:	jsr	LCD_CLEAR	;notify the user
	lda	#0	;
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " Storing...     "	;
	lda	#0	;
	ldx	#1	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " User Settings  "	;

	lda	#0	;
	jsr	EE_READ	;fetch value
	cmp	ST0	;compare
	beq	SV1	;not changed? move on...
	lda	#0
	ldx	ST0
	jsr	EE_WRITE	;store it

SV1:	lda	#1	;
	jsr	EE_READ 	;fetch value
	cmp	ST1	;compare
	beq	SV2	;not changed? move on...
	lda	#1
	ldx	ST1
	jsr	EE_WRITE	;store it

SV2:	lda	#2	;
	jsr	EE_READ 	;fetch value
	cmp	ST2	;compare
	beq	SV3	;not changed? move on...
	lda	#2
	ldx	ST2
	jsr	EE_WRITE	;store it

SV3:	lda	#3	;
	jsr	EE_READ 	;fetch value
	cmp	ST3	;compare
	beq	SV4	;not changed? move on...
	lda	#3
	ldx	ST3
	jsr	EE_WRITE	;store it

SV4:	lda	#4	;
	jsr	EE_READ 	;fetch value
	cmp	ST4	;compare
	beq	SV5	;not changed? move on...
	lda	#4
	ldx	ST4
	jsr	EE_WRITE	;store it

SV5:	lda	#5	;
	jsr	EE_READ 	;fetch value
	cmp	ST5	;compare
	beq	SV6	;not changed? move on...
	lda	#5
	ldx	ST5
	jsr	EE_WRITE	;store it

SV6:	lda	#6	;
	jsr	EE_READ 	;fetch value
	cmp	ST6	;compare
	beq	SV7	;not changed? move on...
	lda	#6
	ldx	ST6
	jsr	EE_WRITE	;store it

SV7:	lda	#7	;
	jsr	EE_READ 	;fetch value
	cmp	ST7	;compare
	beq	SV8	;not changed? move on...
	lda	#7
	ldx	ST7
	jsr	EE_WRITE	;store it

SV8:	lda	#8	;
	jsr	EE_READ 	;fetch value
	cmp	ST8	;compare
	beq	SV9	;not changed? move on...
	lda	#8
	ldx	ST8
	jsr	EE_WRITE	;store it

SV9:	lda	#9	;
	jsr	EE_READ 	;fetch value
	cmp	ST9	;compare
	beq	SV10	;not changed? move on...
	lda	#9
	ldx	ST9
	jsr	EE_WRITE	;store it

SV10:	lda	#10	;
	jsr	EE_READ 	;fetch value
	cmp	ST10	;compare
	beq	SV11	;not changed? move on...
	lda	#10
	ldx	ST10
	jsr	EE_WRITE	;store it

SV11:	lda	#11	;
	jsr	EE_READ 	;fetch value
	cmp	ST11	;compare
	beq	SV12	;not changed? move on...
	lda	#11
	ldx	ST11
	jsr	EE_WRITE	;store it

SV12:	lda	#12	;
	jsr	EE_READ 	;fetch value
	cmp	ST12	;compare
	beq	SV13	;not changed? move on...
	lda	#12
	ldx	ST12
	jsr	EE_WRITE	;store it

SV13:	lda	#13	;
	jsr	EE_READ 	;fetch value
	cmp	ST13	;compare
	beq	SV14	;not changed? move on...
	lda	#13
	ldx	ST13
	jsr	EE_WRITE	;store it

SV14:	lda	#14	;
	jsr	EE_READ 	;fetch value
	cmp	ST14	;compare
	beq	SV15	;not changed? move on...
	lda	#14
	ldx	ST14
	jsr	EE_WRITE	;store it

SV15:	lda	#15	;
	jsr	EE_READ 	;fetch value
	cmp	ST15	;compare
	beq	SV16	;not changed? move on...
	lda	#15
	ldx	ST15
	jsr	EE_WRITE	;store it

SV16:	lda	#16	;
	jsr	EE_READ 	;fetch value
	cmp	ST16	;compare
	beq	SV17	;not changed? move on...
	lda	#16
	ldx	ST16
	jsr	EE_WRITE	;store it

SV17:	lda	#17	;
	jsr	EE_READ 	;fetch value
	cmp	ST17	;compare
	beq	SV18	;not changed? move on...
	lda	#17
	ldx	ST17
	jsr	EE_WRITE	;store it

SV18:	lda	#18	;
	jsr	EE_READ 	;fetch value
	cmp	ST18	;compare
	beq	SV19	;not changed? move on...
	lda	#18
	ldx	ST18
	jsr	EE_WRITE	;store it

SV19:	lda	#19	;
	jsr	EE_READ 	;fetch value
	cmp	ST19	;compare
	beq	SV20	;not changed? move on...
	lda	#19
	ldx	ST19
	jsr	EE_WRITE	;store it

SV20:	lda	#20	;
	jsr	EE_READ 	;fetch value
	cmp	ST20	;compare
	beq	SV21	;not changed? move on...
	lda	#20
	ldx	ST20
	jsr	EE_WRITE	;store it

SV21:	lda	#21	;
	jsr	EE_READ 	;fetch value
	cmp	ST21	;compare
	beq	SV22	;not changed? move on...
	lda	#21
	ldx	ST21
	jsr	EE_WRITE	;store it

SV22:	lda	#22	;
	jsr	EE_READ 	;fetch value
	cmp	ST22	;compare
	beq	SV23	;not changed? move on...
	lda	#22
	ldx	ST22
	jsr	EE_WRITE	;store it

SV23:	lda	#23	;
	jsr	EE_READ 	;fetch value
	cmp	ST23	;compare
	beq	SV24	;not changed? move on...
	lda	#23
	ldx	ST23
	jsr	EE_WRITE	;store it

SV24:	lda	#24	;
	jsr	EE_READ 	;fetch value
	cmp	ST24	;compare
	beq	SV25	;not changed? move on...
	lda	#24
	ldx	ST24
	jsr	EE_WRITE	;store it

SV25:	lda	#25	;
	jsr	EE_READ 	;fetch value
	cmp	ST25	;compare
	beq	SV26	;not changed? move on...
	lda	#25
	ldx	ST25
	jsr	EE_WRITE	;store it

SV26:	lda	#26	;
	jsr	EE_READ 	;fetch value
	cmp	ST26	;compare
	beq	SV27	;not changed? move on...
	lda	#26
	ldx	ST26
	jsr	EE_WRITE	;store it

SV27:	lda	#27	;
	jsr	EE_READ 	;fetch value
	cmp	ST27	;compare
	beq	SV28	;not changed? move on...
	lda	#27
	ldx	ST27
	jsr	EE_WRITE	;store it

SV28:	lda	#28	;
	jsr	EE_READ 	;fetch value
	cmp	ST28	;compare
	beq	SV29	;not changed? move on...
	lda	#28
	ldx	ST28
	jsr	EE_WRITE	;store it

SV29:	lda	#29	;
	jsr	EE_READ 	;fetch value
	cmp	ST29	;compare
	beq	SV30	;not changed? move on...
	lda	#29
	ldx	ST29
	jsr	EE_WRITE	;store it

SV30:	lda	#30	;
	jsr	EE_READ 	;fetch value
	cmp	ST30	;compare
	beq	SV31	;not changed? move on...
	lda	#30
	ldx	ST30
	jsr	EE_WRITE	;store it

SV31:	lda	#31	;
	jsr	EE_READ 	;fetch value
	cmp	ST31	;compare
	beq	SV32	;not changed? move on...
	lda	#31
	ldx	ST31
	jsr	EE_WRITE	;store it

SV32:	lda	#32	;
	jsr	EE_READ 	;fetch value
	cmp	NUM0	;compare
	beq	SV33	;not changed? move on...
	lda	#32
	ldx	NUM0
	jsr	EE_WRITE	;store it

SV33:	lda	#33	;
	jsr	EE_READ 	;fetch value
	cmp	NUM1	;compare
	beq	SV34	;not changed? move on...
	lda	#33
	ldx	NUM1
	jsr	EE_WRITE	;store it

SV34:	lda	#34	;
	jsr	EE_READ 	;fetch value
	cmp	NUM2	;compare
	beq	SV35	;not changed? move on...
	lda	#34
	ldx	NUM2
	jsr	EE_WRITE	;store it

SV35:	lda	#35	;
	jsr	EE_READ 	;fetch value
	cmp	NUM3	;compare
	beq	SV36	;not changed? move on...
	lda	#35
	ldx	NUM3
	jsr	EE_WRITE	;store it

SV36:	lda	#36	;
	jsr	EE_READ 	;fetch value
	cmp	NUM4	;compare
	beq	SV37		;not changed? move on...
	lda	#36
	ldx	NUM4
	jsr	EE_WRITE	;store it

SV37:	lda	#37	;
	jsr	EE_READ 	;fetch value
	cmp	NUM5	;compare
	beq	SV38	;not changed? move on...
	lda	#37
	ldx	NUM5
	jsr	EE_WRITE	;store it

SV38:	lda	#38	;
	jsr	EE_READ 	;fetch value
	cmp	NUM6	;compare
	beq	SV39	;not changed? move on...
	lda	#38
	ldx	NUM6
	jsr	EE_WRITE	;store it

SV39:	lda	#39	;
	jsr	EE_READ 	;fetch value
	cmp	NUM7	;compare
	beq	SV40	;not changed? move on...
	lda	#39
	ldx	NUM7
	jsr	EE_WRITE	;store it

SV40:	lda	#40	;
	jsr	EE_READ 	;fetch value
	cmp	NUM8	;compare
	beq	SV41	;not changed? move on...
	lda	#40
	ldx	NUM8
	jsr	EE_WRITE	;store it

SV41:	lda	#41	;
	jsr	EE_READ 	;fetch value
	cmp	NUM9	;compare
	beq	SV42	;not changed? move on...
	lda	#41
	ldx	NUM9
	jsr	EE_WRITE	;store it

SV42:	lda	#42	;
	jsr	EE_READ 	;fetch value
	cmp	NUM10	;compare
	beq	SV43	;not changed? move on...
	lda	#42
	ldx	NUM10
	jsr	EE_WRITE	;store it

SV43:	lda	#43	;
	jsr	EE_READ 	;fetch value
	cmp	NUM11	;compare
	beq	SV44	;not changed? move on...
	lda	#43
	ldx	NUM11
	jsr	EE_WRITE	;store it

SV44:	lda	#44	;
	jsr	EE_READ 	;fetch value
	cmp	NUM12	;compare
	beq	SV45	;not changed? move on...
	lda	#44
	ldx	NUM12
	jsr	EE_WRITE	;store it

SV45:	lda	#45	;
	jsr	EE_READ 	;fetch value
	cmp	NUM13	;compare
	beq	SV46	;not changed? move on...
	lda	#45
	ldx	NUM13
	jsr	EE_WRITE	;store it

SV46:	lda	#46	;
	jsr	EE_READ 	;fetch value
	cmp	NUM14	;compare
	beq	SV47	;not changed? move on...
	lda	#46
	ldx	NUM14
	jsr	EE_WRITE	;store it

SV47:	lda	#47	;
	jsr	EE_READ 	;fetch value
	cmp	NUM15	;compare
	beq	SV48	;not changed? move on...
	lda	#47
	ldx	NUM15
	jsr	EE_WRITE	;store it

SV48:	lda	#48	;
	jsr	EE_READ 	;fetch value
	cmp	NUM16	;compare
	beq	SV49	;not changed? move on...
	lda	#48
	ldx	NUM16
	jsr	EE_WRITE	;store it

SV49:	lda	#49	;
	jsr	EE_READ 	;fetch value
	cmp	NUM17	;compare
	beq	SV50	;not changed? move on...
	lda	#49
	ldx	NUM17
	jsr	EE_WRITE	;store it

SV50:	lda	#50	;
	jsr	EE_READ 	;fetch value
	cmp	NUM18	;compare
	beq	SV51	;not changed? move on...
	lda	#50
	ldx	NUM18
	jsr	EE_WRITE	;store it

SV51:	lda	#51	;
	jsr	EE_READ 	;fetch value
	cmp	NUM19	;compare
	beq	SV52	;not changed? move on...
	lda	#51
	ldx	NUM19
	jsr	EE_WRITE	;store it

SV52:	lda	#52	;
	jsr	EE_READ 	;fetch value
	cmp	NUM20	;compare
	beq	SV53	;not changed? move on...
	lda	#52
	ldx	NUM20
	jsr	EE_WRITE	;store it

SV53:	lda	#53	;
	jsr	EE_READ 	;fetch value
	cmp	NUM21	;compare
	beq	SV54	;not changed? move on...
	lda	#53
	ldx	NUM21
	jsr	EE_WRITE	;store it

SV54:	lda	#54	;
	jsr	EE_READ 	;fetch value
	cmp	NUM22	;compare
	beq	SV55	;not changed? move on...
	lda	#54
	ldx	NUM22
	jsr	EE_WRITE	;store it

SV55:	lda	#55	;
	jsr	EE_READ 	;fetch value
	cmp	NUM23	;compare
	beq	SV56	;not changed? move on...
	lda	#55
	ldx	NUM23
	jsr	EE_WRITE	;store it

SV56:	lda	#56	;
	jsr	EE_READ 	;fetch value
	cmp	NUM24	;compare
	beq	SV57	;not changed? move on...
	lda	#56
	ldx	NUM24
	jsr	EE_WRITE	;store it

SV57:	lda	#57	;
	jsr	EE_READ 	;fetch value
	cmp	NUM25	;compare
	beq	SV58	;not changed? move on...
	lda	#57
	ldx	NUM25
	jsr	EE_WRITE	;store it

SV58:	lda	#58	;
	jsr	EE_READ 	;fetch value
	cmp	NUM26	;compare
	beq	SV59	;not changed? move on...
	lda	#58
	ldx	NUM26
	jsr	EE_WRITE	;store it

SV59:	lda	#59	;
	jsr	EE_READ 	;fetch value
	cmp	NUM27	;compare
	beq	SV60	;not changed? move on...
	lda	#59
	ldx	NUM27
	jsr	EE_WRITE	;store it

SV60:	lda	#60	;
	jsr	EE_READ 	;fetch value
	cmp	NUM28	;compare
	beq	SV61	;not changed? move on...
	lda	#60
	ldx	NUM28
	jsr	EE_WRITE	;store it

SV61:	lda	#61	;
	jsr	EE_READ 	;fetch value
	cmp	NUM29	;compare
	beq	SV62	;not changed? move on...
	lda	#61
	ldx	NUM29
	jsr	EE_WRITE	;store it

SV62:	lda	#62	;
	jsr	EE_READ 	;fetch value
	cmp	NUM30	;compare
	beq	SV63	;not changed? move on...
	lda	#62
	ldx	NUM30
	jsr	EE_WRITE	;store it

SV63:	lda	#63	;
	jsr	EE_READ 	;fetch value
	cmp	NUM31	;compare
	beq	SV64	;not changed? move on...
	lda	#63
	ldx	NUM31
	jsr	EE_WRITE	;store it

SV64:	lda	#64	;
	jsr	EE_READ 	;fetch value
	cmp	VEL	;compare
	beq	SVEND	;not changed? move on...
	lda	#64
	ldx	VEL
	jsr	EE_WRITE	;store it

SVEND:	jsr	DELAY_1SEC	;pause for user display
	lda	#0	;restore display
	ldx	#0	;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Beam=   Gvel=   "	;
	jsr	BDISP	;
	jsr	VDISP	;
	rts

;---Load user presets

LOAD:	lda	#0	;
	jsr	EE_READ 	;fetch value
	sta	ST0	;store value
	lda	#1	;
	jsr	EE_READ 	;fetch value
	sta	ST1	;store value
	lda	#2	;
	jsr	EE_READ 	;fetch value
	sta	ST2	;store value
	lda	#3	;
	jsr	EE_READ 	;fetch value
	sta	ST3	;store value
	lda	#4	;
	jsr	EE_READ 	;fetch value
	sta	ST4	;store value
	lda	#5	;
	jsr	EE_READ 	;fetch value
	sta	ST5	;store value
	lda	#6	;
	jsr	EE_READ 	;fetch value
	sta	ST6	;store value
	lda	#7	;
	jsr	EE_READ 	;fetch value
	sta	ST7	;store value
	lda	#8	;
	jsr	EE_READ 	;fetch value
	sta	ST8	;store value
	lda	#9	;
	jsr	EE_READ 	;fetch value
	sta	ST9	;store value
	lda	#10	;
	jsr	EE_READ 	;fetch value
	sta	ST10	;store value
	lda	#11	;
	jsr	EE_READ 	;fetch value
	sta	ST11	;store value
	lda	#12	;
	jsr	EE_READ 	;fetch value
	sta	ST12	;store value
	lda	#13	;
	jsr	EE_READ 	;fetch value
	sta	ST13	;store value
	lda	#14	;
	jsr	EE_READ 	;fetch value
	sta	ST14	;store value
	lda	#15	;
	jsr	EE_READ 	;fetch value
	sta	ST15	;store value
	lda	#16	;
	jsr	EE_READ 	;fetch value
	sta	ST16	;store value
	lda	#17	;
	jsr	EE_READ 	;fetch value
	sta	ST17	;store value
	lda	#18	;
	jsr	EE_READ 	;fetch value
	sta	ST18	;store value
	lda	#19	;
	jsr	EE_READ 	;fetch value
	sta	ST19	;store value
	lda	#20	;
	jsr	EE_READ 	;fetch value
	sta	ST20	;store value
	lda	#21	;
	jsr	EE_READ 	;fetch value
	sta	ST21	;store value
	lda	#22	;
	jsr	EE_READ 	;fetch value
	sta	ST22	;store value
	lda	#23	;
	jsr	EE_READ 	;fetch value
	sta	ST23	;store value
	lda	#24	;
	jsr	EE_READ 	;fetch value
	sta	ST24	;store value
	lda	#25	;
	jsr	EE_READ 	;fetch value
	sta	ST25	;store value
	lda	#26	;
	jsr	EE_READ 	;fetch value
	sta	ST26	;store value
	lda	#27	;
	jsr	EE_READ 	;fetch value
	sta	ST27	;store value
	lda	#28	;
	jsr	EE_READ 	;fetch value
	sta	ST28	;store value
	lda	#29	;
	jsr	EE_READ 	;fetch value
	sta	ST29	;store value
	lda	#30	;
	jsr	EE_READ 	;fetch value
	sta	ST30	;store value
	lda	#31	;
	jsr	EE_READ 	;fetch value
	sta	ST31	;store value
	lda	#32	;
	jsr	EE_READ 	;fetch value
	sta	NUM0	;store value
	lda	#33	;
	jsr	EE_READ 	;fetch value
	sta	NUM1	;store value
	lda	#34	;
	jsr	EE_READ 	;fetch value
	sta	NUM2	;store value
	lda	#35	;
	jsr	EE_READ 	;fetch value
	sta	NUM3	;store value
	lda	#36	;
	jsr	EE_READ 	;fetch value
	sta	NUM4	;store value
	lda	#37	;
	jsr	EE_READ 	;fetch value
	sta	NUM5	;store value
	lda	#38	;
	jsr	EE_READ 	;fetch value
	sta	NUM6	;store value
	lda	#39	;
	jsr	EE_READ 	;fetch value
	sta	NUM7	;store value
	lda	#40	;
	jsr	EE_READ 	;fetch value
	sta	NUM8	;store value
	lda	#41	;
	jsr	EE_READ 	;fetch value
	sta	NUM9	;store value
	lda	#42	;
	jsr	EE_READ 	;fetch value
	sta	NUM10	;store value
	lda	#43	;
	jsr	EE_READ 	;fetch value
	sta	NUM11	;store value
	lda	#44	;
	jsr	EE_READ 	;fetch value
	sta	NUM12	;store value
	lda	#45	;
	jsr	EE_READ 	;fetch value
	sta	NUM13	;store value
	lda	#46	;
	jsr	EE_READ 	;fetch value
	sta	NUM14	;store value
	lda	#47	;
	jsr	EE_READ 	;fetch value
	sta	NUM15	;store value
	lda	#48	;
	jsr	EE_READ 	;fetch value
	sta	NUM16	;store value
	lda	#49	;
	jsr	EE_READ 	;fetch value
	sta	NUM17	;store value
	lda	#50	;
	jsr	EE_READ 	;fetch value
	sta	NUM18	;store value
	lda	#51	;
	jsr	EE_READ 	;fetch value
	sta	NUM19	;store value
	lda	#52	;
	jsr	EE_READ 	;fetch value
	sta	NUM20	;store value
	lda	#53	;
	jsr	EE_READ 	;fetch value
	sta	NUM21	;store value
	lda	#54	;
	jsr	EE_READ 	;fetch value
	sta	NUM22	;store value
	lda	#55	;
	jsr	EE_READ 	;fetch value
	sta	NUM23	;store value
	lda	#56	;
	jsr	EE_READ 	;fetch value
	sta	NUM24	;store value
	lda	#57	;
	jsr	EE_READ 	;fetch value
	sta	NUM25	;store value
	lda	#58	;
	jsr	EE_READ 	;fetch value
	sta	NUM26	;store value
	lda	#59	;
	jsr	EE_READ 	;fetch value
	sta	NUM27	;store value
	lda	#60	;
	jsr	EE_READ 	;fetch value
	sta	NUM28	;store value
	lda	#61	;
	jsr	EE_READ 	;fetch value
	sta	NUM29	;store value
	lda	#62	;
	jsr	EE_READ 	;fetch value
	sta	NUM30	;store value
	lda	#63	;
	jsr	EE_READ 	;fetch value
	sta	NUM31	;store value
	lda	#64	;
	jsr	EE_READ 	;fetch value
	sta	VEL	;store value
	rts

;----------------------------------------------------------------
;	Interrupt Call Backs
;----------------------------------------------------------------

	IGNORE_IRQ_SWI_SPI

TIMER_CBCK:

	;---setup timer registers for next time-out

	lda	TLSB	;compute and store next output
	add	OCRLSB	; compare register value
	sta	TEMPOCRLSB	;
	lda	TMSB	;OCR MSB is 1024
	adc	OCRMSB	;
	sta	OCRMSB	;
	lda	TSR	;neccesary to clear OCF flag

	lda	TEMPOCRLSB	;
	sta	OCRLSB	;
	lda	TFLAG	;bump timer flag
	inca		;
	sta	TFLAG	;
	rti

SCI_TX_CBCK:
	jmp     SCI_TX_CBCK_RET


