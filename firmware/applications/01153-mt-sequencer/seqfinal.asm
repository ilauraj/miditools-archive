;===============================================================;
;								;
;       SEQTEST.ASM    Rev 1.0                                  ;
;	Test program for sequencer memory board             	;
;								;
;===============================================================;
;								;
; This application uses the memory expansion board, no LCD,     ;
; and no human interface board.                                 ;
;								;
; RAM and ROM in the memory board are formatted as follows:     ;
;								;
;     ADDR    CONTENTS                                          ;
;     ----    -------------------------------                   ;
;     0000  0 Delta Time Stamp MSB (CNT480+1)                   ;
;     0001    Delta Time Stamp LSB (CNT480)                     ;
;     0002    Status Byte                                       ;
;     0003    Data1                                             ;
;     0004    Data2                                             ;
;     0005  1 Delta Time Stamp MSB (CNT480+1)                   ;
;     0006    Delta Time Stamp LSB (CNT480)                     ;
;     0007    Status Byte                                       ;
;     0008    Data1                                             ;
;     0009    Data2                                             ;
;     000A  2 Delta Time Stamp MSB (CNT480+1)                   ;
;     000B    Delta Time Stamp LSB (CNT480)                     ;
;     000D    Status Byte                                       ;
;     000E    Data1                                             ;
;     000F    Data2                                             ;
;           .                                                   ;
;           .                                                   ;
;           .                                                   ;
;      ?      Delta Time Stamp MSB (CNT480+1)                   ;
;      ?+1    Delta Time Stamp LSB (CNT480)                     ;
;      ?+2    Status Byte                                       ;
;      ?+3    Data1                                             ;
;      ?+4    Data2                                             ;
;      ?+5    $FF -- end of sequence marker                     ;
;								;
; Timing analysis reveals the following:                        ;
;								;
;   Time to read RAM/ROM = 34us                                 ;
;   Time to write RAM    = 36us                                 ;
;   Time to write a record = 315us                              ;
;								;
;----------------------------------------------------------------
;	State Machine Macros
;----------------------------------------------------------------

;STM_BEGIN is the assembler overhead necessary to initiate
; definition of the State Matrix.

STM8_BEGIN: .MACRO

	.CODE
	.RELATIVE
APP_CODE_MARKER8:
        .ENDM

;STM_END is the assembler overhead necessary to terminate
; definition of the State Matrix.

STM8_END: .MACRO

         ORG APP_CODE_MARKER8

        .ENDM

;STM8_ROW writes a row to the State Matchine Matrix

;ARG1 = EVENT code,
;ARG2/3,ARG4/5,ARG6/7,ARG8/9,... ARG16/17 = State transition/action pairs

          .ARGCHK OFF
STM_ROW8: .MACRO ARG1,ARG2,ARG3,ARG4,ARG5,ARG6,ARG7,ARG8,ARG9,ARG10,ARG11,ARG12,ARG13,ARG14,ARG15,ARG16,ARG17
          .ORG (STM8+(ARG1*24))
          .DB ARG2,ARG4,ARG6,ARG8,ARG10,ARG12,ARG14,ARG16
          .DW ARG3,ARG5,ARG7,ARG9,ARG11,ARG13,ARG15,ARG17
          .ENDM

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

TEMP 		.DS	1	;temp variable
ADDRHI          .DS     1       ;memory IC address high byte
ADDRLO          .DS     1       ;memory IC address low byte
DOUT            .DS     1       ;data value written to RAM
APPST           .DS     1       ;state machine current state
APPEV           .DS     1       ;state machine event
MSGPTR          .DS     1       ;indexes bytes in a MIDI message
ICTR            .DS     1       ;timer interrupt counter
CNT480          .DS     2       ;counts at 480Hz
TEMPOCRLSB      .DS     1       ;temp variable for timer ISR
TEMPOCRMSB      .DS     1       ;temp variable for timer ISR

SEQ0            .DS     1       ;preloaded output value (STATUS)
SEQ1            .DS     1       ;preloaded output value (DATA1)
SEQ2            .DS     1       ;preloaded output value (DATA2)

