;
; fibonacci.asm
;
; Created: 15/03/2021 09:01:47
; Author : Brychan
;
; Calculates the Fibonacci sequence and outputs each term over serial in
; hexadecimal with a ~1 second delay between each. Only uses 16 bits to store
; each term, so can only compute terms up to 46368 (0xB520), at which point
; it halts.


start:
	call serial_init

    ldi r20, 0 ;load 1 into prev term registers
	ldi r21, 1

	ldi r22, 0 ;load 1 into current term registers
	ldi r23, 1

	ldi r24, 0 ;load 0 into temporary value registers
	ldi r25, 0

loop:
	call calculate_next_term
	cp r22, r20 ;if current term less than previous term, halt (overflow has occurred)
	brlo halt
	call output_term ;output current term
	ldi r19, 0x0d
	call serial_transmit ;output carriage return
	ldi r19, 0x0a
	call serial_transmit ;output line feed
	call delay_long ;delay for ~1 second
	rjmp loop

halt:
	rjmp halt 

;calculate next fibonacci term, store it in r22 and r23
calculate_next_term:
	mov r24, r22 ;copy current term into temp registers
	mov r25, r23

	add r23, r21 ;add current to prev and store result in current
	adc r22, r20

	mov r20, r24 ;copy temp regiters into prev registers
	mov r21, r25
	ret

;writes the value in r22 and r23 to serial as hexadecimal
output_term:
	mov r19, r22 ;copy upper byte to r19
	andi r19, 0b11110000 ;get top 4 bits
	swap r19 ;move them to bottom four bits
	call output_hex ;output as hex
	mov r19, r22 ;copy most significant byte to r19
	andi r19, 0b00001111 ;get bottom four bits
	call output_hex ;output as hex

	mov r19, r23 ;repeat above for lower byte
	andi r19, 0b11110000
	swap r19
	call output_hex
	mov r19, r23
	andi r19, 0b00001111
	call output_hex
	ret

;output integer from 0 to 15 stored in r19 as hex
output_hex:
	ldi r18, 0x30 ;if value < 10 add 0x30 to it to get to digits ascii range
	cpi r19, 10
	brlo less_than_ten
	ldi r18, 0x41 ;if value >=10 add 0x41 to get to ABCDEF ascii range
	subi r19, 10 ;and subtract 10
less_than_ten:
	add r19, r18
	call serial_transmit
	ret

;delay for around 0.02 seconds
delay:
	ldi r18, 1 ;r18 counts to 256
outerloop:
	ldi r19, 1 ;therefore r19 counts to 256, 256 times
	inc r18
	tst r18
	breq end
innerloop:
	nop
	inc r19
	tst r19
	breq outerloop
	rjmp innerloop
end:
	ret

;delay for around 1 second
delay_long:
	ldi r17, 50 ;call delay 50 times
delay_long_loop:
	call delay
	dec r17
	tst r17
	breq delay_long_end
	rjmp delay_long_loop
delay_long_end:
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