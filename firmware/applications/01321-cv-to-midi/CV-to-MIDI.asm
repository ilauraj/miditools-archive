;===============================================================;
;											;
;       00135.ASM      								;
;	CV-to-MIDI (Upgraded Triple CV-MIDI)	          		;
;											;
;	This device translates four analog voltages into four		;
;	selectable MIDI continuous controllers.				;
;											;
;===============================================================;
;											;
;	Operation:									;	
;											;
;	HOW DO I...									;
;											;
;	...SET THE TRANSMIT CHANNEL FOR EACH CONTROLLER?        	;
;	Press the PARAM SELECT key until the underline cursor		;
;	is under the desired channel parameter. Press the +/-		;
;	key to set the desired channel: 1-16				;
;											;
;	...SET THE CONTROLLER NUMBER FOR EACH CONTROLLER?       	;
;	Press the PARAM SELECT key until the underline cursor		;
;	is under the desired controller number parameter.		;
;	Press the +/- key to set the desired controller number:	;
;	0-127.									;
;											;
;	...SELECT THE ANALOG VOLTAGE FOR EACH CONTROLLER?       	;
;	Press the PARAM SELECT key until the underline cursor		;
;	is under the desired voltage parameter. Press the +/-		;
;	key to select the desired analog votage source: 1-3.		;
;											;
;	...DISABLE THE TRANSLATION FOR A GIVEN CONTROLLER?      	;
;	Press the DISABLE/ENABLE key (A, B, C, D) for the desired	;
;	controller. Press again to enable the translation.		;
;											;
;	...SAVE ALL PARAMETERS?							;
;	Press the SAVE key. All translation parameters are		;
;	saved to nonvolatile EEPROM. They will be recalled		;
;	at powerup.									;
;											;
;	...OPERATE THE DEVICE?							;
;	Four control voltages (0-5VDC) are connected to the		;
;	four ADC inputs (ADC0-ADC3). The digitized voltages		;
;	are mapped to MIDI controller messages according to the	;
;	controller parameters set (voltage source, MIDI channel,	;
;	and MIDI controller number). Incoming MIDI messages are	;
;	ignored. Running status	is implemented.				;
;											;
;---------------------------------------------------------------;
;											;
;	LCD Screen:									;
;											;
;	|CNNVCNNVCNNVCNNV|							;
;	|xdatxdatxdatxdat|							;
;											;
;	where:									;
;											;
;	C=MIDI Transmit Channel (0H-7H)					;
;	NN=MIDI Controller Number (00H-7FH)					;
;	V=Voltage Source (1-3)							;
;	x=Controller Disable Indicator (">"=DISABLE)			;
;	dat=MIDI Controller Data Transmitted (0-127)			;
;											;
;---------------------------------------------------------------;
;											;
;	Hardware:									;
;											;
;	This MIDItool uses a modified CPU board and a Human		;
;	Interface board.								;
;											;
;---------------------------------------------------------------;
;											;
;	States: 									;
;											;
;	StOp		Operate							;
;											;
;	Actions:									;
;											;
;	IDLE		No action							;
;	VALINC	Increment parameter value				;
;	VALDEC	Decrement parameter value				;
;	NXTPAR	Select next parameter					;
;	TOGA		Toggle Controller A Disable status			;
;	TOGB		Toggle Controller B Disable status			;
;	TOGC		Toggle Controller C Disable status			;
;	TOGD		Toggle Controller D Disable status			;
;	SENDV0	Process change in Voltage 0				;
;	SENDV1	Process change in Voltage 1				;
;	SENDV2	Process change in Voltage 2				;
;	SENDV3	Process change in Voltage 3				;
;	SENDA		Transmit controller A message				;
;	SENDB		Transmit controller B message				;
;	SENDC		Transmit controller C message				;
;	SENDD		Transmit controller D message				;
;	SAVE		Save all paramters to memory				;
;	LOAD		Load all parameters and display them		;
;	PUTCUR	Updates cursor						;
;											;
;===============================================================  ;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

