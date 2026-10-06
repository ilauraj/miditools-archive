;===============================================================;
;								;
;       TOOL20.ASM      Rev 0.4                                 ;
;	MIDI Patch Bay						;
;								;
;	The user can patch each of four MIDI outputs to any	;
;	one of four MIDI inputs.				;
;								;
;===============================================================;
;								;
;	Operation:						;
;								;
;	HOW DO I...						;
;								;
;	...CREATE A DESIRED PATCH?				;
;	Press the desired OUTPUT key (A,B,C or D).  Select the	;
;	desired input port with the +/- keys and/or the VALUE	;
;	fader.	A "*" next to the preset number indicates that  ;
;	the preset patch has been modified.  Patches are	;
;	indicated on the LCD and the LED display.		;
;								;
;								;
;	...STORE A CREATED PATCH AS A PRESET?			;
;	Press the PRESET STORE key.  Use the +/- keys and/or	;
;	the VALUE fader to select the desired preset number	;
;	(1-16).  Press the STORE key again to store preset at	;
;	that location.	Press any OUTPUT key to resume patch	;
;	editing.						;
;								;
;								;
;	...LOAD A PRESET PATCH? 				;
;	Press the PRESET LOAD key.  Use the +/- keys and/or	;
;	the VALUE fader to select the desired preset number	;
;	(1-16).  Press the LOAD key again to load the preset.	;
;	Press any OUTPUT key to resume patch editing.		;
;								;
;								;
;	...MERGE TWO INPUTS?					;
;	MIDI merging is not supported.	Each output is allowed	;
;	one and only one input connection.			;
;								;
;---------------------------------------------------------------;
;								;
;	LCD Screen:						;
;								;
;	The cursor arrow points to the parameter that will be	;
;	modified by the +/- keys and VALUE fader.		;
;								;
;	When editing or creating a preset,			;
;								;
;	|Preset   A B C D|	where x = 1-4, nn=1-16		;
;	| *nn	  x x x x|					;
;                                                               ;
;                                                               ;
;	When selecting a preset location for patch storage,	;
;                                                               ;
;	|Store#?  A B C D|	where x = 1-4, nn=1-16		;
;	|  nn	  x x x x|					;
;								;
;                                                               ;
;	When selecting a preset patch to load,			;
;								;
;	|Load#?   A B C D|	where x=1-4, nn=1-16		;
;	|  nn	  x x x x|					;
;                                                               ;
;---------------------------------------------------------------;
;								;
;	Hardware:						;
;								;
;	This MIDItool uses the CPU board, the rack HUMAN	;
;	INTERFACE board, and the MIDI PATCH board.		;
;								;
;---------------------------------------------------------------;
;								;
;	States: 						;
;								;
;	StEdit		Edit patches				;
;	StLoad		Load patch from memory			;
;	StStore 	Store patch to memory			;
;                                                               ;
;	Actions:						;
;								;
;	IDLE		No action				;
;	ASEL		Select Output A for patching		;
;	BSEL		Select Output B for patching		;
;	CSEL		Select Output C for patching		;
;	DSEL		Select Output D for patching		;
;	ININC		Increment selected input number 	;
;	INDEC		Decrement selected input number 	;
;	INFDR		Set selected input number with fader	;
;	PREINC		Increment selected preset number	;
;	PREDEC		Decrement selected preset number	;
;	PREFDR		Set selected preset number with fader	;
;	PTDISP		Update display for patch editing	;
;	STDISP		Update display for preset storing	;
;	LDDISP		Update display for preset loading	;
;	PRDISP		Update display with preset number	;
;	ADISP		Update Output A display 		;
;	BDISP		Update Output B display 		;
;	CDISP		Update Output C display 		;
;	DDISP		Update Output D display 		;
;	STORE		Store patch as preset			;
;	LOAD		Load preset patch and display values	;
;	HDUPD8		Configure hardware			;
;	LDUPD8		Update LED display			;
;	ARWDSP		Place LCD cursor arrow			;
;	ARWCLR		Clear LCD cursor arrow			;
;								;
;===============================================================;

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
        .ABSOLUTE

