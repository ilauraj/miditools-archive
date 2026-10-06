;----------------------------------------------------------------;
; MIDI.ASM - SCI and MIDI Routines                               ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 12-Mar-1994                                           ;
;----------------------------------------------------------------;
;                                                                ;
; These routines provide the interface to the 6805's Serial      ;
; Communiations Interface (SCI), and MIDI processing.            ;
;                                                                ;
; Interupt Service Routine:                                      ;
;                                                                ;
;    SCI_ISR - SCI interrupt service routine                     ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    SCI_RX_INT_EN  - enables receiver interrupts                ;
;    SCI_RX_INT_DIS - disables receiver interrupts               ;
;    SCI_TX_INT_EN  - enables transmitter interrupts             ;
;    SCI_TX_INT_DIS - disables transmitter interrupts            ;
;    SCI_TX_MT_W8   - waits for empty SCI tx register            ;
;    MIDI_CLASS     - returns class mask for a MIDI message      ;
;    MIDI_INIT      - initializes MIDI primitives                ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    MIDI_ISR_LOOPBACK - Retransmits received data               ;
;    MIDI_PUT      - transmits MIDI byte out SCI                 ;
;    MIDI_GET      - receives a MIDI byte from SCI               ;
;    MIDI_PARSE    - parses data in MIDI receive queue           ;
;    MIDI_TEMPO    - sets tempo of outgoing MIDI Clock messages  ;
;    MIDI_METER    - computes NUM and DEN of meter               ;
;    MIDI_COMPUTE_SPP - computes SPP                             ;
;    MIDI_POSN     - sets MEASURE and BEAT                       ;
;    MIDI_PLAY     - start a sequence playing                    ;
;    MIDI_STOP     - stops a sequence                            ;
;    MIDI_SPP      - sends MIDI SPP                              ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    Variables used by transmit and receive queues:              ;
;                                                                ;
;    M_TX_Q      - pointer to data array                         ;
;    M_TX_Q_HEAD - pointer to next byte read from queue          ;
;    M_TX_Q_TAIL - pointer where next byte is written in queue   ;
;    M_TX_Q_MOD  - constant: queue size (must be modulus 2**N-1) ;
;    M_RX_Q	 - pointer to data array			 ;
;    M_RX_Q_HEAD - pointer to next byte read from queue          ;
;    M_RX_Q_TAIL - pointer where next byte is written in queue   ;
;    M_RX_Q_MOD  - constant: queue size (must be modulus 2**N-1) ;
;    M_RX_Q_XPT  - flags whether each class is enqueued          ;
;    M_RX_Q_FULL -  MIDI receive queue full flag                 ;
;                                                                ;
;                                                                ;
;    Variables used in SCI receive ISR, SCI_RX:                  ;
;								 ;
;    M_RSTAT     -  current running status                       ;
;    M_CLASS     -  current running class                        ;
;    M_DATA1     -  first Data Byte value                        ;
;    M_DATA2     -  second Data Byte value                       ;
;    M_THIRD     -  third byte flag                              ;
;    M_FULL_MSG  -  complete message flag                        ;
;								 ;
;    Variables used in MIDI sequencing applications:             ;
;                                                                ;
;    M_TEMPOCRLSB - temp variable for accessing OCR              ;
;    M_CLK_LSB    - LSB of 16-bit MIDI clock                     ;
;    M_CLK_MSB    - MSB of 16-bit MIDI clock                     ;
;    M_CLK_CNTR   - used to timeout MIDI clocks                  ;
;    M_TEMPO      - current M_TEMPO                              ;
;    M_MEASURE    - current measure                              ;
;    M_BEAT       - current beat                                 ;
;    M_NUM        - numerator of meter                           ;
;    M_DEN        - denominator of meter                         ;
;    M_SPPLSB     - song position pointer LSB                    ;
;    M_SPPMSB     - song position pointer MSB                    ;
;    M_PLAY       - flags a sequence is playing                  ;
;                                                                ;
;    Variables used in MIDI_PARSE routine:                       ;
;                                                                ;
;    MP_RSTAT    - current running status                        ;
;    MP_SRSTAT   - current Sys Realtime status                   ;
;    MP_SCSTAT   - current Sys Common status                     ;
;    MP_SXSTAT   - current Sys Exclusive status                  ;
;    MP_NUMDATA  - # of Data Bytes in current message            ;
;    MP_DATA1    - first Data Byte value                         ;
;    MP_DATA2    - second Data Byte value                        ;
;    MP_FLAGS    - MIDI message flags                            ;
;                   bit 0: CHMSG-cur byte is Channel msg         ;
;                   bit 1: SYSRT-cur byte is Sys Realtime msg    ;
;                   bit 2: SYSEX-cur byte is Sys Exclusive msg   ;
;                   bit 3: SYSCO-cur byte is Sys Common msg      ;
;                   bit 4: THIRD-third byte flag                 ;
;                   bit 5: not used                              ;
;                   bit 6: not used                              ;
;                   bit 7: QFULL-MIDI receive queue full flag    ;
;                                                                ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;	Constants
;----------------------------------------------------------------

M_TX_Q_MOD      EQU     31     ;MIDI transmit queue size
				;(must be modulus 2**N-1!)

