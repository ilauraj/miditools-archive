;===============================================================;
;								;
;       TOOL11.ASM      Rev 0.4                                 ;
;	Data Filter						;
;								;
;	The user can pass or reject various MIDI messages	;
;	using 8 independent filters.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A DATA FILTER?				;
;	A filter is selected using the SELECT <-/-> keys.	;
;	Eight independent data filters are available.  The LCD	;
;	cursor arrow points at the selected filter.		;
;								;
;	The following data filters are available:		;
;								;
;	       LCD						;
;	       Code	Message(s) Filtered			;
;	      ------	----------------------			;
;		N	Note On and Note Off			;
;		P	Program Change				;
;		A	Channel and Key Aftertouch		;
;		B	Pitch Bend				;
;		C	Control Change (incl. Mode Messages)	;
;		X	System Exclusive			;
;		M	System Common				;
;		R	System Realtime 			;
;								;
;								;
;	...ENABLE OR DISABLE THE SELECTED FILTER?		;
;	Press the STATUS OnOff key to enable or disable the	;
;	selected filter.  When the filter is enabled, all	;
;	messages received of that type will be rejected 	;
;	(i.e. not transmitted out the MIDI OUT port).		;
;								;
;								;
;	...DISABLE ALL FILTERS? 				;
;	Pressing the STATUS CLEAR key disables all filters.	;
;								;
;								;
;	...MONITOR THE STATUS OF ALL FILTERS?			;
;	Filter status is given in the LCD.  An asterisk (*)	;
;	under the filter code indicates that the filter is	;
;	enabled.						;
;								;
;								;
;	...MONITOR THE RECEIVED DATA STREAM?			;
;	Incoming data is monitored with the LEDs.  If a 	;
;	message is received that matches the filter type, the	;
;	appropriate LED lights, regardless of the status of	;
;	filter status.						;
;								;
;								;
;	...KNOW WHEN THE DATA BUFFER OVERFLOWS? 		;
;	The OVERFLOW LED indicates when the MIDI receive	;
;	buffer is full.  Data errors may occur. 		;
;								;
;								;
;	...ENABLE THE DATA HOLD DISPLAY?			;
;	Press the LEDs HOLD key.  The LEDs will light and stay	;
;	lit when a matching message is received.  Pressing the	;
;	key again clears the LEDs without leaving this mode.	;
;								;
;								;
;	...ENABLE THE FREE RUNNING DISPLAY?			;
;	Press the LEDs FREE key.  After turning off all LEDs,	;
;	the appropriate LED will blink when a matching message	;
;	is received.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the filter that will be	;
;	modified by the STATUS OnOff key.			;
;								;
;	| N P A B C X M R|	*=filter enabled		;
;	| *	*   *	*|					;
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
;	StFree		Filter in LED free run mode		;
;	StHold		Filter in LED hold mode 		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	FILINC		Increment message filter		;
;	FILDEC		Decrement message filter		;
;	FILTOG		Toggle filter status			;
;	RESET		Disable all filters			;
;	LHOLD		Clear LEDs and enter LED hold mode	;
;	LFREE		Clear LEDs and enter LED free run mode	;
;	SDISP		Update display for enabling filters	;
;	MDISP		Control LED message monitor		;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

FILTER		.DS	1	;filter status mask

;  filter status mask format (same as M_RX_Q_XPT)
;  ----------------------------------------
;
;  MSB							 LSB
;  |  B7  |  B6  |  B5	|  B4  |  B3  |  B2  |	B1  |  B0  |
;  | sysr | sysc | sysx | cntl | bend | aft  | prog | note |
;
;  the filter is enabled when the bit is set (logic 1)

