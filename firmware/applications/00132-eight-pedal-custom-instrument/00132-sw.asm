;===============================================================;
;								;
;       001328-P.ASM      Rev 0.1                               ;
;	8-Pedal Custom Instrument      				;
;								;
;	The user can configure up to 8 footswitches to create	;
;	a custom MIDI controller.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...SELECT THE DESIRED FOOTSWITCH TO CONFIGURE?		;
;	Press the LEFT or RIGHT key until the desired 		;
;	footswitch (1-8) is displayed.				;
;								;
;	...SET THE DESIRED MESSAGE TYPE FOR EACH FOOTSWITCH?	;
;	Press the STATUS key.  The MIDI message type		;
;	is set with the +/- keys and/or the VALUE fader.	;
;	For channel messages, the channel changes with the	;
;	changing value of the fader/keys. Available message	;
;	types include: NOTE, CONTROLLER, PROGRAM CHANGE,	;
;	STOP, START, and CONTINUE.				;
;								;
;	...SET THE DATA VALUE NUMBER?				;
;	Press the NUMBER key.  The data value number for	;
;	all footswitch presses is selected using the +/- keys	;
;	and/or VALUE the fader.					;
;								;
;	...SEND A MESSAGE?					;
;	Press a footswitch. When depressed, the selected	;
;	MIDI channel message is transmitted with value=127.	;
;	released, the same message is transmitted with		;
;	value=0. For Program Changes and Stop/Start/Continue	;
;	messages depressing the footswitch sends the		;
;	appropriate message; releasing the switch does nothing.	;
;	Regardless of the selected message, the corresponding	;
;	LED lights when the footswitch is pressed.		;
;								;
;	...SAVE ALL PARAMETERS?					;
;	Press the SAVE key. All parameters are stored in	;
;	nonvolatile memory. They will be restored when the	;
;	device is turned on.					;
;								;
;	...RESTORE SAVED PARAMETERS?				;
;	Press the RESTORE key. All device parameters will be	;
;	restored to those most recently saved.			;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	|x:ssssssssssssss|	where x=1-8; nn=1-16, bbb=0-127,;
;	| CH=nn  NUM=bbb |	ssss="NOTE","CONTROLLER",	;
;				"PROGRAM CHANGE","START",	;
;				"STOP", "CONTINUE"		;
;                                                               ;
;---------------------------------------------------------------;
;                                                               ;
;	LEDs:							;
;								;
;	x	4	5	x				;
;	3	x	x	6				;
;	2	x	x	7				;
;	x	1	8	x				;
;								;
;	The number is the footswitch that is tied to it.	;
;								;
;---------------------------------------------------------------;
;								;
;								;
;	Switches:						;
;								;
;	 ------- ------- ------- -------			;
;	| SAVE  | STATUS| NUMBER|   +   |			;
;	 ------- ------- ------- -------			;
;	|RESTORE|  Left | Right |   -   |			;
;	 ------- ------- ------- -------			;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the EXTERNAL KEYS board.  MIDI	;
;	OUT only.						;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StStat		Set status byte				;
;       StNum           Set number                              ;
;                                                               ;
;	Actions:						;
;								;
;	IDLE		No action				;
;	STINC		Increment status			;
;	STDEC		Decrement status			;
;	STFDR		Set status with fader			;
;       NUMINC          Increment number                        ;
;       NUMDEC          Decrement number                        ;
;       NUMFDR          Set number with fader                   ;
;       SAVE          	Save parameters to memory		;
;	LOAD		Load stored parameters         		;
;	NXTSW		Select next switch	         	;
;	PRVSW		Select previous switch	         	;
;	SCAN    	Scan key matrix and transmit notes  	;
;	SDISP		Update display for changing status	;
;	NDISP		Update display for changing number	;
;	XDISP		Update display for activating switch	;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

