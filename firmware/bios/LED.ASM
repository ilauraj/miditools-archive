;----------------------------------------------------------------;
; LED.ASM - LED Routines                                         ;
;								 ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;								 ;
; LEDs are driven from two cascaded 74HC595 shift registers.     ;
;								 ;
; Data is transferred via SPI, register latch enables are driven ;
; by port A5.                                                    ;
;								 ;
; Private Routines:                                              ;
;                                                                ;
;    LED_STB     - strobes LED driver chips                      ;
;    LED_REFRESH - writes current LED image to driver            ;
;    LED_INIT    - initializes LED display                       ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    LED_CLEAR - clears LEDs                                     ;
;    LED_ON    - turns on specified LED                          ;
;    LED_OFF   - turns off specified LED                         ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    LEDIMG0   - LED image byte 0                                ;
;    LEDIMG1   - LED image byte 1                                ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;       Hardware Access Macros
;----------------------------------------------------------------

LED_STB: .MACRO                 ;strobes LCD driver chips

        bclr    5,PORTA
        bset    5,PORTA
        bclr    5,PORTA

        .ENDM

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

LEDIMG0		.DS	1	;LED image byte 0
LEDIMG1		.DS	1	;LED image byte 1

	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	LED_REFRESH             ;
;                               ;
;-------------------------------;
;                               ;
; Writes current LED image to   ;
; driver chips.                 ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LEDIMG0            ;
;            LEDIMG1            ;
;     Calls:                    ;
;    Macros: LED_STB            ;
;                               ;
;-------------------------------;

LED_REFRESH:

        lda     LEDIMG0         ;transmit low byte of LED image
        jsr     SPI_IO          ;

        lda     LEDIMG1         ;transmit high byte of LED image
        jsr     SPI_IO          ;

        LED_STB                 ;strobe data into LED latches

        rts

;-------------------------------;
;                               ;
;       LED_INIT                ;
;                               ;
;-------------------------------;
;                               ;
; Initializes LEDs.             ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: LEDIMG0            ;
;            LEDIMG1            ;
;     Calls: LED_REFRESH        ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LED_INIT:

	clr	LEDIMG0
	clr	LEDIMG1
	jsr	LED_REFRESH

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       LED_CLEAR               ;
;                               ;
;-------------------------------;
;                               ;
; Clears LEDs.                  ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers:                    ;
; Variables: LEDIMG0            ;
;            LEDIMG1            ;
;     Calls: LED_REFRESH        ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LED_CLEAR:

        clr     LEDIMG0
	clr	LEDIMG1
	jsr	LED_REFRESH

        rts

;-------------------------------;
;                               ;
;	LED_ON                  ;
;                               ;
;-------------------------------;
;                               ;
; Turns on specified LED.       ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: LED # (0-15)    ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LEDIMG0            ;
;            LEDIMG1            ;
;     Calls: LED_REFRESH        ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LED_ON:
        cmp     #7              ;LED in LEDIMG1?
        bhi     LO4             ;yup
	tax			;lookup mask
	lda	LO_TBL,X	;
        ora     LEDIMG0         ;turn LED on
        sta     LEDIMG0         ;
	jsr	LED_REFRESH	;refresh LEDs
        rts                     ;all done

LO4:	sub	#8		;offset LED code
        cmp     #7              ;
        bhi     LO5             ;
	tax			;lookup mask
        lda     LO_TBL,X        ;
        ora     LEDIMG1         ;turn LED on
        sta     LEDIMG1         ;
	jsr	LED_REFRESH	;refresh LEDs
LO5:	rts			;arg was out of range

LO_TBL:	.DB	$01,$02,$04,$08,$10,$20,$40,$80

;-------------------------------;
;                               ;
;       LED_OFF                 ;
;                               ;
;-------------------------------;
;                               ;
; Turns off specified LED.      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: LED # (0-15)    ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LEDIMG0            ;
;            LEDIMG1            ;
;     Calls: LED_REFRESH        ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LED_OFF:
        cmp     #7              ;LED in LEDIMG1?
        bhi     LF4             ;yup
	tax			;lookup mask
        lda     LF_TBL,X        ;
        and     LEDIMG0         ;turn LED off
        sta     LEDIMG0         ;
	jsr	LED_REFRESH	;refresh LEDs
	rts			;all done

LF4:	sub	#8		;offset LED code
        cmp     #7              ;
        bhi     LF5             ;
	tax			;lookup mask
        lda     LF_TBL,X        ;
        and     LEDIMG1         ;turn LED off
        sta     LEDIMG1         ;
	jsr	LED_REFRESH	;refresh LEDs
LF5:    rts                     ;arg was out of range

LF_TBL: .DB     $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F
