;===============================================================;
;								;
;       TOOL16.ASM      Rev 0.4                                 ;
;	Multi-Effector						;
;								;
;	The user can process MIDI events in realtime;		;
;	available effects include gating, limiting,		;
;	compressing or expanding, and delay.			;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE RECEIVE/RETRANSMIT CHANNEL?			;
;	Press the SETUP CHAN key.  The MIDI channel for 	;
;	receiving and retransmitting messages is set using the	;
;	+/- keys and/or the VALUE fader.  The range of MIDI	;
;	channels is: 1-16, ALL, or NONE.			;
;								;
;								;
;	...SET THE GATE THRESHOLD?				;
;	Press the EFFECTS GATE key.  The gate threshold is set	;
;	using the +/- keys and/or the VALUE fader.  All notes	;
;	received with a velocity less than this threshold will	;
;	not be retransmitted.  The GATE LED lights when a note	;
;	is being gated. 					;
;								;
;								;
;	...SET THE LIMITER THRESHOLD?				;
;	Press the EFFECTS LIMIT key.  The limiter threshold is	;
;	set using the +/- keys and/or the VALUE fader.	All	;
;	notes received with a velocity greater than this	;
;	threshold will be retransmitted with the threshold	;
;	velocity.  The LIMIT LED lights when a note is being	;
;	limited.						;
;								;
;								;
;	...SET THE COMPRESSION RATIO?				;
;	Press the EFFECTS CM/EX key.  The compression ratio is	;
;	set using the +/- keys and/or the VALUE fader.	Values	;
;	for compression are found at the bottom half of fader	;
;	travel (lowest 64 positions).  The COMPRESS LED lights	;
;	when a note velocity is being compressed.		;
;								;
;								;
;	...SET THE EXPANSION RATIO?				;
;	Press the EFFECTS CM/EX key.  The expansion ratio is	;
;	set using the +/- keys and/or the VALUE fader.	Values	;
;	for expansion are found at the top half of fader	;
;	travel (highest 64 positions).	The EXPAND LED lights	;
;	when a note velocity is being expanded. 		;
;								;
;								;
;	...SET THE DELAY PARAMETERS?				;
;	Press the EFFECTS DELAY key.  The delayed note spacing	;
;	is set with the NOTE key.  The range of values is:	;
;	1,2,4,8,16, or 32; corresponding to whole, half,	;
;	quarter, eighth, sixteenth, or thirty-second notes.	;
;								;
;	The decay algorithm is entered with the ALG key.  The	;
;	available decay algorithms are: 			;
;								;
;		ALG	Description				;
;		---	-----------				;
;		 0	Delay generator OFF			;
;		 1	Repeat note at same velocity (endless)	;
;		 2	Divide velocity by 2 until v=0		;
;		 3	Divide velocity by 4 until v=0		;
;		 4	Divide velocity by 8 until v=0		;
;		 5	Subtract 2 from velocity until v=0	;
;		 6	Subtract 4 from velocity until v=0	;
;		 7	Subtract 8 from velocity until v=0	;
;		 8	Subtract 16 from velocity until v=0	;
;								;
;	The delay generator affects the last note played only.	;
;								;
;								;
;	...SET THE TEMPO OF DELAYED NOTES?			;
;	Press the SETUP TEMPO key.  The tempo, in quarter	;
;	notes per minute (QPM), of delayed notes is set using	;
;	the +/- keys and/or the VALUE fader.  The range of	;
;	tempo values is 20-255 QPM.				;
;								;
;								;
;	...KNOW THE PROCESSING ORDER?				;
;	Each received note flows through the effects		;
;	processors in the following order:			;
;								;
;	    GATE ==> COMP/EXP ==> LIMITER ==> DELAY		;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When the SETUP CHAN key is pressed,			;
;								;
;	| MULTI-EFFECTOR |	where nnnn=1-16, " ALL",        ;
;	| CHANNEL:  nnnn |	or "NONE"                       ;
;								;
;								;
;	When the SETUP TEMPO key is pressed,			;
;								;
;	| MULTI-EFFECTOR |	where eee=20-255		;
;	| TEMPO:     eee |					;
;								;
;								;
;	When any other key is pressed,				;
;								;
;	| GAT zz LIM DL-A|	where bbb=0-127, cc=0-63,	;
;	| bbb cc bbb rr d|	d=0-8, zz="EX" or "CM",         ;
;				rr=1,2,4,8,16, or 32		;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;---------------------------------------------------------------;
;								;
;	Harware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI ports used: IN,OUT,THRU. 	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StSet		Set channel and tempo			;
;	StCmEx		Set compression/expansion parameters	;
;	StGtLm		Set gate/limit parameters		;
;	StDely		Set delay parameters			;
;								;
;	Actions:						;
;								;
;	IDLE		No action (administer delays & LEDs)	;
;	CTINC		Route setup increment action		;
;	CTDEC		Route setup decrement action		;
;	CTFDR		Route setup fader action		;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	TEMINC		Increment delay tempo			;
;	TEMDEC		Decrement delay tempo			;
;	TEMFDR		Set delay tempo with fader		;
;	CEINC		Increment comp/exp value		;
;	CEDEC		Decrement comp/exp value		;
;	CEFDR		Set comp/exp value with fader		;
;	CECALC		Calculate comp/exp ratio		;
;	GLINC		Route gate/limit increment action	;
;	GLDEC		Route gate/limit decrement action	;
;	GLFDR		Route gate/limit fader action		;
;	GTINC		Increment gate threshold		;
;	GTDEC		Decrement gate threshold		;
;	GTFDR		Set gate threshold with fader		;
;	LMINC		Increment limit threshold		;
;	LMDEC		Decrement limit threshold		;
;	LMFDR		Set limit threshold with fader		;
;	DLINC		Increment value of delayed note 	;
;	ALGINC		Increment decay algorithm		;
;	CHDISP		Update display for changing channel	;
;	TMDISP		Update display for changing tempo	;
;	LBDISP		Update display with comp/exp label	;
;	CXDISP		Update display with comp/exp ratio	;
;	GTDISP		Update display with gate threshold	;
;	LMDISP		Update display with limit threshold	;
;	DLDISP		Update display with delay note value	;
;	ALDISP		Update display with decay algorithm	;
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

