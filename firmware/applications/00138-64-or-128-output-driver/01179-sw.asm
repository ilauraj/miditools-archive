;===============================================================;
;								;
;       0013864O.ASM   Rev 1	                                ;
;	64 Output Driver					;
;								;
;       The user can manipulate up to 128 drivers using MIDI    ;
;	Note On messages received on the same channel.		;
;								;
;       8 Maps are provided to assign specific MIDI Note        ;
;       numbers to specific drivers.                            ;
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
;                                                               ;
;       ...SAVE THE DEVMAP AND CHANNEL?                         ;
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
;       the driver corresponding to the note number. A Note Off ;
;       message, or a Note On message w/velocity=0, will        ;
;       deenergize the driver.                                  ;
;								;
;	...RESET THE DRIVERS?					;
;	Press the ALLOFF key.  All drivers will return to their	;
;	power-up (deenergized) state.				;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screens:						;
;								;
;       | CH  MAP        |      where nn = 1-16, bb=1-8         ;
;	| nn  bb         |					;
;								;
;	The cursor arrow points to the parameter that will be	;
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
;       StMap           Select map                              ;
;								;
;	Actions:						;
;								;
;	IDLE		No action				;
;	ALLOFF		Deenergizes all drivers			;
;	CHINC		Increment channel			;
;	CHDEC		Decrement channel			;
;	CHFDR		Set channel with fader			;
;       MAPINC          Increment Map                           ;
;       MAPDEC          Decrement Map                           ;
;       MAPFDR          Set Map with fader                      ;
;	PROC		Process incoming note messages		;
;       SAVE            Saves channel and Map number            ;
;       LOAD            Loads channel and Map number            ;
;	CISP		Update cursor for changing channel	;
;       ODISP           Update cursor for changing Map          ;
;	DISP		Update display parameters		;
;	ARWCLR		Clears the cursor arrow			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.APPL_RAM
	.ABSOLUTE

CHAN		.DS	1	;MIDI channel (0-15)
MAPNUM          .DS     1       ;Driver Map number
DRIVER		.DS	1	;currently selected driver transitor (0-7)
BANK            .DS     1       ;current bank ($01,$02,$04,$08,$10,...)
BITPOS          .DS     1       ;bit pos of current driver in current BANK
DRIVERS         .DS     16      ;state of drivers
STROBE          .DS     2       ;16-bit STROBE image
N_FLAG          .DS     1       ;flags whether note is on or off

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StLock		EQU	0
StCh 	  	EQU	1
StMap           EQU     2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvLock		EQU	EV_SW1_ON
EvChan		EQU	EV_SW2_ON
EvMap           EQU     EV_SW3_ON
EvUp	   	EQU	EV_SW4_ON
EvSave		EQU	EV_SW5_ON
EvAlloff	EQU	EV_SW7_ON
EvDown		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN
;                  State 0:StLock State 1:StCh   State 2:StMap          Not
;	 Event	   NextSt,Act     NextSt,Act     NextSt,Act            Used
;	 ------------------------------------------------------------------
 STM_ROW EvIdle,   StLock,IDLE,   StCh,IDLE,     StMap,IDLE,    StLock,IDLE
 STM_ROW EvLock,   StLock,IDLE,   StLock,ARWCLR, StLock,ARWCLR, StLock,IDLE
 STM_ROW EvChan,   StCh,CDISP,    StCh,IDLE,     StCh,CDISP,    StLock,IDLE
 STM_ROW EvMap,    StMap,MDISP,   StMap,MDISP,   StMap,IDLE,    StLock,IDLE
 STM_ROW EvUp,     StLock,IDLE,   StCh,CHINC,    StMap,MAPINC,  StLock,IDLE
 STM_ROW EvSave,   StLock,SAVE,   StCh,SAVE,     StMap,SAVE,    StLock,IDLE
 STM_ROW EvAlloff, StLock,ALLOFF, StCh,ALLOFF,   StMap,ALLOFF,  StLock,IDLE
 STM_ROW EvDown,   StLock,IDLE,   StCh,CHDEC,    StMap,MAPDEC,  StLock,IDLE
 STM_ROW EvValue,  StLock,IDLE,   StCh,CHFDR,    StMap,MAPFDR,  StLock,IDLE
 STM_ROW EvMsgIn,  StLock,PROC,   StCh,PROC,     StMap,PROC,    StLock,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- initialize variables

        lda     #0
        sta     DRIVERS
        sta     (DRIVERS+1)
        sta     (DRIVERS+2)
        sta     (DRIVERS+3)
        sta     (DRIVERS+4)
        sta     (DRIVERS+5)
        sta     (DRIVERS+6)
        sta     (DRIVERS+7)
        sta     (DRIVERS+8)
        sta     (DRIVERS+9)
        sta     (DRIVERS+10)
        sta     (DRIVERS+11)
        sta     (DRIVERS+12)
        sta     (DRIVERS+13)
        sta     (DRIVERS+14)
        sta     (DRIVERS+15)
        sta     BITPOS
        sta     BANK
        sta     DRIVER
        sta     STROBE
        sta     (STROBE+1)
        sta     CHAN
        sta     MAPNUM
        sta     N_FLAG

