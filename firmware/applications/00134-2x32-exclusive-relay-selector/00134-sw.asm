;===============================================================;
;								;
;       000134VID.ASM   Rev 1                                   ;
;	VideoSonic Relay Driver 				;
;								;
;	The user can manipulate up to 64 drivers using MIDI	;
;	Note On messages received on the same channel.		;
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
;	The device will continue to respond to MIDI Note On	;
;	commands. The default channel is 1.			;
;								;
;	...SET THE NOTE NUMBER OFFSET?				;
;	Press the OFFSET key.  The note number offset for	;
;	all note messages is selected using the +/- keys	;
;	and/or VALUE the fader. The first driver (D0) will	;
;	respond to the note number equal to the OFFSET. All	;
;	consecutive drivers will respond to consecutive note	;
;	numbers. The device will continue to respond to MIDI	;
;	Note On commands. The default offset is 0.		;
;								;
;	...SAVE THE OFFSET AND CHANNEL?				;
;	Press the SAVE key. Both parameters are stored in	;
;	nonvolatile EEPROM and will be recalled at powerup.	;
;	When storing values, LED #3 blinks.			;
;								;
;	...LOCK THE DISPLAY?					;
;	Pressing the LOCK key prevents any parameter changes	;
;	from taking place.					;
;								;
;	...USE NOTE MESSAGES TO AUTOMATICALLY TRIGGER RELAYS?	;
;	A Note On message (with nonzero velocity) will energize	;
;	the driver corresponding to the note number, adjusted	;
;	byt the note number offset value. Only one driver in	;
;	the AMP Set (drivers 0-31) can be energized at one time.;
;	Only one driver in the SPEAKER Set (drivers 32-63) can	;
;	be energized at one time. When a Note On (vel=nonzero)	;
;	is received, all drivers in that set are deenergized	;
;	for approximately 100msec before the proper driver	;
;	is energized.						;
;								;
;	...RESET THE DRIVERS?					;
;	Press the ALLOFF key.  All drivers will return to their	;
;	power-up (deenergized) state.				;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;	| CH  OF  AMP SPK|	where nn = 1-16, bb=0-63,      	;
;	| nn  bb  cc  cc |	cc=1-32				;
;								;
;	The cursor arrow points to the relay that will be	;
;	modified by the +/- key and/or the VALUE fader. 	;
;								;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the DRIVER board.  MIDI ports	;
;	used: IN and THRU only. 				;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StLock		Locked display mode			;
;	StCh		Set receive channel			;
;	StOff	   	Set note number offset         		;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	ALLOFF		Deenergizes all drivers			;
;	OFF_AMP		Turns all Amps off for 100msec		;
;	OFF_SPKR	Turns all Speakers off for 100msec	;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;	OFFINC		Increment offset			;
;	OFFDEC		Decrement offset			;
;	OFFFDR		Set offset with fader			;
;	PROC		Process incoming note messages		;
;	SAVE		Saves channel and offset		;
;	LOAD		Loads channel and offset		;
;	CISP		Update cursor for changing channel	;
;	ODISP		Update cursor for changing offset	;
;	DISP		Update display parameters		;
;	ARWCLR		Clears the cursor arrow			;
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

CHAN		.DS	1	;MIDI channel (0-15)
OFFSET		.DS	1	;note number offset (0-63)
AMP		.DS	1	;amplifier energized (drivers 0-31)
SPKR		.DS	1	;speaker pair energized (drivers 32-63)
RELAY		.DS	1	;currently selected driver
BANK 		.DS	1	;currently selected bank (0-7)
A_FLAG		.DS	1	;all amps off flag
S_FLAG		.DS	1	;all speakers off flag
DRVMAP		.DS	1	;bit map of driver transistors 

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StLock		EQU	0
StCh 	  	EQU	1
StOff		EQU	2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvLock		EQU	EV_SW1_ON
EvChan		EQU	EV_SW2_ON
EvOffset	EQU	EV_SW3_ON
EvUp	   	EQU	EV_SW4_ON
EvSave		EQU	EV_SW5_ON
EvAlloff	EQU	EV_SW7_ON
EvDown		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		   State 0:StLock State 1:StCh   State 2:StOff          Not
;	 Event	   NextSt,Act     NextSt,Act     NextSt,Act            Used
;	 ------------------------------------------------------------------
 STM_ROW EvIdle,   StLock,IDLE,   StCh,IDLE,     StOff,IDLE,    StLock,IDLE
 STM_ROW EvLock,   StLock,IDLE,   StLock,ARWCLR, StLock,ARWCLR, StLock,IDLE
 STM_ROW EvChan,   StCh,CDISP,    StCh,IDLE,     StCh,CDISP,    StLock,IDLE
 STM_ROW EvOffset, StOff,ODISP,   StOff,ODISP,   StOff,IDLE,    StLock,IDLE
 STM_ROW EvUp,     StLock,IDLE,   StCh,CHINC,    StOff,OFFINC,  StLock,IDLE
 STM_ROW EvSave,   StLock,SAVE,   StCh,SAVE,     StOff,SAVE,    StLock,IDLE
 STM_ROW EvAlloff, StLock,ALLOFF, StCh,ALLOFF,   StOff,ALLOFF,  StLock,IDLE
 STM_ROW EvDown,   StLock,IDLE,   StCh,CHDEC,    StOff,OFFDEC,  StLock,IDLE
 STM_ROW EvValue,  StLock,IDLE,   StCh,CHFDR,    StOff,OFFFDR,  StLock,IDLE
 STM_ROW EvMsgIn,  StLock,PROC,   StCh,PROC,     StOff,PROC,    StLock,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#0		;default channel
	sta	CHAN		;

	lda	#0		;default values
	sta	AMP		;
	sta	SPKR		;
	sta	OFFSET		;
	sta	A_FLAG		;reset all amps off flag
	sta	S_FLAG		;reset all speakers off flag

	X1_HI			;all drivers off

        X0_LO                   ;default expansion latch
        lda     #$00            ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;

