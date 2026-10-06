;===============================================================;
;								;
;       TOOL14.ASM      Rev 0.4                                 ;
;	Keyboard Mapper 					;
;								;
;	The user can map note messages to one, two or three	;
;	channels, as determined by note number or velocity.	;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET ZONE BOUNDARIES? 				;
;	Zone boundaries are selected by pressing the ZONE	;
;	BOUNDARIES keys: Z1-E(nd), Z2-B(eginning), Z2-E 	;
;	or Z3-B.  Boundary values are then set with the +/-	;
;	keys and/or VALUE fader.				;
;								;
;	Zone boundaries are constrained to 0-127.  They are	;
;	defined as follows:					;
;								;
;		ZONE	BEGINNING	END			;
;		 1	    0		Z1-E			;
;		 2	   Z2-B 	Z2-E			;
;		 3	   Z3-B 	127			;
;								;
;								;
;	...SET THE OPERATING MODE?				;
;	Zones values are assigned to one of two parameter	;
;	groups: Note Numbers or Velocities.  The "mode" is      ;
;	selected using the NOTE and VEL keys.  The appropriate	;
;	MODE LED lights.					;
;								;
;								;
;	...OPERATE THE MAPPER?					;
;	In either mode, notes received on channel N are 	;
;	retransmitted on channels assigned to each zone, as	;
;	follows:						;
;								;
;		   ZONE    CHANNEL				;
;		    1	      N 				;
;		    2	     N+1				;
;		    3	     N+2				;
;								;
;	Each zone is considered independently.	If the mode	;
;	parameter value is within the zone's boundaries, it     ;
;	will be retransmitted on that zone's channel.           ;
;								;
;								;
;	...KNOW IF THE DATA BUFFER OVERFLOWS?			;
;	If the receive data buffer becomes full, the OVERFLOW	;
;	LED will light until the device is reset.		;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the VALUE +/- keys and VALUE fader. 	;
;								;
;	| 1:E 2:B 2:E 3:B|	where ccc=0-127 		;
;	| ccc ccc ccc ccc|					;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE BOARD.  MIDI ports used: IN,OUT,THRU. 	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StNote		Operate in Note Number Mode		;
;	StVel		Operate in Velocity Mode		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	BRYINC		Increment Zone boundary 		;
;	BRYDEC		Decrement Zone boundary 		;
;	BRYFDR		Set Zone boundary with fader		;
;	NMODE		Select Note Number mode 		;
;	VMODE		Select Velocity mode			;
;	Z1EDSP		Update display with Zone 1 endpoint	;
;	Z2BDSP		Update display with Zone 2 beginning	;
;	Z2EDSP		Update display with Zone 2 endpoint	;
;	Z3BDSP		Update display with Zone 3 beginning	;
;	ARWCLR		Clear LCD cursor arrow			;
;	KEYMAP		Map incoming messages			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;These codes identify which zone boundary is selected

BRYZ1E		VAR	0	;Zone 1 endpoint
BRYZ2B		VAR	1	;Zone 2 beginning
BRYZ2E		VAR	2	;Zone 2 endpoint
BRYZ3B		VAR	3	;Zone 3 beginning

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

