;===============================================================;
;								;
;       TOOL07.ASM      Rev 1.0  29-Aug-93                      ;
;	Data Monitor						;
;								;
;	The user can continuously monitor MIDI data on one or	;
;	all MIDI channels.					;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT THE MESSAGE MONITOR CHANNEL(S)?		;
;	Press the SETUP CHAN key.  The monitor channel is	;
;	selected using the +/- keys and/or the VALUE fader	;
;	(rack unit only).  To monitor ALL channels		;
;	simultaneously, use the +/- keys to select one above	;
;	channel 16 or two below channel 1.  To monitor System	;
;	Messages only, use the +/- keys to select two above	;
;	channel 16 or one below channel 1 (LCD shows "NONE").   ;
;								;
;								;
;	...MONITOR MESSAGES?					;
;	Press the MODE MSG key.  Message LEDs will light for	;
;	each occurrence of that MIDI message on the selected	;
;	message monitor channel(s).  If no channels are 	;
;	selected, only System Messages will be displayed.	;
;								;
;	Message LEDs include:  Note on (nton), note off (noff), ;
;	channel aftertouch (chaf), key aftertouch (kyaf),	;
;	program change (prog), pitch bend (bend), control	;
;	change (cntl), channel mode (mode), song position	;
;	pointer (spp), song select (song), system exclusive	;
;	(sysx), active sensing (sens), start, stop, continue	;
;	(cont), and timing clock (clk). 			;
;								;
;	The LCD gives information for the last message		;
;	received.  Timing Clock and Active Sense Messages are	;
;	not displayed in the LCD.				;
;								;
;								;
;	...MONITOR MESSAGE CHANNELS?				;
;	Press the MODE CH key.	Channel LEDs will light when	;
;	messages are received on that channel, regardless of	;
;	which channel has been selected for message		;
;	monitoring.						;
;								;
;								;
;	...ENABLE THE DATA HOLD DISPLAY?			;
;	Press the LEDs HOLD key.  The LEDs will light and stay	;
;	lit when a matching message is received.  Pressing	;
;	the key again clears the LEDs without leaving this	;
;	mode.							;
;								;
;								;
;	...ENABLE THE FREE RUNNING DISPLAY?			;
;	Press the LEDs FREE key.  After turning off all LEDs,	;
;	the appropriate LED will blink when a matching message	;
;	is received.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When selecting a channel to monitor,			;
;								;
;	|  MESSAGE MODE  |	where nnnn=1-16, "ALL " or      ;
;	|  Channel: nnnn |	"NONE"                          ;
;								;
;								;
;	When monitoring channels,				;
;								;
;	|  CHANNEL MODE  |					;
;	| ...monitoring  |					;
;								;
;								;
;	When waiting for the first message in message mode,	;
;								;
;	|  MESSAGE MODE  |					;
;	|   ...waiting	 |					;
;								;
;								;
;	If the MIDI receive buffer fills up,			;
;								;
;	|*** WARNING *** |					;
;	|Buffer Overflow |					;
;								;
;								;
;	When messages are received in message mode,		;
;								;
;	|TYPE  CH KEY VEL|  |TYPE  CH KEY VEL|			;
;	|NtOff nn bbb bbb|  |NtOn  nn bbb bbb|			;
;								;
;	|TYPE  CH KEY VAL|  |TYPE  CH NUM VAL|			;
;	|KyAft nn bbb bbb|  |Cntrl nn ccc bbb|			;
;								;
;	|TYPE  CH NUM	 |  |TYPE  CH VAL    |			;
;	|Prgrm nn bbb	 |  |ChAft nn bbb    |			;
;								;
;	|TYPE  CH MSB:LSB|  |TYPE  CH STATUS |			;
;	|PBend nn bbb:bbb|  |RsCtl nn ttttt  |			;
;								;
;	|TYPE  CH STATUS |  |TYPE  CH STATUS |			;
;	|Local nn yyyyy  |  |AlOff nn ttttt  |			;
;								;
;	|TYPE  CH STATUS |  |TYPE  CH STATUS |			;
;	|OmOff nn ttttt  |  |OmOn  nn ttttt  |			;
;								;
;	|TYPE  CH NUM	 |  |TYPE  CH STATUS |			;
;	|MonOn nn  ee	 |  |PlyOn nn ttttt  |			;
;								;
;	|TYPE  TY VAL	 |  |TYPE  MSB:LSB   |			;
;	|MTC	a  dd	 |  |SPosP bbb:bbb   |			;
;								;
;	|TYPE  NUM	 |  |TYPE	     |			;
;	|Song  bbb	 |  |Tune Request    |			;
;								;
;	|TYPE		 |  |TYPE	     |			;
;	|SysEx EOX	 |  |Start	     |			;
;								;
;	|TYPE		 |  |TYPE	     |			;
;	|Continue	 |  |Stop	     |			;
;								;
;	|TYPE		 |  |TYPE	     |			;
;	|System Reset	 |  |System Exclusive|			;
;								;
;	|TYPE	     HEX |					;
;	|Undefined   hhh |					;
;								;
;	where nn=1-16, bbb=0-127, ccc=0-120, hh=00H-FFH,	;
;	yyyyy="ON", "OFF" or "undef", ttttt="OK" or "undef",    ;
;	a=0-7, dd=0-15, ee=0-16 				;
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
;	StMon		Monitor messages and channels		;
;	StSet		Set monitor channel for message mode	;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	LHOLD		Clear LEDs and enter LED hold mode	;
;	LFREE		Clear LEDs and enter LED free run mode	;
;	MSDISP		Parse and display current message	;
;	CHDISP		Update display for channel setup	;
;	MCDISP		Update display for monitoring channels	;
;	MMDISP		Update display for monitoring messages	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel
MONMODE 	.DS	1	;monitor mode flag (CH=0,MSG=1)
HOLD		.DS	1	;LED mode flag (0=free, 1=hold)
TEMPCLASS       .DS     1       ;temporary class storage
TEMPVAL         .DS     1       ;temporary value storage

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StMon		EQU	0
StSet		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvMsg		EQU	EV_SW1_ON
EvChan		EQU	EV_SW2_ON
EvMinus 	EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvCh		EQU	EV_SW5_ON
EvFree		EQU	EV_SW7_ON
EvHold		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StMon State 1: StSet			 Not
;	 Event	  NextSt,Act	NextSt,Act			Used
;	 -----------------------------------------------------------
 STM_ROW EvIdle,  StMon,IDLE,	StSet,IDLE,   StMon,IDLE, StMon,IDLE
 STM_ROW EvPlus,  StMon,IDLE,	StSet,CHINC,  StMon,IDLE, StMon,IDLE
 STM_ROW EvMinus, StMon,IDLE,	StSet,CHDEC,  StMon,IDLE, StMon,IDLE
 STM_ROW EvValue, StMon,IDLE,	StSet,CHFDR,  StMon,IDLE, StMon,IDLE
 STM_ROW EvHold,  StMon,LHOLD,	StSet,LHOLD,  StMon,IDLE, StMon,IDLE
 STM_ROW EvFree,  StMon,LFREE,	StSet,LFREE,  StMon,IDLE, StMon,IDLE
 STM_ROW EvCh,	  StMon,MCDISP, StMon,MCDISP, StMon,IDLE, StMon,IDLE
 STM_ROW EvMsg,   StMon,MMDISP, StMon,MMDISP, StMon,IDLE, StMon,IDLE
 STM_ROW EvChan,  StSet,CHDISP, StSet,IDLE,   StMon,IDLE, StMon,IDLE
 STM_ROW EvMsgIn, StMon,MSDISP, StSet,IDLE,   StMon,IDLE, StMon,IDLE

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
	sta	TEMPVAL 	;

	lda	#1		;
	sta	TEMPCLASS	;

	lda	#16		;
	sta	CHAN		;

	lda	#1		;set flag
	sta	MONMODE 	;

	clr	HOLD		;clear flag

