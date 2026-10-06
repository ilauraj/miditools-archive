;===============================================================;
;								;
;       TOOL01.ASM      Rev 1.0                                 ;
;	Universal Transmitter					;
;								;
;	The user can program and transmit any MIDI message up	;
;	to three (3) bytes in length.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...CONFIGURE A MESSAGE? 				;
;	A byte number is selected using the SELECT BYTE keys:	;
;	1, 2 or 3.  The hex value of the selected byte is	;
;	programmed using the +/- keys and/or the VALUE fader.	;
;	The LCD gives the byte hex values.			;
;								;
;								;
;	...INACTIVATE BYTES?					;
;	After selecting the desired byte number, it can be	;
;	inactivated by pressing the NULL key.  Inactive bytes	;
;	(indicated in the LCD by "--") are not transmitted.     ;
;	Pressing the +/- keys or moving the VALUE fader 	;
;	reactivates the byte.					;
;								;
;								;
;	...SEND THE MESSAGE?					;
;	Press the MESSAGE SEND key.  Activated bytes are	;
;	transmitted.  The TRANSMITTING LED will flash.	The	;
;	message is merged with incoming MIDI data.		;
;								;
;								;
;	...CLEAR THE MESSAGE?					;
;	Press the MESSAGE CLEAR key.  All three bytes are	;
;	reset to their inactive state.				;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When configuring a message,				;
;								;
;	|1:hh  2:hh  3:hh|	where hh=00H-FFH or "--",       ;
;	|Program Byte a  |	a=1,2 or 3			;
;								;
;								;
;	When the CLEAR key is pressed,				;
;								;
;	|1:--  2:--  3:--|					;
;	|Message Reset...|					;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI Ports used: IN,OUT,THRU. 	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StB1		Configure Byte 1			;
;	StB2		Configure Byte 2			;
;	StB3		Configure Byte 3			;
;								;
;	Actions:						;
;								;
;	IDLE		No Action				;
;	B1INC		Increment Byte 1 value			;
;	B1DEC		Decrement Byte 1 value			;
;	B1FDR		Set Byte 1 value with fader		;
;	B2INC		Increment Byte 2 value			;
;	B2DEC		Decrement Byte 2 value			;
;	B2FDR		Set Byte 2 value with fader		;
;	B3INC		Increment Byte 3 value			;
;	B3DEC		Decrement Byte 3 value			;
;	B3FDR		Set Byte 3 value with fader		;
;	B1OFF		Inactivate Byte 1			;
;	B2OFF		Inactivate Byte 2			;
;	B3OFF		Inactivate Byte 3			;
;	MSGCLR		Inactivate all bytes and reset display	;
;	MSGSND		Transmit message			;
;	B1DISP		Update display for programming Byte 1	;
;	B2DISP		Update display for programming Byte 2	;
;	B3DISP		Update display for programming Byte 3	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

BYTE1		.DS	1	;value of Byte 1
BYTE2		.DS	1	;value of Byte 2
BYTE3		.DS	1	;value of Byte 3

BYTE1ACTV	.DS	1	;Byte 1 status flag (0=inactive)
BYTE2ACTV	.DS	1	;Byte 2 status flag (0=inactive)
BYTE3ACTV	.DS	1	;Byte 3 status flag (0=inactive)

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StB1		EQU	0
StB2		EQU	1
StB3		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvByte1 	EQU	EV_SW1_ON
EvByte2 	EQU	EV_SW2_ON
EvByte3 	EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvClear 	EQU	EV_SW5_ON
EvSend		EQU	EV_SW6_ON
EvNull		EQU	EV_SW7_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StB1 State 1:StB2 State 2:StB3       Not
;	 Event	  NextSt,Act   NextSt,Act   NextSt,Act	      Used
;	 ---------------------------------------------------------
 STM_ROW EvIdle,  StB1,IDLE,   StB2,IDLE,   StB3,IDLE,	 StB1,IDLE
 STM_ROW EvPlus,  StB1,B1INC,  StB2,B2INC,  StB3,B3INC,  StB1,IDLE
 STM_ROW EvMinus, StB1,B1DEC,  StB2,B2DEC,  StB3,B3DEC,  StB1,IDLE
 STM_ROW EvValue, StB1,B1FDR,  StB2,B2FDR,  StB3,B3FDR,  StB1,IDLE
 STM_ROW EvNull,  StB1,B1OFF,  StB2,B2OFF,  StB3,B3OFF,  StB1,IDLE
 STM_ROW EvClear, StB1,MSGCLR, StB1,MSGCLR, StB1,MSGCLR, StB1,IDLE
 STM_ROW EvSend,  StB1,MSGSND, StB2,MSGSND, StB3,MSGSND, StB1,IDLE
 STM_ROW EvByte1, StB1,IDLE,   StB1,B1DISP, StB1,B1DISP, StB1,IDLE
 STM_ROW EvByte2, StB2,B2DISP, StB2,IDLE,   StB2,B2DISP, StB1,IDLE
 STM_ROW EvByte3, StB3,B3DISP, StB3,B3DISP, StB3,IDLE,	 StB1,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#$00		;default values
	sta	BYTE1		;
	sta	BYTE2		;
	sta	BYTE3		;

	clr	BYTE1ACTV	;clear flags
	clr	BYTE2ACTV	;
	clr	BYTE3ACTV	;

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "1:     Universal"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0 Transmitter"
	jsr	DELAY_1SEC

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S "1:    2:    3:  "

	jsr	B3DISP		;update display
	jsr	B2DISP		;
	jsr	B1DISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment Byte 1 value