; Note: This tool uses the EEPROM for storing preset memories.
;
;       Presets 1-16 are stored in EEPROM addresses 0-15.
;       The current preset # is stored in EEPROM address 16.

OUTPUT		.DS	1	;current output selected
OUTA		.DS	1	;Output A assignment
OUTB		.DS	1	;Output B assignment
OUTC		.DS	1	;Output C assignment
OUTD		.DS	1	;Output D assignment
MEMNUM          .DS     1       ;memory # for next load/store
PRESET          .DS     1       ;current preset memory #

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StEdit		EQU	0
StLoad          EQU     1
StStore         EQU     2

;--- Map application events to BIOS events

EvIdle		EQU	EV_IDLE
EvLoad		EQU	EV_SW1_ON
EvStore 	EQU	EV_SW2_ON
EvMinus 	EQU	EV_SW3_ON
EvPlus		EQU	EV_SW4_ON
EvA		EQU	EV_SW5_ON
EvB		EQU	EV_SW6_ON
EvC		EQU	EV_SW7_ON
EvD		EQU	EV_SW8_ON
EvValue 	EQU	EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0: StEdit State 1: StLoad State 2: StStore        Not
;	 Event	  NextSt,Act	  NextSt,Act	  NextSt,Act		 Used
;	 --------------------------------------------------------------------
 STM_ROW EvIdle,  StEdit,IDLE,	  StLoad,IDLE,	  StStore,IDLE,   StEdit,IDLE
 STM_ROW EvA,	  StEdit,ASEL,	  StEdit,PTDISP,  StEdit,PTDISP,  StEdit,IDLE
 STM_ROW EvB,	  StEdit,BSEL,	  StEdit,PTDISP,  StEdit,PTDISP,  StEdit,IDLE
 STM_ROW EvC,	  StEdit,CSEL,	  StEdit,PTDISP,  StEdit,PTDISP,  StEdit,IDLE
 STM_ROW EvD,	  StEdit,DSEL,	  StEdit,PTDISP,  StEdit,PTDISP,  StEdit,IDLE
 STM_ROW EvPlus,  StEdit,ININC,   StLoad,PREINC,  StStore,PREINC, StEdit,IDLE
 STM_ROW EvMinus, StEdit,INDEC,   StLoad,PREDEC,  StStore,PREDEC, StEdit,IDLE
 STM_ROW EvValue, StEdit,INFDR,   StLoad,PREFDR,  StStore,PREFDR, StEdit,IDLE
 STM_ROW EvLoad,  StLoad,LDDISP,  StEdit,LOAD,	  StLoad,LDDISP,  StEdit,IDLE
 STM_ROW EvStore, StStore,STDISP, StStore,STDISP, StEdit,STORE,   StEdit,IDLE

        STM_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

APPLICATION:

;--- Initialize variables

	lda	#16		;get current preset number
	jsr	EE_READ 	; from EEPROM
	sta	MEMNUM		;save memory number
	sta	PRESET		;save current preset

;--- Initialize display

	jsr	GREETING

	LCD_PUT_S "20:         MIDI"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "v.3    Patch Bay"
	jsr	DELAY_1SEC

	jsr	LCD_CLEAR

	LCD_PUT_S "         A B C D"

	jsr	LOADND		;get current preset from EEPROM

	jsr	PTDISP		;update display
	jsr	ASEL		;

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--- No action

IDLE:	rts

;--- Select Output A for patching

ASEL:	lda	#'A'            ;fetch output code
	sta	OUTPUT		;save selected output
	jsr	ARWDSP		;display cursor arrow
        rts

;--- Select Output B for patching

BSEL:	lda	#'B'            ;fetch output code
	sta	OUTPUT		;save selected output
	jsr	ARWDSP		;display cursor arrow
        rts

;--- Select Output C for patching

CSEL:	lda	#'C'            ;fetch output code
	sta	OUTPUT		;save selected output
	jsr	ARWDSP		;display cursor arrow
        rts

