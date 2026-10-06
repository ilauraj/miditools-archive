;===============================================================;
;								;
;       TOOL17.ASM      Rev 0.4                                 ;
;	Sequencer Helper					;
;								;
;	The user can control various sequence playback		;
;	parameters with this device placed at the sequencer's   ;
;	output. 						;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...TRANSPOSE THE KEY SIGNATURE OF MY SEQUENCE?		;
;	Press the TRANSPOSE KEY+ key to transpose the song 1/2	;
;	step higher.  Press the TRANSPOSE KEY- key to		;
;	transpose the song 1/2 step lower.  The overall offset	;
;	is given in the LCD.  The KEY OFFSET LED lights for	;
;	nonzero offsets.					;
;								;
;	Key transposition can be disabled for individual	;
;	channels (see Sequencer Setup) to leave certain tracks	;
;	unaltered.						;
;								;
;								;
;	...ADD AN OFFSET TO ALL SEQUENCE VELOCITY VALUES?	;
;	Press the TRANSPOSE VEL+ key to add 1 to all note	;
;	velocities.  Press the TRANSPOSE VEL- key to subtract	;
;	1 from all note velocities.  The overall offset is	;
;	given in the LCD.  The VEL OFFSET LED lights for	;
;	nonzero offsets.					;
;								;
;								;
;	...MUTE PLAYBACK OF MY SEQUENCE WITHOUT STOPPING IT?	;
;	Press the MUTE key.  Press the key again to restore	;
;	playback.  The MUTE LED lights when notes are muted.	;
;	In addition, a message appears in the LCD when notes	;
;	are being muted.					;
;								;
;								;
;	...CONTROL THE OVERALL VOLUME?				;
;	The VOLUME fader acts as a Master Volume control.	;
;	All instrument voices are affected.  Volume is scaled	;
;	according to fader position.  The VOLUME LED lights	;
;	for all non-100% settings.  Volume data are scaled	;
;	from any received Volume data (Controller 7).  In the	;
;	absence of received Volume data, the control defaults	;
;	to a value of 127 (maximum volume).			;
;								;
;	This fader allows controlled fade ins and outs. 	;
;								;
;								;
;	...RESET THE LOCAL DEVICE PARAMETERS?			;
;	Press the LOCAL RESET key to reset the following:	;
;								;
;		KEY OFFSET  -----> 0				;
;		VEL OFFSET  -----> 0				;
;		MUTE  -----------> OFF				;
;		VOLUME	---------> 100% 			;
;		KEY TRANSPOSE ---> all channels enabled 	;
;								;
;								;
;	...RESET ALL CONTROLLERS?				;
;	Pressing the RESET R-CTL key resets controllers 0-95	;
;	on all channels to a value of zero, except for the	;
;	following special cases:				;
;								;
;		VOLUME (Ctl 7) -----> 127			;
;		PAN (Ctl 10) -------> 64			;
;		BALANCE (Ctl 8) ----> 64			;
;								;
;	The Channel Mode Message, RESET ALL CONTROLLERS 	;
;	(Controller 121), is also transmitted on each channel.	;
;								;
;	In addition to controller messages, the following	;
;	parameters are restored to the indicated values:	;
;								;
;		PITCH BEND ---------> MSB=64/LSB=0 (no bend)	;
;		CHANNEL AFTERTOUCH -> 0 			;
;		KEY AFTERTOUCH -----> 0 (all notes)		;
;								;
;								;
;	...TURN OFF ALL NOTES?					;
;	Pressing the RESET PANIC key sends the following	;
;	messages on all channels:				;
;								;
;		ALL NOTES OFF (Ctl 123 - Channel Mode Message)	;
;		NOTE OFF (note numbers 0-127)			;
;								;
;								;
;	...SET UP MY SEQUENCE FOR PROPER OPERATION?		;
;	For proper operation of the master VOLUME fader, the	;
;	sequencer should send the desired nominal volume	;
;	settings (Controller 7) on each MIDI channel used.	;
;								;
;	The user can disable key transposition on channels	;
;	1-7 and 9-15 by sending controller messages as follows: ;
;								;
;	Controller #48 - enables/disables channels 1-7		;
;	----------------------------------------------		;
;	Data Value						;
;	|bit 7|bit 6|bit 5|bit 4|bit 3|bit 2|bit 1|bit 0|	;
;	|  0  |ch 7 |ch 6 |ch 5 |ch 4 |ch 3 |ch 2 |ch 1 |	;
;								;
;	Controller #16 - enables/disables channels 9-15 	;
;	----------------------------------------------- 	;
;	Data Value						;
;	|bit 7|bit 6|bit 5|bit 4|bit 3|bit 2|bit 1|bit 0|	;
;	|  0  |ch 15|ch 14|ch 13|ch 12|ch 11|ch 10|ch 9 |	;
;								;
;	A bit value of "1" disables key transposition on that   ;
;	channel.						;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	|Keysddd  Velsddd|	where s="+" or "-", ddd=0-127,  ;
;	| message	 |	message="Loc Reset - WAIT",     ;
;				"Ctl Reset - WAIT",             ;
;				" PANIC!  - WAIT " or "MUTE ON" ;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board and one HUMAN		;
;	INTERFACE board.  MIDI ports used: IN,OUT,THRU. 	;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StOp		Operate 				;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	VOLSND		Send scaled volume messages		;
;	VELINC		Increment velocity offset		;
;	VELDEC		Decrement velocity offset		;
;	KEYINC		Increment key offset			;
;	KEYDEC		Decrement key offset			;
;	LOCALR		Reset local device parameters		;
;	CNTRLR		Reset all controllers			;
;	PANICR		Reset all instrument voices		;
;	MUTTOG		Toggle mute status			;
;	VDISP		Update display with velocity info	;
;	KDISP		Update display with key info		;
;	MDISP		Update display with mute info		;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