AFLAG		.DS	1	;Controller A Disable flag (1=DISABLE)
BFLAG		.DS	1	;Controller B Disable flag (1=DISABLE)
CFLAG		.DS	1	;Controller C Disable flag (1=DISABLE)
DFLAG		.DS	1	;Controller D Disable flag (1=DISABLE)
ACHAN		.DS	1	;MIDI transmit channel for controller A
BCHAN		.DS	1	;MIDI transmit channel for controller B
CCHAN		.DS	1	;MIDI transmit channel for controller C
DCHAN		.DS	1	;MIDI transmit channel for controller D
ACTL		.DS	1	;MIDI controller number for A
BCTL		.DS	1	;MIDI controller number for B
CCTL		.DS	1	;MIDI controller number for C
DCTL		.DS	1	;MIDI controller number for D
ANUM		.DS	1	;MIDI controller data for A
BNUM		.DS	1	;MIDI controller data for B
CNUM		.DS	1	;MIDI controller data for C
DNUM		.DS	1	;MIDI controller data for D
AVSIG		.DS	1	;voltage source for controller A
BVSIG		.DS	1	;voltage source for controller B
CVSIG		.DS	1	;voltage source for controller C
DVSIG		.DS	1	;voltage source for controller D
PARNUM	.DS	1	;parameter number (0-11)
RUNNING	.DS	1	;running status byte

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle	EQU	EV_IDLE
EvSave	EQU	EV_SW1_ON
EvParam	EQU	EV_SW2_ON
EvUp		EQU	EV_SW3_ON
EvDown	EQU	EV_SW4_ON
EvAtog	EQU	EV_SW5_ON
EvBtog	EQU	EV_SW6_ON
EvCtog	EQU	EV_SW7_ON
EvDtog 	EQU	EV_SW8_ON
EvV0		EQU	EV_F1_MOVE
EvV1		EQU	EV_F2_MOVE
EvV2		EQU	EV_F3_MOVE
EvV3		EQU	EV_F4_MOVE

;--- Build State Matrix

        STM_BEGIN

;                  State 0: StOp  			   Not
;	 Event	   NextSt,Act	               Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,  StOp,IDLE,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvSave,  StOp,SAVE,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvParam, StOp,NXTPAR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvUp,    StOp,VALINC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvDown,  StOp,VALDEC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvAtog,  StOp,TOGA,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvBtog,  StOp,TOGB,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvCtog,  StOp,TOGC,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvDtog,  StOp,TOGD,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvV0,    StOp,SENDV0, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvV1,    StOp,SENDV1, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvV2,    StOp,SENDV2, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvV3,    StOp,SENDV3, StOp,IDLE, StOp,IDLE, StOp,IDLE

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

;--- Initialize running status

	lda	#$00			;
	sta	RUNNING		;

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY
	LCD_PUT_S "   CV-to-MIDI   "

	lda	#1
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S " Translator v.1 "	

	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

;--- Turn LCD cursor ON

	lda	#1		;
	jsr	LCD_CURSOR	;

;--- Recall parameters and set up display

	jsr	LOAD		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Increment parameter value

VALINC:
	lda	PARNUM	;check parameter number
	cmp	#1		;is it Ctl A?
	FAR_BEQ	VIA	;yes? branch...
	cmp	#2		;is it Voltage A?
	FAR_BEQ	VIB	;yes? branch...
	cmp	#3		;is it Chan B?
	FAR_BEQ	VIC	;yes? branch...
	cmp	#4		;is it Ctl B?
	FAR_BEQ	VID	;yes? branch...
	cmp	#5		;is it Voltage B?
	FAR_BEQ	VIE	;yes? branch...
	cmp	#6		;is it Chan C?
	FAR_BEQ	VIF	;yes? branch...
	cmp	#7		;is it Ctl C?
	FAR_BEQ	VIG	;yes? branch...
	cmp	#8		;is it Voltage C?
	FAR_BEQ	VIH	;yes? branch...
	cmp	#9		;is it Chan D?
	FAR_BEQ	VII	;yes? branch...
	cmp	#10		;is it Ctl D?
	FAR_BEQ	VIJ	;yes? branch...
	cmp	#11		;is it Voltage D?
	FAR_BEQ	VIK	;yes? branch...

	lda	ACHAN		;must be Channel A...
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	ACHAN		;save new value
	lda	#0		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIA:	lda	ACTL		;Controller A...
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	ACTL		;save new value
	lda	#1		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIB:	lda	AVSIG		;Voltage A...
	inca			;increment
	sta	AVSIG		;save new value
	cmp	#4		;
	blo	VIBDUN	;<4? we are done...
	lda	#0		;>=4? wrap around to 0
	sta	AVSIG		;save new value