;--- Select Output D for patching

DSEL:	lda	#'D'            ;fetch output code
	sta	OUTPUT		;save selected output
	jsr	ARWDSP		;display cursor arrow
        rts

;--- Increment selected input number

ININC:	lda	#1		;notify user
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#'*'            ;
	jsr	LCD_PUT_C	;

	ldx	OUTPUT		;branch off selected output
	cpx	#'A'            ;
	beq	IIA		;...if A
	cpx	#'B'            ;
	beq	IIB		;...if B
	cpx	#'C'            ;
	beq	IIC		;...if C
	cpx	#'D'            ;
	beq	IID		;...if D

	ldx	#'A'            ;should never get here
	stx	OUTPUT		; (just in case)

IIA:	lda	OUTA		;fetch value
	inca			;increment
	and	#$03		;constrain to 0-3
	sta	OUTA		;store new Output A
	jsr	HDUPD8		;update hardware
	jsr	ADISP		;update display
        rts

IIB:	lda	OUTB		;fetch value
	inca			;increment
	and	#$03		;constrain to 0-3
	sta	OUTB		;store new Output B
	jsr	HDUPD8		;update hardware
	jsr	BDISP		;update display
        rts

IIC:	lda	OUTC		;fetch value
	inca			;increment
	and	#$03		;constrain to 0-3
	sta	OUTC		;store new Output C
	jsr	HDUPD8		;update hardware
	jsr	CDISP		;update display
        rts

IID:	lda	OUTD		;fetch old value
	inca			;increment
	and	#$03		;constrain to 0-3
	sta	OUTD		;store new Output D
	jsr	HDUPD8		;update hardware
	jsr	DDISP		;update display
        rts

;--- Decrement selected input number

INDEC:	lda	#1		;notify user
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#'*'            ;
	jsr	LCD_PUT_C	;

	ldx	OUTPUT		;branch off current output
	cpx	#'A'            ;
	beq	IDA		;...if A
	cpx	#'B'            ;
	beq	IDB		;...if B
	cpx	#'C'            ;
	beq	IDC		;...if C
	cpx	#'D'            ;
	beq	IDD		;...if D

	ldx	#'A'            ;should never get here
	stx	OUTPUT		; (just in case)

IDA:	lda	OUTA		;fetch value
	deca			;decrement
	and	#$03		;constrain to 0-3
	sta	OUTA		;store new Output A
	jsr	HDUPD8		;update hardware
	jsr	ADISP		;update display
	rts

IDB:	lda	OUTB		;fetch value
	deca			;decrement
	and	#$03		;constrain to 0-3
	sta	OUTB		;store new Output B
	jsr	HDUPD8		;update hardware
	jsr	BDISP		;update display
	rts

IDC:	lda	OUTC		;fetch value
	deca			;decrement
	and	#$03		;constrain to 0-3
	sta	OUTC		;store new Output C
	jsr	HDUPD8		;update hardware
	jsr	CDISP		;update display
	rts

IDD:	lda	OUTD		;fetch value
	deca			;decrement
	and	#$03		;constrain to 0-3
	sta	OUTD		;store new Output D
	jsr	HDUPD8		;update hardware
	jsr	DDISP		;update display
        rts

;--- Set selected input number with fader

INFDR:	lda	#1		;notify user
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#'*'            ;
	jsr	LCD_PUT_C	;

	lda	FDR		;fetch fader value
	lsra			;constrain to 0-3
	lsra			;
        lsra                    ;
        lsra                    ;
        lsra                    ;
        lsra                    ;

	ldx	OUTPUT		;branch off current output
	cpx	#'A'            ;
	beq	IFA		;...if A
	cpx	#'B'            ;
	beq	IFB		;...if B
	cpx	#'C'            ;
	beq	IFC		;...if C
	cpx	#'D'            ;
	beq	IFD		;...if D

	ldx	#'A'            ;should never get here
	stx	OUTPUT		; (just in case)

IFA:	sta	OUTA		;store new Output A
	jsr	HDUPD8		;update hardware
	jsr	ADISP		;update display
        rts