TDOWN		.DS	1	;timer down flag
CHAN		.DS	1	;MIDI channel
GTVAL		.DS	1	;gate threshold value
LMVAL		.DS	1	;limit threshold value
CEVAL		.DS	1	;comp/exp value
CERATIO 	.DS	1	;comp/exp calculated ratio
DLVAL		.DS	1	;delayed note value
ALVAL		.DS	1	;decay algorithm value
CT		.DS	1	;channel/tempo flag (0=channel)
GL		.DS	1	;gate/limit flag (0=gate)
CEX		.DS	1	;comp/exp flag (0=compression)
SETFLAG 	.DS	1	;setup state flag

DLTEMP		.DS	1	;delay - temporary variable
DLSTAT		.DS	1	;delay - status byte register
DLPSTAT 	.DS	1	;delay - previous status
DLNOTE		.DS	1	;delay - note number register
DLPNOTE 	.DS	1	;delay - previous note
DLVEL		.DS	1	;delay - velocity register
DLCNT		.DS	1	;delay - data byte counter
DLSEND		.DS	1	;delay - transmit flag
DLOFF		.DS	1	;delay - transmit flag
DLPOFF		.DS	1	;delay - transmit flag

LEDGAT		.DS	1	;LED flag
LEDCMP		.DS	1	;LED flag
LEDEXP		.DS	1	;LED flag
LEDLIM		.DS	1	;LED flag

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StSet		EQU	0
StCmEx		EQU	1
StGtLm		EQU	2
StDely		EQU	3

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvGate		EQU	EV_SW1_ON
EvCmEx		EQU	EV_SW2_ON
EvLimit 	EQU	EV_SW3_ON
EvDelay 	EQU	EV_SW4_ON
EvChan		EQU	EV_SW5_ON
EvMinus 	EQU	EV_SW6_ON
EvPlus		EQU	EV_SW7_ON
EvTempo 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StSet  State 1:StCmEx State 2:StGtLm State 3:StDely
;	 Event	  NextSt,Act	 NextSt,Act	NextSt,Act     NextSt,Act
;	 --------------------------------------------------------------------
 STM_ROW EvIdle,  StSet,IDLE,	 StCmEx,IDLE,	StGtLm,IDLE,   StDely,IDLE
 STM_ROW EvPlus,  StSet,CTINC,	 StCmEx,CEINC,	StGtLm,GLINC,  StDely,ALGINC
 STM_ROW EvMinus, StSet,CTDEC,	 StCmEx,CEDEC,	StGtLm,GLDEC,  StDely,DLINC
 STM_ROW EvValue, StSet,CTFDR,	 StCmEx,CEFDR,	StGtLm,GLFDR,  StDely,IDLE
 STM_ROW EvChan,  StSet,CHDISP,  StSet,CHDISP,	StSet,CHDISP,  StSet,CHDISP
 STM_ROW EvGate,  StGtLm,GTDISP, StGtLm,GTDISP, StGtLm,GTDISP, StGtLm,GTDISP
 STM_ROW EvLimit, StGtLm,LMDISP, StGtLm,LMDISP, StGtLm,LMDISP, StGtLm,LMDISP
 STM_ROW EvTempo, StSet,TMDISP,  StSet,TMDISP,	StSet,TMDISP,  StSet,TMDISP
 STM_ROW EvDelay, StDely,DLDISP, StDely,DLDISP, StDely,DLDISP, StDely,DLDISP
 STM_ROW EvCmEx,  StCmEx,CXDISP, StCmEx,IDLE,	StCmEx,CXDISP, StCmEx,CXDISP

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	CERATIO 	;
	sta	GTVAL		;
	sta	DLVEL		;
	sta	ALVAL		;
	sta	DLSTAT		;
	sta	DLPSTAT 	;
	sta	DLNOTE		;
	sta	DLPNOTE 	;

	lda	#1		;
	sta	DLVAL		;
	sta	DLTEMP		;

	lda	#16		;
	sta	CHAN		;

	lda	#63		;
	sta	CEVAL		;

	lda	#95		;
	sta	DLCNT		;

	lda	#127		;
	sta	LMVAL		;

	clr	CT		;clear flags
	clr	GL		;
	clr	CEX		;
	clr	SETFLAG 	;
	clr	DLSEND		;
	clr	DLOFF		;
	clr	DLPOFF		;
	clr	LEDGAT		;
	clr	LEDLIM		;
	clr	LEDCMP		;
	clr	LEDEXP		;

	lda	#1		;set flags
	sta	TDOWN		;

