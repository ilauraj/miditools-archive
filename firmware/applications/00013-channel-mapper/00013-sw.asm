;===============================================================;
;								;
;       TOOL12.ASM      Rev 0.4                                 ;
;	Channel Mapper						;
;								;
;	The user can map incoming messages on one MIDI channel	;
;	to a different channel. 				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT THE CHANNEL TO MAP?				;
;	Press the CHANNEL IN key.  The channel to be mapped is	;
;	selected using the +/- keys and/or the VALUE fader.	;
;								;
;								;
;	...SELECT THE NEW CHANNEL?				;
;	Press the CHANNEL OUT key.  The new channel is		;
;	selected using the +/- keys and/or the VALUE fader.	;
;								;
;								;
;	...OPERATE THE MAPPER?					;
;	All messages on the IN channel are retransmitted on	;
;	the new OUT channel.  Data bytes are not modified.	;
;	The DATA MAPPED LED lights when data are being mapped.	;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	| CHANNEL MAPPER |	where nn=1-16			;
;	| IN:nn   OUT:nn |					;
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
;	StCIn		Select input channel			;
;	StCOut		Select output channel			;
;								;
;	Actions:						;
;								;
;	IDLE		No action (administer LED)		;
;	CIINC		Increment channel IN number		;
;	CIDEC		Decrement channel IN number		;
;	CIFDR		Set channel IN with fader		;
;	COINC		Increment channel OUT number		;
;	CODEC		Decrement channel OUT number		;
;	COFDR		Set channel OUT with fader		;
;	CIDISP		Update channel IN display		;
;	CODISP		Update channel OUT display		;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CIN		.DS	1	;IN channel number
COUT		.DS	1	;OUT channel number
MAPLED		.DS	1	;LED flag

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCin		EQU	0
StCout		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvChanIn	EQU	EV_SW2_ON
EvChanOut	EQU	EV_SW3_ON
EvMinus 	EQU	EV_SW6_ON
EvPlus		EQU	EV_SW7_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                   State 0: StCin State 1: StCout                  Not
;	 Event	    NextSt,Act	   NextSt,Act			   Used
;	 --------------------------------------------------------------
 STM_ROW EvIdle,    StCin,IDLE,    StCout,IDLE,  StCin,IDLE, StCin,IDLE
 STM_ROW EvPlus,    StCin,CIINC,   StCout,COINC, StCin,IDLE, StCin,IDLE
 STM_ROW EvMinus,   StCin,CIDEC,   StCout,CODEC, StCin,IDLE, StCin,IDLE
 STM_ROW EvValue,   StCin,CIFDR,   StCout,COFDR, StCin,IDLE, StCin,IDLE
 STM_ROW EvChanIn,  StCin,IDLE,    StCin,CIDISP, StCin,IDLE, StCin,IDLE
 STM_ROW EvChanOut, StCout,CODISP, StCout,IDLE,  StCin,IDLE, StCin,IDLE

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

	lda	#0		;default values
	sta	CIN		;
	sta	COUT		;

	clr	MAPLED		;clear flag

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "12:      Channel"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Mapper"
	jsr	DELAY_1SEC

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " CHANNEL MAPPER "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S " IN:     OUT:   "

	jsr	CODISP		;update display
	jsr	CIDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action (administer LED)

IDLE:	lda	MAPLED		;fetch mapped data flag
	beq	IDLEA		;=0 (no data mapped)? branch...

	lda	#3		;=1 (data mapped)? blink LED
	jsr	LED_ON		;
	jsr	DELAY_1MS	;
	lda	#3		;
	jsr	LED_OFF 	;
	clr	MAPLED		;clear flag
IDLEA:	rts

;--- Increment channel IN number

CIINC:	lda	CIN		;fetch input channel
	inca			;increment
	cmp	#15		;valid range: 0-15
	bls	CIIA		;< or =15? branch...
	lda	#0		;>15? wrap to 0
CIIA:	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Decrement channel IN number

CIDEC:	lda	CIN		;fetch input channel
	deca			;decrement
	cmp	#15		;valid range: 0-15
	bls	CIDA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
CIDA:	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Set channel IN with fader

CIFDR:	lda	FDR		;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Increment channel OUT number

COINC:	lda	COUT		;fetch output channel
	inca			;increment
	cmp	#15		;valid range: 0-15
	bls	COIA		;< or =15? branch...
	lda	#0		;>15? wrap to 0
COIA:	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Decrement channel OUT number

CODEC:	lda	COUT		;fetch output channel
	deca			;decrement
	cmp	#15		;valid range: 0-15
	bls	CODA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
CODA:	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Set channel OUT with fader

COFDR:	lda	FDR		;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Update channel IN display

CIDISP: lda	#8		;clear OUT arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;place IN arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#5		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CIN		;fetch input channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update channel OUT display

CODISP: lda	#0		;clear IN arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#8		;place OUT arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	COUT		;fetch output channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
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

;--- Service Status Byte (class is in acca; byte is in x)

SCI_RX_CBCK_S:
	txa			;transfer byte to acca
	cmp	#$F0		;is it a System Message?
	bhs	SENDIT		;yes? branch...
	and	#$0F		;no? get channel
	cmp	CIN		;is it the one to map?
	bne	SENDIT		;no? branch...
	inc	MAPLED		;yes? set LED flag
	txa			;transfer byte to acca
	and	#$F0		;get status nibble
	add	COUT		;add new channel
	jsr	MIDI_PUT	;send byte
	rti			;return, do not buffer

SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer

;--- Service Data Bytes

SCI_RX_CBCK_D1:
SCI_RX_CBCK_D2:
	jmp	SENDIT		;jump...