MUTE		.DS	1	;mute status flag
KOFFSET 	.DS	1	;key offset
VOFFSET 	.DS	1	;velocity offset
VOL01		.DS	1	;volume value/Ch 1
VOL02		.DS	1	;volume value/Ch 2
VOL03		.DS	1	;volume value/Ch 3
VOL04		.DS	1	;volume value/Ch 4
VOL05		.DS	1	;volume value/Ch 5
VOL06		.DS	1	;volume value/Ch 6
VOL07		.DS	1	;volume value/Ch 7
VOL08		.DS	1	;volume value/Ch 8
VOL09		.DS	1	;volume value/Ch 9
VOL10		.DS	1	;volume value/Ch 10
VOL11		.DS	1	;volume value/Ch 11
VOL12		.DS	1	;volume value/Ch 12
VOL13		.DS	1	;volume value/Ch 13
VOL14		.DS	1	;volume value/Ch 14
VOL15		.DS	1	;volume value/Ch 15
VOL16		.DS	1	;volume value/Ch 16
CHCTR		.DS	1	;channel counter
VALCTR		.DS	1	;value counter
KEYDISLO	.DS	1	;key transpose disable mask (LSB)
KEYDISHI	.DS	1	;key transpose disable mask (MSB)
TEMPVAL 	.DS	1	;M_TEMPOrary value storage

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvKeyM		EQU	EV_SW1_ON
EvKeyP		EQU	EV_SW2_ON
EvVelM		EQU	EV_SW3_ON
EvVelP		EQU	EV_SW4_ON
EvReset 	EQU	EV_SW5_ON
EvMute		EQU	EV_SW6_ON
EvRCtl		EQU	EV_SW7_ON
EvPanic 	EQU	EV_SW8_ON
EvVol		EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0: StOp                            Not
;	 Event	  NextSt,Act				  Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,  StOp,IDLE,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvVelM,  StOp,VELDEC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvVelP,  StOp,VELINC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvKeyM,  StOp,KEYDEC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvKeyP,  StOp,KEYINC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvReset, StOp,LOCALR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMute,  StOp,MUTTOG, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvRCtl,  StOp,CNTRLR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvPanic, StOp,PANICR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvVol,   StOp,VOLSND, StOp,IDLE, StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default values
	sta	TEMPVAL 	;

	lda	#127		;
	sta	VOL01		;
	sta	VOL02		;
	sta	VOL03		;
	sta	VOL04		;
	sta	VOL05		;
	sta	VOL06		;
	sta	VOL07		;
	sta	VOL08		;
	sta	VOL09		;
	sta	VOL10		;
	sta	VOL11		;
	sta	VOL12		;
	sta	VOL13		;
	sta	VOL14		;
	sta	VOL15		;
	sta	VOL16		;

	lda	#128		;
	sta	KOFFSET 	;
	sta	VOFFSET 	;

	clr	MUTE		;clear flags

	clr	KEYDISLO	;clear masks
	clr	KEYDISHI	;

	clr	CHCTR		;clear counters
	clr	VALCTR		;

