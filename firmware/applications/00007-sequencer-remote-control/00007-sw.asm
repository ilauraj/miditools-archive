;===============================================================;
;								;
;       TOOL06.ASM      Rev 1.0  29-Aug-93                      ;
;	Sequencer Remote Control				;
;								;
;	The user can remotely control sequencer playback	;
;	functions.						;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...PREPARE MY SEQUENCER?				;
;	Following the sequencer's instruction manual, enter     ;
;	CHASE LOCK MODE.					;
;								;
;								;
;	...CONFIGURE THE REMOTE CONTROL FOR MY SEQUENCE?	;
;	Press the SETUP key.  The time signature is entered	;
;       using the NUM and DEN keys.  The song tempo is entered  ;
;	with the VALUE fader.  Fader function is indicated by	;
;       the FADER LEDs.  Tempo is given in quarter notes per    ;
;	minute (QPM).						;
;								;
;								;
;	...PLAY THE SEQUENCE FROM THE BEGINNING?		;
;	Press the START key.  The sequence plays from the	;
;       first measure.  The tempo can be adjusted during        ;
;	playback with the +/- keys.  While playing, the LCD	;
;	gives the current song measure and beat.		;
;								;
;								;
;	...STOP THE SEQUENCER?					;
;	Press the STOP key.  The LCD gives the last song	;
;	measure and beat.					;
;								;
;								;
;	...SHUTTLE THE SEQUENCER TO A SPECIFIC MEASURE? 	;
;	While stopped, the user can move to any measure using	;
;	the +/- keys and/or the VALUE fader.  Song position	;
;	can be set to any measure between 1-256.  Fader 	;
;	function is indicated by the FADER LEDs.		;
;								;
;								;
;	...CONTINUE PLAYBACK FROM THE CURRENT MEASURE?		;
;	Press the CONT key.  The sequence will play from the	;
;       current measure.  While playing, tempo can be adjusted  ;
;	with the +/- keys.  The LCD gives the current song	;
;	position.						;
;								;
;								;
;	...USE THE MARKER TO SAVE A MEASURE NUMBER?		;
;	At any time, pressing the MARK key will save the	;
;	current song measure number for jumping or looping.	;
;	The LCD gives the number of the marked measure. 	;
;								;
;								;
;	...JUMP TO THE MARKED MEASURE AND CONTINUE PLAYBACK?	;
;	While the sequencer is stopped, press the JUMP key.	;
;	The sequencer will jump to the marked measure and	;
;	resume playback.					;
;								;
;								;
;	...ENTER LOOP PLAY MODE?				;
;	While the sequence is playing, press the JUMP key.	;
;	The sequence will loop continuously between the marked	;
;	measure and the current measure.  The loop starting	;
;	measure is given in the LCD MRK display.		;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When the SETUP key is pressed,				;
;								;
;	|TIME SIG MRK QPM|	where nn=1-16, dd=1,2,4,8	;
;	| nn/dd   eee bbb|	or 16, bbb=20-255, eee=1-256	;
;								;
;								;
;	When any other key is pressed,				;
;								;
;	|status   MRK QPM|	where eee=1-256, ff=1-16,	;
;	|eee:ff   eee bbb|	bbb=20-255, status="PLAYING",   ;
;				"STOPPED", "LOOPING" or         ;
;				"...wait"                       ;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI ports used: OUT only.		;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;       StSet           Set tempo and time signature            ;
;	StSht		Shuttle to new location 		;
;	StPly		Play sequence				;
;								;
;	Actions:						;
;								;
;	IDLE		No action (administer loop function)	;
;	NUMINC		Increment numerator of time sig 	;
;	DENINC		Change denominator of time sig		;
;       TEMINC          Increment tempo                         ;
;       TEMDEC          Decrement tempo                         ;
;       TEMFDR          Set tempo with fader                    ;
;	MEAINC		Increment song measure			;
;	MEADEC		Decrement song measure			;
;	MEAFDR		Set song measure with fader		;
;	STOP		Stop the sequence			;
;	START		Play the sequence from the beginning	;
;	CONT		Play sequence from current measure/beat ;
;	MARK		Mark the current song measure		;
;	JUMP		Jump to the marked measure and play	;
;	LOOP		Jump to the marked measure and loop	;
;	STDISP		Update display for setup		;
;	NMDISP		Display time signature numerator	;
;	DNDISP		Display time signature denominator	;
;	NRDISP		Update display for normal operation	;
;	MSDISP		Display song measure			;
;	BTDISP		Display song beat			;
;       TMDISP          Display tempo                           ;
;	MKDISP		Display marked measure			;
;	MGDISP		Display status message			;
;       LEDTEM          Control tempo fader function LED        ;
;	LEDMEA		Control measure fader function LED	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;These codes specify status stored in the MESSAGE variable

