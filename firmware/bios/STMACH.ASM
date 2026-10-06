;----------------------------------------------------------------;
; STMACH.INC - State Machine Routines                            ;
;								 ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;								 ;
; These routines provide basic state machine services.           ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    STM_GO_NEXT   - transitions to next state in State Matrix   ;
;    STM_DO_ACTION - calls action in State Matrix                ;
;    STM_GET_EVENT - gets latest event                           ;
;    STM_INIT      - initializes state machine                   ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    STM_BEGIN - begin definition of State Matrix                ;
;    STM_END   - end definition of State Matrix                  ;
;    STM_ROW   - writes a row to the State Machine Matrix        ;
;    STM_RUN   - main state machine loop                         ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    STATE   - current state                                     ;
;    EVENT   - latest event                                      ;
;    F1      - fader 1 history                                   ;
;    F2      - fader 2 history                                   ;
;    F3      - fader 3 history                                   ;
;    F4      - fader 4 history                                   ;
;    PREVSW  - switch history                                    ;
;    FDR     - application reads fader position from FDR         ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;	State Machine Macros
;----------------------------------------------------------------

;STM_BEGIN is the assembler overhead necessary to initiate
; definition of the State Matrix.

STM_BEGIN: .MACRO

	.CODE
	.RELATIVE
APP_CODE_MARKER:
        .ENDM

;STM_END is the assembler overhead necessary to terminate
; definition of the State Matrix.

STM_END: .MACRO

	 ORG APP_CODE_MARKER

        .ENDM

;STM_ROW writes a row to the State Matchine Matrix

;ARG1 = EVENT code,
;ARG2/3,ARG4/5,ARG6/7,ARG8/9 = State transition/action pairs

	 .ARGCHK OFF
STM_ROW: .MACRO	ARG1,ARG2,ARG3,ARG4,ARG5,ARG6,ARG7,ARG8,ARG9
         .ORG (STM+ARG1*NUMSTATES*3)
         .DB ARG2,ARG4,ARG6,ARG8
         .DW ARG3,ARG5,ARG7,ARG9
	 .ENDM


;----------------------------------------------------------------
;       State Machine Equates & Declarations
;----------------------------------------------------------------

;NUMEVENTS & NUMSTATES define dimensions of State Matrix
;--------------------------------------------------------

NUMEVENTS       EQU     16      ;defines number of events
NUMSTATES       EQU     4       ;defines number of states

;Enumerate Events
;----------------------------------------------------------------

EV_IDLE		EQU	0
EV_SW1_ON       EQU     1
EV_SW2_ON       EQU     2
EV_SW3_ON       EQU     3
EV_SW4_ON       EQU     4
EV_SW5_ON       EQU     5
EV_SW6_ON       EQU     6
EV_SW7_ON       EQU     7
EV_SW8_ON       EQU     8
EV_F1_MOVE      EQU     9
EV_F2_MOVE      EQU     10
EV_F3_MOVE      EQU     11
EV_F4_MOVE      EQU     12
EV_MIDI_IN      EQU     14
EV_FDR_MOVE     EQU     EV_F1_MOVE

;Allocate ROM for State Matrix
;----------------------------------------------------------------

STM:            BLKB    NUMEVENTS*NUMSTATES*3

;Default State Matrix
;----------------------------------------------------------------

        .ORG STM
	.ABSOLUTE

   STM_ROW  0, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  1, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  2, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  3, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  4, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  5, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  6, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  7, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  8, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW  9, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 10, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 11, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 12, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 13, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 14, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE
   STM_ROW 15, 0,IDLE, 1,IDLE,  2,IDLE, 3,IDLE

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

STATE		.DS	1	;current state
EVENT		.DS	1	;latest event
F1              .DS     1       ;fader 1 history
F2              .DS     1       ;fader 2 history
F3              .DS     1       ;fader 3 history
F4              .DS     1       ;fader 4 history
PREVSW          .DS     1       ;switch history

FDR             EQU     F1      ;application reads FDR


	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	STM_GO_NEXT             ;