;--- Initialize drivers

        jsr     RSTDRVS

;--- Initialize MIDI

	lda	#$01		;buffer note messages
	sta	M_RX_Q_XPT	;

;--- Initialize display

       	jsr	GREETING

	jsr     LCD_CLEAR

	LCD_PUT_S "   64 Output    "
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
        LCD_PUT_S "    Driver      "
	jsr	DELAY_1SEC
        jsr     LCD_CLEAR
	jsr	LOAD		;get saved parameters
	lda	#0		;top line of display (never changes)
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " CHAN MAP DRIVER"
	jsr	ALLOFF		;make sure all drivers are off
	jsr	ARWCLR		;clear cursor (lock mode)
	jsr	DISP		;update display

;--- Execute state machine

        jmp     STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:   rts

;--- Reset all drivers to deenergized state

ALLOFF:

        jsr     ARWCLR          ;clear cursor arrow (lock mode)
	jsr	DISP		;update display

RSTDRVS:
        X1_HI                   ;disable drivers
        X0_LO                   ;default X0

        lda     #0              ;turn all drivers off
        WR_DATA                 ;

        lda     #$FF            ;strobe all driver chips
        jsr     SPI_IO          ;
        lda     #$FF            ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;
        lda     #$00            ;
        jsr     SPI_IO          ;
        lda     #$00            ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;

        X1_LO                   ;enable drivers

        rts

;--- Increment channel

CHINC:  lda     CHAN            ;fetch channel
	inca			;increment
        and     #$0F            ;constrain to 0-15
        sta     CHAN            ;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Decrement channel

CHDEC:  lda     CHAN            ;fetch channel
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	CHAN		;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Set channel with fader

CHFDR:  lda     FDR             ;fetch fader value
	lsra			;divide value by 16
	lsra			;
	lsra			;
	lsra			;
	sta	CHAN		;store new value
	jsr	CDISP		;update cursor
	jsr	DISP		;update values
	rts

;--- Increment MAPNUM

MAPINC: lda     MAPNUM          ;fetch MAPNUM
	inca			;increment
        and     #$07            ;constrain to 0-7
        sta     MAPNUM          ;store new value
        jsr     MDISP           ;update cursor
	jsr	DISP		;update values
	rts

;--- Decrement MAPNUM

MAPDEC: lda     MAPNUM          ;fetch MAPNUM
	deca			;decrement
        and     #$07            ;constrain to 0-7
        sta     MAPNUM          ;store new value
        jsr     MDISP           ;update cursor
	jsr	DISP		;update values
	rts

;--- Set MAPNUM with fader

MAPFDR: lda     FDR             ;fetch fader value
        lsra                    ;divide by 32 (0-7)
	lsra			;
	lsra			;
	lsra			;
	lsra			;
        sta     MAPNUM          ;store new value
        jsr     MDISP           ;update cursor
	jsr	DISP		;update values
	rts

;--- Save all parameters to EEPROM

