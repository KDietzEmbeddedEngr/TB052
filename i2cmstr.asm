;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	i2cmstr.asm
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
;This file is the main program that makes calls to all other sections
;of the program.
;
;*****************************************************************
	list      p=16f872            ; list directive to define processor
	#include <p16f872.inc>        ; processor specific variable definitions
	#include <constant.h>

	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _RC_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

	errorlevel	-302

;***** VARIABLE DEFINITIONS

VAR0		UDATA

CHAR		RES	1	;Character used in LCD communications
TEMP		RES	1	;Used in LCD communications
W_TEMP		RES	1	;Saves w register during interrupt
STATUS_TEMP	RES	1	;Saves status register during interrupt
NODE_COUNT	RES	1	;used to cycle through address nodes in TEST_NODE function
CNT_DLAY	RES	1	;used for delays

DATAOUT		RES	4	;Information going to thermal sensor
DATAIN		RES	2	;Information coming from thermal sensor

TEMP_DATA	RES	8	;contains information for mode being processed

DEC_NUM		RES	3	;contains decimal values of hex numbers collected from sensor, to be sent to LCD

;**********************************************************************

	GLOBAL	TEMP, CHAR, DEC_NUM
	GLOBAL	DATAOUT, DATAIN, TEMP_DATA, NODE_COUNT

	EXTERN	HELLO, LCDInit, CHECK_IDLE, SEND_LCD_ROW1, SEND_LCD_ROW2
	EXTERN	START_CONDITION, SET_POINT_WR_CONFIG, RESTART, READ_CONFIG, STOP_CONDITION
	EXTERN	SET_POINT75, READ75_TEMP, delay_196ms

;**********************************************************************
STARTUP		CODE			; processor reset vector
		NOP
  		goto	START_INIT	; go to beginning of program

ISR		CODE			; interrupt vector location
		movwf	W_TEMP		; save off current W register contents
		movf	STATUS,	0	; move status register into W register
		movwf	STATUS_TEMP	; save off contents of STATUS register


		decf	CNT_DLAY, 1
		btfss	STATUS, Z
		goto	CLEAR_ISR

		call	TEST_NODE	;calls routine where nodes are tested for existance
		call	PROCESS_NODE	;polls node for thermal data if node exists
		movlw	0x09
		movwf	CNT_DLAY
CLEAR_ISR
		banksel	TMR1H
		clrf	TMR1H		;Clearing timer 1
		clrf	TMR1L		;Clearing timer 1
		clrf	PIR1		;Clearing interrupt flags.


		movf	STATUS_TEMP,0	;Retrieve copy of STATUS register
		movwf	STATUS		;Restore pre-isr STATUS register contents
		swapf	W_TEMP,f
		swapf	W_TEMP,w	;Restore pre-isr W register contents
		retfie			;Return from interrupt

INITIALIZE	CODE
START_INIT
		banksel	OPTION_REG
		movlw	0x87		;PORTB pull-ups disabled, RB0 interrupt on falling edge
		movwf	OPTION_REG
		movlw	0x01
		movwf	PIE1		;TMR1 enabled (interrupts)
		movlw	0x00
		movwf	PIE2
		movlw	0x1D
		movwf	SSPCON2
		movlw	0x80		;I2C mode
		movwf	SSPSTAT		;Set data rate to 100kHz mode (max)
		movlw	0x08		;48.6kHz data rate, 4MHz RC oscillator
;		movlw	0x0C		;76.9kHz data rate, 4MHz RC oscillator
;		movlw	0x09		;100kHz bus, 4MHz oscillator
;		movlw	0x27		;100kHz bus, 16MHz oscillator
		movwf	SSPADD
		movlw	0x06
		movwf	ADCON1		;All pins configured as digital
		movlw	0x00
		movwf	TRISA		;Configuring port I/O
		movlw	0xFF
		movwf	TRISB		;Configuring port I/O
		movlw	0x00
		movwf	TRISC		;Configuring port I/O

		banksel	PORTA
		movlw	0x00
		movwf	PORTA		;Clearing registers to known states
		movwf	PORTB
		clrf	PORTC

		movlw	0x28
		movwf	SSPCON		;Enable MSSP, master mode, hardware controlled
		movlw	0x00
		movwf	ADCON0		;A/D is off

