;----------------------------------------------------------------;
; EEPROM.ASM - EEPROM Routines                                   ;
;								 ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;								 ;
; These routines provide the interface to the XICOR X25C02       ;
; EEPROM.                                                        ;
;                                                                ;
; Details on the interface to this EEPROM are available in the   ;
; XICOR data book.                                               ;
;                                                                ;
; Data is transferred via SPI, with chip enable driven by        ;
; port A6.                                                       ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    EE_ENABLE  - enable EEPROM chip select                      ;
;    EE_DISABLE - disable EEPROM chip select                     ;
;    EE_WREN    - set Write Enable Latch                         ;
;    EE_WRDI    - reset Write Enable Latch                       ;
;    EE_INIT    - initializes EEPROM                             ;
;                                                                ;
; Public Routines                                                ;
;                                                                ;
;    EE_READ    - read byte from EEPROM                          ;
;    EE_WRITE   - write byte to EEPROM                           ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    EETEMP - M_TEMPOrary variable				 ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;       Hardware Access Macros
;----------------------------------------------------------------

EE_ENABLE: .MACRO
        bclr    6,PORTA         ;enable EEPROM chip select
        .ENDM

EE_DISABLE: .MACRO
        bset    6,PORTA         ;disable EEPROM chip select
        .ENDM

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

        .PAGE0
	.ABSOLUTE

EETEMP          .DS     1       ;EEPROM temp variable


	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
; EE_WREN                       ;
;                               ;
;-------------------------------;
;                               ;
; Sets the Write Enable Latch.  ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls:                    ;
;    Macros: EE_ENABLE          ;
;            EE_DISABLE         ;
;            SPI_RDY            ;
;                               ;
;-------------------------------;

EE_WREN:
        EE_ENABLE               ;enable EEPROM

        lda     SPSR            ;clears SPIF (prepare to send)
        lda     #$06            ;send instruction
        sta     SPDR            ;
        SPI_RDY                 ;

        EE_DISABLE              ;disable EEPROM
        rts

;-------------------------------;
;                               ;
; EE_WRDI                       ;
;                               ;
;-------------------------------;
;                               ;
; Resets the Write Enable Latch.;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls:                    ;
;    Macros: EE_ENABLE          ;
;            EE_DISABLE         ;
;            SPI_RDY            ;
;                               ;
;-------------------------------;

EE_WRDI:
        EE_ENABLE               ;enable EEPROM

        lda     SPSR            ;clears SPIF (prepare to send)
        lda     #$04            ;send instruction
        sta     SPDR            ;
        SPI_RDY                 ;

        EE_DISABLE              ;disable EEPROM
        rts

;-------------------------------;
;                               ;
; EE_INIT                       ;
;                               ;
;-------------------------------;
;                               ;
; Initialize EEPROM.            ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables:                    ;
;     Calls:                    ;
;    Macros: EE_DISABLE         ;
;                               ;
;-------------------------------;

EE_INIT:
        EE_DISABLE              ;default chip select
        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
; EE_READ                       ;
;                               ;
;-------------------------------;
;                               ;
; Reads a byte from EEPROM      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: address         ;
;   Returns: A: data            ;
; Registers: A,X                ;
; Variables:                    ;
;     Calls:                    ;
;    Macros: EE_ENABLE          ;
;            EE_DISABLE         ;
;            SPI_RDY            ;
;                               ;
;-------------------------------;

EE_READ:
        EE_ENABLE               ;enable EEPROM

        ldx     SPSR            ;clears SPIF (prepare to send)
        ldx     #$03            ;send read instruction
        stx     SPDR            ;
        SPI_RDY                 ;

        ldx     SPSR            ;clears SPIF (prepare to send)
        sta     SPDR            ;send address
        SPI_RDY                 ;

        lda     SPSR            ;clears SPIF (prepare to send)
        sta     SPDR            ;"don't care" triggers response
        SPI_RDY                 ;
        lda     SPDR            ;fetch data from MISO

        EE_DISABLE              ;disable EEPROM

        rts

;-------------------------------;
;                               ;
; EE_WRITE                      ;
;                               ;
;-------------------------------;
;                               ;
; Writes a byte to EEPROM       ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: address         ;
;            X: data            ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: EETEMP             ;
;     Calls: EE_WREN            ;
;            DELAY_10MS         ;
;    Macros: EE_ENABLE          ;
;            EE_DISABLE         ;
;            SPI_RDY            ;
;                               ;
;-------------------------------;

EE_WRITE:
        sta     EETEMP          ;don't loose the address!

        jsr     EE_WREN         ;enable EEPROM writes

        EE_ENABLE               ;enable EEPROM

        lda     SPSR            ;clears SPIF (prepare to send)
        lda     #$02            ;send write instruction
        sta     SPDR            ;
        SPI_RDY                 ;

        lda     SPSR            ;clears SPIF (prepare to send)
        lda     EETEMP          ;retrieve address
        sta     SPDR            ;send address
        SPI_RDY                 ;

        lda     SPSR            ;clears SPIF (prepare to send)
        stx     SPDR            ;send data
        SPI_RDY                 ;

        EE_DISABLE              ;disable EEPROM

        jsr     DELAY_10MS      ;delay for EEPROM write cycle

        rts