;--- Initialize MIDI

	lda	#1		;start with full message status
	sta	M_FULL_MSG 	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "17:    Sequencer"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S "v1.0      Helper"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "Key      Vel    "

	jsr	VDISP		;update display
	jsr	KDISP		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Send scaled volume messages

VOLSND: lda	FDR		;fetch fader value
	cmp	#254		;compare to 254
	blo	VFA		;<254? branch...
	lda	#8		;> or =254? turn LED off
	jsr	LED_OFF 	;
	jmp	VFB		;jump...

VFA:	lda	#8		;turn LED on
	jsr	LED_ON		;

VFB:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFB		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL01		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFC		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFC:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFD:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFD		; receiving a message
	sei			;disable all interrupts
	lda	#$B1		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL02		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFE:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFF:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFF		; receiving a message
	sei			;disable all interrupts
	lda	#$B2		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL03		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFG		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFG:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFH:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFH		; receiving a message
	sei			;disable all interrupts
	lda	#$B3		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL04		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFI		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFI:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFJ:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFJ		; receiving a message
	sei			;disable all interrupts
	lda	#$B4		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL05		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFK		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFK:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFL:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFL		; receiving a message
	sei			;disable all interrupts
	lda	#$B5		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL06		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFM		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFM:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFN:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFN		; receiving a message
	sei			;disable all interrupts
	lda	#$B6		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL07		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFO		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFO:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFP:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFP		; receiving a message
	sei			;disable all interrupts
	lda	#$B7		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL08		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFQ		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFQ:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFR:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFR		; receiving a message
	sei			;disable all interrupts
	lda	#$B8		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL09		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFS		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFS:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFT:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFT		; receiving a message
	sei			;disable all interrupts
	lda	#$B9		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL10		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFU		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFU:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFV:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFV		; receiving a message
	sei			;disable all interrupts
	lda	#$BA		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL11		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFW		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFW:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFX:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFX		; receiving a message
	sei			;disable all interrupts
	lda	#$BB		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL12		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFY		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFY:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFZ:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFZ		; receiving a message
	sei			;disable all interrupts
	lda	#$BC		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL13		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFAA		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFAA:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFBB:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFBB		; receiving a message
	sei			;disable all interrupts
	lda	#$BD		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL14		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFCC		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFCC:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFDD:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFDD		; receiving a message
	sei			;disable all interrupts
	lda	#$BE		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL15		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFEE		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFEE:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause

VFFF:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	VFFF		; receiving a message
	sei			;disable all interrupts
	lda	#$BF		;load Status Byte
	jsr	MIDI_PUT	;send it
	lda	#$07		;load volume controller number
	jsr	MIDI_PUT	;send it
	lda	FDR		;fetch fader value
	lsra			;constrain to 0-127
	ldx	VOL16		;load appropriate channel volume
	mul			;multiply by fader value
	rola			;shift w/carry to effectively
	rolx			; divide by 128 (use MSB in x)
	txa			;transfer new volume to acca
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	VFGG		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
VFGG:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	rts

;--- Increment velocity offset

VELINC: inc	VOFFSET 	;increment offset
	jsr	VDISP		;update display
	rts

;--- Decrement velocity offset

VELDEC: dec	VOFFSET 	;decrement offset
	jsr	VDISP		;update display
	rts

;--- Increment key offset

KEYINC: inc	KOFFSET 	;increment offset
	jsr	KDISP		;update display
	rts

;--- Decrement key offset

KEYDEC: dec	KOFFSET 	;decrement offset
	jsr	KDISP		;update display
	rts

;--- Reset local device parameters

