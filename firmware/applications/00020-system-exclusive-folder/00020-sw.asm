;===============================================================;
;								;
;       TOOL19.ASM      Rev 0.4                                 ;
;	System Exclusive Folder 				;
;								;
;	The user can store, review and retransmit MIDI System	;
;	Exclusive Messages.					;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...CAPTURE SYSTEM EXCLUSIVE DATA?			;
;	Press the CAP(ture) key.  The next System Exclusive	;
;       message is captured. The DATA OVERFLOW LED lights       ;
;       if the folder overflows.                                ;
;								;
;								;
;	...REVIEW THE CONTENTS OF THE FOLDER?			;
;	The contents of the folder can be reviewed at any time	;
;	by using the +/- keys and/or VALUE fader to select the	;
;	desired byte.  Data are presented in the LCD.		;
;								;
;								;
;	...RETRANSMIT STORED DATA?				;
;	Press the SEND key.  The contents of the folder are	;
;	transmitted.						;
;								;
;								;
;	...CLEAR THE FOLDER?					;
;	Press the CLEAR key.  The contents of the folder are	;
;	cleared and all parameters are reset.			;
;								;
;								;
;	...MONITOR THE STATUS OF THE FOLDER?			;
;	The DATA PRESENT LED is lit when data is present in	;
;	the folder.  The length of the message in the folder	;
;	is indicated in the LCD.				;
;								;
;								;
;	...SAVE THE CONTENTS OF THE FOLDER?			;
;       Data are saved automatically to non-volatile EEPROM.    ;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When reviewing data,					;
;                                                               ;
;	|Byte:bbb Data:hh|	where bbb=1-256 or "-",         ;
;	|Msg Length: ccc |	hh=00H-FFH or "-", ccc=0-255    ;
;                                                               ;
;                                                               ;
;	When the CAP key is pressed,				;
;                                                               ;
;	|CAPTURING SYSEX |					;
;	|  ...waiting	 |					;
;                                                               ;
;                                                               ;
;	When the SEND key is pressed,				;
;                                                               ;
;	|SENDING...	 |					;
;	|		 |					;
;                                                               ;
;                                                               ;
;	When the CLEAR key is pressed,				;
;                                                               ;
;	|CLEARING...     |                                      ;
;	|		 |   		      			;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE I/O board.  MIDI ports used: IN,OUT,THRU.	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StOp		Normal operation			;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	CAPINI		Initialize capture mode 		;
;	MSGSTO		Store message				;
;	MSGSND		Send message				;
;	MSGCLR		Clear contents of folder		;
;	LENGET		Get length of folder message		;
;	REVINC		Increment message review pointer	;
;	REVDEC		Decrement review pointer		;
;	REVFDR		Set review pointer with fader		;
;	RDISP		Update display for review		;
;	DDISP		Update display with data		;
;	LDISP		Update display with message length	;
;	ADISP		Update display with everything		;
;								;
;===============================================================;


;----------------------------------------------------------------
;       Constants
;----------------------------------------------------------------

DP_LED		EQU	3	;Data Present LED
OF_LED		EQU	7	;Data Overflow LED
SEX_Q_LEN	EQU	80	;sysex queue length
EE_LEN		EQU	100	;address of msg length in EEPROM

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .APPL_RAM
        .ABSOLUTE

SEX_Q		.DS	SEX_Q_LEN ;SYSEX queue

SEX_Q_WRITE     .DS     1      	;next SYSEX queue write address
EE_Q_READ       .DS     1      	;next EEPROM read address
EE_Q_WRITE      .DS     1      	;next EEPROM write address
SEX_Q_ENABLE	.DS	1	;SYSEX queue enable flag
SEX_CAP         .DS     1      	;flags capture mode (TRUE/FALSE)

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp            EQU     0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvCap           EQU     EV_SW1_ON
EvSend          EQU     EV_SW2_ON
EvClear	        EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 1: StOp                            Not
;	 Event	  NextSt,Act				  Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,  StOp,MSGSTO, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvCap,   StOp,CAPINI, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvSend,  StOp,MSGSND, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvClear, StOp,MSGCLR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvPlus,  StOp,REVINC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMinus, StOp,REVDEC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvValue, StOp,REVFDR, StOp,IDLE, StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	SEX_Q_WRITE	;
	sta	EE_Q_READ	;

	sta	SEX_CAP 	;clear flags
	sta	SEX_Q_ENABLE	;

	jsr	LENGET		;fetch msg length from EEPROM

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "19:       Sys Ex"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Folder"
	jsr	DELAY_1SEC

	jsr	ADISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:   lda     DSPINIT
        beq     NODSP

        jsr     ADISP
        lda     #0
        sta     DSPINIT
