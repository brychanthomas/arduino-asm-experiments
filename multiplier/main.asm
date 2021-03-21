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
	ldi r19, 0x3e ;print '>' character
	call serial_transmit 
get_first_num:
    call serial_receive
	call serial_transmit
	cpi r19, 0x2a ;on * char goto first_num_finished
	breq first_num_finished
	cpi r19, 0x20 ;ignore spaces
	breq get_first_num
	push r19
	rjmp get_first_num
first_num_finished:
	call process_number ;process number on stack
	mov r20, r19
get_second_num:
	call serial_receive
	call serial_transmit
	cpi r19, 0x0a ;on newline char goto second_num_finished
	breq second_num_finished
	cpi r19, 0x20 ;ignore spaces
	breq get_second_num
	push r19
	rjmp get_second_num
second_num_finished:
	call process_number ;process number on stack
	mul r19, r20 ;multiply the two numbers
	call print_integer
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
	ldi r17, 0 ;zero for comparison
divideloop:
	inc r16 ;i+=1
	call multiply8by16 ;i * div -> r9:r10:r11
	cp r3, r11 ;compare num and i*div
	cpc r2, r10
	cpc r17, r9
	brsh divideloop;branch if num >= i*div
	dec r16 ;i-=1
	call multiply8by16 ;i * div
	mov r7, r2 ;move num to r7:r8
	mov r8, r3
	sub r8, r11 ;remainder = num - i * div
	sbc r7, r10
	mov r6, r16 ;result = i
	ret

;multiply 8-bit number stored in r16 with 16-bit number in r4:r5. Result stored in r9:r10:r11
multiply8by16:
	mul r16, r5 ;multiply low byte
	mov r11, r0 ;copy result to r10:r11
	mov r10, r1 
	mul r16, r4 ;multiply high byte
	add	r10, r0 ;add low byte to r10
	ldi r17, 0
	mov r9, r17
	adc r9, r1 ;add high byte to r9
	ret
	
;prints 16-bit integer stored in r1:r0
print_integer:
	mov r2, r1 ;load value to be printed as numerator
	mov r3, r0
	ldi ZH, high(powers_of_10<<1) ;load address of powers into Z
	ldi ZL, low(powers_of_10<<1)
print_integer_loop:
	lpm r4, Z+ ;load divider
	lpm r5, Z+
	call divide
	mov r2, r7 ;numerator = remainder
	mov r3, r8
	ldi r19, 0x30 ;ASCII code of zero
	add r19, r6 ;add result to zero ASCII
	call serial_transmit ;transmit character
	mov r16, r5 ;if low byte of divisor is not 1, loop again
	cpi r16, 0x01
	brne print_integer_loop
	ret


powers_of_10: ;10000, 1000, 100, 10 and 1 as 16-bit integers
	.db 0x27, 0x10, 0x03, 0xe8, 0x00, 0x64, 0x00, 0x0a, 0x00, 0x01

;divides two 16-bit numbers stored in r2:r3 (num) and r4:r5 (div). 8-bit result stored in r6 and
;16-bit remainder stored in r7:r8