SAVE:   lda     #3              ;blink LED
	jsr	LED_ON		;
	jsr	DELAY_1SEC	;
	lda	#3		;
        jsr     LED_OFF		;
	lda	#0
	ldx	CHAN
        jsr     EE_WRITE        ;store it
	lda	#1
        ldx     MAPNUM
        jsr     EE_WRITE        ;store it
        rts

;--- Load preset parameters at powerup

LOAD:   lda     #0              ;
	jsr	EE_READ 	;fetch value
	sta	CHAN		;store value
	lda	#1		;
	jsr	EE_READ 	;fetch value
        sta     MAPNUM          ;store value
        rts

;--- Process incoming note messages

PROC:
        ;--- make sure it is on the MIDI Channel we want

        lda     MP_RSTAT        ;fetch Note Status Byte
	and	#$0F		;get channel
	cmp	CHAN		;is it the one we selected?
	FAR_BNE	PDUN		;no? leave...

        ;--- make sure it is Note On/Off message

        lda     MP_RSTAT        ;fetch Note Status Byte
	cmp	#$90		;compare to Note On Status
        blo     POFF            ;is it a Note Off? process it...
	lda     MP_DATA2        ;fetch velocity value
        cmp     #0              ;compare to 0
        beq     POFF            ;=0? process Note Off...
	lda	#1		;set note status flag
	sta	N_FLAG		;
        jmp     PA              ;
POFF:	lda	#0		;clear note status flag
	sta	N_FLAG		;
PA:

;--- Update DRIVERS bitmap with this driver

        ;--- Map Note # to mapped Driver #

        lda     MAPNUM
        cmp     #0
        beq     ISMAP1
        cmp     #1
        beq     ISMAP2
        cmp     #2
        beq     ISMAP3
        cmp     #3
        beq     ISMAP4
        cmp     #4
        beq     ISMAP5
        cmp     #5
        beq     ISMAP6
        cmp     #6
        beq     ISMAP7
        cmp     #7
        beq     ISMAP8

ISMAP1:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP1,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP2:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP2,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP3:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP3,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP4:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP4,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP5:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP5,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP6:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP6,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP7:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP7,X          ;fetch mapped driver #
        jmp     GOTMAP          ;
ISMAP8:
        ldx     MP_DATA1        ;fetch note #
        lda     MAP8,X          ;fetch mapped driver #
        jmp     GOTMAP          ;

GOTMAP: sta     DRIVER          ;save driver #

	jsr	DSPDRV		;display this driver #

        ;--- Determine which BANK this driver is in, and bitpos in bank

        lda     DRIVER         ;BANK = DRIVER / 8 (0-15)
        lsra                    ;
        lsra                    ;
        lsra                    ;
        sta     BANK            ;

        ;BITPOS = 2^(DRIVER-BANK*8)

        lda     DRIVER          ;build exponent (0-7)
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;
        sub     BANK            ;

        tax                     ;take 2 to the power of exponent
        lda     TWOEXPN,X       ;lookup 2^N

        sta     BITPOS          ;save bit position

        jmp     OVERTABLE
TWOEXPN: .DB     1,2,4,8,16,32,64,128
OVERTABLE:

        ;--- Set state of this bit ( bit[bitpos] in DRIVERS[BANK] )

        lda     N_FLAG
        beq     GOTNOFF

GOTNON:
        ldx     BANK            ;fetch old state of affected DRIVER bank
        lda     DRIVERS,X       ;
        ora     BITPOS          ;turn this driver on
        sta     DRIVERS,X       ;save new state
        jmp     PUPD8           ;

GOTNOFF:
        lda     BITPOS          ;invert mask for clearing bits
        coma                    ;
        sta     BITPOS          ;

        ldx     BANK            ;fetch old state of affected DRIVER bank
        lda     DRIVERS,X       ;
        and     BITPOS          ;turn this driver off
        sta     DRIVERS,X       ;save new state
;        jmp     PUPD8           ;

        ;--- update drivers

PUPD8:
        ; output bit image

;        ldx     BANK            ;fetch bit image for this driver bank
;        lda     DRIVERS,X       ;
        WR_DATA                 ;write it to Data Port

        ;strobe corresponding DRIVER IC

