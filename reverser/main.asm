;
; reverser.asm
;
; Created: 18/03/2021 18:41:27
; Author : Brychan
;

init:
	call serial_init
start:
	ldi r19, 0x0a
	push r19
loop:
    call serial_receive
	cpi r19, 0x0a
	breq input_finished
	push r19
	rjmp loop
input_finished:
	pop r19
	call serial_transmit
	cpi r19, 0x0a
	breq start
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

;transmit line feed character
newline:
	ldi r19, 0x0a
	call serial_transmit
	ret
