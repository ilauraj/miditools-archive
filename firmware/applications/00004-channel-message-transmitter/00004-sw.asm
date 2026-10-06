;===============================================================;
;								;
;       TOOL02.ASM      Rev 1.0  29-Aug-93                      ;
;	Channel Message Transmitter				;
;								;
;	The user can program and transmit certain MIDI Channel	;
;	Voice Messages. 					;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE TRANSMIT CHANNEL?				;
;	Press the SETUP CHAN key.  The MIDI transmit channel	;
;	is selected using the +/- keys and/or the VALUE fader.	;
;								;
;								;
;	...SELECT THE MESSAGE TYPE?				;
;	Press the SETUP MSG key.  The message type is selected	;
;	using the +/- keys.					;
;								;
;	The following Channel Voice Message types can be	;
;	selected for use:					;
;								;
;		Channel Voice Message Type			;
;		----------------------------------		;
;		Program Change					;
;		Pitch Bend					;
;		Channel Aftertouch				;
;		Modulation Wheel (Controller #1)		;
;		Breath Controller (Controller #2)		;
;		Foot Controller (Controller #4) 		;
;		Portamento Time (Controller #5) 		;
;		Data Entry (Controller #6)			;
;		Main Volume (Controller #7)			;
;		Balance (Controller #8) 			;
;		Pan (Controller #10)				;
;		Expression (Controller #11)			;
;								;
;								;
;	...TRANSMIT DATA?					;
;	Press the DATA key.  MIDI messages (of the selected	;
;	type) are transmitted each time the data value is	;
;	modified with the +/- keys and/or the VALUE fader.	;
;	The LCD gives complete message information.		;
;								;
;	Generated data are merged with incoming MIDI data.	;
;								;
;								;
;	...READ THE DISPLAYED PITCH BEND VALUES?		;
;	Pitch bend values are transmitted in 128 discrete	;
;	steps over the full range of possible values.  The LCD	;
;	shows this range as -64 to +63. 			;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|PROGRAM      bbb|   |PITCH BEND   ppp| 		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|AFTERTOUCH   bbb|   |MOD WHEEL    bbb| 		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|BREATH CTL   bbb|   |FOOT CTL	   bbb| 		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|PORTAMENTO   bbb|   |DATA ENTRY   bbb| 		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|VOLUME       bbb|   |BALANCE	   bbb| 		;
;								;
;	|CHANNEL       nn|   |CHANNEL	    nn| 		;
;	|PAN	      bbb|   |EXPRESSION   bbb| 		;
;								;
;	where nn=1-16, bbb=0-127, ppp=-64 to +63		;
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
;	StMsg		Set message type			;
;	StData		Transmit message			;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	MSGINC		Increment message type			;
;	MSGDEC		Decrement message type			;
;	DATINC		Increment data value and transmit it	;
;	DATDEC		Decrement data value and transmit it	;
;	DATFDR		Set data value with fader and transmit	;
;	CDISP		Update display for changing channel	;
;	MDISP		Update display for changing message	;
;	DDISP		Update display for setting data value	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;These codes represent the message type in the MESSAGE variable

MSG_PRGCH	VAR	1	;code for PROGRAM CHANGE
MSG_PBEND	VAR	2	;code for PITCH BEND
MSG_CHAFT	VAR	3	;code for CH AFTERTOUCH
MSG_MOD 	VAR	4	;code for MOD WHEEL
MSG_BRTH	VAR	5	;code for BREATH CONTROL
MSG_FOOT	VAR	6	;code for FOOT CONTROL
MSG_PORTA	VAR	7	;code for PORTAMENTO TIME
MSG_DATA	VAR	8	;code for DATA ENTRY
MSG_VOL 	VAR	9	;code for MAIN VOLUME
MSG_BAL 	VAR	10	;code for BALANCE
MSG_PAN 	VAR	11	;code for PAN
MSG_EXP 	VAR	12	;code for EXPRESSION

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CHAN		.DS	1	;MIDI transmit channel
MESSAGE 	.DS	1	;message type
DATAVAL 	.DS	1	;message data byte value
DATAPREV	.DS	1	;previous data byte value

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StMsg		EQU	1
StData		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvChan		EQU	EV_SW1_ON
EvMsg		EQU	EV_SW2_ON
EvData		EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StCh  State 1:StMsg State 2:StData       Not
;	 Event	  NextSt,Act	NextSt,Act    NextSt,Act	  Used
;	 -------------------------------------------------------------
 STM_ROW EvIdle,  StCh,IDLE,	StMsg,IDLE,   StData,IDLE,   StCh,IDLE
 STM_ROW EvPlus,  StCh,CHINC,	StMsg,MSGINC, StData,DATINC, StCh,IDLE
 STM_ROW EvMinus, StCh,CHDEC,	StMsg,MSGDEC, StData,DATDEC, StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,	StMsg,IDLE,   StData,DATFDR, StCh,IDLE
 STM_ROW EvChan,  StCh,IDLE,	StCh,CDISP,   StCh,CDISP,    StCh,IDLE
 STM_ROW EvMsg,   StMsg,MDISP,	StMsg,IDLE,   StMsg,MDISP,   StCh,IDLE
 STM_ROW EvData,  StData,DDISP, StData,DDISP, StData,IDLE,   StCh,IDLE

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
	sta	DATAVAL 	;
	sta	DATAPREV	;

	lda	#1		;
	sta	MESSAGE 	;

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "2:   Channel Msg"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0 Transmitter"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "CHANNEL"

	jsr	MDISP		;update display
	jsr	DDISP		;
	jsr	CDISP		;

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
	jsr	CDISP		;update display
	rts

;--- Decrement channel

CHDEC:	lda	CHAN		;fetch channel
	deca			;increment
	cmp	#15		;valid range: 0-15
	bls	CDA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
CDA:	sta	CHAN		;store new value
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

;--- Increment message type

MSGINC: lda	MESSAGE 	;fetch message type
	inca			;increment
	cmp	#12		;valid range: 1-12
	bls	MIA		;< or =12? branch...
	lda	#1		;>12? wrap to 1
MIA:	sta	MESSAGE 	;store new value
	jsr	MDISP		;update display
	rts

;--- Decrement message type

MSGDEC: lda	MESSAGE 	;fetch message type
	deca			;decrement
	bne	MDA		;nonzero? branch...
	lda	#12		;=0? wrap to 12
MDA:	sta	MESSAGE 	;store new value
	jsr	MDISP		;update display
	rts

;--- Increment data value and transmit it

DATINC: lda	DATAVAL 	;fetch data value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DDISP		;update display
	jmp	MSGSND		;send message

;--- Decrement data value and transmit it

DATDEC: lda	DATAVAL 	;fetch data value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DDISP		;update display
	jmp	MSGSND		;send message

;--- Set data value with fader and transmit

DATFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	DATAVAL 	;save new value
	jsr	DDISP		;update display

;--- Transmit message

MSGSND: lda	DATAVAL 	;if DATAVAL=DATAPREV,
	cmp	DATAPREV	; return without transmitting
	bne	MSA		;
	rts			;

MSA:	sta	DATAPREV	;update DATAPREV

	ldx	MESSAGE 	;fetch current message for lookup
	decx			;(start from index=0)

MSB:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	MSB		; receiving a message

	sei			;disable all interrupts
	JMP_TABLE TBL_MSG	;execute jump from table

TBL_MSG:
	.DW TXPRGC,TXBEND,TXCHAF,TXMODW,TXBRTH,TXFOOT
	.DW TXPORT,TXDTEN,TXMVOL,TXBAL,TXPAN,TXEXPR

;--- Transmit PROGRAM CHANGE

TXPRGC: lda	#$C0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Data byte
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXPE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXPE:	cli			;enable all interrupts
	rts

;--- Transmit PITCH BEND

TXBEND: lda	#$E0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#0		;load MIDI Data byte (bend LSB)
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Data byte (bend MSB)
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXBE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXBE:	cli			;enable all interrupts
	rts

;--- Transmit CHANNEL AFTERTOUCH

TXCHAF: lda	#$D0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Data byte
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXCE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXCE:	cli			;enable all interrupts
	rts

;--- Transmit MOD WHEEL

TXMODW: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$01		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXME		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXME:	cli			;enable all interrupts
	rts

;--- Transmit BREATH CONTROLLER

TXBRTH: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$02		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXBRE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXBRE:	cli			;enable all interrupts
	rts

;--- Transmit FOOT CONTROLLER

TXFOOT: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$04		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXFE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXFE:	cli			;enable all interrupts
	rts

;--- Transmit PORTAMENTO TIME

TXPORT: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$05		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXPOE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXPOE:	cli			;enable all interrupts
	rts

;--- Transmit DATA ENTRY

TXDTEN: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$06		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXDTE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXDTE:	cli			;enable all interrupts
	rts

;--- Transmit MAIN VOLUME

TXMVOL: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$07		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXMVE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXMVE:	cli			;enable all interrupts
	rts

;--- Transmit BALANCE

TXBAL:	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$08		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXBAE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXBAE:	cli			;enable all interrupts
	rts

;--- Transmit PAN

TXPAN:	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$0A		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXPANE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXPANE: cli			;enable all interrupts
	rts

;--- Transmit EXPRESSION

TXEXPR: lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	#$0B		;load MIDI Controller Number
	jsr	MIDI_PUT	;send it

	lda	DATAVAL 	;load MIDI Controller Value
	jsr	MIDI_PUT	;send it

	lda	M_RSTAT		;fetch external running status
	beq	TXEXE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

TXEXE:	cli			;enable all interrupts
	rts

;--- Update display for changing channel

CDISP:	lda	#11		;clear DATA arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '		;
	jsr	LCD_PUT_C	;

	lda	#11		;place CH arrow
	ldx	#0		;
	jsr	LCD_PUT_ARROW	;

	lda	#15		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for changing message type

MDISP:	lda	#11		;clear CH arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#11		;clear DATA arrow and value
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "     "       ;

	lda	#0		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	ldx	MESSAGE 	;fetch current message for lookup
	decx			;(start from index=0)

	JMP_TABLE TBL_DSP	;execute jump from table

TBL_DSP:
	.DW DPROG,DBEND,DCHAF,DMODW,DBRTH,DFOOT,DPORT,DDATA
	.DW DMVOL,DBAL,DPAN,DEXP

DPROG:	LCD_PUT_S "PROGRAM   "
	rts

DBEND:	LCD_PUT_S "PITCH BEND"
	rts

DCHAF:	LCD_PUT_S "AFTERTOUCH"
	rts

DMODW:	LCD_PUT_S "MOD WHEEL "
	rts

DBRTH:	LCD_PUT_S "BREATH CTL"
	rts

DFOOT:	LCD_PUT_S "FOOT CTL  "
	rts

DPORT:	LCD_PUT_S "PORTAMENTO"
	rts

DDATA:	LCD_PUT_S "DATA ENTRY"
	rts

DMVOL:	LCD_PUT_S "VOLUME    "
	rts

DBAL:	LCD_PUT_S "BALANCE   "
	rts

DPAN:	LCD_PUT_S "PAN       "
	rts

DEXP:	LCD_PUT_S "EXPRESSION"
	rts

;--- Update display for setting data value

DDISP:	lda	#11		;clear CH arrow
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#' '		;
	jsr	LCD_PUT_C	;

	lda	#11		;place DATA arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	MESSAGE 	;fetch message code
	cmp	#MSG_PBEND	;is it pitch bend?
	beq	VDBEND		;yes? branch...

	lda	#15		;no? position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DATAVAL 	;fetch data value
	jsr	LCD_PUT_RJ3_I	;display it
	jmp	VDEND		;jump...

;--- Display pitch bend value as "-64 ... +63"

VDBEND: lda	#13		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	DATAVAL 	;if display value is -9 to +9,
	cmp	#73		; use a space to right justify it
	bhi	VDBA		;
	cmp	#55		;
	blo	VDBA		;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

VDBA:	lda	DATAVAL 	;determine displayed sign
	cmp	#64		;
	bhi	VDBC		;

	beq	VDBB		;no +/- sign for "0"

	lda	#'-'            ;if negative, display "-"
	jsr	LCD_PUT_C	; before value
	lda	#64		;
	sub	DATAVAL 	;
	jsr	LCD_PUT_I	;
	jmp	VDEND		;

VDBB:	LCD_PUT_S " 0"          ;display "0"
	jmp	VDEND		;

VDBC:	lda	#'+'            ;if positive, display "+"
	jsr	LCD_PUT_C	; before value
	lda	DATAVAL 	;
	sub	#64		;
	jsr	LCD_PUT_I	;
VDEND:	rts

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