MSG_STOP	VAR	0	;code for when stopped
MSG_PLAY	VAR	1	;code for when playing
MSG_LOOP	VAR	2	;code for when looping
MSG_WAIT	VAR	3	;code for when waiting

MSG_MIN 	VAR	0	;minimum
MSG_MAX 	VAR	3	;maximum

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

NUMER		.DS	1	;time signature numerator
DENOM		.DS	1	;time signature denominator
MESSAGE 	.DS	1	;playback status message
MARKER		.DS	1	;marked measure
LOOPEND 	.DS	1	;measure at loop end
LOOPFLAG	.DS	1	;loop status flag (0=off,1=on)
LOOPNOT 	.DS	1	;loop control flag (0=restart)

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StSet		EQU	0
StSht		EQU	1
StPly		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvSetup 	EQU	EV_SW1_ON
EvMark		EQU	EV_SW2_ON
EvJump		EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvStart 	EQU	EV_SW5_ON
EvStop		EQU	EV_SW6_ON
EvCont		EQU	EV_SW7_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StSet State 1:StSht State 2:StPly        Not
;	 Event	  NextSt,Act	NextSt,Act    NextSt,Act	  Used
;	 -------------------------------------------------------------
 STM_ROW EvIdle,  StSet,IDLE,	StSht,IDLE,   StPly,IDLE,   StSet,IDLE
 STM_ROW EvPlus,  StSet,NUMINC, StSht,MEAINC, StPly,TEMINC, StSet,IDLE
 STM_ROW EvMinus, StSet,DENINC, StSht,MEADEC, StPly,TEMDEC, StSet,IDLE
 STM_ROW EvValue, StSet,TEMFDR, StSht,MEAFDR, StPly,IDLE,   StSet,IDLE
 STM_ROW EvSetup, StSet,IDLE,	StSet,STDISP, StSet,STDISP, StSet,IDLE
 STM_ROW EvMark,  StSht,NRDISP, StSht,MARK,   StPly,MARK,   StSet,IDLE
 STM_ROW EvJump,  StSht,NRDISP, StPly,JUMP,   StPly,LOOP,   StSet,IDLE
 STM_ROW EvStart, StSht,NRDISP, StPly,START,  StPly,START,  StSet,IDLE
 STM_ROW EvStop,  StSht,NRDISP, StSht,IDLE,   StSht,STOP,   StSet,IDLE
 STM_ROW EvCont,  StSht,NRDISP, StPly,CONT,   StPly,IDLE,   StSet,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	MESSAGE 	;
	sta	MARKER		;
	sta	LOOPEND 	;

	lda	#1		;set flag
	sta	LOOPNOT 	;

	clr	LOOPFLAG	;clear flag

;--- Initialize MIDI

	lda	#4		;default time signature = 4/4
	sta	NUMER		;
	sta	DENOM		;
	ldx	DENOM		;
	jsr	MIDI_METER	;

        lda     #100            ;default tempo = 100 QPM
        jsr     MIDI_TEMPO      ;

	lda	#$40		;enable timer interrupts
	sta	TCR		;

	SCI_RX_INT_DIS   	;disable MIDI receiver interrupts

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "6:     Sequencer"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0      Remote"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	lda	#9
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "MRK QPM"

	jsr	STDISP		;update display
	jsr	MKDISP		;
	jsr	TMDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action (administer loop function)

IDLE:	lda	LOOPNOT 	;should the loop be terminated?
	beq	IA		;=0 (no)? branch...
	rts			;=1 (yes)? return

IA:	lda	#MSG_WAIT	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;

	lda	MARKER		;set up new position
	ldx	#0		;
	jsr	MIDI_PLAY	;continue playing
	jsr	MSDISP		;update display
	jsr	BTDISP		;
	inc	LOOPNOT 	;set control flag

	lda	#MSG_LOOP	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	rts

;--- Increment numerator of time sig

NUMINC: lda	NUMER		;fetch numerator
	inca			;increment
	cmp	#16		;valid range: 1-16
	bls	NIA		;< or =16? branch...
	lda	#1		;>16? wrap to 1
NIA:	sta	NUMER		;save new value
	jsr	NMDISP		;update display
	lda	NUMER		;update clock
	ldx	DENOM		;
	jsr	MIDI_METER	;
	rts

;--- Change denominator of time sig

DENINC: lda	DENOM		;fetch denominator
	lsla			;shift to "increment"
	cmp	#32		;valid range: 1,2,4,8,16
	blo	DIA		;<32? branch...
	lda	#1		;>16? wrap to 1
DIA:	sta	DENOM		;save new value
	jsr	DNDISP		;update display
	lda	NUMER		;update clock
	ldx	DENOM		;
	jsr	MIDI_METER	;
	rts

