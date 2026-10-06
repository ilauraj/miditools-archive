;===============================================================;
;								;
;       000131REL.ASM   Rev 1                                   ;
;	Relay Driver II						;
;								;
;	The user can manipulate eight relays using MIDI		;
;	note on messages received on the same channel.		;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE GLOBAL MIDI RECEIVE CHANNEL? 		;
;	Press the CHAN key.  The global receive channel		;
;	is selected using the +/- key and/or the VALUE fader.	;
;	The device will continue to respond to MIDI commands.	;
;	The default channel is 16.				;
;								;
;	...SELECT A RELAY TO CONFIGURE? 			;
;	Press the RELAY key to display the relay screen.	;
;	A relay can be selected for modification using the	;
;	Left/Right keys. An arrow cursor points at the		;
;	currently selected relay (A-H) note number.		;
;								;
;	...ASSIGN A NOTE NUMBER TO EACH RELAY?			;
;	Select the desired relay, as above. The MIDI note	;
;	number used to control the selected relay is assigned	;
;	with the +/- key and/or the VALUE fader.  For proper	;
;	operation, each relay MUST be assigned to a unique	;
;	note number. The default note numbers are 60-67.	;
;								;
;	...USE NOTE MESSAGES TO AUTOMATICALLY TRIGGER RELAYS?	;
;	A Note On message (with nonzero velocity) will toggle 	;
;	the state of the relay (if it is open when the message	;
;	is received, the relay will close; etc.) The		;
;	corresponding RELAY STATUS LED lights while the relay	;
;	is closed.						;
;								;
;	...MANUALLY CONTROL RELAYS?				;
;	Press the TOG key.  The selected relay will change	;
;	state accordingly.					;
;								;
;	...RESET THE RELAYS?					;
;	Press the RESET key.  All relays will return to their	;
;	power-up state.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	When the selecting the global receive channel,		;
;								;
;	| MIDI           |	where nn = 1-16         	;
;	| CHANNEL:  nn   |	                                ;
;								;
;								;
;	When configuring and operating relays,			;
;								;
;	| -A- -B- -C- -D-|	where bbb = 0-127; OR       	;
;	| bbb bbb bbb bbb|	                                ;
;								;
;	| -E- -F- -G- -H-|	where bbb = 0-127       	;
;	| bbb bbb bbb bbb|	                                ;
;								;
;	The cursor arrow points to the relay that will be	;
;	modified by the + key, VALUE fader, or TOG key. 	;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the RELAY board.  MIDI ports	;
;	used: IN and THRU only. 				;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StCh		Set receive channel			;
;	StRly   	Configure relays         		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	RESET		Resets all relays to default position	;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	NXTRLY		Select next Relay			;
;	PRVRLY		Select previous Relay			;
;	NOTINC		Increment note number of selected relay	;
;	NOTDEC		Decrement note number of selected relay	;
;	NOTFDR		Set note number with fader		;
;	TOG		Toggle current relay status		;
;	RUPD8		Update relay status			;
;	PROC		Process incoming controller messages	;
;	CDISP		Update display for changing channel	;
;	RDISP		Update display for configuring relays	;
;	SDISP		Update relay status (LED) display	;
;	ARWCLR		Clear LCD cursor arrow			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.APPL_RAM
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel
RLYNUM		.DS	1	;currently selected relay
RELAYA		.DS	1	;state of Relay A
RELAYB		.DS	1	;state of Relay B
RELAYC		.DS	1	;state of Relay C
RELAYD		.DS	1	;state of Relay D
RELAYE		.DS	1	;state of Relay E
RELAYF		.DS	1	;state of Relay F
RELAYG		.DS	1	;state of Relay G
RELAYH		.DS	1	;state of Relay H
NOTEA		.DS	1	;note number for Relay A
NOTEB		.DS	1	;note number for Relay B
NOTEC		.DS	1	;note number for Relay C
NOTED		.DS	1	;note number for Relay D
NOTEE		.DS	1	;note number for Relay E
NOTEF		.DS	1	;note number for Relay F
NOTEG		.DS	1	;note number for Relay G
NOTEH		.DS	1	;note number for Relay H

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StCh		EQU	0
StRly   	EQU	1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvReset		EQU	EV_SW1_ON
EvChan		EQU	EV_SW2_ON
EvRelay		EQU	EV_SW3_ON
EvUp	   	EQU	EV_SW4_ON
EvTog		EQU	EV_SW5_ON
EvLeft		EQU	EV_SW6_ON
EvRight		EQU	EV_SW7_ON
EvDown		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StCh State 1:StRly		      Not
;	 Event	  NextSt,Act   NextSt,Act		     Used
;	 --------------------------------------------------------
 STM_ROW EvIdle,  StCh,IDLE,   StRly,IDLE,   StCh,IDLE, StCh,IDLE
 STM_ROW EvReset, StCh,RESET,  StRly,RESET,  StCh,IDLE, StCh,IDLE
 STM_ROW EvChan,  StCh,IDLE,   StCh,CDISP,   StCh,IDLE, StCh,IDLE
 STM_ROW EvRelay, StRly,RDISP, StRly,IDLE,   StCh,IDLE, StCh,IDLE
 STM_ROW EvUp,    StCh,CHINC,  StRly,NOTINC, StCh,IDLE, StCh,IDLE
 STM_ROW EvTog,	  StCh,IDLE,   StRly,TOG,    StCh,IDLE, StCh,IDLE
 STM_ROW EvLeft,  StCh,IDLE,   StRly,PRVRLY, StCh,IDLE, StCh,IDLE
 STM_ROW EvRight, StCh,IDLE,   StRly,NXTRLY, StCh,IDLE, StCh,IDLE
 STM_ROW EvDown,  StCh,CHDEC,  StRly,NOTDEC, StCh,IDLE, StCh,IDLE
 STM_ROW EvValue, StCh,CHFDR,  StRly,NOTFDR, StCh,IDLE, StCh,IDLE
 STM_ROW EvMsgIn, StCh,PROC,   StRly,PROC,   StCh,IDLE, StCh,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#15		;default channel
	sta	CHAN		;

	lda	#0		;default values
	sta	RLYNUM		;
	sta	RELAYA		;
	sta	RELAYB		;
	sta	RELAYC		;
	sta	RELAYD		;
	sta	RELAYE		;
	sta	RELAYF		;
	sta	RELAYG		;
	sta	RELAYH		;

	lda	#60		;default note numbers
	sta	NOTEA		;
	inca			;
	sta	NOTEB		;
	inca			;
	sta	NOTEC		;
	inca			;
	sta	NOTED		;
	inca			;
	sta	NOTEE		;
	inca			;
	sta	NOTEF		;
	inca			;
	sta	NOTEG		;
	inca			;
	sta	NOTEH		;
	inca			;

        X0_LO                   ;default expansion latch
        lda     #0              ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;

