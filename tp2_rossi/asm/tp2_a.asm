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

bajo: 
			SBIS PINB,entrada ; mientras el estado de PB0 sea bajo quedara en loop. 
			JMP bajo
			SBI PORTB,salida ; si el valor de entrada es alto se impone un valor de 1 logico en la salida.
alto:
			SBIC PINB,entrada ; mientras el estado de PB0 sea alto quedara en loop.
			JMP alto
			CBI PORTB,salida ; si el valor de entrada es alto se impone un valor de 0 logico en la salida.
			JMP bajo	; reinicio el ciclo