LOCALR: lda	#0		;notify user
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Loc Reset - WAIT"
	jsr	DELAY_1SEC

	lda	#255		;load reset value
	sta	FDR		;save new value
	jsr	VOLSND		;reset master volume

	lda	#128		;load reset value
	sta	VOFFSET 	;save new offsets
	sta	KOFFSET 	;

	clr	MUTE		;disable mute
	clr	KEYDISLO	;clear mask LSB
	clr	KEYDISHI	;clear mask MSB

	jsr	MDISP		;update display
	jsr	VDISP		;
	jsr	KDISP		;
	rts

;--- Reset all controllers

CNTRLR: lda	#0		;notify user
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "Ctl Reset - WAIT"

	;--- reset controllers 0-95

	lda	#15		;setup channel counter
	sta	CHCTR		;

RCA:	lda	#95		;setup controller counter
	sta	VALCTR		;

RCB:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCB		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	VALCTR		;load controller number
	jsr	MIDI_PUT	;send it
	lda	#$00		;load reset value
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCC		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCC:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

	lda	VALCTR		;get controller counter
	beq	RCD		;=0? branch...
	deca			;nonzero? dec controller counter
	sta	VALCTR		;save new value
	jmp	RCB		;loop

RCD:	lda	CHCTR		;get channel counter
	beq	RCE		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RCA		;loop

	;--- update special values (controllers 7,8,10)

RCE:	lda	#15		;setup channel counter
	sta	CHCTR		;

RCF:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCF		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#$07		;load Controller=7
	jsr	MIDI_PUT	;send it
	lda	#$7F		;load reset value=127
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCG		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCG:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

RCH:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCH		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#$08		;load Controller=8
	jsr	MIDI_PUT	;send it
	lda	#$40		;load reset value=64
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCI		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCI:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

RCJ:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCJ		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#$0A		;load Controller=10
	jsr	MIDI_PUT	;send it
	lda	#$40		;load reset value=64
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCK		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCK:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

RCL:	lda	CHCTR		;get channel counter
	beq	RCM		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RCF		;loop

	;--- update bend, aftertouch values

RCM:	lda	#15		;setup channel counter
	sta	CHCTR		;

RCN:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCN		; receiving a message
	sei			;disable all interrupts
	lda	#$E0		;load Pitch Bend Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#$00		;load LSB=0
	jsr	MIDI_PUT	;send it
	lda	#$40		;load MSB=64
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCO		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCO:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

RCP:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCP		; receiving a message
	sei			;disable all interrupts
	lda	#$D0		;load Channel Aftertouch nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#$00		;load reset value=0
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCQ		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCQ:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

	lda	#127		;setup note number counter
	sta	VALCTR		;

RCR:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCR		; receiving a message
	sei			;disable all interrupts
	lda	#$A0		;load Key Aftertouch nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	VALCTR		;load note number
	jsr	MIDI_PUT	;send it
	lda	#$00		;load reset value=0
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCS		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCS:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

	lda	VALCTR		;get note number counter
	beq	RCT		;=0? branch...
	deca			;nonzero? dec note number counter
	sta	VALCTR		;save new value
	jmp	RCR		;loop

RCT:	lda	CHCTR		;get channel counter
	beq	RCU		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RCN		;loop

	;--- send controller 121 (Reset Controllers)

RCU:	lda	#15		;setup channel counter
	sta	CHCTR		;

RCV:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RCV		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#121		;load Controller=121
	jsr	MIDI_PUT	;send it
	lda	#$00		;load reset value=0
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RCW		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RCW:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

	lda	CHCTR		;get channel counter
	beq	RCX		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RCV		;loop

RCX:	jsr	MDISP		;update display
	rts

;--- Reset all instrument voices

PANICR: lda	#0		;notify user
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "  PANIC! - WAIT "

	;--- send All Notes Off message on all channels

	lda	#15		;setup channel counter
	sta	CHCTR		;

RPA:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RPA		; receiving a message
	sei			;disable all interrupts
	lda	#$B0		;load Controller Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	#123		;load Controller=123
	jsr	MIDI_PUT	;send it
	lda	#$00		;load value=00
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RPB		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RPB:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

RPC:	lda	CHCTR		;get channel counter
	beq	RPD		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RPA		;loop

	;--- send Note Off messages for each key on each channel