SEQMODE         .DS     1       ;sequencer mode (has below values)
SEQIDLE         EQU     0       ;sequencer is idle
RAMPLAY         EQU     1       ;Ram playback
ROMPLAY         EQU     2       ;Rom playback
RAMREC          EQU     3       ;Ram recording

CCFLAG          .DS     1       ;flags a CC is ready for recording
MSGNUM          .DS     1       ;(internal parser) message number
SEX_Q_ENABLE	.DS	1	;flag for sysex msg
SEX_Q_COUNT	.DS	1	;counter for sysex msgs
TEMPCLASS	.DS	1	;temporary variable
TEMPVAL		.DS	1	;temporary variable
MIDIEV          .DS     1       ;flags a new event for state machine

THEEV           .DS     1

;---------------------------------
; 16-bit address increment

INCADDR: .MACRO

        lda     ADDRLO
        add     #1
        sta     ADDRLO
        lda     ADDRHI
        adc     #0
        sta     ADDRHI

        .ENDM
;---------------------------------

;----------------------------------------------------------------
;	State Matrix
;----------------------------------------------------------------

;--- Enumerate states

STPD            EQU     0
ROMPL           EQU     1
RAMPL           EQU     2
RAMRC           EQU     3
ROMW8           EQU     4
RAMPLW8         EQU     5
RAMRCW8         EQU     6
StIDLE          EQU     7

;--- State Machine events

EvIDLE          EQU     0
EvPLROM         EQU     1
EvPLRAM         EQU     2
EvRCRAM         EQU     3
EvMSTPL         EQU     4
EvMSTSTOP       EQU     5
EvRTSTART       EQU     6
EvRTCONT        EQU     7
EvRTSTOP        EQU     8

;--- Build State Matrix

;Allocate ROM for State Matrix
;----------------------------------------------------------------

        .CODE
        .RELATIVE

STM8:   BLKB    9*24  ;NUMEVENTS * NUMSTATES * 3 bytes per state

        STM8_BEGIN
;                   STPD=0       ROMPL=1        RAMPL=2        RAMRC=3         ROMW8=4        RAMPLW8=5      RAMRCW8=6     StIDLE=7
;         Event     Stopped      ROMplay        RAMplay        RAMrec          ROMwait        RAMplay wait   RAMrec wait   IDLE
;         -----------------------------------------------------------------------------------------------------------------------

 STM_ROW8 EvPLROM,  ROMW8,MsgA,  ROMW8,PLSTPA,  ROMW8,PLSTPA,  ROMW8,RCSTPA,   ROMW8,MsgAA,   ROMW8,MsgA,    ROMW8,MsgA,    StIDLE,IDLE
 STM_ROW8 EvPLRAM,  RAMPLW8,MsgB,RAMPLW8,PLSTPB,RAMPLW8,PLSTPB,RAMPLW8,RCSTPB, RAMPLW8,MsgB,  RAMPLW8,MsgBB, RAMPLW8,MsgB,  StIDLE,IDLE
 STM_ROW8 EvRCRAM,  RAMRCW8,MsgC,RAMRCW8,PLSTPC,RAMRCW8,PLSTPC,RAMRCW8,RCSTPC, RAMRCW8,MsgC,  RAMRCW8,MsgC,  RAMRCW8,MsgCC, StIDLE,IDLE
 STM_ROW8 EvMSTPL,  STPD,MsgD,   STPD,PLSTPD,   STPD,PLSTPD,   STPD,RCSTPD,    STPD,MsgD,     STPD,MsgD,     STPD,MsgD,     StIDLE,IDLE
 STM_ROW8 EvMSTSTOP,STPD,MsgE,   STPD,PLSTPE,   STPD,PLSTPE,   STPD,RCSTPE,    STPD,MsgE,     STPD,MsgE,     STPD,MsgE,     StIDLE,IDLE
 STM_ROW8 EvRTSTART,STPD,IDLE,   ROMPL,IDLE,    RAMPL,IDLE,    RAMRC,IDLE,     ROMPL,PLROMSEQ,RAMPL,PLRAMSEQ,RAMRC,RCRAMSEQ,StIDLE,IDLE
 STM_ROW8 EvRTCONT, STPD,IDLE,   ROMPL,IDLE,    RAMPL,IDLE,    RAMRC,IDLE,     ROMPL,PLROMSEQ,RAMPL,PLRAMSEQ,RAMRC,RCRAMSEQ,StIDLE,IDLE
 STM_ROW8 EvRTSTOP, STPD,IDLE,   STPD,PLSTP,    STPD,PLSTP,    STPD,RCSTP,     ROMW8,IDLE,    RAMPLW8,IDLE,  RAMRCW8,IDLE,  StIDLE,IDLE
 STM_ROW8 EvIDLE,   STPD,IDLE,   ROMPL,IDLE,    RAMPL,IDLE,    RAMRC,IDLE,     ROMW8,IDLE,    RAMPLW8,IDLE,  RAMRCW8,IDLE,  StIDLE,IDLE

        STM8_END

