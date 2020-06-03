.include "m328pdef.inc"

.def CONTADOR = R20

.macro	setstackpointer
		LDI R16, LOW(RAMEND)
		OUT SPL, R16
		LDI R16, HIGH(RAMEND)
		OUT SPH, R16
.endm

.cseg
.org 0x0000
			JMP main

main:

		; Configuro el puerto B como salida

		LDI R16, 0xFF
		OUT DDRB, R16

		setstackpointer ; inicializo el SP

		; prendo el primer LED durante 0.5 segundos como inicio y luego entra en loop
		LDI R16, 0x20
		OUT PORTB, R16
		CALL cycle

loop:	LDI CONTADOR, 5
loop1: 
		; esta primera parte se encarga de ir desplazando el led encendido desde PB5 a PB0
		LSR R16 
		OUT PORTB, R16
		CALL cycle
		DEC CONTADOR
		BRNE loop1
		LDI CONTADOR, 5
loop2:
		; esta segunda parte se encarga de ir desplazando el led encendido desde PB0 a PB5
		LSL R16
		OUT PORTB, R16
		CALL cycle
		DEC CONTADOR
		BRNE loop2
		JMP loop
cycle:
		; retardo de aproximadamente 0.5 segundos IDEM TP1
		LDI		R21,0x00
		LDI		R22,0x00
		LDI		R23,0x00
cycle2:		
		INC		R21 
		CPI		R21,0xFF
		BRLO	cycle2
		LDI		R21,0x00
		INC		R22
		CPI		R22,0xFF
		BRLO	cycle2
		LDI		R22,0x00
		INC		R23
		CPI		R23,0x20
		BRLO	cycle2
		RET    
		