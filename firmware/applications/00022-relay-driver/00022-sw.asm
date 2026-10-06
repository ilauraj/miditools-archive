;===============================================================;
;								;
;       TOOL08.ASM      Rev 1.0                                 ;
;	Relay Driver						;
;								;
;	The user can manipulate four relays using MIDI		;
;	controller messages received on the same channel.	;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE GLOBAL MIDI RECEIVE CHANNEL? 		;
;	Press the SETUP CHAN key.  The global receive channel	;
;	is selected using the + key and/or the VALUE fader.	;
;								;
;								;
;	...SELECT A RELAY TO CONFIGURE? 			;
;	Press the SELECT key (A, B, C or D) to select a relay	;
;	for configuration and/or manual use.			;
;								;
;								;
;	...ASSIGN A CONTROLLER NUMBER TO EACH RELAY?		;
;	Press the SETUP CTL key.  The MIDI Controller number	;
;	used to control the selected relay is assigned using	;
;	the + key and/or the VALUE fader.  For proper		;
;	operation, each relay must be assigned to a unique	;
;	controller number.					;
;								;
;								;
;	...USE CONTROLLERS TO AUTOMATICALLY TRIGGER RELAYS?	;
;	For the assigned MIDI Controller, appropriate values	;
;	manipulate each relay as follows:			;
;								;
;		Controller Value	Action			;
;		----------------	------			;
;		less than 64		closes relay		;
;		64 or higher		opens relay		;
;								;
;	The corresponding RELAY CLOSED LED lights while the	;
;	relay is closed.					;
;								;
;								;
;	...MANUALLY CONTROL RELAYS?				;
;	Press the TOG key.  The currently selected relay will	;
;	change state.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When the selecting the global receive channel,		;
;								;
;	| MIDI           |	where nn = 1-16         	;
;	| CHANNEL:  nn   |	                                ;
;								;
;								;
;	When configuring and operating relays,			;
;								;
;	| -A- -B- -C- -D-|	where bbb = 0-120       	;
;	| bbb bbb bbb bbb|	                                ;
;								;
;	The cursor arrow points to the relay that will be	;
;	modified by the + key, VALUE fader, or TOG key. 	;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the RELAY board.  MIDI ports	;
;	used: IN and THRU only. 				;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StCh		Set receive channel			;
;	StRly   	Configure relays         		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CHINC		Increment channel			;
;	CHFDR		Set channel with fader			;
;	ASEL		Select Relay A				;
;	BSEL		Select Relay B				;
;	CSEL		Select Relay C				;
;	DSEL		Select Relay D				;
;	CTLINC		Increment Controller of selected relay	;
;	CTLFDR		Select Controller with fader		;
;	TOG		Toggle current relay status		;
;	RUPD8		Update relay status			;
;	PROC		Process incoming controller messages	;
;	CDISP		Update display for changing channel	;
;	RDISP		Update display for configuring relays	;
;	SDISP		Update relay status display		;
;	ARWCLR		Clear LCD cursor arrow			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.APPL_RAM
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel
CURRLY		.DS	1	;currently selected relay
RELAYA		.DS	1	;state of Relay A
RELAYB		.DS	1	;state of Relay B
RELAYC		.DS	1	;state of Relay C
RELAYD		.DS	1	;state of Relay D
CTLRA		.DS	1	;controller for Relay A
CTLRB		.DS	1	;controller for Relay B
CTLRC		.DS	1	;controller for Relay C
CTLRD		.DS	1	;controller for Relay D

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StRly   	EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvChan		EQU	EV_SW1_ON
EvPlus		EQU	EV_SW2_ON
EvCtl		EQU	EV_SW3_ON
EvTog   	EQU	EV_SW4_ON
EvA		EQU	EV_SW5_ON
EvB		EQU	EV_SW6_ON
EvC		EQU	EV_SW7_ON
EvD		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StCh State 1:StRly		      Not
;	 Event	  NextSt,Act   NextSt,Act		     Used
;	 --------------------------------------------------------
 STM_ROW EvIdle,  StCh,IDLE,   StRly,IDLE,   StCh,IDLE, StCh,IDLE
 STM_ROW EvPlus,  StCh,CHINC,  StRly,CTLINC, StCh,IDLE, StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,  StRly,CTLFDR, StCh,IDLE, StCh,IDLE
 STM_ROW EvChan,  StCh,IDLE,   StCh,CDISP,   StCh,IDLE, StCh,IDLE
 STM_ROW EvCtl,   StRly,RDISP, StRly,IDLE,   StCh,IDLE, StCh,IDLE
 STM_ROW EvA,	  StRly,RDISP, StRly,ASEL,   StCh,IDLE, StCh,IDLE
 STM_ROW EvB,	  StRly,RDISP, StRly,BSEL,   StCh,IDLE, StCh,IDLE
 STM_ROW EvC,	  StRly,RDISP, StRly,CSEL,   StCh,IDLE, StCh,IDLE
 STM_ROW EvD,	  StRly,RDISP, StRly,DSEL,   StCh,IDLE, StCh,IDLE
 STM_ROW EvTog,   StCh,TOG,    StRly,TOG,    StCh,IDLE, StCh,IDLE
 STM_ROW EvMsgIn, StCh,PROC,   StRly,PROC,   StCh,IDLE, StCh,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	CHAN		;
	sta	RELAYA		;
	sta	RELAYB		;
	sta	RELAYC		;
	sta	RELAYD		;

	sta	CTLRA		;
	inca			;
	sta	CTLRB		;
	inca			;
	sta	CTLRC		;
	inca			;
	sta	CTLRD		;

	lda	#'A'            ;
	sta	CURRLY		;

        X0_LO                   ;default expansion latch
        lda     #0              ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;

