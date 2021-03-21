;
; multiplier.asm
;
; Created: 18/03/2021 17:11:54
; Author : Brychan
;

init:
	call serial_init
	;multiply 8-bit number stored in r16 with 16-bit number in r4:r5. Result stored in r6:r7:r8
	ldi r16, 0xf2 ;load 62145 into r4:r5
	mov r4, r16
	ldi r16, 0xc1
	mov r5, r16
	ldi r16, 0x24 ;load 36 into r16
	call multiply ;multiply r16 by r4:r5. Result should be 2237220 or 0x222324, which translates to ASCII "#$
	mov r19, r6
	call serial_transmit
	mov r19, r7
	call serial_transmit
	mov r19, r8
	call serial_transmit
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

;divides two 16-bit numbers stored in r2:r3 (num) and r4:r5 (div). 8-bit result stored in r6 and
;16-bit remainder stored in r7:r8
divide:
	ldi r16, 0 ;i=0
divideloop:
	

;multiply 8-bit number stored in r16 with 16-bit number in r4:r5. Result stored in r6:r7:r8
multiply:
	mul r16, r5 ;multiply low byte
	mov r8, r0 ;copy result to r7:r8
	mov r7, r1 
	mul r16, r4 ;multiply high byte
	add	r7, r0 ;add low byte to r7
	ldi r17, 0
	mov r6, r17
	adc r6, r1 ;add high byte to r6
	ret
