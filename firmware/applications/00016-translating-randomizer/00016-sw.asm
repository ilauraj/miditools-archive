;===============================================================;
;								;
;       TOOL15.ASM      Rev 0.4                                 ;
;	Translating Randomizer					;
;								;
;	The user can randomize or translate various MIDI	;
;	channel messages in realtime.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE RECEIVE/RETRANSMIT CHANNEL?			;
;	Press the SETUP CHAN key.  The MIDI channel for both	;
;	receiving and retransmitting messages is set using the	;
;	+/- keys and/or the VALUE fader.  The range of MIDI	;
;	channels is: 1-16, ALL or NONE. 			;
;								;
;								;
;	...CHOOSE THE MODE OF OPERATION?			;
;	Press the SETUP MODE key.  The processor function is	;
;	selected using the +/- keys.  The available modes are:	;
;								;
;	Mode  Description					;
;	----  -----------					;
;	 0    Translating randomizer OFF			;
;	 1    Randomize note numbers				;
;	 2    Randomize velocity values 			;
;	 3    Randomize program change values			;
;	 4    Translate channel aftertouch to negative bend	;
;	 5    Translate channel aftertouch to positive bend	;
;	 6    Translate channel aftertouch to volume		;
;	 7    Translate pitch bend to pan			;
;	 8    Translate pitch bend to balance			;
;	 9    Translate modulation wheel to channel aftertouch	;
;								;
;	Mode 1 randomizes notes numbers received in Note On	;
;	messages only.	Therefore, most retransmitted notes	;
;	will not have a corresponding Note Off message. 	;
;	Voices should be chosen with this in mind (e.g. use	;
;	voices with natural decay).				;
;								;
;	Modes 4-6 and 9 use channel aftertouch only.		;
;								;
;								;
;	...CONTROL THE DEGREE OF EACH EFFECT?			;
;	Press the SETUP DEG key.  The degree of each effect	;
;	can be set using the +/- keys and/or the VALUE fader.	;
;	The "degree" is used to modify messages, as follows:    ;
;								;
;	Mode	Description					;
;	----	-----------					;
;	1-3	Sets window of possible values centered on	;
;		the received value, with wraparound.		;
;								;
;		Mode 1 - Example A: Note=50 is received 	;
;		with Degree=31.  The transmitted note will	;
;		be a random number between 35-66.		;
;								;
;		Mode 1 - Example B: Note=110 is received	;
;		with Degree=63.  The transmitted note will	;
;		be a random number between 79-127, or 0-14	;
;		(due to wraparound...). 			;
;								;
;	4-5	Sets the degree of damping.  The starting	;
;		pitch bend value is 64.  Therefore, data	;
;		are divided by the value of:			;
;								;
;		     [(Degree+1)/2], where Degree>1		;
;								;
;		When Degree=0 or 1, the data are divided	;
;		by 2.  After dividing, the data are		;
;		subtracted (Mode 4) or added (Mode 5)		;
;		to the starting pitch bend value of 64. 	;
;								;
;	6	Sets the minimum transmitted volume value	;
;								;
;	7-8	Sets the degree of damping.  The data are	;
;		first divided by [Degree+1].  The full range	;
;		of new values is then centered around 64.	;
;		The bend wheel center indent position		;
;		corresponds to the center pan (Mode 7) or	;
;		equal balance (Mode 8) position.		;
;								;
;	9	Sets degree of damping.  The data are divided	;
;		by [Degree+1] before being retransmitted.	;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	| CH  MODE DEGREE|	where nnnn=1-16,"NONE" or       ;
;	|nnnn	b    ccc |	"ALL ", ccc=0,1,3,7,15,31,63    ;
;				or 127, b=0-9			;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI ports used: IN,OUT,THRU. 	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StCh		Set the receive/retransmit channel	;
;	StMode		Select the processing function		;
;	StDeg		Set the degree of processing		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	MODINC		Increment mode number			;
;	MODDEC		Decrement mode number			;
;	DEGINC		Increment degree of processing		;
;	DEGDEC		Decrement degree of processing		;
;	DEGFDR		Set degree of processing with fader	;
;	CHDISP		Update display for changing channel	;
;	MODISP		Update display for changing mode number ;
;	DGDISP		Update display for changing degree	;
;	ARWCLR		Clear LCD cursor arrow			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel
MODE		.DS	1	;mode of operation
DEGREE		.DS	1	;degree of processing
WINDOW		.DS	1	;2^DEGREE
HALFWIN 	.DS	1	;2^DEGREE/2
STATNIB 	.DS	1	;status nibble
CHANNIB 	.DS	1	;channel nibble
TEMPVAL 	.DS	1	;M_TEMPOrary value storage

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StMode		EQU	1
StDeg		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvChan		EQU	EV_SW1_ON
EvMode		EQU	EV_SW2_ON
EvDeg		EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StCh   State 1:StMode State 2:StDeg        Not
;	 Event	  NextSt,Act	 NextSt,Act	NextSt,Act	    Used
;	 ---------------------------------------------------------------
 STM_ROW EvIdle,  StCh,IDLE,	 StMode,IDLE,	StDeg,IDLE,    StCh,IDLE
 STM_ROW EvPlus,  StCh,CHINC,	 StMode,MODINC, StDeg,DEGINC,  StCh,IDLE
 STM_ROW EvMinus, StCh,CHDEC,	 StMode,MODDEC, StDeg,DEGDEC,  StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,	 StMode,IDLE,	StDeg,DEGFDR,  StCh,IDLE
 STM_ROW EvChan,  StCh,IDLE,	 StCh,CHDISP,	StCh,CHDISP,   StCh,IDLE
 STM_ROW EvMode,  StMode,MODISP, StMode,IDLE,	StMode,MODISP, StCh,IDLE
 STM_ROW EvDeg,   StDeg,DGDISP,  StDeg,DGDISP,	StDeg,IDLE,    StCh,IDLE

       STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	MODE		;
	sta	DEGREE		;
	sta	HALFWIN 	;
	sta	WINDOW		;
	sta	TEMPVAL 	;
	sta	STATNIB 	;
	sta	CHANNIB 	;

	lda	#16		;
	sta	CHAN		;