;--- Initialize MIDI

	lda	#100		;set default M_TEMPO
        jsr     MIDI_TEMPO      ;

	clr	TCR		;disable timer interrupts

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "16:       Multi-"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3     Effector"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	jsr	CHDISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action (administer delays & LEDs)

IDLE:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	IDLENC		; receiving a message

	lda	TDOWN		;is timer down?
	bne	IDLENC		;yes? branch...
	lda	#$40		;no? enable timer interrupts
	sta	TCR		;

	;--- turn off previous note and send new one

	lda	DLSEND		;get send flag
	beq	IDLEA		;=0? branch...
	sei			;=1? disable all interrupts
	clr	DLSEND		;reset send flag
	lda	DLPSTAT 	;get previous Status Byte
	jsr	MIDI_PUT	;send it
	lda	DLPNOTE 	;get previous Note Number
	jsr	MIDI_PUT	;send it
	lda	#$00		;load note off velocity
	jsr	MIDI_PUT	;send it
	lda	DLSTAT		;get new Status Byte
	jsr	MIDI_PUT	;send it
	lda	DLNOTE		;get new Note Number
	jsr	MIDI_PUT	;send it
	lda	DLVEL		;get new velocity
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	IGO1		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
IGO1:	lda	DLSTAT		;fetch status
	sta	DLPSTAT 	;save as previous status
	lda	DLNOTE		;fetch note number
	sta	DLPNOTE 	;save as previous note number
	cli			;enable all interrupts
	rts

	;--- turn off previous delayed note only

IDLEA:	lda	DLOFF		;get off-only flag
	beq	IDLLED		;=0? branch...
	sei			;=1? disable all interrupts
	inc	TDOWN		;set timer down flag
	clr	DLOFF		;reset off-only flag
	lda	DLPSTAT 	;get previous Status Byte
	jsr	MIDI_PUT	;send it
	lda	DLPNOTE 	;get previous Note Number
	jsr	MIDI_PUT	;send it
	lda	#$00		;load note off velocity
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	IGO2		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
IGO2:	cli			;enable all interrupts
	rts

IDLENC: clr	TCR		;disable timer interrupts

	;--- administer LEDs (when not generating delayed notes)

IDLLED: lda	LEDGAT		;get LED flag
	beq	IDLEC		;=0? branch...
	lda	#3		;=1? blink GATE LED
	jsr	LED_ON		;
	lda	#3		;
	jsr	LED_OFF 	;
	clr	LEDGAT		;clear LED flag
	rts

