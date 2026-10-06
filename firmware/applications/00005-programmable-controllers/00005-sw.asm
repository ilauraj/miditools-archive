;===============================================================;
;								;
;       TOOL03.ASM      Rev 1.0  29-Aug-93                      ;
;	Programmable Controllers				;
;								;
;	The user can program and use three independent MIDI	;
;	controllers.						;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A CONTROLLER? 				;
;	Press the desired CONTROLLER SELECT key: A, B or C.	;
;	One of three independent controllers is selected for	;
;	programming and/or use. 				;
;								;
;								;
;	...SET THE SELECTED CONTROLLER'S TRANSMIT CHANNEL?      ;
;	Press the SETUP CHAN key.  The MIDI transmit channel	;
;	is set using the +/- keys and/or the VALUE fader.	;
;								;
;								;
;	...SET THE SELECTED CONTROLLER'S NUMBER?                ;
;	Press the SETUP CTL key.  The controller number is	;
;	assigned using the +/- keys and/or the VALUE fader.	;
;								;
;								;
;	...TRANSMIT MESSAGES USING THE SELECTED CONTROLLER?	;
;	Press the DATA key.  The VALUE fader and/or the +/-	;
;	keys are used to transmit MIDI controller messages.	;
;	The LCD gives all parameters and transmitted data	;
;	values for the selected controller.			;
;								;
;	Generated data are merged with incoming MIDI messages.	;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	|x: CH	CTL  DATA|	where x=A,B or C, nn=1-16,	;
;	|   nn	bbb   bbb|	bbb=0-127			;
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
;	StCh		Set transmit channel			;
;	StCtl		Set controller number			;
;	StData		Transmit controller messages		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	CTLINC		Increment controller number		;
;	CTLDEC		Decrement controller number		;
;	CTLFDR		Set controller number with fader	;
;	DATINC		Increment data value and transmit msg	;
;	DATDEC		Decrement data value and transmit msg	;
;	DATFDR		Set value with fader and transmit msg	;
;	CHDISP		Update display for changing channel	;
;	CTDISP		Update display for changing controller	;
;	DTDISP		Update display for setting data value	;
;	ADISP		Update display with Controller A data	;
;	BDISP		Update display with Controller B data	;
;	CDISP		Update display with Controller C data	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

INDEX		.DS	1	;active controller marker
CHAN		.DS	1	;MIDI channel
CHANA		.DS	1	;Controller A MIDI channel
CHANB		.DS	1	;Controller B MIDI channel
CHANC		.DS	1	;Controller C MIDI channel
CTL		.DS	1	;controller number
CTLA		.DS	1	;Controller A number
CTLB		.DS	1	;Controller B number
CTLC		.DS	1	;Controller C number
DATAVAL 	.DS	1	;MIDI data byte
DATAPREV	.DS	1	;previous MIDI data value
DATAPREVA	.DS	1	;Controller A previous data value
DATAPREVB	.DS	1	;Controller B previous data value
DATAPREVC	.DS	1	;Controller C previous data value

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StCtl		EQU	1
StData		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvChan		EQU	EV_SW1_ON
EvCtl		EQU	EV_SW2_ON
EvData		EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvA		EQU	EV_SW5_ON
EvB		EQU	EV_SW6_ON
EvC		EQU	EV_SW7_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0: StCh  State 1: StCtl State 2: StData      Not
;	 Event	  NextSt,Act	 NextSt,Act	NextState,Act	    Used
;	 ---------------------------------------------------------------
 STM_ROW EvIdle,  StCh,IDLE,	 StCtl,IDLE,	StData,IDLE,   StCh,IDLE
 STM_ROW EvPlus,  StCh,CHINC,	 StCtl,CTLINC,	StData,DATINC, StCh,IDLE
 STM_ROW EvMinus, StCh,CHDEC,	 StCtl,CTLDEC,	StData,DATDEC, StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,	 StCtl,CTLFDR,	StData,DATFDR, StCh,IDLE
 STM_ROW EvChan,  StCh,IDLE,	 StCh,CHDISP,	StCh,CHDISP,   StCh,IDLE
 STM_ROW EvCtl,   StCtl,CTDISP,  StCtl,IDLE,	StCtl,CTDISP,  StCh,IDLE
 STM_ROW EvData,  StData,DTDISP, StData,DTDISP, StData,IDLE,   StCh,IDLE
 STM_ROW EvA,	  StData,ADISP,  StData,ADISP,	StData,ADISP,  StCh,IDLE
 STM_ROW EvB,	  StData,BDISP,  StData,BDISP,	StData,BDISP,  StCh,IDLE
 STM_ROW EvC,	  StData,CDISP,  StData,CDISP,	StData,CDISP,  StCh,IDLE

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

	lda	#$00		;default values
	sta	CHAN		;
	sta	CHANA		;
	sta	CHANB		;
	sta	CHANC		;
	sta	CTL		;
	sta	CTLA		;
	sta	CTLB		;
	sta	CTLC		;
	sta	DATAPREV	;
	sta	DATAPREVA	;
	sta	DATAPREVB	;
	sta	DATAPREVC	;
	sta	DATAVAL		;

	lda	#1		;
	sta	INDEX		;

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "3:  Programmable"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0 Controllers"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "A: CH  CTL  DATA"

	jsr	CTDISP		;update display
	jsr	DTDISP		;
	jsr	CHDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment channel

CHINC:	lda	CHAN		;fetch channel
	inca			;increment
	cmp	#15		;valid range: 0-15
	bls	CIA		;< or =15? branch...
	lda	#0		;>15? wrap to 0