;--- Initialize MIDI

	lda	#$10		;buffer controller messages
	sta	M_RX_Q_XPT		;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "08:        Relay"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0      Driver"
	jsr	DELAY_1SEC

        jsr     LCD_CLEAR

	jsr	CDISP		;update display

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
        and     #$0F            ;constrain to 0-15
        sta     CHAN            ;store new value
	jsr	CDISP		;update display
	rts

;--- Set channel with fader

CHFDR:	lda	FDR		;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	CHAN		;store new value
	jsr	CDISP		;update display
	rts

;--- Select Relay A

ASEL:	lda	#'A'            ;load relay code
	sta	CURRLY		;store as current relay
	jsr	RDISP		;update display
        rts

;--- Select Relay B

BSEL:	lda	#'B'            ;load relay code
	sta	CURRLY		;store as current relay
	jsr	RDISP		;update display
        rts

;--- Select Relay C

CSEL:	lda	#'C'            ;load relay code
	sta	CURRLY		;store as current relay
	jsr	RDISP		;update display
        rts

;--- Select Relay D

DSEL:	lda	#'D'            ;load relay code
	sta	CURRLY		;store as current relay
	jsr	RDISP		;update display
        rts

;--- Increment Controller for selected relay

CTLINC:
        ldx     CURRLY          ;< or =120? branch off cur relay
	cpx	#'A'            ;
        beq     CIA             ;...if A
	cpx	#'B'            ;
        beq     CIB             ;...if B
	cpx	#'C'            ;
        beq     CIC             ;...if C
	cpx	#'D'            ;
        beq     CID             ;...if D
        ldx     #'A'            ;should never get here
        stx     CURRLY          ;

CIA:    lda     CTLRA           ;fetch current controller assignment
        inca                    ;increment
        cmp     #120            ;valid range: 0-120
        bls     CIAOK           ;check limits
        lda     #0              ;wrap to zero
CIAOK:  sta     CTLRA           ;save new controller assignment
        jmp     CIDISP          ;go update display

