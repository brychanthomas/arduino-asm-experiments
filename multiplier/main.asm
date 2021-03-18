;
; multiplier.asm
;
; Created: 18/03/2021 17:11:54
; Author : Brychan
;

init:
	call serial_init
start:
	ldi r19, 0 ;push 0 to stack
	push r19
get_first_num:
    call serial_receive
	cpi r19, 0x2a ;* char
	breq first_num_finished
	cpi r19, 0x20 ;space
	breq get_first_num
	push r19
	rjmp get_first_num
first_num_finished:
	call process_number
	mov r20, r19
get_second_num:
	call serial_receive
	cpi r19, 0x0a ;newline char
	breq second_num_finished
	cpi r19, 0x20 ;space
	breq get_second_num
	push r19
	rjmp get_second_num
second_num_finished:
	call process_number
	mul r19, r20
	mov r19, r0
	call serial_transmit
	call newline
	rjmp start

	

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

;converts denary string in stack to integer in r19
process_number:
	pop r9 ;pop return pointer
	pop r10
	ldi r16, 0x30 ;ASCII code of 0
	ldi r17, 1 ;digit multiplier
	ldi r18, 10 ;digit multiplier increased by 10 on each digit
	ldi r19, 0 ;initialise r19 to 0
process_number_loop:
	pop r15 ;get next char
	tst r15 ;if char is zero number has ended
	breq number_end_reached
	sub r15, r16 ;subtract ASCII value of zero to get integer 0 - 9
	mul r15, r17 ;multiply by digit multiplier
	add r19, r0 ;add result to r19
	mul r17, r18 ;multiply digit multiplier by 10
	mov r17, r0
	rjmp process_number_loop
number_end_reached:
	ldi r16, 0 ;push 0 back to stack
	push r16
	push r10 ;push return pointer
	push r9
	ret