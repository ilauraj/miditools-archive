;===============================================================;
;								;
;       00130000.ASM      Rev 2.0  18-Aug-95                    ;
;	CV-to-MIDI Translator           			;
;								;
;	The device translates 4 analog voltages and 4 switch    ;
;	closures to MIDI commands.	   			;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SET THE TRANSMIT CHANNEL?			        ;
;	Press the CH UP or CH DN keys.  The MIDI transmit	;
;	channel is set.						;
;								;
;	...SET THE NOTE NUMBER OFFSET?			        ;
;	Press the OFF UP or OFF DN keys.  The starting note	;
;	number is set.						;
;								;
;	...OPERATE THE DEVICE?					;
;	Four control voltages (0-5VDC) are connected to the	;
;	four ADC inputs (ADC0-ADC1). The digitaized voltages	;
;	are mapped to MIDI messages as follows:			;
;								;
;	INPUT	RANGE		MIDI OUT	RANGE		;
;	F1	0-5VDC		note number	0-63 (+offset)	;
;	F2	0-5VDC		pitch bend	0-127		;
;	F3	0-5VDC		chan aftertouch 0-127		;
;	F4	0-5VDC		modulation	0-127		;
;								;
;	In addition, logic signals (0 or 5VDC) trigger MIDI	;
;	events as follows:					;
;								;
;	INPUT	VALUE		MIDI OUT			;
;	SW1	HI		Note On Message			;
;	SW1	LO		Note Off Message		;
;	SW2	HI		Sustain On Message		;
;	SW2	LO		Sustain Off Message		;
;	SW5	HI		Portamento On Message		;
;	SW5	LO		Portamento Off Message		;
;	SW6	HI		Soft Pedal On Message		;
;	SW6	LO		Soft Pedal Off Message		;
;								;
;	Incoming MIDI messages are ignored. Running status	;
;	is implemented.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	|ChOfNotAftBndMod|  where nn=1-16, aa=0-63, zzz=0-127	;
;	|nnaazzzbbbcccddd|  bbb=0-127, ccc=0-127, ddd=0-127	;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, and 4 switches from	;
;	the Human Interface board.				;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StOp		Operate					;
;								;
;	Actions:						;
;								;
;	IDLE		No action (process key off actions)	;
;	CHINC		Increment transmit channel		;
;	CHDEC		Decrement transmit channel		;
;	OFINC		Increment note number offset		;
;	OFDEC		Decrement note number offset		;
;	NOTON		Transmit MIDI Note On			;
;	SUSON		Transmit MIDI Sustain On		;
;	PORON		Transmit MIDI Portamento On		;
;	SOFON		Transmit MIDI Soft Pedal On		;
;	AFTF3		Set channel aftertouch with voltage 3	;
;	BENDF2		Set pitch bend with voltage 1 		;
;	MODF4		Set modulation with voltage 3 		;
;	CHDISP		Update display with channel		;
;	OFDISP		Update display with note number offset  ;
;	NTDISP		Update display with note number (pitch) ;
;	AFDISP		Update display with aftertouch value	;
;	PBDISP		Update display with pitch bend value	;
;	MDDISP		Update display with modulation value	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CHAN		.DS	1	;MIDI transmit channel
OFFSET		.DS	1	;note number offset
NOTE		.DS	1	;note number currently on
ONFLAG		.DS	1	;bit-mapped flag (on keys)
SWTEMP		.DS	1	;temp variable
RUNNING		.DS	1	;running status byte
MOD		.DS	1	;modulation value
BEND		.DS	1	;pitch bend value
AFT		.DS	1	;aftertouch value

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvNotOn		EQU	EV_SW1_ON
EvSusOn		EQU	EV_SW2_ON
EvChanUp		EQU	EV_SW3_ON
EvOffUp		EQU	EV_SW4_ON
EvPorOn		EQU	EV_SW5_ON
EvSofOn		EQU	EV_SW6_ON
EvChanDn		EQU	EV_SW7_ON
EvOffDn 		EQU	EV_SW8_ON
EvBend		EQU	EV_F2_MOVE
EvAft			EQU	EV_F3_MOVE
EvMod			EQU	EV_F4_MOVE

;--- Build State Matrix

        STM_BEGIN