RPD:	lda	#15		;setup channel counter
	sta	CHCTR		;

RPE:	lda	#127		;setup note number counter
	sta	VALCTR		;

RPF:	lda	M_FULL_MSG 	;wait if in the middle of
	beq	RPF		; receiving a message
	sei			;disable all interrupts
	lda	#$80		;fetch Note Off Status nibble
	add	CHCTR		;add channel
	jsr	MIDI_PUT	;send it
	lda	VALCTR		;load note number
	jsr	MIDI_PUT	;send it
	lda	#$00		;load velocity=0
	jsr	MIDI_PUT	;send it
	lda	M_RSTAT		;fetch external running status
	beq	RPG		;=0? branch...
	jsr	MIDI_PUT	;nonzero? restore running status
RPG:	cli			;enable all interrupts
	jsr	DELAY_1MS	;pause
	jsr	DELAY_1MS	;

	lda	VALCTR		;get note number counter
	beq	RPH		;=0? branch...
	deca			;nonzero? dec value counter
	sta	VALCTR		;save new value
	jmp	RPF		;loop

RPH:	lda	CHCTR		;get channel counter
	beq	RPI		;=0? branch...
	deca			;nonzero? dec channel counter
	sta	CHCTR		;save new value
	jmp	RPE		;loop

RPI:	jsr	MDISP		;update display
	rts

;--- Toggle mute status

MUTTOG: lda	MUTE		;fetch flag
	beq	TMA		;=0? branch...
	clr	MUTE		;=1? clear mute flag
	jmp	TMB		;jump...
TMA:	lda	#1		;set mute flag
	sta	MUTE		;
TMB:	jsr	MDISP		;update display
	rts

;--- Update display with key info

KDISP:	lda	KOFFSET 	;fetch KOFFSET (0-255)
	cmp	#128		;compare to 128
	bhi	KDA		;>128? branch...

	cmp	#127		;compare to 127
	blo	KDB		;<127? branch...

	lda	#3		;=127 or =128? clear sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#" "            ;
	jsr	LCD_PUT_C	;

	lda	#6		;display value=0
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#0		;
	jsr	LCD_PUT_RJ3_I	;
	jmp	KDC		;jump...

KDA:	lda	#3		;display "+" sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#"+"            ;
	jsr	LCD_PUT_C	;

	lda	#6		;positive value=KOFFSET-128
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	KOFFSET 	;
	sub	#128		;
	jsr	LCD_PUT_RJ3_I	;
	jmp	KDC		;jump...

KDB:	lda	#3		;display "-" sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#"-"            ;
	jsr	LCD_PUT_C	;

	lda	#6		;negative value=127-KOFFSET
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#127		;
	sub	KOFFSET 	;
	jsr	LCD_PUT_RJ3_I	;

KDC:	lda	KOFFSET 	;fetch offset value
	cmp	#127		;compare to 127
	beq	KDD		;=127? branch...
	cmp	#128		;compare to 128
	beq	KDD		;=128? branch...

	lda	#0		;>128 or <127? turn LED on
	jsr	LED_ON		;
	rts

KDD:	lda	#0		;turn LED off
	jsr	LED_OFF 	;
	rts

;--- Update display with velocity info

VDISP:	lda	VOFFSET 	;fetch VOFFSET (0-255)
	cmp	#128		;compare to 128
	bhi	VDA		;>128? branch...

	cmp	#127		;compare to 127
	blo	VDB		;<127? branch...

	lda	#12		;=127 or =128? clear sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#" "            ;
	jsr	LCD_PUT_C	;

	lda	#15		;display value=0
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#0		;
	jsr	LCD_PUT_RJ3_I	;
	jmp	VDC		;jump...

VDA:	lda	#12		;display "+" sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#"+"            ;
	jsr	LCD_PUT_C	;

	lda	#15		;positive value=VOFFSET-128
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	VOFFSET 	;
	sub	#128		;
	jsr	LCD_PUT_RJ3_I	;
	jmp	VDC		;jump...

VDB:	lda	#12		;display "-" sign
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#"-"            ;
	jsr	LCD_PUT_C	;

	lda	#15		;negative value=127-VOFFSET
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#127		;
	sub	VOFFSET 	;
	jsr	LCD_PUT_RJ3_I	;