STT		.DS	1	;MIDI status byte
STTA		.DS	1	;MIDI status byte
STTB		.DS	1	;MIDI status byte
STTC		.DS	1	;MIDI status byte
STTD		.DS	1	;MIDI status byte
STTE		.DS	1	;MIDI status byte
STTF		.DS	1	;MIDI status byte
STTG		.DS	1	;MIDI status byte
STTH		.DS	1	;MIDI status byte
NUM		.DS	1	;MIDI data byte 1 value
NUMA		.DS	1	;MIDI data byte 1 value
NUMB		.DS	1	;MIDI data byte 1 value
NUMC		.DS	1	;MIDI data byte 1 value
NUMD		.DS	1	;MIDI data byte 1 value
NUME		.DS	1	;MIDI data byte 1 value
NUMF		.DS	1	;MIDI data byte 1 value
NUMG		.DS	1	;MIDI data byte 1 value
NUMH		.DS	1	;MIDI data byte 1 value
KEYS            .DS     1       ;image of keyswitches
TEMP		.DS	1	;Temporary variable
KEYCHG		.DS	1	;Temporary image of A register
OLDCOL		.DS	1	;Temporary image of X register
SWNUM           .DS     1       ;switch number

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StNum		EQU	0
StStat          EQU     1

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvSave		EQU	EV_SW1_ON
EvStat          EQU     EV_SW2_ON
EvNum           EQU     EV_SW3_ON
EvUp            EQU     EV_SW4_ON
EvRest          EQU     EV_SW5_ON
EvLeft		EQU     EV_SW6_ON
EvRight         EQU     EV_SW7_ON
EvDown   	EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StNum State 1:StStat                   Not
;	 Event	  NextSt,Act     NextSt,Act     	        Used
;	 -----------------------------------------------------------
 STM_ROW EvIdle,  StNum,SCAN,   StStat,SCAN,  StNum,IDLE, StNum,IDLE
 STM_ROW EvSave,  StNum,SAVE,   StStat,SAVE,  StNum,IDLE, StNum,IDLE
 STM_ROW EvStat,  StStat,SDISP, StStat,SCAN,  StNum,IDLE, StNum,IDLE
 STM_ROW EvNum,   StNum,SCAN,   StNum,NDISP,  StNum,IDLE, StNum,IDLE
 STM_ROW EvUp,    StNum,NUMINC, StStat,STINC, StNum,IDLE, StNum,IDLE
 STM_ROW EvRest,  StNum,LOAD,   StNum,LOAD,   StNum,IDLE, StNum,IDLE
 STM_ROW EvLeft,  StNum,PRVSW,  StNum,PRVSW,  StNum,IDLE, StNum,IDLE
 STM_ROW EvRight, StNum,NXTSW,  StNum,NXTSW,  StNum,IDLE, StNum,IDLE
 STM_ROW EvDown,  StNum,NUMDEC, StStat,STDEC, StNum,IDLE, StNum,IDLE
 STM_ROW EvValue, StNum,NUMFDR, StStat,STFDR, StNum,IDLE, StNum,IDLE

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

	lda	#0		;default values
	sta	STT		;
	sta	STTA		;
	sta	STTB		;
	sta	STTC		;
	sta	STTD		;
	sta	STTE		;
	sta	STTF		;
	sta	STTG		;
	sta	STTH		;
	sta	NUM 		;
	sta	NUMA 		;
	sta	NUMB 		;
	sta	NUMC 		;
	sta	NUMD 		;
	sta	NUME 		;
	sta	NUMF 		;
	sta	NUMG 		;
	sta	NUMH 		;
	sta	SWNUM		;

	X0_LO			;default latch strobe for
				; expansion board

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "       McLachlan"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
        LCD_PUT_S "v0.1  Controller"

	jsr	DELAY_1SEC
	jsr	LCD_CLEAR
	jsr	LED_INIT

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
        LCD_PUT_S " CH=    NUM=    "

	jsr	LOAD		;get stored parameters/display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment status for selected switch

