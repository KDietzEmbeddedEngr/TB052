;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	hex2ascii.asm
;Date:		April 12, 2001
;Version:	1.1
;Engineer:	Ken Dietz
;
;*****************************************************************
;
;Modifications:
;Version 1.1 developed for new project.  Accommodates T-SENSE.PJT now.
;
;Removed pagesel directives, not required for PIC16F872.
;
;*****************************************************************
;
;Purpose:
;This function assumes that a hex number is in the working register, w.  It
;then returns the ASCII equivalent in w.  The code is relocatable.
;
;*****************************************************************

	list	p=16F872
	#include <p16F872.inc>
	#include <constant.h>

	errorlevel	-302

HEXVAR		UDATA
CONVERT_DATA	RES	1

HEX_CODE	CODE
hex2ascii	
		global	hex2ascii
		banksel	CONVERT_DATA
		movwf	CONVERT_DATA
		sublw	0x09
		btfss	STATUS,	C
		goto	add_37
		goto	add_30

add_37		
		global	add_37
		banksel	CONVERT_DATA
		movf	CONVERT_DATA,	w
		addlw	0x37			;ASCII value is in w register
		return

add_30		
		global	add_30
		banksel	CONVERT_DATA
		movf	CONVERT_DATA,	w
		addlw	0x30			;ASCII value is in w register
		return

		end

