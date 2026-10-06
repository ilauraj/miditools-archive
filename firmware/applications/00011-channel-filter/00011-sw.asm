;===============================================================;
;								;
;       TOOL10.ASM      Rev 0.4                                 ;
;	Channel Filter						;
;								;
;	The user can independently pass or reject MIDI		;
;	messages on all MIDI channels.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A CHANNEL FILTER?				;
;	A filter is selected using the SELECT <-/-> keys.	;
;	Sixteen independent channel filters are available.	;
;	The LCD cursor underlines the selected filter.		;
;								;
;								;
;	...ENABLE OR DISABLE THE SELECTED FILTER?		;
;	Press the STATUS OnOff key to enable or disable the	;
;	selected filter.  When the filter is enabled, all	;
;	messages received on that channel will be rejected	;
;	(i.e. not transmitted out the MIDI OUT port).		;
;								;
;								;
;	...DISABLE ALL FILTERS? 				;
;	Pressing the STATUS CLEAR key disables all filters.	;
;								;
;								;
;	...MONITOR THE STATUS OF ALL FILTERS?			;
;	Filter status is given in the LCD.  An asterisk (*)	;
;	under the filter number indicates that the filter is	;
;	enabled.						;
;								;
;								;
;	...MONITOR THE RECEIVED DATA STREAM?			;
;	Incoming data is monitored with the LEDs.  If a 	;
;	message is received on the appropriate channel, the	;
;	LED lights, regardless of the status of the filter.	;
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
;	The cursor underlines the filter that will be modified	;
;	by the STATUS OnOff key.				;
;								;
;	|1234567890123456|	*=filter enabled		;
;	| *	*   *	*|					;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This project uses the CPU board and one HUMAN		;
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

FILTERLO	.DS	1	;filter status mask LSB
FILTERHI	.DS	1	;filter status mask MSB

;  filter status mask format
;  -------------------------
;
;  FILTERLO (LSB)
;
;  |  B7  |  B6  |  B5	|  B4  |  B3  |  B2  |	B1  |  B0  |
;  | CH 8 | CH 7 | CH 6 | Ch 5 | Ch 4 | Ch 3 | Ch 2 | CH 1 |
;
;  FILTERHI (MSB)
;
;  |  B7  |  B6  |  B5	|  B4  |  B3  |  B2  |	B1  |  B0  |
;  | CH 16| CH 15| CH 14| Ch 13| Ch 12| Ch 11| Ch 10| CH 9 |
;
;  the filter is ENABLED if the bit is set (logic 1)

CHANPTR 	.DS	1	;pointer to current filter bit
HOLD		.DS	1	;LED mode flag (0=free, 1=hold)
TEMPCLASS	.DS	1	;M_TEMPOrary class storage
TEMPVAL 	.DS	1	;M_TEMPOrary value storage
TEMPCP		.DS	1	;M_TEMPOrary pointer storage

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
	sta	FILTERLO	;
	sta	FILTERHI	;
	sta	TEMPCLASS	;
	sta	TEMPVAL 	;
	sta	TEMPCP		;

	clr	HOLD		;clear flag

	clr	CHANPTR 	;default pointer value

;--- Initialize MIDI

	lda	#$1F		;buffer channel messages
	sta	M_RX_Q_XPT		;

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "10:      Channel"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Filter"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "1234567890123456"

	lda	#0		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#1		;turn cursor on
	jsr	LCD_CURSOR	;

	jsr	SDISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment message filter

FILINC: lda	CHANPTR 	;fetch channel pointer
	inca			;increment
	cmp	#15		;valid range: 0-15
	bls	FIA		;< or =15? branch...
	lda	#0		;>15? wrap to 0
FIA:	sta	CHANPTR 	;store new value
	jsr	SDISP		;update display
	rts

;--- Decrement message filter

FILDEC: lda	CHANPTR 	;fetch channel pointer
	deca			;decrement
	cmp	#15		;valid range: 0-15
	bls	FDA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
