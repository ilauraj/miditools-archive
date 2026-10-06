;----------------------------------------
;	Constants
;----------------------------------------

OF_LED		EQU	7	;Data Overflow LED
SEX_Q_LEN	EQU	65	;sysex queue length

;-----------------------------------------
;	Variables
;-----------------------------------------

        .APPL_RAM
        .ABSOLUTE

SEX_Q		.DS	SEX_Q_LEN ;SYSEX queue

SEX_Q_WRITE     .DS     1      	;next SYSEX queue write address
EE_Q_WRITE      .DS     1      	;next EEPROM write address
SEX_Q_ENABLE	.DS	1	;SYSEX queue enable flag
SEX_CAP         .DS     1      	;flags capture mode (TRUE/FALSE)

CHAN		.DS	1	;MIDI channel
PAGE		.DS	1	;device page number
AAV		.DS	1	;AAV function flag (1=on)
LOCK		.DS	1	;display lock flag (1=locked)
CAPTURE		.DS	1	;capture mode flag (1=capturing)
RELAY1		.DS	1	;MIDI message code for Relay 1 (0-255)
RELAY2		.DS	1	;MIDI message code for Relay 2 (0-255)
RELAY3		.DS	1	;MIDI message code for Relay 3 (0-255)
RELAY4		.DS	1	;MIDI message code for Relay 4 (0-255)
RELAY5		.DS	1	;MIDI message code for Relay 5 (0-255)
RELAY6		.DS	1	;MIDI message code for Relay 6 (0-255)
RELAY7		.DS	1	;MIDI message code for Relay 7 (0-255)
RELAY8		.DS	1	;MIDI message code for Relay 8 (0-255)
DIM1		.DS	1	;MIDI Controller Number for Dimmer 1 (0-127)
DIM2		.DS	1	;MIDI Controller Number for Dimmer 2 (0-127)
DIM3		.DS	1	;MIDI Controller Number for Dimmer 3 (0-127)
DIM4		.DS	1	;MIDI Controller Number for Dimmer 4 (0-127)
DIM5		.DS	1	;MIDI Controller Number for Dimmer 5 (0-127)
DIM6		.DS	1	;MIDI Controller Number for Dimmer 6 (0-127)
RLYMAP		.DS	1	;bit mapped relay status byte
TEMPVAL		.DS	1	;temporary byte
TEMPCLASS	.DS	1	;temporary class
SEX_ID		.DS	1	;SysEx ID byte flag
REL_TMR 	.DS	1	;relay-closed timer count (msec)
CLOSED		.DS	1	;relay-is-closed flag (1=relay is closed)
RELAY_DUR	.DS	1	;relay closure duration factor (2-254)

;-------------------------------
;	State Matrix
;-------------------------------

;--- Enumerate states

StOp		EQU	0

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvLock		EQU	EV_SW1_ON
EvCap		EQU	EV_SW2_ON
EvNext		EQU	EV_SW3_ON
EvUp	   	EQU	EV_SW4_ON
EvChan		EQU	EV_SW5_ON
EvAAV		EQU	EV_SW6_ON
EvSave		EQU	EV_SW7_ON
EvDown		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE
EvMsgIn 	EQU	EV_MIDI_IN

;--- Build State Matrix

        STM_BEGIN

;		  State 0:StOp                             Not
;	 Event	  NextSt,Act                              Used
;	 -----------------------------------------------------
 STM_ROW EvIdle,  StOp,MSGSTO, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvLock,  StOp,LCKTOG, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvCap,   StOp,CAPTOG, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvNext,  StOp,PGINC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvUp,    StOp,NUMINC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvChan,  StOp,CHINC,  StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvAAV,   StOp,AAVTOG, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvSave,  StOp,SAVE,   StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvDown,  StOp,NUMDEC, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvValue, StOp,NUMFDR, StOp,IDLE, StOp,IDLE, StOp,IDLE
 STM_ROW EvMsgIn, StOp,PROC,   StOp,IDLE, StOp,IDLE, StOp,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	jsr	LOAD		;load all stored paramters

;--- Initialize relays

        X0_LO                   ;default expansion latch
        lda     #$00            ;
        jsr     SPI_IO          ;
        X0_HI                   ;
        X0_LO                   ;

	lda	#0		;initialize flag, counter, relay map
	sta	CLOSED		;
	sta	REL_TMR 	;
	sta	RLYMAP		;

;--- Initialize MIDI

	lda	#$11		;buffer note and controller messages
	sta	M_RX_Q_XPT	;

