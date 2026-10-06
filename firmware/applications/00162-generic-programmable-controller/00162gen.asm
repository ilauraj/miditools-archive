;----------------------------------------
;	Constants
;----------------------------------------

SEX_Q_LEN	EQU	86	;sysex queue length
MMAID		EQU	125	;MMA manufacturer ID number ($7D)
OL_LED		EQU	15	;overload LED

; total of only 95 is allowed, including variables!!!

;-----------------------------------------
;	Variables
;-----------------------------------------

        .APPL_RAM
        .ABSOLUTE

SEX_Q		.DS  SEX_Q_LEN	;SYSEX queue

SEX_Q_WRITE     .DS     1      	;next SYSEX queue write address (0-255)
EE_Q_WRITE      .DS     1      	;next EEPROM write address (0-255)
SEX_Q_ENABLE	.DS	1	;SYSEX queue enable flag (0=enabled)
SEX_CAP         .DS     1      	;flags capture mode (1=capturing)
SEX_ID		.DS	1	;SysEx ID byte ready flag (1=check ID)

TEMPVAL		.DS	1	;temporary data value byte
TMPNUM		.DS	1	;temporary display variable
LOWNIB		.DS	1	;low nibble byte
NLOW		.DS	1	;low nibble present flag (1=yes)

;-------------------------------
;	State Matrix
;-------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
Ev1		EQU	EV_SW1_ON
Ev2		EQU	EV_SW2_ON
Ev3		EQU	EV_SW3_ON
Ev4	   	EQU	EV_SW4_ON
Ev5		EQU	EV_SW5_ON
Ev6		EQU	EV_SW6_ON
Ev7		EQU	EV_SW7_ON
Ev8		EQU	EV_SW8_ON
EvScroll 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StOp                             Not
;	 Event	  NextSt,Act                              Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,   StOp,IDLE,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev1,      StOp,SEND1, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev2,      StOp,SEND2, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev3,      StOp,SEND3, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev4,      StOp,SEND4, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev5,      StOp,SEND5, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev6,      StOp,SEND6, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev7,      StOp,SEND7, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW Ev8,      StOp,SEND8, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvScroll, StOp,DISP,  StOp,IDLE, StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;
	sta	SEX_CAP 	;
	sta	SEX_Q_WRITE	;
	sta	EE_Q_WRITE	;
	sta	SEX_Q_ENABLE	;
	sta	SEX_ID		;
	sta	NLOW		;

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S "  MediaMation  "	;Generic Programmable MIDI Controller;

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S " Controller v.1 "
	jsr	DELAY_1SEC

        jsr     LCD_CLEAR

	lda	#0		;display top line (fixed characters)
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "MSG BYTE HEXVAL "

	jsr	DISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- Idle action (administer sysex message storage)

IDLE:	lda	SEX_Q_WRITE	;any new data for EEPROM?
	sub	EE_Q_WRITE	;
	beq	MSEND		;no? leave...
        cmp     #SEX_Q_LEN	;
	bhi	MS_OL		;overloaded? branch...

	;we have new data to write to EEPROM

	ldx	EE_Q_WRITE	;yes? find location of next data in queue
	cpx	#SEX_Q_LEN	;compare
	blo	MS2		;straightforward? jump ahead...

	;adjust pointer to locate data

MSADJ:	txa			;transfer pointer to acca
	sub	#SEX_Q_LEN	;subtract queue length
	tax			;transfer remainder to x
	cpx	#SEX_Q_LEN	;compare to queue again
	blo	MS2		;finished? jump ahead...
	jmp	MSADJ		;no? loop and adjust again...

	;data is in queue at location given by x

MS2:	ldx	SEX_Q,X 	;get new data byte from queue
	lda	EE_Q_WRITE	;get position to write data to
        jsr     EE_WRITE        ;write data to EEPROM
	lda	EE_Q_WRITE	;get EE_Q_WRITE
	inca			;increment it
	sta	EE_Q_WRITE	;save new value
MSEND:	rts

	;overloaded buffer, act as if sysex was terminated

MS_OL:	ldx	#0		;reset
	stx	SEX_Q_ENABLE	;
	stx	SEX_Q_WRITE	;
	stx	EE_Q_WRITE	;
	stx	SEX_CAP		;
	stx	SEX_ID		;
	jsr	DISP		;
	lda	#OL_LED		;
	jsr	LED_ON		;
	rts

;--- Send Message #1

SEND1:	lda	#0		;initialize counter
	sta	TMPNUM		;save counter
S1A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#32		;compare to limit
	bhs	S1DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S1A		;loop
S1DUN:	rts			;

;--- Send Message #2

SEND2:	lda	#32		;initialize counter
	sta	TMPNUM		;save counter
S2A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#64		;compare to limit
	bhs	S2DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S2A		;loop
S2DUN:	rts			;

;--- Send Message #3

SEND3:	lda	#64		;initialize counter
	sta	TMPNUM		;save counter
S3A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#96		;compare to limit
	bhs	S3DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S3A		;loop
S3DUN:	rts			;

;--- Send Message #4

SEND4:	lda	#96		;initialize counter
	sta	TMPNUM		;save counter
S4A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#128		;compare to limit
	bhs	S4DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S4A		;loop
S4DUN:	rts			;

;--- Send Message #5

SEND5:	lda	#128		;initialize counter
	sta	TMPNUM		;save counter
S5A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#160		;compare to limit
	bhs	S5DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S5A		;loop
S5DUN:	rts			;

;--- Send Message #6