Z1E		.DS	1	;Zone 1 endpoint
Z2B		.DS	1	;Zone 2 beginning
Z2E		.DS	1	;Zone 2 endpoint
Z3B		.DS	1	;Zone 3 beginning
MODE		.DS	1	;mode flag (0=Note, 1=Vel)
BOUND		.DS	1	;zone boundary code
STAT2		.DS	1	;Zone 2 status storage
STAT3		.DS	1	;Zone 3 status storage
CBYTE		.DS	1	;comparison byte

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StNote		EQU	0
StVel		EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvZ1E		EQU	EV_SW1_ON
EvZ2B		EQU	EV_SW2_ON
EvZ2E		EQU	EV_SW3_ON
EvZ3B		EQU	EV_SW4_ON
EvNote		EQU	EV_SW5_ON
EvVel		EQU	EV_SW6_ON
EvMinus 	EQU	EV_SW7_ON
EvPlus		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StNote State 1:StVel                      Not
;	 Event	  NextSt,Act	 NextSt,Act			   Used
;	 --------------------------------------------------------------
 STM_ROW EvIdle,  StNote,IDLE,	 StVel,IDLE,   StNote,IDLE, StNote,IDLE
 STM_ROW EvZ1E,   StNote,Z1EDSP, 	 StVel,Z1EDSP, StNote,IDLE, StNote,IDLE
 STM_ROW EvZ2B,   StNote,Z2BDSP, 	 StVel,Z2BDSP, StNote,IDLE, StNote,IDLE
 STM_ROW EvZ2E,   StNote,Z2EDSP, 	 StVel,Z2EDSP, StNote,IDLE, StNote,IDLE
 STM_ROW EvZ3B,   StNote,Z3BDSP,     StVel,Z3BDSP, StNote,IDLE, StNote,IDLE
 STM_ROW EvNote,  StNote,IDLE,	 StNote,NMODE, StNote,IDLE, StNote,IDLE
 STM_ROW EvVel,   StVel,VMODE,	 StVel,IDLE,   StNote,IDLE, StNote,IDLE
 STM_ROW EvMinus, StNote,BRYDEC,     StVel,BRYDEC, StNote,IDLE, StNote,IDLE
 STM_ROW EvPlus,  StNote,BRYINC,     StVel,BRYINC, StNote,IDLE, StNote,IDLE
 STM_ROW EvValue, StNote,BRYFDR,     StVel,BRYFDR, StNote,IDLE, StNote,IDLE
 STM_ROW EvMsgIn, StNote,KEYMAP,     StVel,KEYMAP, StNote,IDLE, StNote,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	BOUND		;
	sta	STAT2		;
	sta	STAT3		;
	sta	CBYTE		;

	lda	#127		;
	sta	Z1E		;
	sta	Z2B		;
	sta	Z2E		;
	sta	Z3B		;

	clr	MODE		;clear flag

;--- Initialize MIDI

	lda	#$01		;buffer note messages
	sta	M_RX_Q_XPT		;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "14:     Keyboard"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Mapper"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S " 1:E 2:B 2:E 3:B"

	jsr	Z3BDSP		;update display
	jsr	Z2EDSP		;
	jsr	Z2BDSP		;
	jsr	Z1EDSP		;
	jsr	NMODE		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment Zone boundary

BRYINC: lda	BOUND		;fetch boundary code
	beq	BIZ1E		;=0? branch...

	cmp	#1		;
	beq	BIZ2B		;=1? branch...

	cmp	#2		;
	beq	BIZ2E		;=2? branch...

	lda	Z3B		;must be =3, fetch value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	Z3B		;save new value
	jsr	Z3BDSP		;update display
	rts

BIZ1E:	lda	Z1E		;fetch value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	Z1E		;save new value
	jsr	Z1EDSP		;update display
	rts

BIZ2B:	lda	Z2B		;fetch value
	inca			;increment
	and	#$7F		;constrain to 0-127
	cmp	Z2E		;compare to Zone 2 endpoint
	bls	BIZ2B2		;is it < or =? yes? branch...
	lda	#0		;no? load new beginning
BIZ2B2: sta	Z2B		;save new value
	jsr	Z2BDSP		;update display
	rts

BIZ2E:	lda	Z2E		;fetch value
	inca			;increment
	and	#$7F		;constrain to 0-127
	cmp	Z2B		;compare to Zone 2 beginning
	bhs	BIZ2E2		;is it < or =? yes? branch...
	lda	Z2B		;no? load new endpoint
BIZ2E2: sta	Z2E		;save new value
	jsr	Z2EDSP		;update display
	rts

;--- Decrement Zone boundary

BRYDEC: lda	BOUND		;fetch boundary code
	beq	BDZ1E		;=0? branch...

	cmp	#1		;
	beq	BDZ2B		;=1? branch...

	cmp	#2		;
	beq	BDZ2E		;=2? branch...

	lda	Z3B		;must be =3, fetch value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	Z3B		;save new value
	jsr	Z3BDSP		;update display
	rts

BDZ1E:	lda	Z1E		;fetch value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	Z1E		;save new value
	jsr	Z1EDSP		;update display
	rts

BDZ2B:	lda	Z2B		;fetch value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	cmp	Z2E		;compare to Zone 2 endpoint
	bls	BDZ2B2		;is it < or =? yes? branch...
	lda	Z2E		;no? load new beginning