;--- Initialize to capture mode=OFF

	lda	#0		;
	sta	CAPTURE		;
	sta	SEX_CAP 	;
	sta	SEX_Q_WRITE	;
	sta	EE_Q_WRITE	;
	sta	SEX_Q_ENABLE	;
	sta	SEX_ID		;

;--- Initialize display

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " Quad Projector "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S " Controller v1.0"
	jsr	DELAY_1SEC

        jsr     LCD_CLEAR

	jsr	DISP		;update display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:   rts

;--- Toggle Capture On/Off

CAPTOG:	lda	CAPTURE		;check capture status
        eor     #$01            ;toggle it
	sta	CAPTURE		;save new status

	beq	CTA		;check status
	jmp	CAPINI		;=1 (on)? go initialize capture mode

CTA:	jsr	DISP		;= off? restore display
	ldx	#0		;reinitialize queues
        stx     SEX_Q_WRITE     ;
        stx     EE_Q_WRITE      ;
	sta	SEX_CAP 	;clear flags
	sta	SEX_Q_ENABLE	;
	rts

;--- Initialize capture mode (CAPTURE flag is =1 here)

CAPINI:	lda	#1		;lock display
	sta	LOCK		;
	lda	#3		;turn LED on
	jsr	LED_ON		;

	lda	#0		;reset queues
	sta	SEX_Q_WRITE	;
        sta     EE_Q_WRITE      ;
	sta	SEX_Q_ENABLE	;
        lda     #1              ;enable SYSEX Q capture
        sta     SEX_CAP         ;

	jsr	LCD_CLEAR	;notify user

	LCD_PUT_S "CAPTURING CURVE "
	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
	LCD_PUT_S "  ...waiting    "

	lda	#OF_LED 	;turn Data Overflow LED off
	jsr	LED_OFF		;
        rts

;--- Store message (administer relay closures)

MSGSTO: lda	CLOSED		;check to see if any relays are closed
	beq	MSTO3		;no? continue...

	lda	REL_TMR 	;get timer counter
	cmp	RELAY_DUR	;is it time to open relay?
	bhs	MSTO2		;yes? branch...

	jsr	DELAY_1MS	;no? pause 1msec (does not use acca)
	jsr	DELAY_1MS	;pause another 1msec
	inca			;increment counter
	sta	REL_TMR 	;
	jmp	MSTO3		;continue

MSTO2:	lda	#$00		;deenergize all relays
	jsr	SPI_IO		;send data
        X0_HI                   ;latch data
        X0_LO                   ;
	lda	#0		;clear closed flag and relay map
	sta	CLOSED		; and continue...
	sta	RLYMAP		;

MSTO3:	lda	SEX_CAP 	;are we capturing?
	beq	MSEND		;no? leave now...
	lda	SEX_Q_WRITE	;yes? any fresh new data for EEPROM?
        cmp     EE_Q_WRITE      ;
	bls	MSEND		;no? leave...
	ldx	EE_Q_WRITE	;yes? write data in location

	cpx	#SEX_Q_LEN
	blo	MS2
	cpx	#129
	bhs	MSEND

	txa
	sub	#SEX_Q_LEN
	tax

MS2:	ldx	SEX_Q,X 	; EE_Q_WRITE to EEPROM address
				; EE_Q_WRITE
	lda	EE_Q_WRITE	;
        jsr     EE_WRITE        ;write data to EEPROM
	lda	EE_Q_WRITE	;get EE_Q_WRITE
	inca			;increment
	sta	EE_Q_WRITE	;save new value
MSEND:	rts

;--- Toggle AAV function On/Off

AAVTOG:	lda	LOCK		;check lockout status
	bne	ATEND		;if on, ignore...

	lda	AAV		;fetch current status
	and	#$01		;constrain to 0 or 1
        eor     #$01            ;toggle it
	sta	AAV		;save new status

	beq	ATA		;check status
	lda	#15		;=1 (on)? turn LED on
	jsr	LED_ON		;
	jmp	ATEND		;

ATA:	lda	#15		;=0 (off)? turn LED off
	jsr	LED_OFF		;

ATEND:	jsr	DISP		;
	rts

;--- Toggle display lock On/Off

LCKTOG:	lda	LOCK		;check lockout status
	and	#$01		;constrain to 0 or 1
        eor     #$01            ;toggle it
	sta	LOCK		;save new status

	beq	LTA		;check status
	lda	#3		;=1 (on)? turn LED on
	jsr	LED_ON		;
	jmp	LTEND		;

