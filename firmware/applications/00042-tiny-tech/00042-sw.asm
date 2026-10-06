;===============================================================;
;								;
;       TEST.ASM      Rev 1.0                                   ;
;	MIDItools Test Program  				;
;								;
;	This program performs diagnostic tests on the various	;
;	pieces of the MIDItools computer.     		        ;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI Ports used: IN,OUT.      	;
;								;
;---------------------------------------------------------------;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

TEMP 	.DS	1
SWSTAT  .DS     1
LEDSTAT	.DS	1
MIDIOUT	.DS	1
MIDIIN	.DS	1
LPBKCNT .DS     1
MIDIERR	.DS	1
EECNT	.DS	1
EEERR	.DS	1

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StSw		EQU	0
StADC		EQU	1
StMIDI		EQU	2
StEE    	EQU	3

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvNext		EQU	EV_SW1_ON
EvSw2On		EQU	EV_SW2_ON
EvSw3On		EQU	EV_SW3_ON
EvSw4On		EQU	EV_SW4_ON
EvSw5On		EQU	EV_SW5_ON
EvSw6On		EQU	EV_SW6_ON
EvSw7On		EQU	EV_SW7_ON
EvSw8On		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StSw  State 1:StADC   State 2:StMIDI State 3:StEE
;	 Event	  NextSt,Act	NextSt,Act      NextSt,Act     NextSt,Act
;	 ----------------------------------------------------------------
 STM_ROW EvIdle,  StSw,SWUPD8,  StADC,ADCUPD8,  StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvValue, StSw,IDLE,	StADC,LEDCHG,   StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvNext,  StADC,ENTADC,	StMIDI,ENTMIDI, StEE,ENTEE,   StSw,ENTSW
 STM_ROW EvSw2On, StSw,SW2ON,	StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw3On, StSw,SW3ON,   StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw4On, StSw,SW4ON,	StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw5On, StSw,SW5ON,   StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw6On, StSw,SW6ON,   StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw7On, StSw,SW7ON,   StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE
 STM_ROW EvSw8On, StSw,SW8ON,   StADC,IDLE,     StMIDI,IDLE,  StEE,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0
	sta	SWSTAT
	sta	LEDSTAT

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

	lda	#$FF		;buffer all messages
	sta	M_RX_Q_XPT	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "    Hardware    "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "  Diagnostics   "
	jsr	DELAY_1SEC
	jsr	DELAY_1SEC

	jsr	ENTSW

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- test switches

ENTSW:
	jsr	LCD_CLEAR
	LCD_PUT_S "Switches "

	lda	#'*'
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C

	lda	#9
	ldx	#1
	jsr	LCD_GOTOXY
	lda	#$DB
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C
	lda	#' '
	jsr	LCD_PUT_C
	lda	#$DB
	jsr	LCD_PUT_C

	lda	#0
	sta	SWSTAT

	jsr	SWUPD8

	rts

SWUPD8:
	lda	#3
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "$"

	jsr	SW_READ
	jsr	LCD_PUT_H

	rts

SW2ON:
	lda	#$02
	eor	SWSTAT
	sta	SWSTAT
	brclr	1,SWSTAT,SW2OFF

	lda	#11
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW2OFF:
	lda	#11
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW3ON:
	lda	#$04
	eor	SWSTAT
	sta	SWSTAT
	brclr	2,SWSTAT,SW3OFF

	lda	#13
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW3OFF:
	lda	#13
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW4ON:
	lda	#$08
	eor	SWSTAT
	sta	SWSTAT
	brclr	3,SWSTAT,SW4OFF

	lda	#15
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW4OFF:
	lda	#15
	ldx	#0
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW5ON:
	lda	#$10
	eor	SWSTAT
	sta	SWSTAT
	brclr	4,SWSTAT,SW5OFF

	lda	#9
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW5OFF:
	lda	#9
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW6ON:
	lda	#$20
	eor	SWSTAT
	sta	SWSTAT
	brclr	5,SWSTAT,SW6OFF

	lda	#11
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW6OFF:
	lda	#11
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW7ON:
	lda	#$40
	eor	SWSTAT
	sta	SWSTAT
	brclr	6,SWSTAT,SW7OFF

	lda	#13
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW7OFF:
	lda	#13
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

SW8ON:
	lda	#$80
	eor	SWSTAT
	sta	SWSTAT
	brclr	7,SWSTAT,SW8OFF

	lda	#15
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$FF
	jsr	LCD_PUT_C

	rts

SW8OFF:
	lda	#15
	ldx	#1
	jsr	LCD_GOTOXY

	lda	#$DB
	jsr	LCD_PUT_C

	rts

;--- test ADC & LEDs

ENTADC:
	jsr	LCD_CLEAR
	LCD_PUT_S "--- ADC ---  LED"

	jsr	ADCUPD8
	jsr	LEDCHG

	rts

ADCUPD8:
	jsr	ADC_READ

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	lda	ADC0
	jsr	LCD_PUT_H

	lda	#3
	ldx	#1
	jsr	LCD_GOTOXY
	lda	ADC1
	jsr	LCD_PUT_H

	lda	#6
	ldx	#1
	jsr	LCD_GOTOXY
	lda	ADC2
	jsr	LCD_PUT_H

	lda	#9
	ldx	#1
	jsr	LCD_GOTOXY
	lda	ADC3
	jsr	LCD_PUT_H

	rts

LEDCHG:
	jsr	LED_CLEAR

	lda	ADC0
	lsra
	lsra
	lsra
	lsra
	sta	LEDSTAT

	jsr	LED_ON

	lda	#15
	ldx	#1
	jsr	LCD_GOTOXY

	lda	LEDSTAT
	jsr	LCD_PUT_RJ2_I

	rts