;--- Initialize MIDI

	lda	#$FF		;buffer all messages
	sta	M_RX_Q_XPT		;

;--- Initialize display

        jsr     LCD_CLEAR
        LCD_PUT_S "*  MIDItools   *"
        jsr     DELAY_1SEC
        jsr     LCD_CLEAR

        LCD_PUT_S "7:          Data"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0     Monitor"
	jsr	DELAY_1SEC

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S "  MESSAGE MODE  "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "   ...waiting   "

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

;--- Clear LEDs and enter hold mode

LHOLD:	jsr	LED_INIT	;turn off all LEDs
	lda	#1		;set flag
	sta	HOLD		;
	rts

;--- Clear LEDs and enter free run mode

LFREE:	jsr	LED_INIT	;turn off all LEDs
	clr	HOLD		;clear flag
	rts

;--- Parse and display current message

MSDISP: lda	MONMODE 	;fetch mode flag
	bne	DSPMSG		;=1 (message mode)? branch...

;--- Display channel (Channel Mode)

	brclr	CHMSG,MP_FLAGS,MDEND

	lda	MP_RSTAT 	;=0 (channel mode)? fetch ststus
	and	#$0F		;get channel
	jsr	LED_ON		;turn appropriate LED on

	lda	HOLD		;fetch LED mode flag
	cmp	#1		;hold mode?
	beq	MDEND		;yes? branch...
	lda	MP_RSTAT 	;no? fetch status
	and	#$0F		;get channel
	jsr	LED_OFF 	;turn appropriate LED off
