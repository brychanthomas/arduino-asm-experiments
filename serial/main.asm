;
; serial.asm
;
; Created: 14/03/2021 18:21:10
; Author : Brychan
;
; based closely on https://github.com/pearsonalan/arduino-serial-asm/blob/master/serial-message.asm
;
; To flash, press F7 to assemble then go Tools > Deploy.
;

	

init:
	rcall serial_init

main:
    ldi zl, LOW(data<<1)
	ldi zh, HIGH(data<<1)

loop:
	lpm r19, z+
	tst r19
	breq main
	rcall serial_transmit
    rjmp loop

;initialise serial connection
serial_init:
	ldi r16, 103
	clr r17

	sts 0xc5, r17
	sts 0xc4, r16

	ldi	r16, (1<<4)|(1<<3)
	sts	0xc1, r16

	ldi	r16, 0b00001110
	sts	0xc2, r16
	ret

; transmit byte stored in r19 over serial
serial_transmit:
	lds	r16, 0xc0
	sbrs r16, 5
	rjmp serial_transmit

	sts 0xc6, r19
	ret

data:
	.db "Serial output!", 0x0d, 0x0a, 0x00, 0x00