LTA:	lda	#3		;=0 (off)? turn LED off
	jsr	LED_OFF		;

LTEND:	rts

;--- Increment channel

CHINC:	lda	LOCK		;check lockout status
	bne	CIA		;if on, ignore...
	lda	CHAN		;fetch channel
	inca			;increment
        and     #$0F            ;constrain to 0-15
        sta     CHAN            ;store new value
	jsr	DISP		;update display
CIA:	rts

;--- Select next device page

PGINC:	lda	LOCK		;check lockout status
	bne	PIB		;if on, ignore...
	lda	PAGE		;fetch current page number
	inca			;increment
	cmp	#9		;
	blo	PIA		;<9? move on...
	lda	#0		;>=9? wrap to zero...
PIA:	sta     PAGE            ;store new value
	jsr	DISP		;update display
PIB:	rts

;--- Increment MIDI note/ctl number

NUMINC:	lda	LOCK		;check lockout status
	FAR_BNE	NIEND		;if on, ignore...

	ldx     PAGE		;branch off current page number
	cpx	#1            	;
        beq     NIA             ;...if Relay 1
	cpx	#2            	;
        beq     NIB             ;...if Relay 2
	cpx	#3            	;
        beq     NIC             ;...if Relay 3
	cpx	#4            	;
        beq     NID             ;...if Relay 4
	cpx	#5            	;
        beq     NIE             ;...if Relay 5
	cpx	#6            	;
        beq     NIF             ;...if Relay 6
	cpx	#7            	;
        beq     NIG             ;...if Relay 7
	cpx	#8            	;
        beq     NIH             ;...if Relay 8

	;must be Dimmer 1

	lda     DIM1            ;fetch current controller assignment
        inca                    ;increment
	and	#$7F		;constrain to 0-127
	sta     DIM1            ;save new controller assignment
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM2		;save Dimmer 2 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM3		;save Dimmer 3 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM4		;save Dimmer 4 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM5		;save Dimmer 5 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM6		;save Dimmer 6 value
        jmp	NIEND		;

	;Relay 1

NIA:    lda     RELAY1          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY1          ;save new code assignment
        jmp	NIEND		;

	;Relay 2

NIB:    lda     RELAY2          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY2          ;save new code assignment
        jmp	NIEND		;

	;Relay 3

NIC:    lda     RELAY3          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY3          ;save new code assignment
        jmp	NIEND		;

	;Relay 4

NID:    lda     RELAY4          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY4          ;save new code assignment
        jmp	NIEND		;

	;Relay 5

NIE:    lda     RELAY5          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY5          ;save new code assignment
        jmp	NIEND		;

	;Relay 6

NIF:    lda     RELAY6          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY6          ;save new code assignment
        jmp	NIEND		;

	;Relay 7

NIG:    lda     RELAY7          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY7          ;save new code assignment
        jmp	NIEND		;

	;Relay 8

NIH:    lda     RELAY8          ;fetch current code assignment
        inca                    ;increment
	sta     RELAY8          ;save new code assignment

NIEND:	jsr	DISP		;update display
	rts

;--- Decrement MIDI note/ctl number

NUMDEC:	lda	LOCK		;check lockout status
	FAR_BNE	NDEND		;if on, ignore...

	ldx     PAGE		;branch off current page number
	cpx	#1              ;
        beq     NDA             ;...if Relay 1
	cpx	#2            	;
        beq     NDB             ;...if Relay 2
	cpx	#3            	;
        beq     NDC             ;...if Relay 3
	cpx	#4            	;
        beq     NDD             ;...if Relay 4
	cpx	#5            	;
        beq     NDE             ;...if Relay 5
	cpx	#6            	;
        beq     NDF             ;...if Relay 6
	cpx	#7            	;
        beq     NDG             ;...if Relay 7
	cpx	#8            	;
        beq     NDH             ;...if Relay 8

	;must be Dimmer 1

	lda     DIM1            ;fetch current controller assignment
        deca                    ;decrement
	and	#$7F		;constrain to 0-127
	sta     DIM1            ;save new controller assignment
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM2		;save Dimmer 2 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM3		;save Dimmer 3 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM4		;save Dimmer 4 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM5		;save Dimmer 5 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM6		;save Dimmer 6 value
	jmp	NDEND		;

	;Relay 1

NDA:    lda     RELAY1          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY1          ;save new code assignment
	jmp	NDEND		;

	;Relay 2

NDB:    lda     RELAY2          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY2          ;save new code assignment
	jmp	NDEND		;

	;Relay 3