;--- Initialize MIDI

	lda	#$01		;buffer note messages
	sta	M_RX_Q_XPT		;

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "15:  Translating"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0  Randomizer"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S " CH  MODE DEGREE"

	jsr	DGDISP		;update display
	jsr	MODISP		;
	jsr	CHDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment channel

CHINC:	lda	CHAN		;fetch channel
	inca			;increment
	cmp	#17		;valid range: 0-17
	bls	CIA		;< or =17? branch...
	lda	#0		;>17? wrap to 0
CIA:	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Decrement channel

CHDEC:	lda	CHAN		;fetch channel
	deca			;decrement
	cmp	#17		;valid range: 0-17
	bls	CDA		;< or =17? branch...
	lda	#17		;>17? wrap to 17
CDA:	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Set channel with fader

CHFDR:	lda	FDR		;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Increment mode number

MODINC: lda	M_FULL_MSG 	;wait if in the middle of
	beq	MODINC		; receiving a message
	sei			;disable all interrupts
	lda	M_RSTAT		;fetch external running status
	beq	MIA		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
MIA:	lda	MODE		;fetch mode
	inca			;increment
	cmp	#9		;valid range: 0-9
	bls	MIB		;< or =9? branch...
	lda	#0		;>9? wrap to 0
MIB:	sta	MODE		;store new value
	jsr	MODISP		;update display
	cli			;enable all interrupts
	rts

;--- Decrement mode number

MODDEC: lda	M_FULL_MSG 	;wait if in the middle of
	beq	MODDEC		; receiving a message
	sei			;disable all interrupts
	lda	M_RSTAT		;fetch external running status
	beq	MDA		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
MDA:	lda	MODE		;fetch mode
	deca			;decrement
	cmp	#9		;valid range: 0-9
	bls	MDB		;< or =9? branch...
	lda	#9		;>9? wrap to 9
MDB:	sta	MODE		;store new value
	jsr	MODISP		;update display
	cli			;enable all interrupts
	rts

;--- Increment degree of processing

DEGINC: lda	DEGREE		;fetch degree
	inca			;increment
	cmp	#7		;valid range: 0-7
	bls	DIA		;< or =7? branch...
	lda	#0		;>7? wrap to 0
DIA:	sta	DEGREE		;store new value
	jsr	DGDISP		;update display
	rts

;--- Decrement degree of processing

