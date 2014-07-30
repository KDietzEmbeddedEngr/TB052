;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	glue.asm
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
;This file provides control signals and data manipulations that are not
;normally in lcdcoms.asm.  It interfaces between the main program and lcdcoms.asm.
;
;*****************************************************************
	list      p=16f872            ; list directive to define processor
	#include <p16f872.inc>        ; processor specific variable definitions
	#include <constant.h>

	errorlevel	-302

	EXTERN	SendCmd, SendChar, hex2ascii, NODE_COUNT
	EXTERN	DATAOUT, DATAIN, TEMP_DATA, DEC_NUM

LCD_VARS	UDATA
DELAY_COUNT	RES	1
GLUE_WTEMP	RES	1
COUNT_INSIDE	RES	1
COUNT_OUTSIDE	RES	1
COUNT0		RES	1
COUNT1		RES	1
COUNT2		RES	1

LCD_GLUE	CODE

;*****************************************************************
;
;The following routine displays splash message on the LCD
;
;*****************************************************************
HELLO
		GLOBAL	HELLO
		movlw	0x07
		movwf	COUNT1
		clrf	COUNT0
LOOP
		movlw	HIGH TABLE
		movwf	PCLATH
		movf	COUNT0, 0
		call	TABLE
		call	SendChar
		clrf	PCLATH
		incf	COUNT0, 1
		decfsz	COUNT1, 1
		goto	LOOP
		return

;*****************************************************************
;
;The following routine sends the first row of information to the LCD.
;
;Notes:
;None
;
;*****************************************************************
SEND_LCD_ROW1
		GLOBAL	SEND_LCD_ROW1

		movlw	0x01			;Direct LCD to Line 1
		call	SendCmd

		movlw	HIGH TABLE
		movwf	PCLATH
		movlw	0x07			;Sending "0" to LCD, row 1
		call	TABLE
		call	SendChar
		movlw	0x08			;Sending "x" to LCD, row 1
		call	TABLE
		call	SendChar
		movlw	0x07			;Sending "0" to LCD, row 1
		call	TABLE
		call	SendChar

		rrf	NODE_COUNT, 0		;shift address value and write to WREG
		call	hex2ascii		;convert WREG contents to ascii
		call	SendChar		;send WREG to the LCD

		movlw	0x09			;display " T75" on LCD
		movwf	COUNT2			;preload counter with table call value
LCD_ROW1_LOOP					;call table values 0x09 through 0x0C
		movlw	HIGH TABLE		;preload PCPLATH from TABLE
		movwf	PCLATH
		movf	COUNT2, 0		;place counter in WREG
		call	TABLE			;get ascii table value
		call	SendChar		;send data to LCD
		incf	COUNT2, 1		;increment counter
		movf	COUNT2, 0		;test counter for max value
		sublw	0x0C
		btfss	STATUS, Z		;if counter is at max, move on, if not, loop back
		goto	LCD_ROW1_LOOP

		movlw	0x05
		call	hex2ascii		;convert WREG contents to ascii
		call	SendChar		;send WREG to the LCD
END_SEND_LCD_ROW1
		return

;*****************************************************************
;
;The following routine sends the second row of information to the LCD.
;
;Notes:
;None
;
;*****************************************************************
SEND_LCD_ROW2
		GLOBAL	SEND_LCD_ROW2

		movlw	0xC0		;Direct LCD to Line 2
		call	SendCmd

SIGN_75		btfsc	TEMP_DATA + MSBTemp, 7
		goto	SEND_MINUS

SEND_PLUS	movlw	HIGH TABLE
		movwf	PCLATH
		movlw	0x0D
		call	TABLE
		call	SendChar
		goto	HEX_TO_DEC

SEND_MINUS	movlw	HIGH TABLE
		movwf	PCLATH
		movlw	0x0E
		call	TABLE
		call	SendChar
		comf	TEMP_DATA + MSBTemp, 0
		addlw	0x01
		movwf	TEMP_DATA + MSBTemp	;2's compliment now in memory

HEX_TO_DEC	movlw	0x64
		subwf	TEMP_DATA + MSBTemp, 0	;subtract 100's place
		btfsc	STATUS, C
		goto	SUB100
		clrf	DEC_NUM + OutByte0	;value below 100
		goto	SUB_TENS

SUB100		movwf	TEMP_DATA + MSBTemp
		movlw	0x01			;value 100 or above
		movwf	DEC_NUM + OutByte0
		bcf	STATUS, C

SUB_TENS	movlw	0x0A			;this routine determines how many tens are in the tens place
		movwf	GLUE_WTEMP		;preload GLUE_WTEMP with 10 since WREG gets corrupted
		clrf	COUNT2			;clear counter, this counter counts the number of tens