;--- Initialize MIDI

	lda	#$01		;buffer note messages
	sta	M_RX_Q_XPT	;

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S " DALE PRO AUDIO "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

        LCD_PUT_S " Speaker Matrix "
	jsr	DELAY_1SEC

        jsr     LCD_CLEAR

	jsr	LOAD		;get saved parameters

	lda	#0		;top line of display (never changes)
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " CH  OF  AMP SPK"

	jsr	ALLOFF		;make sure all drivers are off
	jsr	ARWCLR		;clear cursor (lock mode)
	jsr	DISP		;update display

	X1_LO			;all drivers ready

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Reset all drivers to deenergized state

ALLOFF:	jsr	OFF_AMP		;reset Amps (drivers 0-31)
	jsr	OFF_SPKR	;reset Speakers (drivers 32-63)
	jsr	ARWCLR		;clear cursor arrow (lock mode)
	jsr	DISP		;update display
	rts

;--- Turn off all Amps (drivers 0-31) for 100msec

OFF_AMP:
	lda	#1		;set off flag
	sta	A_FLAG

	lda	#$00		;
	WR_DATA			;write data to Port
	lda	#$01		;initialize
OA1:	sta	BANK		;save new Bank
	jsr	SPI_IO		;latch data
	X0_HI			;
	X0_LO			;
	lda	#$00		;clear data
	jsr	SPI_IO		;
	X0_HI			;
	X0_LO			;
	lda	BANK		;get current Bank
	lsla			;shift in next Bank
	and	#$0F		;constrain to low Banks 0-3 (Amps)
	bne	OA1		;not finished? loop...
	jsr	DELAY_100MS	;pause
	rts

;--- Turn off all Speakers (drivers 32-63) for 100msec

OFF_SPKR:
	lda	#1		;set off flag
	sta	S_FLAG

	lda	#$00		;
	WR_DATA			;write data to Port
	lda	#$10		;initialize
OS1:	sta	BANK		;save new Bank
	jsr	SPI_IO		;latch data
	X0_HI			;
	X0_LO			;			
	lda	#$00		;clear data
	jsr	SPI_IO		;
	X0_HI			;
	X0_LO			;
	lda	BANK		;get current Bank
	lsla			;shift in next Bank
	bne	OS1		;not finished? loop...
	jsr	DELAY_100MS	;pause
	rts

;--- Increment channel

CHINC:	lda	CHAN		;fetch channel
	inca			;increment
        and     #$0F            ;constrain to 0-15
        sta     CHAN            ;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Decrement channel

CHDEC:	lda	CHAN		;fetch channel
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	CHAN		;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Set channel with fader

CHFDR:	lda	FDR		;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	CHAN		;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Increment offset

OFFINC: lda	OFFSET		;fetch offset
	inca			;increment
	and	#$3F		;constrain to 0-63
        sta     OFFSET          ;store new value
	jsr	ODISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Decrement offset

OFFDEC: lda	OFFSET		;fetch offset
	deca			;decrement
	and	#$3F		;constrain to 0-63
        sta     OFFSET          ;store new value
	jsr	ODISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Set offset with fader

OFFFDR: lda     FDR             ;fetch fader value
	lsra			;divide by 4 (0-63)
	lsra			;
	sta	OFFSET		;store new value
	jsr	ODISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Save all parameters to EEPROM