BDZ2B2: sta	Z2B		;save new value
	jsr	Z2BDSP		;update display
	rts

BDZ2E:	lda	Z2E		;fetch value
	deca			;decrement
	and	#$7F		;constrain to 0-127
	cmp	Z2B		;compare to Zone 2 beginning
	bhs	BDZ2E2		;is it < or =? yes? branch...
	lda	#127		;no? load new endpoint
BDZ2E2: sta	Z2E		;save new value
	jsr	Z2EDSP		;update display
	rts

;--- Set Zone boundary with fader

BRYFDR: lda	BOUND		;fetch boundary code
	beq	BFZ1E		;=0? branch...

	cmp	#1		;
	beq	BFZ2B		;=1? branch...

	cmp	#2		;
	beq	BFZ2E		;=2? branch...

	lda	FDR		;must be =3, fetch fader value
	lsra			;constrain to 0-127
	sta	Z3B		;save new value
	jsr	Z3BDSP		;update display
	rts

BFZ1E:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	Z1E		;save new value
	jsr	Z1EDSP		;update display
	rts

BFZ2B:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	cmp	Z2E		;compare to Zone 2 endpoint
	bls	BFZ2B2		;is it < or =? yes? branch...
	lda	Z2E		;no? load endpoint
BFZ2B2: sta	Z2B		;save new value
	jsr	Z2BDSP		;update display
	rts

BFZ2E:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	cmp	Z2B		;compare to Zone 2 beginning
	bhs	BFZ2E2		;is it < or =? yes? branch...
	lda	Z2B		;no? load beginning
BFZ2E2: sta	Z2E		;save new value
	jsr	Z2EDSP		;update display
	rts

;--- Select Note Number mode

NMODE:	clr	MODE		;clear flag
	lda	#15		;turn VEL LED off
	jsr	LED_OFF 	;
	lda	#3		;turn NOTE LED on
	jsr	LED_ON		;
	rts

;--- Select Velocity mode

VMODE:	lda	#1		;set flag
	sta	MODE		;
	lda	#3		;turn NOTE LED off
	jsr	LED_OFF 	;
	lda	#15		;turn VEL LED on
	jsr	LED_ON		;
	rts

;--- Update display with Zone 1 endpoint

Z1EDSP: lda	#BRYZ1E 	;load Zone 1 boundary code
	sta	BOUND		;save new code

	lda	#3		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	Z1E		;fetch value
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow
	lda	#0		;place Z1E arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with Zone 2 beginning

Z2BDSP: lda	#BRYZ2B 	;load Zone 2 boundary code
	sta	BOUND		;save new code

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	Z2B		;fetch value
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow
	lda	#4		;place Z2B arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with Zone 2 endpoint

Z2EDSP: lda	#BRYZ2E 	;load Zone 2 boundary code
	sta	BOUND		;save new code

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	Z2E		;fetch value
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow
	lda	#8		;place Z2E arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update display with Zone 3 beginning

Z3BDSP: lda	#BRYZ3B 	;load Zone 3 boundary code
	sta	BOUND		;save new code

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	Z3B		;fetch value
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow
	lda	#12		;place Z3B arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Clear LCD cursor arrow

ARWCLR: lda	#0		;1st possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;2nd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#8		;3rd possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#12		;4th possible arrow position
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	rts

;--- Map incoming message

KEYMAP: brclr   QFULL,MP_FLAGS,KMA  ;check overflow flag
	lda	#0		;overflow? turn LED on...
	jsr	LED_ON		;

KMA:    brset   CHMSG,MP_FLAGS,KMB  ;was there a note message?
	rts			;no? return

