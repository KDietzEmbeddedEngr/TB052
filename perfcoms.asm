;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	perfcoms.asm
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
;Controls communications between the PICmicro and peripheral.
;
;*****************************************************************

	list      p=16f872            ; list directive to define processor
	#include <p16f872.inc>        ; processor specific variable definitions
	#include <constant.h>

	errorlevel	-302

	EXTERN	DATAOUT, DATAIN, TEMP_DATA

PERIPHERAL_COMS		CODE

;**********************************************************
;
;Creates start condition on bus.
;
;**********************************************************
START_CONDITION
		global	START_CONDITION
		banksel	SSPCON2
		bsf	SSPCON2, SEN	;intitiate start condition
		btfss	SSPSTAT, S
		goto	$-1
		return

;**********************************************************
;
;Creates a restart condition on the bus.
;
;**********************************************************
RESTART
		global	RESTART
		banksel	SSPCON2
		bsf	SSPCON2, RSEN	;intitiate restart condition
		btfss	SSPSTAT, S
		goto	$-1
		return

;**********************************************************
;
;Creates stop condition on bus.
;
;**********************************************************
STOP_CONDITION
		global	STOP_CONDITION
		banksel	SSPCON2
		bsf	SSPCON2, PEN	;generate stop condition
		btfss	SSPSTAT, P
		goto	$-1
		return

;**********************************************************
;
;Checks for an idle MSSP.
;
;**********************************************************
CHECK_IDLE
		global	CHECK_IDLE
		banksel	SSPSTAT
		btfsc	SSPSTAT, R_W	;transmit in progress?
		goto	$-1
		movf	SSPCON2, 0	;get copy of SSPCON2
		andlw	0x1F		;mask non-status
		btfss	STATUS, Z
		goto	$-3		;bus busy, test again
		return

;**********************************************************
;
;This function sets the node pointer to the configuration register, then writes to the configuration register.
;
;**********************************************************
SET_POINT_WR_CONFIG
		global	SET_POINT_WR_CONFIG

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte0, 0	;move control byte to SSPBUF
		movwf	SSPBUF
		btfss	PIR1, SSPIF
		goto	$-1			;wait for SSPBUF to empty
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	EXIT_SET_POINT		;received NACK, something is wrong or node does not exist

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte1, 0	;move pointer information to SSPBUF
		movwf	SSPBUF
		btfss	PIR1, SSPIF
		goto	$-1			;wait for slave acknowledge
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	EXIT_SET_POINT		;received NACK, something is wrong or node does not exist

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte2, 0	;move configuration info to SSPBUF
		movwf	SSPBUF
		btfss	PIR1, SSPIF
		goto	$-1			;wait for data
EXIT_SET_POINT
		return

;**********************************************************
;
;Reads the configuration register for the node.
;
;**********************************************************
READ_CONFIG
		global	READ_CONFIG

		banksel	PIR1
		clrf	PIR1
		movlw	0x01
		iorwf	DATAOUT + OutByte0, 0
		movwf	SSPBUF			;send control byte
		btfss	PIR1, SSPIF
		goto	$-1			;wait for slave acknowledge
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	EXIT_READ_CONFIG	;received NACK, something is wrong or node does not exist

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		banksel	SSPCON2
		bsf	SSPCON2, 3		;set MSSP to receive mode
		btfss	SSPSTAT, BF
		goto	$-1
		banksel	SSPBUF
		movf	SSPBUF, 0
		movwf	DATAIN + InByte0
		banksel	SSPCON2
		bsf	SSPCON2, ACKDT
		bsf	SSPCON2, ACKEN		;send NACK
		banksel	PIR1
		btfss	PIR1, SSPIF
		goto	$-1
EXIT_READ_CONFIG
		return

;**********************************************************
;
;Sets pointer for the TCN75
;
;**********************************************************
SET_POINT75
		global	SET_POINT75

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte0, 0	;move control byte to SSPBUF
		movwf	SSPBUF
		btfss	PIR1, SSPIF
		goto	$-1
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	EXIT_SET_POINT75	;received NACK, something is wrong or node does not exist

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte1, 0	;move pointer information to SSPBUF
		movwf	SSPBUF
		btfss	PIR1, SSPIF
		goto	$-1			;wait for data to be sent
EXIT_SET_POINT75
		return

;**********************************************************
;
;Reads temperature from the TCN75
;
;**********************************************************
READ75_TEMP
		global	READ75_TEMP

		banksel	PIR1
		clrf	PIR1
		movf	DATAOUT + OutByte0, 0
		movwf	SSPBUF			;send control byte
		btfss	PIR1, SSPIF
		goto	$-1			;wait for slave acknowledge
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	EXIT_READ75_TEMP	;received NACK, something is wrong or node does not exist

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		banksel	SSPCON2
		bsf	SSPCON2, 3		;set MSSP to receive mode
		btfss	SSPSTAT, BF
		goto	$-1
		banksel	SSPBUF
		movf	SSPBUF, 0
		movwf	TEMP_DATA + MSBTemp
		banksel	SSPCON2
		bcf	SSPCON2, ACKDT
		bsf	SSPCON2, ACKEN		;send ACK
		banksel	PIR1
		btfss	PIR1, SSPIF
		goto	$-1

		call	CHECK_IDLE

		banksel	PIR1
		clrf	PIR1
		banksel	SSPCON2
		bsf	SSPCON2, 3		;set MSSP to receive mode
		btfss	SSPSTAT, BF
		goto	$-1
		banksel	SSPBUF
		movf	SSPBUF, 0
		movwf	TEMP_DATA + LSBTemp
		banksel	SSPCON2
		bsf	SSPCON2, ACKDT
		bsf	SSPCON2, ACKEN		;send NACK
		banksel	PIR1
		btfss	PIR1, SSPIF
		goto	$-1
EXIT_READ75_TEMP
		return

		END