IDLEC:	lda	LEDEXP		;get LED flag
	beq	IDLED		;=0? branch...
	lda	#7		;=1? blink EXPANSION LED
	jsr	LED_ON		;
	lda	#7		;
	jsr	LED_OFF 	;
	clr	LEDEXP		;clear LED flag
	rts

IDLED:	lda	LEDCMP		;get LED flag
	beq	IDLEE		;=0? branch...
	lda	#11		;=1? blink COMPRESSION LED
	jsr	LED_ON		;
	lda	#11		;
	jsr	LED_OFF 	;
	clr	LEDCMP		;clear LED flag
	rts

IDLEE:	lda	LEDLIM		;get LED flag
	beq	IDLEF		;=0? branch...
	lda	#15		;=1? blink LIMIT LED
	jsr	LED_ON		;
	lda	#15		;
	jsr	LED_OFF 	;
	clr	LEDLIM		;clear LED flag
IDLEF:	rts

;--- Route setup increment action

CTINC:	lda	CT		;get flag
	beq	CHINC		;=0? go increment channel...
	jmp	TEMINC		;=1? go increment M_TEMPO...

;--- Route setup decrement action

CTDEC:	lda	CT		;get flag
	beq	CHDEC		;=0? go decrement channel...
	jmp	TEMDEC		;=1? go decrement M_TEMPO...

;--- Route setup fader action

CTFDR:	lda	CT		;get flag
	beq	CHFDR		;=0? go set channel to fader...
	jmp	TEMFDR		;=1? go set M_TEMPO to fader...

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

;--- Increment tempo

TEMINC: lda	M_TEMPO		;fetch M_TEMPO
	inca			;increment
	cmp	#20		;valid range: 20-255
	bhs	TIA		;> or =20? branch...
	lda	#20		;<20? wrap to 20
TIA:    jsr     MIDI_TEMPO      ;update clock
	jsr	TMDISP		;update display
	rts

;--- Decrement tempo

TEMDEC: lda	M_TEMPO		;fetch M_TEMPO
	deca			;decrement
	cmp	#20		;valid range: 20-255
	bhs	TDA		;> or =20? branch...
	lda	#255		;<20? wrap to 255
TDA:    jsr     MIDI_TEMPO      ;update clock
	jsr	TMDISP		;update display
	rts

;--- Set tempo with fader

TEMFDR: lda	FDR		;fetch fader value
	cmp	#20		;valid range: 20-255
	bhs	TFA		;> or =20? branch...
	lda	#20		;<20? stay at 20
TFA:    jsr     MIDI_TEMPO      ;update clock
	jsr	TMDISP		;update display
	rts

;--- Increment comp/exp value

CEINC:	lda	CEVAL		;fetch comp/exp value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	CEVAL		;store new value
	jmp	CECALC		;jump...

;--- Decrement comp/exp value

CEDEC:	lda	CEVAL		;fetch comp/exp value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	CEVAL		;store new value
	jmp	CECALC		;jump...

;--- Set comp/exp value with fader

CEFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	CEVAL		;store new value

;--- Calculate comp/exp ratio (comp/exp value is in acca)

CECALC: cmp	#64		;compare comp/exp value
	bhi	CCA		;>64? branch...

	cmp	#63		;< or =64? compare again
	blo	CCB		;<63? branch...

	clr	CEX		;=63 or =64? clear comp/exp flag
	clr	CERATIO 	;clear ratio (=0/OFF)
	jmp	CCEND		;jump...

CCA:	sub	#64		;expansion ratio=CEVAL-64
	sta	CERATIO 	;store ratio
	lda	#1		;set comp/exp flag
	sta	CEX		;
	jmp	CCEND		;jump...

CCB:	lda	#63		;compression ratio=63-CEVAL
	sub	CEVAL		;
	sta	CERATIO 	;store ratio
	clr	CEX		;clear comp/exp flag

CCEND:	jsr	LBDISP		;update display
	jsr	CXDISP		;
	rts

;--- Route gate/limit increment action

GLINC:	lda	GL		;get flag
	beq	GTINC		;=0? go increment gate thresh...
	jmp	LMINC		;=1? go increment limit thresh...

;--- Route gate/limit decrement action

GLDEC:	lda	GL		;get flag
	beq	GTDEC		;=0? go decrement gate thresh...
	jmp	LMDEC		;=1? go decrement limit thresh...