;----------------------------------------------------------------
;	Application
;----------------------------------------------------------------

	.CODE
	.RELATIVE

;--------------------------------
STM8_GO_NEXT:

;--- set pointer to next state in State Matrix

        lda     THEEV           ;next=STM8+EVENT*24+curstate
        ldx     #24             ;
        mul                     ;
        add     APPST           ;
	tax			;

;--- lookup and save next state

        lda     STM8,X          ;lookup next state
        sta     APPST           ;save next state

        rts

;--------------------------------
STM8_DO_ACTION:

;--- set pointer to action in State Matrix

        lda     THEEV           ;action=STM8+EVENT*24+8+curstate*2
        ldx     #24             ;
        mul                     ;
        add     APPST           ;
        add     APPST           ;
        add     #8              ;
	tax			;

;--- create opcode/operand for extended jump

        lda     #$CC            ;create opcode for extended jmp
        sta     SMC_IMG         ;
        lda     STM8,X          ;fetch high byte of address
        sta     SMC_IMG+1       ;
        lda     STM8+1,X        ;fetch low byte of address
        sta     SMC_IMG+2       ;

;--- call action

        jmp     SMC_IMG         ;jmp to action routine

;-------------------------------------------------------------------------

APPLICATION:

;--- Initialize variables

	lda	#$00		;default values
        sta     TEMP
	sta	ADDRLO
	sta	ADDRHI
	sta	DOUT
        sta     APPEV
        sta     APPST
        sta     CCFLAG
        sta     MSGNUM
        sta     SEX_Q_ENABLE
        sta     SEX_Q_COUNT
        sta     TEMPCLASS
        sta     TEMPVAL
        sta     MIDIEV
        sta     THEEV
        sta     CNT480
        sta     (CNT480+1)
        sta     ICTR
        sta     MSGPTR

        lda     #SEQIDLE
        sta     SEQMODE

; --- initialize Memory PCB

	jsr	MEMPCB_INIT

        lda     #$FF            ;mark RAM[0] with end of sequence
        jsr     WRRAM           ;

;--- initialize timer

        lda     #$40            ;initialize timer interrupts
        sta     TCR             ;for output compare

;--- Execute state machine

STMLP:
        jsr     STM8_GET_EV
        jsr     STM8_DO_ACTION   ;perform action
        jsr     STM8_GO_NEXT     ;transition to next state
        bra     STMLP

STM8_GET_EV:

        lda     MIDIEV
        beq     NOEVENT

        lda     #0
        sta     MIDIEV

        lda     APPEV
        cmp     #8              ;bounds checking, may not be necessary
        bls     OKAYEV          ;
        lda     #0              ;
OKAYEV: sta     THEEV
        rts

NOEVENT:
        lda     #EvIDLE
        sta     THEEV
        rts

;----------------------------------------------------------------
;       Actions
;----------------------------------------------------------------

;--------------------------------------
;       IDLE
;--------------------------------------

IDLE:
        rts

;--------------------------------------
;       REALTIME PLAY STOP
;--------------------------------------

PLSTP:  lda     #SEQIDLE
        sta     SEQMODE
        rts

;--------------------------------------
;       REALTIME RECORD STOP
;--------------------------------------

RCSTP:  lda     #SEQIDLE
        sta     SEQMODE

        rts

;--------------------------------------
;       OUTPUT MESSAGE A
;--------------------------------------