CIA:	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Decrement channel

CHDEC:	lda	CHAN		;fetch channel
	deca			;increment
	cmp	#15		;valid range: 0-15
	bls	CDA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
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

;--- Increment controller number

CTLINC: lda	CTL		;fetch controller number
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	CTL		;store new value
	jsr	CTDISP		;update display
	rts

;--- Decrement controller number

CTLDEC: lda	CTL		;fetch controller number
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	CTL		;store new value
	jsr	CTDISP		;update display
	rts

;--- Set controller number with fader

CTLFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	CTL		;store new value
	jsr	CTDISP		;update display
	rts

;--- Increment data value and transmit msg

DATINC: lda	DATAVAL 	;fetch data value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DTDISP		;update display
	jmp	MSGSND		;jump...

;--- Decrement data value and transmit msg

DATDEC: lda	DATAVAL 	;fetch data value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DTDISP		;update display
	jmp	MSGSND		;jump...

;--- Set value with fader and transmit msg

DATFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DTDISP		;update display

;--- Transmit controller message

MSGSND: lda	DATAVAL 	;if DATAVAL=DATAPREV,
	cmp	DATAPREV	; do not transmit
	bne	MSA		;
	rts			;

MSA:	ldx	M_FULL_MSG 	;wait if in the middle of
	beq	MSA		; receiving a message

	sei			;disable all interrupts
	sta	DATAPREV	;update DATAPREV

	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	CTL		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	MSB		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

MSB:	cli			;enable all interrupts
	rts

;--- Update display for changing channel

CHDISP: lda	#6		;clear CTL arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;clear DATA arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#2		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#4		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for changing controller number

CTDISP: lda	#2		;clear CH arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;clear DATA arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;place CTL arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CTL		;fetch controller number
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for setting data value

DTDISP: lda	#2		;clear CH arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;clear CTL arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;place DATA arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DATAVAL 	;fetch data value
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display with Controller A values

ADISP:	lda	INDEX		;branch off active index
	cmp	#2		;
	beq	ADA		;...if B
	cmp	#3		;
	beq	ADB		;...if C
	jsr	DTDISP		;...if A, update diplay
	rts			;

ADA:	lda	CHAN		;send B values into storage
	sta	CHANB		;
	lda	CTL		;
	sta	CTLB		;
	lda	DATAVAL 	;
	sta	DATAPREVB	;
	jmp	ADC		;jump

ADB:	lda	CHAN		;send C values into storage
	sta	CHANC		;
	lda	CTL		;
	sta	CTLC		;
	lda	DATAVAL 	;
	sta	DATAPREVC	;

ADC:	lda	CHANA		;recall A values from storage
	sta	CHAN		;
	lda	CTLA		;
	sta	CTL		;
	lda	DATAPREVA	;
	sta	DATAVAL 	;
	sta	DATAPREV	;

	lda	#0		;notify user
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "A"           ;

	jsr	CHDISP		;update display
	jsr	CTDISP		;
	jsr	DTDISP		;

	lda	#1		;set active controller marker
	sta	INDEX		;
	rts

;--- Update display with Controller B data

BDISP:	lda	INDEX		;branch off active index
	cmp	#1		;
	beq	BDA		;...if A
	cmp	#3		;
	beq	BDB		;...if C
	jsr	DTDISP		;...if B, update diplay
	rts			;

BDA:	lda	CHAN		;send A values into storage
	sta	CHANA		;
	lda	CTL		;
	sta	CTLA		;
	lda	DATAVAL 	;
	sta	DATAPREVA	;
	jmp	BDC		;jump

BDB:	lda	CHAN		;send C values into storage
	sta	CHANC		;
	lda	CTL		;
	sta	CTLC		;
	lda	DATAVAL 	;
	sta	DATAPREVC	;

BDC:	lda	CHANB		;recall B values from storage
	sta	CHAN		;
	lda	CTLB		;
	sta	CTL		;
	lda	DATAPREVB	;
	sta	DATAVAL 	;
	sta	DATAPREV	;

	lda	#0		;notify user
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "B"           ;

	jsr	CHDISP		;update display
	jsr	CTDISP		;
	jsr	DTDISP		;

	lda	#2		;set active controller marker
	sta	INDEX		;
	rts

;--- Update display with Controller C data

CDISP:	lda	INDEX		;branch off active index
	cmp	#1		;
	beq	CDSA		;...if A
	cmp	#2		;
	beq	CDB		;...if B
	jsr	DTDISP		;...if C, update diplay
	rts			;

CDSA:	lda	CHAN		;send A values into storage
	sta	CHANA		;
	lda	CTL		;
	sta	CTLA		;
	lda	DATAVAL 	;
	sta	DATAPREVA	;
	jmp	CDC		;jump

CDB:	lda	CHAN		;send B values into storage
	sta	CHANB		;
	lda	CTL		;
	sta	CTLB		;
	lda	DATAVAL 	;
	sta	DATAPREVB	;

CDC:	lda	CHANC		;recall C values from storage
	sta	CHAN		;
	lda	CTLC		;
	sta	CTL		;
	lda	DATAPREVC	;
	sta	DATAVAL 	;
	sta	DATAPREV	;

	lda	#0		;notify user
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "C"           ;

	jsr	CHDISP		;update display
	jsr	CTDISP		;
	jsr	DTDISP		;

	lda	#3		;set active controller marker
	sta	INDEX		;
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

SCI_RX_CBCK_S:
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D1:
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D2:
        MIDI_ISR_LOOPBACK