M_RX_Q_MOD      EQU     3      ;MIDI receive queue size
				;(must be modulus 2**N-1!)

;These constants bitmap the MP_FLAGS variable

CHMSG		EQU	0	;current byte is Channel msg
SYSRT		EQU	1	;current byte is Sys Realtime msg
SYSEX		EQU	2	;current byte is Sys Exclusive msg
SYSCO		EQU	3	;current byte is Sys Common msg
THIRD           EQU     4       ;current  byte is third in a msg
QFULL           EQU     7       ;full buffer flag

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

;--- MIDI receive and transmit queues

M_TX_Q          .DS     (M_TX_Q_MOD+1) ;MIDI transmit queue data
M_TX_Q_HEAD     .DS     1       ;MIDI transmit queue head ptr
M_TX_Q_TAIL     .DS     1       ;MIDI transmit queue tail ptr

M_RX_Q          .DS     (M_RX_Q_MOD+1) ;MIDI receive queue data
M_RX_Q_HEAD     .DS     1       ;MIDI receive queue head ptr
M_RX_Q_TAIL     .DS     1       ;MIDI receive queue tail ptr

M_RX_Q_FULL     .DS     1       ;full buffer flag

;M_RX_Q_XPT is a bitfield which flags whether each class
;of received MIDI data is to be enqueued into the MIDI receive
;queue (M_RX_Q).
;
;M_RX_Q_XPT has the following bitfield format, corresponding to the
;MIDI message classes:
;
;     $80     $40   $20   $10   $08   $04    $02       $01
;  -----------------------------------------------------------
;  |SysReal|SysCom|SysEx|Ctlr|PchBnd|AftTch|PrgChg|NoteOn/Off|
;  -----------------------------------------------------------
;bit:  7       6     5     4     3     2      1         0

M_RX_Q_XPT      .DS     1       ;bitfield enables class buffers

;--- variables used in SCI interrupt service routine

M_RSTAT         .DS     1       ;current running status
M_CLASS         .DS     1       ;current running class
M_DATA1         .DS     1       ;first Data Byte value
M_DATA2         .DS     1       ;second Data Byte value
M_THIRD         .DS     1       ;third byte flag
M_FULL_MSG      .DS     1       ;complete message flag

;--- variables used in MIDI_PARSE function

MP_RSTAT        .DS     1       ;current running status
MP_SRSTAT       .DS     1       ;current Sys Realtime status
MP_SCSTAT       .DS     1       ;current Sys Common status
MP_SXSTAT       .DS     1       ;current Sys Exclusive status
MP_NUMDATA      .DS     1       ;# of Data Bytes in current msg
MP_DATA1        .DS     1       ;first Data Byte value
MP_DATA2        .DS     1       ;second Data Byte value
MP_FLAGS        .DS     1       ;MIDI message flags

;--- variables used in MIDI sequencing applications

M_TEMPOCRLSB    .DS     1       ;temp variable for accessing OCR
M_CLK_LSB    	.DS     1       ;LSB of 16-bit MIDI clock
M_CLK_MSB    	.DS     1       ;MSB of 16-bit MIDI clock
M_CLK_CNTR   	.DS     1       ;used to timeout MIDI clocks
M_TEMPO         .DS     1       ;current M_TEMPO
M_MEASURE       .DS     1       ;current measure
M_BEAT          .DS     1       ;current beat
M_NUM           .DS     1       ;numerator of meter
M_DEN           .DS     1       ;denominator of meter
M_SPPLSB        .DS     1       ;song position pointer LSB
M_SPPMSB        .DS     1       ;song position pointer MSB
M_PLAY          .DS     1       ;flags a sequence is playing

	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Register Access Macros
;----------------------------------------------------------------

SCI_RX_INT_EN: .MACRO           ;enables receiver interrupts
	bset	5,SCCR2
	.ENDM

SCI_RX_INT_DIS: .MACRO          ;disables receiver interrupts
	bclr	5,SCCR2
	.ENDM

SCI_TX_INT_EN: .MACRO           ;enables transmitter interrupts
	bset	7,SCCR2
	.ENDM

SCI_TX_INT_DIS: .MACRO          ;disables transmitter interrupts
	bclr	7,SCCR2
	.ENDM

SCI_TX_MT_W8: .MACRO            ;waits while transmit is busy

X|<*>	;places label "X###" where ### = program counter
	;this is necessary to define bounds of local labels

W8SCITX?: brclr   7,SCSR,W8SCITX?

X|<*>   ;see comment above
        ;

	NOP

	.ENDM

;----------------------------------------------------------------
;       Interrupt Service Routine
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       SCI_ISR                 ;
;                               ;
;-------------------------------;
;                               ;
; SCI interrupt service routine ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: M_RX_Q             ;
;            M_RX_Q_HEAD        ;
;            M_RX_Q_TAIL        ;
;            M_RX_Q_MOD         ;
;            M_TX_Q             ;
;            M_TX_Q_HEAD        ;
;            M_TX_Q_TAIL        ;
;            M_TX_Q_MOD         ;
;            M_FULL_MSG         ;
;            M_CLASS            ;
;            M_RSTAT            ;
;            M_THIRD            ;
;            M_DATA1            ;
;            M_DATA2            ;
;            M_RX_Q_XPT         ;
;            M_RX_Q_FULL        ;
;     Calls: MIDI_CLASS         ;
;    Macros: Q_PSH              ;
;            Q_POP              ;
;            SCI_TX_INT_DIS     ;
;                               ;
;-------------------------------;