;--- Initialize MIDI

	lda	#$01		;buffer note messages
	sta	M_RX_Q_XPT	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S " FINN Pro Audio "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S " Relay Driver v1"
	jsr	DELAY_1SEC

        jsr     LCD_CLEAR

	jsr	CDISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Reset all relays

RESET:	lda	#0		;default values
	sta	RELAYA		;
	sta	RELAYB		;
	sta	RELAYC		;
	sta	RELAYD		;
	sta	RELAYE		;
	sta	RELAYF		;
	sta	RELAYG		;
	sta	RELAYH		;
	jsr	SDISP		;update display
	jsr	RUPD8		;update relay status
	rts

;--- Increment channel

CHINC:	lda	CHAN		;fetch channel
	inca			;increment
        and     #$0F            ;constrain to 0-15
        sta     CHAN            ;store new value
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

;--- Select next Relay

NXTRLY:	lda	RLYNUM		;fetch current relay number
	inca			;increment
        and     #$07            ;constrain to 0-7
        sta     RLYNUM          ;store new value
	jsr	RDISP		;update display
	rts

;--- Select previous Relay

PRVRLY:	lda	RLYNUM		;fetch current relay number
	deca			;decrement
	cmp	#7		;valid range: 0-7
	bls	PRA		;< or =7? branch...
	lda	#7		;>7? wrap to 7
PRA:	sta	RLYNUM		;store new value
	jsr	RDISP		;update display
	rts

;--- Increment note number for selected relay

NOTINC:	ldx     RLYNUM		;branch off cur relay
	cpx	#0              ;
        beq     NIA             ;...if A
	cpx	#1            	;
        beq     NIB             ;...if B
	cpx	#2            	;
        beq     NIC             ;...if C
	cpx	#3            	;
        beq     NID             ;...if D
	cpx	#4            	;
        beq     NIE             ;...if E
	cpx	#5            	;
        beq     NIF             ;...if F
	cpx	#6            	;
        beq     NIG             ;...if G
	cpx	#7            	;
        beq     NIH             ;...if H

        ldx     #0	        ;should never get here
        stx     RLYNUM          ;