STINC:	lda	STT
	cmp	#$9F
	beq	SIAA
	cmp	#$CF
	beq	SIAB
	cmp	#$FC
	beq	SIAC
        inca			;increment
	jmp	SIAD
SIAA:	lda	#$B0
	jmp	SIAD
SIAB:	lda	#$FA
	jmp	SIAD
SIAC:	lda	#$90
SIAD:	sta     STT		;save new assignment

	ldx     SWNUM		;branch off current switch
	cpx	#0              ;
        beq     SIA             ;...if A
	cpx	#1            	;
        beq     SIB             ;...if B
	cpx	#2            	;
        beq     SIC             ;...if C
	cpx	#3            	;
        beq     SID             ;...if D
	cpx	#4            	;
        beq     SIE             ;...if E
	cpx	#5            	;
        beq     SIF             ;...if F
	cpx	#6            	;
        beq     SIG             ;...if G
	cpx	#7            	;
        beq     SIH             ;...if H

        ldx     #0	        ;should never get here
        stx     SWNUM		;

SIA:	sta     STTA		;save new assignment
        jmp     SIDISP		;go update display

SIB:    sta     STTB		;save new assignment
        jmp     SIDISP          ;go update display

SIC:    sta     STTC		;save new assignment
        jmp     SIDISP          ;go update display

SID:    sta     STTD		;save new assignment
        jmp     SIDISP          ;go update display

SIE:    sta     STTE		;save new assignment
        jmp     SIDISP          ;go update display

SIF:    sta     STTF		;save new assignment
        jmp     SIDISP          ;go update display

SIG:    sta     STTG		;save new assignment
        jmp     SIDISP          ;go update display

SIH:    sta     STTH		;save new assignment

SIDISP:	jsr	NDISP
	jsr     SDISP           ;update display
        rts

;--- Decrement status for selected switch

STDEC:	lda	STT
	cmp	#$90
	beq	SDAA
	cmp	#$B0
	beq	SDAB
	cmp	#$FA
	beq	SDAC
        deca			;decrement
	jmp	SDAD
SDAA:	lda	#$FC
	jmp	SDAD
SDAB:	lda	#$9F
	jmp	SDAD
SDAC:	lda	#$CF
SDAD:	sta     STT		;save new assignment

	ldx     SWNUM		;branch off current switch
	cpx	#0              ;
        beq     SDA             ;...if A
	cpx	#1            	;
        beq     SDB             ;...if B
	cpx	#2            	;
        beq     SDC             ;...if C
	cpx	#3            	;
        beq     SDD             ;...if D
	cpx	#4            	;
        beq     SDE             ;...if E
	cpx	#5            	;
        beq     SDF             ;...if F
	cpx	#6            	;
        beq     SDG             ;...if G
	cpx	#7            	;
        beq     SDH             ;...if H

        ldx     #0	        ;should never get here
        stx     SWNUM		;

SDA:    sta     STTA		;save new assignment
        jmp     SDDISP          ;go update display

SDB:    sta     STTB		;save new assignment
        jmp     SDDISP          ;go update display

SDC:    sta     STTC		;save new assignment
        jmp     SDDISP          ;go update display

SDD:    sta     STTD		;save new assignment
        jmp     SDDISP          ;go update display

SDE:    sta     STTE		;save new assignment
        jmp     SDDISP          ;go update display

SDF:    sta     STTF		;save new assignment
        jmp     SDDISP          ;go update display

SDG:    sta     STTG		;save new assignment
        jmp     SDDISP          ;go update display

SDH:    sta     STTH		;save new assignment

SDDISP:	jsr	NDISP
	jsr     SDISP           ;update display
        rts

;--- Select status with fader

STFDR:	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	add	#$80		;add 128 (to get 128-255 range)
	cmp	#$FC
	bhi	SFEND
	cmp	#$FA
	blo	SFAA
	jmp	SFAC

