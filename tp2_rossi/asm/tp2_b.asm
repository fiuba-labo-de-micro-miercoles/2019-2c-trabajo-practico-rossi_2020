.include "m328pdef.inc"

.equ entrada = 0
.equ salida = 1

.cseg
.org 0x0000
			JMP main

.org INT_VECTORS_SIZE

main:

			LDI R16, (0<<0 | 1<<1) ; Configuro PB0 como entrada y PB1 como salida.
			OUT DDRB, R16
			CBI PORTB,salida ;aseguro que el programa arranque con el LED apagado.
			SBI PORTB, entrada ; habilito la R de pullup interna del puerto de entrada.

bajo:
			SBIC PINB,entrada ; mientras el estado de PB0 sea alto (no presiono el botón) quedara en loop. 
			JMP bajo
			SBI PORTB,salida ; cuando detecto un estado en bajo de la entrada (presiono el botón) prendo el led de salida.

alto: 
			SBIS PINB,entrada ; mientras el estado de PB0 sea bajo (el botón está presionado) quedara en loop. 
			JMP alto
			CBI PORTB,salida ; cuando detecto un estado en alto de la entrada (suelto el botón) apago el led de salida.
			JMP bajo ; reinicio el ciclo