;                  State 0: StOp  			    Not
;	 Event	   NextSt,Act	 			   Used
;	 ------------------------------------------------------
 STM_ROW EvIdle,   StOp,IDLE,	StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvNotOn,  StOp,NOTON,	StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvSusOn,  StOp,SUSON,	StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvChanUp, StOp,CHINC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvOffUp,  StOp,OFINC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvPorOn,  StOp,PORON,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvSofOn,  StOp,SOFON,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvChanDn, StOp,CHDEC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvOffDn,  StOp,OFDEC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvBend,   StOp,BENDF2, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvAft,    StOp,AFTF3,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMod,	   StOp,MODF4,  StOp,IDLE, StOp,IDLE, StOp,IDLE

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

	lda	#$00		;default values
	sta	ONFLAG		;
	sta	SWTEMP		;
	sta	CHAN		;
	sta	OFFSET		;
	sta	NOTE		;
	sta	RUNNING		;
	sta	MOD		;
	sta	BEND		;
	sta	AFT		;

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S "      CV-to-MIDI"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v2    Translator"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "ChOfNotAftBndMod"

	jsr	CHDISP		;update display
	jsr	OFDISP		;
	jsr	NTDISP		;
	jsr	AFDISP		;
	jsr	PBDISP		;
	jsr	MDDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action (process key off actions)

IDLE:	lda	ONFLAG		;get flag
	beq	ID4		;if nothing on, return
	RD_SWROWS		;if any on, read switches
	sta	SWTEMP		;store temporarily
		
	brclr	0,ONFLAG,ID1	;note not on? branch... 
	brclr	3,SWTEMP,NOTOFF	;branch if key released
	
ID1:	brclr	1,ONFLAG,ID2	;sustain not on? branch... 
	brclr	2,SWTEMP,SUSOFF	;branch if key released

ID2:	brclr	2,ONFLAG,ID3	;portamento not on? branch... 
	brclr	7,SWTEMP,POROFF	;branch if key released

ID3:	brclr	3,ONFLAG,ID4	;soft pedal not on? branch... 
	brclr	6,SWTEMP,SOFOFF	;branch if key released
ID4:	rts			;otherwise, return

;--- send a Note Off message

NOTOFF:	sei			;disable interrupts
	lda	#$90		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	NO2		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
NO2:	lda	NOTE		;load playing note number
	jsr	MIDI_PUT	;send it
	lda	#0	 	;load velocity
	jsr	MIDI_PUT	;send it
	bclr	0,ONFLAG	;reset flag
	cli			;enable interrupts
	jmp	ID1

;--- send a Sustain Off message

SUSOFF:	sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	SUS2		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SUS2:	lda	#$40		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$00	 	;load off value
	jsr	MIDI_PUT	;send it
	bclr	1,ONFLAG	;reset flag
	cli			;disable interrupts
	jmp	ID2

;--- send a Portamento Off message

POROFF:	sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	POR2		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
POR2:	lda	#$41		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$00	 	;load off value
	jsr	MIDI_PUT	;send it
	bclr	2,ONFLAG	;reset flag
	cli			;enable interrupts
	jmp	ID3

;--- send a Soft Pedal Off message

SOFOFF:	sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	SOF2		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SOF2:	lda	#$43		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$00	 	;load off value
	jsr	MIDI_PUT	;send it
	bclr	3,ONFLAG	;reset flag
	cli			;enable interrupts
	rts

;--- Increment channel

CHINC:	lda	CHAN		;fetch channel
	inca			;increment
	cmp	#15		;valid range: 0-15
	bls	CIA		;< or =15? branch...
	lda	#0		;>15? wrap to 0
CIA:	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Decrement channel

CHDEC:	lda	CHAN		;fetch channel
	deca			;increment
	cmp	#15		;valid range: 0-15
	bls	CDA		;< or =15? branch...
	lda	#15		;>15? wrap to 15
CDA:	sta	CHAN		;store new value
	jsr	CHDISP		;update display
	rts

;--- Increment starting note number

OFINC:  lda	OFFSET		;fetch note offset
	inca			;increment
	and	#$3F		;constrain to 0-63
	sta	OFFSET		;store new value
	jsr	OFDISP		;update display
	rts

;--- Decrement starting note number

OFDEC:  lda	OFFSET		;fetch note offset
	deca			;decrement
	and	#$3F		;constrain to 0-63
	sta	OFFSET		;store new value
	jsr	OFDISP		;update display
	rts

;--- Send a note on message

NOTON:  sei			;disable interrupts
	lda	#$90		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	NOT1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
