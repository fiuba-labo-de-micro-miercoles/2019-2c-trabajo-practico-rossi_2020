; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 24 de junio de 2020

.include "m328pdef.inc"

.def contador = r16
.def dummy = r25

.macro set_sp
	ldi dummy, low(RAMEND)
	out spl, dummy
	ldi dummy, high(RAMEND)
	out sph, dummy
.endm

.cseg
.org 0x0000
			jmp config

; EXT INT

.org INT0addr
			jmp isr_int0
.org INT_VECTORS_SIZE

 config:
			set_sp

			; configuro interrupcion externa INT0,INT1
			ldi		dummy,(0 << ISC01 | 0 << ISC00  ) ;0x03 ; IE0 por flanco descendente
			sts		EICRA,dummy					   ;(ISC01=1;ISC00=1)
			ldi		dummy,(1 << INT0)	;0x01	; habilito IE0
			out		EIMSK,dummy

			;habilito interrupuciones
			sei ;(I en 1)

			;Configuracion de puertos
			; portd,2 como entrada
			ldi		dummy, (0 << 2)
			out		DDRD, dummy
			ldi		dummy, (1 << 2)
			out		PORTD,dummy ;(R pull up activa)

			; PB0 y PB1 como salidas
			ldi		dummy, (1 << 0 | 1 << 1)
			out		DDRB, dummy
			clr		dummy
			out		PORTB,dummy ; inicializo en cero

main:
			sbi		PORTB,0
standby:
			rjmp	standby


isr_int0:
			cbi		PORTB,0
twink:
			ldi		contador,0x05
on:
			sbi		PORTB,1
			set
			rjmp	delay
off:
			cbi		PORTB,1
			clt
			rjmp	delay
rt:
			dec		contador
			brne	on
			sbi		PORTB,0
			reti

delay:
			ldi		r20,0xff
			ldi		r21,0xff
			ldi		r22,0x29			
cycle:
			dec		r20
			brne	cycle
			ldi		r20,0xff
			dec		r21
			brne	cycle
			ldi		r21,0xff
			dec		r22		; con este valor es facil variar de forma apreciable la frecuencia ya que es un multiplicador de todos los incrementos anteriores
			brne	cycle

			brts	off
			jmp		rt