VIBDUN:
	lda	#3		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	AVSIG		;
	inca			;display as 1-4
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIC:	lda	BCHAN		;Channel B...
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	BCHAN		;save new value
	lda	#4		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VID:	lda	BCTL		;Controller B...
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	BCTL		;save new value
	lda	#5		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIE:	lda	BVSIG		;Voltage B...
	inca			;increment
	sta	BVSIG		;save new value
	cmp	#4		;
	blo	VIEDUN	;<4? we are done...
	lda	#0		;>=4? wrap around to 0
	sta	BVSIG		;save new value

VIEDUN:
	lda	#7		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BVSIG		;
	inca			;display as 1-4
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIF:	lda	CCHAN		;Channel C...
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	CCHAN		;save new value
	lda	#8		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIG:	lda	CCTL		;Controller C...
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	CCTL		;save new value
	lda	#9		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIH:	lda	CVSIG		;Voltage C...
	inca			;increment
	sta	CVSIG		;save new value
	cmp	#4		;
	blo	VIHDUN	;<4? we are done...
	lda	#0		;>=4? wrap around to 0
	sta	CVSIG		;save new value

VIHDUN:
	lda	#11		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CVSIG		;
	inca			;display as 1-3
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts

VII:	lda	DCHAN		;Channel D...
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	DCHAN		;save new value
	lda	#12		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIJ:	lda	DCTL		;Controller D...
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DCTL		;save new value
	lda	#13		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VIK:	lda	DVSIG		;Voltage D...
	inca			;increment
	sta	DVSIG		;save new value
	cmp	#4		;
	blo	VIKDUN	;<4? we are done...
	lda	#0		;>=4? wrap around to 0
	sta	DVSIG		;save new value

VIKDUN:
	lda	#15		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DVSIG		;
	inca			;display as 1-3
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts

;--- Decrement parameter value

VALDEC:
	lda	PARNUM	;check parameter number
	cmp	#1		;is it Ctl A?
	FAR_BEQ	VDA	;yes? branch...
	cmp	#2		;is it Voltage A?
	FAR_BEQ	VDB	;yes? branch...
	cmp	#3		;is it Chan B?
	FAR_BEQ	VDC	;yes? branch...
	cmp	#4		;is it Ctl B?
	FAR_BEQ	VDD	;yes? branch...
	cmp	#5		;is it Voltage B?
	FAR_BEQ	VDE	;yes? branch...
	cmp	#6		;is it Chan C?
	FAR_BEQ	VDF	;yes? branch...
	cmp	#7		;is it Ctl C?
	FAR_BEQ	VDG	;yes? branch...
	cmp	#8		;is it Voltage C?
	FAR_BEQ	VDH	;yes? branch...
	cmp	#9		;is it Chan D?
	FAR_BEQ	VDI	;yes? branch...
	cmp	#10		;is it Ctl D?
	FAR_BEQ	VDJ	;yes? branch...
	cmp	#11		;is it Voltage D?
	FAR_BEQ	VDK	;yes? branch...

	lda	ACHAN		;must be Channel A...
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	ACHAN		;save new value
	lda	#0		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDA:	lda	ACTL		;Controller A...
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	ACTL		;save new value
	lda	#1		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDB:	lda	AVSIG		;Voltage A...
	deca			;decrement
	sta	AVSIG		;save new value
	cmp	#4		;compare to 4
	blo	VDBDUN	;<4? we are done...
	lda	#3		;>=4? wrap around to 3
	sta	AVSIG		;save new value