SFAA:	cmp	#$CF
	bhi	SFEND
	cmp	#$B0
	blo	SFAB
	jmp	SFAC

SFAB:	cmp	#$9F
	bhi	SFEND
	cmp	#$90
	blo	SFEND

SFAC:	sta     STT		;save new assignment

	ldx	SWNUM		;branch off current switch
	cpx	#0              ;
	beq	SFA		;...if A
	cpx	#1              ;
	beq	SFB		;...if B
	cpx	#2              ;
	beq	SFC		;...if C
	cpx	#3              ;
	beq	SFD		;...if D
	cpx	#4              ;
	beq	SFE		;...if E
	cpx	#5              ;
	beq	SFF		;...if F
	cpx	#6              ;
	beq	SFG		;...if G
	cpx	#7              ;
	beq	SFH		;...if H

	ldx	#0              ;should never get here
        stx     SWNUM		;

SFA:	sta	STTA		;save for A
	jmp	SFI		;jump...

SFB:	sta	STTB		;save for B
	jmp	SFI		;jump...

SFC:	sta	STTC		;save for C
	jmp	SFI		;jump...

SFD:	sta	STTD		;save for D
	jmp	SFI		;jump...

SFE:	sta	STTE		;save for E
	jmp	SFI		;jump...

SFF:	sta	STTF		;save for F
	jmp	SFI		;jump...

SFG:	sta	STTG		;save for G
	jmp	SFI		;jump...

SFH:	sta	STTH		;save for H

SFI:	jsr	NDISP
	jsr	SDISP		;update display
SFEND:	rts

;--- Increment number for selected switch

NUMINC:	lda     NUM		;fetch current assignment
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	NUM		;save new value

	ldx     SWNUM		;branch off current switch
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
        stx     SWNUM           ;

NIA:	sta     NUMA            ;save new assignment
        jmp     NIDISP          ;go update display

NIB:	sta     NUMB            ;save new assignment
        jmp     NIDISP          ;go update display

NIC:	sta     NUMC            ;save new assignment
        jmp     NIDISP          ;go update display

NID:	sta     NUMD            ;save new assignment
        jmp     NIDISP          ;go update display

NIE:	sta     NUME            ;save new assignment
        jmp     NIDISP          ;go update display

NIF:	sta     NUMF            ;save new assignment
        jmp     NIDISP          ;go update display

NIG:	sta     NUMG            ;save new assignment
        jmp     NIDISP          ;go update display

NIH:	sta     NUMH            ;save new assignment

NIDISP:	jsr     NDISP           ;update display
        rts

;--- Decrement number for selected switch

NUMDEC:	lda     NUM		;fetch current assignment
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	NUM		;save new value

	ldx     SWNUM		;branch off current switch
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
        stx     SWNUM           ;

NDA:	sta     NUMA            ;save new note assignment
        jmp     NDDISP          ;go update display

NDB:	sta     NUMB            ;save new note assignment
        jmp     NDDISP          ;go update display

NDC:	sta     NUMC            ;save new note assignment
        jmp     NDDISP          ;go update display

NDD:	sta     NUMD            ;save new note assignment
        jmp     NDDISP          ;go update display

NDE:	sta     NUME            ;save new note assignment
        jmp     NDDISP          ;go update display

NDF:	sta     NUMF            ;save new note assignment
        jmp     NDDISP          ;go update display

NDG:	sta     NUMG            ;save new note assignment
        jmp     NDDISP          ;go update display

NDH:	sta     NUMH            ;save new note assignment

NDDISP:	jsr     NDISP           ;update display
        rts

;--- Select number with fader

NUMFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	sta	NUM		;save new value

	ldx	SWNUM		;branch off cur relay
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
        stx     SWNUM           ;

NFA:	sta	NUMA	 	;save note for Relay A
	jmp	NFI		;jump...

NFB:	sta	NUMB		;save note for Relay B
	jmp	NFI		;jump...