NODSP:
        rts

;--- Initialize capture mode

CAPINI: lda	#0		;enable SYSEX Q capture
	sta	SEX_Q_WRITE	; and reset queues
	sta	EE_Q_READ       ;
        sta     EE_Q_WRITE      ;
	sta	SEX_Q_ENABLE	;
        lda     #1              ;
        sta     SEX_CAP         ;

	jsr	LCD_CLEAR	;notify user

	LCD_PUT_S "CAPTURING SYSEX "
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "  ...waiting    "

	lda	#OF_LED 	;turn Data Overflow LED off
	jsr	LED_OFF		;
	lda	#DP_LED 	;turn Data Present LED off
	jsr	LED_OFF		;
        rts

;--- Store message

MSGSTO: lda	SEX_Q_WRITE	;any fresh new data for EEPROM?
        cmp     EE_Q_WRITE      ;
	bls	MSNONE		;no? branch...
	ldx	EE_Q_WRITE	;yes? write data in location
	ldx	SEX_Q,X 	; EE_Q_WRITE to EEPROM address
				; EE_Q_WRITE
	cpx	#$F7		;EOX?
	beq	MSEOX		;yes? branch...
	lda	EE_Q_WRITE	;no? write data to EEPROM
        jsr     EE_WRITE        ;

	lda	EE_Q_WRITE	;get EE_Q_WRITE
	inca			;increment
	sta	EE_Q_WRITE	;save new value

	cmp	#1		;first byte?
	bne	MSDLEN		;no? branch...
	jsr	ADISP		;yes? update display
	jmp	MSDLEN		;jump...

MSEOX:	lda	EE_Q_WRITE	;write EOX to EEPROM
        jsr     EE_WRITE        ;

     	ldx	EE_Q_WRITE	;update length field in EEPROM
	incx			;
	stx	EE_Q_WRITE	;
     	lda	#EE_LEN		;store in address 255
     	jsr	EE_WRITE	;

        jsr     ADISP

MSDLEN: jsr	LDISP		;update display
	lda	#DP_LED 	;turn Data Present LED on
	jsr 	LED_ON		;
MSNONE: rts

;--- Send message

MSGSND: jsr	LCD_CLEAR	;notify user
	LCD_PUT_S " SENDING..." ;

	lda	#0		;transmit message
MS4:    sta     EE_Q_READ       ;
	jsr	EE_READ		;fetch next byte
        jsr     MIDI_PUT        ;transmit it
        lda     EE_Q_READ       ;bump index
        inca                    ;
        cmp     EE_Q_WRITE      ;
        bls     MS4             ;close transmit loop

	lda	#0		;reset read pointer
	sta	EE_Q_READ	;

	jsr	DELAY_100MS	;pause for user to read display
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;

	jsr	ADISP		;update display
        rts

;--- Clear contents of folder

MSGCLR: lda	#0		;clear all variables
        sta     SEX_Q_WRITE     ;
        sta     EE_Q_READ       ;
        sta     EE_Q_WRITE      ;

	sta	SEX_CAP 	;clear flags
	sta	SEX_Q_ENABLE	;

   	ldx	EE_Q_WRITE	;update length field in EEPROM
   	lda	#EE_LEN		;
   	jsr	EE_WRITE	;

	lda	#OF_LED 	;turn Data Overflow LED off
	jsr	LED_OFF		;
	lda	#DP_LED 	;turn Data Present LED off
	jsr	LED_OFF		;

	jsr	LCD_CLEAR	;notify user
	LCD_PUT_S "CLEARING..." ;

	jsr	DELAY_100MS	;pause for user to read display
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;
        jsr     DELAY_100MS     ;

	jsr	ADISP		;update display
        rts

;--- Get length of folder message

LENGET: lda	#EE_LEN 	;fetch message length
	jsr	EE_READ		;
	sta	EE_Q_WRITE	;save value
        rts

;--- Increment message review pointer

REVINC: lda	EE_Q_READ	;fetch value
	inca			;increment
	cmp	EE_Q_WRITE	;compare
	bhs	RINO		;> or =EE_Q_WRITE? branch...
	sta	EE_Q_READ	;<EE_Q_WRITE? save new value
	jsr	RDISP		;update display
	jsr	DDISP		;
RINO:   rts

;--- Decrement review pointer

REVDEC: lda	EE_Q_READ	;fetch value
	cmp	#0		;compare to 0
	beq	RDNO		;=0? branch...
	deca			;nonzero? decrement
	sta	EE_Q_READ	;save new value
	jsr	RDISP		;update display
	jsr	DDISP		;
RDNO:   rts

;--- Set review pointer with fader