;                               ;
;-------------------------------;
;                               ;
;Transitions to next state in   ;
;State Matrix.                  ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: STATE refreshed    ;
; Registers: A,X                ;
; Variables: EVENT              ;
;            STATE              ;
;            STM                ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

STM_GO_NEXT:

;--- set pointer to next state in State Matrix

        lda     EVENT           ;next=STM+EVENT*12+curstate
        ldx     #12             ;
        mul                     ;
	add	STATE		;
	tax			;

;--- lookup and save next state

        lda     STM,X           ;lookup next state
        sta     STATE           ;save next state

        rts

;-------------------------------;
;                               ;
;	STM_DO_ACTION           ;
;                               ;
;-------------------------------;
;                               ;
; Calls action in State Matrix. ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: EVENT              ;
;            STATE              ;
;            STM                ;
;            SMOD               ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

STM_DO_ACTION:

;--- set pointer to action in State Matrix

        lda     EVENT           ;;action=STM+EVENT*12+4+curstate*2
        ldx     #12             ;
        mul                     ;
	add	STATE		;
	add	STATE		;
        add     #4              ;
	tax			;

;--- create opcode/operand for extended jump

        lda     #$CC            ;create opcode for extended jmp
        sta     SMC_IMG         ;
        lda     STM,X           ;fetch high byte of address
        sta     SMC_IMG+1       ;
        lda     STM+1,X         ;fetch low byte of address
        sta     SMC_IMG+2       ;

;--- call action

        jmp     SMC_IMG         ;jmp to action routine

;-------------------------------;
;                               ;
;	STM_GET_EVENT           ;
;                               ;
;-------------------------------;
;                               ;
; Gets latest event.            ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: EVENT refreshed    ;
; Registers: A,X                ;
; Variables: PREVSW             ;
;            EVENT              ;
;	     MP_FLAGS		;
;            F1                 ;
;            F2                 ;
;            F3                 ;
;            F4                 ;
;            ADC0               ;
;            ADC1               ;
;            ADC2               ;
;            ADC3               ;
;     Calls: SW_READ            ;
;            MIDI_PARSE         ;
;            ADC_READ           ;
;    Macros: FAR_BEQ            ;
;                               ;
;-------------------------------;

STM_GET_EVENT:

        lda     #EV_IDLE        ;default = no event
        sta     EVENT           ;

;--- see if any MIDI wandered in

        jsr     MIDI_PARSE      ;parse incoming MIDI

	lda	MP_FLAGS	;see if a new message is ready
        and     #$0F            ;look at message type flags
	beq	SGE1		;no new message

	lda	#EV_MIDI_IN	;register event
	sta	EVENT		;
	rts

;--- see if switch status has changed

SGE1:	jsr	SW_READ 	;read switches
	cmp	PREVSW		;has switch status changed?
	FAR_BEQ	CIFF		;nope, go check faders

	tax			;buffer new status in index reg
	eor	PREVSW		;bit set for each changed switch

        ;release all switches in PREVSW that just got released

	txa			;A = new switch status
	eor	PREVSW		;A = what changed
	and	PREVSW		;A = what released
	eor	PREVSW		;A = old switch status - releases
	sta	PREVSW		;update switch history

	;process one newly pushed switch

	comx			;X still = new switch status
	txa			;A = complemented switch status
	ora	PREVSW		;A = switches that didn't change
	coma			;A = switches that did change

	cmp	#$08		;check for single key entries
	beq	GE3		;
        cmp     #$80            ;
        beq     GE1             ;
        cmp     #$20            ;
	beq	GE4		;
        cmp     #$02            ;
	beq	GE5		;
	cmp	#$40		;
	beq	GE6		;
	cmp	#$04		;
	beq	GE7		;
	cmp	#$10		;
	beq	GE8		;
	cmp	#$01		;
	beq	GE9		;
	jmp	CIFF		;no switch events, see if faders

GE1:    lda     PREVSW          ;update switch 5 history
        ora     #$80            ;
	sta	PREVSW		;
        lda     #EV_SW5_ON      ;register event
	sta	EVENT		;
	rts