B1INC:	lda	#1		;activate byte
	sta	BYTE1ACTV	;
	inc	BYTE1		;increment value
	jsr	B1DISP		;update display
        rts

;--- Decrement Byte 1 value

B1DEC:	lda	#1		;activate byte
	sta	BYTE1ACTV	;
	dec	BYTE1		;decrement value
	jsr	B1DISP		;update display
        rts

;--- Set Byte 1 value with fader

B1FDR:	lda	#1		;activate byte
	sta	BYTE1ACTV	;
	lda	FDR		;fetch fader value
	sta	BYTE1		;save new value
	jsr	B1DISP		;update display
	rts

;--- Increment Byte 2 value

B2INC:	lda	#1		;activate byte
	sta	BYTE2ACTV	;
	inc	BYTE2		;increment value
	jsr	B2DISP		;update display
        rts

;--- Decrement Byte 2 value

B2DEC:	lda	#1		;activate byte
	sta	BYTE2ACTV	;
	dec	BYTE2		;decrement value
	jsr	B2DISP		;update display
	rts

;--- Set Byte 2 value with fader

B2FDR:	lda	#1		;activate byte
	sta	BYTE2ACTV	;
	lda	FDR		;fetch fader value
	sta	BYTE2		;save new value
	jsr	B2DISP		;update display
        rts

;--- Increment Byte 3 value

B3INC:	lda	#1		;activate byte
	sta	BYTE3ACTV	;
	inc	BYTE3		;increment value
	jsr	B3DISP		;update display
	rts

;--- Decrement Byte 3 value

B3DEC:	lda	#1		;activate byte
	sta	BYTE3ACTV	;
	dec	BYTE3		;decrement value
	jsr	B3DISP		;update display
        rts

;--- Set Byte 3 value with fader

B3FDR:	lda	#1		;activate byte
	sta	BYTE3ACTV	;
	lda	FDR		;fetch fader value
	sta	BYTE3		;save new value
	jsr	B3DISP		;update display
	rts

;--- Inactivate Byte 1

B1OFF:	clr	BYTE1ACTV	;reset flag
	jsr	B1DISP		;update display
        rts

;--- Inactivate Byte 2

B2OFF:	clr	BYTE2ACTV	;reset flag
	jsr	B2DISP		;update display
        rts

;--- Inactivate Byte 3

B3OFF:	clr	BYTE3ACTV	;reset flag
	jsr	B3DISP		;update display
        rts

;--- Inactivate all bytes and reset display

MSGCLR: lda	#$00		;clear byte values
	sta	BYTE1		;
	sta	BYTE2		;
	sta	BYTE3		;

	clr	BYTE1ACTV	;reset flags
	clr	BYTE2ACTV	;
	clr	BYTE3ACTV	;

	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Message Reset..."
	jsr	DELAY_1SEC	;

	jsr	B3DISP		;update display
	jsr	B2DISP		;
	jsr	B1DISP		;
        rts

;--- Transmit message

MSGSND: lda	M_FULL_MSG 	;wait if in the middle of
	beq	MSGSND		; receiving a message

	sei			;disable all interrupts
	lda	BYTE1ACTV	;check Byte 1 status
	beq	MSA		;=0 (inactive)? branch...
	lda	BYTE1		;=1 (active)? fetch Byte 1
	jsr	MIDI_PUT	;send it

MSA:	lda	BYTE2ACTV	;check Byte 2 status
	beq	MSB		;=0 (inactive)? branch...
	lda	BYTE2		;=1 (active)? fetch Byte 2
	jsr	MIDI_PUT	;send it

MSB:	lda	BYTE3ACTV	;check Byte 3 status
	beq	MSC		;=0 (inactive)? branch...
	lda	BYTE3		;=1 (active)? fetch Byte 3
	jsr	MIDI_PUT	;send it

MSC:	lda	M_RSTAT		;fetch external running status
	beq	MSD		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status

MSD:	cli			;enable all interrupts
	lda	#3		;notify user by blinking LED
	jsr	LED_ON		;
	jsr	DELAY_100MS	;
	lda	#3		;
	jsr	LED_OFF 	;
	rts

;--- Update display for programming Byte 1

B1DISP: lda	#2		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;

	lda	BYTE1ACTV	;check Byte 1 status
	beq	B1DA		;=0 (inactive)? branch...
	lda	BYTE1		;=1 (active)? fetch value
	jsr	LCD_PUT_H	;display it
	jmp	B1DB		;jump...

B1DA:	LCD_PUT_S "--"          ;display null value

B1DB:	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Program Byte 1  "
        rts

;--- Update display for programming Byte 2

B2DISP: lda	#8		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;

	lda	BYTE2ACTV	;check Byte 2 status
	beq	B2DA		;=0 (inactive)? branch...
	lda	BYTE2		;=1 (active)? fetch value
	jsr	LCD_PUT_H	;display it
	jmp	B2DB		;jump...

B2DA:	LCD_PUT_S "--"          ;display null value

B2DB:	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Program Byte 2  "
        rts

;--- Update display for programming Byte 3

B3DISP: lda	#14		;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;

	lda	BYTE3ACTV	;check Byte 3 status
	beq	B3DA		;=0 (inactive)? branch...
	lda	BYTE3		;=1 (active)? fetch value
	jsr	LCD_PUT_H	;display it
	jmp	B3DB		;jump...

B3DA:	LCD_PUT_S "--"          ;display null value

B3DB:	lda	#0		;notify user
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "Program Byte 3  "
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

