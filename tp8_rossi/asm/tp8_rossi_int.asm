; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 19 de agosto de 2020

.include "m328pdef.inc"

.def dato_recibido = r18
.def contador = r19
.def dummy2 = r24
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

.macro set_pointer_z
	ldi ZL, low(@0 << 1)
	ldi ZH, high(@0 << 1)
.endm

.cseg

.org 0x0000
	jmp config

; habilito interrupciones dadas por RXC0 y UDRE0
.org URXCaddr
	jmp	isr_rx
.org UDREaddr
	jmp	mensaje_inicio
.org OVF1addr
	jmp isr_delayoff
; EXT INT
.org INT_VECTORS_SIZE

config:
	set_sp

	; Rx PD0
	; Tx PD1
	; Leds en PB 0,1,2,3
	
	; Config Puerto D como salida excepto PD0

	ldi		dummy,0xFE
	out		DDRD,dummy

	; puerto B como salida
	set_port_as_out	DDRB

	; Configuro USART en baud 9600

	clr		dummy
	sts		UBRR0H, dummy
	ldi		dummy, 103
	sts		UBRR0L, dummy

	; seteo el formato 8 bits y 1 de stop
	ldi		dummy, (1 << UCSZ01 | 1 << UCSZ00)
	sts		UCSR0C, dummy

	; config de interrupciones de USART 0 y enable de transmisión y recepción
	ldi		dummy,(1 << UDRIE0|1 << RXCIE0 | 1 << TXCIE0 | 1 << RXEN0 | 1 << TXEN0 )
	sts		UCSR0B, dummy

	


	; config timer para delay
	ldi		dummy,0x01
	sts		TIMSK1, dummy
	ldi		dummy, 0x02 ; prescaler de 8
	sts		TCCR1B, dummy

	; inicializo puntero Z
	set_pointer_z TABLA_ROM
	; habilito interrupciones globales.
	sei
main:
	

; delay inicial para dar tiempo a la consola
delay:
	brts	delay_off
	rjmp	delay

delay_off:		
	clt
	; limpio el puerto B
	clr		dummy
	out		PORTB,dummy

hold:
	brts		refresh_leds
	rjmp		hold

refresh_leds:
	; reviso que el dato recibido este en los valores que tienen acción
	cpi		dato_recibido, 0x31
	brlo	no_es_valido
	cpi		dato_recibido, 0x35
	brsh	no_es_valido
	; si es 1 2 3 o 4 ingresa

match:

	mov		dummy,dato_recibido
	subi	dummy,0x30
	mov		contador, dummy
	; ahora contador contiene el numero de led a permutar 1,2,3,4
	
	ldi		dummy,0x01
	cp		dummy,contador
	breq	sigo
	dec		contador
	; corro la mascara (dummy) a la posición en PortB del led a encender

loop:
	lsl		dummy
	dec		contador
	breq	sigo
	rjmp	loop

sigo:
	; permuto el led correspondiete determinado por la mascara en dummy
	in		dummy2, PORTB
	eor		dummy2, dummy
	out		PORTB, dummy2

	clt	

no_es_valido:
	rjmp	hold

isr_delayoff:
	set
	clr		dummy
	sts		TCCR1B, dummy
	reti

mensaje_inicio:
	; rutine de interrupcion para transmitir el mensaje
	; cada vez que el buffer de transmision este libre para cargarlo se entra a al rutina
	; cargo porximo byte a transmitir en dummy
	lpm		dummy, Z+
	cpi		dummy, 0
	breq	end ; si leo 0 es que termine de transmitir

	sts		UDR0, dummy
	reti
end:
	; deshabilito interupciones y transmisión cuando termino de transimitir el mensaje
	ldi		dummy,(0 << UDRIE0|1 << RXCIE0 |0 << TXCIE0 | 1 << RXEN0 | 0 << TXEN0 )
	sts		UCSR0B, dummy
	reti

isr_rx:
	; si recibo un dato marco el mismo con el bit t
	lds		dato_recibido, UDR0
	set
	reti

.org 0x500
TABLA_ROM: .db "*** Hola Labo de Micro ***",'\r','\n',"Escriba 1, 2, 3 o 4 para controlar los LEDs",'\r','\n',0