FILTPTR 	.DS	1	;pointer to current filter
HOLD		.DS	1	;LED mode flag (0=free, 1=hold)
TEMPCLASS	.DS	1	;M_TEMPOrary class storage
TEMPVAL 	.DS	1	;M_TEMPOrary value storage

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StFree		EQU	0
StHold		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvFree		EQU	EV_SW1_ON
EvLeft		EQU	EV_SW3_ON
EvRight 	EQU	EV_SW4_ON
EvHold		EQU	EV_SW5_ON
EvClear 	EQU	EV_SW7_ON
EvOnOff 	EQU	EV_SW8_ON
EvMsg		EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StFree State 1:StHold                      Not
;	 Event	  NextSt,Act	 NextSt,Act			    Used
;	 ---------------------------------------------------------------
 STM_ROW EvIdle,  StFree,IDLE,	 StHold,IDLE,	StFree,IDLE, StFree,IDLE
 STM_ROW EvLeft,  StFree,FILDEC, StHold,FILDEC, StFree,IDLE, StFree,IDLE
 STM_ROW EvRight, StFree,FILINC, StHold,FILINC, StFree,IDLE, StFree,IDLE
 STM_ROW EvOnOff, StFree,FILTOG, StHold,FILTOG, StFree,IDLE, StFree,IDLE
 STM_ROW EvClear, StFree,RESET,  StHold,RESET,	StFree,IDLE, StFree,IDLE
 STM_ROW EvFree,  StFree,IDLE,	 StFree,LFREE,	StFree,IDLE, StFree,IDLE
 STM_ROW EvHold,  StHold,LHOLD,  StHold,LHOLD,	StFree,IDLE, StFree,IDLE
 STM_ROW EvMsg,   StFree,MDISP,  StHold,MDISP,	StFree,IDLE, StFree,IDLE

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
	sta	FILTER		;
	sta	TEMPCLASS	;
	sta	TEMPVAL 	;

	lda	#$01		;default pointer value
	sta	FILTPTR		;

	clr	HOLD		;clear flag

;--- Initialize MIDI

	lda	#$FF		;buffer all messages
	sta	M_RX_Q_XPT		;

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "11:         Data"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Filter"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	lda	#1		;static display line
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'N'            ;
	jsr	LCD_PUT_C	;

	lda	#3		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'P'            ;
	jsr	LCD_PUT_C	;

	lda	#5		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'A'            ;
	jsr	LCD_PUT_C	;

	lda	#7		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'B'            ;
	jsr	LCD_PUT_C	;

	lda	#9		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'C'            ;
	jsr	LCD_PUT_C	;

	lda	#11		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'X'            ;
	jsr	LCD_PUT_C	;

	lda	#13		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'M'            ;
	jsr	LCD_PUT_C	;

	lda	#15		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#'R'            ;
	jsr	LCD_PUT_C	;

	jsr	SDISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment message filter

FILINC: lda	FILTPTR 	;get current pointer
	clc			;clear carry to prepare rotate
	rola			;rotate left to "increment"
	bcc	FIA		;branch if no carry (no wrap)
	lda	#$01		;wrap around value
FIA:	sta	FILTPTR 	;store new value
	jsr	SDISP		;update display
	rts

;--- Decrement message filter

FILDEC: lda	FILTPTR 	;get current pointer
	clc			;clear carry to prepare rotate
	rora			;rotate right to "decrement"
	bcc	FDA		;branch if no carry (no wrap)
	lda	#$80		;wrap around value
FDA:	sta	FILTPTR 	;store new value
	jsr	SDISP		;update display
	rts

;--- Toggle FILTER status

FILTOG: lda	M_FULL_MSG 	;wait if in the middle of
	beq	FILTOG		; receiving a message
	sei			;disable all interrupts
	lda	FILTPTR 	;toggle current filter status
	eor	FILTER		;
	sta	FILTER		;store new value
	lda	M_RSTAT		;fetch external running status
	beq	FILTGA		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
FILTGA: cli			;enable all interrupts
	jsr	SDISP		;update display
	rts

;--- Disable all filters

RESET:	lda	#2		;remove arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#8		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#10		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#14		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#$01		;reset pointer
	sta	FILTPTR 	;


RESETA: lda	M_FULL_MSG 	;wait if in the middle of
	beq	RESETA		; receiving a message

	sei			;disable all interrupts
	clr	FILTER		;disable all filters
	lda	M_RSTAT		;fetch external running status
	beq	RSAB		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RSAB:	cli			;enable all interrupts
	jsr	SDISP		;update display
	rts

;--- Clear LEDs and enter hold mode

LHOLD:	jsr	LED_INIT	;turn off all LEDs
	lda	#1		;set flag
	sta	HOLD		;
	rts

;--- Clear LEDs and enter free run mode

LFREE:	jsr	LED_INIT	;turn off all LEDs
	clr	HOLD		;clear flag
	rts

;--- Update display for enabling filters