VDBDUN:	
	lda	#3		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	AVSIG		;
	inca			;display as 1-4
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDC:	lda	BCHAN		;Channel B...
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	BCHAN		;save new value
	lda	#4		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDD:	lda	BCTL		;Controller B...
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	BCTL		;save new value
	lda	#5		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDE:	lda	BVSIG		;Voltage B...
	deca			;decrement
	sta	BVSIG		;save new value
	cmp	#4		;compare to 4
	blo	VDEDUN	;<4? we are done...
	lda	#3		;>=4? wrap around to 3
	sta	BVSIG		;save new value

VDEDUN:
	lda	#7		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BVSIG		;
	inca			;display as 1-3
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDF:	lda	CCHAN		;Channel C...
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	CCHAN		;save new value
	lda	#8		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDG:	lda	CCTL		;Controller C...
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	CCTL		;save new value
	lda	#9		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDH:	lda	CVSIG		;Voltage C...
	deca			;decrement
	sta	CVSIG		;save new value
	cmp	#4		;compare to 4
	blo	VDHDUN	;<3? we are done...
	lda	#3		;>=3? wrap around to 3
	sta	CVSIG		;save new value

VDHDUN:
	lda	#11		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CVSIG		;
	inca			;display as 1-3
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts

VDI:	lda	DCHAN		;Channel D...
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	DCHAN		;save new value
	lda	#12		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCHAN		;
	jsr	LCD_PUT_HH	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDJ:	lda	DCTL		;Controller D...
	deca			;decrement
	and	#$7F		;constrain to 0-127
	sta	DCTL		;save new value
	lda	#13		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCTL		;
	jsr	LCD_PUT_H	;display it
	jsr	PUTCUR	;replace cursor
	rts			;

VDK:	lda	DVSIG		;Voltage D...
	deca			;decrement
	sta	DVSIG		;save new value
	cmp	#4		;compare to 4
	blo	VDKDUN	;<4? we are done...
	lda	#3		;>=4? wrap around to 3
	sta	DVSIG		;save new value

VDKDUN:
	lda	#15		;
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DVSIG		;
	inca			;display as 1-3
	jsr	LCD_PUT_I	;display it
	jsr	PUTCUR	;replace cursor
	rts

;---Select next parameter

NXTPAR:
	lda	PARNUM	;get parameter number
	inca			;increment
	sta	PARNUM	;save new value
	cmp	#12		;compare
	bne	NPDUN		;<=11? go move cursor...
	lda	#0		;>11? wrap to 0
	sta	PARNUM	;save new value

NPDUN:
	jsr	PUTCUR	;go update cursor position

;---Update cursor

PUTCUR:
	lda	PARNUM	;get parameter number
	cmp	#1		;is it Ctl A?
	beq	PCA		;yes? branch...
	cmp	#2		;is it Voltage A?
	beq	PCB		;yes? branch...
	cmp	#3		;is it Chan B?
	beq	PCC		;yes? branch...
	cmp	#4		;is it Ctl B?
	beq	PCD		;yes? branch...
	cmp	#5		;is it Voltage B?
	beq	PCE		;yes? branch...
	cmp	#6		;is it Chan C?
	beq	PCF		;yes? branch...
	cmp	#7		;is it Ctl C?
	beq	PCG		;yes? branch...
	cmp	#8		;is it Voltage C?
	beq	PCH		;yes? branch...
	cmp	#9		;is it Chan D?
	beq	PCI		;yes? branch...
	cmp	#10		;is it Ctl D?
	beq	PCJ		;yes? branch...
	cmp	#11		;is it Voltage D?
	beq	PCK		;yes? branch...

	lda	#0		;must be Chan A...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCA:	lda	#2		;Controller A...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;
	
