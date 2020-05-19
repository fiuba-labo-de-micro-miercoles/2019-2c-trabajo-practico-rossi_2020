.include "m328pdef.inc"

.cseg
.org 0x0000
			jmp main

.org INT_VECTORS_SIZE


main:
					
			ldi		r20,0xff
			out		DDRB,r20		;	Configuro puerto B como salida

			ser		r25				; valores 0xFF y 0x00 para luego conmutar el puerto B
			clr		r26

			ldi		r23,0xff
on:			out		PORTB,r25			;enciendo TODO el PUERTO B.
		
			
delay:
			ldi		r20,0x00
			ldi		r21,0x00
			ldi		r22,0x00	
		
cycle:		inc		r20
			cpi		r20,0xff
			brlo	cycle
			ldi		r20,0x00
			inc		r21
			cpi		r21,0xff
			brlo	cycle
			ldi		r21,0x00
			inc		r22
			cpi		r22,0x20		; con este valor es facil variar de forma apreciable la frecuencia ya que es un multiplicador de todos los incrementos anteriores
			brlo	cycle
			inc		r23

			mov		r24, r23
			andi	r24, 0x01	; el resultado es 0 o 1, y define si r23 es o no par.
			breq	off			; Si es el valor de r23 es par entonces que apague el led, si no que lo prenda, asi cada vez que incrementa r23 tiene un resultado diferente, hace 1 ciclo con LED on y otro con LED off
			RJMP	on			; reinicio el ciclo

off:		out		PORTB,r26			;apago el PUERTO B entero
			RJMP	delay
