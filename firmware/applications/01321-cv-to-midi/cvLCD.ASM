;----------------------------------------------------------------;
; LCD.ASM - LCD Routines                                         ;
;                                                                ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;                                                                ;
; These routines support 16x2 LCD modules implementing the       ;
; Hitachi HD44780 (or equivalent) controller.  This covers       ;
; most available character LCD modules.                          ;
;                                                                ;
; Details on the interface to this controller are available in   ;
; any LCD module data sheet, or in the Hitachi data book.        ;
;                                                                ;
; LCD is driven from the general purpose parallel bus.           ;
; RS, RW, and E are driven by ports A2, A1, and A0 respectively. ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    LCD_RS_IR  - selects LCD IR register for data transfer      ;
;    LCD_RS_DR  - selects LCD DR register for data transfer      ;
;    LCD_RW_RD  - executes LCD read                              ;
;    LCD_RW_WR  - executes LCD write                             ;
;    LCD_E_0    - reset LCD E signal                             ;
;    LCD_E_1    - set LCD E signal  e                            ;
;    LCD_IR_RD  - reads from LCD IR                              ;
;    LCD_IR_WR  - writes to LCD IR                               ;
;    LCD_DR_RD  - reads from LCD DR                              ;
;    LCD_DR_WR  - writes to LCD DR                               ;
;    LCD_W8_BSY - waits for LCD busy flag to clear               ;
;    LCD_INIT   - initializes LCD                                ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    LCD_CLEAR     - clears LCD                                  ;
;    LCD_CURSOR    - turns cursor on or off                      ;
;    LCD_GOTOXY    - positions cursor at X,Y                     ;
;    LCD_PUT_C     - writes a character to LCD                   ;
;    LCD_PUT_S     - writes a string to LCD                      ;
;    LCD_PUT_I     - writes an integer (0-255) to LCD            ;
;    LCD_PUT_H     - writes a hex value (00 - FF) to LCD         ;
;    LCD_PUT_RJ2_I - writes 2-digit right justified int to LCD   ;
;    LCD_PUT_RJ3_SI- writes 3-digit right justified signed int   ;
;    LCD_PUT_RJ3_I - writes 3-digit right justified int to LCD   ;
;    LCD_PUT_ARROW - writes an arrow at X,Y                      ;
;                                                                ;
; The following variables are allocated in PAGE0 RAM:            ;
;                                                                ;
;    LCDIR      - LCD INSTR register                             ;
;    LCDDR      - LCD DATA register                              ;
;                                                                ;
;----------------------------------------------------------------;

;----------------------------------------------------------------
;       Hardware Access Macros
;----------------------------------------------------------------

LCD_RS_IR: .MACRO           ;selects IR register for data transfer
        bclr    2,PORTA
	.ENDM

LCD_RS_DR: .MACRO           ;selects DR register for data transfer
        bset    2,PORTA
	.ENDM

LCD_RW_RD: .MACRO           ;executes LCD read
        bset    1,PORTA
        .ENDM

LCD_RW_WR: .MACRO           ;executes LCD write
	bclr	1,PORTA
	.ENDM

LCD_E_0: .MACRO             ;resets LCD E signal
	bclr	0,PORTA
	.ENDM

LCD_E_1: .MACRO             ;sets LCD E signal
	bset	0,PORTA
	.ENDM

;----------------------------------------------------------------
;	Variables
;----------------------------------------------------------------

	.PAGE0
	.ABSOLUTE

LCDIR		.DS	1	;LCD INSTR register
LCDDR		.DS	1	;LCD DATA register

        .CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	LCD_IR_RD               ;
;                               ;
;-------------------------------;
;                               ;
; Reads LCD INSTR register.     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: LCDIR refreshed    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls:                    ;
;    Macros: LCD_RS_IR          ;
;            LCD_RW_RD          ;
;            LCD_E_0            ;
;            LCD_E_1            ;
;            RD_DATA            ;
;                               ;
;-------------------------------;

LCD_IR_RD:

        LCD_E_0                 ;ensure proper E state
        LCD_RS_IR               ;select IR register
        LCD_RW_RD               ;select read

	RD_DATA			;set up data port for inputs
        LCD_E_1                 ;force LCDE 0->1

        RD_DATA                 ;read data port
	sta	LCDIR		;save in LCD IR register

        LCD_E_0                 ;force LCDE 1->0
	rts

