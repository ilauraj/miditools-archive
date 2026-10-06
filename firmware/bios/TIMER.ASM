;----------------------------------------------------------------;
; TIMER.ASM - Timer Routines                                     ;
;								 ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;								 ;
; These routines provide the interface to the 6805's timer, and  ;
; and software delay loops.                                      ;
;                                                                ;
; Interrupt Service Routine:                                     ;
;                                                                ;
;    TIMER_ISR - timer interrupt service routine                 ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    TIMER_INIT -  initializes timer                             ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    DELAY_1MS   - waits 1 ms                                    ;
;    DELAY_10MS  - waits 10 ms                                   ;
;    DELAY_100MS - waits 100 ms                                  ;
;    DELAY_1SEC  - waits 1 second                                ;
;                                                                ;
;----------------------------------------------------------------;

	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Interrupt Service Routine
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       TIMER_ISR               ;
;                               ;
;-------------------------------;
;                               ;
; Timer interrupt service       ;
; routine.                      ;
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

TIMER_ISR:                      ;timer interrupt vectors here

        jmp     TIMER_CBCK      ;call application code
TIMER_CBCK_RET:                 ;

	rti

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	TIMER_INIT              ;
;                               ;
;-------------------------------;
;                               ;
; Initializes timer.            ;
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

TIMER_INIT:
	lda	#$00		;ICIE off, OCIE off, TOIE off,
	sta	TCR		;IEDG off, OLVL off
        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	DELAY_1MS               ;
;                               ;
;-------------------------------;
;                               ;
; Waits 1 ms and then returns.  ;
;                               ;
; Note: This routine does not   ;
;       use the timer.          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: X                  ;
; Variables:                    ;
;     Calls:                    ;
;    Macros:                    ;
;                               ;
;-------------------------------;

DELAY_1MS:

        ldx     #200            ;2~  200 iterations of 5us loop
D1MSLP: decx                    ;3~<---
	nop			;2~   ^
	nop			;2~   |5us
	bne	D1MSLP		;3~----

        rts

;-------------------------------;
;                               ;
;       DELAY_10MS              ;
;                               ;
;-------------------------------;
;                               ;
; Waits 10 ms and then returns. ;
;                               ;
; Note: This routine does not   ;
;       use the timer.          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls: DELAY_1MS          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

DELAY_10MS:

        lda     #10             ;10 * 1ms = 10ms
D10MSLP:
        jsr     DELAY_1MS       ;1ms delay loop
	deca			;
        bne     D10MSLP         ;

        rts

;-------------------------------;
;                               ;
;	DELAY_100MS             ;
;                               ;
;-------------------------------;
;                               ;
; Waits 100 ms and then returns.;
;                               ;
; Note: This routine does not   ;
;       use the timer.          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls: DELAY_1MS          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

DELAY_100MS:

       	lda	#100		;100 * 1ms = 100ms
D100MSLP:
        jsr     DELAY_1MS       ;1ms delay loop
	deca			;
	bne	D100MSLP	;

        rts

;-------------------------------;
;                               ;
;	DELAY_1SEC              ;
;                               ;
;-------------------------------;
;                               ;
; Waits 1 second and returns.   ;
;                               ;
; Note: This routine does not   ;
;       use the timer.          ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns:                    ;
; Registers: A                  ;
; Variables:                    ;
;     Calls: DELAY_1MS          ;
;    Macros:                    ;
;                               ;
;-------------------------------;

DELAY_1SEC:

       	lda	#200		;200 * 1ms = 200ms
D1SLP1:	jsr	DELAY_1MS	;
	deca			;
	bne	D1SLP1		;

       	lda	#200		;400ms
D1SLP2:	jsr	DELAY_1MS	;
	deca			;
	bne	D1SLP2		;

       	lda	#200		;600ms
D1SLP3:	jsr	DELAY_1MS	;
	deca			;
	bne	D1SLP3		;

       	lda	#200		;800ms
D1SLP4:	jsr	DELAY_1MS	;
	deca			;
	bne	D1SLP4		;

       	lda	#200		;1000ms
D1SLP5:	jsr	DELAY_1MS	;
	deca			;
	bne	D1SLP5		;
        rts