NIA:    lda     NOTEA           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEA           ;save new note assignment
        jmp     NIDISP          ;go update display

NIB:    lda     NOTEB           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEB           ;save new note assignment
        jmp     NIDISP          ;go update display

NIC:    lda     NOTEC           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEC           ;save new note assignment
        jmp     NIDISP          ;go update display

NID:    lda     NOTED           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTED           ;save new note assignment
        jmp     NIDISP          ;go update display

NIE:    lda     NOTEE           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEE           ;save new note assignment
        jmp     NIDISP          ;go update display

NIF:    lda     NOTEF           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEF           ;save new note assignment
        jmp     NIDISP          ;go update display

NIG:    lda     NOTEG           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEG           ;save new note assignment
        jmp     NIDISP          ;go update display

NIH:    lda     NOTEH           ;fetch current note assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     NOTEH           ;save new note assignment

NIDISP: jsr     RDISP           ;update display
        rts

;--- Decrement note number for selected relay

NOTDEC:	ldx     RLYNUM		;branch off cur relay
	cpx	#0              ;
        beq     NDA             ;...if A
	cpx	#1            	;
        beq     NDB             ;...if B
	cpx	#2            	;
        beq     NDC             ;...if C
	cpx	#3            	;
        beq     NDD             ;...if D
	cpx	#4            	;
        beq     NDE             ;...if E
	cpx	#5            	;
        beq     NDF             ;...if F
	cpx	#6            	;
        beq     NDG             ;...if G
	cpx	#7            	;
        beq     NDH             ;...if H

        ldx     #0	        ;should never get here
        stx     RLYNUM          ;

NDA:    lda     NOTEA           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEA           ;save new note assignment
        jmp     NDDISP          ;go update display

NDB:    lda     NOTEB           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEB           ;save new note assignment
        jmp     NDDISP          ;go update display

NDC:    lda     NOTEC           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEC           ;save new note assignment
        jmp     NDDISP          ;go update display

NDD:    lda     NOTED           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTED           ;save new note assignment
        jmp     NDDISP          ;go update display

NDE:    lda     NOTEE           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEE           ;save new note assignment
        jmp     NDDISP          ;go update display

NDF:    lda     NOTEF           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEF           ;save new note assignment
        jmp     NDDISP          ;go update display

NDG:    lda     NOTEG           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEG           ;save new note assignment
        jmp     NDDISP          ;go update display

NDH:    lda     NOTEH           ;fetch current note assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     NOTEH           ;save new note assignment

NDDISP: jsr     RDISP           ;update display
        rts

;--- Select note number with fader

NOTFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	RLYNUM		;branch off cur relay
	cpx	#0              ;
	beq	NFA		;...if A
	cpx	#1              ;
	beq	NFB		;...if B
	cpx	#2              ;
	beq	NFC		;...if C
	cpx	#3              ;
	beq	NFD		;...if D
	cpx	#4              ;
	beq	NFE		;...if E
	cpx	#5              ;
	beq	NFF		;...if F
	cpx	#6              ;
	beq	NFG		;...if G
	cpx	#7              ;
	beq	NFH		;...if H

	ldx	#0              ;should never get here
        stx     RLYNUM          ;

NFA:	sta	NOTEA		;save note for Relay A
	jmp	NFI		;jump...

NFB:	sta	NOTEB		;save note for Relay B
	jmp	NFI		;jump...

NFC:	sta	NOTEC		;save note for Relay C
	jmp	NFI		;jump...

NFD:	sta	NOTED		;save note for Relay D
	jmp	NFI		;jump...

NFE:	sta	NOTEE		;save note for Relay E
	jmp	NFI		;jump...

NFF:	sta	NOTEF		;save note for Relay F
	jmp	NFI		;jump...

NFG:	sta	NOTEG		;save note for Relay G
	jmp	NFI		;jump...

NFH:	sta	NOTEH		;save note for Relay H

NFI:	jsr	RDISP		;update display
        rts

;--- Toggle current relay status

