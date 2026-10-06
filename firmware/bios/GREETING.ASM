;---------------------------------------------------------------;
; GREETING.ASM - Greet the User 				;
;                                                               ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)      ;
;                                                               ;
; Rev: 1.0 29-Aug-1993                                          ;
;---------------------------------------------------------------;
;								;
;	This subroutine provides a common LCD greeting for	;
;	all projects.  The LCD is cleared before returning.	;
;								;
;---------------------------------------------------------------;

;----------------------------------------------------------------
;	Code
;----------------------------------------------------------------

	.CODE
	.RELATIVE

GREETING:
	jsr	LCD_CLEAR

	LCD_PUT_S " ___            "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|           "
	jsr	DELAY_100MS
	jsr	DELAY_100MS
	jsr	DELAY_100MS
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/            "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/l           "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|>          "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/ol          "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|->         "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/ool         "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-->        "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/tool        "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|--->       "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/Itool       "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|---->      "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/DItool      "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|----->     "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/IDItool     "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|------>    "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/MIDItool    "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|------->   "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " __/ MIDItool   "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-------->  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " ___ MIDItool   "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=>   "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=->   "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->s "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=->s"
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " ___ MIDItool  s"

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=-=> "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " ___ MIDItool s "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#0
	jsr	LCD_GOTOXY

	LCD_PUT_S " ___ MIDItools  "

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|-=-=-=-=>  "
	jsr	DELAY_100MS

	lda	#0
	ldx	#1
	jsr	LCD_GOTOXY

	LCD_PUT_S "|___|=-=-=-=->  "
	jsr	DELAY_100MS
	jsr	DELAY_100MS
	jsr	DELAY_100MS

	jsr	LCD_CLEAR
	rts