CIB:    lda     CTLRB           ;fetch current controller assignment
        inca                    ;increment
        cmp     #120            ;valid range: 0-120
        bls     CIBOK           ;check limits
        lda     #0              ;wrap to zero
CIBOK:  sta     CTLRB           ;save new controller assignment
        jmp     CIDISP          ;go update display

CIC:    lda     CTLRC           ;fetch current controller assignment
        inca                    ;increment
        cmp     #120            ;valid range: 0-120
        bls     CICOK           ;check limits
        lda     #0              ;wrap to zero
CICOK:  sta     CTLRC           ;save new controller assignment
        jmp     CIDISP          ;go update display

CID:    lda     CTLRD           ;fetch current controller assignment
        inca                    ;increment
        cmp     #120            ;valid range: 0-120
        bls     CIDOK           ;check limits
        lda     #0              ;wrap to zero
CIDOK:  sta     CTLRD           ;save new controller assignment


CIDISP: jsr     RDISP           ;update display
        rts

;--- Select Controller with fader

CTLFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
        cmp     #120            ;valid range: 0-120
	bhi	CFE		;>120? branch...
	ldx	CURRLY		;< or =120? branch off cur relay
	cpx	#'A'            ;
	beq	CFA		;...if A
	cpx	#'B'            ;
	beq	CFB		;...if B
	cpx	#'C'            ;
	beq	CFC		;...if C
	cpx	#'D'            ;
	beq	CFD		;...if D

	ldx	#'A'            ;should never get here
        stx     CURRLY          ;

CFA:	sta	CTLRA		;save controller for Relay A
	jmp	CFE		;jump...

CFB:	sta	CTLRB		;save controller for Relay B
	jmp	CFE		;jump...

CFC:	sta	CTLRC		;save controller for Relay C
	jmp	CFE		;jump...

CFD:	sta	CTLRD		;save controller for Relay D

CFE:	jsr	RDISP		;update display
        rts

;--- Toggle current relay status

TOG:	ldx	CURRLY		;branch off current relay
	cpx	#'A'            ;
	beq	TA		;...if A
	cpx	#'B'            ;
	beq	TB		;...if B
	cpx	#'C'            ;
	beq	TC		;...if C
	cpx	#'D'            ;
	beq	TD		;...if D

	ldx	#'A'            ;should never get here
        stx     CURRLY          ;

TA:	lda	RELAYA		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYA		;save new status
	jmp	TE		;jump...

TB:	lda	RELAYB		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYB		;save new status
	jmp	TE		;jump...

TC:	lda	RELAYC		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYC		;save new status
	jmp	TE		;jump...

TD:	lda	RELAYD		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYD		;save new status

TE:	jsr	SDISP		;update display
	jsr	RUPD8		;update relay status
        rts

;--- Update relay status

RUPD8:	lda	#$00		;initialize (all off)

	ldx	RELAYA		;add in Relay A status
        cpx     #0              ;
	beq	RUA		;
        ora     #$01            ;

RUA:	ldx	RELAYB		;add in Relay B status
        cpx     #0              ;
	beq	RUB		;
        ora     #$02            ;

RUB:	ldx	RELAYC		;add in Relay C status
        cpx     #0              ;
	beq	RUC		;
        ora     #$04            ;

RUC:	ldx	RELAYD		;add in Relay D status
        cpx     #0              ;
	beq	RUD		;
        ora     #$08            ;

RUD:	jsr	SPI_IO		;send data
        X0_HI                   ;latch data
        X0_LO                   ;
        rts

;--- Process incoming controller messages

PROC:
        lda     MP_RSTAT        ;fetch Controller Status Byte
	and	#$0F		;get channel
	cmp	CHAN		;is it the one we selected?
	bne	PF		;no? branch...

        lda     MP_DATA1        ;yes? branch off cntl number
        cmp     CTLRA           ;
	beq	PA		;...matches Relay A
        cmp     CTLRB           ;
	beq	PB		;...matches Relay B
        cmp     CTLRC           ;
	beq	PC		;...matches Relay C
        cmp     CTLRD           ;
	beq	PD		;...matches Relay D
	rts			;...not a desired controller

