;----------------------------------------
;	Constants
;----------------------------------------

;-----------------------------------------
;	Variables
;-----------------------------------------

        .APPL_RAM
        .ABSOLUTE

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

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S "Sequencer Tester"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "   8/12/97  v.1 "

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- Idle action

IDLE:	rts

;--- Send Message #1 (PLAYrom = F0 00 01 1A 01 00 F7)

SEND1:	sei			;disable interrupts
	lda	#$F0		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$1A		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$F7		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #2 (PLAYram = F0 00 01 1A 01 01 F7)

SEND2:	sei			;disable interrupts
	lda	#$F0		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$1A		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$F7		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #3 (RECram = F0 00 01 1A 01 02 F7)

SEND3:	sei			;disable interrupts
	lda	#$F0		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$1A		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$02		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$F7		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #4 (MstrPLAY = F0 00 01 1A 01 03 F7)

SEND4:	sei			;disable interrupts
	lda	#$F0		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$1A		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$03		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$F7		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #5 (MstrSTOP = F0 00 01 1A 01 04 F7)

SEND5:	sei			;disable interrupts
	lda	#$F0		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$00		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$1A		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$01		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$04		;set value
	jsr	MIDI_PUT	;send byte
	lda	#$F7		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #6 (RltmSTART = FA)

SEND6:	sei			;disable interrupts
	lda	#$FA		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #7 (RltmCONT = FB)

SEND7:	sei			;disable interrupts
	lda	#$FB		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

;--- Send Message #8 (RltmSTOP = FC)

SEND8:	sei			;disable interrupts
	lda	#$FC		;set value
	jsr	MIDI_PUT	;send byte
	cli			;enable interrupts
	rts			;

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
	jmp	SCI_RX_CBCK_S_RET

SCI_RX_CBCK_D1:
	jmp	SCI_RX_CBCK_D1_RET

SCI_RX_CBCK_D2:
	jmp	SCI_RX_CBCK_D2_RET