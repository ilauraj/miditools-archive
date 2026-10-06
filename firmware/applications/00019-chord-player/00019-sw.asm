;===============================================================;
;								;
;       TOOL18.ASM      Rev 2.0		April 29, 1997          ;
;	Chord Player						;
;								;
;	The user can generate selected chords by playing only	;
;	the root note.						;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT A CHORD TYPE? 				;
;	The chord type is selected with the appropriate key.	;
;	Available chords types are: MAJOR, Major 7th (MAJ 7),	;
;	Dominant 7th (DOM 7), Major 9th (MAJ 9), MINOR, 	;
;	Minor 7th (MIN 7), Minor 7th+9th (MIN79), and		;
;	Major 7th+9th (MAJ79).					;
;								;
;								;
;	...SIMULATE A GUITAR STRUM OR PIANO ARPEGGIO?		;
;	The time between each note in the chord can be set	;
;	using the STRUM fader.	A minimum setting simulates	;
;	a piano chord (all notes are played simultaneously); a	;
;	maximum setting simulates a slow guitar strum.	Notes	;
;	play from the lowest (root) note of the chord to the	;
;	highest.						;
;								;
;	There is a special strum mode available when the STRUM	;
;	value is between 16-31.  In this range, the downward	;
;	strum occurs with the received Note On message.  When,	;
;	the key is released, an upward strum is generated at a	;
;	velocity slightly less than the downward strum.  This	;
;	upward strum is played in half the selected STRUM time. ;
;	When the upward strum is finished, the chord is 	;
;	immediately turned off. 				;
;								;
;								;
;	...PLAY CHORDS USING THIS PLAYER?			;
;	The chord begins playing when a root note message is	;
;	received.  The CHORD and STRUM settings are displayed	;
;	in the LCD.						;
;								;
;	All non-note messages are merged with any generated	;
;	note messages (e.g. controllers, timing clock, etc.)	;
;								;
;								;
;	...SET MY MASTER CONTROLLER FOR PROPER OPERATION?	;
;	This device should be controlled using a monophonic	;
;	(one note at a time) controller or technique.  It is	;
;	not meant for polyphonic input except for special	;
;	effect purposes.					;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	|CHORD	    STRUM|	where xxxxxxxxxx="major",       ;
;	|xxxxxxxxxx  mmm |	"minor", "dominant 7",          ;
;				"major 7", "minor 7+9",         ;
;				"minor 7", "major 7+9", or      ;
;				"major 9", mmm=0-255            ;
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
;	StOp		Operate 				;
;								;
;	Actions:						;
;								;
;	IDLE		No action (administer chords)		;
;	CMAJ		Set chord to major			;
;	CMAJ7		Set chord to major 7th			;
;	CDOM7		Set chord to dominant 7th		;
;	CMAJ9		Set chord to major 9th			;
;	CMIN		Set chord to minor			;
;	CMIN7		Set chord to minor 7th			;
;	CMIN79		Set chord to minor 7th+9th		;
;	CMAJ79		Set chord to major 7th+9th		;
;	STRSET		Set strum delay with fader		;
;	CDISP		Update display with chord type		;
;	SDISP		Update display with strum value 	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;These codes represent the chord type in the CHORD variable

CHMAJ		VAR	0	;major chord
CHMAJ7		VAR	1	;major 7th chord
CHDOM7		VAR	2	;dominant 7th chord
CHMAJ9		VAR	3	;major 9th chord
CHMIN		VAR	4	;minor chord
CHMIN7		VAR	5	;minor 7th chord
CHMIN79 	VAR	6	;minor 7th+9th chord
CHMAJ79 	VAR	7	;major 7th+9th chord

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

CHORD		.DS	1	;chord type
ONCHORD 	.DS	1	;chord on flag
OFFCHORD	.DS	1	;chord off flag
STRUM		.DS	1	;strum value
ROOTSTAT	.DS	1	;root note status byte
ROOT		.DS	1	;root note number
ROOTVEL 	.DS	1	;root note velocity
ONVEL		.DS	1	;root note on velocity
DCNT		.DS	1	;delay counter
NCNT		.DS	1	;note counter
NPNT		.DS	1	;note offset pointer

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvMajor 	EQU	EV_SW1_ON
EvMaj7		EQU	EV_SW2_ON
EvDom7		EQU	EV_SW3_ON
EvMaj9		EQU	EV_SW4_ON
EvMinor 	EQU	EV_SW5_ON
EvMin7		EQU	EV_SW6_ON
EvMin79 	EQU	EV_SW7_ON
EvMaj79 	EQU	EV_SW8_ON
EvStrum 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0: StOp                            Not
;	 Event	  NextSt,Act				  Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,  StOp,IDLE,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMajor, StOp,CMAJ,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMaj7,  StOp,CMAJ7,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvDom7,  StOp,CDOM7,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMaj9,  StOp,CMAJ9,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMinor, StOp,CMIN,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMin7,  StOp,CMIN7,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMin79, StOp,CMIN79, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMaj79, StOp,CMAJ79, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvStrum, StOp,STRSET, StOp,IDLE, StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	CHORD		;
	sta	STRUM		;
	sta	ROOTSTAT	;
	sta	ROOT		;
	sta	ROOTVEL 	;
	sta	ONVEL		;

	clr	ONCHORD 	;clear flags
	clr	OFFCHORD	;

	clr	DCNT		;clear counters
	clr	NCNT		;

	clr	NPNT		;clear pointer

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "18:        Chord"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3       Player"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "CHORD      STRUM"

	jsr	CDISP		;update display
	jsr	SDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action (administer chords)