NFC:	sta	NUMC		;save note for Relay C
	jmp	NFI		;jump...

NFD:	sta	NUMD		;save note for Relay D
	jmp	NFI		;jump...

NFE:	sta	NUME		;save note for Relay E
	jmp	NFI		;jump...

NFF:	sta	NUMF		;save note for Relay F
	jmp	NFI		;jump...

NFG:	sta	NUMG		;save note for Relay G
	jmp	NFI		;jump...

NFH:	sta	NUMH		;save note for Relay H

NFI:	jsr	NDISP		;update display
        rts

;--- Select next switch

NXTSW:	lda	SWNUM		;fetch current switch
	inca			;increment
        and     #$07            ;constrain to 0-7
        sta     SWNUM           ;store new value
	jsr	XDISP		;update display
	rts

;--- Select previous switch

PRVSW:	lda	SWNUM		;fetch current switch
	deca			;decrement
        and     #$07            ;constrain to 0-7
        sta     SWNUM           ;store new value
	jsr	XDISP		;update display
	rts

;--- Save all parameters to EEPROM

SAVE:	lda	#2		;notify user
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "Storing!      "
	jsr	DELAY_1SEC

	lda	#0
	ldx	STTA
        jsr     EE_WRITE        ;store it
	lda	#1
	ldx	STTB
        jsr     EE_WRITE        ;store it
	lda	#2
	ldx	STTC
        jsr     EE_WRITE        ;store it
	lda	#3
	ldx	STTD
        jsr     EE_WRITE        ;store it
	lda	#4
	ldx	STTE
        jsr     EE_WRITE        ;store it
	lda	#5
	ldx	STTF
        jsr     EE_WRITE        ;store it
	lda	#6
	ldx	STTG
        jsr     EE_WRITE        ;store it
	lda	#7
	ldx	STTH
        jsr     EE_WRITE        ;store it

	lda	#8
	ldx	NUMA		;
        jsr     EE_WRITE        ;store it
	lda	#9
	ldx	NUMB		;
        jsr     EE_WRITE        ;store it
	lda	#10
	ldx	NUMC		;
        jsr     EE_WRITE        ;store it
	lda	#11
	ldx	NUMD		;
        jsr     EE_WRITE        ;store it
	lda	#12
	ldx	NUME		;
        jsr     EE_WRITE        ;store it
	lda	#13
	ldx	NUMF		;
        jsr     EE_WRITE        ;store it
	lda	#14
	ldx	NUMG		;
        jsr     EE_WRITE        ;store it
	lda	#15
	ldx	NUMH		;
        jsr     EE_WRITE        ;store it
	
	lda	#16
	ldx	SWNUM		;
        jsr     EE_WRITE        ;store it
	lda	#17
	ldx	STT		;
        jsr     EE_WRITE        ;store it
	lda	#18
	ldx	NUM		;
        jsr     EE_WRITE        ;store it

	jsr	SDISP		;reset status display
        rts

;--- Load preset parameters at powerup