;-------------------------------;
;                               ;
;	LCD_IR_WR               ;
;                               ;
;-------------------------------;
;                               ;
; Writes LCD INSTR register.    ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: LCDIR              ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls: LCD_W8_BSY         ;
;    Macros: LCD_RS_IR          ;
;            LCD_RW_WR          ;
;            LCD_E_0            ;
;            LCD_E_1            ;
;            WR_DATA            ;
;                               ;
;-------------------------------;

LCD_IR_WR:

	jsr	LCD_W8_BSY	;come back when LCD is ready

        LCD_E_0                 ;ensure proper E state
        LCD_RS_IR               ;select IR register
        LCD_RW_WR               ;select write

	lda	LCDIR		;write data to peripheral
        WR_DATA                 ;write ACCU to data port

        LCD_E_1                 ;cycle LCDE 0->1->0
	LCD_E_0			;

        rts

;-------------------------------;
;                               ;
;	LCD_DR_RD               ;
;                               ;
;-------------------------------;
;                               ;
; Reads LCD DATA register.      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: LCDDR refreshed    ;
; Registers: A                  ;
; Variables: LCDDR              ;
;     Calls: LCD_W8_BSY         ;
;    Macros: LCD_RS_DR          ;
;            LCD_RW_RD          ;
;            LCD_E_0            ;
;            LCD_E_1            ;
;            RD_DATA            ;
;                               ;
;-------------------------------;

LCD_DR_RD:

	jsr	LCD_W8_BSY	;come back when LCD is ready

        LCD_E_0                 ;ensure proper E state
        LCD_RS_DR               ;select DR register
        LCD_RW_RD               ;select read

	RD_DATA			;set up data port for inputs
        LCD_E_1                 ;force LCDE 0->1

        RD_DATA                 ;read data port
	sta	LCDDR		;save in LCD DR register

        LCD_E_0                 ;force LCDE 1->0

        rts

;-------------------------------;
;                               ;
;	LCD_DR_WR               ;
;                               ;
;-------------------------------;
;                               ;
; Writes LCD DATA register.     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: LCDDR              ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDDR              ;
;     Calls: LCD_W8_BSY         ;
;    Macros: LCD_RS_DR          ;
;            LCD_RW_WR          ;
;            LCD_E_0            ;
;            LCD_E_1            ;
;            WR_DATA            ;
;                               ;
;-------------------------------;

LCD_DR_WR:

        jsr     LCD_W8_BSY      ;come back when LCD is ready

        LCD_E_0                 ;ensure proper E state
        LCD_RS_DR               ;select DR register
        LCD_RW_WR               ;select write

	lda	LCDDR		;write data to peripheral
        WR_DATA                 ;write ACCU to data port

        LCD_E_1                 ;cycle LCDE 0->1->0
	LCD_E_0			;

        rts

;-------------------------------;
;                               ;
;	LCD_W8_BSY              ;
;                               ;
;-------------------------------;
;                               ;
; Reads LCD INSTR register and  ;
; loops until busy flag clears. ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls:                    ;
;    Macros: LCD_RS_IR          ;
;            LCD_RW_RD          ;
;            LCD_E_0            ;
;            LCD_E_1            ;
;            RD_DATA            ;
;                               ;
;-------------------------------;

LCD_W8_BSY:

        LCD_E_0                 ;ensure proper E state
        LCD_RS_IR               ;select IR register
        LCD_RW_RD               ;select read

BSYLP:	RD_DATA			;set up data port for inputs
        LCD_E_1                 ;force LCDE 0->1
        RD_DATA                 ;reads data port
        LCD_E_0                 ;force LCDE 1->0
	and	#$80		;mask busy flag
	bne	BSYLP		;loop if busy flag is set

        rts