;--- test MIDI

LPBKDATA: .DB $00,$01,$02,$04,$08,$10,$20,$40,$80

ENTMIDI:
	jsr	LCD_CLEAR
	LCD_PUT_S "MIDI"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Testing Loopback"

	jsr	DELAY_1SEC	;let the user see what's happening

	lda	#0		;reset error counter
	sta	MIDIERR         ;

	lda	#8		;# of bytes to send during loopback
	sta	LPBKCNT		;

TRYLPBK:

	lda	#$FF		;reset MIDIIN
	sta	MIDIIN		;

	ldx	LPBKCNT		;look up next byte to send
	lda	LPBKDATA,X	;

	sta	MIDIOUT         ;save to compare to what comes back
	jsr	MIDI_PUT        ;send data byte

	jsr	DELAY_10MS	;wait for data to come back

	lda	MIDIIN		;see what came back
	cmp	#$FF		;did anything come back?
	bne	LPBKOK		;yup
	jmp	LPBKERR         ;nope

LPBKOK:
	cmp	MIDIOUT         ;if MIDI IN not equal MIDI OUT,
	bne	LPBKDERR        ; go yell at user...

	;if we get here, successful loopback

	jmp	LPBKNEXT

LPBKDERR:
	lda	MIDIERR        	;bump error counter
	inca                    ;
	sta	MIDIERR         ;

	jsr	LCD_CLEAR
	LCD_PUT_S "Loopback Failure"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "!!!!!!!!!!!!!!!!"

	jsr	DELAY_1SEC

	jsr	LCD_CLEAR
	LCD_PUT_S " Data Mismatch  "
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S " Out:    In:    "
	lda	#5
	ldx	#1
	jsr	LCD_GOTOXY
	lda	MIDIOUT
	jsr	LCD_PUT_H
	lda	#12
	ldx	#1
	jsr	LCD_GOTOXY
	lda	MIDIIN
	jsr	LCD_PUT_H

	jsr	DELAY_1SEC

	jsr	LCD_CLEAR
	LCD_PUT_S "MIDI"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Testing Loopback"

	jmp     LPBKNEXT

LPBKERR:
	lda	MIDIERR        	;bump error counter
	inca                    ;
	sta	MIDIERR         ;

	jsr	LCD_CLEAR
	LCD_PUT_S "Loopback Failure"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "!!!!!!!!!!!!!!!!"

	jsr	DELAY_1SEC

	jsr	LCD_CLEAR
	LCD_PUT_S " Please Connect "
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "  MIDI In->Out  "

	jsr	DELAY_1SEC

	jsr	LCD_CLEAR
	LCD_PUT_S "MIDI"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Testing Loopback"

LPBKNEXT:

	lda	LPBKCNT		;bump timeout counter,
	deca			; try again if not done
	sta	LPBKCNT		;
	beq	LPBKDUN 	;
	jmp	TRYLPBK         ;

	;done
LPBKDUN:
	jsr	LCD_CLEAR
	LCD_PUT_S " Test Complete  "
	lda	#1
	ldx	#1
	jsr	LCD_GOTOXY

	lda	MIDIERR        	;fetch error counter
	jsr	LCD_PUT_I	;display it

	LCD_PUT_S " MIDI Errors"

	rts

;--- test EEPROM

ENTEE:
	jsr	LCD_CLEAR
	LCD_PUT_S "EEPROM"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Testing...      "

	lda	#0		;reset error count
	sta	EEERR		;

	;write data into EEPROM

	lda	#0		;initialize EEPROM address count
	sta	EECNT		;

EEWLP:
	lda	EECNT           ;write address (EECNT) with !EECNT
	ldx	EECNT           ;
	comx                    ;
	jsr	EE_WRITE        ;

	lda	EECNT		;bump count
	inca			;
	sta	EECNT		;
	bne	EEWLP		;go until we wrap back to 0

	;read data from EEPROM

	lda	#0		;initialize EEPROM address count
	sta	EECNT		;

EERLP:
	lda	EECNT           ;read address (EECNT)
	jsr	EE_READ         ;

	coma			;data should be complement of EECNT
	cmp	EECNT		;
	beq	EEROK		;

	;if we get here, data error

	sta	TEMP
	lda	EEERR		;bump error counter
	inca			;
	sta	EEERR		;

	jsr	LCD_CLEAR	;
	LCD_PUT_S "EEPROM Error!"
	lda	#0		;
	ldx	#1		;
	jsr	LCD_GOTOXY
	LCD_PUT_S "A:   WR:   RD:  "
	lda	#2		;
	ldx	#1		;
	jsr	LCD_GOTOXY
	lda	EECNT
	jsr	LCD_PUT_H
	lda	#8		;
	ldx	#1		;
	jsr	LCD_GOTOXY
	lda	EECNT
	coma
	jsr	LCD_PUT_H
	lda	#14		;
	ldx	#1		;
	jsr	LCD_GOTOXY
	lda	TEMP
	jsr	LCD_PUT_H

	jsr	DELAY_100MS

EEROK:
	lda	EECNT		;bump count
	inca			;
	sta	EECNT		;
	beq	EEDUN		;
	jmp	EERLP		;

EEDUN:
	jsr	LCD_CLEAR
	LCD_PUT_S " Test Complete  "
	lda	#1
	ldx	#1
	jsr	LCD_GOTOXY

	lda	EEERR        	;fetch error counter
	jsr	LCD_PUT_I	;display it

	LCD_PUT_S " EEPROM Errs"

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

	lda	SCDAT		;fetch data
	sta	MIDIIN		;
        rti

SCI_RX_CBCK_S:
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D1:
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D2:
        MIDI_ISR_LOOPBACK