GE3:    lda     PREVSW          ;update switch 1 history
	ora	#$08		;
	sta	PREVSW		;
        lda     #EV_SW1_ON      ;register event
	sta	EVENT		;
	rts

GE4:    lda     PREVSW          ;update switch 8 history
	ora	#$20		;
	sta	PREVSW		;
        lda     #EV_SW8_ON      ;register event
	sta	EVENT		;
	rts

GE5:    lda     PREVSW          ;update switch 4 history
	ora	#$02		;
	sta	PREVSW		;
        lda     #EV_SW4_ON      ;register event
	sta	EVENT		;
	rts

GE6:    lda     PREVSW          ;update switch 6 history
	ora	#$40		;
	sta	PREVSW		;
        lda     #EV_SW6_ON      ;register event
	sta	EVENT		;
	rts

GE7:    lda     PREVSW          ;update switch 2 history
	ora	#$04		;
	sta	PREVSW		;
        lda     #EV_SW2_ON      ;register event
	sta	EVENT		;
	rts

GE8:    lda     PREVSW          ;update switch 7 history
	ora	#$10		;
	sta	PREVSW		;
        lda     #EV_SW7_ON      ;register event
	sta	EVENT		;
	rts

GE9:    lda     PREVSW          ;update switch 3 history
	ora	#$01		;
	sta	PREVSW		;
        lda     #EV_SW3_ON      ;register event
	sta	EVENT		;
	rts

;--- see if any faders moved

CIFF:	jsr	ADC_READ	;get current ADC values

        ;see if Fader 4 moved

	lda	ADC3		;fetch F4

	cmp	F4		;F4 moved?
	beq	CIFF3		;nope

	sta	F4		;save new F4 position
	lda	#EV_F4_MOVE	;register F4 movement event
	sta	EVENT		;
	rts

        ;see if Fader 3 moved

CIFF3:	lda	ADC2		;F3 read from ADC chan 2

	cmp	F3		;F3 moved?
	beq	CIFF2		;nope

	sta	F3		;save new F3 position
	lda	#EV_F3_MOVE	;register F3 movement event
	sta	EVENT		;
	rts

        ;see if Fader 2 moved

CIFF2:	lda	ADC1		;F2 read from ADC chan 1

	cmp	F2		;F2 moved?
	beq	CIFF1		;nope

	sta	F2		;save new F2 position
	lda	#EV_F2_MOVE	;register F2 movement event
	sta	EVENT		;
	rts

        ;see if Fader 1 moved

CIFF1:	lda	ADC0		;F1 read from ADC chan 0

	cmp	F1		;F1 moved?
	beq	GE10		;nope

	sta	F1		;save new F1 position
	lda	#EV_F1_MOVE	;register F1 movement event
	sta	EVENT		;
GE10:
        rts

;-------------------------------;
;                               ;
;	STM_INIT                ;
;                               ;
;-------------------------------;
;                               ;
; Initializes State Machine     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: EVENT              ;
;            STATE              ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

STM_INIT:
        lda     #EV_IDLE        ;default to Idle event
	sta	EVENT		;

        lda     #0              ;default to state 0
        sta     STATE           ;

        jsr     ADC_READ        ;initialize ADC history
        lda     ADC0            ;
        sta     F1              ;
        lda     ADC1            ;
        sta     F2              ;
        lda     ADC2            ;
        sta     F3              ;
        lda     ADC3            ;
        sta     F4              ;

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	STM_RUN                 ;
;                               ;
;-------------------------------;
;                               ;
; Main State Machine loop.      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls: STM_INIT           ;
;            STM_GET_EVENT      ;
;            STM_DO_ACTION      ;
;            STM_GO_NEXT        ;
;    Macros:                    ;
;                               ;
;-------------------------------;

STM_RUN:
        jsr     STM_INIT        ;initialize state machine

STM_LOOP:
        jsr     STM_GET_EVENT   ;get latest event
        jsr     STM_DO_ACTION   ;perform action
        jsr     STM_GO_NEXT     ;transition to next state
        jmp     STM_LOOP        ;complete the loop