;-------------------------------;
;                               ;
;	LCD_INIT                ;
;                               ;
;-------------------------------;
;                               ;
; Initializes LCD:              ;
;                               ;
;    - 8 bit I/F                ;
;    - 2 lines                  ;
;    - 5x7 font                 ;
;    - display on               ;
;    - cursor off               ;
;    - cursor shifts right      ;
;    - cursor homed             ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_INIT:

	lda	#$38		;function set: 8 bit, 2 lines,
	sta	LCDIR		;5x7 font
	jsr	LCD_IR_WR	;write instruction

        lda     #$0C            ;display on, cursor off,
	sta	LCDIR		;blink off
	jsr	LCD_IR_WR	;write instruction

	lda	#$01		;clear LCD
	sta	LCDIR		;
	jsr	LCD_IR_WR	;write instruction

	lda	#$06		;cursor shifts right after
	sta	LCDIR		;each data write
	jsr	LCD_IR_WR	;write instruction

	lda	#$C0		;home cursor
	sta	LCDIR		;
	jsr	LCD_IR_WR	;write instruction

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	LCD_CLEAR               ;
;                               ;
;-------------------------------;
;                               ;
; Clears LCD.                   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_CLEAR:

	lda	#$01		;form CLEAR DISPLAY command
	sta	LCDIR		;
	jsr	LCD_IR_WR	;write instruction

        rts

;-------------------------------;
;                               ;
;	LCD_CURSOR              ;
;                               ;
;-------------------------------;
;                               ;
; Turns LCD cursor on/off.      ;
; Cursor does not blink.        ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: 0/1 = off/on    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_CURSOR:

	tsta			;test ACCU
        beq     CURSOFF         ;branch if $00 (off)

	lda	#$0E		;form command (cursor on)
	jmp	WRCURS		;go write this command

CURSOFF:
	lda	#$0C		;form command (cursor off)

WRCURS:	sta	LCDIR		;
	jsr	LCD_IR_WR	;write instruction

        rts

;-------------------------------;
;                               ;
;	LCD_GOTOXY              ;
;                               ;
;-------------------------------;
;                               ;
; Positions LCD cursor at X,Y   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: Xpos (0-15)     ;
;            X: Ypos (0-1)      ;
;   Returns:                    ;
; Registers: A                  ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_GOTOXY:

	cpx	#1		;if x = 1, add $40 to cursor addr
	bne	NOTLINE1	;
	add	#$40		;

NOTLINE1:
	add	#$80		;form set DD RAM address command
	sta	LCDIR		;
	jsr	LCD_IR_WR	;write instruction

        rts

;-------------------------------;
;                               ;
;	LCD_PUT_C               ;
;                               ;
;-------------------------------;
;                               ;
; Writes character to LCD.      ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: character       ;
;   Returns:                    ;
; Registers:                    ;
; Variables: LCDDR              ;
;     Calls: LCD_DR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_C:

        sta     LCDDR           ;write character to LCD
        jsr     LCD_DR_WR       ; DATA register

        rts

;-------------------------------;
;                               ;
;       LCD_PUT_S (MACRO)       ;
;                               ;
;-------------------------------;
;                               ;
; Writes string argument to LCD ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: ARG1: "string"     ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDIR              ;
;     Calls: LCD_DR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

;Note: STRLP?, STR?, and STRNULL? are local labels

LCD_PUT_S: .MACRO ARG1		;macro has one arg - the string

X|<*>	;places label "X###" where ### = program counter
	;this is necessary to define bounds of local labels

	ldx	#0		;initialize X

STRLP?:	lda	STR?,X		;fetch next char
	beq	STRNULL?	;if NULL ($00), exit loop
	sta	LCDDR		;write char to LCD
	jsr	LCD_DR_WR	;
	incx			;point to next character
	jmp	STRLP?		;complete loop

STR?:	.FCC	ARG1		;string is buffered here
	.DB	0		;NULL termination
STRNULL?:

X|<*>   ;see comment above
        ;

	NOP

	.ENDM

;-------------------------------;
;                               ;
;	LCD_PUT_I               ;
;                               ;
;-------------------------------;
;                               ;
; Writes unsigned integer to    ;
; LCD.                          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: integer (0-255) ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDDR              ;
;     Calls: LCD_DR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_I:

	cmp	#10		;no leading zeroes before
	blo	WRITE1		;single digit (<10) number

	ldx	#'0'		;assume digit is 0