DEGDEC: lda	DEGREE		;fetch degree
	deca			;decrement
	cmp	#7		;valid range: 0-7
	bls	DDA		;< or =7? branch...
	lda	#7		;>7? wrap to 7
DDA:	sta	DEGREE		;store new value
	jsr	DGDISP		;update display
	rts

;--- Set degree of processing with fader

DEGFDR: lda	FDR		;fetch fader value
	lsra			;valid range: 0-7
	lsra			;
	lsra			;
	lsra			;
	lsra			;
	sta	DEGREE		;store new value
	jsr	DGDISP		;update display
	rts

;--- Update display for changing channel

CHDISP: jsr	ARWCLR		;clear arrow

	lda	#0		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	CHAN		;branch off channel
	cmp	#16		;
	beq	CDSA		;...if "ALL"
	cmp	#17		;
	bhs	CDSB		;...if "NONE"

	lda	#2		;...if other, position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#' '            ;write 2 spaces to display
	jsr	LCD_PUT_C	; for cleanup
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	rts

CDSA:	lda	#1		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "ALL "        ;display "ALL"
	rts

CDSB:	lda	#1		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "NONE"        ;display "NONE"
	rts

;--- Update display for changing mode number

MODISP: jsr	ARWCLR		;clear arrow

	lda	#6		;place MODE arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MODE		;fetch mode
	jsr	LCD_PUT_I	;display it
	rts

;--- Update display for changing degree

DGDISP: jsr	ARWCLR		;clear arrow

	lda	#11		;place DEGREE arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	#1		;start with display value=1
	ldx	DEGREE		;setup counter in x

DDSPA:	beq	DDSPB		;counter=0? branch...
	lsla			;nonzero? multiply value*2
	decx			;decrement counter
	jmp	DDSPA		;loop

DDSPB:	deca			;constrain to 0-127
	sta	WINDOW		;store window value (0-127)
	jsr	LCD_PUT_RJ3_I	;display it
	lda	WINDOW		;fetch window
	lsra			;divide by 2
	sta	HALFWIN 	;save half window value (0-63)
	rts

;--- Clear LCD cursor arrow

ARWCLR: lda	#0		;1st possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;2nd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#11		;3rd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	rts

;----------------------------------------------------------------
;	Interrupt Call Backs
;----------------------------------------------------------------

        IGNORE_IRQ_SWI_SPI

TIMER_CBCK:
        jmp     TIMER_CBCK_RET

SCI_TX_CBCK:
        jmp     SCI_TX_CBCK_RET

SCI_RX_CBCK:
        jmp     SCI_RX_CBCK_RET

;--- Process Status Byte

SCI_RX_CBCK_S:
	cmp	#$10		;is it a channel message?
	bls	URS1		;yes? branch...
	jmp	SENDIT		;no? jump...

URS1:	lda	M_RSTAT		;fetch Status Byte
	and	#$0F		;get channel
	sta	CHANNIB 	;save channel nibble
	cmp	CHAN		;is it the channel we want?
	beq	URS2		;yes? branch...
	lda	CHAN		;no? fetch effect channel
	cmp	#16		;is it =16 (ALL)?
	beq	URS2		;yes? branch...
	jmp	SENDIT		;no? jump...

	;--- we have a channel message on a selected channel

URS2:	lda	M_RSTAT		;fetch Status Byte
	and	#$F0		;get status nibble
	sta	STATNIB 	;save status nibble

	lda	MODE		;fetch mode
	bne	URS3		;nonzero? branch...
	jmp	SENDIT		;=0? jump...

URS3:	ldx	MODE		;fetch mode (it is nonzero)
	lda	MATCHSTAT,X	;index using mode to see if
	cmp	STATNIB 	; status nibble matches
	beq	URS4		;match? branch...
	ldx	M_RSTAT		;no match? restore Status Byte
	jmp	SENDIT		;send it

	;--- we have a message ready for modifaction (mode in x)

URS4:	lda	TRANSTAT,X	;index to get translated status
	add	CHANNIB 	;add channel nibble
	jsr	MIDI_PUT	;transmit replacement byte
	rti			;return, do not buffer

;--- Process 1st Data Bytes

SCI_RX_CBCK_D1:
	cmp	#$10		;is it a channel message?
	bls	URD11		;yes? branch...
	jmp	SENDIT		;no? jump...