;--- Increment tempo

TEMINC: lda     M_TEMPO         ;fetch M_TEMPO
	inca			;increment
	cmp	#19		;valid range: 20-255
	bhi	TIA		;>19? branch...
	lda	#20		;<20 ("above" 255)? wrap to 20
TIA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TMDISP		;update display
	rts

;--- Decrement tempo

TEMDEC: lda	M_TEMPO		;fetch M_TEMPO
	deca			;increment
	cmp	#19		;valid range: 20-255
	bhi	TDA		;>19? branch...
	lda	#255		;<20 ("above" 255)? wrap to 255
TDA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TMDISP		;update display
	rts

;--- Set tempo with fader

TEMFDR: lda	FDR		;fetch fader value
	cmp	#19		;valid range: 20-255
	bhi	TFA		;>19? branch...
	lda	#20		;<20 ("above" 255)? stay at 20
TFA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TMDISP		;update display
	rts

;--- Increment song measure

MEAINC: lda	M_MEASURE 	;fetch measure
	inca			;increment
	ldx	#0		;set up new position
	jsr	MIDI_POSN	;
	jsr	MSDISP		;update display
	jsr	BTDISP		;update display
	rts

;--- Decrement song measure

MEADEC: lda	M_MEASURE 	;fetch measure
	deca			;decrement
	ldx	#0		;set up new position
	jsr	MIDI_POSN
	jsr	MSDISP		;update display
	jsr	BTDISP		;update display
	rts

;--- Set song measure with fader

MEAFDR: lda	FDR		;fetch fader value
	ldx	#0		;set up new position
	jsr	MIDI_POSN	;
	jsr	MSDISP		;update display
	jsr	BTDISP		;update display
	rts

;--- Stop the sequence

STOP:	lda	#MSG_WAIT	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;

	jsr	MIDI_STOP	;transmit STOP message

	lda	#MSG_STOP	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	jsr	LEDMEA		;update display
	rts

;--- Play the sequence from the beginning

START:	clr	LOOPFLAG	;reset loop flag

	lda	M_PLAY	;already playing?
	beq	STA		;no? branch...

	lda	#MSG_WAIT	;yes? notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;

STA:	lda	#0		;rewind and play
	ldx	#0		;
	jsr	MIDI_PLAY	;

	lda	#MSG_PLAY	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	jsr	MSDISP		;update display
	jsr	BTDISP		;
	jsr	LED_INIT	;
	rts

;--- Play sequence from current measure and beat

CONT:	clr	LOOPFLAG	;reset loop flag

	lda	M_MEASURE 	;play from current measure
	ldx	M_BEAT		;
	jsr	MIDI_PLAY	;

	lda	#MSG_PLAY	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	jsr	LED_INIT	;update display
	rts

;--- Mark the current song measure

MARK:	lda	M_MEASURE 	;fetch measure
	sta	MARKER		;save marker value
	jsr	MKDISP		;update display
	rts			;

;--- Jump to the marked measure and play

JUMP:	clr	LOOPFLAG	;reset loop flag

	lda	MARKER		;play from marked measure
	ldx	#0		;
	jsr	MIDI_PLAY	;

	lda	#MSG_PLAY	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	jsr	MSDISP		;update display
	jsr	BTDISP		;
	jsr	LED_INIT	;
	rts

;--- Jump to the marked measure and loop

LOOP:	lda	#1		;turn looping "on"
	sta	LOOPFLAG	; by setting loop flag

	lda	#MSG_WAIT	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;

	lda	M_MEASURE 	;set loop end point to the
	inca			; start of the measure
	sta	LOOPEND 	; after the current measure

	cmp	MARKER		;is LOOPEND>MARKER?
	bhi	LA		;yes? branch...

	lda	MARKER		;no? exchange the two endpoints
	inca			;
	sta	LOOPEND 	;
	lda	M_MEASURE 	;
	sta	MARKER		;

LA:	lda	MARKER		;play from marked measure
	ldx	#0		;
	jsr	MIDI_PLAY	;

	lda	#MSG_LOOP	;notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;
	jsr	MSDISP		;update display
	jsr	BTDISP		;
	jsr	MKDISP		;
	rts

;--- Update display for setup

STDISP: lda	M_PLAY	;are we playing?
	beq	SETA		;no? continue...

	lda	#MSG_WAIT	;yes? notify user
	sta	MESSAGE 	;
	jsr	MGDISP		;

	jsr	MIDI_STOP	;stop the sequence

SETA:	lda	#MSG_STOP	;save playback status message
	sta	MESSAGE 	;

	lda	#0		;display time signature label
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TIME SIG"    ;

	lda	#3		;display backslash
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#'/'            ;
	jsr	LCD_PUT_C	;

	jsr	NMDISP		;update display
	jsr	DNDISP		;
	jsr	LEDTEM		;
	rts