LOAD:	lda	#2		;notify user
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "Restoring!    "
	jsr	DELAY_1SEC

	lda	#0		;
	jsr	EE_READ 	;fetch value
	sta	STTA		;store value
	lda	#1		;
	jsr	EE_READ 	;fetch value
	sta	STTB		;store value
	lda	#2		;
	jsr	EE_READ 	;fetch value
	sta	STTC		;store value
	lda	#3		;
	jsr	EE_READ 	;fetch value
	sta	STTD		;store value
	lda	#4		;
	jsr	EE_READ 	;fetch value
	sta	STTE		;store value
	lda	#5		;
	jsr	EE_READ 	;fetch value
	sta	STTF		;store value
	lda	#6		;
	jsr	EE_READ 	;fetch value
	sta	STTG		;store value
	lda	#7		;
	jsr	EE_READ 	;fetch value
	sta	STTH		;store value

	lda	#8		;
	jsr	EE_READ		;fetch value
	sta	NUMA		;store value
	lda	#9		;
	jsr	EE_READ		;fetch value
	sta	NUMB		;store value
	lda	#10		;
	jsr	EE_READ		;fetch value
	sta	NUMC		;store value
	lda	#11		;
	jsr	EE_READ		;fetch value
	sta	NUMD		;store value
	lda	#12		;
	jsr	EE_READ		;fetch value
	sta	NUME		;store value
	lda	#13		;
	jsr	EE_READ		;fetch value
	sta	NUMF		;store value
	lda	#14		;
	jsr	EE_READ		;fetch value
	sta	NUMG		;store value
	lda	#15		;
	jsr	EE_READ		;fetch value
	sta	NUMH		;store value

	lda	#16		;
	jsr	EE_READ		;fetch value
	sta	SWNUM		;store value
	lda	#17		;
	jsr	EE_READ		;fetch value
	sta	STT		;store value
	lda	#18		;
	jsr	EE_READ		;fetch value
	sta	NUM		;store value

	jsr	XDISP		;restore display
        rts

;--- Scan key matrix and transmit notes

SCAN:	lda	#$FE		;select column 0
	jsr	SPI_IO 		;
	X0_HI                   ;latch data
	X0_LO                   ;

        RD_DATA                 ;load rows
        sta     TEMP            ;buffer this temporarily

	lda	#$FF		;turn off this column
	jsr	SPI_IO 		;
	X0_HI                   ;latch data
	X0_LO			;

	lda	TEMP		;any changes?
	eor	KEYS		;
        cmp     #$00            ;
	FAR_BEQ SDUN		;no? branch...
	sta	KEYCHG		;yes? switch changes-->KEYCHG

	lda	KEYS		;old switch status-->OLDCOL
        sta     OLDCOL          ;

	lda	TEMP		;fetch new column data
        sta     KEYS            ;update history

        ;--- bit 7

S7:	tst	KEYCHG		;has this key changed?
	bpl	S6		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S7ON		;yes? key is now on! branch...
	jmp	S7OFF		;jump...

S7ON:   lda	#14
	jsr	LED_ON
	lda	STTH
	jsr	MIDI_PUT
	lda	STTH
	cmp	#$CF
	bhi	S6
	lda	NUMH
	jsr	MIDI_PUT	
	lda	STTH
	cmp	#$BF
	bhi	S6
	lda	#127
	jsr	MIDI_PUT	
	jmp	S6
	
S7OFF:	lda	#14
	jsr	LED_OFF
	lda	STTH
	cmp	#$BF
	bhi	S6
	jsr	MIDI_PUT
	lda	NUMH
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

        ;--- bit 6

S6:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S5		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S6ON		;yes? key is now on! branch...
	jmp	S6OFF		;jump...

S6ON:   lda	#11
	jsr	LED_ON
	lda	STTG
	jsr	MIDI_PUT
	lda	STTG
	cmp	#$CF
	bhi	S5
	lda	NUMG
	jsr	MIDI_PUT	
	lda	STTG
	cmp	#$BF
	bhi	S5
	lda	#127
	jsr	MIDI_PUT	
	jmp	S5
	
S6OFF:	lda	#11
	jsr	LED_OFF
	lda	STTG
	cmp	#$BF
	bhi	S5
	jsr	MIDI_PUT
	lda	NUMG
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

        ;--- bit 5

S5:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S4		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S5ON		;yes? key is now on! branch...
	jmp	S5OFF		;jump...

S5ON:   lda	#7
	jsr	LED_ON
	lda	STTF
	jsr	MIDI_PUT
	lda	STTF
	cmp	#$CF
	bhi	S4
	lda	NUMF
	jsr	MIDI_PUT	
	lda	STTF
	cmp	#$BF
	bhi	S4
	lda	#127
	jsr	MIDI_PUT	
	jmp	S4
	