PLSTPA:
        lda     #SEQIDLE
        sta     SEQMODE
        bra     MsgA

RCSTPA:
        lda     #SEQIDLE
        sta     SEQMODE

       ; bra     MsgA

MsgA:
MsgAA:
        ldx     #0
        stx     MSGPTR
MSGALP:
        lda     MSGASTR,X
        cmp     #$FF
        beq     MSGADUN

        cmp     #$FE
        bne     MSGANODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGANEXT
MSGANODLY:
        jsr     MIDI_PUT
MSGANEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGALP

MSGADUN:
        rts

MSGASTR: .DB $F0,$7F,$7F,$06,$44,$06,$01,$00,$00,$00,$00,$00,$03,$F7,$FE,$CE,$00,$FF

;--------------------------------------
;       OUTPUT MESSAGE B
;--------------------------------------

PLSTPB:
        lda     #SEQIDLE
        sta     SEQMODE
        bra     MsgB

RCSTPB:
        lda     #SEQIDLE
        sta     SEQMODE

       ; bra     MsgB
MsgB:
MsgBB:
        ldx     #0
        stx     MSGPTR
MSGBLP:
        lda     MSGBSTR,X
        cmp     #$FF
        beq     MSGBDUN

        cmp     #$FE
        bne     MSGBNODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGBNEXT
MSGBNODLY:
        jsr     MIDI_PUT
MSGBNEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGBLP

MSGBDUN:
        jsr     MsgCTR
        rts

MSGBSTR: .DB $F0,$7F,$7F,$06,$44,$06,$01,$00,$00,$00,$00,$00,$03,$F7,$FE,$CE,$00,$FF

;--------------------------------------
;       OUTPUT MESSAGE C
;--------------------------------------

PLSTPC:
        lda     #SEQIDLE
        sta     SEQMODE
        bra     MsgC

RCSTPC:
        lda     #SEQIDLE
        sta     SEQMODE

       ; bra     MsgC
MsgC:
MsgCC:
        ldx     #0
        stx     MSGPTR
MSGCLP:
        lda     MSGCSTR,X
        cmp     #$FF
        beq     MSGCDUN

        cmp     #$FE
        bne     MSGCNODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGCNEXT
MSGCNODLY:
        jsr     MIDI_PUT
MSGCNEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGCLP

MSGCDUN:
        jsr     MsgCTR
        rts

MSGCSTR: .DB $F0,$7F,$7F,$06,$44,$06,$01,$00,$00,$00,$00,$00,$03,$F7,$FE,$CE,$00,$FF

;--------------------------------------
;       OUTPUT MESSAGE D
;--------------------------------------

PLSTPD:
        lda     #SEQIDLE
        sta     SEQMODE
        bra     MsgD

RCSTPD:
        lda     #SEQIDLE
        sta     SEQMODE

       ; bra     MsgD
MsgD:
        ldx     #0
        stx     MSGPTR
MSGDLP:
        lda     MSGDSTR,X
        cmp     #$FF
        beq     MSGDDUN

        cmp     #$FE
        bne     MSGDNODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGDNEXT
MSGDNODLY:
        jsr     MIDI_PUT
MSGDNEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGDLP

MSGDDUN:
        rts

MSGDSTR: .DB $F0,$7F,$7F,$06,$44,$06,$01,$00,$00,$00,$00,$00,$03,$F7,$FE,$CE,$01,$FF

;--------------------------------------
;       OUTPUT MESSAGE E
;--------------------------------------

PLSTPE:
        lda     #SEQIDLE
        sta     SEQMODE
        bra     MsgE

RCSTPE:
        lda     #SEQIDLE
        sta     SEQMODE

       ; bra     MsgE
MsgE:
        ldx     #0
        stx     MSGPTR
MSGELP:
        lda     MSGESTR,X
        cmp     #$FF
        beq     MSGEDUN

        cmp     #$FE
        bne     MSGENODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGENEXT
MSGENODLY:
        jsr     MIDI_PUT
MSGENEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGELP

MSGEDUN:
        rts

MSGESTR: .DB $F0,$7F,$7F,$06,$01,$F7,$FE,$FF

;--------------------------------------
;       OUTPUT CONTROLLER MESSAGES
;--------------------------------------

