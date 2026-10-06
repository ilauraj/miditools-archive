;----------------------------------------------------------------;
; 6805C8.ASM - Basic MC68HC705C8 System Stuff                    ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;                                                                ;
; This file provides the basic MC68HC705C8 memory map equates,   ;
; hardware assignments, macro language enhancements, Reset ISR,  ;
; SWI ISR, and IRQ ISR.                                          ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;       Macro Language Enhancements
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       JMP_TABLE (MACRO)       ;
;                               ;
;-------------------------------;
;                               ;
; "Jump from table" extension   ;
; to 6805's native instruction  ;
; set.				;
;                               ;
; Creates "self-modifying code" ;
; in SMC_IMG RAM image.         ;
;                               ;
;-------------------------------;
;                               ;
;                               ;
; Arguments: X: table entry	;
;	     TABLE: ptr to table;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: SMOD_IMG           ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;


JMP_TABLE: .MACRO TABLE

        lda     #$CC            ;create jmp opcode
        sta     SMC_IMG         ;

	lslx			;point to table entry

	lda	TABLE,X 	;high byte of address
        sta     SMC_IMG+1       ;

	lda	TABLE+1,X	;low byte of address
        sta     SMC_IMG+2       ;

        jmp     SMC_IMG         ;execute this instruction

	.ENDM

;-------------------------------;
;                               ;
;       FAR_BEQ     (MACROS)    ;
;	FAR_BNE                 ;
;       FAR_BRSET               ;
;       FAR_BRCLR               ;
;       FAR_BHI                 ;
;       FAR_BLO                 ;
;       FAR_BHS                 ;
;       FAR_BLS                 ;
;       FAR_BCS                 ;
;       FAR_BCC                 ;
;       FAR_BPL                 ;
;       FAR_BMI                 ;
;                               ;
;-------------------------------;
;                               ;
; These Extensions to 6805's    ;
; native instruction set allow  ;
; 16-bit branches.              ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: DEST: destination  ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

FAR_BEQ: .MACRO DEST

X|<*>	;places label "X###" where ### = program counter
	;this is necessary to define bounds of local labels

	bne	NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BNE: .MACRO DEST

X|<*>   ;see comment above
        ;

	beq	NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BRSET: .MACRO ARG1,ARG2,ARG3

X|<*>   ;see comment above
        ;

	brclr	ARG1,ARG2,NOBRA?
	jmp	ARG3
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BRCLR: .MACRO ARG1,ARG2,ARG3

X|<*>   ;see comment above
        ;

        brset   ARG1,ARG2,NOBRA?
	jmp	ARG3
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BHI: .MACRO DEST

X|<*>   ;see comment above
        ;

        bls     NOBRA?
	jmp	DEST
NOBRA?:

	NOP
	.ENDM


FAR_BLO: .MACRO DEST

X|<*>   ;see comment above
        ;

        bhs     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BHS: .MACRO DEST

X|<*>   ;see comment above
        ;

        blo     NOBRA?
	jmp	DEST
NOBRA?:

	NOP
	.ENDM

FAR_BLS: .MACRO DEST

X|<*>   ;see comment above
        ;

        bhi     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BCS: .MACRO DEST

X|<*>   ;see comment above
        ;

        bcc     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BCC: .MACRO DEST

X|<*>   ;see comment above
        ;

        bcs     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BPL: .MACRO DEST

X|<*>   ;see comment above
        ;

        bmi     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM

FAR_BMI: .MACRO DEST

X|<*>   ;see comment above
        ;

        bpl     NOBRA?
	jmp	DEST
NOBRA?:

X|<*>   ;see comment above
        ;

	NOP
	.ENDM


;-------------------------------;
;                               ;
;       Q_PSH (MACRO)           ;
;                               ;
;-------------------------------;
;                               ;
; Pushes byte onto tail of      ;
; queue.                        ;
;                               ;
; Caller must avoid overflow.   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: byte            ;
;            Qptr: addr of Q    ;
;            Qtail: next in     ;
;            Qmod: Q modulus    ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

Q_PSH: .MACRO Qptr,Qtail,Qmod

        ldx     Qtail           ;write byte to Q
	sta	Qptr,X		;

	txa			;advance Qtail
	inca			;
	and	#Qmod 		;modulus Qmod
	sta	Qtail		;

	.ENDM