IFB:	sta	OUTB		;store new Output B
	jsr	HDUPD8		;update hardware
	jsr	BDISP		;update display
        rts

IFC:	sta	OUTC		;store new Output C
	jsr	HDUPD8		;update hardware
	jsr	CDISP		;update display
        rts

IFD:	sta	OUTD		;store new Output D
	jsr	HDUPD8		;update hardware
	jsr	DDISP		;update display
        rts

;--- Increment selected preset number

PREINC: lda	MEMNUM		;fetch number
	inca			;increment
	and	#$0F		;constrain to 0-15
	sta	MEMNUM		;save new value
	jsr	PRDISP		;update display
        rts

;--- Decrement selected preset number

PREDEC: lda	MEMNUM		;fetch number
	deca			;decrement
	and	#$0F		;constrain to 0-15
	sta	MEMNUM		;save new value
	jsr	PRDISP		;update display
        rts

;--- Set selected preset number with fader

PREFDR: lda	FDR		;fetch fader value
	lsra			;constrain to 0-15
	lsra			;
        lsra                    ;
        lsra                    ;
	sta	MEMNUM		;save new value
	jsr	PRDISP		;update display
        rts

;--- Update display for patch editing

PTDISP: lda	#0		;display message
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "PRESET  "    ;

	lda	PRESET		;fetch preset number
	sta	MEMNUM		;restore memory number
	jsr	PRDISP		;update display
        rts

;--- Update display for preset storing

STDISP: lda	#0		;notify user
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "STORE#? "    ;
        rts

;--- Update display for preset loading

LDDISP: lda	#0		;notify user
	ldx	#0		;
	jsr	LCD_GOTOXY	;
	LCD_PUT_S "LOAD#?  "    ;
        rts

;--- Update display with preset number

PRDISP: lda	#3		;position cursor
        ldx     #1              ;
	jsr	LCD_GOTOXY	;
	lda	MEMNUM		;fetch value
	inca			;increment to display as 1-16
	jsr	LCD_PUT_RJ2_I	;display it
        rts

;--- Update Output A display

ADISP:	lda	#9		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OUTA		;fetch value
	inca			;increment to display as 1-4
	jsr	LCD_PUT_I	;display it
        rts

;--- Update Output B display

BDISP:	lda	#11		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OUTB		;fetch value
	inca			;increment to display as 1-16
	jsr	LCD_PUT_I	;display it
        rts

;--- Update Output C display

CDISP:	lda	#13		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OUTC		;fetch value
	inca			;increment to display as 1-16
	jsr	LCD_PUT_I	;display it
        rts

;--- Update Output D display

DDISP:	lda	#15		;position cursor
	ldx	#1		;
	jsr	LCD_GOTOXY	;
	lda	OUTD		;fetch value
	inca			;increment to display as 1-16
	jsr	LCD_PUT_I	;display it
        rts

;--- Store patch as preset

; Preset Byte Value format
; ------------------------
;
;   MSB                                LSB
; -----------------------------------------
; | d1 | d0 | c1 | c0 | b1 | b0 | a1 | a0 |
; -----------------------------------------
;  \ OUT D / \ OUT C / \ OUT B / \ OUT A /
;
; For each output, x=a,b,c or d
;
;   bit values
;     x1 x0	  input assigned
;     -- --	  --------------
;      0  0	     1
;      0  1	     2
;      1  0	     3
;      1  1	     4

STORE:	lda	OUTD		;create preset byte value
        lsla                    ;
        lsla                    ;
        ora     OUTC            ;
        lsla                    ;
        lsla                    ;
        ora     OUTB            ;
        lsla                    ;
        lsla                    ;
        ora     OUTA            ;

	tax			;transfer acca to x
	lda	MEMNUM		;fetch memory number
        jsr     EE_WRITE        ;store it

	lda	#1		;remove modification notice
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;notify user
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "Storing!"

	jsr	DELAY_1SEC	;pause

	lda	MEMNUM		;fetch preset
	sta	PRESET		;save preset
	jsr	PTDISP		;update display
        rts

;--- Load preset patch

; Preset Byte Value format
; ------------------------
;
;   MSB                                LSB
; -----------------------------------------
; | d1 | d0 | c1 | c0 | b1 | b0 | a1 | a0 |
; -----------------------------------------
;  \ OUT D / \ OUT C / \ OUT B / \ OUT A /
;
;
; For each output, x=a,b,c or d
;
;   bit values
;     x1 x0	  input assigned
;     -- --	  --------------
;      0  0	     1
;      0  1	     2
;      1  0	     3
;      1  1	     4

LOAD:	lda	#1		;remove modification notice
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
	lda	#' '            ;
	jsr	LCD_PUT_C	;

	lda	#0		;notify user
        ldx     #0              ;
        jsr     LCD_GOTOXY      ;
	LCD_PUT_S "Loading!"

	jsr	DELAY_1SEC	;pause

	lda	MEMNUM		;fetch preset
	sta	PRESET		;save preset
	jsr	PTDISP		;update display

	;enter here to skip the above display

LOADND: lda	#0		;reset outputs
        sta     OUTA            ;
        sta     OUTB            ;
        sta     OUTC            ;
        sta     OUTD            ;

	lda	MEMNUM		;fetch preset number
	jsr	EE_READ 	;fetch preset
	tax			;transfer acca to x

	and	#$03		;get Output A setup
	sta	OUTA		;save new value

	lsrx			;line up Output B data
        lsrx                    ;
	txa			;get Output B setup
        and     #$03            ;
	sta	OUTB		;save new value

	lsrx			;line up Output C data
        lsrx                    ;
	txa			;get Output C setup
        and     #$03            ;
	sta	OUTC		;save new value

	lsrx			;line up Output D data
        lsrx                    ;
	txa			;get Output D setup
        and     #$03            ;
	sta	OUTD		;save new value

	jsr	HDUPD8		;update hardware

	ldx	MEMNUM		;fetch preset
	stx	PRESET		;save preset
	lda	#16		;save in EEPROM
        jsr     EE_WRITE        ;

	jsr	ADISP		;update display
	jsr	BDISP		;
	jsr	CDISP		;
	jsr	DDISP		;
        rts

;--- Configure hardware

; Control Byte format
; -------------------
;
;   MSB                                LSB
; -----------------------------------------
; | d1 | d0 | c1 | c0 | b1 | b0 | a1 | a0 |
; -----------------------------------------
;  \ OUT D / \ OUT C / \ OUT B / \ OUT A /
;
;
; For each output, x=a,b,c or d
;
;   bit values
;     x1 x0	  input assigned
;     -- --	  --------------
;      0  0	     1
;      0  1	     2
;      1  0	     3
;      1  1	     4

HDUPD8: lda	OUTD		;create Control Byte
        lsla                    ;
        lsla                    ;
        ora     OUTC            ;
        lsla                    ;
        lsla                    ;
        ora     OUTB            ;
        lsla                    ;
        lsla                    ;
        ora     OUTA            ;

        X0_HI                   ;make sure latch clock is hi
        WR_DATA                 ;write data to data bus
        X0_LO                   ;cycle latch clock hi-lo-hi
        X0_HI                   ;

	jsr	LDUPD8		;update display
	rts

;--- Update LED display

LDUPD8: lda	#0		;clear all LEDs
        sta     LEDIMG0         ;
        sta     LEDIMG1         ;

	lda	OUTA		;fetch Output A
        lsla                    ;multiply by 4 to get LED code
        lsla                    ;
        cmp     #8              ;corresponding LED in LEDIMG1?
	bhs	OAA		;yes? branch...
	tax			;no? lookup bit for this code
        lda     LEDMASK,X       ;
        add     LEDIMG0         ;set this bit
        sta     LEDIMG0         ;
	jmp	UPLB		;jump...

OAA:	sub	#8		;offset for high byte of image
        tax                     ;lookup bit mask for this code
        lda     LEDMASK,X       ;
        add     LEDIMG1         ;set this bit
        sta     LEDIMG1         ;