NOT1:	lda	F1		;fetch voltage value
	lsra			;
	lsra			;constrain to 0-63
	cmp	#1		;
	FAR_BEQ	NOT2		;=1? increment note number...
	cmp	#3		;
	FAR_BEQ	NOT2		;=3? increment note number...
	cmp	#6		;
	FAR_BEQ	NOT2		;=6? increment note number...
	cmp	#8		;
	FAR_BEQ	NOT2		;=8? increment note number...
	cmp	#10		;
	FAR_BEQ	NOT2		;=10? increment note number...
	cmp	#13		;
	FAR_BEQ	NOT2		;=13? increment note number...
	cmp	#15		;
	FAR_BEQ	NOT2		;=15? increment note number...
	cmp	#18		;
	FAR_BEQ	NOT2		;=18? increment note number...
	cmp	#20		;
	FAR_BEQ	NOT2		;=20? increment note number...
	cmp	#22		;
	FAR_BEQ	NOT2		;=22? increment note number...
	cmp	#25		;
	FAR_BEQ	NOT2		;=25? increment note number...
	cmp	#27		;
	FAR_BEQ	NOT2		;=27? increment note number...
	cmp	#30		;
	FAR_BEQ	NOT2		;=30? increment note number...
	cmp	#32		;
	FAR_BEQ	NOT2		;=32? increment note number...
	cmp	#34		;
	FAR_BEQ	NOT2		;=34? increment note number...
	cmp	#37		;
	FAR_BEQ	NOT2		;=37? increment note number...
	cmp	#39		;
	FAR_BEQ	NOT2		;=39? increment note number...
	cmp	#42		;
	FAR_BEQ	NOT2		;=42? increment note number...
	cmp	#44		;
	FAR_BEQ	NOT2		;=44? increment note number...
	cmp	#46		;
	FAR_BEQ	NOT2		;=46? increment note number...
	cmp	#49		;
	FAR_BEQ	NOT2		;=49? increment note number...
	cmp	#51		;
	FAR_BEQ	NOT2		;=51? increment note number...
	cmp	#54		;
	FAR_BEQ	NOT2		;=54? increment note number...
	cmp	#56		;
	FAR_BEQ	NOT2		;=56? increment note number...
	cmp	#58		;
	FAR_BEQ	NOT2		;=58? increment note number...
	cmp	#61		;
	FAR_BEQ	NOT2		;=61? increment note number...
	cmp	#63		;
	FAR_BEQ	NOT2		;=63? increment note number...

	jmp	NOT3		;no match? do not increment...

NOT2:	inca			;

NOT3:	add	OFFSET		;add starting note offset
	sta	NOTE		;save to turn off, and to display
	jsr	MIDI_PUT	;send it
	lda	#10		;default velocity value
	jsr	MIDI_PUT	;send velocity value
	bset	0,ONFLAG	;set flag
	cli			;enable interrupts
	jsr	NTDISP		;update display	
	rts

;--- Send a sustain on message

SUSON:  sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	SUS1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SUS1:	lda	#$40		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$7F	 	;load on value
	jsr	MIDI_PUT	;send it
	bset	1,ONFLAG	;set flag
	cli			;enable interrupts
	rts

;--- Send a portamento on message

PORON:  sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	POR1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
POR1:	lda	#$41		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$7F	 	;load on value
	jsr	MIDI_PUT	;send it
	bset	2,ONFLAG	;set flag
	cli			;enable interrupts
	rts

;--- Send a soft pedal on message

SOFON:  sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	SOF1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SOF1:	lda	#$43		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$7F	 	;load on value
	jsr	MIDI_PUT	;send it
	bset	3,ONFLAG	;set flag
	cli			;enable interrupts
	rts

;--- Set pitch bend with voltage 2

BENDF2: sei			;disable interrupts
	lda	#$E0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	BEN1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
BEN1:	lda	#0		;load pitch bend LSB
	jsr	MIDI_PUT	;send it
	lda	F2		;fetch voltage value
	lsra			;constrain to 0-127
	sta	BEND		;save value for displaying
	jsr	MIDI_PUT	;send pitch bend value
	cli			;enable interrupts
	jsr	PBDISP		;update display
	rts

;--- Set Channel Aftertouch with voltage #3

AFTF3:  sei			;disable interrupts
	lda	#$D0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	AFT1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
AFT1:	lda	F3	 	;load voltage value
	lsra			;constrain to 0-127
	sta	AFT		;save value
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts
	jsr	AFDISP		;update display
	rts

;--- Set modulation with voltage 4

MODF4:  sei			;disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	MOD1		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
MOD1:	lda	#$01		;load controller number
	jsr	MIDI_PUT	;send it
	lda	F4		;fetch voltage value
	lsra			;constrain to 0-127
	sta	MOD		;save value for displaying
	jsr	MIDI_PUT	;send it as mod wheel value
	cli			;enable interrupts
	jsr	MDDISP		;update display
	rts

;--- Update display for changing channel

CHDISP: lda	#1		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for changing offset number

OFDISP: lda	#3		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OFFSET		;fetch offset number
	jsr	LCD_PUT_RJ2_I	;display it
	rts

;--- Update display for note number (only when note on is transmitted)

NTDISP: lda	#6		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NOTE	 	;fetch note number
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for Channel Aftertouch

AFDISP: lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	AFT	 	;fetch velocity
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for pitch bend

PBDISP: lda	#12		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BEND	 	;fetch pitch bend
	jsr	LCD_PUT_RJ3_I	;display it
	rts

;--- Update display for modulation

MDDISP: lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	MOD	 	;fetch modulation
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
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D1:
        MIDI_ISR_LOOPBACK

SCI_RX_CBCK_D2:
        MIDI_ISR_LOOPBACK