PA:	ldx	#0		;assume relay is off
        lda     MP_DATA2          ;fetch controller value
	cmp	#64		;compare to 64
	blo	PAA		;<64 (off)? branch...
	incx			;> or =64? set relay to "on"
PAA:	stx	RELAYA		;save new relay status
	jmp	PE		;jump...

PB:	ldx	#0		;assume relay is off
	lda	MP_DATA2		;fetch controller value
	cmp	#64		;compare to 64
	blo	PBB		;<64 (off)? branch...
	incx			;> or =64? set relay to "on"
PBB:	stx	RELAYB		;save new relay status
	jmp	PE		;jump...

PC:	ldx	#0		;assume relay is off
	lda	MP_DATA2		;fetch controller value
	cmp	#64		;compare to 64
	blo	PCC		;<64 (off)? branch...
	incx			;> or =64? set relay to "on"
PCC:	stx	RELAYC		;save new relay status
	jmp	PE		;jump...

PD:	ldx	#0		;assume relay is off
	lda	MP_DATA2		;fetch controller value
	cmp	#64		;compare to 64
	blo	PDD		;<64 (off)? branch...
	incx			;> or =64? set relay to "on"
PDD:	stx	RELAYD		;save new relay status

PE:	jsr	SDISP		;update display
	jsr	RUPD8		;update relay status
PF:	rts

;--- Update display for changing channel

CDISP:	lda	#0		;display top line
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " MIDI           "

	lda	#0		;display bottom line
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " CHANNEL:   "

	lda	CHAN		;fetch channel number
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#13		;erase remainder of bottom line
        ldx     #1              ;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "         ;
        rts

;--- Update display for configuring relays

RDISP:	lda	#0		;top line of display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " -A- -B- -C- -D-"

	lda	#3		;position cursor
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
	lda	CTLRA		;fetch Relay A controller
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CTLRB		;fetch Relay B controller
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CTLRC		;fetch Relay C controller
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CTLRD		;fetch Relay D controller
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow

	lda	CURRLY		;branch off current relay
	cmp	#'A'            ;
	beq	RDA		;...if A
	cmp	#'B'            ;
	beq	RDB		;...if B
	cmp	#'C'            ;
	beq	RDC		;...if C

	lda	#12		;place arrow for Relay D
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDA:	lda	#0		;place arrow for Relay A
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
        rts

RDB:	lda	#4		;place arrow for Relay B
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDC:	lda	#8		;place arrow for Relay C
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update relay status display

SDISP:	lda	#0		;load Relay A LED number
	ldx	RELAYA		;fetch relay status
	beq	SDAA		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDB		;jump...
SDAA:	jsr	LED_OFF 	;turn LED off

SDB:	lda	#1		;load Relay B LED number
	ldx	RELAYB		;fetch relay status
	beq	SDBB		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDC		;jump...
SDBB:	jsr	LED_OFF 	;turn LED off

SDC:	lda	#2		;load Relay C LED number
	ldx	RELAYC		;fetch relay status
	beq	SDCC		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDD		;jump...
SDCC:	jsr	LED_OFF 	;turn LED off

SDD:	lda	#3		;load Relay D LED number
	ldx	RELAYD		;fetch relay status
	beq	SDDD		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDE		;jump...
SDDD:	jsr	LED_OFF 	;turn LED off
SDE:	rts

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

	lda	#8		;3rd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;4th possible arrow position
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

SCI_RX_CBCK_S:
        jmp     SCI_RX_CBCK_S_RET

SCI_RX_CBCK_D1:
        jmp     SCI_RX_CBCK_D1_RET

SCI_RX_CBCK_D2:
        jmp     SCI_RX_CBCK_D2_RET