;--- Display time signature numerator

NMDISP: lda	#2		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NUMER		;fetch numerator
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Display time signature denominator

DNDISP: lda	#4		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DENOM		;fetch denominator
	jsr	LCD_PUT_I	;display it
	lda	#' '            ;display additional space
	jsr	LCD_PUT_C	; to clear extra digit(s)
	rts

;--- Update display for normal operation

NRDISP: jsr	MGDISP		;update display

	lda	#3		;display colon
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#':'            ;
	jsr	LCD_PUT_C	;

	jsr	MSDISP		;update display
	jsr	BTDISP		;
	jsr	LEDMEA		;
	rts

;--- Display song measure

MSDISP: lda	#2		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_MEASURE 	;fetch measure
	inca			;increment to display as 1-256
	beq	MDA		;=0? branch...
	jsr	LCD_PUT_RJ3_I	;nonzero?  display measure
	rts

MDA:	lda	#0		;display as "256"
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "256"         ;
	rts

;--- Display song beat

BTDISP: lda	#4		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_BEAT		;fetch beat
	inca			;increment to display as 1-16
	jsr	LCD_PUT_I	;display it
	lda	#' '            ;display additional space
	jsr	LCD_PUT_C	; to clear extra digit
	rts

;--- Display tempo

TMDISP: lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_TEMPO		;fetch M_TEMPO
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Display marked measure

MKDISP: lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MARKER		;fetch marker
	inca			;increment to display as 1-256
	beq	MKA		;=0? branch...
	jsr	LCD_PUT_RJ3_I	;nonzero?  display measure
	rts

MKA:	lda	#9		;display as "256"
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "256"         ;
	rts

;--- Display status message

MGDISP: lda	#0		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;

	lda	MESSAGE 	;branch off current message
	cmp	#MSG_STOP	;
	beq	MSGA		;...if stopped
	cmp	#MSG_PLAY	;
	beq	MSGB		;...if playing
	cmp	#MSG_LOOP	;
	beq	MSGC		;...if looping

	LCD_PUT_S "...wait "    ;...if waiting
	rts			;

MSGA:	LCD_PUT_S "STOPPED "    ;
	rts			;

MSGB:	LCD_PUT_S "PLAYING "    ;
	rts			;

MSGC:	LCD_PUT_S "LOOPING "    ;
	rts			;

;--- Control tempo fader function LED

LEDTEM: lda	#15		;turn MEASURE LED off
	jsr	LED_OFF 	;
        lda     #3              ;turn tempo LED on
	jsr	LED_ON		;
	rts

;--- Control measure fader function LED

LEDMEA: lda     #3              ;turn tempo LED off
	jsr	LED_OFF 	;
	lda	#15		;turn MEASURE LED on
	jsr	LED_ON		;
	rts

;----------------------------------------------------------------
;	Interrupt Call Backs
;----------------------------------------------------------------

        IGNORE_IRQ_SWI_SPI

TIMER_CBCK:

	lda	#$F8		;load MIDI clock
	jsr	MIDI_PUT	;send it

	;--- setup timer registers for next time-out

	lda	M_CLK_LSB	;compute and store next output
	add	OCRLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	OCRMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;

	;--- update MEASURE/BEAT counters

	lda	M_PLAY	;are we playing?
	beq	THEND		;no? branch...

	inc	M_CLK_CNTR	;yes? update clock counter
	lda	#96		;
	ldx	M_DEN		;divide 96 by meter denominator

TH2:	cpx	#0		;note that DEN is set up to equal
	beq	TH3		; log2(denominator) to make this
	lsra			; division possible with shifts
	decx			;
	jmp	TH2 		;

TH3:	cmp	M_CLK_CNTR	;a new quarter note?
	bhi	THEND		;no? branch...

	clr	M_CLK_CNTR	;yes? start counting another beat
	inc	M_BEAT		;increment BEAT

	lda	M_NUM		;fetch numerator
	cmp	M_BEAT		;a new measure?
	bhi	TH4		;no? branch...

	;--- start of new measure

	inc	M_MEASURE 	;yes? increment measure

	lda	LOOPFLAG	;looping?
	beq	TH5		;no? branch...

	;--- administer loop mode

	lda	M_MEASURE 	;yes? get measure
	cmp	LOOPEND 	;are we at the endpoint?
	blo	TH5		;no? branch...

	clr	LOOPNOT 	;yes? reset flag to restart loop
	rti			;return, bypass BIOS timer ISR

TH5:	clr	M_BEAT		;clear beat
	jsr	MSDISP		;update display
TH4:	jsr	BTDISP		;update display
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