SEND6:	lda	#160		;initialize counter
	sta	TMPNUM		;save counter
S6A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#192		;compare to limit
	bhs	S6DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S6A		;loop
S6DUN:	rts			;

;--- Send Message #7

SEND7:	lda	#192		;initialize counter
	sta	TMPNUM		;save counter
S7A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#224		;compare to limit
	bhs	S7DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S7A		;loop
S7DUN:	rts			;

;--- Send Message #8

SEND8:	lda	#224		;initialize counter
	sta	TMPNUM		;save counter
S8A:	jsr	EE_READ		;get data from EEPROM
	jsr	MIDI_PUT	;send byte
	jsr	DELAY_1MS	;wait
	lda	TMPNUM		;get counter
	inca			;increment
	cmp	#0		;compare to limit
	beq	S8DUN		;sent 32 bytes? leave...
	sta	TMPNUM		;not done? save new counter value
	jmp	S8A		;loop
S8DUN:	rts			;

;--- Update display

DISP:	lda	#1		;move cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	FDR		;get fader value
	lsra			;divide by 32
	lsra			;
	lsra			;
	lsra			;
	lsra			;
	sta	TMPNUM		;save message number as 0-7
	inca			;increment to display as 1-8
	jsr	LCD_PUT_I	;write message number

	lda	#6		;move cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	TMPNUM		;get message number (0-7)
	lsla			;multiply by 32
	lsla			;
	lsla			;
	lsla			;
	lsla			;
	sta	TMPNUM		;save value (0,32,64,96,128,160,192 or 224)
	lda	FDR		;get fader value
	sub	TMPNUM		;subtract to get byte number (0-31)
	inca			;increment to display as 1-32)
	jsr	LCD_PUT_RJ2_I	;write byte number

	lda	#11		;move cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	FDR		;get fader value
	jsr	EE_READ 	;fetch stored data byte value
	jsr	LCD_PUT_H	;write byte value in hex
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

;--- Process Status Bytes

SCI_RX_CBCK_S:

	;data is in x

	cpx	#$F0		;is message a SYSEX?
	beq	RXSEX		;yes? process it...

	;we have a non-SysEx status byte

	lda	SEX_CAP		;are we capturing?
	bne	RXD2		;yes? continue...
	rti			;no? leave...

	;once in capture mode, treat any status byte as EOX

RXD2:	ldx	#0		;yes? disable and reset queues
	stx	SEX_Q_ENABLE	;
        stx     SEX_Q_WRITE     ;
        stx     EE_Q_WRITE      ;
	stx	SEX_CAP 	;
	stx	SEX_ID		;
;	jsr	DISP		;update display...
	rti			;leave...

	;process SysEx status byte

RXSEX:	ldx	#1		;enable queue
	stx	SEX_Q_ENABLE	;
	stx	SEX_ID		;set up for next (ID) byte
	rti			;leave...

;--- Process Data Bytes

SCI_RX_CBCK_D1:

	;data is in x

	stx	TEMPVAL		;save data value
	lda	SEX_Q_ENABLE	;is SYSEX queue enabled?
	bne	RXNQ		;yes? continue...
	rti			;no? leave...

	;queue is enabled (we are capturing)

RXNQ:	lda	SEX_ID		;are we waiting for 1st data byte (ID)?
	beq	RXNQA		;no? move on to enqueue data...

	;check manufacturer ID byte (data is still in x)

	cpx	#MMAID		;yes? SysEx ID match?
	bne	RX_RST		;no? go reset queue...

	;we have a valid sysex string; prepare to process

	lda	#1		;yes? set capture mode flag
	sta	SEX_CAP		;
	sta	NLOW		;initialize low nibble present flag
	lda	#0		;reset ID flag
	sta	SEX_ID		;
	rti			;leave, do not enqueue ID byte...

	;we have a valid data byte to put in queue

RXNQA:	ldx	SEX_Q_WRITE	;load queue position
	cpx	#SEX_Q_LEN	;compare to max length
	blo	RXNQA2		;<max length? continue...

	;adjust queue pointer position

RNQADJ:	txa			;transfer to acca
	sub	#SEX_Q_LEN	;subtract max length
	tax			;transfer to x
	cpx	#SEX_Q_LEN	;compare to max length
	blo	RXNQA2		;<max length? continue...
	jmp	RNQADJ		;no? loop...

	;write data to queue (queue pointer is in x)

RXNQA2:	lda	NLOW		;check low nibble present flag
	beq	RXHI		;not present? jump...

	;we have a low nibble to save for later

	lda	TEMPVAL		;get data
	sta	LOWNIB		;save as low nibble
	lda	#0		;clear low nibble present flag
	sta	NLOW		;
	rti			;leave...

	;we have a high nibble, combine and write to queue

RXHI:	lda	TEMPVAL		;get data
	lsla			;shift nibble into MS position
	lsla			;
	lsla			;
	lsla			;
	add	LOWNIB		;add in low nibble
	sta	SEX_Q,X 	;write data to queue
	ldx	SEX_Q_WRITE	;get SEX_Q_WRITE
	incx			;increment
	stx	SEX_Q_WRITE	;save new value
	lda	#1		;reset flag
	sta	NLOW
	rti			;leave...

RX_RST:	ldx	#0		;disable queue
	sta	SEX_Q_ENABLE	;
	sta	SEX_ID		;
	rti			;leave...

;--- Process 2nd Data Bytes (can not be System Exclusive data)

SCI_RX_CBCK_D2:
       rti			;leave, do not enqueue...