REVFDR: lda	FDR		;fetch fader position
	lsra			;valid range: 0-127
        cmp     EE_Q_WRITE      ;if fader is inside of
	bhs	RFNO		; EE queue, point with it
	sta	EE_Q_READ	;save new value
	jsr	RDISP		;update display
	jsr	DDISP		;
RFNO:   rts


;--- Update display for review

RDISP:	lda	SEX_Q_ENABLE	;don't update display if
	cmp	#1		; SYSEX queue is enabled
        beq     DRDUN           ;

	lda	#7		;position cursor
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;

	lda	EE_Q_WRITE	;make sure queue isn't empty
	cmp	#0		;
	bne	OKRDSP		;

	LCD_PUT_S "-"		;this means "empty"
	jmp	DRDUN		;jump...

OKRDSP: lda	EE_Q_READ	;fetch queue read pointer
	inca			;increment to display as 1-256
	jsr	LCD_PUT_RJ3_I	;display it
DRDUN:	rts

;--- Update display with data

DDISP:	lda	SEX_Q_ENABLE	;don't update display if
	cmp	#1		; SYSEX queue is enabled
        beq     DDDUN           ;

	lda	#14		;position cursor
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;

	lda	EE_Q_WRITE	;make sure queue isn't empty
	cmp	#0		;
	bne	OKDDSP		;

	LCD_PUT_S "-"		;this means "empty"
	jmp	DDDUN		;jump...

OKDDSP: lda	EE_Q_READ	;fetch queue read pointer
	jsr	EE_READ 	;fetch data value
	jsr	LCD_PUT_H	;display it
DDDUN:	rts

;--- Update display with message length

LDISP:	lda	SEX_Q_ENABLE	;don't update display if
	cmp	#1		; SYSEX queue is enabled
        beq     DLDUN           ;

	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	EE_Q_WRITE	;fetch value
	jsr	LCD_PUT_RJ3_I	;display it
DLDUN:	rts

;--- Update display with everything

ADISP:	lda	SEX_Q_ENABLE	;don't update display if
	cmp	#1		; SYSEX queue is enabled
        beq     DADUN           ;

	jsr	LCD_CLEAR	;display static labels

	LCD_PUT_S "Byte:    Data:"
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Msg Length:"

	jsr	RDISP		;update display
	jsr	DDISP		;
	jsr	LDISP		;
DADUN:	rts

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

;--- Process Status Bytes (SYSEX and EOX)

SCI_RX_CBCK_S:
	lda	SEX_Q_WRITE	;is the queue full?
	inca			;
        cmp     #SEX_Q_LEN      ;
	bhs	RX_OL		;yes? branch...
	txa			;no? transfer data to acca

RXST:	ldx	SEX_CAP 	;is capture mode enable?
	beq	RX_DUN		;=0 (no)? branch...
RX3:	cmp	#$F0		;=1 (yes)? is message a SYSEX?
	beq	RXSEX		;yes? branch...
	sta	SEX_Q_ENABLE	;no? disable queue

	cmp	#$F7		;is message an EOX?
	bne	RX_DUN		;no? branch...
RXEOX:	ldx	#0		;yes? disable capture mode
	stx	SEX_CAP 	; (clear flag)
	jmp	RXNQ		;jump...

RXSEX:	ldx	#1		;enable queue
	stx	SEX_Q_ENABLE	; (set flag)
	jmp	RXNQ		;jump...

;--- Process 1st Data Bytes (System Exclusive data)

SCI_RX_CBCK_D1:
	lda	SEX_Q_WRITE	;is the queue full?
	inca			;
        cmp     #SEX_Q_LEN      ;
	bhs	RX_OL		;yes? branch...
	txa			;no? transfer data to acca

	ldx	SEX_Q_ENABLE	;is SYSEX queue enabled?
	beq	RX_DUN		;=0 (no)? branch...
RXNQ:	ldx	SEX_Q_WRITE	;=1 (yes)? enqueue data
	sta	SEX_Q,X 	;
	incx			;
	stx	SEX_Q_WRITE	;
RX_DUN: rti			;return, do not buffer

RX_OL:	ldx	#0		;reinitialize variables
        stx     SEX_Q_WRITE     ;
        stx     EE_Q_READ       ;
        stx     EE_Q_WRITE      ;
	sta	SEX_CAP 	;clear flags
	sta	SEX_Q_ENABLE	;
	lda	#OF_LED 	;turn Data Overflow LED on
        jsr     LED_ON          ;
	lda	#DP_LED 	;turn Data Present LED off
        jsr     LED_OFF         ;

	rti			;return, do not buffer

;--- Process 2nd Data Bytes (can not be System Exclusive data)

SCI_RX_CBCK_D2:
        jmp     SCI_RX_CBCK_D2_RET  ;return, do not buffer