IDLE:	lda	ONCHORD 	;get chord on flag
	FAR_BNE IDON		;=1 (play chord)? branch...
	lda	OFFCHORD	;=0? get chord off flag
	FAR_BEQ IDEND		;=0? branch...
	lda	STRUM		;=1 (chord off)? get strum value
	cmp	#16		;compare to 16
	blo	IDOFF		;<16? branch...
	cmp	#32		;> or =16? compare to 32
	bhs	IDOFF		;> or =32? branch...

	;--- generate upward strum in special strum mode (16-31)

IDUP:	lda	CHORD		;get chord type
	add	#24		;add 24 to setup pointer
	sta	NPNT		;save as note pointer

	lda	#4		;reset note counter
	sta	NCNT		;

IDUPA:	beq	IDUPG		;finished? branch...
IDUPB:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDUPB		; of receiving a message
	lda	ROOTSTAT	;fetch root Status Byte
	and	#$0F		;get channel
	add	#$90		;add Note On status nibble
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

	ldx	NPNT		;get note pointer for lookup
IDUP1:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDUP1		; of receiving a message
	lda	NOTELIST,X	;get note offset from table
	add	ROOT		;add root note to offset
	and	#$7F		;constrain to 0-127
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

IDUP2:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDUP2		; of receiving a message
	lda	ONVEL		;new velocity=on velocity-20
	cmp	#20		; (if on vel<21, send same)
	bls	IDUPC		;
	sub	#20		;
IDUPC:	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts
IDUP3:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDUP3		; of receiving a message
	lda	M_RSTAT		;fetch external running status
	beq	IDUPD		;=0? branch...
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts
	
IDUPD:	lda	NPNT		;for next note: pointer-8
	sub	#8		;
	sta	NPNT		;save new pointer
	lda	STRUM		;get strum value
	sta	DCNT		;save delay counter

IDUPE:	beq	IDUPF		;administer delayed strum
	dec	DCNT		; (1 STRUM=1 MS)
	jsr	DELAY_1MS	;pause
	lda	DCNT		;load counter
	jmp	IDUPE		;loop

IDUPF:	lda	NCNT		;get note counter
	deca			;decrement
	sta	NCNT		;save new note counter
	jmp	IDUPA		;loop

IDUPG:	jsr	DELAY_1MS	;wait before ending chord

	;--- turn chord off

IDOFF:	lda	CHORD		;get chord type
	sta	NPNT		;save as pointer value

IDOF1:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDOF1		; of receiving a message
	lda	ROOTSTAT	;fetch root Status Byte
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

	lda	#4		;reset note counter
	sta	NCNT		;

IDOFFA: beq	IDOFFB		;finished? branch...
	ldx	NPNT		;load note pointer for lookup
IDOF2:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDOF2		; of receiving a message
	lda	NOTELIST,X	;get note offset from table
	add	ROOT		;add root note to offset
	and	#$7F		;constrain to 0-127
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
IDOF3:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDOF3		; of receiving a message
	lda	#0		;load off velocity=0
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

	lda	#8		;for next note: pointer+8
	add	NPNT		;
	sta	NPNT		;save new value

	lda	NCNT		;get note counter
	deca			;decrement
	sta	NCNT		;save new note counter
	jmp	IDOFFA		;loop

IDOFFB: lda	M_FULL_MSG 	;wait if in the middle
	beq	IDOFFB		; of receiving a message
	lda	M_RSTAT		;fetch external running status
	beq	IDOFFC		;=0? branch...
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

IDOFFC: clr	ONCHORD 	;clear flags
	clr	OFFCHORD	;
	rts

	;--- play chord

IDON:	lda	CHORD		;get chord type
	sta	NPNT		;save as pointer value

	lda	#4		;reset note counter
	sta	NCNT		;

IDONA:	beq	IDONF		;finished? branch...
	lda	STRUM		;set delay counter
	sta	DCNT		;

IDONB:	beq	IDONC		;administer delayed strum
	dec	DCNT		; (1 STRUM=1 MS)
	jsr	DELAY_1MS	;pause
	lda	DCNT		;load counter
	jmp	IDONB		;loop