NDC:    lda     RELAY3          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY3          ;save new code assignment
	jmp	NDEND		;

	;Relay 4

NDD:    lda     RELAY4          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY4          ;save new code assignment
	jmp	NDEND		;

	;Relay 5

NDE:    lda     RELAY5          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY5          ;save new code assignment
	jmp	NDEND		;

	;Relay 6

NDF:    lda     RELAY6          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY6          ;save new code assignment
	jmp	NDEND		;

	;Relay 7

NDG:    lda     RELAY7          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY7          ;save new code assignment
	jmp	NDEND		;

	;Relay 8

NDH:    lda     RELAY8          ;fetch current code assignment
        deca                    ;decrement
	sta     RELAY8          ;save new code assignment
	jmp	NDEND		;

NDEND:	jsr     DISP            ;update display
	rts

;--- Select MIDI note/ctl number with fader

NUMFDR: lda	LOCK		;check lockout status
	FAR_BNE	NFEND		;if on, ignore...

	lda	FDR		;fetch fader value
	ldx     PAGE		;branch off current page number
	cpx	#1              ;
        beq     NFA             ;...if Relay 1
	cpx	#2            	;
        beq     NFB             ;...if Relay 2
	cpx	#3            	;
        beq     NFC             ;...if Relay 3
	cpx	#4            	;
        beq     NFD             ;...if Relay 4
	cpx	#5            	;
        beq     NFE             ;...if Relay 5
	cpx	#6            	;
        beq     NFF             ;...if Relay 6
	cpx	#7            	;
        beq     NFG             ;...if Relay 7
	cpx	#8            	;
        beq     NFH             ;...if Relay 8

	;must be Dimmer 1

 	lsra			;constrain to 0-127
	sta     DIM1            ;save new controller assignment
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM2		;save Dimmer 2 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM3		;save Dimmer 3 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM4		;save Dimmer 4 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM5		;save Dimmer 5 value
	inca			;increment
	and	#$7F		;constrain to 0-127
	sta	DIM6		;save Dimmer 6 value
	jmp	NFEND		;

	;Relay 1

NFA:	sta	RELAY1		;save code for Relay 1
	jmp	NFEND		;

	;Relay 2

NFB:	sta	RELAY2		;save code for Relay 2
	jmp	NFEND		;

	;Relay 3

NFC:	sta	RELAY3		;save code for Relay 3
	jmp	NFEND		;

	;Relay 4

NFD:	sta	RELAY4		;save code for Relay 4
	jmp	NFEND		;

	;Relay 5

NFE:	sta	RELAY5		;save code for Relay 5
	jmp	NFEND		;

	;Relay 6

NFF:	sta	RELAY6		;save code for Relay 6
	jmp	NFEND		;

	;Relay 7

NFG:	sta	RELAY7		;save code for Relay 7
	jmp	NFEND		;

	;Relay 8

NFH:	sta	RELAY8		;save code for Relay 8

NFEND:	jsr	DPD		;update display (number only!)
	rts

;--- Update relays

RUPD8:	lda	RLYMAP		;get bitmap
	jsr	SPI_IO		;send data
        X0_HI                   ;latch data
        X0_LO                   ;
	lda	#0		;
	sta	REL_TMR 	;start timer here
	lda	#1		;set flag
	sta	CLOSED		;
	rts

;--- Process incoming MIDI messages (buffer has notes and controllers)

PROC:	brclr	QFULL,MP_FLAGS,PROC2
	lda	#11		;turn on overflow LED
	jsr	LED_ON		; (does not shut off!)
	rts

PROC2:	lda     MP_RSTAT        ;fetch Status Byte
	cmp	#$90		;compare to Note Off Status
	FAR_BLO	PEND		;Note Off? ignore...

	and	#$0F		;get channel
	cmp	CHAN		;is it the one we selected?
	FAR_BNE	PEND		;different channel? ignore...

	;message is Note On or Controller on the proper channel

	lda	MP_RSTAT	;fetch status byte again
	cmp	#$AF		;compare to Note On Status
	FAR_BHI	PCTL		;not=Note On? go process controller...

	;message is Note On

        lda     MP_DATA2        ;look at velocity
	FAR_BEQ	PEND		;=0? ignore message...

	;message is Note On w/nonzero velocity

        lda     MP_DATA1        ;yes? branch off note number
        cmp     RELAY1          ;
	beq	PA		;...matches Relay 1
        cmp     RELAY2          ;
	beq	PB		;...matches Relay 2
        cmp     RELAY3          ;
	beq	PC		;...matches Relay 3
        cmp     RELAY4          ;
	FAR_BEQ	PD		;...matches Relay 4
        cmp     RELAY5          ;
	FAR_BEQ	PE		;...matches Relay 5
        cmp     RELAY6          ;
	FAR_BEQ	PF		;...matches Relay 6
        cmp     RELAY7          ;
	FAR_BEQ	PG		;...matches Relay 7
        cmp     RELAY8          ;
	FAR_BEQ	PH		;...matches Relay 8

	;note number does not match

	jmp	PEND		;ignore...

	;Relay 1

