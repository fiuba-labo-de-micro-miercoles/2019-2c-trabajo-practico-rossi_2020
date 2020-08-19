; Autor: Francisco Rossi
; Padron: 99540
; 86.07 Laboratorio de Microprocesadores - FIUBA
; Catedra: Miercoles
; Fecha: 29 de julio de 2020
; TP6 - Timers

.include "m328pdef.inc"

; ETIQUETAS

.equ cant_pasos = 16 ;(Solo usar potencias de dos hasta 256)
.equ paso = (256/cant_pasos)
.equ brillo_minimo = 0x00
.equ brillo_maximo = (256 - paso) 

.def cte_paso = r24
.def dummy = r25

;MACROS
.macro set_sp
	ldi dummy, low(RAMEND)
	out spl, dummy
	ldi dummy, high(RAMEND)
	out sph, dummy
.endm


.cseg
.org 0x0000
	jmp config

; Interrupciones
.org INT0addr
	jmp isr_inc
.org INT1addr
	jmp isr_dec

.org INT_VECTORS_SIZE

config:
	set_sp

	; config de interupciones HABILITO INT0 INT1 POR FLANCO DESCENDENTE
	ldi		dummy, (1 << 3 | 1 << 1)
	sts		EICRA, dummy
	
	ldi		dummy, (1 << 1 | 1 << 0)
	out		EIMSK, dummy
		
	; config de puertos pd6 como salida y pd2 y pd3 como entrada
	ldi		dummy, (1 << 6); pd6 como salida y demas entrada
	out		DDRD, dummy

	; config inicial del timer0
	ldi		dummy, 128
	out		OCR0A, dummy ; inicio a aprox 50%
	ldi		dummy, (1 << 7| 1 << 1 | 1 << 0) ;toggle OCR0A +fastpwm mode3
	out		TCCR0A, dummy
	ldi		dummy, (1 << 0) ;no prescaler, max freq y wgm2=0
	out		TCCR0B, dummy
	
	; habilito interupciones globales
	sei

main:
	ldi		cte_paso, paso

hold:
 	rjmp	hold

isr_inc:
	in		dummy, OCR0A

	cpi		dummy, brillo_maximo
	breq	max_brillo

	add		dummy, cte_paso
	out		OCR0A, dummy		

max_brillo:
	reti

isr_dec:
	in		dummy, OCR0A
	cpi		dummy, brillo_minimo
	breq	min_brillo

	sub		dummy, cte_paso
	out		OCR0A, dummy

min_brillo:
	reti