MsgCTR:
        ldx     #0
        stx     MSGPTR
MSGXLP:
        lda     MSGCTRSTR,X
        cmp     #$FF
        beq     MSGXDUN

        cmp     #$FE
        bne     MSGXNODLY
        jsr     DELAY_10MS
        jsr     DELAY_10MS
        bra     MSGXNEXT
MSGXNODLY:
        jsr     MIDI_PUT
MSGXNEXT:
        ldx     MSGPTR
        incx
        stx     MSGPTR
        jmp     MSGXLP

MSGXDUN:
        rts

MSGCTRSTR: .DB $F0,$00,$20,$26,$01,$5E,$00,$F7,$FE
           .DB $B0,$07,$64,$FE
           .DB $B1,$07,$64,$FE
           .DB $B2,$07,$64,$FE
           .DB $B3,$07,$64,$FE
           .DB $B4,$07,$64,$FE
           .DB $B5,$07,$64,$FE
           .DB $B6,$07,$64,$FE
           .DB $B7,$07,$64,$FE

           .DB $B0,$0A,$40,$FE
           .DB $B1,$0A,$40,$FE
           .DB $B2,$0A,$40,$FE
           .DB $B3,$0A,$40,$FE
           .DB $B4,$0A,$40,$FE
           .DB $B5,$0A,$40,$FE
           .DB $B6,$0A,$40,$FE
           .DB $B7,$0A,$40,$FE

           .DB $B0,$19,$00,$FE
           .DB $B1,$19,$00,$FE
           .DB $B2,$19,$00,$FE
           .DB $B3,$19,$00,$FE
           .DB $B4,$19,$00,$FE
           .DB $B5,$19,$00,$FE
           .DB $B6,$19,$00,$FE
           .DB $B7,$19,$00,$FE

           .DB $FF

;--------------------------------------
;       PLAY ROM SEQUENCE
;--------------------------------------

PLROMSEQ:
        lda     #0
        sta     ADDRLO
        sta     ADDRHI

        ; --- CNT480 = next deltaSYT

        jsr     RDROM
        sta     (CNT480+1)
        INCADDR
        jsr     RDROM
        sta     CNT480

        ; --- preload next message

        INCADDR
        jsr     RDROM
        sta     SEQ0

        INCADDR
        jsr     RDROM
        sta     SEQ1

        INCADDR
        jsr     RDROM
        sta     SEQ2

        ;--- flag ROM PLAYBACK

        lda     #ROMPLAY
        sta     SEQMODE

        rts

;--------------------------------------
;       PLAY RAM SEQUENCE
;--------------------------------------

PLRAMSEQ:

        lda     #0
        sta     ADDRLO
        sta     ADDRHI

        ; --- CNT480 = next deltaSYT

        jsr     RDRAM
        sta     (CNT480+1)
        INCADDR
        jsr     RDRAM
        sta     CNT480


        ; --- preload next message

        INCADDR
        jsr     RDRAM
        sta     SEQ0

        INCADDR
        jsr     RDRAM
        sta     SEQ1

        INCADDR
        jsr     RDRAM
        sta     SEQ2

        ;--- flag RAM PLAYBACK

        lda     #RAMPLAY
        sta     SEQMODE

        rts

;--------------------------------------
;       RECORD RAM SEQUENCE
;--------------------------------------

RCRAMSEQ:
        lda     #0
        sta     ADDRLO
        sta     ADDRHI
        sta     CNT480
        sta     (CNT480+1)

        ;--- flag RAM RECORD

        lda     #RAMREC
        sta     SEQMODE

        rts

;-------------------------------------------------------------------------
;       MEMORY PRIMTIIVES
;-------------------------------------------------------------------------

;---------------------------------
;       INITIALIZE MEMORY PCB
;---------------------------------

MEMPCB_INIT:

	X0_LO			;idle address latch clock port
	X1_HI			;disable RAM WE
	bset	6,PORTA		;diasble RAM/ROM OE

	rts

;---------------------------------
;       READ ROM
;---------------------------------

RDROM:
	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and ROM CS
	lda	ADDRHI
	and	#$3F
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute read
	clr	DDRB		;set up port B for all inputs
	bclr	6,PORTA
	lda	PORTB
	bset	6,PORTA

	; -- return with data in ACCU

	rts