PCB:	lda	#3		;Voltage A...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCC:	lda	#4		;Chan B...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCD:	lda	#6		;Controller B...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCE:	lda	#7		;Voltage B...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCF:	lda	#8		;Chan C...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCG:	lda	#10		;Controller C...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCH:	lda	#11		;Voltage C...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN

PCI:	lda	#12		;Chan D...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCJ:	lda	#14		;Controller D...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor
	jmp	PCDUN		;

PCK:	lda	#15		;Voltage D...
	ldx	#0		;
	jsr	LCD_GOTOXY	;position cursor

PCDUN:	rts

;---Toggle Controller A Disable status

TOGA:
	lda	AFLAG		;get flag
	eor	#$01		;toggle it
	sta	AFLAG		;save new status
	beq	TGAA		;=0? jump...

	lda	#0		;disabled? show indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S ">"	;place indicator A
	jmp	TGADUN	;finito

TGAA:
	lda	#0		;no? clear indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " "	;clear indicator A

TGADUN:
	jsr	PUTCUR	;replace cursor
	rts

;---Toggle Controller B Disable status

TOGB:
	lda	BFLAG		;get flag
	eor	#$01		;toggle it
	sta	BFLAG		;save new status
	beq	TGBA		;=0? jump...

	lda	#4		;disabled? show indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S ">"	;place indicator B
	jmp	TGBDUN	;finito

TGBA:
	lda	#4		;no? clear indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " "	;clear indicator B

TGBDUN:
	jsr	PUTCUR	;replace cursor
	rts

;---Toggle Controller C Disable status

TOGC:
	lda	CFLAG		;get flag
	eor	#$01		;toggle it
	sta	CFLAG		;save new status
	beq	TGCA		;=0? jump...

	lda	#8		;disabled? show indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S ">"	;place indicator C
	jmp	TGCDUN	;finito

TGCA:
	lda	#8		;no? clear indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " "	;clear indicator C

TGCDUN:
	jsr	PUTCUR	;replace cursor
	rts

;---Toggle Controller D Disable status

TOGD:
	lda	DFLAG		;get flag
	eor	#$01		;toggle it
	sta	DFLAG		;save new status
	beq	TGDA		;=0? jump...

	lda	#12		;disabled? show indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S ">"	;place indicator D
	jmp	TGDDUN	;finito

TGDA:
	lda	#12		;no? clear indicator
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " "	;clear indicator D

TGDDUN:
	jsr	PUTCUR	;replace cursor
	rts

;---Process change in Voltage 0

SENDV0:
	lda	AVSIG		;get voltage source number
	cmp	#0		;compare to 0
	bne	SV0B		;not =0? move on...
	lda	F1		;get voltage value
	lsra			;constrain to 0-127
	sta	ANUM		;save data value
	jsr	SENDA		;send MIDI message

SV0B:	lda	BVSIG		;reload source number
	cmp	#0		;compare to 0
	bne	SV0C		;not =0? move on...
	lda	F1		;get voltage value
	lsra			;constrain to 0-127
	sta	BNUM		;save data value
	jsr	SENDB		;send MIDI message

SV0C:	lda	CVSIG		;reload source number
	cmp	#0		;compare to 0
	bne	SV0D		;not =0? move on...
	lda	F1		;get voltage value
	lsra			;constrain to 0-127
	sta	CNUM		;save data value
	jsr	SENDC		;send MIDI message

SV0D:	lda	DVSIG		;reload source number
	cmp	#0		;compare to 0
	bne	SV0DUN		;not =0? move on...
	lda	F1		;get voltage value
	lsra			;constrain to 0-127
	sta	DNUM		;save data value
	jsr	SENDD		;send MIDI message

SV0DUN:	rts

;---Process change in Voltage 1

SENDV1:
	lda	AVSIG		;get voltage source number
	cmp	#1		;compare to 1
	bne	SV1B		;not =1? move on...
	lda	F2		;get voltage value
	lsra			;constrain to 0-127
	sta	ANUM		;save data value
	jsr	SENDA		;send MIDI message

