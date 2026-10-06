;----------------------------------------------------------------;
; SW.ASM - Switch Routines                                       ;
;								 ;
; Written for 2500AD 6805 assembler & linker (Version 5.0)       ;
;                                                                ;
; Rev: 1.0 29-Aug-1993                                           ;
;----------------------------------------------------------------;
;								 ;
; These routines provide the interface to the Standard IO Board  ;
; switches.                                                      ;
;                                                                ;
; Switches are read directly from the Switch Bus.                ;
;                                                                ;
; Private Routines:                                              ;
;                                                                ;
;    SW_INIT - initializes switches                              ;
;                                                                ;
; Public Routines:                                               ;
;                                                                ;
;    SW_READ - reads switches and returns current status         ;
;                                                                ;
;----------------------------------------------------------------;

	.CODE
	.RELATIVE

;----------------------------------------------------------------
;       Private Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;       SW_INIT                 ;
;                               ;
;-------------------------------;
;                               ;
; Initializes switches.         ;
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

SW_INIT:

        rts

;----------------------------------------------------------------
;       Public Routines
;----------------------------------------------------------------

;-------------------------------;
;                               ;
;	SW_READ                 ;
;                               ;
;-------------------------------;
;                               ;
; Reads switches and returns    ;
; current status.               ;
;                               ;
;-------------------------------;
;                               ;
; Arguments:                    ;
;   Returns: A: switches image  ;
; Registers:                    ;
; Varaibles:                    ;
;     Calls:                    ;
;    Macros: RD_SWROWS          ;
;                               ;
;-------------------------------;

SW_READ:
        RD_SWROWS               ;read switches
	rts