;---------------------------------
;       READ RAM
;---------------------------------

RDRAM:
	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and RAM CS
	lda	ADDRHI
	ora	#$C0
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute read
	clr	DDRB		;set up port B for all inputs
	bclr	6,PORTA
	lda	PORTB
	bset	6,PORTA

	; -- return with data in ACCU
	rts

;---------------------------------
;       WRITE RAM
;---------------------------------

WRRAM:
        ; --- enter with data in A

        sta     DOUT

	; -- set up addr

	;write addr low byte
	lda	ADDRLO
	WR_DATA
	X0_HI
	X0_LO

	;write high byte and ROM CS
	lda	ADDRHI
	ora	#$C0
	sta	PORTB
	X0_HI
	X0_LO

	; -- execute write

	lda	DOUT
	sta	PORTB
	X1_LO
	X1_HI

	rts

;----------------------------------------------------------------
;	Interrupt Call Backs
;----------------------------------------------------------------

        IGNORE_IRQ_SWI_SPI

;--- the timer is configured to bump the CNT480 variable at a rate of 480Hz

;TPMSB is always 1024 => gives 1042, 1042, 1041 prescales which
;                        averages to 480 Hz

TPLSB:  .DB 18,18,17

TIMER_CBCK:

        ; --- setup timer registers for next time-out

        ldx     ICTR            ;bump interrupt counter
        incx                    ;
        cpx     #2              ;
        bls     TC0             ;
        ldx     #0              ;
TC0:    stx     ICTR            ;

        lda     TPLSB,X         ;compute and store next output
	add	OCRLSB		; compare register value
        sta     TEMPOCRLSB      ;
        lda     #$04            ;OCR MSB is 1024
	adc	OCRMSB		;
	sta	OCRMSB		;
	lda	TSR		;neccesary to clear OCF flag
        lda     TEMPOCRLSB      ;
	sta	OCRLSB		;

        ;--- dispatch to handle current sequencer mode

        lda     SEQMODE
        cmp     #RAMPLAY
        FAR_BEQ TCRAMPL

        cmp     #ROMPLAY
        beq     TCROMPL

        cmp     #RAMREC
        FAR_BEQ TCRAMREC

      ;  rti

TCDUN3: rti

;--- ROM PLAYBACK -------------------------------

TCROMPL:

        ; --- bug fix: SYT of 00 00 was not working right

        lda     CNT480                  ;check syt delta
        bne     BF0                     ;if nonzero, process as usual
        lda     (CNT480+1)              ;
        bne     BF0                     ; "

        ;if we get here, SYT is 0
        bra     FIREAWAY
BF0:

        ; --- bump CNT480, exit if not 0 yet

        lda     CNT480
        sub     #1
        sta     CNT480
        lda     (CNT480+1)
        sbc     #0
        sta     (CNT480+1)
        bne     TCDUN3
        lda     CNT480
        bne     TCDUN3

FIREAWAY:
        ; --- output message

        lda     SEQ0
        jsr     MIDI_PUT
        lda     SEQ1
        jsr     MIDI_PUT
        lda     SEQ2
        jsr     MIDI_PUT

        ; --- CNT480 = next deltaSYT

        INCADDR
        jsr     RDROM
        cmp     #$FF                    ;trap $FF to indicate end of SEQ
        FAR_BEQ SEQPDUN
        sta     (CNT480+1)
        INCADDR
        jsr     RDROM
        sta     CNT480

        ; --- preload next message

        INCADDR
        jsr     RDROM
        sta     SEQ0

        INCADDR
        jsr     RDROM
        sta     SEQ1

        INCADDR
        jsr     RDROM
        sta     SEQ2

        rti

;--- RAM RECORD   -------------------------------