KMB:	lda	MP_RSTAT 	;yes? fetch status
	and	#$0F		;get channel
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	STAT2		;M_TEMPOrary storage
	inca			;increment again
	and	#$0F		;constrain to 0-15
	sta	STAT3		;M_TEMPOrary storage

	lda	MP_RSTAT 	;fetch status
	and	#$F0		;get status nibble
	add	STAT2		;add M_TEMPOrary storage
	sta	STAT2		;save as Zone 2 status

	lda	MP_RSTAT 	;fetch status
	and	#$F0		;get status nibble
	add	STAT3		;add M_TEMPOrary storage
	sta	STAT3		;save as Zone 3 status

	lda	MP_DATA2		;fetch velocity value
	beq	KMOFF		;=0 (note "off")? branch...

	lda	MP_RSTAT 	;nonzero? fetch status
	and	#$F0		;get status nibble
	cmp	#$90		;is it Note On?
	FAR_BEQ KMON		;yes? branch...

;--- turn note(s) off in all zones

KMOFF:	lda	M_FULL_MSG 	;wait if in the middle
	beq	KMOFF		; of receiving a message
	sei			;disable all interrupts
	lda	MP_RSTAT 	;fetch Zone 1 Status Byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;fetch ("off") velocity value
	jsr	MIDI_PUT	;send it
	cli			;enable all interrupts
	jsr	DELAY_1MS	;wait

KMOFFA: lda	M_FULL_MSG 	;wait if in the middle
	beq	KMOFFA		; of receiving a message
	sei			;disable all interrupts
	lda	STAT2		;fetch Zone 2 Status Byte
	jsr	MIDI_PUT	;send status
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;load ("off") velocity value
	jsr	MIDI_PUT	;send it
	cli			;enable all interrupts
	jsr	DELAY_1MS	;wait

KMOFFB: lda	M_FULL_MSG 	;wait if in the middle
	beq	KMOFFB		; of receiving a message
	sei			;disable all interrupts
	lda	STAT3		;fetch Zone 3 Status Byte
	jsr	MIDI_PUT	;send status
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;load ("off") velocity value
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	KMOFFC		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
KMOFFC: cli			;enable all interrupts
	jsr	DELAY_1MS	;wait
	rts

;--- turn note(s) on and administer to various zones

KMON:	lda	MODE		;fetch mode flag
	beq	KMNOTE		;=0 (note mode)? branch...

KMVEL:	lda	MP_DATA2		;=1 (vel mode)? fetch velocity
	sta	CBYTE		;save as comparison byte
	jmp	KMON1		;jump...

KMNOTE: lda	MP_DATA1		;fetch note number
	sta	CBYTE		;save as comparison byte

KMON1:	cmp	Z1E		;is value within Zone 1?
	bhi	KMON2		;no? branch...

KMONW1: lda	M_FULL_MSG 	;yes? wait if in the middle
	beq	KMONW1		; of receiving a message
	sei			;disable all interrupts
	lda	MP_RSTAT 	;fetch Zone 1 Status Byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;fetch velocity value
	jsr	MIDI_PUT	;send it
	cli			;enable all interrputs
	jsr	DELAY_1MS	;wait

KMON2:	lda	CBYTE		;fetch comparison byte
	cmp	Z2B		;is value below Zone 2?
	blo	KMON3		;yes? branch...
	cmp	Z2E		;is value above Zone 2?
	bhi	KMON3		;yes? branch...

KMONW2: lda	M_FULL_MSG 	;no? wait if in the middle
	beq	KMONW2		; of receiving a message
	sei			;disable all interrupts
	lda	STAT2		;fetch Zone 2 Status Byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;fetch velocity value
	jsr	MIDI_PUT	;send it
	cli			;enable all interrupts
	jsr	DELAY_1MS	;wait

KMON3:	lda	CBYTE		;fetch comparison byte
	cmp	Z3B		;is value within Zone 3?
	blo	KMONZ		;no? branch...

KMONW3: lda	M_FULL_MSG 	;yes? wait if in the middle
	beq	KMONW3		; of receiving a message
	sei			;disable all interrupts
	lda	STAT3		;fetch Zone 3 Status Byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1		;fetch note number
	jsr	MIDI_PUT	;send it
	lda	MP_DATA2		;fetch velocity value
	jsr	MIDI_PUT	;send it
KMONZ:	lda	M_RSTAT		;fetch external running status
	beq	KMONZ2		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
KMONZ2: cli			;enable all interrupts
	jsr	DELAY_1MS	;wait
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
	cmp	#$01		;is it note message class?
	bne	SENDIT		;no? branch...
        jmp     SCI_RX_CBCK_S_RET ;yes? go buffer it
SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer
