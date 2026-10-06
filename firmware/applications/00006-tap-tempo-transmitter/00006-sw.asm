;===============================================================;
;								;
;       TOOL05.ASM      Rev 1.0 29-Aug-93                       ;
;       Tap Tempo Transmitter                                   ;
;								;
;	The user can control sequence playback by tapping a	;
;       key according to the desired tempo.                     ;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...PREPARE MY SEQUENCER?				;
;	Following the sequencer's instruction manual, enter     ;
;	CHASE LOCK MODE or MIDI SYNC MODE.			;
;								;
;								;
;       ...SET THE INITIAL (ESTIMATED) TEMPO?                   ;
;	With the sequencer stopped, an estimate of the initial	;
;       tempo should be entered with the +/- keys and/or the    ;
;       tempo fader.                                            ;
;								;
;								;
;	...START SEQUENCE PLAYBACK FROM THE BEGINNING?		;
;	Press the START key.  The sequencer will play from	;
;	the first beat of the first measure. Continue playing	;
;	the sequence by tapping the BEAT key once for each	;
;	subsequent beat.					;
;								;
;								;
;       ...MANUALLY CONTROL THE TEMPO OF THE SEQUENCE?          ;
;	Press and release the BEAT key once for each beat.	;
;	The user controls the sequence playback speed.	The	;
;       LCD gives the approximate tempo in quarter notes per    ;
;	minute (QPM).						;
;								;
;								;
;       ...ENABLE THE TEMPO SMOOTHING FUNCTION (TSF)?           ;
;       A tempo smoothing function can be enabled by pressing   ;
;	the TSF key.  Smoothing function status is given in	;
;	the LCD.						;
;								;
;								;
;	...STOP THE SEQUENCER?					;
;	Press the STOP key.  The sequencer will stop at the	;
;       end of the current measure.  When stopped, the tempo    ;
;       can be modified using the +/- keys and/or tempo fader.  ;
;								;
;								;
;	...CONTINUE PLAYBACK FROM WHERE IT WAS STOPPED? 	;
;	Press the CONT key.  The sequencer will start playing	;
;	from the first beat of the current measure.  Continue	;
;	playing the sequence with the BEAT key, as above.	;
;								;
;								;
;	...KNOW IF THE SEQUENCE IS STOPPED OR NOT?		;
;	Playback status is indicated by the STOPPED and 	;
;	PLAYING LEDs.						;
;								;
;								;
;	...AUTOMATICALLY CONTROL SEQUENCE PLAYBACK?		;
;	With the sequence playing, press the AUTO key.	In	;
;	AUTO mode, sequence playback is controlled		;
;       automatically at the current tempo.  Pressing the       ;
;	BEAT key at any time while autoplaying returns control	;
;	to the user (MANUAL mode).				;
;								;
;	With the sequencer stopped, playback mode is changed	;
;	each time the AUTO key is pressed.  In AUTO mode,	;
;	pressing START or CONT initiates automatic playback.	;
;								;
;       While autoplaying, the tempo can be modified with the   ;
;	+/- keys.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	|QPM   MODE   TSF|	where eee=20-255, vvv="ON"      ;
;	|eee  ffffff  vvv|	or "OFF", ffffff="MANUAL"       ;
;				or "AUTO"                       ;
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
;	State:							;
;								;
;	StOp		Sequencer stopped			;
;	StPl		Sequencer playing			;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	START		Send Start message			;
;	CONT		Send Continue message			;
;	STOP		Send Stop message			;
;       TEMINC          Increment tempo                         ;
;       TEMDEC          Decrement tempo                         ;
;	TEMFDR		Set M_TEMPO with fader			;
;	CLK24		Transmit 24 clocks and calculate QPM	;
;       TSFTOG          Toggle tempo Smoothing Function status  ;
;	AUTOPL		Set autoplay mode			;
;	AUTTOG		Toggle playback mode status		;
;	MDISP		Update display with playback mode	;
;       TDISP           Update display with tempo value         ;
;	LEDSTP		Control STOPPED LED			;
;	LEDPLY		Control PLAYING LED			;
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