TOG:	ldx	RLYNUM		;branch off current relay
	cpx	#0              ;
	beq	TOGA		;...if A
	cpx	#1              ;
	beq	TOGB		;...if B
	cpx	#2              ;
	beq	TOGC		;...if C
	cpx	#3              ;
	beq	TOGD		;...if D
	cpx	#4              ;
	beq	TOGE		;...if E
	cpx	#5              ;
	beq	TOGF		;...if F
	cpx	#6              ;
	beq	TOGG		;...if G
	cpx	#7              ;
	beq	TOGH		;...if H

	ldx	#0              ;should never get here
        stx     RLYNUM          ;

TOGA:	lda	RELAYA		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYA		;save new status
	jmp	TOGI		;jump...

TOGB:	lda	RELAYB		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYB		;save new status
	jmp	TOGI		;jump...

TOGC:	lda	RELAYC		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYC		;save new status
	jmp	TOGI		;jump...

TOGD:	lda	RELAYD		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYD		;save new status
	jmp	TOGI		;jump...

TOGE:	lda	RELAYE		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYE		;save new status
	jmp	TOGI		;jump...

TOGF:	lda	RELAYF		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYF		;save new status
	jmp	TOGI		;jump...

TOGG:	lda	RELAYG		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYG		;save new status
	jmp	TOGI		;jump...

TOGH:	lda	RELAYH		;fetch relay status
	eor	#$01		;toggle it
	sta	RELAYH		;save new status

TOGI:	jsr	SDISP		;update display
	jsr	RUPD8		;update relay status
        rts

;--- Update relay status

RUPD8:	lda	#$00		;initialize (all off)

RUA:	ldx	RELAYA		;add in Relay A status
        cpx     #0              ;
	beq	RUB		;
        ora     #$01            ;

RUB:	ldx	RELAYB		;add in Relay B status
        cpx     #0              ;
	beq	RUC		;
        ora     #$02            ;

RUC:	ldx	RELAYC		;add in Relay C status
        cpx     #0              ;
	beq	RUD		;
        ora     #$04            ;

RUD:	ldx	RELAYD		;add in Relay D status
        cpx     #0              ;
	beq	RUE		;
        ora     #$08            ;

RUE:	ldx	RELAYE		;add in Relay E status
        cpx     #0              ;
	beq	RUF		;
        ora     #$10            ;

RUF:	ldx	RELAYF		;add in Relay F status
        cpx     #0              ;
	beq	RUG		;
        ora     #$20            ;

RUG:	ldx	RELAYG		;add in Relay G status
        cpx     #0              ;
	beq	RUH		;
        ora     #$40            ;

RUH:	ldx	RELAYH		;add in Relay H status
        cpx     #0              ;
	beq	RUI		;
        ora     #$80            ;

RUI:	jsr	SPI_IO		;send data
        X0_HI                   ;latch data
        X0_LO                   ;
        rts

;--- Process incoming note messages

PROC:	lda     MP_RSTAT        ;fetch Note Status Byte
	cmp	#$90		;compare to Note On Status
	FAR_BLO	PJ		;Note Off? branch...
	and	#$0F		;get channel
	cmp	CHAN		;is it the one we selected?
	FAR_BNE	PJ		;no? branch...

        lda     MP_DATA1        ;yes? branch off note number
        cmp     NOTEA           ;
	beq	PA		;...matches Relay A
        cmp     NOTEB           ;
	beq	PB		;...matches Relay B
        cmp     NOTEC           ;
	beq	PC		;...matches Relay C
        cmp     NOTED           ;
	beq	PD		;...matches Relay D
        cmp     NOTEE           ;
	beq	PE		;...matches Relay E
        cmp     NOTEF           ;
	beq	PF		;...matches Relay F
        cmp     NOTEG           ;
	beq	PG		;...matches Relay G
        cmp     NOTEH           ;
	beq	PH		;...matches Relay H
	rts			;...not a desired note

PA:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	FAR_BEQ	PJ		;=0? ignore...
	lda	RELAYA		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYA		;save new status
	jmp	PI		;jump...

PB:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYB		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYB		;save new status
	jmp	PI		;jump...

PC:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYC		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYC		;save new status
	jmp	PI		;jump...

PD:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYD		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYD		;save new status
	jmp	PI		;jump...

PE:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYE		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYE		;save new status
	jmp	PI		;jump...

PF:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYF		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYF		;save new status
	jmp	PI		;jump...

PG:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYG		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYG		;save new status
	jmp	PI		;jump...