MDEND:	rts

;--- Display message contents (Message Mode)

DSPMSG: FAR_BRSET QFULL,MP_FLAGS,SHOWERR
	FAR_BRSET CHMSG,MP_FLAGS,SHOWCHM
	FAR_BRSET SYSRT,MP_FLAGS,SHOWRT
	FAR_BRSET SYSEX,MP_FLAGS,SHOWSEX
	FAR_BRSET SYSCO,MP_FLAGS,SHOWCOM

	jmp	SHOWUNDEF	;should never get here

;--- Display System Exclusive Messages

SHOWSEX:
	lda	#10		;turn on SYSEX LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X10		;
	lda	#10		;
	jsr	LED_OFF 	;

X10:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "System Exclusive"
	rts


;--- Display System Realtime Messages

SHOWRT: lda	MP_SRSTAT		;fetch Sys Realtime status byte
	cmp	#$F8		;display CLOCK
	FAR_BEQ	SHOWCLK		;
	cmp	#$FA		;display START
	FAR_BEQ	SHOWSTART	;
	cmp	#$FB		;display CONTINUE
	FAR_BEQ	SHOWCONT	;
	cmp	#$FC		;display STOP
	FAR_BEQ	SHOWSTOP	;
	cmp	#$FE		;display ACTIVE SENSING
	FAR_BEQ	SHOWACT		;
	cmp	#$FF		;display RESET
	FAR_BEQ SHOWRST 	;
	jmp	SHOWUNDEF	;others are undefined

SHOWCLK:
	lda	#15		;turn on CLOCK LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	CLKEND		;
	lda	#15		;
	jsr	LED_OFF 	;
CLKEND: rts

SHOWSTART:
	lda	#3		;turn on START LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X3		;
	lda	#3		;
	jsr	LED_OFF 	;

X3:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Start           "
	rts

SHOWCONT:
	lda	#11		;turn on CONTINUE LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X11		;
	lda	#11		;
	jsr	LED_OFF 	;

X11:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Continue        "
	rts

SHOWSTOP:
	lda	#7		;turn on STOP LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X7		;
	lda	#7		;
	jsr	LED_OFF 	;

X7:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Stop            "
	rts

SHOWACT:
	lda	#14		;turn on ACTIVE SENSE LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	ACTEND		;
	lda	#14		;
	jsr	LED_OFF 	;
ACTEND: rts

SHOWRST:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "System Reset    "
	rts

SHOWUNDEF:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE        HEX "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Undefined     H "

	lda	#12		;display hex value
	ldx	#1		;
	jsr	LCD_GOTOXY	;

        brset   SYSRT,MP_FLAGS,SURT     ;find out where the status
        brset   SYSCO,MP_FLAGS,SUSC     ;  byte is...

	lda	MP_RSTAT	;
        bra     SUD             ;
SURT:   lda     MP_SRSTAT       ;
        bra     SUD
SUSC:   lda     MP_SCSTAT

SUD:    jsr     LCD_PUT_H       ;
	rts

;--- Display System Common Messages

SHOWCOM:
        lda     MP_SCSTAT       ;fetch Sys Common status byte
	cmp	#$F1		;MTC Quarter Frame?
	FAR_BEQ SHOWMTC 	;
	cmp	#$F2		;Song Position Pointer?
	FAR_BEQ SHOWSPP 	;
	cmp	#$F3		;Song Select?
	FAR_BEQ SHOWSSEL	;
	cmp	#$F6		;Tune Request?
	FAR_BEQ SHOWTUNE	;
	cmp	#$F7		;EOX?
	FAR_BEQ SHOWEOX 	;
	jmp	SHOWUNDEF	;others are undefined

SHOWMTC:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  TY VAL    "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "MTC             "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	MP_DATA1	;get MTC type and show it
	lsra			;
	lsra			;
	lsra			;
	lsra			;
	jsr	LCD_PUT_RJ2_I	;

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	MP_DATA1	;get MTC value and show it
	and	#$0F		;
	jsr	LCD_PUT_RJ2_I	;
	rts

