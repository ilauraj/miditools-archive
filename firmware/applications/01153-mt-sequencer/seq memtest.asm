;===============================================================;
;								;
;       SEQTEST.ASM    Rev 1.0                                  ;
;	Test program for sequencer memory board             	;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...NOTHING                      			;
;	Well, that's what this does.                            ;
;							        ;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;		  111111					;
;	0123456789012345					;
;      ------------------					;
;      |ADDR Rd Wr	|					;
;      |aaaa rr ww	|					;
;      ------------------					;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StIdle  	                        		;
;								;
;	Actions:						;
;								;
;	IDLE		No Action				;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

TEMP 		.DS	1	;temp variable
ADDRHI 		.DS	1	;
ADDRLO 		.DS	1	;
DOUT 		.DS	1	;

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StIdle  	EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvRDRAM    	EQU	EV_SW1_ON
EvRDROM   	EQU	EV_SW2_ON
EvSW3   	EQU	EV_SW3_ON
EvUP 		EQU	EV_SW4_ON
EvWRRAM    	EQU	EV_SW5_ON
EvSW6 		EQU	EV_SW6_ON
EvSW7 		EQU	EV_SW7_ON
EvDN    	EQU	EV_SW8_ON
EvValue  	EQU	EV_FDR_MOVE
EvMIDI		EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StIdle State 1:     State 2:     State 3:
;	 Event	  NextSt,Act     NextSt,Act   NextSt,Act   NextSt,Act
;	 -------------------------------------------------------------
 STM_ROW EvIdle,  StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvUP,    StIdle,INCADDR,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvDN,    StIdle,DECADDR,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvRDRAM, StIdle,RDRAM,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvWRRAM, StIdle,WRRAM,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvRDROM, StIdle,RDROM,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW3,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW6,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW7,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvValue, StIdle,SETDATA,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvMIDI,  StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE

        STM_END


;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#$00		;default values
	sta	TEMP		;
	sta	ADDRLO
	sta	ADDRHI
	sta	DOUT

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "Sequencer Memory"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "  Board Tester"
	jsr	DELAY_1SEC
	jsr	LCD_CLEAR
	
	LCD_PUT_S "Addr Rd Wr"
	jsr	DSP_ADDR
	jsr	DSP_DATA

	jsr	MEMPCB_INIT
	

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;---------------------------------
MEMPCB_INIT:

	X0_LO			;idle address latch clock port
	X1_HI			;disable RAM WE
	bset	6,PORTA		;diasble RAM/ROM OE

	rts

;---------------------------------
INCADDR:
	lda	ADDRLO		;bump low byte
	inca			;
	sta	ADDRLO		;
	bne	IA0		;if not equal 0, we haven't wrapped low byte, done

	; -- bump high byte

	lda	ADDRHI		;bump low byte
	inca			;
	sta	ADDRHI		;

IA0:	jsr	DSP_ADDR
	rts

;---------------------------------
DECADDR:
	; -- if low byte = 0, set to $FF and dec hi byte.
	; -- otherwise, just dec low byte

	lda	ADDRLO		;check low byte
	beq	DA0		;=0, branch

	lda	ADDRLO		;
	deca			;
	sta	ADDRLO		;
	jsr	DSP_ADDR
	rts
DA0:
	lda	#$FF
	sta	ADDRLO
	lda	ADDRHI		;bump low byte
	deca			;
	sta	ADDRHI		;
	jsr	DSP_ADDR
	rts

;---------------------------------
RDROM:
	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and ROM CS
	lda	ADDRHI
	and	#$3F
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute read
	clr	DDRB		;set up port B for all inputs
	bclr	6,PORTA
	lda	PORTB
	bset	6,PORTA

	; -- return with data in ACCU
	;!!! rts

	; for now, display it
	jsr	DSP_RDDATA
	rts
	
;---------------------------------
RDRAM:
	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and RAM CS
	lda	ADDRHI
	ora	#$C0
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute read
	clr	DDRB		;set up port B for all inputs
	bclr	6,PORTA
	lda	PORTB
	bset	6,PORTA

	; -- return with data in ACCU

	;!!! rts

	; for now, display it

	jsr	DSP_RDDATA
	rts
	
;---------------------------------
WRRAM:
	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and ROM CS
	lda	ADDRHI
	ora	#$C0
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute write

	lda	DOUT
	sta	PORTB
	X1_LO
	X1_HI
	
	rts
	
;---------------------------------
SETDATA:
	lda	FDR
	sta	DOUT
	jsr	DSP_DATA
	rts

;---------------------------------
DSP_ADDR:
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	
	lda	ADDRHI
	jsr	LCD_PUT_H
	lda	ADDRLO
	jsr	LCD_PUT_H

	rts

;---------------------------------
DSP_RDDATA:
	
	; -- enter with data value in ACCU

	sta	TEMP

	lda	#5
	ldx	#1
	jsr	LCD_GOTOXY
	
	lda	TEMP
	jsr	LCD_PUT_H
	
	rts

;---------------------------------
DSP_DATA:

	lda	#8
	ldx	#1
	jsr	LCD_GOTOXY
	
	lda	DOUT
	jsr	LCD_PUT_H
	
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