FDA:	sta	CHANPTR 	;store new value
	jsr	SDISP		;update display
	rts

;--- Toggle FILTER status

FILTOG: lda	M_FULL_MSG 	;wait if in the middle of
	beq	FILTOG		; receiving a message

	sei			;disable all interrupts
	ldx	CHANPTR 	;fetch channel pointer

	JMP_TABLE TBL_FIL	;look up branch location

TBL_FIL:
	.DW FT0,FT1,FT2,FT3,FT4,FT5,FT6,FT7
	.DW FT8,FT9,FT10,FT11,FT12,FT13,FT14,FT15

FT0:	brclr	0,FILTERLO,FT0S ;check current status
FT0C:	bclr	0,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT0S:	bset	0,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT1:	brclr	1,FILTERLO,FT1S ;check current status
FT1C:	bclr	1,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT1S:	bset	1,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT2:	brclr	2,FILTERLO,FT2S ;check current status
FT2C:	bclr	2,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT2S:	bset	2,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT3:	brclr	3,FILTERLO,FT3S ;check current status
FT3C:	bclr	3,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT3S:	bset	3,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT4:	brclr	4,FILTERLO,FT4S ;check current status
FT4C:	bclr	4,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT4S:	bset	4,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT5:	brclr	5,FILTERLO,FT5S ;check current status
FT5C:	bclr	5,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT5S:	bset	5,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT6:	brclr	6,FILTERLO,FT6S ;check current status
FT6C:	bclr	6,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT6S:	bset	6,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT7:	brclr	7,FILTERLO,FT7S ;check current status
FT7C:	bclr	7,FILTERLO	;enabled? disable it
	jmp	FTCONT		;
FT7S:	bset	7,FILTERLO	;disabled? enable it
	jmp	FTCONT		;

FT8:	brclr	0,FILTERHI,FT8S ;check current status
FT8C:	bclr	0,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT8S:	bset	0,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT9:	brclr	1,FILTERHI,FT9S ;check current status
FT9C:	bclr	1,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT9S:	bset	1,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT10:	brclr	2,FILTERHI,FT10S ;check current status
FT10C:	bclr	2,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT10S:	bset	2,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT11:	brclr	3,FILTERHI,FT11S ;check current status
FT11C:	bclr	3,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT11S:	bset	3,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT12:	brclr	4,FILTERHI,FT12S ;check current status
FT12C:	bclr	4,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT12S:	bset	4,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT13:	brclr	5,FILTERHI,FT13S ;check current status
FT13C:	bclr	5,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT13S:	bset	5,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT14:	brclr	6,FILTERHI,FT14S ;check current status
FT14C:	bclr	6,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT14S:	bset	6,FILTERHI	;disabled? enable it
	jmp	FTCONT		;

FT15:	brclr	7,FILTERHI,FT15S ;check current status
FT15C:	bclr	7,FILTERHI	;enabled? disable it
	jmp	FTCONT		;
FT15S:	bset	7,FILTERHI	;disabled? enable it

FTCONT: lda	M_RSTAT		;fetch external running status
	beq	FTCON2		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
FTCON2: cli			;enable all interrupts
	jsr	SDISP		;update display
	rts

;--- Disable all filters

RESET:	clr	CHANPTR 	;reset pointer
RESETA: lda	M_FULL_MSG 	;wait if in the middle of
	beq	RESETA		; receiving a message
	sei			;disable all interrupts
	clr	FILTERLO	;disable all filters
	clr	FILTERHI	;
	lda	M_RSTAT		;fetch external running status
	beq	RESETB		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RESETB: cli			;enable all interrupts
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

SDISP:	lda	#0		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	brset	0,FILTERLO,SDA	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDB		;
SDA:	lda	#'*'            ;...if filter enabled
SDB:	jsr	LCD_PUT_C	;

	brset	1,FILTERLO,SDC	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDD		;
SDC:	lda	#'*'            ;...if filter enabled
SDD:	jsr	LCD_PUT_C	;

	brset	2,FILTERLO,SDE	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDF		;