SV1B:	lda	BVSIG		;reload source number
	cmp	#1		;compare to 1
	bne	SV1C		;not =1? move on...
	lda	F2		;get voltage value
	lsra			;constrain to 0-127
	sta	BNUM		;save data value
	jsr	SENDB		;send MIDI message

SV1C:	lda	CVSIG		;reload source number
	cmp	#1		;compare to 1
	bne	SV1D		;not =1? move on...
	lda	F2		;get voltage value
	lsra			;constrain to 0-127
	sta	CNUM		;save data value
	jsr	SENDC		;send MIDI message

SV1D:	lda	DVSIG		;reload source number
	cmp	#1		;compare to 1
	bne	SV1DUN	;not =1? move on...
	lda	F2		;get voltage value
	lsra			;constrain to 0-127
	sta	DNUM		;save data value
	jsr	SENDD		;send MIDI message

SV1DUN:	rts

;---Process change in Voltage 2

SENDV2:
	lda	AVSIG		;get voltage source number
	cmp	#2		;compare to 2
	bne	SV2B		;not =2? move on...
	lda	F3		;get voltage value
	lsra			;constrain to 0-127
	sta	ANUM		;save data value
	jsr	SENDA		;send MIDI message

SV2B:	lda	BVSIG		;reload source number
	cmp	#2		;compare to 2
	bne	SV2C		;not =2? move on...
	lda	F3		;get voltage value
	lsra			;constrain to 0-127
	sta	BNUM		;save data value
	jsr	SENDB		;send MIDI message

SV2C:	lda	CVSIG		;reload source number
	cmp	#2		;compare to 2
	bne	SV2D		;not =2? move on...
	lda	F3		;get voltage value
	lsra			;constrain to 0-127
	sta	CNUM		;save data value
	jsr	SENDC		;send MIDI message

SV2D:	lda	DVSIG		;reload source number
	cmp	#2		;compare to 2
	bne	SV2DUN	;not =2? move on...
	lda	F3		;get voltage value
	lsra			;constrain to 0-127
	sta	DNUM		;save data value
	jsr	SENDD		;send MIDI message

SV2DUN:	rts

;---Process change in Voltage 3

SENDV3:
	lda	AVSIG		;get voltage source number
	cmp	#3		;compare to 3
	bne	SV3B		;not =3? move on...
	lda	F4		;get voltage value
	lsra			;constrain to 0-127
	sta	ANUM		;save data value
	jsr	SENDA		;send MIDI message

SV3B:	lda	BVSIG		;reload source number
	cmp	#3		;compare to 3
	bne	SV3C		;not =3? move on...
	lda	F4		;get voltage value
	lsra			;constrain to 0-127
	sta	BNUM		;save data value
	jsr	SENDB		;send MIDI message

SV3C:	lda	CVSIG		;reload source number
	cmp	#3		;compare to 3
	bne	SV3D		;not =3? move on...
	lda	F4		;get voltage value
	lsra			;constrain to 0-127
	sta	CNUM		;save data value
	jsr	SENDC		;send MIDI message

SV3D:	lda	DVSIG		;reload source number
	cmp	#3		;compare to 3
	bne	SV3DUN	;not =3? move on...
	lda	F4		;get voltage value
	lsra			;constrain to 0-127
	sta	DNUM		;save data value
	jsr	SENDD		;send MIDI message

SV3DUN:	rts

;---Transmit controller A message

SENDA:
	lda	AFLAG		;check A disable flag
	bne	SADUN		;A Disabled? ignore...

	sei			;Translation Enabled? disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	ACHAN		;add channel
	cmp	RUNNING	;compare with running status
	beq	SAA		;=? skip status byte
	sta	RUNNING	;not =? save new running status
	jsr	MIDI_PUT	;send it
SAA:
	lda	ACTL		;load controller number
	jsr	MIDI_PUT	;send it
	lda	ANUM		;fetch controller data value
	jsr	MIDI_PUT	;send it as mod wheel value
	cli			;enable interrupts
	lda	#3		;display value
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	ANUM		;
	jsr	LCD_PUT_RJ3_I	;
	jsr	PUTCUR	;replace cursor