LP100:	cmp	#100		;loop as long as number > 100
	blo	WR100		;
	sub	#100		;increment 100's digit
	incx			;
	jmp	LP100		;complete 100's digit loop

WR100:	cpx	#'0'		;don't write 0 to LCD
	beq	LP10		;

	stx	LCDDR		;write digit to LCD
	tax			;M_TEMPOrary storage of ACCU
	jsr	LCD_DR_WR	;
	txa			;retrieve stored ACCU

	ldx	#'0'		;assume digit is 0
LP10:	cmp	#10		;loop as long as number > 10
	blo	WR10		;
	sub	#10		;increment 10's digit
	incx			;
	jmp	LP10		;complete loop

WR10:	stx	LCDDR		;write digit to LCD
	tax			;M_TEMPOrary storage of ACCU
	jsr	LCD_DR_WR	;
	txa			;retrieve stored ACCU

WRITE1:
	add	#'0'		;add ASCII '0' offset
	sta	LCDDR		;write 1's digit to LCD
	jsr	LCD_DR_WR	;

        rts

;-------------------------------;
;                               ;
;	LCD_PUT_H               ;
;                               ;
;-------------------------------;
;                               ;
; Writes hex number to LCD.     ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: number ($00-$FF);
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDDR              ;
;     Calls: LCD_DR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_H:

	ldx	#'0'		;assume digit is 0

LP16:	cmp	#$10		;subtract $10 until less than $10
	blo	WR16		;the number of iterations = 16's
	sub	#$10		;digit
	incx			;
	jmp	LP16		;

WR16:	cpx	#'9'		;if digit > 9, offset to A-F
	bls	WRNUM16		;
	incx			;add 7 to offset to ASCII A-F
	incx			;
	incx			;
	incx			;
	incx			;
	incx			;
	incx			;

WRNUM16:
	stx	LCDDR		;write digit to LCD
	tax			;M_TEMPOrary storage of ACCU
	jsr	LCD_DR_WR	;
	txa			;retrieve stored ACCU

	cmp	#9		;if 1's digit > 9, offset to A-F
	bls	WR1		;
	add	#7		;add 7 to offset to ASCII A-F

WR1:	add	#'0'		;add ASCII offset
	sta	LCDDR		;write 1's digit to LCD
	jsr	LCD_DR_WR	;

        rts

;-------------------------------;
;                               ;
;	LCD_PUT_HH               ;
;                               ;
;-------------------------------;
;                               ;
; Writes single digit hex number;
; to LCD.     			  ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: number ($0-$F)  ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDDR              ;
;     Calls: LCD_DR_WR          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_HH:

	ldx	#'0'		;assume digit is 0

LL16:	cmp	#$10		;subtract $10 until less than $10
	blo	WL16		;the number of iterations = 16's
	sub	#$10		;digit
	incx			;
	jmp	LL16		;

WL16:	cpx	#'9'		;if digit > 9, offset to A-F
	bls	WLNUM16		;
	incx			;add 7 to offset to ASCII A-F
	incx			;
	incx			;
	incx			;
	incx			;
	incx			;
	incx			;

WLNUM16:
	;stx	LCDDR		;write digit to LCD
	;tax			;M_TEMPOrary storage of ACCU
	;jsr	LCD_DR_WR	;
	;txa			;retrieve stored ACCU

	cmp	#9		;if 1's digit > 9, offset to A-F
	bls	WL1		;
	add	#7		;add 7 to offset to ASCII A-F

WL1:	add	#'0'		;add ASCII offset
	sta	LCDDR		;write 1's digit to LCD
	jsr	LCD_DR_WR	;

        rts

;-------------------------------;
;                               ;
;	LCD_PUT_RJ2_I           ;
;                               ;
;-------------------------------;
;                               ;
; Writes right-hand-justified   ;
; 2-digit (0-99) int to LCD.    ;
;                               ;
; Current cursor position is    ;
; where 1's digit is aligned.   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: integer (0-99)  ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;            LCD_PUT_C          ;
;            LCD_PUT_I          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_RJ2_I:

	tax			;buffer argument in X
	lda	#$10		;shift cursor left
	sta	LCDIR		;
	jsr	LCD_IR_WR	;

	txa			;retrieve #
	cmp	#9		;if greater than 9 write #
	bhi	LPR2		;
	lda	#' '		;blank ten's digit
	jsr	LCD_PUT_C	;