URD11:	lda	CHANNIB 	;fetch current channel nibble
	cmp	CHAN		;is it the channel we want?
	beq	URD12		;yes? branch...
	lda	CHAN		;no? fetch effect channel
	cmp	#16		;is it =16 (ALL)?
	beq	URD12		;yes? branch...
	jmp	SENDIT		;no? jump...

	;--- we have a channel message on a selected channel

URD12:	lda	MODE		;fetch mode
	bne	URD13		;nonzero? branch...
	jmp	SENDIT		;=0? jump...

URD13:	ldx	MODE		;fetch mode (it is nonzero)
	lda	MATCHSTAT,X	;index using mode to see if
	cmp	STATNIB 	; to see if status nibble matches
	beq	URD14		;match? branch...
	ldx	M_DATA1 	;no match? restore Data Byte 1
	jmp	SENDIT		;jump...

	;--- we have a message ready for modifaction (mode in x)

URD14:	cpx	#1		;branch off mode
	beq	URD1_1		;...if Mode 1
	cpx	#2		;
	beq	URD1_2		;...if Mode 2
	cpx	#3		;
	beq	URD1_3		;...if Mode 3
	cpx	#9		;
	beq	URD1_9		;...if Mode 9

	lda	BYTE1VAL,X	;... if Modes 4-8? get Byte 1
	jsr	MIDI_PUT	;send it

	ldx	MODE		;branch off mode
	cpx	#4		;
	beq	URD1_4		;...if Mode 4
	cpx	#5		;
	beq	URD1_5		;...if Mode 5
	cpx	#6		;
	beq	URD1_6		;...if Mode 6
URD1_9: rti			;...if Modes 7-9? return

	;--- Mode 1 (randomize note numbers)

URD1_1: lda	M_DATA1 	;fetch note number
	sub	HALFWIN 	;subtract half window
	sta	M_DATA1 	;M_TEMPOrary storage
	jsr	RANDOMIZE	;get random offset
	add	M_DATA1 	;add to note number
	and	#$7F		;constrain to 0-127
	jsr	MIDI_PUT	;send new note
	rti			;return, do not buffer

	;--- Mode 2 (does not affect 1st Data Byte)

URD1_2: ldx	M_DATA1 	;restore Data Byte 1
	jmp	SENDIT		;jump...

	;--- Mode 3 (randomize program change values)

URD1_3: lda	M_DATA1 	;fetch program number
	sub	HALFWIN 	;subtract half window
	sta	M_DATA1 	;M_TEMPOrary storage
	jsr	RANDOMIZE	;get random offset
	add	M_DATA1 	;add to program number
	and	#$7F		;constrain to 0-127
	jsr	MIDI_PUT	;send new program number
	rti			;return, do not buffer

	;--- Mode 4 (translate chan aftertouch to negative bend)

URD1_4: ldx	M_DATA1 	;get aftertouch value
	lsrx			;divide by 2
	lda	DEGREE		;dampen by shifting right once
URD14A: cmp	#1		; for every degree
	bls	URD14B		;finished? branch...
	lsrx			;no? divide aftertouch by 2
	deca			;decrement counter
	jmp	URD14A		;loop
URD14B: stx	TEMPVAL 	;save new aftertouch
	lda	#64		;initial pitch bend (OFF)=64
	sub	TEMPVAL 	;PITCH BEND=64-new aftertouch
	jsr	MIDI_PUT	;send pitch bend
	rti			;return, do not buffer

	;--- Mode 5 (translate chan aftertouch to positive bend)

URD1_5: ldx	M_DATA1 	;get aftertouch value
	lsrx			;divide by 2
	lda	DEGREE		;dampen by shifting right once
URD15A: cmp	#1		; for every degree
	bls	URD15B		;finished? branch...
	lsrx			;no? divide aftertouch by 2
	deca			;decrement counter
	jmp	URD15A		;loop
URD15B: stx	TEMPVAL 	;save new aftertouch
	lda	#64		;initial pitch bend (OFF)=64
	add	TEMPVAL 	;PITCH BEND=64+new aftertouch
	jsr	MIDI_PUT	;send pitch bend
	rti			;return, do not buffer

	;--- Mode 6 (translate chan aftertouch to volume)