SADUN:
	rts

;---Transmit controller B message

SENDB:
	lda	BFLAG		;check B disable flag
	bne	SBDUN		;B Disabled? ignore...

	sei			;Translation Enabled? disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	BCHAN		;add channel
	cmp	RUNNING	;compare with running status
	beq	SBA		;=? skip status byte
	sta	RUNNING	;not =? save new running status
	jsr	MIDI_PUT	;send it
SBA:
	lda	BCTL		;load controller number
	jsr	MIDI_PUT	;send it
	lda	BNUM		;fetch controller data value
	jsr	MIDI_PUT	;send it as mod wheel value
	cli			;enable interrupts
	lda	#7		;display value
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BNUM		;
	jsr	LCD_PUT_RJ3_I	;
	jsr	PUTCUR	;replace cursor

SBDUN:
	rts

;---Transmit controller C message

SENDC:
	lda	CFLAG		;check C disable flag
	bne	SCDUN		;C Disabled? ignore...

	sei			;Translation Enabled? disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	CCHAN		;add channel
	cmp	RUNNING		;compare with running status
	beq	SCA		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SCA:
	lda	CCTL		;load controller number
	jsr	MIDI_PUT	;send it
	lda	CNUM		;fetch controller data value
	jsr	MIDI_PUT	;send it as mod wheel value
	cli			;enable interrupts
	lda	#11		;display value
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CNUM		;
	jsr	LCD_PUT_RJ3_I	;
	jsr	PUTCUR		;replace cursor

SCDUN:
	rts

;---Transmit controller D message

SENDD:
	lda	DFLAG		;check D disable flag
	bne	SDDUN		;D Disabled? ignore...

	sei			;Translation Enabled? disable interrupts
	lda	#$B0		;load MIDI Status nibble
	add	DCHAN		;add channel
	cmp	RUNNING	;compare with running status
	beq	SDA		;=? skip status byte
	sta	RUNNING		;not =? save new running status
	jsr	MIDI_PUT	;send it
SDA:
	lda	DCTL		;load controller number
	jsr	MIDI_PUT	;send it
	lda	DNUM		;fetch controller data value
	jsr	MIDI_PUT	;send it as mod wheel value
	cli			;enable interrupts
	lda	#15		;display value
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DNUM		;
	jsr	LCD_PUT_RJ3_I	;
	jsr	PUTCUR		;replace cursor

SDDUN:
	rts

;---Save all paramters to memory

SAVE:
	lda	#0
	ldx	ACHAN
        jsr     EE_WRITE        ;store it
	lda	#1
	ldx	BCHAN
        jsr     EE_WRITE        ;store it
	lda	#2
	ldx	CCHAN
        jsr     EE_WRITE        ;store it
	lda	#3
	ldx	DCHAN
        jsr     EE_WRITE        ;store it
	lda	#4
	ldx	ACTL
        jsr     EE_WRITE        ;store it
	lda	#5
	ldx	BCTL
        jsr     EE_WRITE        ;store it
	lda	#6
	ldx	CCTL
        jsr     EE_WRITE        ;store it
	lda	#7
	ldx	DCTL
        jsr     EE_WRITE        ;store it
	lda	#8
	ldx	ANUM
        jsr     EE_WRITE        ;store it
	lda	#9
	ldx	BNUM
        jsr     EE_WRITE        ;store it
	lda	#10
	ldx	CNUM
        jsr     EE_WRITE        ;store it
	lda	#11
	ldx	DNUM
        jsr     EE_WRITE        ;store it
	lda	#12
	ldx	AVSIG
        jsr     EE_WRITE        ;store it
	lda	#13
	ldx	BVSIG
        jsr     EE_WRITE        ;store it
	lda	#14
	ldx	CVSIG
        jsr     EE_WRITE        ;store it
	lda	#15
	ldx	DVSIG
        jsr     EE_WRITE        ;store it

	lda	#15
	jsr	LED_ON
	jsr	DELAY_1SEC
	lda	#15
	jsr	LED_OFF

	rts

