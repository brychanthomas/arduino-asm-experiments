;
; reverser.asm
;
; Created: 18/03/2021 18:41:27
; Author : Brychan
;
; Receives a string over serial, reverses it using the stack and transmits
; the reverse
;

init:
	call serial_init
start:
	ldi r19, 0x0a ;push newline onto the stack
	push r19
	ldi r19, 0x3e ;print '>'
	call serial_transmit
loop:
    call serial_receive ;receive a character
	call serial_transmit ;print character
	cpi r19, 0x0a
	breq input_finished ;if it's a newline jump to input_finished
	push r19 ;otherwise push it to the stack
	rjmp loop
input_finished:
	pop r19 ;remove char from top of stack
	call serial_transmit ;transmit it
	cpi r19, 0x0a
	breq start ;if it's a newline, full string has been sent so go back to start
	rjmp input_finished

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

;transmit byte stored in r19 over serial
serial_transmit:
	lds	r16, 0xc0
	sbrs r16, 5
	rjmp serial_transmit

	sts 0xc6, r19
	ret

;wait for byte to be sent, store it in r19 and return
serial_receive:
	lds r16, 0xc0 ;get value in USART Control and Status Register A
	sbrs r16, 7 ;if receive is complete skip next instruction
	rjmp serial_receive

	lds r19, 0xc6 ;load value in USART I/O data register into r19
	ret