PH:	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	beq	PJ		;=0? ignore...
	lda	RELAYH		;fetch relay status
        eor     #$01            ;toggle it
	sta	RELAYH		;save new status

PI:	jsr	SDISP		;update display
	jsr	RUPD8		;update relay status

PJ:	rts

;--- Update display for changing channel

CDISP:	lda	#0		;display top line
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " MIDI           "

	lda	#0		;display bottom line
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " CHANNEL:   "

	lda	CHAN		;fetch channel number
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#13		;erase remainder of bottom line
        ldx     #1              ;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "   "         ;
        rts

;--- Update display for configuring relays

RDISP:	lda	RLYNUM		;get current relay number
	cmp	#3		;
	FAR_BHI	RDISP2		;>3? go to page 2 of display

	lda	#0		;top line of display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " -A- -B- -C- -D-"

	lda	#0		;clear bottom line of display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "                "

	lda	#3		;position cursor
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
	lda	NOTEA		;fetch Relay A note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTEB		;fetch Relay B note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTEC		;fetch Relay C note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTED		;fetch Relay D note
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow

	lda	RLYNUM		;branch off current relay
	cmp	#0              ;
	beq	RDA		;...if A
	cmp	#1              ;
	beq	RDB		;...if B
	cmp	#2              ;
	beq	RDC		;...if C

	lda	#12		;place arrow for Relay D
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDA:	lda	#0		;place arrow for Relay A
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
        rts

RDB:	lda	#4		;place arrow for Relay B
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDC:	lda	#8		;place arrow for Relay C
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDISP2:	lda	#0		;top line of display
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " -E- -F- -G- -H-"

	lda	#0		;clear bottom line of display
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "                "

	lda	#3		;position cursor
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
	lda	NOTEE		;fetch Relay E note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#7		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTEF		;fetch Relay F note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTEG		;fetch Relay G note
	jsr	LCD_PUT_RJ3_I	;display it

	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTEH		;fetch Relay H note
	jsr	LCD_PUT_RJ3_I	;display it

	jsr	ARWCLR		;clear arrow

	lda	RLYNUM		;branch off current relay
	cmp	#4              ;
	beq	RDE		;...if E
	cmp	#5              ;
	beq	RDF		;...if F
	cmp	#6              ;
	beq	RDG		;...if G

	lda	#12		;place arrow for Relay H
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDE:	lda	#0		;place arrow for Relay E
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
        rts

RDF:	lda	#4		;place arrow for Relay F
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

RDG:	lda	#8		;place arrow for Relay G
        ldx     #1              ;
	jsr	LCD_PUT_ARROW	;
	rts

;--- Update relay status display

SDISP:	lda	#0		;load Relay A LED number
	ldx	RELAYA		;fetch relay status
	beq	SDAA		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDB		;jump...
SDAA:	jsr	LED_OFF 	;turn LED off

SDB:	lda	#1		;load Relay B LED number
	ldx	RELAYB		;fetch relay status
	beq	SDBB		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDC		;jump...
SDBB:	jsr	LED_OFF 	;turn LED off

SDC:	lda	#2		;load Relay C LED number
	ldx	RELAYC		;fetch relay status
	beq	SDCC		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDD		;jump...
SDCC:	jsr	LED_OFF 	;turn LED off

SDD:	lda	#3		;load Relay D LED number
	ldx	RELAYD		;fetch relay status
	beq	SDDD		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDE		;jump...
SDDD:	jsr	LED_OFF 	;turn LED off

SDE:	lda	#12		;load Relay E LED number
	ldx	RELAYE		;fetch relay status
	beq	SDEE		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDF		;jump...
SDEE:	jsr	LED_OFF 	;turn LED off

SDF:	lda	#13		;load Relay F LED number
	ldx	RELAYF		;fetch relay status
	beq	SDFF		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDG		;jump...
SDFF:	jsr	LED_OFF 	;turn LED off

SDG:	lda	#14		;load Relay G LED number
	ldx	RELAYG		;fetch relay status
	beq	SDGG		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDH		;jump...
SDGG:	jsr	LED_OFF 	;turn LED off

SDH:	lda	#15		;load Relay H LED number
	ldx	RELAYH		;fetch relay status
	beq	SDHH		;=0 (off)? branch...
	jsr	LED_ON		;=1 (on)? turn LED on
	jmp	SDI		;jump...
SDHH:	jsr	LED_OFF 	;turn LED off

SDI:	rts

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