;-------------------------------;
;                               ;
;       Q_POP (MACRO)           ;
;                               ;
;-------------------------------;
;                               ;
; Pops byte from head of queue. ;
;                               ;
; Caller must avoid underflow.  ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: Qptr: addr of Q    ;
;            Qhead: next out    ;
;            Qmod: Q modulus    ;
;   Returns: A: byte            ;
; Registers: A,X                ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

Q_POP: .MACRO Qptr,Qhead,Qmod

        ldx     Qhead           ;read byte from Q
	ldx	Qptr,X		;

	lda	Qhead		;advance Qhead
	inca			;
	and	#Qmod 		;modulus Qmod
	sta	Qhead		;

	txa

	.ENDM


;----------------------------------------------------------------
;	MC68HC705C8 Memory Map
;----------------------------------------------------------------

PORTA	EQU	$0000		;ports
PORTB	EQU	$0001		;
PORTC	EQU	$0002		;
PORTD	EQU	$0003		;
DDRA	EQU	$0004		;
DDRB	EQU	$0005		;
DDRC	EQU	$0006		;

;UNUSED		$0007		;unused
;UNUSED		$0008		;
;UNUSED		$0009		;

SPCR	EQU	$000A		;SPI registers
SPSR	EQU	$000B		;
SPDR	EQU	$000C		;

BAUD	EQU	$000D		;SCI registers
SCCR1	EQU	$000E		;
SCCR2	EQU	$000F		;
SCSR	EQU	$0010		;
SCDAT	EQU	$0011		;

TCR	EQU	$0012		;timer registers
TSR	EQU	$0013		;
ICRMSB	EQU	$0014		;
ICRLSB	EQU	$0015		;
OCRMSB	EQU	$0016		;
OCRLSB	EQU	$0017		;
CNTRMSB	EQU	$0018		;
CNTRLSB	EQU	$0019		;
CARMSB	EQU	$001A		;
CARLSB	EQU	$001B		;

PROG	EQU	$001C		;EPROM program register

COPRST	EQU	$001D		;COP registers
COPCR	EQU	$001E		;

;UNUSED		$001F		;unused

RAM0    EQU     $0030           ;32 bytes of RAM (OPTION reg. RAM0=1)
RAM	EQU	$0050		;176 bytes of RAM
STACK	EQU	$00C0		;64 bytes of stack (not accessible)
RAM1	EQU	$0100		;96 bytes of RAM (OPTION reg. RAM1=1)

;PROM	EQU	$0160		;7584 bytes of user PROM
PROM	EQU	$0180		;7584 bytes of user PROM (***** EVM FIX *****)

BOOT	EQU	$1F00		;233 bytes of BOOT ROM
OPTREG	EQU	$1FDF		;OPTION register
VBOOT	EQU	$1FE0		;16 bytes of BOOT vectors

;UNUSED		$1FF0		;4 bytes unused

VSPI	EQU	$1FF4		;SPI vector
VSCI	EQU	$1FF6		;SCI vector
VTIMER	EQU	$1FF8		;TIMER vector
VIRQ	EQU	$1FFA		;IRQ vector
VSWI	EQU	$1FFC		;SWI vector
VRESET	EQU	$1FFE		;RESET vector

;----------------------------------------------------------------
;       MIDItools CPU Board Hardware Assignments
;----------------------------------------------------------------

;Port A -- misc control
;----------------------------------------------------------------
; PA7:	ADC chip select
; PA6:  EEPROM chip select
; PA5:  LED shift register latch enable
; PA4:  expansion port X1
; PA3:	expansion port X0
; PA2:	LCDRS control line to LCD peripheral
; PA1:	LCDRW control line to LCD peripheral
; PA0:	LCDE control line to LCD peripheral

IVPORTA EQU     $C0             ;initial Port A value
IVDDRA	EQU	$FF		;initial DDR A value (outputs)

X0_HI   .MACRO                  ;macro sets X0
        bset    3,PORTA         ;
        .ENDM                   ;

X0_LO   .MACRO                  ;macro clears X0
        bclr    3,PORTA         ;
        .ENDM                   ;

X1_HI   .MACRO                  ;macro sets X1
        bset    4,PORTA         ;
        .ENDM                   ;

X1_LO   .MACRO                  ;macro clears X1
        bclr    4,PORTA         ;
        .ENDM                   ;
*
;Port B -- general purpose data bus
;----------------------------------------------------------------
;Port B is the general purpose bi-directional data bus

