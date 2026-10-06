;===============================================================;
;								;
;       TOOL09.ASM      Rev 1.0  29-Aug-93                      ;
;	Control Thinner 					;
;								;
;	The user can thin incoming MIDI control messages	;
;	(Controllers, Pitch Bend and Aftertouch).		;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A MESSAGE TYPE FOR THINNING?			;
;	Select a message type with the MESSAGE TYPE keys:	;
;	CTL (controllers 0-63), BEND (pitch bend), or AFT	;
;	(channel and key aftertouch).				;
;								;
;								;
;	...SET THE AMOUNT OF THINNING FOR EACH MESSAGE TYPE?	;
;	The amount of thinning prodcued for the selected	;
;	message type is set using the +/- keys and/or the	;
;	VALUE fader.						;
;								;
;								;
;	...OPERATE THE THINNER? 				;
;	All controller messages are thinned and retransmitted	;
;	according to the assigned thinning amount, M.  If M=0,	;
;	every message is thinned (rejected).  If M=31, every	;
;	32nd message of that type is thinned (rejected).	;
;	For any valid value of M, every M+1 message is		;
;	rejected.  M represents the number of messages that	;
;	will be passed before one message is rejected.		;
;								;
;	Thinning is channel independent.			;
;								;
;								;
;	...BYPASS THE THINNER?					;
;	Press the BYPASS keys: CTL, BEND or AFT.  Thinning	;
;	of that message type will be disabled.	The		;
;	appropriate BYPASS LED will light.  Pressing the	;
;	BYPASS key again enables thinning and turns the LED	;
;	off.							;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	|CTL   BEND   AFT|	where nn=0-31			;
;       | nn    nn     nn|                                      ;
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
;       StCtl           Select control change thinning          ;
;       StBnd           Select pitch bend thinning              ;
;       StAft           Select aftertouch thinning              ;
;                                                               ;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CTLINC		Increment control thinning value	;
;	CTLDEC		Decrement control thinning value	;
;	CTLFDR		Set control thinning value with fader	;
;	BNDINC		Increment bend thinning value		;
;	BNDDEC		Decrement bend thinning value		;
;	BNDFDR		Set bend thinning value with fader	;
;	AFTINC		Increment aftertouch thinning value	;
;	AFTDEC		Decrement aftertouch thinning value	;
;	AFTFDR		Set aftertouch thin value with fader	;
;	CTLBY		Toggle control thinning bypass		;
;	BNDBY		Toggle bend thinning bypass		;
;	AFTBY		Toggle aftertouch thinning bypass	;
;	CDISP		Update display for control change	;
;	BDISP		Update display for pitch bend		;
;	ADISP		Update display for aftertouch		;
;								;
;===============================================================;

;----------------------------------------------------------------
;       Constants
;----------------------------------------------------------------

MAXTHIN 	EQU	31	;max amount of thinning
				; NOTE: if this changes, you must
				; alter limits on fader changes

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CTL		.DS	1	;control change thinning value
CTLCNT		.DS	1	;counts occurances of ctl
BND		.DS	1	;bend thinning value
BNDCNT		.DS	1	;counts occurances of bend
AFT		.DS	1	;aftertouch thinning value
AFTCNT		.DS	1	;counts occurances of aftertouch
STAT		.DS	1	;running status holder
ECHO_ON 	.DS	1	;message echo flag
CTLACTV 	.DS	1	;flag for ctl thin (0=bypass)
BNDACTV 	.DS	1	;flag for bend thin (0=bypass)
AFTACTV 	.DS	1	;flag for aft thin (0=bypass)

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCtl           EQU     0
StBnd           EQU     1
StAft           EQU     2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvCtl           EQU     EV_SW1_ON
EvBnd           EQU     EV_SW2_ON
EvAft           EQU     EV_SW3_ON
EvPlus          EQU     EV_SW4_ON
EvBCtl		EQU	EV_SW5_ON
EvBBnd		EQU	EV_SW6_ON
EvBAft		EQU	EV_SW7_ON
EvMinus         EQU     EV_SW8_ON
EvValue         EQU     EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StCtl State 1:StBnd State 2: StAft       Not
;	 Event	  NextSt,Act	NextSt,Act    NextSt,Act	  Used
;	 -------------------------------------------------------------
 STM_ROW EvIdle,  StCtl,IDLE,	StBnd,IDLE,   StAft,IDLE,   StCtl,IDLE
 STM_ROW EvPlus,  StCtl,CTLINC, StBnd,BNDINC, StAft,AFTINC, StCtl,IDLE
 STM_ROW EvMinus, StCtl,CTLDEC, StBnd,BNDDEC, StAft,AFTDEC, StCtl,IDLE
 STM_ROW EvValue, StCtl,CTLFDR, StBnd,BNDFDR, StAft,AFTFDR, StCtl,IDLE
 STM_ROW EvCtl,   StCtl,IDLE,	StCtl,CDISP,  StCtl,CDISP,  StCtl,IDLE
 STM_ROW EvBnd,   StBnd,BDISP,	StBnd,IDLE,   StBnd,BDISP,  StCtl,IDLE
 STM_ROW EvAft,   StAft,ADISP,	StAft,ADISP,  StAft,IDLE,   StCtl,IDLE
 STM_ROW EvBCtl,  StCtl,CTLBY,	StBnd,CTLBY,  StAft,CTLBY,  StCtl,IDLE
 STM_ROW EvBBnd,  StCtl,BNDBY,	StBnd,BNDBY,  StAft,BNDBY,  StCtl,IDLE
 STM_ROW EvBAft,  StCtl,AFTBY,	StBnd,AFTBY,  StAft,AFTBY,  StCtl,IDLE

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

	lda	#MAXTHIN	;default values
        sta     CTL             ;
        sta     BND             ;
        sta     AFT             ;
        sta     CTLCNT          ;
        sta     BNDCNT          ;
        sta     AFTCNT          ;

	lda	#1		;set flags
	sta	CTLACTV 	;
	sta	BNDACTV 	;
	sta	AFTACTV 	;