PA:	lda     #$01            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#0		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#0		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 2

PB:	lda     #$10            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#4		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#4		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 3

PC:	lda     #$02            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#8		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#8		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 4

PD:	lda     #$20            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#12		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#12		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 5

PE:	lda     #$04            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#1		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#1		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 6

PF:	lda     #$40            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#5		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#5		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 7

PG:	lda     #$08            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#9		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#9		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;
 
	;Relay 8

PH:	lda     #$80            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#13		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#13		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;process controller message

PCTL:   lda     MP_DATA1        ;branch off controller number
        cmp     DIM1            ;
	beq	PCA		;...matches Dimmer 1
        cmp     DIM2            ;
	FAR_BEQ	PCB		;...matches Dimmer 2
        cmp     DIM3            ;
	FAR_BEQ	PCC		;...matches Dimmer 3
        cmp     DIM4            ;
	FAR_BEQ	PCD		;...matches Dimmer 4
        cmp     DIM5            ;
	FAR_BEQ	PCE		;...matches Dimmer 5
        cmp     DIM6            ;
	FAR_BEQ	PCF		;...matches Dimmer 6

	add	#128		;add 128 to check code
        cmp     RELAY1          ;
	FAR_BEQ	PCG		;...matches Relay 1
        cmp     RELAY2          ;
	FAR_BEQ	PCH		;...matches Relay 2
        cmp     RELAY3          ;
	FAR_BEQ	PCI		;...matches Relay 3
        cmp     RELAY4          ;
	FAR_BEQ	PCJ		;...matches Relay 4
        cmp     RELAY5          ;
	FAR_BEQ	PCK		;...matches Relay 5
        cmp     RELAY6          ;
	FAR_BEQ	PCL		;...matches Relay 6
        cmp     RELAY7          ;
	FAR_BEQ	PCM		;...matches Relay 7
        cmp     RELAY8          ;
	FAR_BEQ	PCN		;...matches Relay 8

	;controller number does not match

	jmp	PEND		;

	;Dimmer 1

PCA:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts

	lda	MP_DATA2	;check new value
	FAR_BEQ	PCAA		;if zero, move on...

	lda	#2		;if nonzero, turn LED on
	jsr	LED_ON		;
	jmp	PEND		;leave...

PCAA:	lda	#2		;if zero, turn LED off
	jsr	LED_OFF		;

	lda	AAV		;get AAV status
	FAR_BEQ	PEND		;AAV off? ignore message...
	
	;AAV is on - advance Projector 1 using Relay 1

	lda	#0		;turn LED on
	jsr	LED_ON		;
	lda     #$01            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	jsr	RUPD8		;toggle relay
	lda	#0		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Dimmer 2

PCB:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts

	lda	MP_DATA2	;check new value
	FAR_BEQ	PCBB		;if zero, move on...

	lda	#6		;if nonzero, turn LED on
	jsr	LED_ON		;
	jmp	PEND		;leave...

PCBB:	lda	#6		;if zero, turn LED off
	jsr	LED_OFF		;

	lda	AAV		;get AAV status
	FAR_BEQ	PEND		;AAV off? ignore message...
	
	;AAV is on - advance Projector 2 using Relay 3

	lda	#8		;turn LED on
	jsr	LED_ON		;
	lda     #$02            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	jsr	RUPD8		;toggle relay
	lda	#8		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Dimmer 3

PCC:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts

	lda	MP_DATA2	;check new value
	FAR_BEQ	PCCC		;if zero, move on...

	lda	#10		;if nonzero, turn LED on
	jsr	LED_ON		;
	jmp	PEND		;leave...

PCCC:	lda	#10		;if zero, turn LED off
	jsr	LED_OFF		;

	lda	AAV		;get AAV status
	FAR_BEQ	PEND		;AAV off? ignore message...
	
	;AAV is on - advance Projector 3 using Relay 5

	lda	#1		;turn LED on
	jsr	LED_ON		;
	lda	#$04		;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	jsr	RUPD8		;toggle relay
	lda	#1		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Dimmer 4

