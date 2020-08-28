; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 19 de agosto de 2020

.include "m328pdef.inc"

.def poll_buff = r17
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

.org OVF1addr
	jmp isr_delayoff

; EXT INT
.org INT_VECTORS_SIZE

config:
	; inicializo el stack pointer
	set_sp

	; Rx PD0
	; Tx PD1
	; Leds en PB0,1,2,3
	
	;Puerto D como salida excepto PD0

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

	; habilito el envio y la recepción de datos
	ldi		dummy,(1 << RXEN0 | 1 << TXEN0 )
	sts		UCSR0B, dummy

	; inicializo puntero Z en la tabla con el mensaje a enviar
	set_pointer_z TABLA_ROM

	; config timer para delay
	ldi		dummy,0x01
	sts		TIMSK1, dummy
	ldi		dummy, 0x02 ; prescaler de 8
	sts		TCCR1B, dummy
	
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

	call	mensaje_inicio
	; desactivo la transmisión
	ldi		dummy,(1 << RXEN0 | 0 << TXEN0 )
	sts		UCSR0B, dummy

leer_entrada:
	; polling hasta que halla datos a recibir
	lds		dummy,UCSR0A
	sbrs	dummy,RXC0
	rjmp	leer_entrada
	; guardo el dato
	lds		dato_recibido, UDR0

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

	; si es 1 directamente encendo el mismo
	ldi		dummy,0x01
	cp		dummy,contador
	breq	sigo
	; si no sigo
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
		
no_es_valido:
	rjmp	leer_entrada

isr_delayoff:

	set
	clr		dummy
	; apago el timer
	sts		TCCR1B, dummy
	reti

mensaje_inicio:
	; cargo proximo byte a transmitir en el registro dummy
	lpm		dummy, Z+

	cpi		dummy, 0
	breq	end ; si leo 0 es que termine de transmitir

	; espero a que el buffer de transmision este libre para cargarlo
buffer_empty_poll:
	lds		poll_buff, UCSR0A
	sbrs	poll_buff, UDRE0
	rjmp	buffer_empty_poll

	; si esta libre transmito dato
	sts		UDR0, dummy
	rjmp	mensaje_inicio
end:
	ret

.org 0x500
TABLA_ROM: .db "*** Hola Labo de Micro ***",'\r','\n',"Escriba 1, 2, 3 o 4 para controlar los LEDs",'\r','\n',0