;--- Route gate/limit fader action

GLFDR:	lda	GL		;get flag
	beq	GTFDR		;=0? go set gate with fader...
	jmp	LMFDR		;=1? go set limit with fader...

;--- Increment gate threshold

GTINC:	lda	GTVAL		;fetch threshold value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	GTVAL		;store new value
	jsr	GTDISP		;update display
	rts

;--- Decrement gate threshold

GTDEC:	lda	GTVAL		;fetch threshold value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	GTVAL		;store new value
	jsr	GTDISP		;update display
	rts

;--- Set gate threshold with fader

GTFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	GTVAL		;store new value
	jsr	GTDISP		;update display
	rts

;--- Increment limit threshold

LMINC:	lda	LMVAL		;fetch threshold value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	LMVAL		;store new value
	jsr	LMDISP		;update display
	rts

;--- Decrement limit threshold

LMDEC:	lda	LMVAL		;fetch threshold value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	LMVAL		;store new value
	jsr	LMDISP		;update display
	rts

;--- Set limit threshold with fader

LMFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	LMVAL		;store new value
	jsr	LMDISP		;update display
	rts

;--- Increment value of delayed note

DLINC:	lda	DLVAL		;fetch note value
	lsla			;shift left to increment
	cmp	#32		;compare
	bls	DIA		;< or =32? branch...
	lda	#1		;>32? wrap to 1