PCD:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts

	lda	MP_DATA2	;check new value
	FAR_BEQ	PCDD		;if zero, move on...

	lda	#14		;if nonzero, turn LED on
	jsr	LED_ON		;
	jmp	PEND		;leave...

PCDD:	lda	#14		;if zero, turn LED off
	jsr	LED_OFF		;

	lda	AAV		;get AAV status
	FAR_BEQ	PEND		;AAV off? ignore message...
	
	;AAV is on - advance Projector 4 using Relay 7

	lda	#9		;turn LED on
	jsr	LED_ON		;
	lda     #$08            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	jsr	RUPD8		;toggle relay
	lda	#9		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Dimmer 5 (no AAV, no LED)

PCE:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts
	jmp	PEND		;leave...

	;Dimmer 6 (no AAV)

PCF:	sei			;disable all interrupts
	lda	MP_RSTAT	;get status byte
	jsr	MIDI_PUT	;send it
	lda	MP_DATA1	;get controller number
	jsr	MIDI_PUT	;
	lda	MP_DATA2	;get controller value
	jsr	EE_READ 	;fetch curve value
	sta	MP_DATA2	;save new value
	jsr	MIDI_PUT	;send mapped value
	cli			;enable all interrupts
	jmp	PEND		;leave...

	;Relay 1

PCG:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$01            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#0		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#0		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 2

PCH:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$10            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#4		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#4		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 3

PCI:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$02            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#8		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#8		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 4

PCJ:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$20            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#12		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#12		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 5

PCK:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$04            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#1		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#1		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 6

PCL:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$40            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#5		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#5		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;

	;Relay 7

PCM:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$08            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#9		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#9		;turn LED off
	jsr	LED_OFF		;
	jmp	PEND		;
 
	;Relay 8

PCN:	lda	MP_DATA2	;get controller value
	cmp	#64		;process only if data value>63
	FAR_BLO	PEND		;

	lda     #$80            ;load value
	ora	RLYMAP		;combine with existing relay status
	sta	RLYMAP		;save new map
	lda	#13		;turn LED on
	jsr	LED_ON		;
	jsr	RUPD8		;toggle relay
	lda	#13		;turn LED off
	jsr	LED_OFF		;

PEND:	rts

;--- Update display

DISP:	lda	#0		;display top line (fixed characters)
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "CH AAV        # "

	lda	#0		;display bottom line (fixed characters)
	ldx	#1		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "            =   "

	;display page heading and MIDI message type

	lda	PAGE		;get page number
	beq	DPA		;=0 (dimmer)? branch...

	lda	#7		;must be relay; display page name
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S " RELAY"

	lda	#15		;display page number
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	PAGE		;display value is same as page number
        jsr	LCD_PUT_I	;

	jmp	DPB		;move on

DPA:	lda	#7		;must be dimmer; display page name
	ldx	#0		;
	jsr	LCD_GOTOXY	;
        LCD_PUT_S "DIMMER"

	lda	#15		;display dimmer number
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	lda	#1		;display value is 1
        jsr	LCD_PUT_I	;
	
	lda	#7		;disply message type name
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "CNTRL"	;

	;display MIDI channel

DPB:	lda	#1		;set cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	CHAN		;fetch channel number
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it

	;display AAV function status

	lda	AAV		;get status
	beq	DPC		;=0 (OFF)? branch...

	lda	#3		;=1 (ON)? set cursor
        ldx     #1              ;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " ON"         ;
	jmp	DPD		;

DPC:	lda	#3		;=0 (OFF)? set cursor
        ldx     #1              ;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "OFF"         ;
	
	;display MIDI controller/note number

DPD:	lda	#15		;set cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;

	lda	PAGE		;get page number
	cmp	#1		;
	beq	DPE		;branch if Relay 1
	cmp	#2		;
	beq	DPF		;branch if Relay 2
	cmp	#3		;
	beq	DPG		;branch if Relay 3
	cmp	#4		;
	beq	DPH		;branch if Relay 4
	cmp	#5		;
	beq	DPI		;branch if Relay 5
	cmp	#6		;
	beq	DPJ		;branch if Relay 6
	cmp	#7		;
	beq	DPK		;branch if Relay 7
	cmp	#8		;
	beq	DPL		;branch if Relay 8

	;it must be Dimmer 1

	lda	DIM1		;fetch controller number
	jsr	LCD_PUT_RJ3_I	;display it
	rts

	;Relay 1