S5OFF:	lda	#7
	jsr	LED_OFF
	lda	STTF
	cmp	#$BF
	bhi	S4
	jsr	MIDI_PUT
	lda	NUMF
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT
	
        ;--- bit 4

S4:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S3		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S4ON		;yes? key is now on! branch...
	jmp	S4OFF		;jump...

S4ON:   lda	#2
	jsr	LED_ON
	lda	STTE
	jsr	MIDI_PUT
	lda	STTE
	cmp	#$CF
	bhi	S3
	lda	NUME
	jsr	MIDI_PUT	
	lda	STTE
	cmp	#$BF
	bhi	S3
	lda	#127
	jsr	MIDI_PUT	
	jmp	S3
	
S4OFF:	lda	#2
	jsr	LED_OFF
	lda	STTE
	cmp	#$BF
	bhi	S3
	jsr	MIDI_PUT
	lda	NUME
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT
	
        ;--- bit 3

S3:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S2		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S3ON		;yes? key is now on! branch...
	jmp	S3OFF		;jump...

S3ON:   lda	#1
	jsr	LED_ON
	lda	STTD
	jsr	MIDI_PUT
	lda	STTD
	cmp	#$CF
	bhi	S2
	lda	NUMD
	jsr	MIDI_PUT	
	lda	STTD
	cmp	#$BF
	bhi	S2
	lda	#127
	jsr	MIDI_PUT	
	jmp	S2
	
S3OFF:	lda	#1
	jsr	LED_OFF
	lda	STTD
	cmp	#$BF
	bhi	S2
	jsr	MIDI_PUT
	lda	NUMD
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

        ;--- bit 2

S2:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S1		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S2ON		;yes? key is now on! branch...
	jmp	S2OFF		;jump...

S2ON:   lda	#4
	jsr	LED_ON
	lda	STTC
	jsr	MIDI_PUT
	lda	STTC
	cmp	#$CF
	bhi	S1
	lda	NUMC
	jsr	MIDI_PUT	
	lda	STTC
	cmp	#$BF
	bhi	S1
	lda	#127
	jsr	MIDI_PUT	
	jmp	S1
	
S2OFF:	lda	#4
	jsr	LED_OFF
	lda	STTC
	cmp	#$BF
	bhi	S1
	jsr	MIDI_PUT
	lda	NUMC
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

        ;--- bit 1

S1:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	S0		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S1ON		;yes? key is now on! branch...
	jmp	S1OFF		;jump...

S1ON:   lda	#8
	jsr	LED_ON
	lda	STTB
	jsr	MIDI_PUT
	lda	STTB
	cmp	#$CF
	bhi	S0
	lda	NUMB
	jsr	MIDI_PUT	
	lda	STTB
	cmp	#$BF
	bhi	S0
	lda	#127
	jsr	MIDI_PUT	
	jmp	S0
	
S1OFF:	lda	#8
	jsr	LED_OFF
	lda	STTB
	cmp	#$BF
	bhi	S0
	jsr	MIDI_PUT
	lda	NUMB
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

        ;--- bit 0

S0:	lda	KEYCHG		;shift this key into position
        lsla                    ;
        sta     KEYCHG          ;
        lda     OLDCOL          ;
        lsla                    ;
        sta     OLDCOL          ;

	tst	KEYCHG		;has this key changed?
	bpl	SDUN		;no? branch...

	tst	OLDCOL		;was old status off?
	bmi	S0ON		;yes? key is now on! branch...
	jmp	S0OFF		;jump...

S0ON:   lda	#13
	jsr	LED_ON
	lda	STTA
	jsr	MIDI_PUT
	lda	STTA
	cmp	#$CF
	bhi	SDUN
	lda	NUMA
	jsr	MIDI_PUT	
	lda	STTA
	cmp	#$BF
	bhi	SDUN
	lda	#127
	jsr	MIDI_PUT	
	jmp	SDUN
	