COUNTEMP        .DS     1       ;temporary counter value
TLSB            .DS     1       ;temporary tempo LSB value
TMSB            .DS     1       ;temporary tempo MSB value
SMOOTH		.DS	1	;TSF flag (1=on)
AUTOPLAY	.DS	1	;autoplay mode flag (1=autoplay)

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp		EQU	0
StPl		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvStart 	EQU	EV_SW1_ON
EvCont		EQU	EV_SW2_ON
EvStop		EQU	EV_SW3_ON
EvBeat		EQU	EV_SW4_ON
EvTSF		EQU	EV_SW5_ON
EvMinus 	EQU	EV_SW6_ON
EvPlus		EQU	EV_SW7_ON
EvAuto		EQU	EV_SW8_ON
EvTempo         EQU     EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;		  State 0: StOp State 1: StPl		      Not
;	 Event	  NextSt,Act	NextSt,Act		     Used
;	 --------------------------------------------------------
 STM_ROW EvIdle,  StOp,IDLE,	StPl,IDLE,   StOp,IDLE, StOp,IDLE
 STM_ROW EvStart, StPl,START,	StPl,IDLE,   StOp,IDLE, StOp,IDLE
 STM_ROW EvCont,  StPl,CONT,	StPl,IDLE,   StOp,IDLE, StOp,IDLE
 STM_ROW EvStop,  StOp,IDLE,	StOp,STOP,   StOp,IDLE, StOp,IDLE
 STM_ROW EvBeat,  StOp,IDLE,	StPl,CLK24,  StOp,IDLE, StOp,IDLE
 STM_ROW EvTSF,   StOp,TSFTOG,	StPl,TSFTOG, StOp,IDLE, StOp,IDLE
 STM_ROW EvMinus, StOp,TEMDEC,	StPl,TEMDEC, StOp,IDLE, StOp,IDLE
 STM_ROW EvPlus,  StOp,TEMINC,	StPl,TEMINC, StOp,IDLE, StOp,IDLE
 STM_ROW EvAuto,  StOp,AUTTOG,	StPl,AUTOPL, StOp,IDLE, StOp,IDLE
 STM_ROW EvTempo, StOp,TEMFDR,  StPl,IDLE,   StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	TLSB		;
	sta	TMSB		;

	lda	#1		;
	sta	SMOOTH		;
	sta	AUTOPLAY	;

	clr	COUNTEMP	;clear counter

	clr	M_PLAY	;clear flag

;--- Initialize MIDI

	SCI_RX_INT_DIS 	;disable MIDI receiver interrupts

        lda     #100            ;set initial tempo
        jsr     MIDI_TEMPO      ;

	lda	#$40		;enable timer interrupts
	sta	TCR		;

;--- Initialize display

	jsr	GREETING

        LCD_PUT_S "5:     Tap Tempo"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0 Transmitter"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "QPM   MODE   TSF"

	jsr	LEDSTP		;control status LED
	jsr	TDISP		;update display
	jsr	TSFTOG		;TSF off and update display
	jsr	AUTTOG		;AUTOPLAY off and update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Send Start message

START:	clr	TCR		;disable timer interrupts
	inc	M_PLAY	;flag playing status

	lda	#$FA		;send Start message
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	lda	#$F8		;send one MIDI clock
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
	inc	M_PLAY	;flag playing status

	lda	#$FB		;send Continue message
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	lda	#$F8		;send one MIDI clock
	jsr	MIDI_PUT	;
	lda	#$F8		;send another MIDI clock (to
	jsr	MIDI_PUT	; finish at the end of a beat)

	jsr	LEDPLY		;update display
	clr	M_CLK_CNTR	;continue from mesure beginning

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

STOP:	lda	M_CLK_CNTR	;wait for end of measure
	cmp	#24		;
	blo	STOP		;

	jsr	MIDI_STOP	;stop the sequencer
	jsr	LEDSTP		;update display
	rts

;--- Increment tempo

TEMINC: lda	M_PLAY	;are we playing?
	beq	TIGO		;no? branch...
	lda	AUTOPLAY	;yes? are we in manual mode?
	beq	TIEND		;yes? branch...

TIGO:	lda	M_TEMPO		;fetch M_TEMPO
	inca			;increment
	cmp	#19		;<20 ("above" 255)?
	bhi	TIA		;no? branch...
	lda	#20		;yes? wrap to 20

TIA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
TIEND:	rts

;--- Decrement tempo

TEMDEC: lda     M_PLAY          ;are we playing?
	beq	TDGO		;no? branch...
	lda	AUTOPLAY	;yes? are we in manual mode?
	beq	TDEND		;yes? branch...

TDGO:	lda	M_TEMPO		;fetch M_TEMPO
	deca			;decrement
	cmp	#19		;<20? ("above" 255)?
	bhi	TDA		;no? branch...
	lda	#255		;yes? wrap to 255

TDA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
TDEND:	rts

;--- Set tempo with fader

TEMFDR: lda	FDR		;fetch fader value
	cmp	#19		;>19?
	bhi	TFA		;yes? branch...
	lda	#20		;no? stay at 20

TFA:    jsr     MIDI_TEMPO      ;update M_TEMPO
	jsr	TDISP		;update display
	rts

;--- Transmit 24 clocks and calculate QPM