DPE:	lda	RELAY1		;fetch note number
	jmp	DPEND		;
	
	;Relay 2

DPF:	lda	RELAY2		;fetch note number
	jmp	DPEND		;

	;Relay 3

DPG:	lda	RELAY3		;fetch note number
	jmp	DPEND		;

	;Relay 4

DPH:	lda	RELAY4		;fetch note number
	jmp	DPEND		;
	
	;Relay 5

DPI:	lda	RELAY5		;fetch note number
	jmp	DPEND		;
	
	;Relay 6

DPJ:	lda	RELAY6		;fetch note number
	jmp	DPEND		;
	
	;Relay 7

DPK:	lda	RELAY7		;fetch note number
	jmp	DPEND		;
	
	;Relay 8

DPL:	lda	RELAY8		;fetch note number

DPEND:	cmp	#128		;
	bhs	DPEND2		;128-255 (Controller mode)? branch...

	;must be Note mode (code 0-127)

	jsr	LCD_PUT_RJ3_I	;display number

	lda	#7		;display message type name
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S " NOTE"	;
	rts

	;must be Controller mode (code 128-255)

DPEND2:	sub	#128		;subtract 128 from code to get number
	jsr	LCD_PUT_RJ3_I	;display number

	lda	#7		;display message type name
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "CNTRL"	;
	rts
	
;--- Save all parameters to EEPROM

SAVE:	jsr	LCD_CLEAR	;clear display

	lda	#0		;notify user
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "S t o r i n g..."
	jsr	DELAY_1SEC

	lda	#146
	ldx	CHAN
        jsr     EE_WRITE        ;store it
	lda	#129
	ldx	AAV
        jsr     EE_WRITE        ;store it
	lda	#130
	ldx	PAGE
        jsr     EE_WRITE        ;store it
	lda	#131
	ldx	RELAY1
        jsr     EE_WRITE        ;store it
	lda	#132
	ldx	RELAY2
        jsr     EE_WRITE        ;store it
	lda	#133
	ldx	RELAY3
        jsr     EE_WRITE        ;store it
	lda	#134
	ldx	RELAY4
        jsr     EE_WRITE        ;store it
	lda	#135
	ldx	RELAY5
        jsr     EE_WRITE        ;store it
	lda	#136
	ldx	RELAY6		;
        jsr     EE_WRITE        ;store it
	lda	#137
	ldx	RELAY7		;
        jsr     EE_WRITE        ;store it
	lda	#138
	ldx	RELAY8		;
        jsr     EE_WRITE        ;store it
	lda	#139
	ldx	DIM1		;
        jsr     EE_WRITE        ;store it
	lda	#140
	ldx	DIM2		;
        jsr     EE_WRITE        ;store it
	lda	#141
	ldx	DIM3		;
        jsr     EE_WRITE        ;store it
	lda	#142
	ldx	DIM4		;
        jsr     EE_WRITE        ;store it
	lda	#143
	ldx	DIM5		;
        jsr     EE_WRITE        ;store it
	lda	#144
	ldx	DIM6		;
        jsr     EE_WRITE        ;store it
	lda	#145
	ldx	LOCK		;
        jsr     EE_WRITE        ;store it
	jsr	DISP		;restore display
        rts

;--- Load preset parameters at powerup

LOAD:	lda	#128		;fetch value
	jsr	EE_READ 	;
	lsla			;multiply by 2 (range: 0,2,4,...,254)
	sta	RELAY_DUR	;
	lda	#146		;
	jsr	EE_READ 	;fetch value
	sta	CHAN		;store value
	lda	#129		;
	jsr	EE_READ 	;fetch value
	sta	AAV		;store value
	lda	#130		;
	jsr	EE_READ 	;fetch value
	sta	PAGE		;store value
	lda	#131		;
	jsr	EE_READ 	;fetch value
	sta	RELAY1		;store value
	lda	#132		;
	jsr	EE_READ 	;fetch value
	sta	RELAY2		;store value
	lda	#133		;
	jsr	EE_READ 	;fetch value
	sta	RELAY3		;store value
	lda	#134		;
	jsr	EE_READ 	;fetch value
	sta	RELAY4		;store value
	lda	#135		;
	jsr	EE_READ 	;fetch value
	sta	RELAY5		;store value
	lda	#136		;
	jsr	EE_READ		;fetch value
	sta	RELAY6		;store value
	lda	#137		;
	jsr	EE_READ		;fetch value
	sta	RELAY7		;store value
	lda	#138		;
	jsr	EE_READ		;fetch value
	sta	RELAY8		;store value
	lda	#139		;
	jsr	EE_READ		;fetch value
	sta	DIM1		;store value
	lda	#140		;
	jsr	EE_READ		;fetch value
	sta	DIM2		;store value
	lda	#141		;
	jsr	EE_READ		;fetch value
	sta	DIM3		;store value
	lda	#142		;
	jsr	EE_READ		;fetch value
	sta	DIM4		;store value
	lda	#143		;
	jsr	EE_READ		;fetch value
	sta	DIM5		;store value
	lda	#144		;
	jsr	EE_READ		;fetch value
	sta	DIM6		;store value

	lda	#0		;unlock to set AAV
	sta	LOCK		;
	jsr	AAVTOG		;toggle twice to reset LED
	jsr	AAVTOG		;

	lda	#145		;
	jsr	EE_READ		;fetch value
	sta	LOCK		;store value
	jsr	LCKTOG		;toggle twice to reset LED
	jsr	LCKTOG		;
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