SCI_ISR:

	;determine who caused the interrupt

        brset   5,SCSR,SCI_RX   ;receiver register full?
        brset   7,SCSR,SCI_TX   ;transmit register empty?

	lda	SCDAT		;make sure interrupt is cleared
	rti			;should never get here

;--------------------------------
;service transmit register empty
;--------------------------------

SCI_TX: jmp     SCI_TX_CBCK     ;call application code
SCI_TX_CBCK_RET:

	lda	M_TX_Q_HEAD	;if head=tail, queue is not empty
	cmp	M_TX_Q_TAIL	;
	beq	M_TX_MT		;

        Q_POP   M_TX_Q,M_TX_Q_HEAD,M_TX_Q_MOD ;pop next byte
	sta	SCDAT		;ship it
	rti

M_TX_MT:
        SCI_TX_INT_DIS          ;queue is empty, disable further
				; interrupts (writes to queue will
				; re-enable interrupts)
	rti

;--------------------------------
;service receiver full
;--------------------------------

SCI_RX: jmp     SCI_RX_CBCK     ;call application code
SCI_RX_CBCK_RET:

	ldx	SCDAT		;get byte
	bpl	SCIDATA		;branch if Data Byte

;--- process status byte (in x)

	txa
        jsr     MIDI_CLASS      ;get class --> acca
	ldx	SCDAT		;fetch current byte

	;dispatch all SYSTEM REALTIME messages

	cmp	#$80		;System Realtime?
	beq	SCIREAL		;yes? branch...

	;dispatch 1-BYTE SYSTEM COMMON messages (Tune,EOX,undefined)

        clr     M_FULL_MSG      ;reset full message flag
        sta     M_CLASS         ;store current "running" class
	cpx	#$F4		;is it a 1-byte Sys Common?
	bhs	SCICOM1		;yes? branch...

	;process other messages (all SYS EX; all CHANNEL: MTC, SPP, SONG SEL)

        stx     M_RSTAT         ;store running status
        clr     M_THIRD         ;reset third byte flag
SCIREAL:jmp     SCI_RX_CBCK_S   ;call application with Status Byte

SCICOM1:clr     M_RSTAT         ;clear running status
        inc     M_FULL_MSG      ;full message flag
        jmp     SCI_RX_CBCK_S   ;call appliation with Status Byte

;--- process data byte

SCIDATA:clr     M_FULL_MSG      ;reset full message flag

        lda     M_RSTAT         ;check running status
	beq	SCI_IGNORE	;if inactive, ignore data; continue

        lda     M_THIRD         ;branch if this is third data byte
	bne	SCI2_2		;

        lda     M_RSTAT         ;fetch running status

	cmp	#$C0		;branch if...
	blo	SCI1_2		; ...NOTE OFF, NOTE ON, KEY AFT, CONTROL

	cmp	#$E0		;branch if...
	blo	SCI1_1		; ...PROG CHANGE, CH AFT

	cmp	#$F0		;branch if...
	blo	SCI1_2		; ...PITCH BEND

	cmp	#$F2		;branch if...
	beq	SCI1_2		; ...SPP

	cmp	#$F0		;branch if...
	bne	SCI1_1R		; ...MTC, SONG SEL

	;otherwise, it is SYS EX data byte...

        stx     M_DATA1         ;store Data Byte
        lda     M_CLASS         ;fetch current class
        jmp     SCI_RX_CBCK_D1  ;call application with Data Byte 1

SCI1_1R:clr     M_RSTAT         ;clear running status
SCI1_1: stx     M_DATA1         ;store Data Byte
        inc     M_FULL_MSG      ;set full msg flag
        lda     M_CLASS         ;fetch current class
        jmp     SCI_RX_CBCK_D1  ;call application with Data Byte 1

SCI1_2: stx     M_DATA1         ;save data byte
        inc     M_THIRD         ;set third byte flag
        lda     M_CLASS         ;fetch current class
        jmp     SCI_RX_CBCK_D1  ;call application with Data Byte 1

SCI2_2: stx     M_DATA2         ;store Data Byte
        inc     M_FULL_MSG      ;full message flag
        clr     M_THIRD         ;clear third byte flag
        lda     M_CLASS         ;fetch running class
	cmp	#$40		;is it SPP (Sys Common)?
	bne	SCI2_2B		;no? call appl with Data Byte 2
        clr     M_RSTAT         ;yes? clear status
SCI2_2B:jmp     SCI_RX_CBCK_D2  ;call appl with Data Byte 2

;--- ignore data byte

SCI_IGNORE:
        inc     M_FULL_MSG      ;default full message flag
	rti			;ignore data, do not call application

;--- load buffer with selected bytes (data is in x, class is in acca)

SCI_RX_CBCK_S_RET:
SCI_RX_CBCK_D1_RET:
SCI_RX_CBCK_D2_RET:

SCI_BUFF:
        and     M_RX_Q_XPT      ;is this class enabled to buffer?
	bne	SCIBF1		;no? don't buffer it, return...
	rti

