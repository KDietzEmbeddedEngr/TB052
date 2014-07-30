;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	lcdcoms.asm
;Date:		April 12, 2001
;Version:	1.1
;Engineer:	Ken Dietz
;
;*****************************************************************
;
;Modifications:
;Version 1.1 developed for new project.  Accommodates T-SENSE.PJT now.
;
;*****************************************************************
;
;Purpose:
;Controls communications between the PICmicro and LCD.
;
;*****************************************************************

		list      p=16f872            ; list directive to define processor
		#include <p16f872.inc>        ; processor specific variable definitions
		#include <constant.h>

		errorlevel	-302

		EXTERN	TEMP, CHAR

LCDCOMS		CODE

;*****************************************************************
;  TITLE   "8 Bit LCD Driver"
;  These routines implement an 8 bit interface to a Hitachi
;  LCD module, busy flag used when valid.  The data lines
;  are on port_d, E is on port_a bit3,
;  R/W is on port_a bit 2, RS is on port_a bit 1.
;*****************************************************************
;*  This routine is a software delay.                            *
;*  At 4Mhz clock, the loop takes 3uS, so initialize TEMP with   *
;*  a value of 3 to give 9uS, plus the move etc should result in *
;*  a total time of > 10uS.                                      *
;*****************************************************************

SetupDelay
		nop
		decfsz  TEMP, F
		goto    SetupDelay
		return

;*****************************************************************
;*  SendChar - Sends character contained in register W to LCD    *
;*****************************************************************

SendChar
		GLOBAL	SendChar
		movwf   CHAR            ;Character to be sent is in W
		call    BusyCheck       ;Wait for LCD to be ready
		movf    CHAR,w          
		movwf   PORTB             ;Send data to LCD
		bcf     CNTRL,RW        ;Set LCD in read mode
		bsf     CNTRL,RS        ;Set LCD in data mode
		NOP
		bsf     CNTRL,E         ;toggle E for LCD
		NOP
		bcf     CNTRL,E
		NOP
		return

;**************************************************************
;*  SendCmd - Sends command contained in register W to LCD    *
;**************************************************************

SendCmd
		GLOBAL	SendCmd
		movwf   CHAR            ;Command to be sent is in W
		call    BusyCheck       ;Wait for LCD to be ready
		movf    CHAR,w          
		movwf   PORTB             ;Send data to LCD
		bcf     CNTRL,RW        ;Set LCD in read mode
		bcf     CNTRL,RS        ;Set LCD in command mode
		NOP
		bsf     CNTRL,E         ;toggle E for LCD
		NOP
		bcf     CNTRL,E
		return

;**************************************************************
;* This routine checks the busy flag, returns when not busy   *
;*  Affects:                                                  *
;*      TEMP - Returned with busy/address                     *
;**************************************************************

BusyCheck
		clrf	PORTB		;Set PORTB for input
		banksel	TRISB
		movlw   0x0FF		; "
		movwf   TRISB		; "
		banksel	CNTRL
		bcf     CNTRL,RS        ;Set LCD for command mode
		bsf     CNTRL,RW        ;Setup to read busy flag
		nop
		bsf     CNTRL,E         ;Set E high
		nop
		nop
		movf    PORTB,W           ;Read busy flag, DDram address
		bcf     CNTRL,E         ;Set E low       
		movwf	TEMP
		btfsc   TEMP,7          ;Check busy flag, high=busy
		goto    BusyCheck

		bcf     CNTRL,RW        
		banksel	TRISB
		movlw   0x00		; "
		movwf   TRISB           ; "
		banksel	PORTB
		return

;**************************************************************
;* This routine initializes the LCD module                    *
;*  Affects:                                                  *
;*      TEMP - Returned with busy/address                     *
;**************************************************************

LCDInit
		GLOBAL	LCDInit
		bcf	STATUS,RP0	;---Bank 0
		clrf	PORTA
		clrf	PORTB
		bsf     STATUS,RP0      ;---Bank 1
		movlw   B'00000000'     ;Set PortB as outputs
		movwf   TRISB
		movlw   B'00000000'     ;Set PortA as outputs
		movwf   TRISA
		bcf     STATUS,RP0      ;---Bank 0
		clrf   	PORTA           ;Clear PortA

		movlw   B'00111000'     ;Set LCD to 8 bit interface
		movwf   PORTB
		nop
		bsf     CNTRL,E         ;toggle E for LCD
		nop
		bcf     CNTRL,E

		movlw   0x0             ;Setup call to SetupDelay
		movwf   TEMP
		call    SetupDelay      ;Each call to delay is 
		call    SetupDelay      ;0.771ms, six makes 4.6ms
		call    SetupDelay      ;This wait is necessary because
		call    SetupDelay      ;the busy flag is not valid yet.
		call    SetupDelay      ;
		call    SetupDelay      ;

		movlw   B'00111000'     ;Function set to 2 lines
		movwf   PORTB		;of 5x7 bit chars
		nop
		bsf     CNTRL,E         ;toggle E for LCD
		nop
		bcf     CNTRL,E
		call	SetupDelay

;Busy flag should be valid after this point
		movlw   B'00001110'     ;Display on, cursor on
		call    SendCmd

		movlw   B'00000001'     ;Clear display
		call    SendCmd

		movlw   B'00000110'     ;Set entry mode inc, no shift
		call    SendCmd

		movlw   B'10000000'     ;Address DDRam upper left
		call    SendCmd

		return
		END

