;===============================================================;
;								;
;       TOOL04.ASM      Rev 1.0                                 ;
;	Custom Instrument       				;
;								;
;	The user can integrate up to 64 switches to create a	;
;	custom MIDI keyboard controller.			;
;								;
;===============================================================;
;										;
;	Operation:								;
;										;
;	HOW DO I...								;
;										;
;	...SET THE TRANSMIT CHANNEL?					;
;	Press the SETUP CHAN key.  The MIDI transmit channel	;
;	is set with the +/- keys and/or the VALUE fader.	;
;										;
;										;
;	...SET THE NOTE NUMBER OFFSET?				;
;	Press the SETUP OFSET key.  The note number offset for;
;	all note messages is selected using the +/- keys	;
;	and/or VALUE the fader. 					;
;										;
;										;
;	...SET THE VELOCITY FOR ALL NOTES?				;
;	Press the SETUP VEL key.  The velocity for all Note On;
;	messages is set with the +/- keys and/or the VALUE	;
;	fader.								;
;										;
;---------------------------------------------------------------;
;										;
;	LCD Screens:							;
;										;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.			;
;										;
;	| CH  OFFSET  VEL|	where nn=1-16, bbb=0-127,	;
;	| nn   ssss   bbb|	ssss=-128 to 127			;
;                                                               ;
;---------------------------------------------------------------;
;										;
;	Hardware:								;
;										;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the EXTERNAL KEYS board.  MIDI	;
;	OUT only.								;
;										;
;---------------------------------------------------------------;
;										;
;	States: 								;
;										;
;	StCh		Set transmit channel				;
;     StOff       Set offset                              	;
;     StVel       Set velocity                            	;
;                                                           ;
;	Actions:								;
;										;
;	IDLE		No action						;
;	CHINC		Increment channel					;
;	CHDEC		Decrement channel					;
;	CHFDR		Set channel with fader				;
;     OFFINC      Increment offset                        	;
;     OFFDEC      Decrement offset                        	;
;     OFFFDR      Set offset with fader                   	;
;     VELINC      Increment velocty                       	;
;	VELDEC	Decrement velocity         			;
;	VELFDR	Set velocity with fader         		;
;	SCAN    	Scan key matrix and transmit notes  	;
;	CDISP		Update display for changing channel		;
;	ODISP		Update display for changing offset		;
;	VDISP		Update display for changing velocity	;
;										;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel
VEL		.DS	1	;note velocity
OFFSET	.DS	1	;note number offset
KEYS        .DS   8     ;image of key matrix
COL		.DS	1	;current column being read
NOTENUM 	.DS	1	;passes note #s to subroutines
NOTEVEL     .DS   1     ;passes velocity to subroutines
TEMP		.DS	1	;Temporary variable
KEYCHG	.DS	1	;Temporary image of A register
OLDCOL	.DS	1	;Temporary image of X register

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StOff       EQU   1
StVel       EQU   2

;--- Map application events to BIOS events

EvIdle	EQU	EV_IDLE
EvChan	EQU	EV_SW1_ON
EvOff       EQU   EV_SW2_ON
EvVel       EQU   EV_SW3_ON
EvPlus      EQU   EV_SW4_ON
EvMinus 	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StCh State 1:StOff State 2:StVel       Not
;	 Event	  NextSt,Act   NextSt,Act    NextSt,Act 	Used
;	 -----------------------------------------------------------
 STM_ROW EvIdle,  StCh,SCAN,   StOff,SCAN,   StVel,SCAN,   StCh,IDLE
 STM_ROW EvPlus,  StCh,CHINC,  StOff,OFFINC, StVel,VELINC, StCh,IDLE
 STM_ROW EvMinus, StCh,CHDEC,  StOff,OFFDEC, StVel,VELDEC, StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,  StOff,OFFFDR, StVel,VELFDR, StCh,IDLE
 STM_ROW EvChan,  StCh,SCAN,   StCh,CDISP,   StCh,CDISP,   StCh,IDLE
 STM_ROW EvOff,   StOff,ODISP, StOff,SCAN,   StOff,ODISP,  StCh,IDLE
 STM_ROW EvVel,   StVel,VDISP, StVel,VDISP,  StVel,SCAN,   StCh,IDLE

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

	lda	#$00			;default values
	sta	CHAN			;
	sta	COL 			;
      sta   OFFSET            ;

      lda     #64             ;
      sta     VEL             ;

	X0_LO				;default latch strobe for
					; expansion board

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "4:        Custom"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0  Instrument"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

        LCD_PUT_S " CH  OFFSET  VEL"

	jsr	ODISP		;update display
	jsr	VDISP		;
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
	deca			;decrement
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

;--- Increment offset

OFFINC: lda	OFFSET		;fetch offset
	inca			;increment
      sta     OFFSET          ;store new value
	jsr	ODISP		;update display
	rts

;--- Decrement offset

OFFDEC: lda	OFFSET		;fetch offset
	deca			;decrement
      sta     OFFSET          ;store new value
	jsr	ODISP		;update display
	rts

;--- Set offset with fader