;--- Initialize display

	jsr	GREETING

        LCD_PUT_S "19:      Control"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0     Thinner"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

        LCD_PUT_S "CTL   BEND   AFT"

	jsr	BDISP		;update display
	jsr	ADISP		;
	jsr	CDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment control thinning value

CTLINC: lda	CTL		;fetch value
	inca			;increment
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	CIA		;< or =MAXTHIN? branch...
	lda	#0		;>MAXTHIN? wrap to 0
CIA:	sta	CTL		;store new value
        sta     CTLCNT          ;
        jsr     CDISP           ;update display
	rts

;--- Decrement control thinning value

CTLDEC: lda	CTL		;fetch value
	deca			;decrement
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	CDA		;< or =MAXTHIN? branch...
	lda	#MAXTHIN	;>MAXTHIN? wrap to MAXTHIN
CDA:	sta	CTL		;store new value
        sta     CTLCNT          ;
         jsr     CDISP           ;update display
	rts

;--- Set control thinning value with fader

CTLFDR: lda	FDR		;fetch fader value
	lsra			;valid range: 0-31(MAXTHIN)
        lsra                    ;
        lsra                    ;
        sta     CTL             ;store new value
        sta     CTLCNT          ;
        jsr     CDISP           ;update display
	rts

;--- Increment bend thinning value

BNDINC: lda	BND		;fetch value
	inca			;increment
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	BIA		;< or =MAXTHIN? branch...
	lda	#0		;>MAXTHIN? wrap to 0
BIA:	sta	BND		;store new value
        sta     BNDCNT          ;
        jsr     BDISP           ;update display
	rts

;--- Decrement bend thinning value

BNDDEC: lda	BND		;fetch value
	deca			;decrement
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	BDA		;< or =MAXTHIN? branch...
	lda	#MAXTHIN	;>MAXTHIN? wrap to MAXTHIN
BDA:	sta	BND		;store new value
        sta     BNDCNT          ;
        jsr     BDISP           ;update display
	rts

;--- Set bend thinning value with fader

BNDFDR: lda	FDR		;fetch fader value
	lsra			;valid range: 0-31(MAXTHIN)
	lsra			;
	lsra			;
	sta	BND		;store new value
        sta     BNDCNT          ;
        jsr     BDISP           ;update display
	rts

;--- Increment aftertouch thinning value

AFTINC: lda	AFT		;fetch value
	inca			;increment
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	AIA		;< or =MAXTHIN? branch...
	lda	#0		;>MAXTHIN? wrap to 0
AIA:	sta	AFT		;store new value
        sta     AFTCNT          ;
        jsr     ADISP           ;update display
	rts

;--- Decrement aftertouch thinning value

AFTDEC: lda	AFT		;fetch value
	deca			;decrement
	cmp	#MAXTHIN	;valid range: 0-MAXTHIN
	bls	ADA		;< or =MAXTHIN? branch...
	lda	#MAXTHIN	;>MAXTHIN? wrap to MAXTHIN
ADA:	sta	AFT		;store new value
        sta     AFTCNT          ;
        jsr     ADISP           ;update display
	rts

;--- Set aftertouch thin  value with fader

AFTFDR: lda	FDR		;fetch fader value
	lsra			;valid range: 0-31(MAXTHIN)
	lsra			;
	lsra			;
	sta	AFT		;store new value
        sta     AFTCNT          ;
        jsr     ADISP           ;update display
	rts

;--- Toggle control thinning bypass

CTLBY:	lda	CTLACTV 	;fetch flag
        eor     #$01            ;toggle it
	sta	CTLACTV 	;save new flag
	beq	CBA		;=0 (bypass)? branch...
	lda	#3		;=1 (enable)? turn LED off
	jsr	LED_OFF 	;
	jmp	CBB		;jump...
CBA:	lda	#3		;turn LED on
	jsr	LED_ON		;
CBB:	rts

;--- Toggle bend thinning bypass