LCD_ROW2_LOOP1	movf	GLUE_WTEMP, 0		;transfer 10 to WREG
		subwf	TEMP_DATA + MSBTemp, 1	;subtract 10
		btfss	STATUS, C		;if Carry is clear, COUNT2 holds the number of tens
		goto	LCD_ROW2_LOOP2		;if Carry is set, subtract some more
		incf	COUNT2, 1		;increment counter
		goto	LCD_ROW2_LOOP1
LCD_ROW2_LOOP2
		movf	COUNT2, 0		;move number of tens to WREG
		movwf	DEC_NUM + OutByte1	;move WREG to tens place in DEC_NUM
		bcf	STATUS, C		;clear Carry for future use

SUB_ONES	movlw	0x0A
		addwf	TEMP_DATA + MSBTemp, 0	;something 9 or less is left, ignore carry
		movwf	DEC_NUM + OutByte2	;place it in the ones holder in DEC_NUM
END_HEX_TO_DEC

		movf	DEC_NUM + OutByte0, 0
		call	hex2ascii
		call	SendChar

		movf	DEC_NUM + OutByte1, 0
		call	hex2ascii
		call	SendChar

		movf	DEC_NUM + OutByte2, 0
		call	hex2ascii
		call	SendChar

		btfss	TEMP_DATA + LSBTemp, 7	;Testing for .0 or .5 data
		goto	ZERO_LEFT

HALF_LEFT	movlw	0x13			;This routine places ".5-C" on LCD
		movwf	COUNT2			;Preload counter with table call value
LCD_DEC_LOOP					;Call table values 0x12 through 0x15
		movlw	HIGH TABLE		;Preload PCPLATH from TABLE
		movwf	PCLATH
		movf	COUNT2, 0		;Place counter in WREG
		call	TABLE			;Get ascii value from TABLE
		call	SendChar		;Send ascii value to LCD
		incf	COUNT2, 1		;Increment counter
		movf	COUNT2, 0		;Test counter for max value
		sublw	0x17
		btfss	STATUS, Z
		goto	LCD_DEC_LOOP		;If counter not max, loop back
		goto	END_LCD_ROW2		;If counter is max, leave the routine

ZERO_LEFT	movlw	0x0F			;This routine places ".0-C" on LCD
		movwf	COUNT2			;Preload counter with table call value
LCD_ROW2_LOOP3					;Call table values 0x0E through 0x11
		movlw	HIGH TABLE		;Preload PCPLATH from TABLE
		movwf	PCLATH
		movf	COUNT2, 0		;Place counter in WREG
		call	TABLE			;Get ascii value from TABLE
		call	SendChar		;Send ascii value to LCD
		incf	COUNT2, 1		;Increment counter
		movf	COUNT2, 0		;Test counter for max value
		sublw	0x13
		btfss	STATUS, Z		;If counter not max, loop back
		goto	LCD_ROW2_LOOP3		;If counter is max, leave the routine
END_LCD_ROW2
		return

;**********************************************************************
;
;Function:	delay_196ms
;Description:	delays for 196.1ms with a 4MHz clock.
;Algorithm:	
;		initialize variables
;		increment variables until rolls over
;		return
;
;NOTES:
;1. Does not return anything, just delays processor.
;
;**********************************************************************
delay_196ms
		global	delay_196ms
		banksel	COUNT_INSIDE
		movlw	0x01
		movwf	COUNT_OUTSIDE
		movlw	0x01
		movwf	COUNT_INSIDE
		incfsz	COUNT_INSIDE, 1
		goto	$-1
		incfsz	COUNT_OUTSIDE, 1
		goto	$-5
		return

;*****************************************************************
;
;Just a table for calling LCD information
;LCD Display format:
;0xXXX T75	<--XXX is the address, T75 is the device
;+XXX.X-C	<-- +/-XXX is the temperature is degrees C
;
;*****************************************************************

GETDATA		CODE
TABLE
		GLOBAL	TABLE
		addwf	PCL, f
		DT	"WORKING"	;table values 0 to 6	(0x00 to 0x06)
		DT	"0x"		;table values 7 to 8	(0x07 to 0x08)
		DT	" T75"		;table values 9 to 12	(0x09 to 0x0C)
		DT	"+"		;table value  13	(0x0D)
		DT	"-"		;table value  14	(0x0E)
		DT	".0-C"		;table values 15 to 17	(0x0F to 0x12)
		DT	".5-C"		;table values 18 to 21	(0x13 to 0x16)

		end