SHOWSPP:
	lda	#2		;turn on SPP LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X2B		;
	lda	#2		;
	jsr	LED_OFF 	;

X2B:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  MSB:LSB   "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "SPosP    :      "

	lda	#8		;display MSB
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;
	jsr	LCD_PUT_RJ3_I	;

	lda	#12		;display LSB
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA1        ;
	jsr	LCD_PUT_RJ3_I	;
	rts

SHOWSSEL:
	lda	#6		;turn on SONG SELECT LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X6		;
	lda	#6		;
	jsr	LED_OFF 	;

X6:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  NUM       "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Song            "

	lda	#8		;display data byte
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA1        ;
	jsr	LCD_PUT_RJ3_I	;
	rts

SHOWTUNE:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Tune Request    "
	rts

SHOWEOX:
	lda	#10		;turn on SYSEX LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X10B		;
	lda	#10		;
	jsr	LED_OFF 	;

X10B:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE            "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "SysEx EOX       "
	rts


;--- Display Channel Messages

SHOWCHM:
	lda	CHAN		;fetch selected channel
	cmp	#16		;=16 (ALL)?
	beq	SCMA		;yes? branch...

	lda	MP_RSTAT 	;no? fetch received status
	and	#$0F		;get channel
	cmp	CHAN		;is it the selected channel?
	beq	SCMA		;yes? branch...
	rts			;no? return

SCMA:	lda	MP_RSTAT 	;fetch status byte
	and	#$F0		;get MIDI Channel

	cmp	#$80		;note off?
	FAR_BEQ	SHOWNTOF	;
	cmp	#$90		;note on?
	FAR_BEQ	SHOWNTON	;
	cmp	#$A0		;key aftertouch?
	FAR_BEQ	SHOWKEYAFT	;
	cmp	#$B0		;controller?
	FAR_BEQ	SHOWCTLR	;
	cmp	#$C0		;program change?
	FAR_BEQ	SHOWPRGCH	;
	cmp	#$D0		;channel aftertouch?
	FAR_BEQ	SHOWCHAFT	;
	cmp	#$E0		;pitch bend?
	FAR_BEQ	SHOWPBEND	;
	jmp	SHOWUNDEF	;anything else

;displays the 2nd Data Byte of 3-byte Channel Messages

SHOWCHMSG3:
	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	jsr	LCD_PUT_RJ3_I	;display it

;displays Status & 1st Data Bytes of Channel messages

SHOWCHMSG2:
	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA1        ;fetch 1st data byte
	jsr	LCD_PUT_RJ3_I	;display it
	rts

SHOWNTOF:
	lda	#4		;turn on NOTE OFF LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X4		;
	lda	#4		;
	jsr	LED_OFF 	;

X4:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH KEY VEL"

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "NtOff           "

	jmp	SHOWCHMSG3	;display data

SHOWNTON:
	lda	#0		;turn on NOTE ON LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X0		;
	lda	#0		;
	jsr	LED_OFF 	;

X0:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH KEY VEL"

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "NtOn            "

	jmp	SHOWCHMSG3	;display data

SHOWKEYAFT:
	lda	#12		;turn on KEY AFTERTOUCH LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X12		;
	lda	#12		;
	jsr	LED_OFF 	;

X12:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH KEY VAL"

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "KyAft           "

	jmp	SHOWCHMSG3	;display data

SHOWCTLR:
        lda     MP_DATA1        ;fetch 1st data byte
	cmp	#120		;mode message?
	bhi	SHOWMODE	;yes? branch...

	lda	#9		;no? turn on CONTROLLER LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X9		;
	lda	#9		;
	jsr	LED_OFF 	;

X9:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH NUM VAL"

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Cntrl           "

	jmp	SHOWCHMSG3	;display data

SHOWMODE:
	lda	#13		;turn on MODE LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X13		;
	lda	#13		;
	jsr	LED_OFF 	;

X13:    lda     MP_DATA1        ;dispatch MODE message
	cmp	#121		;reset all controllers?
	FAR_BEQ SHOWRALL	;
	cmp	#122		;local control?
	FAR_BEQ SHOWLOCAL	;
	cmp	#123		;all notes off?
	FAR_BEQ SHOWALLOFF	;
	cmp	#124		;OMNI off?
	FAR_BEQ SHOWOMOF	;
	cmp	#125		;OMNI on?
	FAR_BEQ SHOWOMON	;
	cmp	#126		;MONO on?
	FAR_BEQ SHOWMONO	;
	jmp	SHOWPOLY	;must be POLY on