TCRAMREC:

        ; --- bump CNT480

        lda     CNT480
        add     #1
        sta     CNT480
        lda     (CNT480+1)
        adc     #0
        sta     (CNT480+1)

        ; --- if MIDI event has come in, store it!

        lda     CCFLAG
        beq     TCDUN2

        lda     #0
        sta     CCFLAG


        ;--- store SYT

        lda     (CNT480+1)
        jsr     WRRAM
        INCADDR
        lda     CNT480
        jsr     WRRAM
        INCADDR

        lda     #0              ;reset time stamp
        sta     CNT480          ;
        sta     (CNT480+1)      ;

        ;--- store message

        lda     M_RSTAT
        jsr     WRRAM
        INCADDR

        lda     M_DATA1
        jsr     WRRAM
        INCADDR

        lda     M_DATA2
        jsr     WRRAM
        INCADDR

        lda     #$FF            ;mark new end of sequence
        jsr     WRRAM

        lda     ADDRHI          ;check for end of memory
        cmp     #$1F            ;last address is $1FFF
        blo     TCDUN2          ;
        lda     ADDRLO          ;
        cmp     #$F9            ;make sure at least 5 bytes left
        blo     TCDUN2          ;

        ;if we get here, out of RAM --> stop recording

        lda     #SEQIDLE
        sta     SEQMODE

TCDUN2:
        rti

;--- RAM PLAYBACK -------------------------------

TCRAMPL:

        ; --- bump CNT480, exit if not 0 yet

        lda     CNT480
        sub     #1
        sta     CNT480
        lda     (CNT480+1)
        sbc     #0
        sta     (CNT480+1)
        bne     TCDUN2
        lda     CNT480
        bne     TCDUN2

        ; --- output message

        lda     SEQ0
        jsr     MIDI_PUT
        lda     SEQ1
        jsr     MIDI_PUT
        lda     SEQ2
        jsr     MIDI_PUT

        ; --- CNT480 = next deltaSYT

        INCADDR
        jsr     RDRAM
        cmp     #$FF                    ;trap $FF to indicate end of SEQ
        beq     SEQPDUN
        sta     (CNT480+1)
        INCADDR
        jsr     RDRAM
        sta     CNT480

        ; --- preload next message

        INCADDR
        jsr     RDRAM
        sta     SEQ0

        INCADDR
        jsr     RDRAM
        sta     SEQ1

        INCADDR
        jsr     RDRAM
        sta     SEQ2

	rti

SEQPDUN:
        lda     #SEQIDLE
        sta     SEQMODE
        rti

;-------------------------------------------------------------------------
; MIDI Parser
;-------------------------------------------------------------------------

SCI_TX_CBCK:
        jmp     SCI_TX_CBCK_RET

SCI_RX_CBCK:
        jmp     SCI_RX_CBCK_RET

;--- Service status byte (do not rti; need a proper MR_STAT)

SCI_RX_CBCK_S:
	sta	TEMPCLASS
	stx	TEMPVAL

	cpx	#$F0		;yes? is message a SYSEX?
	beq	RXSEX		;yes? branch...

	cpx	#$F7		;yes? is message a EOX?
	beq	RXEOX		;yes? branch...

	cpx	#$FA		;yes? is message a START?
	beq	RXSTART		;yes? branch...

	cpx	#$FB		;yes? is message a CONT?
	beq	RXCONT		;yes? branch...

	cpx	#$FC		;yes? is message a STOP?
	beq	RXSTOP		;yes? branch...

        cpx     #$F8            ;other RT messages to ignore
        beq     RXXEND
        cpx     #$FE            ;other RT messages to ignore
        beq     RXXEND
        cpx     #$FF            ;other RT messages to ignore
        beq     RXXEND

	;treat any other status byte as EOX, as well

RXEOX:	lda	#0		;reset queue no matter what
	sta	SEX_Q_ENABLE	; (set flag)
	sta	SEX_Q_COUNT	;get ready to start over
        lda     MSGNUM          ;do we have a valid SYSEX message?
	cmp	#0		;
        bne     SETFLG          ;yes, go set flag
        jmp     RXXEND          ;no, leave...

RXSEX:	lda	#1		;enable queue
	sta	SEX_Q_ENABLE	; (set flag)
	lda	#0		;reset count
	sta	SEX_Q_COUNT	;
	jmp	RXXEND		;leave...

RXSTART:
	lda	#6		;
	sta	MSGNUM
	jmp	SETFLG

RXCONT:	lda	#7		;
	sta	MSGNUM
	jmp	SETFLG