SDE:	lda	#'*'            ;...if filter enabled
SDF:	jsr	LCD_PUT_C	;

	brset	3,FILTERLO,SDG	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDH		;
SDG:	lda	#'*'            ;...if filter enabled
SDH:	jsr	LCD_PUT_C	;

	brset	4,FILTERLO,SDI	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDJ		;
SDI:	lda	#'*'            ;...if filter enabled
SDJ:	jsr	LCD_PUT_C	;

	brset	5,FILTERLO,SDK	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDL		;
SDK:	lda	#'*'            ;...if filter enabled
SDL:	jsr	LCD_PUT_C	;

	brset	6,FILTERLO,SDM	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDN		;
SDM:	lda	#'*'            ;...if filter enabled
SDN:	jsr	LCD_PUT_C	;

	brset	7,FILTERLO,SDO	;check filter
	lda	#' '            ;...if filter disabled
	bra	SDP		;
SDO:	lda	#'*'            ;...if filter enabled
SDP:	jsr	LCD_PUT_C	;

	brset	0,FILTERHI,SDAA ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDBB		;
SDAA:	lda	#'*'            ;...if filter enabled
SDBB:	jsr	LCD_PUT_C	;

	brset	1,FILTERHI,SDCC ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDDD		;
SDCC:	lda	#'*'            ;...if filter enabled
SDDD:	jsr	LCD_PUT_C	;

	brset	2,FILTERHI,SDEE ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDFF		;
SDEE:	lda	#'*'            ;...if filter enabled
SDFF:	jsr	LCD_PUT_C	;

	brset	3,FILTERHI,SDGG ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDHH		;
SDGG:	lda	#'*'            ;...if filter enabled
SDHH:	jsr	LCD_PUT_C	;

	brset	4,FILTERHI,SDII ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDJJ		;
SDII:	lda	#'*'            ;...if filter enabled
SDJJ:	jsr	LCD_PUT_C	;

	brset	5,FILTERHI,SDKK ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDLL		;
SDKK:	lda	#'*'            ;...if filter enabled
SDLL:	jsr	LCD_PUT_C	;

	brset	6,FILTERHI,SDMM ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDNN		;
SDMM:	lda	#'*'            ;...if filter enabled
SDNN:	jsr	LCD_PUT_C	;

	brset	7,FILTERHI,SDOO ;check filter
	lda	#' '            ;...if filter disabled
	bra	SDPP		;
SDOO:	lda	#'*'            ;...if filter enabled
SDPP:	jsr	LCD_PUT_C	;

	lda	CHANPTR 	;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	rts

;--- Control LED message monitor

MDISP:	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	jsr	LED_ON		;turn LED on
	lda	HOLD		;fetch mode flag
	bne	MDA		;=1 (hold)? branch...
	lda	MP_RSTAT 	;=0 (free run)? fetch status
	and	#$0F		;get channel
	jsr	LED_OFF 	;turn appropriate LED off
MDA:	rts

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

	cmp	#$10		;is it a channel message?
	bls	URCHAN		;yes? branch...
	jmp	URSEND		;no? send it

URCHAN: lda	M_RSTAT		;fetch current status
	and	#$0F		;get channel
	tax			;transfer to x for indexing
	lda	CMASK,X 	;get mask value in acca

	cpx	#7		;is channel>7?
	bhi	FILHI		;yes? branch...

FILLO:	and	FILTERLO	;0-7? process filter
	beq	URSEND		;
	jmp	URFILT		;jump...

FILHI:	and	FILTERHI	;8-15? process filter
	bne	URFILT		;

URSEND: lda	TEMPVAL 	;fetch byte value
	jsr	MIDI_PUT	;retransmit byte

URFILT: lda	TEMPCLASS	;restore class
	ldx	TEMPVAL 	;restore value
        jmp     SCI_RX_CBCK_S_RET ;return, buffer it

CMASK:	.DB $01,$02,$04,$08,$10,$20,$40,$80
	.DB $01,$02,$04,$08,$10,$20,$40,$80