SHOWRALL:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "RsCtl           "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is value valid (=0)?
	beq	RSACA		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

RSACA:	LCD_PUT_S " OK "        ;display "OK"
	rts

SHOWLOCAL:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Local           "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is it "local off" (=0)?
	beq	LOCALA		;yes? branch...
	cmp	#127		;no? is it "local on" (=127)?
	beq	LOCALB		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

LOCALA: LCD_PUT_S " off"        ;display "off"
	rts

LOCALB: LCD_PUT_S " on"         ;display "on"
	rts

SHOWALLOFF:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "AlOff           "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is value valid (=0)?
	beq	AOFFA		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

AOFFA:	LCD_PUT_S " OK "        ;display "OK"
	rts

SHOWOMOF:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OmOff           "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is value valid (=0)?
	beq	OMOFA		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

OMOFA:	LCD_PUT_S " OK "        ;display "OK"
	rts

SHOWOMON:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OmOn            "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is value valid (=0)?
	beq	OMONA		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

OMONA:	LCD_PUT_S " OK "        ;display "OK"
	rts

SHOWMONO:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH NUM   "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "MonOn          "

	jmp	SHOWCHMSG3	;display channel and #channels

SHOWPOLY:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH STATUS "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "PlyOn           "

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch 2nd data byte
	cmp	#0		;is value valid (=0)?
	beq	POLYA		;yes? branch...
	LCD_PUT_S "undef"       ;no? display "undef"
	rts

POLYA:	LCD_PUT_S " OK "        ;display "OK"
	rts

SHOWPRGCH:
	lda	#1		;turn on PROG LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X1		;
	lda	#1		;
	jsr	LED_OFF 	;

X1:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH NUM    "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Prgrm           "

	jmp	SHOWCHMSG2	;display data

SHOWCHAFT:
	lda	#8		;turn on CHAN AFTERTOUCH LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X8		;
	lda	#8		;
	jsr	LED_OFF 	;

X8:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH VAL    "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "ChAft           "

	jmp	SHOWCHMSG2	;display data

SHOWPBEND:
	lda	#5		;turn on BEND LED
	jsr	LED_ON		;

	lda	HOLD		;turn off only if
	cmp	#1		; in free run mode
	beq	X5		;
	lda	#5		;
	jsr	LED_OFF 	;

X5:	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "TYPE  CH MSB:LSB"

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "PBend       :   "

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA1        ;fetch LSB (1st data byte)
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MP_RSTAT 	;fetch status
	and	#$0F		;get channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        lda     MP_DATA2        ;fetch MSB (2nd data byte)
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Display Full Buffer Message

SHOWERR:
	lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "*** WARNING *** "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Buffer Overflow "

	bclr 	QFULL,MP_FLAGS	;clear flag

	rts

;--- Update display for channel setup

CHDISP: jsr	LED_INIT	;turn LEDs off

	lda	#0		;display top line
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  MESSAGE MODE  "

	lda	#0		;display bottom line
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  Channel:      "

	lda	CHAN		;fetch channel number
	cmp	#16		;
	beq	CDSA		;branch if "ALL"
	cmp	#17		;
	bhs	CDSB		;branch if "NONE"

	lda	#13		;otherwise, position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

CDSA:	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "ALL"         ;display "ALL"
	rts

CDSB:	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "NONE"        ;display "NONE"
	rts

;--- Update display for monitoring channels

MCDISP: lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  CHANNEL MODE  "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " ...monitoring  "

	clr	MONMODE 	;clear mode flag
	jsr	LED_INIT	;reset LEDs
	rts

;--- Update display for monitoring messages

MMDISP: lda	#0		;top line of LCD display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "  MESSAGE MODE  "

	lda	#0		;bottom line of LCD display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   ...waiting   "

	lda	#1		;set mode flag
	sta	MONMODE 	;
	jsr	LED_INIT	;reset LEDs
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
SCI_RX_CBCK_D1:
SCI_RX_CBCK_D2:
	sta	TEMPCLASS	;save class
	stx	TEMPVAL 	;save value
	txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	lda	TEMPCLASS	;restore class in acca
	ldx	TEMPVAL 	;restore value in x
        jmp     SCI_RX_CBCK_S_RET  ;return, buffer it