SCIBF1:	lda	M_RX_Q_TAIL	;if (tail+1)=head, queue is FULL
	inca			;
	and	#M_RX_Q_MOD	;
	cmp	M_RX_Q_HEAD	;
	bne	SCIBF2		;jump if room in queue
	lda	#1		;set overflow flag
        sta     M_RX_Q_FULL     ;
	rti

SCIBF2:	txa			;fetch data
	Q_PSH	M_RX_Q,M_RX_Q_TAIL,M_RX_Q_MOD ;push into queue
	rti

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       MIDI_CLASS              ;
;                               ;
;-------------------------------;
;                               ;
; Return class mask for a MIDI  ;
; message.                      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: Status byte     ;
;   Returns: A: class mask      ;
; Registers: A,X                ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_CLASS:

	cmp	#$F0		;Channel Message?
	blo	GCHMSG		;yes? branch...

	and	#$0F		;no? System Message...
	tax			;index with lowest 4 bits
	lda	CLASSMSK,X	;look up mask

        rts

GCHMSG: and     #$F0            ;strip off channel number
	lsra			;shift to index with 16-28
	lsra			; (counting by two's)
	lsra			;
	tax			;
	lda	CLASSMSK,X	;look up mask

        rts

CLASSMSK:	.DB	$20,$40,$40,$40,$40,$40,$40,$40,$80,$80
		.DB	$80,$80,$80,$80,$80,$80,$01,$00,$01,$00
		.DB	$04,$00,$10,$00,$02,$00,$04,$00,$08

;-------------------------------;
;                               ;
;	MIDI_INIT               ;
;                               ;
;-------------------------------;
;                               ;
; Initializes SCI for MIDI.     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: SCCR1              ;
;            SCCR2              ;
;            BAUD               ;
;            M_TX_Q_HEAD        ;
;            M_TX_Q_TAIL        ;
;            M_RX_Q_HEAD        ;
;            M_RX_Q_TAIL        ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_INIT:
        clr     M_TX_Q_HEAD     ;initialize MIDI queues
	clr	M_TX_Q_TAIL	;
        clr     M_RX_Q_HEAD     ;
	clr	M_RX_Q_TAIL	;
        clr     M_RX_Q_XPT      ;

	lda	#$00		;1 start, 8 data, 1 stop, wake-
	sta	SCCR1		;up = idle line

	lda	#$0C		;TIE=0, TCIE=0, RIE=0, ILIE=0
	sta	SCCR2		;TE=1, RE=1, RWU=0, SBK=0

	lda	#$20		;baud = 31.25 kbps
	sta	BAUD		;

        clr     MP_RSTAT        ;MIDI_PARSE variables
        clr     MP_SRSTAT       ;
        clr     MP_SCSTAT       ;
        clr     MP_SXSTAT       ;
        clr     MP_NUMDATA      ;
        clr     MP_DATA1        ;
        clr     MP_DATA2        ;
        clr     MP_FLAGS        ;

        clr     M_RSTAT         ;receive ISR variables
        clr     M_CLASS         ;
        clr     M_DATA1         ;
        clr     M_DATA2         ;
        clr     M_THIRD         ;
        clr     M_FULL_MSG      ;
        clr     M_RX_Q_FULL     ;

	lda	#0		;set M_TEMPO to 0 (MIDI Clock off)
        jsr     MIDI_TEMPO      ;

        clr     M_CLK_LSB       ;MIDI sequencer variables
	clr	M_CLK_MSB	;
	clr	M_CLK_CNTR	;
	clr	M_MEASURE 	;
	clr	M_BEAT		;
	clr	M_NUM		;
	clr	M_DEN		;
	clr	M_SPPLSB	;
	clr	M_SPPMSB	;
	clr	M_PLAY		;

        SCI_RX_INT_EN           ;enable SCI receiver interrupts

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;     MIDI_ISR_LOOPBACK (MACRO) ;
;                               ;
;-------------------------------;
;                               ;
; Retransmits received byte.    ;
;                               ;
; This MACRO should only be     ;
; used in ISR call backs!!!     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: X: received byte   ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls: MIDI_PUT           ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_ISR_LOOPBACK: .MACRO

        txa                     ;transfer byte to acca
	jsr	MIDI_PUT	;transmit it
        rti                     ;ret from interrupt, don't buffer

        .ENDM

;-------------------------------;
;                               ;
;	MIDI_PUT                ;
;                               ;
;-------------------------------;
;                               ;
; Transmits byte out SCI.       ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: byte            ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: M_TX_Q_TAIL        ;
;            M_TX_Q_HEAD        ;
;            M_TX_Q_MOD         ;
;     Calls:                    ;
;    Macros: SCI_TX_MT_W8       ;
;            Q_PSH              ;
;            SCI_TX_INT_EN      ;
;                               ;
;-------------------------------;

MIDI_PUT:

        tax

MPUTW8: lda	M_TX_Q_TAIL	;if (tail+1)=head, queue is full!
	inca			;
	and	#M_TX_Q_MOD	;
	cmp	M_TX_Q_HEAD	;
	beq	MPUTW8		;jump & wait if no room in queue
	txa

        ;push byte into MIDI TX queue

	Q_PSH	M_TX_Q,M_TX_Q_TAIL,M_TX_Q_MOD

	;enable transmit interrupts
        ;(SCI_ISR disables tx interrupts once queue is empty)

        SCI_TX_INT_EN

	rts

;-------------------------------;
;                               ;
;	MIDI_GET                ;
;                               ;
;-------------------------------;
;                               ;
; Read a byte from MIDI receive ;
; queue.                        ;
;                               ;
; Don't call if queue is empty! ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: A: received byte   ;
; Registers:                    ;
; Variables: M_RX_Q             ;
;            M_RX_Q_HEAD        ;
;            M_RX_Q_TAIL        ;
;            M_RX_Q_MOD         ;
;     Calls:                    ;
;    Macros: Q_POP              ;
;                               ;
;-------------------------------;

MIDI_GET:

        Q_POP   M_RX_Q,M_RX_Q_HEAD,M_RX_Q_MOD ;pop next byte

	rts

;-------------------------------;
;                               ;
;       MIDI_PARSE              ;
;                               ;
;-------------------------------;
;                               ;
; Parses data in MIDI receive   ;
; queue.                        ;
;                               ;
; Flags a new message via       ;
; MP_FLAGS variable.            ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: MP_FLAGS refreshed ;
; Registers: A,X                ;
; Variables: M_RX_Q_HEAD        ;
;            M_RX_Q_TAIL        ;
;            MP_RSTAT           ;
;            MP_DATA1           ;
;            MP_DATA2           ;
;            MP_NUMDATA         ;
;            MP_SRSTAT          ;
;            MP_FLAGS           ;
;            M_RX_Q_FULL        ;
;     Calls: MIDI_GET           ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_PARSE:

        lda     MP_FLAGS        ;clear message type flags
        and     #$F0            ;
        sta     MP_FLAGS        ;assume message is not ready

	lda	M_RX_Q_HEAD	;if head=tail, queue is empty
	cmp	M_RX_Q_TAIL	;
	bne	GOTBYTE 	;
	jmp	PARSEND 	;exit if no data waiting

GOTBYTE:
	jsr	MIDI_GET	;get next byte
	cmp	#$80
	blo	MIDIDATA	;branch if data byte

;--- process status byte

	;dispatch all SYSTEM REALTIME messages

	cmp	#$F8		;branch if System Realtime
	bhs	REALTM		;

	;dispatch 1-BYTE SYSTEM COMMON messages (Tune,EOX,undefined)

	cmp	#$F4		;dispatch System Common (1-byte) Msg
	bhs	SYSCOM1 	;

	;process other messages (all SYS EX, all CHANNEL, MTC, SPP, SONG SEL)

        sta     MP_RSTAT        ;store running status
        bclr    THIRD,MP_FLAGS  ;reset third byte flag
	jmp	PARSEND 	;continue

REALTM: sta     MP_SRSTAT       ;save status btye
        clr     MP_NUMDATA      ;no data bytes
        bset    SYSRT,MP_FLAGS  ;flag REALTIME event
	jmp	PARSEND 	;continue

SYSCOM1:
        sta     MP_SCSTAT       ;save status byte
        clr     MP_NUMDATA      ;no data bytes
        clr     MP_RSTAT        ;clear running status
        bset    SYSCO,MP_FLAGS  ;flag SYSTEM COMMON event
	jmp	PARSEND 	;continue

;--- process data byte

MIDIDATA:
	tax			;save received data byte

        lda     MP_RSTAT        ;check running status
	beq	PARSEND 	;if inactive, ignore data, continue

        brset THIRD,MP_FLAGS,X2_OF_2  ;branch if this is third byte

	cmp	#$C0		;branch if...
	blo	X1_OF_2 	; ...NOTE OFF, NOTE ON, KEY AFT, CONTROL

	cmp	#$E0		;branch if...
	blo	X1_OF_1 	; ...PROG CHANGE, CH AFT

	cmp	#$F0		;branch if...
	blo	X1_OF_2 	; ...PITCH BEND

	cmp	#$F2		;branch if...
	beq	X1_OF_2 	; ...SPP

	cmp	#$F0		;branch if...
	bne	X1_OF_1R	; ...MTC, SONG SEL

				;otherwise, SYSTEM EXCLUSIVE data byte
        sta     MP_SXSTAT       ;store as sys ex status (F0H)
	lda	#1		;this message has 1 data byte
        sta     MP_NUMDATA      ;
        stx     MP_DATA1        ;save data byte
        bset    SYSEX,MP_FLAGS  ;flag SYSTEM EXCLUSIVE data event
	jmp	PARSEND 	;continue

X1_OF_1R:
        sta     MP_SCSTAT       ;store as sys com status
	lda	#1		;this message has 1 data byte
        sta     MP_NUMDATA      ;
        stx     MP_DATA1        ;save data byte
        bset    SYSCO,MP_FLAGS  ;flag SYSTEM COMMON message
        clr     MP_RSTAT        ;clear running status
	jmp	PARSEND 	;continue

X1_OF_1:
	lda	#1		;this message has 1 data byte
        sta     MP_NUMDATA      ;
        stx     MP_DATA1        ;save data byte
        bset    CHMSG,MP_FLAGS  ;flag CHANNEL message
	jmp	PARSEND 	;continue

X1_OF_2:
        bset    THIRD,MP_FLAGS  ;flag third byte is coming up
        stx     MP_DATA1        ;save data
	jmp	PARSEND 	;continue

X2_OF_2:
        bclr    THIRD,MP_FLAGS 	;clear third byte flag
	lda	#2		;this message has 2 data bytes
        sta     MP_NUMDATA      ;
        stx     MP_DATA2        ;save data byte
        lda     MP_RSTAT        ;fetch running status
	cmp	#$F2		;is it SPP?
	beq	X2_OF_2R	;yes? branch to clear status
        bset    CHMSG,MP_FLAGS  ;no? flag CHANNEL message
	jmp	PARSEND 	;continue

X2_OF_2R:
        sta     MP_SCSTAT       ;store as sys com status
        bset    SYSCO,MP_FLAGS  ;flag SYSTEM COMMON message
        clr     MP_RSTAT        ;clear running status
	jmp	PARSEND 	;continue

PARSEND:
        ;detect and register "MIDI receive queue full" flags

        lda     M_RX_Q_FULL     ;fetch full buffer flag
	beq	P_RETURN	;leave now if buffer not full
        bset    QFULL,MP_FLAGS 	;flag full buffer condition
        clr     M_RX_Q_FULL     ;reset flag

P_RETURN:
	rts

;-------------------------------;
;                               ;
;       MIDI_TEMPO              ;
;                               ;
;-------------------------------;
;                               ;
; Sets tempo of outgoing MIDI   ;
; clock messages.               ;
;                               ;
; M_TEMPO = 0 turns MIDI Clock  ;
; off.                          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: M_TEMPO (20-255);
;   Returns:                    ;
; Registers: A,X                ;
; Variables: M_CLK_LSB          ;
;            M_CLK_MSB          ;
;            M_TEMPO            ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_TEMPO:

        sta     M_TEMPO

        ;setup timer for output compare interrupts

	cmp	#0		;turn off MIDI Clock?
	beq	MT1		;yup

        ;setup timer output compare reg for next timeout

	lda	M_TEMPO		;retrieve M_TEMPO

	cmp	#127		;indexed lookup only good for
	bhi	USETT2		;255 bytes, so table is split in 2

	lsla			;multiply index by 2 for words
	tax			;

	lda	TEMPOTBL1,X	;fetch high byte
	sta	M_CLK_MSB	;
	incx			;fetch low byte
	lda	TEMPOTBL1,X	;
	sta	M_CLK_LSB	;

        rts

USETT2: sub	#128		;offset for table
	lsla			;multiply index by 2 for words
	tax			;

	lda	TEMPOTBL2,X	;fetch high byte
	sta	M_CLK_MSB	;
	incx			;fetch low byte
	lda	TEMPOTBL2,X	;
	sta	M_CLK_LSB	;

        rts

MT1:	clr	TCR		;disable output compare interrupt

        rts

TEMPOTBL1:
.DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
.DW $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
.DW $0000, $0000, $0000, $0000
.DW $F424, $E884, $DDF2, $D44C, $CB73, $C350
.DW $BBCD, $B4D8, $AE63, $A85F, $A2C3, $9D83, $9896, $93F7
.DW $8F9D, $8B82, $87A2, $83F8, $807F, $7D33, $7A12, $7718
.DW $7442, $718E, $6EF9, $6C82, $6A26, $67E4, $65BA, $63A6
.DW $61A8, $5FBE, $5DE6, $5C21, $5A6C, $58C7, $5731, $55AA
.DW $5430, $52C2, $5161, $500C, $4EC1, $4D81, $4C4B, $4B1F
.DW $49FB, $48E1, $47CE, $46C4, $45C1, $44C6, $43D1, $42E3
.DW $41FC, $411B, $403F, $3F6A, $3E9A, $3DCF, $3D09, $3C48
.DW $3B8C, $3AD4, $3A21, $3972, $38C7, $3820, $377D, $36DD
.DW $3641, $35A8, $3513, $3481, $33F2, $3366, $32DD, $3257
.DW $31D3, $3152, $30D4, $3058, $2FDF, $2F68, $2EF3, $2E81
.DW $2E10, $2DA2, $2D36, $2CCC, $2C64, $2BFD, $2B99, $2B36
.DW $2AD5, $2A76, $2A18, $29BC, $2961, $2908, $28B1, $285B
.DW $2806, $27B3, $2761, $2710, $26C1, $2673

TEMPOTBL2:
.DW $2626, $25DA
.DW $258F, $2546, $24FE, $24B6, $2470, $242B, $23E7, $23A4
.DW $2362, $2321, $22E1, $22A1, $2263, $2225, $21E9, $21AD
.DW $2172, $2137, $20FE, $20C5, $208D, $2056, $2020, $1FEA
.DW $1FB5, $1F81, $1F4D, $1F1A, $1EE7, $1EB6, $1E84, $1E54
.DW $1E24, $1DF5, $1DC6, $1D98, $1D6A, $1D3D, $1D10, $1CE4
.DW $1CB9, $1C8E, $1C63, $1C39, $1C10, $1BE7, $1BBE, $1B96
.DW $1B6E, $1B47, $1B20, $1AFA, $1AD4, $1AAF, $1A89, $1A65
.DW $1A40, $1A1C, $19F9, $19D6, $19B3, $1991, $196E, $194D
.DW $192B, $190A, $18EA, $18C9, $18A9, $1889, $186A, $184B
.DW $182C, $180E, $17EF, $17D2, $17B4, $1797, $177A, $175D
.DW $1740, $1724, $1708, $16ED, $16D1, $16B6, $169B, $1680
.DW $1666, $164C, $1632, $1618, $15FF, $15E5, $15CC, $15B4
.DW $159B, $1583, $156A, $1553, $153B, $1523, $150C, $14F5
.DW $14DE, $14C7, $14B1, $149A, $1484, $146E, $1458, $1443
.DW $142D, $1418, $1403, $13EE, $13D9, $13C5, $13B0, $139C
.DW $1388, $1374, $1360, $134D, $1339, $1326

;-------------------------------;
;                               ;
;	MIDI_METER              ;
;                               ;
;-------------------------------;
;                               ;
; Computes new M_NUM and M_DEN  ;
; variables used by other       ;
; procedures to compute MEASURE ;
; and BEAT.                     ;
;                               ;
; M_NUM = numerator of meter    :
;       valid range: 1-16       ;
;                               ;
; M_DEN = log2(denominator)     ;
;       valid range: 0-4        ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: numerator (1-16);
;            X: denominator     :
;               (1,2,4,8,16)    ;
;   Returns: M_NUM, M_DEN   	;
;	     refreshed          ;
; Registers: A,X                ;
; Variables: M_NUM              ;
;            M_DEN              ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_METER:

	sta	M_NUM

	lda	#0		;translate 1,2,4,8,16 to 0,1,2,3,4
	cpx	#1		;this is the number of left shifts
	beq	MM0		;for computation of current beat
	inca			;
	cpx	#2		;
	beq	MM0		;
	inca			;
	cpx	#4		;
	beq	MM0		;
	inca			;
	cpx	#8		;
	beq	MM0		;
	inca			;
	cpx	#$10		;
	beq	MM0		;

        rts                     ;if we get here, error

MM0:	sta	M_DEN		;save new meter denominator

        rts

;-------------------------------;
;                               ;
;	MIDI_COMPUTE_SPP        ;
;                               ;
;-------------------------------;
;                               ;
; Computes new SPP from         ;
; M_MEASURE and BEAT.           ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: M_SPPMSB refreshed ;
;            M_SPPLSB refreshed ;
; Registers: A,X                ;
; Variables: M_NUM              ;
;            M_MEASURE          ;
;            M_SPPLSB           ;
;            M_SPPMSB           ;
;            M_BEAT             ;
;            M_DEN              ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

;procedure to compute SPP:
;  1) compute # elapsed beats (NUM*MEASURE+BEAT)
;  2) multiply by 96/denominator to get # pulses
;  3) divide by 6 to get SPP
;
;this simplifies to (#elapsed beats)*16/denominator, since
;denominator = 1,2,4,8,16 this further simplifies to:
;
;  SPP = (NUM*MEASURE+BEAT) << (4,3,2,1,0)
;                               ^ ^ ^ ^ ^
;              for denominator= 1,2,4,8,16

MIDI_COMPUTE_SPP:
	lda	M_NUM		;NUM*MEASURE
	ldx	M_MEASURE	;
        mul                     ;
	sta	M_SPPLSB	;
	stx	M_SPPMSB	;
	add	M_BEAT		;NUM*MEASURE+BEAT
	sta	M_SPPLSB	;
	txa			;
	adc	#0		;
	sta	M_SPPMSB	;M_SPPMSB:M_SPPLSB = # elapsed beats

	lda	M_DEN		;DEN = log2(denom) = 0,1,2,3,4
	cmp	#0		;corresponding to 1,2,4,8,16
	beq	MCS0		;
	cmp	#1		;
	beq	MCS1		;
	cmp	#2		;
	beq	MCS2		;
	cmp	#3		;
	beq	MCS3		;

	;multiply NUM*MEASURE+BEAT by 2

MCS4:	lda	M_SPPLSB
	lsla
	sta	M_SPPLSB
	lda	M_SPPMSB
	rola
	sta	M_SPPMSB

	;multiply NUM*MEASURE+BEAT by 2

MCS3:	lda	M_SPPLSB
	lsla
	sta	M_SPPLSB
	lda	M_SPPMSB
	rola
	sta	M_SPPMSB

	;multiply NUM*MEASURE+BEAT by 2

MCS2:	lda	M_SPPLSB
	lsla
	sta	M_SPPLSB
	lda	M_SPPMSB
	rola
	sta	M_SPPMSB

	;multiply NUM*MEASURE+BEAT by 2

MCS1:	lda	M_SPPLSB
	lsla
	sta	M_SPPLSB
	lda	M_SPPMSB
	rola
	sta	M_SPPMSB

MCS0:   rts

;-------------------------------;
;                               ;
;	MIDI_POSN		;
;                               ;
;-------------------------------;
;                               ;
; Sets MEASURE and BEAT to	;
; argument.  This subroutine	;
; call is necessary to avoid	;
; contention with the timer ISR ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: measure         ;
;            X: beat            ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: M_MEASURE          ;
;            M_BEAT             ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_POSN:

	sta	M_MEASURE 	;save new MEASURE
	stx	M_BEAT		;save new BEAT

        rts

;-------------------------------;
;                               ;
;	MIDI_PLAY               ;
;                               ;
;-------------------------------;
;                               ;
; Sends MIDI Stop, computes new ;
; SPP from arguments, sends SPP,;
; sends MIDI Continue.          ;
;                               ;
; If arguments (measure,beat)   ;
; = 0 (start of song) MIDI      ;
; Start is sent in lieu of SPP  ;
; and Continue.                 ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: measure         ;
;            X: beat            ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: M_PLAY             ;
;            M_MEASURE          ;
;            M_BEAT             ;
;            M_MEASURE          ;
;            M_CLK_LSB          ;
;            M_CLK_MSB       	;
;            M_TEMPOCRLSB       ;
;            M_CLK_CNTR         ;
;     Calls: MIDI_POSN          ;
;            MIDI_STOP          ;
;            MIDI_COMPUTE_SPP   ;
;            MIDI_SPP           ;
;            MIDI_PUT           ;
;            DELAY_1MS          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_PLAY:

	jsr	MIDI_POSN	;save new MEASURE and BEAT

	lda	M_PLAY		;are we playing?
	beq	MP1		;

	jsr	MIDI_STOP	;yes? send MIDI Stop message

MP1:	inc	M_PLAY		;flag "playing status"

	lda	M_MEASURE 	;
	ora	M_BEAT		;if MEASURE=BEAT=0,
	beq	MP3		; send MIDI Start

	jsr	MIDI_COMPUTE_SPP ;otherwise, compute new SPP
	jsr	MIDI_SPP	;send new SPP

        ;setup timer registers for first time-out

	clr	TCR		;disable timer interrupts
	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;

	lda	#$FB		;send MIDI Continue
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	clr	M_CLK_CNTR	;reset clock counter
	lda	#$40		;enable timer interrupts
	sta	TCR		;

        rts

MP3:	;--- setup timer registers for first time-out

	clr	TCR		;disable timer interrupts
	lda	M_CLK_LSB	;compute and store next output
	add	CARLSB		; compare register value
	sta	M_TEMPOCRLSB	;
	lda	M_CLK_MSB	;
	adc	CARMSB		;
	sta	OCRMSB		;
	lda	TSR		;necessary to clear OCF flag
	lda	M_TEMPOCRLSB	;
	sta	OCRLSB		;

	lda	#$FA		;send MIDI Start
	jsr	MIDI_PUT	;
	jsr	DELAY_1MS	;
	clr	M_CLK_CNTR	;reset clock counter
	lda	#$40		;enable timer interrupts
	sta	TCR		;

        rts

;-------------------------------;
;                               ;
;	MIDI_STOP               ;
;                               ;
;-------------------------------;
;                               ;
; Sends MIDI Stop and updates   ;
; M_PLAY with "not playing"   	;
; status.                       ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: M_PLAY          	;
;     Calls: DELAY_100MS        ;
;            MIDI_PUT           ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_STOP:

	clr	M_PLAY		;turn off PLAY flag

	lda	#$FC		;send MIDI Stop message
	jsr	MIDI_PUT	;

	jsr	DELAY_100MS	;delay to allow the sequencer
	jsr	DELAY_100MS	; time to reset itself, etc.
	jsr	DELAY_100MS	;
	jsr	DELAY_100MS	;
	jsr	DELAY_100MS	;

        rts

;-------------------------------;
;                               ;
;	MIDI_SPP                ;
;                               ;
;-------------------------------;
;                               ;
; Sends MIDI Song Position      ;
; Pointer, derived from global  ;
; M_SPPMSB, M_SPPLSB varaibles. ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: M_SPPLSB           ;
;            M_SPPMSB           ;
;            M_RSTAT            ;
;     Calls: MIDI_PUT           ;
;    Macros:                    ;
;                               ;
;-------------------------------;

MIDI_SPP:

	sei			;disable all interrupts
	lda	#$F2		;send SPP Status byte
	jsr	MIDI_PUT	;

	lda	M_SPPLSB	;convert SPP to MIDI data bytes
	bmi	MSP1		;...branch if MSB of M_SPPLSB = 1

	jsr	MIDI_PUT	;transmit SPP LSB

	lda	M_SPPMSB	;fetch SPP MSB
	lsla			;(LSB = M_SPPLSB's MSB = 0)
	and	#$7F		;force to data byte format
	jsr	MIDI_PUT	;transmit SPP MSB
	cli			;enable all interrupts

        rts

MSP1:	and	#$7F		;force to data byte format
	jsr	MIDI_PUT	;transmit SPP LSB

	lda	M_SPPMSB	;fetch SPP MSB
	lsla			;(LSB = M_SPPLSB's MSB = 1)
	ora	#$01		;
	and	#$7F		;force to data byte format
	jsr	MIDI_PUT	;transmit SPP MSB

        lda     M_RSTAT         ;fetch current running status
	beq	MSP2		;=0? continue
	jsr	MIDI_PUT	;not =0? send it...

MSP2:	cli			;enable all interrupts

        rts