;        ldx     BANK            ;get Bank

        cpx     #8              ;see if driver is on 2nd relay expansion PCB
        bhs     RELAY2          ;yup

RELAY1: lda     #0              ;all upper banks off
        sta     (STROBE+1)      ;
;        ldx     BANK           ;look up bit position for this BANK
        lda     TWOEXPN,X       ;
        sta     STROBE          ;save it
        jmp     STROBEDATA

RELAY2: lda     #0              ;all lower banks off
        sta     STROBE          ;
        lda     BANK            ;look up bit position for this BANK
        sub     #8              ;
        tax                     ;
        lda     TWOEXPN,X       ;
        sta     (STROBE+1)      ;save it
;        jmp     STROBEDATA

STROBEDATA:

        ;turn strobe on

        lda     (STROBE+1)      ;send MS byte
        jsr     SPI_IO          ;
        lda     STROBE          ;send LS byte
        jsr     SPI_IO          ;latch it
        X0_HI                   ;
	X0_LO			;

        ;turn strobe off

        lda     #$00            ;
        jsr     SPI_IO          ;
        lda     #$00            ;
        jsr     SPI_IO          ;
        X0_HI                   ;
	X0_LO			;

        ;--- Update display

	jsr	DISP		;update display

PDUN:	rts

;--- Update cursor for changing channel
CDISP:	jsr	ARWCLR		;clear arrow
	lda	#0		;place CH arrow
	ldx	#1		;
	jsr	LCD_PUT_ARROW	;
        rts

;--- Update cursor for changing MAP
MDISP:  jsr     ARWCLR          ;clear arrow
        lda     #5              ;place MAP arrow
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
        lda     MAPNUM          ;fetch MAP number
        inca
        jsr     LCD_PUT_I       ;display it
	rts

;--- display driver #

DSPDRV:
	lda	#13
	ldx	#1
	jsr	LCD_GOTOXY
	
	lda	DRIVER
	jsr	LCD_PUT_RJ3_I
	
	rts

;--- Clear cursor arrow
ARWCLR:	lda	#0		;clear 1st position
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
        lda     #5              ;clear 2nd position
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;
	rts

;----------------------------------------------------------------
;       MAPs
;----------------------------------------------------------------

MAP1:   .DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
        .DB 80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
        .DB 96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111
        .DB 112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127


MAP2:   .DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
        .DB 80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
        .DB 96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111
        .DB 112,113,114,115

MAP3:   .DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
        .DB 80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
        .DB 96,97,98,99,100,101,102,103

MAP4:   .DB 92,93,94,95,96,97,98,99,100,101,102,103
	.DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
        .DB 80,81,82,83,84,85,86,87,88,89,90,91

MAP5:   .DB 80,81,82,83,84,85,86,87,88,89,90,91
	.DB 92,93,94,95,96,97,98,99,100,101,102,103
	.DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79

MAP6:   .DB 68,69,70,71,72,73,74,75,76,77,78,79
	.DB 80,81,82,83,84,85,86,87,88,89,90,91
	.DB 92,93,94,95,96,97,98,99,100,101,102,103
	.DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
        .DB 64,65,66,67

MAP7:   .DB 56,57,58,59,60,61,62,63,64,65,66,67
	.DB 68,69,70,71,72,73,74,75,76,77,78,79
	.DB 80,81,82,83,84,85,86,87,88,89,90,91
	.DB 92,93,94,95,96,97,98,99,100,101,102,103
	.DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
        .DB 48,49,50,51,52,53,54,55

MAP8:   .DB 44,45,46,47,48,49,50,51,52,53,54,55
	.DB 56,57,58,59,60,61,62,63,64,65,66,67
	.DB 68,69,70,71,72,73,74,75,76,77,78,79
	.DB 80,81,82,83,84,85,86,87,88,89,90,91
	.DB 92,93,94,95,96,97,98,99,100,101,102,103
	.DB 104,105,106,107,108,109,110,111,112,113,114,115
	.DB 116,117,118,119,120,121,122,123,124,125,126,127
	.DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .DB 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .DB 32,33,34,35,36,37,38,39,40,41,42,43


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

