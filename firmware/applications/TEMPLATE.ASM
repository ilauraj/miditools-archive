;===============================================================;
;								;
;       TEMPLATE.ASM    Rev 1.0                                 ;
;	Generic Template for new MIDItools Application  	;
;								;
;	This Applicaiton does nothing - it's just a template.	;
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

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StIdle  	EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvSW1   	EQU	EV_SW1_ON
EvSW2   	EQU	EV_SW2_ON
EvSW3   	EQU	EV_SW3_ON
EvSW4 		EQU	EV_SW4_ON
EvSW5   	EQU	EV_SW5_ON
EvSW6 		EQU	EV_SW6_ON
EvSW7 		EQU	EV_SW7_ON
EvSW8   	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMIDI		EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StIdle State 1:     State 2:     State 3:
;	 Event	  NextSt,Act     NextSt,Act   NextSt,Act   NextSt,Act
;	 -------------------------------------------------------------
 STM_ROW EvIdle,  StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW1,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW2,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW3,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW4,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW5,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW6,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW7,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvSW8,   StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
 STM_ROW EvValue, StIdle,IDLE,   StIdle,IDLE, StIdle,IDLE, StIdle,IDLE
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

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "Generic Template"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0   Bob Moses"
	jsr	DELAY_1SEC
	jsr	LCD_CLEAR

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts


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