VDC:	lda	VOFFSET 	;fetch offset value
	cmp	#127		;compare to 127
	beq	VDD		;=127? branch...
	cmp	#128		;compare to 128
	beq	VDD		;=128? branch...

	lda	#4		;>128 or <127? turn LED on
	jsr	LED_ON		;
	rts

VDD:	lda	#4		;turn LED off
	jsr	LED_OFF 	;
	rts

;--- Update display with mute info

MDISP:	lda	MUTE		;get mute flag
	beq	MDA		;=0? branch...
	lda	#12		;=1? turn LED on
	jsr	LED_ON		;

	lda	#0		;notify user
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "    MUTE ON     "
	rts

MDA:	lda	#12		;turn LED off
	jsr	LED_OFF 	;

	lda	#0		;clear message
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "                "
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

;--- Process Status Bytes

SCI_RX_CBCK_S:
SENDIT: txa			;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
	rti			;return, do not buffer

;--- Process 1st Data Bytes

SCI_RX_CBCK_D1:
	cmp	#$01		;is it a note message?
	beq	URD1A		;yes? branch...
	jmp	SENDIT		;no? jump...

URD1A:	lda	M_RSTAT		;fetch current status
	and	#$0F		;get channel
	tax			;transfer to x for table lookup
	lda	CMASK,X 	;get mask value in acca

	cpx	#7		;compare channel
	bhi	KEYHI		;>7? branch...

KEYLO:	and	KEYDISLO	;< or =7? process mask LSB
	beq	URD1B		;=0 (enabled)? branch...
	lda	M_DATA1 	;=1 (disabled)? fetch byte value
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

KEYHI:	and	KEYDISHI	;process mask MSB
	beq	URD1B		;=0 (enabled)? branch...
	lda	M_DATA1 	;=1 (disabled)? fetch byte value
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

URD1B:	lda	KOFFSET 	;fetch KOFFSET (0-255)
	cmp	#128		;compare to 128
	bhi	URD1C		;>128? branch...
	cmp	#127		;compare to 127
	blo	URD1D		;<127? branch...
	lda	M_DATA1 	;=127 or =128? fetch byte value
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

	;--- key transposition

URD1C:	sub	#128		;new value=(KOFFSET-128)+M_DATA1
	add	M_DATA1 	;
	and	#$7F		;constrain to 0-127 (i.e. w/wrap)
	jsr	MIDI_PUT	;send it
	rti			;return, do not process

URD1D:	lda	#127		;new value=M_DATA1-(127-KOFFSET)
	sub	KOFFSET 	;
	sta	TEMPVAL 	;save M_TEMPOrary value
	lda	M_DATA1 	;complete the subtraction
	sub	TEMPVAL 	;
	and	#$7F		;constrain to 0-127 (i.e. w/wrap)
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

CMASK:	.DB $01,$02,$04,$08,$10,$20,$40,$80
	.DB $01,$02,$04,$08,$10,$20,$40,$80

;--- Process 2nd Data Bytes

SCI_RX_CBCK_D2:
	cmp	#$01		;is it a note message?
	beq	URD2NT 		;yes? branch...
	cmp	#$10		;no? is it a controller message?
	beq	URD2CT		;yes? branch...
	jmp	SENDIT		;neither? jump...

	;--- process notes

URD2NT: lda	MUTE		;get mute flag
	beq	URD2NA		;=0? branch...
	lda	#$00		;=1? load velocity=0
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

URD2NA: lda	M_RSTAT		;fetch status
	and	#$F0		;get status
	cmp	#$90		;is it a Note On?
	beq	URD2NB		;yes? branch...
	jmp	SENDIT		;no? jump...

URD2NB: cpx	#$00		;is velocity=0?
	bne	URD2NC		;no? branch...
	jmp	SENDIT		;yes? jump...

URD2NC: lda	VOFFSET 	;fetch VOFFSET (0-255)
	cmp	#128		;compare to 128
	bhi	URD2ND		;>128? branch...
	cmp	#127		;compare to 127
	blo	URD2NF		;<127? branch...
	lda	M_DATA2 	;=127 or =128? load byte value
	jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

	;--- velocity transposition