IDONC:	beq	IDOND		;administer delayed strum
	dec	DCNT		; (1 STRUM= 1 MS)
	jsr	DELAY_1MS	;pause
	lda	DCNT		;load counter
	jmp	IDONC		;loop

IDOND:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDOND		; of receiving a message
	lda	ROOTSTAT	;load root Status Byte
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

	ldx	NPNT		;load note pointer for lookup
IDON1:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDON1		; of receiving a message
	lda	NOTELIST,X	;get note offset from table
	add	ROOT		;add root note ot offset
	and	#$7F		;constrain to 0-127
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
IDON2:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDON2		; of receiving a message
	lda	ROOTVEL 	;load velocity
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

IDON3:	lda	M_FULL_MSG 	;wait if in the middle
	beq	IDON3		; of receiving a message
	lda	M_RSTAT		;fetch external running status
	beq	IDONE		;=0? branch...
	sei			;disable all interrupts
	jsr	MIDI_PUT	;send it
	cli			;enable interrupts

IDONE:	lda	OFFCHORD	;has new Note Off message
	FAR_BNE IDOFF		; been received? yes? jump...
	lda	#8		;no? for next note: pointer+8
	add	NPNT		;
	sta	NPNT		;save new value

	lda	NCNT		;get note counter
	deca			;decrement
	sta	NCNT		;save new note counter
	jmp	IDONA		;loop

IDONF:	clr	ONCHORD 	;clear flag
IDEND:	rts

NOTELIST:
	.DB	$07,$07,$07,$07,$07,$07,$07,$07
	.DB	$0C,$0B,$0A,$0C,$0C,$0A,$0A,$0B
	.DB	$10,$10,$10,$0E,$0F,$0F,$0E,$0E
	.DB	$13,$13,$13,$13,$13,$13,$13,$13

;--- Set chord to major

CMAJ:	lda	#CHMAJ		;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to major 7th

CMAJ7:	lda	#CHMAJ7 	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to dominant 7th

CDOM7:	lda	#CHDOM7 	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to major 9th

CMAJ9:	lda	#CHMAJ9 	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to minor

CMIN:	lda	#CHMIN		;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to minor 7

CMIN7:	lda	#CHMIN7 	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to minor 7th+9th

CMIN79: lda	#CHMIN79	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set chord to major 7th+9th

CMAJ79: lda	#CHMAJ79	;load chord code
	sta	CHORD		;save new value
	jsr	CDISP		;update display
	rts

;--- Set strum value with fader

STRSET: lda	FDR		;load fader value
	sta	STRUM		;save new value
	jsr	SDISP		;update display
	rts

;--- Update display with chord type

CDISP:	lda	#0		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	ldx	CHORD		;index to display chord type
	JMP_TABLE TBL_DSP	;execute jump from table

TBL_DSP:
	.DW DMAJ,DMAJ7,DDOM7,DDIM,DMIN,DMIN7,DMIN79,DAUG

DMAJ:	LCD_PUT_S "major     "
	rts

DMAJ7:	LCD_PUT_S "major 7   "
	rts

DDOM7:	LCD_PUT_S "dominant 7"
	rts

DDIM:	LCD_PUT_S "major 9   "
	rts

DMIN:	LCD_PUT_S "minor     "
	rts

DMIN7:	LCD_PUT_S "minor 7   "
	rts

DMIN79: LCD_PUT_S "minor 7+9 "
	rts

DAUG:	LCD_PUT_S "major 7+9 "
	rts

;--- Update display with strum value

SDISP:	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	STRUM		;fetch value
	jsr	LCD_PUT_RJ3_I	;display
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

;--- Service Status Bytes

SCI_RX_CBCK_S:
	cmp	#$01		;is it a note message?
	beq	URSA		;yes? branch...
	jmp	SENDIT		;no? jump...
URSA:	stx	ROOTSTAT	;save root Status Byte
	jmp	SENDIT		;jump...

;--- Service 1st Data Bytes

SCI_RX_CBCK_D1:
	cmp	#$01		;is it a note message?
	beq	URD1A		;yes? branch...
	jmp	SENDIT		;no? jump...
URD1A:	stx	ROOT		;save root note number
	jmp	SENDIT		;jump...

;--- Service 2nd Data Bytes

SCI_RX_CBCK_D2:
	cmp	#$01		;is it a note message?
	beq	URD2A		;yes? branch...
	jmp	SENDIT		;no? jump...

URD2A:	stx	ROOTVEL 	;save root note velocity
	beq	URD2B		;=0 (note "off")? branch...
	lda	ROOTSTAT	;nonzero? get root Status Byte
	and	#$F0		;get status nibble
	cmp	#$80		;is it Note Off?
	beq	URD2B		;yes? branch...
	inc	ONCHORD 	;no? set chord on flag
	lda	ROOTVEL 	;fetch root note velocity
	sta	ONVEL		;save value
	jmp	SENDIT		;jump...

URD2B:	inc	OFFCHORD	;set chord off flag

SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer
