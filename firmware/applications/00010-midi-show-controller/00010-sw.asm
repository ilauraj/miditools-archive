;===============================================================;
;								                ;
;       MIDI Show Controller  Rev 2.0  15-Feb-99                ;
;								                ;
;       Maps MIDI Program change commands to MIDI Show          ;
;       Control GO commands.                                    ;
;							                	    ;
;===============================================================;
;								                ;
; The unit has two modes:  Edit mode, and Run mode              ;
;                                                               ;
; Edit Mode:  User can select MSC Device ID, and map            ;
;             program change commands to MSC cue ranges.        ;
;                                                               ;
; Run Mode:   LCD shows recieved Program Change commands,       ;
;             and transmitted MSC commands.                     ;
;                                                               ;
;                                                               ;
;---------------------------------------------------------------;
;								                ;
;	LCD Screen:						                ;
;								                ;
; Edit Mode:                                                    ;
;                                                               ;
;       | DEV CH --CUES--|      where nn=1-16                   ;
;       | ddd nn ccc-cccc|            ddd=0-127                 ;
;								                ;
; Run Mode:                                                     ;
;                                                               ;
;       | CH  PRG   CUE  |      where nn=1-16                   ;
;       | nn  ppp   cccc |            ppp=0-127                 ;
;                                     cccc=0-1023               ;
;                                                               ;
;---------------------------------------------------------------;
;								                ;
;	Hardware:						                ;
;								                ;
;	This MIDItool uses the CPU board and one HUMAN		    ;
;	INTERFACE board.  MIDI ports used: IN,OUT,THRU. 	    ;
;								                ;
;---------------------------------------------------------------;
;								                ;
;	States: 						                ;
;								                ;
;       StDev           Select Device ID                        ;
;       StCh            Select MIDI Channel                     ;
;       StCues          Select MSC Cue range                    ;
;       StRun           Watch MIDI activity                     ;
;                                                               ;
;	Actions:						                ;
;								                ;
;	IDLE		No action				                ;
;							 	                ;
;===============================================================;

;----------------------------------------------------------------
;       Constants
;----------------------------------------------------------------


;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

DEV             .DS     1
CHAN            .DS     1
CUERANGE        .DS     1
SENDMSC         .DS     1
CUE             .DS     1
BANK            .DS     1
AREG		    .DS	1
BREG		    .DS	1
DISP1		    .DS	1
DISP2		    .DS	1
DISP3		    .DS	1
DISP4		    .DS	1
AX		    .DS	1
BX		    .DS	1
CX		    .DS	1


;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

StDev           EQU     0
StCh            EQU     1
StCue           EQU     2
StRun           EQU     3

;--- Map application events to BIOS events

EvIdle	    EQU	EV_IDLE
EvDev           EQU     EV_SW1_ON
EvCh            EQU     EV_SW2_ON
EvCue           EQU     EV_SW3_ON
EvInc           EQU     EV_SW4_ON
EvEdit          EQU     EV_SW5_ON
EvRun           EQU     EV_SW6_ON
EvNA            EQU     EV_SW7_ON
EvDec           EQU     EV_SW8_ON
EvValue         EQU     EV_FDR_MOVE

;--- Build State Matrix

        STM_BEGIN

;                 State 0:StDev State 1:StCh  State 2: StCue   State 3: StRun
;        Event    NextSt,Act    NextSt,Act    NextSt,Act       NextSt, Act
;        --------------------------------------------------------------------
 STM_ROW EvIdle,  StDev,IDLE,  StCh, IDLE,   StCue,IDLE,   StRun,RIDLE
 STM_ROW EvEdit,  StDev,IDLE,  StCh, IDLE,   StCue,IDLE,   StDev,GOEDIT
 STM_ROW EvRun,   StRun,GORUN, StRun,GORUN,  StRun,GORUN,  StRun,RIDLE
 STM_ROW EvInc,   StDev,IDLE,  StCh, IDLE,   StCue,IDLE,   StRun,RIDLE
 STM_ROW EvDec,   StDev,IDLE,  StCh, IDLE,   StCue,IDLE,   StRun,RIDLE
 STM_ROW EvValue, StDev,DEVFDR,StCh, CHFDR,  StCue,CUEFDR, StRun,RIDLE
 STM_ROW EvDev,   StDev,GODEV, StDev,GODEV,  StDev,GODEV,  StRun,RIDLE
 STM_ROW EvCh,    StCh, GOCH,  StCh, GOCH,   StCh, GOCH,   StRun,RIDLE
 STM_ROW EvCue,   StCue,GOCUE, StCue,GOCUE,  StCue,GOCUE,  StRun,RIDLE

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

        lda     #0              ;default values
        sta     CHAN            ;
        sta     CUERANGE        ;
        sta     CUE             ;
        sta     SENDMSC         ;
        sta     BANK            ;
	  sta	    AREG		  ;
	  sta	    BREG		  ;
	  lda     #$7F            ;
        sta     DEV             ;

;--- Initialize display

      jsr     LCD_CLEAR
      LCD_PUT_S "MIDI SHOW CONTR"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY
      LCD_PUT_S "  v.2 2/15/99  "

	jsr	DELAY_1SEC
      jsr   DELAY_1SEC
	jsr	LCD_CLEAR

      jsr   GOEDIT          ;initialize display

;--- Execute state machine

	jmp	STM_RUN

;----------------------------------------------------------------
;	Actions
;----------------------------------------------------------------

;--- EDT mode IDLE

IDLE:
        rts

;--- Run mode IDLE -- watch for MIDI and display it

RIDLE:
	  lda     SENDMSC
        beq     NOMSC

        lda     #2
        ldx     #1
        jsr     LCD_GOTOXY
        lda     BANK
	  inca
        jsr     LCD_PUT_RJ2_I

        lda     #7
        ldx     #1
        jsr     LCD_GOTOXY
        lda     CUE
        jsr     LCD_PUT_RJ3_I

	  ;--- send MSC GO command

        lda     #$F0                    ;send MSC Go header
        jsr     MIDI_PUT                ;
        lda     #$7F                    ;more header
        jsr     MIDI_PUT                ;
        lda     DEV                     ;device ID
        jsr     MIDI_PUT                ;
        lda     #$02                    ;MSC
        jsr     MIDI_PUT                ;
        lda     #$7F                    ;command: all call
        jsr     MIDI_PUT                ;
        lda     #$01                    ;GO command
        jsr     MIDI_PUT                ;

        jsr     MIDI_PI		    	    ;

FINISH: lda     #$F7                    ;send EOX
        jsr     MIDI_PUT                ;

;--- all done, exit

        lda     #0
        sta     SENDMSC

NOMSC:
        rts

;--- convert int (0-1024) to ASCII, send via MIDI,and display

;my version

MIDI_PI:		lda	#0
			sta	DISP1
			sta	DISP2
			sta	DISP3
			sta	DISP4

		ldx	#0
		lda	AREG
		cmp	#3
		FAR_BHI	ONET		;if > write "ERROR"

TWOT:		cmp 	#0			;16-bit compare
		beq	THREET		;continue count
		lda	BREG
		clc
		sub	#100			;16 - bit subtract
		sta 	BREG
		lda	AREG
		sbc	#0
		sta	AREG
		incx
		lda	AREG
 	  	jmp	TWOT			;subtract 100 until AREG = 0

THREET:  	lda	BREG			;continue to subract until entire count is in the x register
		cmp	#100
		blo	FOURT
		clc
		sub	#100
		sta 	BREG
		lda	AREG
		sbc	#0
		sta	AREG
		incx
		lda	BREG
		jmp	THREET

FOURT:	sta	BREG			;100's are in x, remainder is in BREG
		txa
		sta	AX
		cmp 	#10			
		beq	WRTEN			;write ascii "1 & 0" if 10 is in the x register
		cmp	#0			;if no 100's, jump to test 10's without 100's
		beq	SIXT			;
	  	add	#'0'
		jsr	MIDI_PUT		;write the 100's digit

			lda 	AX
			sta	DISP2

		ldx	#0			;reinitialize the count
	  	jmp	SIXT			;go test 10's with 100's			

WRTEN:	lda	#1
		sta	BX
		lda	#'1'			;write the 1000's digit
		jsr	MIDI_PUT

			lda 	#10
			sta	DISP1
  			  
NINET:  	lda	#'0'			;put a 0 if 100's exist
		jsr	MIDI_PUT
		ldx 	#0

SIXT:		lda	BREG			;test 10's 
		cmp	#10
		blo	EIGHT			;go write 1's digit
SEVENT:	lda	BREG
		cmp	#10
		blo	FIVET
		sub	#10
		incx
		sta	BREG
		jmp	SEVENT		

FIVET:	txa				;display 10's digit
		sta	CX
	  	add	#'0'
		jsr	MIDI_PUT

			lda 	CX
			sta	DISP3

  		jmp	TENT
		
EIGHT:	lda	BX
		cmp	#0
		beq	ELET
		lda	#0
		sta	BX
		jmp	TENT

ELET:		lda	AX			;10's with 100's?
		cmp 	#0
		beq	TENT
		lda	#'0'
		jsr	MIDI_PUT

			lda 	#0
			sta	DISP3
	  
TENT:		lda	BREG			;display 1's digit
		add	#'0'
		jsr	MIDI_PUT

			lda 	BREG
			sta	DISP4

			lda     #11
        		ldx     #1
        		jsr     LCD_GOTOXY
        		lda     DISP1
        		jsr     LCD_PUT_I

			lda     #12
        		ldx     #1
        		jsr     LCD_GOTOXY
        		lda     DISP2
        		jsr     LCD_PUT_I

			lda     #13
        		ldx     #1
        		jsr     LCD_GOTOXY
        		lda     DISP3
        		jsr     LCD_PUT_I

			lda     #14
        		ldx     #1
        		jsr     LCD_GOTOXY
        		lda     DISP4
        		jsr     LCD_PUT_I

		rts

ONET:	  	lda	#0
		ldx	#1
		jsr	LCD_GOTOXY
      	LCD_PUT_S "    ERROR!     "

		rts

;--- enter edit mode (Device ID state)

GOEDIT:
        jsr     LCD_CLEAR

        LCD_PUT_S " DEV CH --CUES--"

        jsr     GOCUE
        jsr     GOCH
        jsr     GODEV

        rts

;--- enter run mode

GORUN:
        jsr     LCD_CLEAR

        LCD_PUT_S " CH  PRG   CUE  "

        lda     #0
        ldx     #1
        jsr     LCD_GOTOXY
        LCD_PUT_S " --  ---   ---- "

        rts


;--- Set Device ID with fader

DEVFDR: lda     FDR             ;fetch fader value
        lsra                    ;valid range: 0-127
        sta     DEV             ;store new value
        jsr     DEVDSP          ;update display

	  rts

;--- Set Channel with fader

CHFDR:  lda     FDR             ;fetch fader value
        lsra                    ;valid range: 0-15
        lsra                    ;
        lsra                    ;
        lsra                    ;
        sta     CHAN            ;store new value
        jsr     CHDSP           ;update display

	  rts

;--- Set Cue Range with fader

CUEFDR: lda     FDR             ;fetch fader value
        lsra                    ;valid range: 0-7
        lsra                    ;
        lsra                    ;
        lsra                    ;
        lsra                    ;
        sta     CUERANGE        ;store new value
        jsr     CUEDSP          ;update display

	  rts

;--- Point to and display Device ID

GODEV:
        lda     #4
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #7
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #0
        ldx     #1
        jsr     LCD_PUT_ARROW

;--- Update Device ID value

DEVDSP: lda     #3              ;Update Device ID
        ldx     #1              ;
	  jsr	    LCD_GOTOXY	  ;
        lda     DEV             ;
        jsr     LCD_PUT_RJ3_I   ;display it

	  rts

;--- Point to and display MIDI CH

GOCH:
        lda     #0
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #7
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #4
        ldx     #1
        jsr     LCD_PUT_ARROW

;--- Update MIDI CH value

CHDSP:  lda     #6              ;Update MIDI CH
        ldx     #1              ;
	  jsr	    LCD_GOTOXY	  ;
        lda     CHAN            ;
        inca
	  jsr	    LCD_PUT_RJ2_I	  ;display it

	  rts

;--- Point to and display CUE RANGE

GOCUE:
        lda     #0
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #4
        ldx     #1
        jsr     LCD_GOTOXY
        lda     #' '
        jsr     LCD_PUT_C

        lda     #7
        ldx     #1
        jsr     LCD_PUT_ARROW

;--- Update CUE RANGE value

CUEDSP:
        lda     #8              ;Update CUE RANGE
        ldx     #1              ;
	  jsr	    LCD_GOTOXY   	  ;

        lda     CUERANGE        ;
        cmp     #0

        FAR_BEQ     CUE0
        cmp     #1
        FAR_BEQ     CUE1
        cmp     #2
        FAR_BEQ     CUE2
        cmp     #3
        FAR_BEQ     CUE3
        cmp     #4
        FAR_BEQ     CUE4
        cmp     #5
        FAR_BEQ     CUE5
        cmp     #6
        FAR_BEQ     CUE6
        cmp     #7
        FAR_BEQ     CUE7

        lda     #0
        sta     CUERANGE

CUE0:   LCD_PUT_S "  0-127 "
        rts
CUE1:   LCD_PUT_S "128-255 "
        rts
CUE2:   LCD_PUT_S "256-383 "
        rts
CUE3:   LCD_PUT_S "384-511 "
        rts
CUE4:   LCD_PUT_S "512-639 "
        rts
CUE5:   LCD_PUT_S "640-767 "
        rts
CUE6:   LCD_PUT_S "768-895 "
        rts
CUE7:   LCD_PUT_S "896-1023"
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

;--- Service Status Bytes (class in acca, value in x)

SCI_RX_CBCK_S:

        lda     M_RSTAT         ;see if it's a Prog Change
        tax                     ;
        and     #$F0            ;
        cmp     #$C0            ;
        bne     NOTPC           ;nope, ignore

        txa                     ;BANK = MIDI Chan
        and     #$0F            ;
	  sta     BANK            ;

NOTPC:
        rti

;--- Service 1st Data Bytes (class in acca, value in x)

SCI_RX_CBCK_D1:

        lda     M_RSTAT         ;see we're gettin' a Prog change
        and     #$F0            ;
        cmp     #$C0            ;
        bne     IGNRD1          ;nope, ignore

	  lda	    BANK
	  cmp	    CHAN
	  bne	    IGNRD1

	  lda     M_DATA1         ;cue = program number
	  sta     CUE             ;

	  lda	    CUERANGE
	  ldx	    #128
	  mul
	  sta	    BREG
	  stx	    AREG
	  add     CUE
	  sta	    BREG
	  txa
	  adc	    #$00
	  sta     AREG

	  lda     #1              ;flag that we need to send MSC
        sta     SENDMSC         ;

IGNRD1:
        rti

;--- Service 2nd Data Bytes - retransmit if echo is on

SCI_RX_CBCK_D2:

        rti

			
	




        