RXSTOP:	lda	#8
	sta	MSGNUM

SETFLG:	lda	MSGNUM		;set flag
	sta	APPEV
        lda     #1              ;flags a new event for state machine to act on
        sta     MIDIEV          ;  event code is in APPEV
	lda	#0		;reset match flag and abort any sysex msg
	sta	MSGNUM		;
	sta	SEX_Q_ENABLE	;
	sta	SEX_Q_COUNT	;

RXXEND:	lda	TEMPCLASS
	ldx	TEMPVAL
	jmp	SCI_RX_CBCK_S_RET

;--- Process 1st Data Bytes (rti is ok here; no need to parse; data is in x)

SCI_RX_CBCK_D1:
        sta     TEMPCLASS
	stx	TEMPVAL

        lda     SEX_Q_ENABLE    ;is SYSEX queue enabled?
	beq	RXDUN		;=0 (no)? leave...

RXNQ0:	lda	SEX_Q_COUNT	;
	cmp	#0		;
	bne	RXNQ1		;
	cpx	#$00		;yes? SysEx ID first byte match?
	bne	RX_RST		;no? reset queue enable...
	jmp	RXNQA		;

RXNQ1:	lda	SEX_Q_COUNT	;
	cmp	#1		;
	bne	RXNQ2		;
	cpx	#$01		;yes? SysEx ID second byte match?
	bne	RX_RST		;no? reset queue enable...
	jmp	RXNQA		;

RXNQ2:	lda	SEX_Q_COUNT	;
	cmp	#2		;
	bne	RXNQ3		;
	cpx	#$1A		;yes? SysEx ID third byte match?
	bne	RX_RST		;no? reset queue enable...
	jmp	RXNQA		;

RXNQ3:	lda	SEX_Q_COUNT	;
	cmp	#3		;
	bne	RXNQ4		;
	cpx	#$01		;yes? SysEx fourth byte match?
	bne	RX_RST		;no? reset queue enable...
	jmp	RXNQA		;

RXNQ4:	lda	SEX_Q_COUNT	;
	cmp	#4		;
	bne	RX_RST		;
	cpx	#$00		;yes? SysEx ID fifth byte match?
	beq	RX_GOT1		;
	cpx	#$01		;yes? SysEx ID fifth byte match?
	beq	RX_GOT2		;
	cpx	#$02		;yes? SysEx ID fifth byte match?
	beq	RX_GOT3		;
	cpx	#$03		;yes? SysEx ID fifth byte match?
	beq	RX_GOT4		;
	cpx	#$04		;yes? SysEx ID fifth byte match?
	beq	RX_GOT5		;
	jmp	RX_RST		;no match...

RX_GOT1:
	lda	#1		;
	jmp	RXG_DUN

RX_GOT2:
	lda	#2		;
	jmp	RXG_DUN

RX_GOT3:
	lda	#3		;
	jmp	RXG_DUN

RX_GOT4:
	lda	#4		;
	jmp	RXG_DUN

RX_GOT5:
	lda	#5		;

RXG_DUN:
	sta	MSGNUM		;save message number
        jmp	RXDUN		;

RXNQA:	lda	SEX_Q_COUNT	;enqueue data
	inca			;
	sta	SEX_Q_COUNT	;
        jmp	RXDUN		;

RX_RST:	lda	#0		;reinitialize variables
        sta     SEX_Q_COUNT     ;
	sta	SEX_Q_ENABLE	;
	sta	MSGNUM		;

RXDUN:
        lda     TEMPCLASS
	ldx	TEMPVAL
        jmp     SCI_RX_CBCK_D1_RET

;--- Service 2nd Data Bytes (byte value is in x; controller msg only)

SCI_RX_CBCK_D2:
        sta     TEMPCLASS

	lda	M_RSTAT		;fetch current Status Byte
	and	#$F0		;mask channel off
	cmp	#$B0		;is it a Controller message?
	beq	UR2A		;yes? branch...
	jmp	UR2DUN		;no? leave...

UR2A:	lda	#1		;set flags
        sta     CCFLAG          ;

UR2DUN: lda     TEMPCLASS
        jmp     SCI_RX_CBCK_D2_RET


