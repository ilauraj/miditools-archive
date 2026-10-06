;----------------------------------------------------------------;
; ADC.ASM - Analog to Digital Converter Support                  ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;                                                                ;
; These routines provide the interface to the National           ;
; Semiconductor ADC0834 ADC.                                     ;
;                                                                ;
; Details on the interface to this chip are available in the     ;
; National Semiconductor "Data Conversion" data book.            ;
;                                                                ;
; Data is transferred via SPI, with chip select driven by        ;
; port A7.                                                       ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    ADC_ENABLE  - enables ADC chip select                       ;
;    ADC_DISABLE - disables ADC chip select                      ;
;    ADC_INIT    - initializes ADC                               ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    ADC_READ - reads all four channels of ADC.                  ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    ADC0     - current value of ADC channel 0                   ;
;    ADC1     - current value of ADC channel 1                   ;
;    ADC2     - current value of ADC channel 2                   ;
;    ADC3     - current value of ADC channel 3                   ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;       Hardware Access Macros
;----------------------------------------------------------------

ADC_ENABLE: .MACRO              ;enable ADC chip select
        bclr    7,PORTA
        .ENDM

ADC_DISABLE: .MACRO             ;disable ADC chip select
        bset    7,PORTA
        .ENDM


;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

ADC0		.DS	1	;current value of ADC channel 0
ADC1		.DS	1	;current value of ADC channel 1
ADC2		.DS	1	;current value of ADC channel 2
ADC3		.DS	1	;current value of ADC channel 3


	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	ADC_INIT                ;
;                               ;
;-------------------------------;
;                               ;
; Initializes ADC.              ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: ADC0               ;
;            ADC1               ;
;            ADC2               ;
;            ADC3               ;
;     Calls:                    ;
;    Macros: ADC_DISABLE        ;
;                               ;
;-------------------------------;

ADC_INIT:

	clr	ADC0		;clear ADC values
	clr	ADC1		;
	clr	ADC2		;
	clr	ADC3		;

        ADC_DISABLE             ;default chip select

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	ADC_READ                ;
;                               ;
;-------------------------------;
;                               ;
; Reads chan's 0,1,2,3 of ADC.  ;
;                               ;
; SPI operation is performed    ;
; directly since SPI use is     ;
; unique.                       ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: ADC0 refreshed     ;
;            ADC1 refreshed     ;
;            ADC2 refreshed     ;
;            ADC3 refreshed     ;
; Registers: A,X                ;
; Variables: ADC0               ;
;            ADC1               ;
;            ADC2               ;
;            ADC3               ;
;     Calls:                    ;
;    Macros: ADC_ENABLE         ;
;            ADC_DISABLE        ;
;            SPI_RDY            ;
;                               ;
;-------------------------------;

ADC_READ:

	 ;rts				;*************** MOD TO DISABLE ADC!!!!!!!!!!!!!!!

;--- read chan 0

        ADC_ENABLE

        lda     SPSR            ;clears SPIF (prepare to send)
        lda     #$C0            ;adc header for chan 1
	sta	SPDR		;transmit via SPI
        SPI_RDY                 ;

        lda     SPDR            ;fetch data

        ldx     SPSR            ;clears SPIF (prepare to send)
        stx     SPDR            ;transmit "don't care" out SPI
        SPI_RDY                 ;

        ldx     SPDR            ;receive SPI byte

        lsra                    ;shift LS 3 bits of A into
        rorx                    ; MS 5 bits of X
	lsra			;
	rorx			;
	lsra			;
	rorx			;
        stx     ADC0            ;save value

        ADC_DISABLE

;--- read adc chan 1

        ADC_ENABLE

        lda     SPSR            ;clears SPIF (prepare to send)
	lda	#$E0		;adc header for chan 1
	sta	SPDR		;transmit via SPI
        SPI_RDY                 ;

        lda     SPDR            ;fetch data

        ldx     SPSR            ;clears SPIF (prepare to send)
	stx	SPDR		;transmit "don't care" out SPI
        SPI_RDY                 ;

        ldx     SPDR            ;receive SPI byte

        lsra                    ;shift LS 3 bits of A into
        rorx                    ; MS 5 bits of X
	lsra			;
	rorx			;
	lsra			;
	rorx			;
        stx     ADC1            ;save value

        ADC_DISABLE

;--- read adc chan 2

        ADC_ENABLE

        lda     SPSR            ;clears SPIF (prepare to send)
	lda	#$D0		;adc header for chan 2
	sta	SPDR		;transmit via SPI
        SPI_RDY                 ;

        lda     SPDR            ;fetch data

        ldx     SPSR            ;clears SPIF (prepare to send)
	stx	SPDR		;transmit "don't care" out SPI
        SPI_RDY                 ;

        ldx     SPDR            ;receive SPI byte

        lsra                    ;shift LS 3 bits of A into
        rorx                    ; MS 5 bits of X
	lsra			;
	rorx			;
	lsra			;
	rorx			;
        stx     ADC2            ;save value

        ADC_DISABLE

;--- read adc chan 3

        ADC_ENABLE

	lda	SPSR		;clears SPIF (prepare to send)
        lda     #$F0            ;adc header for chan 3
	sta	SPDR		;transmit via SPI
        SPI_RDY                 ;

        lda     SPDR            ;fetch data

        ldx     SPSR            ;clears SPIF (prepare to send)
	stx	SPDR		;transmit "don't care" out SPI
        SPI_RDY                 ;

        ldx     SPDR            ;receive SPI byte

        lsra                    ;shift LS 3 bits of A into
        rorx                    ; MS 5 bits of X
	lsra			;
	rorx			;
	lsra			;
	rorx			;

	stx	ADC3		;save value

        ADC_DISABLE

;--- that's all folks

        rts