URD2ND: sub	#128		;new value=(VOFFSET-128)+M_DATA2
	add	M_DATA2 	;
	bpl	URD2NE		;result<128? branch...
	lda	#127		;result>127? load max value=127
URD2NE: jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

URD2NF: lda	#127		;new value=M_DATA2-(127-VOFFSET)
	sub	VOFFSET 	;
	sta	TEMPVAL 	;save M_TEMPOrary value
	lda	M_DATA2 	;complete the subtraction
	sub	TEMPVAL 	;
	bcc	URD2NG		;is result not negative? branch...
	lda	#0		;negative? load min value=0
URD2NG: jsr	MIDI_PUT	;send it
	rti			;return, do not buffer

	;--- process controller messages

URD2CT: lda	M_DATA1 	;fetch controller number
	cmp	#7		;
	beq	URD2C7		;...if Controller=7 (volume)
	cmp	#16		;
	FAR_BEQ URD2C16 	;...if Controller=16
	cmp	#48		;
	FAR_BEQ URD2C48 	;...if Controller=48
	jmp	SENDIT		;...if other controllers

	;--- process controller #7 (volume) messages

URD2C7: lda	M_RSTAT		;fetch status byte
	and	#$0F		;get channel
	tax			;transfer to x for table lookup
	JMP_TABLE TBL_VAR	;execute jump from table

TBL_VAR:
	.DW UR1,UR2,UR3,UR4,UR5,UR6,UR7,UR8
	.DW UR9,UR10,UR11,UR12,UR13,UR14,UR15,UR16

UR1:	ldx	M_DATA2 	;fetch received value
	stx	VOL01		;save for master volume control
	jmp	SENDIT		;jump...

UR2:	ldx	M_DATA2 	;fetch received value
	stx	VOL02		;save for master volume control
	jmp	SENDIT		;jump...

UR3:	ldx	M_DATA2 	;fetch received value
	stx	VOL03		;save for master volume control
	jmp	SENDIT		;jump...

UR4:	ldx	M_DATA2 	;fetch received value
	stx	VOL04		;save for master volume control
	jmp	SENDIT		;jump...

UR5:	ldx	M_DATA2 	;fetch received value
	stx	VOL05		;save for master volume control
	jmp	SENDIT		;jump...

UR6:	ldx	M_DATA2 	;fetch received value
	stx	VOL06		;save for master volume control
	jmp	SENDIT		;jump...

UR7:	ldx	M_DATA2 	;fetch received value
	stx	VOL07		;save for master volume control
	jmp	SENDIT		;jump...

UR8:	ldx	M_DATA2 	;fetch received value
	stx	VOL08		;save for master volume control
	jmp	SENDIT		;jump...

UR9:	ldx	M_DATA2 	;fetch received value
	stx	VOL09		;save for master volume control
	jmp	SENDIT		;jump...

UR10:	ldx	M_DATA2 	;fetch received value
	stx	VOL10		;save for master volume control
	jmp	SENDIT		;jump...

UR11:	ldx	M_DATA2 	;fetch received value
	stx	VOL11		;save for master volume control
	jmp	SENDIT		;jump...

UR12:	ldx	M_DATA2 	;fetch received value
	stx	VOL12		;save for master volume control
	jmp	SENDIT		;jump...

UR13:	ldx	M_DATA2 	;fetch received value
	stx	VOL13		;save for master volume control
	jmp	SENDIT		;jump...

UR14:	ldx	M_DATA2 	;fetch received value
	stx	VOL14		;save for master volume control
	jmp	SENDIT		;jump...

UR15:	ldx	M_DATA2 	;fetch received value
	stx	VOL15		;save for master volume control
	jmp	SENDIT		;jump...

UR16:	ldx	M_DATA2 	;fetch received value
	stx	VOL16		;save for master volume control
	jmp	SENDIT		;jump...

	;--- process controller #16 messages

URD2C16:
	stx	KEYDISHI	;save key transpose mask MSB
	jmp	SENDIT		;jump...

	;--- process controller #48 messages

URD2C48:
	stx	KEYDISLO	;save key transpose mask LSB
	jmp	SENDIT		;jump...
