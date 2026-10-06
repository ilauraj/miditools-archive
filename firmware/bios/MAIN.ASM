;----------------------------------------------------------------;
; MAIN.ASM - Main Source Code File                               ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 31-Mar-1993						 ;
;----------------------------------------------------------------;
;                                                                ;
; This file builds the source code from the BIOS files and one   ;
; Application file.                                              ;
;                                                                ;
;----------------------------------------------------------------;

;--- Bios Files

        .INCLUDE 6805C8.ASM     ;MC68HC705C8 routines
	  ;.INCLUDE DAC6805.ASM     ;MC68HC705C8 routines

	  .INCLUDE SPI.ASM	  ;SPI routines

	  .INCLUDE MIDI.ASM	  ;MIDI routines
 	  ;.INCLUDE RS232.ASM

	  .INCLUDE TIMER.ASM	  ;Timer routines
	  .INCLUDE EEPROM.ASM	  ;EEPROM routines
        .INCLUDE LCD.ASM        ;LCD routines
        .INCLUDE SW.ASM         ;Switch routines
        .INCLUDE LED.ASM        ;LED routines
        .INCLUDE ADC.ASM        ;ADC routines
        .INCLUDE STMACH.ASM     ;State Machine routines
        .INCLUDE GREETING.ASM   ;Standard LCD greeting

	    
;--- Application Files

        .INCLUDE trum7a.ASM     ;Application

;----------------------------------------------------------------
;	Interrupt Service Routines Vectors
;----------------------------------------------------------------

;Note: Interrupt vectors must appear last in S19 file or the
;      Motorola EVM will choke.  This is a Motorola EVM bug
;      which will hopefully be fixed some day.

	.CODE
	.ABSOLUTE

	.ORG	VSPI
        .DW     SPI_ISR         ;SPI

	.ORG	VSCI
        .DW     SCI_ISR         ;SCI

	.ORG	VTIMER
        .DW     TIMER_ISR       ;Timer

	.ORG	VIRQ
        .DW     IRQ_ISR         ;IRQ

	.ORG	VSWI
        .DW     SWI_ISR         ;SWI

	.ORG	VRESET
        .DW     RESET_ISR       ;Reset

	.END
