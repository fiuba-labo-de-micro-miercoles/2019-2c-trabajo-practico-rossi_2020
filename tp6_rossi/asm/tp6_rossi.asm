; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 29 de julio de 2020
; TP6 - Timers

.include "m328pdef.inc"

; ETIQUETAS
.equ	NOCLOCK = 0x00
.equ	PRE64  = 0x03
.equ	PRE256	= 0x04
.equ	PRE1024 = 0x05

.def dummy = r25

;MACROS
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

; PIN CHANGES
.org PCI2addr
	jmp isr_pci2
; INT x OVF del timer 1
.org OVF1addr
	jmp isr_t1ovf
.org INT_VECTORS_SIZE

config:
	set_sp

	; pin change config para PD0 y PD1 (PCINT16 y PCIN17)
	ldi		dummy, (1<<PCIE2) ; PCIE2 enable pinchage
	sts		PCICR, dummy

	ldi		dummy, (1<<1 | 1<<0)
	sts		PCMSK2, dummy
	
	; config de puertos
	set_port_as_in DDRD
	set_port_as_out DDRB

	; config inicial del timer default habilito int x overflow y globales
	ldi		dummy,0x01
	sts		TIMSK1, dummy
	
	sei

main:
	; led encendido
	sbi		PORTB,0
	set

here:	
	jmp		here

isr_pci2:
	sbis	PIND,0
	rjmp	low_es_cero

; x1
low_es_uno:
	sbis	PIND,1
	rjmp	high_es_cero
;caso 11
	ldi		dummy, PRE1024
	sts		TCCR1B, dummy
	reti

;caso 01
high_es_cero:
	ldi		dummy, PRE64
	sts		TCCR1B, dummy
	reti

low_es_cero:
	sbis	PIND,1
	rjmp	input_es_cero
;caso 10
	ldi		dummy, PRE256
	sts		TCCR1B, dummy
	reti
;caso 00
input_es_cero:
	ldi		dummy, NOCLOCK
	sts		TCCR1B, dummy
	sbi		PORTB,0
	set
	reti

; RUTINA DE INT X OVF DEL TIMER 1
isr_t1ovf:
	brts	apagar_led

encender_led:
	sbi		PORTB,0
	set
	reti

apagar_led:
	cbi		PORTB,0
	clt
	reti