;		movlw	0x35		;0011 0101, prescale 1:8
;		movlw	0x25		;0010 0101, prescale 1:4
;		movlw	0x15		;0001 0101, prescale 1:2
		movlw	0x05		;0000 0101, prescale 1:1
		movwf	T1CON		;turn on timer 1, prescale set, internal clock
		movlw	0x09
		movwf	CNT_DLAY

		call	LCDInit
		call	delay_196ms
		call	HELLO

		movlw	0x01		;This do-while loop makes LCD splash visible
		movwf	CNT_DLAY
		call	delay_196ms
		decfsz	CNT_DLAY, 1
		goto	$-2

		movlw	0x10
		movwf	NODE_COUNT	;Pre-loading counter
		movlw	0xC0
		movwf	INTCON		;Enabling interrupts

;*****************************************************************
;
;main
;	On TMR1 interrupt
;		call GET_DATA
;	goto main
;
;*****************************************************************
MAIN		goto	MAIN		;loop here until interrupt

;*****************************************************************
;
;The following routine is TEST_NODE.
;
;Notes:
;Pattern for DO DO DO is 0x90 + 0x01 + 0x1A, where the first byte is addressed with the address
;counter for bits 1, 2, and 3.
;
;*********************************************************
TEST_NODE

		clrf	TEMP_DATA + Device
		clrf	TEMP_DATA + MSBTemp
		clrf	TEMP_DATA + LSBTemp
		clrf	TEMP_DATA + CONF_REG
		clrf	DATAOUT + OutByte0
		clrf	DATAOUT + OutByte1
		clrf	DATAOUT + OutByte2
		clrf	DATAIN + InByte0
		clrf	DATAIN + InByte1
		clrf	DEC_NUM + OutByte0
		clrf	DEC_NUM + OutByte1
		clrf	DEC_NUM + OutByte2

		movlw	0x02
		subwf	NODE_COUNT, 1		;subtraction is 2's compliment, most-signicant nibble should remain zero
		btfss	NODE_COUNT, 7		;test bit 7, if high, then register was zero, must roll over
		goto	CONTINUE_TEST
CLEAR_COUNT
		movlw	0x0E
		movwf	NODE_COUNT
CONTINUE_TEST
		movlw	0x90			;start byte for temperature sensor
		movwf	DATAOUT + OutByte0
		movf	NODE_COUNT, 0
		iorwf	DATAOUT + OutByte0, 1	;Placing address in start byte
		movlw	0x01
		movwf	DATAOUT + OutByte1	;pointing to configuration register
		movlw	0x1A
		movwf	DATAOUT + OutByte2	;writing to configuration register

		call	CHECK_IDLE
		call	START_CONDITION
		call	CHECK_IDLE
		call	SET_POINT_WR_CONFIG
		call	CHECK_IDLE
		call	RESTART
		call	CHECK_IDLE
		call	READ_CONFIG
		banksel	DATAIN
		movf	DATAIN + InByte0, 0
		movwf	TEMP_DATA + CONF_REG	;data returned in w, preload variable data
		call	CHECK_IDLE
		call	STOP_CONDITION

		banksel	TEMP_DATA
		clrf	TEMP_DATA + Device	;clear register if node does not exist
		movf	TEMP_DATA + CONF_REG, 0
		sublw	0x1A
		btfss	STATUS, Z
		goto	CLEAR_NODE
CONFIG_TCN75
		movlw	0x75
		movwf	TEMP_DATA + Device
		goto	EXIT_TEST_NODE
CLEAR_NODE	clrf	TEMP_DATA + Device
EXIT_TEST_NODE					;label added for jump location
		global	EXIT_TEST_NODE

		return

;*****************************************************************
;
;FUNCTION:	PROCESS_NODE
;
;*****************************************************************
PROCESS_NODE
		global	PROCESS_NODE
				;Preassign outgoing registers here
				;Pattern for this section is: [S DO DO Sr DO DI DI P]
		btfss	TEMP_DATA + Device, 0	;If device is not TCN75, do not display data
		goto	END_PROCESS_NODE
		movlw	0x90			;start byte for temperature sensor
		movwf	DATAOUT + OutByte0
		movf	NODE_COUNT, 0
		iorwf	DATAOUT + OutByte0, 1	;Placing address in start byte
		clrf	DATAOUT + OutByte1	;pointing to temperature register

		call	CHECK_IDLE
		call	START_CONDITION
		call	CHECK_IDLE
		call	SET_POINT75
		call	CHECK_IDLE

		banksel	DATAOUT
		incf	DATAOUT + OutByte0, 1	;doing a read operation now, LSb = 1

		call	RESTART
		call	CHECK_IDLE
		call	READ75_TEMP
		call	CHECK_IDLE
		call	STOP_CONDITION

		call	delay_196ms
		call	SEND_LCD_ROW1
		call	delay_196ms
		call	SEND_LCD_ROW2
END_PROCESS_NODE
		return

		END			;directive 'end of program'