LPR2:	txa			;restore argument
	jsr	LCD_PUT_I	;now write the number

        rts

;-------------------------------;
;                               ;
;       LCD_PUT_RJ3_SI          ;
;                               ;
;-------------------------------;
;                               ;
; Writes right-hand-justified   ;
; 3-digit signed int            ;
; (-128 to 127) to LCD.         ;
;                               ;
; Note that minus sign takes    ;
; up a fourth digit!            ;
;                               ;
; Current cursor position is    ;
; where 1's digit is aligned.   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: integer         ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;            LCD_PUT_C          ;
;            LCD_PUT_I          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_RJ3_SI:

	tax			;buffer argument in X

        lda     #$10            ;shift cursor left thrice
	sta	LCDIR		;
	jsr	LCD_IR_WR	;
        jsr     LCD_IR_WR       ;
        jsr     LCD_IR_WR       ;

        txa                     ;pos or neg?
        cmp     #$80            ;
        bhs     LPRS3NEG        ;branch if neg

        cmp     #0              ;no sign for 0
        beq     LPRS30          ;

        lda     #'+'            ;display plus sign
        jsr     LCD_PUT_C       ;

LPRS3NUM:
        txa                     ;retrieve #
	cmp	#99		;if greater than 99 write #
        bhi     LPRS3           ;
	lda	#' '		;blank 100's digit
	jsr	LCD_PUT_C	;

	txa			;retrieve #
	cmp	#9		;if greater than 9 write #
        bhi     LPRS3           ;
	lda	#' '		;blank ten's digit
	jsr	LCD_PUT_C	;

LPRS3:  txa                     ;restore argument
	jsr	LCD_PUT_I	;now write the number

        rts

LPRS3NEG:
        lda     #'-'            ;display minus sign
        jsr     LCD_PUT_C       ;

        txa                     ;negate number
        coma                    ;
        inca                    ;
        tax                     ;
        jmp     LPRS3NUM        ;go display number

LPRS30:
        lda     #' '            ;blank sign digit
        jsr     LCD_PUT_C       ;
        jmp     LPRS3NUM        ;go display number

;-------------------------------;
;                               ;
;	LCD_PUT_RJ3_I           ;
;                               ;
;-------------------------------;
;                               ;
; Writes right-hand-justified   ;
; 3-digit (0-255) int to LCD.   ;
;                               ;
; Current cursor position is    ;
; where 1's digit is aligned.   ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: integer (0-255) ;
;   Returns:                    ;
; Registers: A,X                ;
; Variables: LCDIR              ;
;     Calls: LCD_IR_WR          ;
;            LCD_PUT_C          ;
;            LCD_PUT_I          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_RJ3_I:

        tax                     ;buffer argument in X

	lda	#$10		;shift cursor left twice
	sta	LCDIR		;
	jsr	LCD_IR_WR	;
	jsr	LCD_IR_WR	;

	txa			;retrieve #
	cmp	#99		;if greater than 99 write #
	bhi	LPR3		;
	lda	#' '		;blank 100's digit
	jsr	LCD_PUT_C	;

	txa			;retrieve #
	cmp	#9		;if greater than 9 write #
	bhi	LPR3		;
	lda	#' '		;blank ten's digit
	jsr	LCD_PUT_C	;

LPR3:	txa			;restore argument
	jsr	LCD_PUT_I	;now write the number

        rts

;-------------------------------;
;                               ;
;	LCD_PUT_ARROW           ;
;                               ;
;-------------------------------;
;                               ;
; Writes arrow at X,Y.          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments: A: X position      ;
;            X: Y position      ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls: LCD_PUT_C          ;
;            LCD_GOTOXY         ;
;    Macros:                    ;
;                               ;
;-------------------------------;

LCD_PUT_ARROW:

	jsr	LCD_GOTOXY	;position cursor

        lda     #$7E            ;code for right arrow "->"
	jsr	LCD_PUT_C	;

        rts