;---Load all parameters and display them

LOAD:
	lda	#0		;
	jsr	EE_READ 	;fetch value
	sta	ACHAN		;store value
	lda	#1		;
	jsr	EE_READ 	;fetch value
	sta	BCHAN		;store value
	lda	#2		;
	jsr	EE_READ 	;fetch value
	sta	CCHAN		;store value
	lda	#3		;
	jsr	EE_READ 	;fetch value
	sta	DCHAN		;store value
	lda	#4		;
	jsr	EE_READ 	;fetch value
	sta	ACTL		;store value
	lda	#5		;
	jsr	EE_READ 	;fetch value
	sta	BCTL		;store value
	lda	#6		;
	jsr	EE_READ 	;fetch value
	sta	CCTL		;store value
	lda	#7		;
	jsr	EE_READ 	;fetch value
	sta	DCTL		;store value
	lda	#8		;
	jsr	EE_READ 	;fetch value
	sta	ANUM		;store value
	lda	#9		;
	jsr	EE_READ 	;fetch value
	sta	BNUM		;store value
	lda	#10		;
	jsr	EE_READ 	;fetch value
	sta	CNUM		;store value
	lda	#11		;
	jsr	EE_READ 	;fetch value
	sta	DNUM		;store value
	lda	#12		;
	jsr	EE_READ 	;fetch value
	sta	AVSIG		;store value
	lda	#13		;
	jsr	EE_READ 	;fetch value
	sta	BVSIG		;store value
	lda	#14		;
	jsr	EE_READ 	;fetch value
	sta	CVSIG		;store value
	lda	#15		;
	jsr	EE_READ 	;fetch value
	sta	DVSIG		;store value

	lda	#0		;display Chan A
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACHAN		;
	jsr	LCD_PUT_HH	;
	
	lda	#1		;display Controller A
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	ACTL		;
	jsr	LCD_PUT_H	;

	lda	#3		;display Voltage A
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	AVSIG		;
	inca
	jsr	LCD_PUT_I	;

	lda	#4		;display Chan B
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCHAN		;
	jsr	LCD_PUT_HH	;
	
	lda	#5		;display Controller B
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BCTL		;
	jsr	LCD_PUT_H	;

	lda	#7		;display Voltage B
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	BVSIG		;
	inca
	jsr	LCD_PUT_I	;

	lda	#8		;display Chan C
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCHAN		;
	jsr	LCD_PUT_HH	;
	
	lda	#9		;display Controller C
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CCTL		;
	jsr	LCD_PUT_H	;

	lda	#11		;display Voltage C
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	CVSIG		;
	inca
	jsr	LCD_PUT_I	;

	lda	#12		;display Chan D
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCHAN		;
	jsr	LCD_PUT_HH	;
	
	lda	#13		;display Controller D
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DCTL		;
	jsr	LCD_PUT_H	;

	lda	#15		;display Voltage D
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	DVSIG		;
	inca
	jsr	LCD_PUT_I	;

	lda	#3		;display data A
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	ANUM		;
	jsr	LCD_PUT_RJ3_I	;

	lda	#7		;display data B
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	BNUM		;
	jsr	LCD_PUT_RJ3_I	;

	lda	#11		;display data C
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CNUM		;
	jsr	LCD_PUT_RJ3_I	;

	lda	#15		;display data D
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	DNUM		;
	jsr	LCD_PUT_RJ3_I	;

	lda	#0		;enable all translations
	sta	AFLAG
	sta	BFLAG
	sta	CFLAG
	sta	DFLAG

	jsr	SENDA		;resend stored controller settings
	jsr	SENDB		;
	jsr	SENDC		;
	jsr	SENDD

	lda	#0		;
	sta	PARNUM	;reset parameter number
	jsr	PUTCUR	;place cursor

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