S0OFF:	lda	#13
	jsr	LED_OFF
	lda	STTA
	cmp	#$BF
	bhi	SDUN
	jsr	MIDI_PUT
	lda	NUMA
	jsr	MIDI_PUT	
	lda	#0
	jsr	MIDI_PUT	

SDUN:	rts

;--- Update display for changing status

SDISP:	lda	#7		;clear NUM arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	STT
	cmp	#$F0
	bhi	SDSA

	lda	#5		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	STT		;get status
	and	#$0F		;get channel nibble
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
	jmp	SDSB

SDSA:	lda	#4		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "--"

SDSB:	lda     #2              ;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;

	lda     STT		;branch off status code number
	cmp	#$FA		;
	FAR_BEQ	SSTART		;...if Start message
	cmp	#$FB		;
	FAR_BEQ	SCONT		;...if Continue message
	cmp	#$FC		;
	FAR_BEQ	SSTOP		;...if Stop message

	and	#$F0		;get status nibble
	cmp	#$90            ;
        beq     SNOTE           ;...if note message
	cmp	#$B0           	;
        beq     SCTL            ;...if controller message
	cmp	#$C0           	;
        beq     SPROG           ;...if program change message

        lda     #$90	        ;should never get here
        sta     STT             ;

SNOTE:	LCD_PUT_S "NOTE          "
	rts

SCTL:	LCD_PUT_S "CONTROLLER    "
	rts

SPROG:	LCD_PUT_S "PROGRAM CHANGE"
	rts

SSTART:	LCD_PUT_S "START         "
	rts

SCONT:	LCD_PUT_S "CONTINUE      "
	rts

SSTOP:	LCD_PUT_S "STOP          "
	rts

;--- Update display for changing number

NDISP:	lda	#0		;clear CH arrow
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#7		;place NUM arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;

	lda	STT		;check status
	cmp	#$F0		;
	bhi	NDDA		;no data byte? branch
 
        lda     #14             ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	NUM		;fetch number
	jsr	LCD_PUT_RJ3_I	;display it
	jmp	NDEND

NDDA:	lda     #12             ;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "---"		;display it

NDEND:	rts

;--- Update display for changing switch

XDISP:	lda     #0              ;position cursor
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	SWNUM		;fetch switch number
	inca			;display as 1-8
	jsr	LCD_PUT_RJ3_I	;display it

	ldx     SWNUM		;branch off switch
	cpx	#0              ;
        beq     XDA             ;...if A
	cpx	#1            	;
        beq     XDB             ;...if B
	cpx	#2            	;
        beq     XDC             ;...if C
	cpx	#3            	;
        beq     XDD             ;...if D
	cpx	#4            	;
        beq     XDE             ;...if E
	cpx	#5            	;
        beq     XDF             ;...if F
	cpx	#6            	;
        beq     XDG             ;...if G
	cpx	#7            	;
        beq     XDH             ;...if H

        ldx     #0	        ;should never get here
        stx     SWNUM           ;

XDA:    lda	STTA
	sta	STT
	lda	NUMA
	sta	NUM
	jmp	XDDISP

XDB:    lda	STTB
	sta	STT
	lda	NUMB
	sta	NUM
	jmp	XDDISP

XDC:    lda	STTC
	sta	STT
	lda	NUMC
	sta	NUM
	jmp	XDDISP

XDD:    lda	STTD
	sta	STT
	lda	NUMD
	sta	NUM
	jmp	XDDISP

XDE:    lda	STTE
	sta	STT
	lda	NUME
	sta	NUM
	jmp	XDDISP

XDF:    lda	STTF
	sta	STT
	lda	NUMF
	sta	NUM
	jmp	XDDISP

XDG:    lda	STTG
	sta	STT
	lda	NUMG
	sta	NUM
	jmp	XDDISP

XDH:    lda	STTH
	sta	STT
	lda	NUMH
	sta	NUM

XDDISP:	jsr	SDISP
	jsr	NDISP
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


