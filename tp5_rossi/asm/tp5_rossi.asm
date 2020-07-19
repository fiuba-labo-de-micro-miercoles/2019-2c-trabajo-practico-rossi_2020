; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 19 de julio de 2020

.include "m328pdef.inc"

.def dummy = r25

.macro set_sp
	ldi dummy, low(RAMEND)
	out spl, dummy
	ldi dummy, high(RAMEND)
	out sph, dummy
.endm

.macro set_port_as_out
	ldi dummy, 0xFF
	out @0, dummy
.endm

.macro set_port_as_in
	ldi dummy, 0x00
	out @0, dummy
.endm


.cseg
.org 0x0000
	jmp config
	
.org 0x002A 
	jmp		isr_adc
.org INT_VECTORS_SIZE

config:
	set_sp
	
	set_port_as_out		DDRB
	set_port_as_in		DDRC

	; adc
	
	ldi		dummy, 0x62; 0b01100010(VREF = VCC ,ajustar a la izq, para que sea de 8 bits ADLAR = 1, MUX 0010 ADC2)
	sts		ADMUX, dummy
	ldi		dummy, 0xAF; 0b10101111 (ADCENABLE,no arranco conv,autotrigger,prescaler=128, ADIE=1)
	sts		ADCSRA, dummy ; ADEN=1 ahbilito adc, ADSC= 1 inicio conversion prescaler en 128 para que no supere la velocidad de conversion del ADC
	; adcsrb en 0. free running

	sei ; habilito interrupciones
main:
	
	lds		dummy,ADCSRA
	ori		dummy,(1<<6) ; inicio conversion
	sts		ADCSRA,dummy
hold:
 	jmp		hold

isr_adc:
	; leo entrada
	lds		dummy,ADCH
	; division por 4 para que vaya entre 0 y 63
	lsr		dummy
	lsr		dummy
	; salida por PORTB
	out		PORTB,dummy

	reti
