;
; fibonacci.asm
;
; Created: 15/03/2021 09:01:47
; Author : Brychan
;


start:
	;call serial_init

    ldi r20, 0 ;load 1 into prev term registers
	ldi r21, 1

	ldi r22, 0 ;load 1 into current term registers
	ldi r23, 1

	ldi r24, 0 ;load 0 into temporary value registers
	ldi r25, 0

loop:
	call calculate_next_term
	call calculate_next_term
	call calculate_next_term
halt:
	rjmp halt ;should see 00 03 00 05 in regs 20-23

calculate_next_term:
	mov r24, r22 ;copy current term into temp registers
	mov r25, r23

	add r23, r21 ;add current to prev and store result in current
	adc r22, r20

	mov r20, r24 ;copy temp regiters into prev registers
	mov r21, r25
	ret

; initialise serial connection
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