UPLB:	lda	OUTB		;fetch Output B
        lsla                    ;multiply by 4 and add 1 to
	lsla			; get LED code
        add     #1              ;
        cmp     #8              ;corresponding LED in LEDIMG1?
	bhs	OBA		;yes?
	tax			;no? lookup bit for this code
        lda     LEDMASK,X       ;
        add     LEDIMG0         ;set this bit
        sta     LEDIMG0         ;
        jmp     UPLC            ;

OBA:	sub	#8		;offset for high byte of image
        tax                     ;lookup bit mask for this code
        lda     LEDMASK,X       ;
        add     LEDIMG1         ;set this bit
        sta     LEDIMG1         ;

UPLC:	lda	OUTC		;fetch Output C
        lsla                    ;multiply by 4 and add 2 to
	lsla			; get LED code
        add     #2              ;
        cmp     #8              ;corresponding LED in LEDIMG1?
	bhs	OCA		;yes?
	tax			;no? lookup bit for this code
        lda     LEDMASK,X       ;
        add     LEDIMG0         ;set this bit
        sta     LEDIMG0         ;
        jmp     UPLD            ;
OCA:	sub	#8		;offset for high byte of image
        tax                     ;lookup bit mask for this code
        lda     LEDMASK,X       ;
        add     LEDIMG1         ;set this bit
        sta     LEDIMG1         ;

UPLD:	lda	OUTD		;fetch Output D
        lsla                    ;multiply by 4 and add 3 to
	lsla			; get LED code
        add     #3              ;
        cmp     #8              ;corresponding LED in LEDIMG1?
	bhs	ODA		;yes?
	tax			;no? lookup bit for this code
        lda     LEDMASK,X       ;
        add     LEDIMG0         ;set this bit
        sta     LEDIMG0         ;
	jmp	LRFSH		;
ODA:	sub	#8		;offset for high byte of image
        tax                     ;lookup bit mask for this code
        lda     LEDMASK,X       ;
        add     LEDIMG1         ;set this bit
        sta     LEDIMG1         ;

LRFSH:	jsr	LED_REFRESH	;refresh all the LEDs
        rts

LEDMASK:
	.DB 1,2,4,8,16,32,64,128

;--- Place LCD cursor arrow

ARWDSP: jsr	ARWCLR		;clear arrow

	lda	OUTPUT		;branch off current output
        cmp     #'A'            ;
	beq	DAA		;...if A
        cmp     #'B'            ;
	beq	DAB		;...if B
        cmp     #'C'            ;
	beq	DAC		;...if C
        cmp     #'D'            ;
	beq	DAD		;...if D

	lda	#'A'            ;should never get here
	sta	OUTPUT		; (just in case)

DAA:	lda	#8		;place A arrow
	ldx	#1		;
        jsr     LCD_PUT_ARROW   ;
        rts

DAB:	lda	#10		;place B arrow
        ldx     #1              ;
        jsr     LCD_PUT_ARROW   ;
        rts

DAC:	lda	#12		;place C arrow
	ldx	#1		;
        jsr     LCD_PUT_ARROW   ;
        rts

DAD:	lda	#14		;place D arrow
        ldx     #1              ;
        jsr     LCD_PUT_ARROW   ;
        rts

;--- Clear LCD cursor arrow

ARWCLR: lda	#8		;clear Output A arrow
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
        lda     #' '            ;
        jsr     LCD_PUT_C       ;

	lda	#10		;clear Output B arrow
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
        lda     #' '            ;
        jsr     LCD_PUT_C       ;

	lda	#12		;clear Output C arrow
	ldx	#1		;
        jsr     LCD_GOTOXY      ;
        lda     #' '            ;
        jsr     LCD_PUT_C       ;

	lda	#14		;clear Output D arrow
        ldx     #1              ;
        jsr     LCD_GOTOXY      ;
        lda     #' '            ;
        jsr     LCD_PUT_C       ;
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