OFFFDR: lda     FDR             ;fetch fader value
	cmp	#$80		;compare to 128
	bhs	OFA		;> or =128? branch...
	add	#$80		;<128? translate (0-127) to
	jmp	OFB		; (-128 to -1)

OFA:	sub	#$80		;translate (128-255) to
				; (0 to 127)
OFB:	sta	OFFSET		;store new value
	jsr	ODISP		;update display
	rts

;--- Increment velocity

VELINC: lda	VEL		;fetch velocity
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	VEL		;store new value
	jsr	VDISP		;update display
	rts

;--- Decrement velocity

VELDEC: lda	VEL		;fetch velocity
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	VEL		;store new value
	jsr	VDISP		;update display
	rts

;--- Set velocity with fader

VELFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	VEL		;store new value
	jsr	VDISP		;update display
	rts

;--- Scan key matrix and transmit notes

SCAN:	lda	COL		;fetch column pointer
	inca			;increment
	and	#$07		;constrain to 0-7
	sta	COL		;save new value
	tax			;transfer column pointer to x

	lda	COLMASK,X	;select this column
	jsr	SPI_IO 	;
	X0_HI             ;latch data
	X0_LO             ;

      RD_DATA           ;load rows
      sta     TEMP      ;buffer this temporarily

	lda	#$FF		;turn off this column
	jsr	SPI_IO 	;
	X0_HI             ;latch data
	X0_LO			;

	ldx	COL		;any changes?
	lda	TEMP		;
	eor	KEYS,X	;
      cmp   #$00        ;
	FAR_BEQ SDUN	;no? branch...
	sta	KEYCHG	;yes? changes-->KEYCHG

	lda	KEYS,X	;old column status-->OLDCOL
      sta   OLDCOL      ;

	lda	TEMP		;fetch new column data
      sta   KEYS,X      ;update history

        ;--- bit 7

S7:	tst	KEYCHG		;has this key changed?
	bpl	S6		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
        lsla                    ;
        lsla                    ;
        add     #7              ;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S7ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	jmp	S7TX		;jump...

S7ON:   lda     VEL             ;note on velocity

S7TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 6

S6:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S5		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#6		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S6ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S6TX		;jump...

S6ON:	lda	VEL		;note on velocity

S6TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 5

S5:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S4		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#5		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S5ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S5TX		;jump...

S5ON:	lda	VEL		;note on velocity

S5TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 4

S4:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S3		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#4		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S4ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S4TX		;jump...

S4ON:	lda	VEL		;note on velocity

S4TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 3

S3:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S2		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#3		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S3ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S3TX		;jump...

S3ON:	lda	VEL		;note on velocity

S3TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 2

S2:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S1		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#2		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S2ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S2TX		;jump...

S2ON:	lda	VEL		;note on velocity

S2TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 1

S1:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S0		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#1		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S1ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S1TX		;jump...

S1ON:	lda	VEL		;note on velocity

S1TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message

        ;--- bit 0

S0:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	SDUN		;no? branch...

	lda	COL		;yes? compute note number
	lsla			; =(8*COL+bit#)
	lsla			;
	lsla			;
	add	#0		;
	sta	NOTENUM 	;save note number

	tst	OLDCOL		;was old status off?
	bmi	S0ON		;yes? key is now on! branch...
	lda	#0		;no? note off velocity = 0
	bra	S0TX		;jump...

S0ON:	lda	VEL		;note on velocity

S0TX:	sta	NOTEVEL 	;save note velocity
	jsr	NOTEON		;send Note On message
SDUN:	rts

COLMASK: .DB $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

;--- Transmit Note On message

NOTEON: lda	NOTENUM 	;fetch note number
        add     OFFSET          ;add offset
	cmp	#127		;valid range: 0-127
	bhi	NOA		;>127? branch...

	sei			;< or =127? disable interrupts
	lda	#$90		;load Note On status nibble
	add	CHAN		;add channel
	jsr	MIDI_PUT	;send it

	lda	NOTENUM 	;load note number
        add     OFFSET          ;add offset
	jsr	MIDI_PUT	;send it

	lda	NOTEVEL 	;load velocity
	jsr	MIDI_PUT	;send it
	cli			;enable all interupts
NOA:	rts

;--- Update display for changing channel

CDISP:	lda	#4		;clear OFFSET arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;clear VEL arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	#2		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
        rts

;--- Update display for changing offset

ODISP:	lda	#0		;clear CH arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;clear VEL arrow
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;place OFFSET arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

        lda     #9              ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OFFSET		;fetch offset
	jsr	LCD_PUT_RJ3_SI	;display it (signed)
	rts

;--- Update display for changing velocity

VDISP:	lda	#0		;clear CH arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;clear OFFSET arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;place VEL arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

        lda     #15             ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	VEL		;fetch velocity
	jsr	LCD_PUT_RJ3_I	;display it
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
        jmp     SCI_RX_CBCK_S_RET

SCI_RX_CBCK_D1:
        jmp     SCI_RX_CBCK_D1_RET

SCI_RX_CBCK_D2:
        jmp     SCI_RX_CBCK_D2_RET