SAVE:	lda	#3		;blink LED
	jsr	LED_ON		;
	jsr	DELAY_1SEC	;
	lda	#3		;
        jsr     LED_OFF		;

	lda	#0
	ldx	CHAN
        jsr     EE_WRITE        ;store it
	lda	#1
	ldx	OFFSET
        jsr     EE_WRITE        ;store it
        rts

;--- Load preset parameters at powerup

LOAD:	lda	#0		;
	jsr	EE_READ 	;fetch value
	sta	CHAN		;store value
	lda	#1		;
	jsr	EE_READ 	;fetch value
	sta	OFFSET		;store value
        rts

;--- Process incoming note messages

PROC:	lda     MP_RSTAT        ;fetch Note Status Byte

	;make sure it is Note On message

	cmp	#$90		;compare to Note On Status
	FAR_BLO	PDUN		;Note Off? branch...

	;make sure it is on the MIDI Channel we want

	and	#$0F		;get channel
	cmp	CHAN		;is it the one we selected?
	FAR_BNE	PDUN		;no? branch...

	;make sure the Note On has a nonzero Velocity

	lda     MP_DATA2        ;fetch velocity value
	cmp	#0		;compare to 0
	FAR_BEQ	PDUN		;=0? ignore note offs...

	;make sure it is in the MIDI Note Range we want

	lda	MP_DATA1	;get note number
	sub	OFFSET		;subtract note number offset
	and	#$7F		;constrain to 0-127

	cmp	#32		;is it an Amp selection?
	blo	PA		;yes? turn them off...
	cmp	#64		;is it a Speaker selection?
	blo	PB		;yes? turn them off...
	jmp	PDUN		;otherwise, ignore this note...

	;if an Amp driver (0-31) is selected, turn Amps OFF

PA:	sta	AMP		;initialize value (0-31)
	sta	RELAY		;driver number (0-31)
	jsr	OFF_AMP		;turn off Amps for 100msec
	lda	#0		;reset off flag
	sta	A_FLAG		;
	jmp	PC		;continue

	;if a Speaker driver (32-63) is selected, turn Speakers OFF

PB:	sta	SPKR		;initialize value (32-63)
	sta	RELAY		;driver number (32-63)
	jsr	OFF_SPKR	;turn off Speakers for 100msec
	lda	#0		;reset off flag
	sta	S_FLAG		;

	;calculate BANK (each bit represents a 2803 driver chip)

PC:	ldx	#$01		;initialize Bank
	stx	BANK		;

	lda	RELAY		;get driver number (0-63)
PD:	sub	#8		;subtract 8
	bmi	PE		;finished? move on...
	lslx			;increment Bank
	stx	BANK		;save new Bank
	sta	RELAY		;save new driver number (0-7)
	jmp	PD		;loop

	;translate/bitmap RELAY (each bit=a transistor on the chip)

PE:	ldx	#$01		;initialize bitmap
	stx	DRVMAP		;
	lda	RELAY		;fetch driver number (0-7)
PF:	beq	PG		;done? move along...
	lslx			;no? shift bit
	stx	DRVMAP		;save it
	deca			;decrement counter
	jmp	PF

	;set up and send data to energize the driver

PG:	lda	DRVMAP		;get driver data
	WR_DATA			;write it to Port
	lda	BANK		;get Bank
	jsr	SPI_IO		;latch it
	X0_HI			;
	X0_LO			;
	lda	#$00		;clear data
	jsr	SPI_IO		;latch it
	X0_HI			;
	X0_LO			;
	jsr	DISP		;update display
PDUN:	rts

;--- Update cursor for changing channel

CDISP:	jsr	ARWCLR		;clear arrow
	lda	#0		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
        rts

;--- Update cursor for changing offset

ODISP:	jsr	ARWCLR		;clear arrow
	lda	#4		;place OF arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
        rts

;--- Update display with values

DISP:	lda	#2		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	CHAN		;fetch channel number
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	lda	#6		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OFFSET		;fetch channel number
	jsr	LCD_PUT_RJ2_I	;display it

	lda	A_FLAG		;check off flag
	bne	DS2		;all amps off? place '--'
	lda	#10		;position cursor
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
	lda	AMP		;fetch current Amp number
	inca			;display as 1-32
	jsr	LCD_PUT_RJ2_I	;display it

DS1:	lda	S_FLAG		;check off flag
	bne	DS3		;all speakers off? place '--'
	lda	#14		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	SPKR		;fetch current Speaker number
	sub	#32		;display as 1-32
	inca			;
	jsr	LCD_PUT_RJ2_I	;display it
	rts

DS2:	lda	#9		;position cursor
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "--"
	jmp	DS1

DS3:	lda	#13		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "--"
	rts

;--- Clear cursor arrow

ARWCLR:	lda	#0		;clear 1st position
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#4		;clear 2nd position
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
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