URD1_6: lda	M_DATA1 	;get aftertouch value
	cmp	WINDOW		;compare to window size
	bhs	URD16A		;> or =WINDOW? branch...
	lda	WINDOW		;<WINDOW? load window instead
URD16A: jsr	MIDI_PUT	;send volume
	rti			;return, do not buffer

;--- Process 2nd Data Bytes

SCI_RX_CBCK_D2:
	cmp	#$10		;is it a channel message?
	bls	URD21		;yes? branch...
	jmp	SENDIT		;no? jump...

URD21:	lda	CHANNIB 	;fetch current channel nibble
	cmp	CHAN		;is it the channel we want?
	beq	URD22		;yes? branch...
	lda	CHAN		;no? fetch effect channel
	cmp	#16		;is it =16 (ALL)?
	beq	URD22		;yes? branch...
	jmp	SENDIT		;no? jump...

	;--- we have a channel message on a selected channel

URD22:	lda	MODE		;fetch mode
	bne	URD23		;nonzero? branch...
	jmp	SENDIT		;=0? jump...

URD23:	ldx	MODE		;fetch mode (it is nonzero)
	lda	MATCHSTAT,X	;index using mode to see if
	cmp	STATNIB 	; to see if status nibble matches
	beq	URD24		;match? branch...
	ldx	M_DATA2 	;no match? load Data Byte 2
	jmp	SENDIT		;jump...

	;--- we have a message ready for modifaction (mode in x)

URD24:	cpx	#2		;branch off mode number
	beq	URD2_2		;...if Mode 2
	cpx	#9		;
	beq	URD2_9		;...if Mode 9
	cpx	#7		;
	bhs	URD2_78 	;...if Modes 7 or 8
	ldx	M_DATA2 	;...if Modes 1 and 3? get Byte 2
	jmp	SENDIT		;jump...

	;--- Mode 2 (randomize velocity values)

URD2_2: lda	M_DATA2 	;fetch velocity value
	sub	HALFWIN 	;subtract half window
	sta	M_DATA2 	;M_TEMPOrary storage
	jsr	RANDOMIZE	;get random offset
	add	M_DATA2 	;add to velocity value
	and	#$7F		;constrain to 0-127
	jsr	MIDI_PUT	;send new velocity
	rti			;return, do not buffer

	;--- Modes 7 and 8 (translate pitch bend to pan/balance)

URD2_78:
	ldx	M_DATA2 	;fetch pitch bend MSB
	lda	DEGREE		;dampen by shifting value right
URD27A: beq	URD27B		; once for each degree (div by 2)
	lsrx			;divide bend value by 2
	deca			;decrement counter
	jmp	URD27A		;loop
URD27B: stx	TEMPVAL 	;save new bend value
	ldx	DEGREE		;fetch degree
	lda	BENDADDER,X	;get adder (to center range @64)
	add	TEMPVAL 	;add new bend value to adder
	jsr	MIDI_PUT	;send as pan/balance
	rti			;return, do not buffer

	;--- Mode 9 (translate mod wheel to channel aftertouch)

URD2_9: ldx	M_DATA2 	;fetch mod wheel value
	lda	DEGREE		;dampen by shifting value right
URD29A: beq	URD29B		; once for each degree (div by 2)
	lsrx			;divide bend value by 2
	deca			;decrement counter
	jmp	URD29A		;loop
URD29B: jmp	SENDIT		;jump

;--- Return a random number in acca (uses DEGREE variable)

RANDOMIZE:
	lda	CARLSB		;get LSB of timer
	and	#$7F		;constrain to (0-127)
	ldx	#7		;init counter
RAND0:	cpx	DEGREE		;finished?
	beq	RAND1		;yes? jump
	lsra			;no? divide value by 2
	decx			;decrement counter
	jmp	RAND0		;loop
RAND1:	rts			;return (with random # in acca)

;--- Send byte (in x)

SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer

;--- Lookup tables used in receive call backs

MATCHSTAT:
	.DB	$00,$90,$90,$C0,$D0,$D0,$D0,$E0,$E0,$B0

TRANSTAT:
	.DB	$00,$90,$90,$C0,$E0,$E0,$B0,$B0,$B0,$D0

BYTE1VAL:
	.DB	$00,$00,$00,$00,$00,$00,$07,$0A,$08

BENDADDER:
	.DB	$00,$20,$30,$38,$3C,$3E,$3F,$40