CLK24:	clr	TCR		;stop clock
	lda	AUTOPLAY	;are we autoplaying?
	beq	CGO		;no? branch...

	clr	AUTOPLAY	;yes? clear autoplay flag
	jsr	MDISP		;update display

	lda	M_CLK_CNTR	;fetch counter
	cmp	#12		;are we in the 2nd half beat?
	bhi	CGO		;yes? branch...
	lda	#$40		;1st half? finish beat, continue
	sta	TCR		;enable timer interrupts
	rts			;return

CGO:	lda	M_CLK_CNTR	;fetch counter
	sta	COUNTEMP	;save value

	cmp	#24		;24 or more clocks counted?
	bhs	CALCTEM 	;yes? branch...

CSPIT:	lda	#$F8		;no? send a MIDI clock
	jsr	MIDI_PUT	;
	lda	M_CLK_CNTR	;fetch counter
	cmp	#23		;finished?
	beq	CALCTEM 	;yes? branch...
	inc	M_CLK_CNTR	;no? increment counter value
	jmp	CSPIT		;loop

CALCTEM:
	lda	SMOOTH		;fetch TSF status
	bne	STEM		;=1 (on)? branch...

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
	jmp	CEND		;jump...

CMAX:	lda	#255		;new M_TEMPO=255
        jsr     MIDI_TEMPO      ;save new M_TEMPO
	jmp	CEND		;jump...

;
; SMOOTH FORMULA:   K=24-(COUNTEMP)
;		    --> if K<0, decrement M_TEMPO
;		    --> if K>0, increment M_TEMPO
;		    --> if K=0, M_TEMPO is unchanged
;

STEM:	lda	COUNTEMP	;fetch clock counter
	cmp	#24		;compare to 24
	blo	SCINC		;less than 24? branch...
	bhi	SCDEC		;greater than 24? branch...
	jmp	CEND		;equal to 24? jump...

SCINC:	lda	M_TEMPO		;fetch current M_TEMPO
	cmp	#255		;is it =255?
	beq	CEND		;yes? branch...
	inca			;no? increment it
        jsr     MIDI_TEMPO      ;save new M_TEMPO
	jmp	CEND		;jump...

SCDEC:	lda	M_TEMPO		;fetch current M_TEMPO
	cmp	#20		;is it =20?
	beq	CEND		;yes? branch...
	deca			;no? decrement it
        jsr     MIDI_TEMPO      ;save new M_TEMPO

CEND:	jsr	TDISP		;update display
	clr	M_CLK_CNTR	;reset clock counter

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

;--- Toggle tempo Smoothing Function status

TSFTOG: lda	SMOOTH		;fetch smoothing flag
	beq	TSFA		;=0 (off)? branch...

	clr	SMOOTH		;=1 (on)? reset TSF flag
	lda	#13		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OFF"         ;
	rts

TSFA:	inc	SMOOTH		;set TSF flag
	lda	#13		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " ON"         ;
	rts

;--- Set autoplay mode

AUTOPL: lda	#1		;set autoplay flag
	sta	AUTOPLAY	;
	jsr	MDISP		;update display
	rts

;--- Toggle playback mode status

AUTTOG: lda	AUTOPLAY	;fetch autoplay flag
	beq	ATA		;=0? branch...
	clr	AUTOPLAY	;=1? clear flag
	jmp	ATB		;jump...

ATA:	inc	AUTOPLAY	;set flag

ATB:	jsr	MDISP		;update display
	rts

;--- Update display with playback mode

MDISP:	lda	AUTOPLAY	;fetch flag
	bne	ADON		;=1? branch...

	lda	#5		;=0? update display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "MANUAL"      ;
	rts

ADON:	lda	#5		;update display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " AUTO "      ;
	rts

;--- Update display with tempo value

TDISP:	lda	#2		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	M_TEMPO		;fetch M_TEMPO
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Control STOPPED LED

LEDSTP: lda	#15		;turn PLAYING LED off
	jsr	LED_OFF 	;
	lda	#3		;turn STOPPED LED on
	jsr	LED_ON		;
	rts

;--- Control PLAYING LED

LEDPLY: lda	#3		;turn STOPPED LED off
	jsr	LED_OFF 	;
	lda	#15		;turn PLAYING LED on
	jsr	LED_ON		;
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

	lda	M_PLAY	;are we playing?
	bne	THA		;yes? branch...

	lda	#$F8		;no? load MIDI clock
	jsr	MIDI_PUT	;send it
	rti

THA:	lda	AUTOPLAY	;autoplay mode?
	bne	THB		;yes? branch...

	lda	M_CLK_CNTR	;no? fetch counter
	cmp	#24		;24 or higher? do not transmit
	bhs	THD		; any more MIDI clocks

THB:	lda	M_CLK_CNTR	;fetch counter
	cmp	#24		;
	blo	THE		;<24? branch...
	clr	M_CLK_CNTR	;=24? clear counter

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