SDISP:	lda	#1		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	brset	0,FILTER,SDA	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDB		;
SDA:	lda	#'*'            ;...if filter enabled
SDB:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	1,FILTER,SDC	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDD		;
SDC:	lda	#'*'            ;...if filter enabled
SDD:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	2,FILTER,SDE	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDF		;
SDE:	lda	#'*'            ;...if filter enabled
SDF:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	3,FILTER,SDG	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDH		;
SDG:	lda	#'*'            ;...if filter enabled
SDH:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	4,FILTER,SDI	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDJ		;
SDI:	lda	#'*'            ;...if filter enabled
SDJ:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	5,FILTER,SDK	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDL		;
SDK:	lda	#'*'            ;...if filter enabled
SDL:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	6,FILTER,SDM	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDN		;
SDM:	lda	#'*'            ;...if filter enabled
SDN:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	brset	7,FILTER,SDO	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDP		;
SDO:	lda	#'*'            ;...if filter enabled
SDP:	jsr	LCD_PUT_C	;
	lda	#' '            ;move one space
	jsr	LCD_PUT_C	;

	lda	FILTPTR 	;branch off filter pointer
	cmp	#$80		;
	FAR_BEQ A8		;...if R
	cmp	#$40		;
	FAR_BEQ A7		;...if M
	cmp	#$20		;
	FAR_BEQ A6		;...if X
	cmp	#$10		;
	FAR_BEQ A5		;...if C
	cmp	#$08		;
	beq	A4		;...if B
	cmp	#$04		;
	beq	A3		;...if A
	cmp	#$02		;
	beq	A2		;...if P

A1:	lda	#14		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#2		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;place arrow on N
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A2:	lda	#0		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#4		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#2		;place arrow on P
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A3:	lda	#2		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#6		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;place arrow on A
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A4:	lda	#4		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#8		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#6		;place arrow on B
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A5:	lda	#6		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#10		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#8		;place arrow on C
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A6:	lda	#8		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#12		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#10		;place arrow on X
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A7:	lda	#10		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#14		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;place arrow on M
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

A8:	lda	#12		;clear arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	lda	#0		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#14		;place arrow on R
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Control LED message monitor

MDISP:	lda	MP_FLAGS	;fetch MIDI flags
	bpl	MDCONT		;is buffer full? no? branch...

	lda	#3		;yes? turn on Overflow LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	MDCONT		; in free run mode
	lda	#3		;
	jsr	LED_OFF 	;

MDCONT: FAR_BRSET SYSRT,MP_FLAGS,SYSR
	FAR_BRSET SYSEX,MP_FLAGS,SYSX
	FAR_BRSET SYSCO,MP_FLAGS,SYSC

	;--- display Channel Messages

	lda	MP_RSTAT 	;fetch status
	jsr	MIDI_CLASS	;get class
	cmp	#$10		;
	beq	CNTL		;...if control change?
	cmp	#$08		;
	beq	BEND		;...if pitch bend?
	cmp	#$04		;
	beq	AFT		;...if aftertouch?
	cmp	#$02		;
	beq	PRCH		;...if program change?

NOTE:	lda	#0		;turn on NOTE LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	NA		; in free run mode
	lda	#0		;
	jsr	LED_OFF 	;
NA:	rts

PRCH:	lda	#4		;turn on PROG LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	PA		; in free run mode
	lda	#4		;
	jsr	LED_OFF 	;
PA:	rts

AFT:	lda	#8		;turn on AFT LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	AA		; in free run mode
	lda	#8		;
	jsr	LED_OFF 	;
AA:	rts

BEND:	lda	#12		;turn on BEND LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	BA		; in free run mode
	lda	#12		;
	jsr	LED_OFF 	;
BA:	rts

CNTL:	lda	#2		;turn on CNTL LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	CA		; in free run mode
	lda	#2		;
	jsr	LED_OFF 	;
CA:	rts

	;--- display System Realtime messages

SYSR:	lda	#14		;turn on SYSR LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	RA		; in free run mode
	lda	#14		;
	jsr	LED_OFF 	;
RA:	rts

	;--- display System Exclusive messages

SYSX:	lda	#6		;turn on SYSX LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	XA		; in free run mode
	lda	#6		;
	jsr	LED_OFF 	;
XA:	rts

	;--- display System Common messages

SYSC:	lda	#10		;turn on SYSC LED
	jsr	LED_ON		;
	lda	HOLD		;turn off only if
	bne	MA		; in free run mode
	lda	#10		;
	jsr	LED_OFF 	;
MA:	rts

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
SCI_RX_CBCK_D1:
SCI_RX_CBCK_D2:

	sta	TEMPCLASS	;save class
	stx	TEMPVAL 	;save value
	and	FILTER		;process filter
	beq	URXA		;=0? branch...
        jmp     SCI_RX_CBCK_S_RET ;filter this? reject by buffering
URXA:	txa			;transfer byte value to acca
	jsr	MIDI_PUT	;retransmit byte
	lda	TEMPCLASS	;restore class
	ldx	TEMPVAL 	;restore value
        jmp     SCI_RX_CBCK_S_RET  ;return, buffer it