IVPORTB	EQU	$00		;initial Port B value
IVDDRB	EQU	$00		;initial DDR B value (inputs)

WR_DATA	.MACRO			;macro writes ACCU to port B
	clr	DDRB		;set up port B for all outputs
	dec	DDRB		;(DDRB = $FF)
	sta	PORTB		;output data
	.ENDM

RD_DATA	.MACRO			;macro reads port B, ACCU = value
	clr	DDRB		;set up port B for all inputs
	lda	PORTB		;read data
	.ENDM

;Port C -- switches
;----------------------------------------------------------------
;Port C is the switch input bus

; PC0-PC7 = SW0-SW7

IVPORTC EQU     $00             ;initial Port C value
IVDDRC  EQU     $00             ;initial DDR C value (inputs)

RD_SWROWS: .MACRO               ;macro reads switch rows
        clr     DDRC
        lda     PORTC
	.ENDM

;----------------------------------------------------------------
;       Define RAM and ROM Sections
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE
        .ORG RAM0

SMC_IMG:  .DS 3                 ;reserve 3 bytes for self
				;modifying code

APPL_RAM: .SECTION
          .ABSOLUTE             ;this is where applications put RAM
          .ORG RAM1             ;

        .CODE                   ;this is where program code lives
        .RELATIVE               ;
        .ORG    PROM            ;

;----------------------------------------------------------------
;       Reset Interrupt Service Routine
;----------------------------------------------------------------

RESET_ISR:

	sei			;disable interrupts until we're initialized

;--- Initialize 68HC05C8 OPTION Register

;[ OPTION Register ]
;Bit 7  RAM0    define RAM0 block: 0 = PROM, 1 = RAM
;Bit 6  RAM1    define RAM1 block: 0 = PROM, 1 = RAM
;Bit 5	unused
;Bit 4	unused
;Bit 3	SEC	SECURITY: 0 = security off, 1 = on
;Bit 2	unused
;Bit 1	IRQ	IRQ sensitivity: 0 = fall/level, 1 = fall
;Bit 0	unused


        lda     #$C2            ;RAM0 & RAM1 = RAM, no security,
        sta     OPTREG          ; IRQ on falling edge

;--- Initialize Ports

        lda     #IVPORTA	;set up initial states of ports
        sta     PORTA           ; as defined in ports discussion
        lda     #IVPORTB        ; above
        sta     PORTB		;
        lda	#IVPORTC	;
        sta     PORTC		;

        lda	#IVDDRA		;set up data direction registers
        sta     DDRA            ; as defined in ports discussion
        lda     #IVDDRB         ; above
        sta     DDRB		;
        lda	#IVDDRC		;
        sta     DDRC		;

;--- Initialize Internal Peripherals

	jsr	MIDI_INIT	;initialize SCI for MIDI
	jsr	SPI_INIT	;initialize SPI

;*********************************************************************************************

;--- Initialize Custom instrument hardware

	;X0_LO                   
	;lda	#$FF			;lets go of data bus
	;jsr	SPI_IO		;
	;X0_HI                   ;latch data
	;X0_LO                   ;

;*********************************************************************************************

;--- Initialize External Peripherals

	jsr	SW_INIT 	;initialize switches
	jsr	LCD_INIT	;initialize LCD
	jsr	LED_INIT	;initialize LEDs
	jsr	EE_INIT 	;initialize EEPROM
	jsr	ADC_INIT	;initialize ADC

;--- Initialize Interrupts

        cli                     ;enable interrupts

;--- Start Application

        jmp     APPLICATION     ;vector off to application land

;----------------------------------------------------------------
;       IRQ and SWI Interrupt Service Routines
;----------------------------------------------------------------

;NULL ISRs

IRQ_ISR:
        jmp     IRQ_CBCK        ;call application code
IRQ_CBCK_RET:                   ;
        rti

SWI_ISR:
        jmp     SWI_CBCK        ;call application code
SWI_CBCK_RET:                   ;
        rti

;This MACRO provides the most minimal ISR Call Back overhead for
;the SPI, External, and Software interrupts. An application can
;call this MACRO if it doesn't service any of these interrupts.
;----------------------------------------------------------------

IGNORE_IRQ_SWI_SPI: .MACRO

IRQ_CBCK: jmp IRQ_CBCK_RET      ;return to BIOS
SWI_CBCK: jmp SWI_CBCK_RET
SPI_CBCK: jmp SPI_CBCK_RET

        .ENDM