;--- Process Status Bytes (SYSEX and EOX)

SCI_RX_CBCK_S:
	sta	TEMPCLASS
	stx	TEMPVAL
	txa			;transfer data to acca

RXST:	ldx	SEX_CAP 	;is capture mode enable?
	beq	RX_DUNS 	;=0 (no)? branch...

RX3:	cmp	#$F0		;yes? is message a SYSEX?
	beq	RXSEX		;yes? branch...

	ldx	#0		;no? disable queue
	stx	SEX_Q_ENABLE	; (Bob had this as "STA")

	;treat any other status byte as EOX

RXEOX:	ldx	#0		;yes? disable capture mode
	stx	SEX_CAP 	; (clear flag)
	jsr	CAPTOG		;turn capture mode off, restore display...
	rti			;leave...

RXSEX:	ldx	#1		;enable queue
	stx	SEX_Q_ENABLE	; (set flag)
	stx	SEX_ID		;get ready for next (ID) byte
	rti			;leave...

RX_DUNS: lda	    TEMPCLASS
	 ldx	    TEMPVAL
	 jmp	    SCI_RX_CBCK_S_RET

;--- Process 1st Data Bytes (System Exclusive data)

SCI_RX_CBCK_D1:
	sta	TEMPCLASS
	stx	TEMPVAL

	lda	SEX_Q_WRITE	;is the queue done/full?
	cmp	#129		;
	bhs	RX_OL		;yes? branch...
	txa			;no? transfer data to acca

	ldx	SEX_Q_ENABLE	;is SYSEX queue enabled?
	beq	RX_DUN		;=0 (no)? branch...
RXNQ:	ldx	SEX_ID		;see if we are at 1st data byte (ID)
	beq	RXNQA		;no? move on to enqueue data...

	cmp	#$7D		;yes? SysEx ID match?
	bne	RX_RST		;no? reset queue enable...
	lda	#0		;yes? reset ID flag
	sta	SEX_ID		;
	rti			;yes? do not enqueue ID byte...return

RXNQA:	ldx	SEX_Q_WRITE	;(yes)? enqueue data

	cpx	#SEX_Q_LEN
	blo	RXNQA2

	txa
	sub	#SEX_Q_LEN
	tax
	lda	TEMPVAL
	sta	SEX_Q,X
	ldx	SEX_Q_WRITE
	incx
	stx	SEX_Q_WRITE
	rti

RXNQA2: sta	SEX_Q,X 	;
	incx			;
	stx	SEX_Q_WRITE	;
	rti			;leave

RX_DUN: lda	    TEMPCLASS
	ldx	    TEMPVAL
	jmp	    SCI_RX_CBCK_D1_RET

RX_OL:	ldx	#0		;reinitialize variables
        stx     SEX_Q_WRITE     ;
        stx     EE_Q_WRITE      ;
	sta	SEX_CAP 	;clear flags
	sta	SEX_Q_ENABLE	;
	sta	SEX_ID		;
	lda	#OF_LED 	;turn Data Overflow LED on
        jsr     LED_ON          ;
	rti			;return, do not enqueue

RX_RST:	ldx	#0		;disable queue
	sta	SEX_Q_ENABLE	;
	rti			;return, do not enqueue

;--- Process 2nd Data Bytes (can not be System Exclusive data)

SCI_RX_CBCK_D2:
       jmp  SCI_RX_CBCK_D2_RET
