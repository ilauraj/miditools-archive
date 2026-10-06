;----------------------------------------------------------------;
; SPI.ASM - Serial Peripheral Interface Support                  ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;                                                                ;
; These routines provide basic support for the SPI port.         ;
;                                                                ;
; Interrupt Service Routine:                                     ;
;                                                                ;
;    SPI_ISR  - SPI interrupt service routine                    ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    SPI_RDY  - waits for SPIF flag to set                       ;
;    SPI_INIT - initializes SPI                                  ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    SPI_IO   - outputs MOSI and inputs MISO                     ;
;                                                                ;
;----------------------------------------------------------------;

	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Interrupt Service Routine
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       SPI_ISR                 ;
;                               ;
;-------------------------------;
;                               ;
; SPI interrupt service routine ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

SPI_ISR:                        ;SPI interrupts vector here

        jmp     SPI_CBCK        ;call application code
SPI_CBCK_RET:                   ;

        rti

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       SPI_RDY (MACRO)         ;
;                               ;
;-------------------------------;
;                               ;
; Waits for SPI's SPIF flag to  ;
; set, indicating the SPI is    ;
; ready.                        ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

SPI_RDY: .MACRO

X|<*>	;places label "X###" where ### = program counter
	;this is necessary to define bounds of local labels
W8LOOP?:
	brclr	7,SPSR,W8LOOP?	;wait for SPIF (transfer complete)

X|<*>   ;see comments above
        ;

	NOP

	.ENDM


;-------------------------------;
;                               ;
;       SPI_INIT                ;
;                               ;
;-------------------------------;
;                               ;
; Initialize SPI.               ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

SPI_INIT:

        lda     #$53            ;this code enables SPI in master
        sta     SPCR            ; mode, baud = clock/32

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	SPI_IO                  ;
;                               ;
;-------------------------------;
;                               ;
; Transfers data to/from SPI    ;
; ports.                        ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: out (MOSI) value;
;   Returns: A: in (MISO) value ;
; Registers: A,X                ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

SPI_IO:
;	SPI_RDY 		;wait if SPI is busy
        ldx     SPSR            ;clears SPIF (prepare to send)
	sta	SPDR		;transmit via SPI
        SPI_RDY                 ;wait for SPIF (transfer complete)
	lda	SPDR		;fetch incoming data
	rts