BNDBY:	lda	BNDACTV 	;fetch flag
	eor	#$01		;toggle it
	sta	BNDACTV 	;save new flag
	beq	BBA		;=0 (bypass)? branch...
	lda	#7		;=1 (enable)? turn LED off
	jsr	LED_OFF 	;
	jmp	BBB		;jump...
BBA:	lda	#7		;turn LED on
	jsr	LED_ON		;
BBB:	rts

;--- Toggle aftertouch thinning bypass

AFTBY:	lda	AFTACTV 	;fetch flag
	eor	#$01		;toggle it
	sta	AFTACTV 	;save new flag
	beq	ABA		;=0 (bypass)? branch...
	lda	#11		;=1 (enable)? turn LED off
	jsr	LED_OFF 	;
	jmp	ABB		;jump...
ABA:	lda	#11		;turn LED on
	jsr	LED_ON		;
ABB:	rts

;--- Update display for control thinning

CDISP:	lda	#6		;clear BND arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#13		;clear AFT arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;place CTL arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

        lda     #2              ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CTL		;fetch value
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for pitch bend thinning

BDISP:	lda	#0		;clear CTL arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#13		;clear AFT arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;place BEND arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

        lda     #8              ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BND		;fetch value
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for aftertouch thinning

ADISP:	lda	#0		;clear CTL arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;clear BND arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#13		;place AFT arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

        lda     #15             ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	AFT		;fetch value
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

;--- Service Status Bytes (class in acca, value in x)

SCI_RX_CBCK_S:
	cmp	#$10		;branch off class
	beq	URST		;...if control change
	cmp	#$08		;
	beq	URST		;...if pitch bend
	cmp	#$04		;
	beq	URST		;...if aftertouch
	jmp	SENDIT		;...if other, send it

URST:	stx	STAT		;save status in holder
        rti

;--- Service 1st Data Bytes (class in acca, value in x)

SCI_RX_CBCK_D1:
	cmp	#$10		;branch off class
	beq	URCTL		;...if control change
	cmp	#$08		;
	beq	URBND		;...if pitch bend
	cmp	#$04		;
	beq	URAFT		;...if aftertouch

SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	lda	#1		;set echo flag
        sta     ECHO_ON         ;
	rti			;return, do not buffer

URCTL:	lda	CTLACTV 	;fetch enable flag
	beq	CBY		;=0 (bypass)? branch...
	cpx	#63		;valid range: 0-63 (no switches)
	bhi	CBY		;>63? branch...
	lda	CTLCNT		;get count
	deca			;decrement
	bmi	CTHIN		;=-1? branch...
        sta     CTLCNT          ;save new count
CBY:	lda	STAT		;fetch Status Byte
	FAR_BEQ SENDIT		;=0? send this data byte
	jsr	MIDI_PUT	;nonzero? send Status Byte first
	clr	STAT		;enter running status
	ldx	M_DATA1 	;retrieve data value
	jmp	SENDIT		;send it
CTHIN:	clr	ECHO_ON 	;clear echo flag to thin
	lda	CTL		;fetch thinning value
	sta	CTLCNT		;reset counter
	rti			;return, do not buffer

URBND:	lda	BNDACTV 	;fetch enable flag
	beq	BBY		;=0 (bypass)? branch...
	lda	BNDCNT		;get count
	deca			;decrement
	bmi	BTHIN		;=-1? branch...
	sta	BNDCNT		;save new count
BBY:	lda	STAT		;fetch Status Byte
	FAR_BEQ SENDIT		;=0? send this data byte
	jsr	MIDI_PUT	;nonzero? send Status Byte first
	clr	STAT		;enter running status
	ldx	M_DATA1 	;retrieve data value
	jmp	SENDIT		;send it
BTHIN:	clr	ECHO_ON 	;clear echo flag to thin
	lda	BND		;fetch thinning value
	sta	BNDCNT		;reset counter
	rti			;return, do not buffer

URAFT:	lda	AFTACTV 	;fetch enable flag
	beq	ABY		;=0 (bypass)? branch...
	lda	AFTCNT		;get count
	deca			;decrement
	bmi	ATHIN		;=-1? branch...
	sta	AFTCNT		;save new count
ABY:	lda	STAT		;fetch Status Byte
	FAR_BEQ SENDIT		;=0? send this data byte
	jsr	MIDI_PUT	;nonzero? send Status Byte first
	clr	STAT		;enter running status
	ldx	M_DATA1 	;retrieve data value
	jmp	SENDIT		;send it
ATHIN:	clr	ECHO_ON 	;clear echo flag to thin
	lda	AFT		;fetch thinning value
	sta	AFTCNT		;reset counter
	rti			;return, do not buffer

;--- Service 2nd Data Bytes - retransmit if echo is on

SCI_RX_CBCK_D2:
	lda	ECHO_ON 	;fetch echo flag
	FAR_BNE SENDIT		;=1? send it
	rti			;=0? return, do not buffer
				; (message is being thinned)
