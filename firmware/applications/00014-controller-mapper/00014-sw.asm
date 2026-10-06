;===============================================================;
;								;
;       TOOL13.ASM      Rev 0.4                                 ;
;	Controller Mapper					;
;								;
;	The user can map incoming controller messages to a	;
;	different controller number.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A CONTROLLER TO MAP?				;
;	Press the CONTROLLER IN key.  The controller to be	;
;	mapped is selected using the +/- keys and/or the VALUE	;
;	fader.							;
;								;
;								;
;	...SELECT THE NEW CONTROLLER?				;
;	Press the CONTROLLER OUT key.  The new controller	;
;	number is selected using the +/- keys and/or the VALUE	;
;	fader.							;
;								;
;								;
;	...OPERATE THE MAPPER?					;
;	All messages of the IN controller number are		;
;	retransmitted as the new OUT controller.  Data bytes	;
;	are not modified.  The DATA MAPPED LED lights when	;
;	data are being mapped.	The last mapped message's       ;
;	channel and value are displayed.			;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	|CH VAL   IN  OUT|	where nn=1-16, bbb=0-127	;
;	|nn bbb  bbb  bbb|					;
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
;	StCIn		Select input controller 		;
;	StCOut		Select output controller		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CIINC		Increment controller IN number		;
;	CIDEC		Decrement controller IN number		;
;	CIFDR		Set controller IN with fader		;
;	COINC		Increment controller OUT number 	;
;	CODEC		Decrement controller OUT number 	;
;	COFDR		Set controller OUT with fader		;
;	CIDISP		Update display for controller IN	;
;	CODISP		Update display for controller OUT	;
;	MSGMAP		Update display with message info	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CIN		.DS	1	;IN controller number
COUT		.DS	1	;OUT controller number
TEMPCLASS	.DS	1	;M_TEMPOrary class storage
TEMPVAL 	.DS	1	;M_TEMPOrary value storage

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCin		EQU	0
StCout		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvCtlIn 	EQU	EV_SW2_ON
EvCtlOut	EQU	EV_SW3_ON
EvMinus 	EQU	EV_SW6_ON
EvPlus		EQU	EV_SW7_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;                  State 0: StCin State 1: StCout                   Not
;	 Event	   NextSt,Act	  NextSt,Act			   Used
;	 --------------------------------------------------------------
 STM_ROW EvIdle,   StCin,IDLE,	  StCout,IDLE,	 StCin,IDLE, StCin,IDLE
 STM_ROW EvPlus,   StCin,CIINC,   StCout,COINC,  StCin,IDLE, StCin,IDLE
 STM_ROW EvMinus,  StCin,CIDEC,   StCout,CODEC,  StCin,IDLE, StCin,IDLE
 STM_ROW EvValue,  StCin,CIFDR,   StCout,COFDR,  StCin,IDLE, StCin,IDLE
 STM_ROW EvCtlIn,  StCin,IDLE,	  StCin,CIDISP,  StCin,IDLE, StCin,IDLE
 STM_ROW EvCtlOut, StCout,CODISP, StCout,IDLE,	 StCin,IDLE, StCin,IDLE
 STM_ROW EvMsgIn,  StCin,MSGMAP,  StCout,MSGMAP, StCin,IDLE, StCin,IDLE

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
	sta	TEMPCLASS	;
	sta	TEMPVAL 	;

;--- Initialize MIDI

	lda	#$10		;buffer controller messages
	sta	M_RX_Q_XPT		;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "13:   Controller"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Mapper"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "CH VAL   IN  OUT"

	lda	#0		;default message
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "-- ---"      ;

	jsr	CODISP		;update display
	jsr	CIDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment controller IN number

CIINC:	lda	CIN		;fetch input controller number
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Decrement controller IN number

CIDEC:	lda	CIN		;fetch input controller number
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Set controller IN with fader

CIFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	CIN		;store new value
	jsr	CIDISP		;update display
	rts

;--- Increment controller OUT number

COINC:	lda	COUT		;fetch output controller number
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Decrement controller OUT number

CODEC:	lda	COUT		;fetch output controller number
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Set controller OUT with fader

COFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	COUT		;store new value
	jsr	CODISP		;update display
	rts

;--- Update display for controller IN

CIDISP: lda	#12		;clear OUT arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#7		;place IN arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#10		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CIN		;fetch input controller number
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for controller OUT

CODISP: lda	#7		;clear IN arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;place OUT arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	COUT		;fetch output controller number
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display with message info

MSGMAP: lda	MP_DATA1		;get received controller number
	cmp	CIN		; (stored in buffer unmapped!!!)
	bne	MMA		;no match? branch...

	lda	#3		;match? blink LED
	jsr	LED_ON		;
	lda	#3		;
	jsr	LED_OFF 	;

	lda	#1		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch mapped status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#5		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_DATA2		;fetch controller value
	jsr	LCD_PUT_RJ3_I	;display it
MMA:	rts

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

;--- Service Status Bytes and 2nd Data Bytes

SCI_RX_CBCK_S:
SCI_RX_CBCK_D2:
	sta	TEMPCLASS	;save class
	stx	TEMPVAL 	;save value
	jmp	SENDIT		;jump...

;--- Service 1st Data Byte (class is in acca; byte is in x)

SCI_RX_CBCK_D1:
	sta	TEMPCLASS	;save class
	stx	TEMPVAL 	;save value
	cmp	#$10		;is it a controller message?
	bne	SENDIT		;no? jump...
	cpx	CIN		;yes? is it the one to map?
	bne	SENDIT		;no? jump...
	lda	COUT		;yes? fetch new controller
	jsr	MIDI_PUT	;send it
	lda	TEMPCLASS	;restore class
	ldx	TEMPVAL 	;restore value (unmapped!!!)
        jmp     SCI_RX_CBCK_D1_RET ;go buffer it

SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	lda	TEMPCLASS	;restore class
	ldx	TEMPVAL 	;restore value
        jmp     SCI_RX_CBCK_D1_RET ;go buffer it
