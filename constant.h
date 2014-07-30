;*****************************************************************
;
;Project:	T-SENSE.PJT
;File name:	constant.h
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
;Sets up header data and definitions for project.
;
;*****************************************************************
;	General Program Algorithm:
;	Initialize PIC
;	Read bus
;	Initialize TCN75
;main
;	On TMR1 interrupt (plus delay)
;		call TEST_NODE
;	goto main
;
;TEST_NODE
;	Read data from TCN75
;	If node exists
;		call PROCESS_NODE
;	Else
;		return
;
;PROCESS_NODE
;	Read data from TCN75
;	Convert data from 2's complement to ASCII
;	Send to LCD
;
;**********************************************************************
;
;	Notes:
;
;	This program is written in relocatable form and shows how
;	to communicate with a set of TCN75 thermal sensors.
;	The code is intended to support the I2C interface.
;
;	Processor runs in RC mode at about 4Mhz.
;
;	Because the LCD is only 8 digits long (2 rows available), the 
;	address and data will be shown in the following form:
;	NORMAL
;	XXX oC
;
;	LCD pins:
;	PIN 1  = GND
;	PIN 2  = +5V
;	PIN 3  = CONTRAST POT.
;	PIN 4  = RA1		;LCD register select
;	PIN 5  = RA2		;LCD R/W signal
;	PIN 6  = RA3		;LCD enable signal
;	PIN 7  = RB0		;LCD data bit
;	PIN 8  = RB1		;LCD data bit
;	PIN 9  = RB2		;LCD data bit
;	PIN 10 = RB3		;LCD data bit
;	PIN 11 = RB4		;LCD data bit
;	PIN 12 = RB5		;LCD data bit
;	PIN 13 = RB6		;LCD data bit
;	PIN 14 = RB7		;LCD data bit
;
;**********************************************************************

#DEFINE	CNTRL		PORTA
#DEFINE	E		3
#DEFINE	RW		2
#DEFINE	RS		1
#DEFINE	RB0		0
#DEFINE	RB1		1
#DEFINE	RB2		2
#DEFINE	RB3		3
#DEFINE	RB4		4
#DEFINE	RB5		5
#DEFINE	RB6		6
#DEFINE	RB7		7

#define	Device		0
#define	MSBTemp		1
#define	LSBTemp		2
#define	CONF_REG	3

#define	OutByte0	0
#define	OutByte1	1
#define	OutByte2	2

#define	InByte0		0
#define	InByte1		1