DIA:	sta	DLVAL		;store new value
	jsr	DLDISP		;update display

	;--- calculate the number of MIDI clocks between
	;    delayed notes (start count from clock #0)

	ldx	#3		;load starting counter value
	stx	DLCNT		;store it

	lda	DLVAL		;fetch note value (1,2,4,8,16,32)
	lsla			;shift left once to set up

DIB:	lsla			;shift left one bit
	bmi	DIC		;if MSB set, branch...
	lslx			;if MSB still clear, multiply
	jmp	DIB		; counter by 2

DIC:	decx			;start counting from 0
	stx	DLCNT		;store counter value
	rts

;--- Increment decay algorithm

ALGINC: lda	ALVAL		;fetch algorithm
	inca			;increment
	cmp	#8		;valid range: 0-8
	bls	ALA		;< or =8? branch...
	lda	#0		;>8? wrap to 0
ALA:	sta	ALVAL		;store new value
	jsr	ALDISP		;update display
	rts

;--- Update display for changing channel

CHDISP: clr	SETFLAG 	;clear setup flag
	clr	CT		;clear channel/tempo flag

	lda	#0		;top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " MULTI-EFFECTOR "

	lda	#0		;bottom line of LCD
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " CHANNEL:       "

	lda	CHAN		;branch off channel number
	cmp	#16		;
	beq	CDSA		;...if "ALL"
	cmp	#17		;
	bhs	CDSB		;...if "NONE"

	lda	#14		;...otherwise, position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

CDSA:	lda	#12		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "ALL"         ;display "ALL"
	rts

CDSB:	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "NONE"        ;display "NONE"
	rts

;--- Update display for changing tempo

TMDISP: clr	SETFLAG 	;clear setup flag
	lda	#1		;set channel/tempo flag
	sta	CT		;

	lda	#0		;top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " MULTI-EFFECTOR "

	lda	#0		;bottom line of LCD
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " TEMPO:         "

	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_TEMPO		;fetch M_TEMPO
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display with comp/exp label

LBDISP: lda	CEX		;fetch comp/exp flag
	beq	CXLA		;=0 (compress)? branch...

	lda	#5		;=1 (expand)? position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "EX"          ;display "EX"
	rts

CXLA:	lda	#5		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "CM"          ;display "CM"
	rts

;--- Update display with comp/exp ratio

CXDISP: lda	SETFLAG 	;get setup flag
	bne	CXDA		;=1? branch...

	lda	#0		;=0? top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " GAT    LIM DL-A"

	inc	SETFLAG 	;set setup flag
	jsr	LBDISP		;update comp/exp label
	jsr	GTDISP		;update gate threshold
	jsr	LMDISP		;update limit threshold
	jsr	DLDISP		;update delay note value
	jsr	ALDISP		;update decay algorithm

CXDA:	jsr	ARWCLR		;clear arrow

	lda	#4		;place arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#6		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CERATIO 	;fetch comp/exp ratio
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display with gate threshold

GTDISP: lda	SETFLAG 	;get setup flag
	bne	GTDA		;=1? branch...

	lda	#0		;=0? top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " GAT    LIM DL-A"

	inc	SETFLAG 	;set setup flag
	jsr	LBDISP		;update comp/exp label
	jsr	LMDISP		;update limit threshold
	jsr	CXDISP		;update comp/exp ratio
	jsr	DLDISP		;update delay note value
	jsr	ALDISP		;update decay algorithm

GTDA:	jsr	ARWCLR		;clear arrow

	lda	#0		;place arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#3		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	GTVAL		;fetch gate threshold
	jsr	LCD_PUT_RJ3_I	;display it

	clr	GL		;reset gate/limit flag
	rts

;--- Update display with limit threshold

LMDISP: lda	SETFLAG 	;get setup flag
	bne	LMDA		;=1? branch...

	lda	#0		;=0? top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " GAT    LIM DL-A"

	inc	SETFLAG 	;set setup flag
	jsr	LBDISP		;update comp/exp label
	jsr	GTDISP		;update gate threshold
	jsr	CXDISP		;update comp/exp ratio
	jsr	DLDISP		;update delay note value
	jsr	ALDISP		;update decay algorithm

LMDA:	jsr	ARWCLR		;clear arrow

	lda	#7		;place arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#10		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	LMVAL		;fetch limit threshold
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#1		;set gate/limit flag
	sta	GL		;
	rts

;--- Update display with delay note value

DLDISP: lda	SETFLAG 	;get setup flag
	bne	DLDA		;=1? branch...

	lda	#0		;=0? top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " GAT    LIM DL-A"

	inc	SETFLAG 	;set setup flag
	jsr	LBDISP		;update comp/exp label
	jsr	GTDISP		;update gate threshold
	jsr	LMDISP		;update limit threshold
	jsr	CXDISP		;update comp/exp ratio
	jsr	ALDISP		;update decay algorithm

DLDA:	jsr	ARWCLR		;clear arrow

	lda	#11		;place arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#13		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DLVAL		;fetch note value
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display with decay algorithm

ALDISP: lda	SETFLAG 	;get setup flag
	bne	ALGDA		;=1? branch...

	lda	#0		;=0? top line of LCD
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " GAT    LIM DL-A"

	inc	SETFLAG 	;set setup flag
	jsr	LBDISP		;update comp/exp label
	jsr	GTDISP		;update gate threshold
	jsr	LMDISP		;update limit threshold
	jsr	CXDISP		;update comp/exp ratio
	jsr	DLDISP		;update delay note value

ALGDA:	jsr	ARWCLR		;clear arrow

	lda	#14		;place arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	ALVAL		;fetch algorithm value
	jsr	LCD_PUT_I	;display it
	rts

;--- Clear LCD cursor arrow

ARWCLR: lda	#0		;1st possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;2nd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#7		;3rd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#11		;4th possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#14		;5th possible arrow position
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
	lda	M_CLK_LSB	;compute and store next output
	add	OCRLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	OCRMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;

	lda	M_CLK_CNTR	;fetch clock counter
	cmp	DLCNT		;is it =delay counter?
	beq	THA		;yes? branch...
	inc	M_CLK_CNTR	;no? increment counter
	rti			;return

	;--- generate delayed note parameters

THA:	clr	M_CLK_CNTR	;reset counter

	lda	ALVAL		;fetch decay algorithm
	cmp	#4		;compare
	bhi	THSUB		;>4? branch...

	;--- division algorithms (1-4)

THDIV:	ldx	DLVEL		;< or =4? fetch velocity
THDA:	deca			;count down ALVAL for shifting
	beq	THDB		;finished? jump...
	lsrx			;divide velocity by 2
	jmp	THDA		;loop

THDB:	cpx	#0		;compare velocity
	bne	THDC		;nonzero? branch...
	lda	#1		;=0? set off-only flag
	sta	DLOFF		;
	rti			;return

THDC:	stx	DLVEL		;store new velocity
	lda	#1		;set new note flag
	sta	DLSEND		;
	rti			;return

	;--- subtraction algorithms (5-8)

THSUB:	sub	#4		;set working ALG# counter: 1-4
	ldx	DLTEMP		;fetch temp variable (init=1)

THSA:	lslx			;multiply temp by 2
	deca			;decrement counter
	beq	THSB		;finished? jump...
	jmp	THSA		;loop

THSB:	stx	DLTEMP		;save new temp value
	lda	DLVEL		;fetch velocity
	sub	DLTEMP		;subtract offset (stored in temp)
	bcs	THSC		;result is negative? branch...
	beq	THSC		;result=0? branch...

	sta	DLVEL		;result>0? store new velocity
	lda	#1		;set new note flag
	sta	DLSEND		;
	lda	#1		;reset temp variable
	sta	DLTEMP		;
	rti			;return

THSC:	lda	#1		;set off-only flag
	sta	DLOFF		;
	lda	#1		;reset temp variable
	sta	DLTEMP		;
	rti			;return


SCI_TX_CBCK:
        jmp     SCI_TX_CBCK_RET

SCI_RX_CBCK:
        jmp     SCI_RX_CBCK_RET

;--- Service Status Bytes and 1st Data Bytes

SCI_RX_CBCK_S:
SCI_RX_CBCK_D1:
SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer

;--- Service 2nd Data Bytes (byte value is in x)

SCI_RX_CBCK_D2:
	lda	M_RSTAT		;fetch current Status Byte
	and	#$F0		;get status nibble
	cmp	#$90		;is it a Note On message?
	beq	UR2A		;yes? branch...
	jmp	SENDIT		;no? jump...

UR2A:	lda	M_RSTAT		;fetch current Status Byte
	and	#$0F		;get channel nibble
	cmp	CHAN		;is it the one we are "effecting"
	beq	UR2B		;yes? branch...
	lda	CHAN		;no? fetch effect channel
	cmp	#16		;is it "ALL"?
	beq	UR2B		;yes? branch...
	jmp	SENDIT		;no? jump...

	;--- x now holds a velocity byte ready for modification

UR2B:	cpx	#0		;compare velocity value
	bne	EFFGAT		;nonzero? branch...
	jmp	SENDIT		;=0? jump...

	;--- gate processor (velocity is in x)

EFFGAT: cpx	GTVAL		;is velocity > or = threshold?
	bhs	EFFCX		;yes? branch...
	lda	#1		;no? set LED flag
	sta	LEDGAT		;
	lda	#$00		;load gated velocity
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

	;--- compression/expansion processor (velocity is in x)

EFFCX:	lda	CERATIO 	;fetch comp/exp ratio
	beq	EFFLIM		;=0? branch...
	lda	CEX		;nonzero? get comp/exp flag
	beq	EFFCXA		;=0 (compression)? branch...
	lda	#1		;=1 (expansion)? set LED flag
	sta	LEDEXP		;
	jmp	EFFCXB		;jump...
EFFCXA: lda	#1		;set LED flag
	sta	LEDCMP		;

EFFCXB: lda	CEVAL		;fetch comp/exp value (0-127)
	mul			;calculate [velocity*CEVAL]/64
	lsla			;
	rolx			;
	lsla			;
	rolx			;use MSB only (in x)
	txa			;transfer to acca
	sub	CEVAL		;acca value=(acca-CEVAL)
	bcc	EFFCXC		;result not negative? branch...
	add	#64		;negative? add 64 now
	bcs	EFFCXD		;did result go positive? branch...
	lda	#1		;still negative? load minimum vel
	jmp	EFFCXD		;jump...

EFFCXC: add	#64		;initial result valid, add 64 now
	bpl	EFFCXD		;result<128? branch...
	lda	#127		;result> or =127? set maximum vel
EFFCXD: tax			;transfer new velocity to x

	;--- limiter processor (velocity is in x)

EFFLIM: cpx	LMVAL		;is velocity < or = threshold?
	bls	EFFDLY		;yes? branch...
	lda	#1		;no? set LED flag
	sta	LEDLIM		;
	ldx	LMVAL		;load limited velocity value

	;--- delay processor (velocity is in x)

EFFDLY: lda	ALVAL		;fetch algorithm
	bne	EFFDA		;nonzero? branch...
	jmp	SENDIT		;=0? jump...

EFFDA:	lda	M_RSTAT		;fetch Status Byte
	sta	DLSTAT		;save for delayed note processor
	lda	M_DATA1 	;fetch note number
	sta	DLNOTE		;save for delayed note processor
	stx	DLVEL		;save velocity for note proc
	txa			;transfer velocity to acca
	jsr	MIDI_PUT	;send it
	clr	M_CLK_CNTR	;reset clock counter

	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;
	clr	TDOWN		;clear timer down flag
	rti			;return, do not buffer
