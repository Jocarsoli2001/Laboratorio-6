; Archivo: Lab 6
; Dispositivo: PIC16F887
; Autor: José Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Utilización de TMR1 y TMR2
; Hardware: Displays de 7 segmentos y leds
    
; Creado: 24 de Agosto, 2021
; Última modificación: 24 de agosto de 2021

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;---------------Macros-------------------------  
 REINICIAR_TMR0 MACRO
    BANKSEL	PORTA
    MOVLW	193		; Timer 0 reinicia cada 2 ms
    MOVWF	TMR0		; Mover este valor al timer 0
    BCF		T0IF		; Limpiar la bandera del Timer 0
    ENDM
    
 REINICIAR_TMR1 MACRO
    MOVLW	133		;TIMER1 HIGH = 133
    MOVWF	TMR1H
    MOVLW	163		;TIMER1 LOW = 163
    MOVWF	TMR1L
    BCF		TMR1IF
    ENDM
 
;-----------Valores globales------------------
UP	EQU 0			; Literal up = bit 0
DOWN	EQU 5			; Literal down = bit 5
;-----------Variables a utilizar---------------
PSECT udata_bank0	    ; common memory
    CONT:	    DS 1
    CONT_UNI:	    DS 1
    CONT_DECE:	    DS 1
    UNI:	    DS 1
    DECE:	    DS 1
    DISP_SELECTOR:  DS 1
    PORT:	    DS 1
    PORT1:	    DS 1
    
PSECT udata_shr	    ; common memory
    W_TEMP:	    DS 1	    ; 1 byte
    STATUS_TEMP:    DS 1	    ; 1 byte
    
PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h			    ; posición 0000h para el reset
 resetVec:  
    PAGESEL MAIN
    goto MAIN

 PSECT intVect, class=CODE, abs, delta=2
 ;------------vector interrupciones-----------------
 ORG 04h			    ; posición 0000h para interrupciones
 
 PUSH:
    MOVWF	W_TEMP
    SWAPF	STATUS, W
    MOVWF	STATUS_TEMP
 
 ISR:
    BTFSC	TMR1IF
    CALL	INT_T1
    
    BTFSC	T0IF
    CALL	INT_TMR0
    
    BTFSC	TMR2IF
    CALL	INT_T2

 POP:
    SWAPF	STATUS_TEMP, W
    MOVWF	STATUS
    SWAPF	W_TEMP, F
    SWAPF	W_TEMP, W
    RETFIE
   
 ;------------Sub rutinas de interrupción--------------
 INT_T1:
    REINICIAR_TMR1		    ; Reiniciar el Timer 0	
    INCF	CONT_UNI	    ; Incrementar el contador en variable PORT1
    
    MOVF	CONT_UNI, W	    ; Mover el valor de PORT1 a w
    SUBLW	10		    ; Realizar la resta 10 - valor en PORT1
    BTFSC	STATUS, 2	    ; Chequear si el bit 2 del registro status es 1
    CALL	INCREMENTO
    
    MOVWF	CONT_UNI, W
    CALL	TABLA
    MOVWF	UNI
    
    MOVWF	CONT_DECE, W
    CALL	TABLA
    MOVWF	DECE
    RETURN
  
 INCREMENTO:
    INCF	CONT_DECE	    ; Incrementar en 1 el valor del PORT3
    CLRF	CONT_UNI	    ; Colocar en 0 el valor del contador PORT1
    MOVWF	CONT_UNI, W	    ; Mover el valor de las unidades a W
    CALL	TABLA		    ; Llamar tabla
    MOVWF	PORTC		    ; Pasar el valor traducido a tabla
    
    MOVF	CONT_DECE, W	    ; Mover el valor de PORT3 a w
    SUBLW	6		    ; Restar 6 - valor en PORT3
    BTFSC	STATUS, 2	    ; Chequear si el bit 2 del registro status es 1
    CLRF	CONT_DECE	    ; Limpiar el contador PORT3 para reiniciar el mismo
    RETURN   
    
 INT_TMR0:
    REINICIAR_TMR0
    
    BANKSEL	PORTD
    MOVF	PORT1, W
    MOVWF	PORTD
    
    MOVF	PORT1, W
    SUBLW	1			;Chequear si PORT1 = 001
    BTFSC	STATUS, 2
    CALL	DISPLAY_UNI
    
    MOVF	PORT1, W
    SUBLW	2			;Chequear si PORT1 = 010
    BTFSC	STATUS, 2
    CALL	DISPLAY_DECE	
    
     ;MOVER EL 1 EN DISP_SELECTOR 1 POSICIÓN A LA IZQUIERDA
    BCF		STATUS, 0		;Se limpia el bit de carry
    RLF		PORT1, 1		;1 en PORT1 se corre una posición a al izquierda
    
    ;REINICIAR DISP_SELECTOR SI EL VALOR SUPERÓ EL NÚMERO DE DISPLAYS
    MOVF	PORT1, W
    SUBLW	4			; Chequear si PORT1 = 100
    BTFSC	STATUS, 2
    CALL	RESET_DISP
    
    RETURN
    
 DISPLAY_UNI:
    MOVF	UNI, W
    MOVWF	PORTC
    RETURN
    
 DISPLAY_DECE:
    MOVF	DECE, W
    MOVWF	PORTC
    RETURN
    
 RESET_DISP:
    CLRF	PORT1
    INCF	PORT1, 1
    RETURN
      
  INT_T2:
    BCF		TMR2IF
    INCF	PORT
    MOVF	PORT, W
    ANDLW	00000001
    MOVWF	PORTB
    RETURN
 
 ;---------------Código principal----------------   
    
 PSECT CODE, DELTA=2, ABS
 ORG 100H		    ;Posición para el codigo
 ;------------------Tablas-----------------------
 
 TABLA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
 ;-----------Configuración----------------
 MAIN:
    CALL	RESET_DISP
    CALL	CONFIG_IO	    ;Configuraciones de entradas y salidas
    CALL	CONFIG_RELOJ	    ;Configuración del oscilador
    CALL	CONFIG_TMR0	    ;Configuración del Timer 0
    CALL	CONFIG_TMR1
    CALL	CONFIG_TMR2
    CALL	CONFIG_INT_ENABLE   ;Configuración de interrupciones	
    
 LOOP:
   
    GOTO	LOOP
 
 ;-------------SUBRUTINAS------------------  
 CONFIG_INT_ENABLE:
    BANKSEL	TRISA
    BSF		TMR1IE		    ;INTERRUPCIÓN TMR1
    BSF		TMR2IE		    ;INTERRUPCIÓN TMR2
    
    BANKSEL	PORTA
    BSF		T0IE		    ;HABILITAR TMR0
    BCF		T0IF		    ;BANDERA DE TMR0
    
    BCF		TMR1IF		    ;BANDERA DE TMR1
    BCF		TMR2IF		    ;BANDERA DE TMR2
    
    BSF		PEIE		    ;INTERRUPCIONES PERIFÉRICAS
    BSF		GIE		    ;INTERRUPCIONES GLOBALES
    RETURN   
    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS		    ;Reloj interno
    BCF		PSA		    ;PRESCALER
    BCF		PS2 
    BCF		PS1
    BSF		PS0		    ;Prescaler = 001 = 1:4
    BANKSEL	PORTC
    REINICIAR_TMR0
    RETURN
    
 CONFIG_TMR1:
    BANKSEL	PORTC
    BCF		TMR1GE		    ;SIEMPRE CONTANDO
    BSF		T1CKPS1		    ;CONFIGURACIÓN DE PRESCALER
    BCF		T1CKPS0		    ;PRESCALER DE 1:8 - CADA 1 Hz
    BCF		T1OSCEN		    ;LOW POWER OSCILATOR OFF
    BCF		TMR1CS
    BSF		TMR1ON		    ;ENCENDER EL TMR1
    
    ;CARGAR LOS VALORES INICIALES
    REINICIAR_TMR1
    RETURN
    
 CONFIG_TMR2:
    BANKSEL	PORTA
    BSF		TOUTPS3
    BSF		TOUTPS2
    BSF		TOUTPS1
    BSF		TOUTPS0		    ;POSTCALER = 1111 = 1:16
    
    BSF		TMR2ON
    
    BSF		T2CKPS1
    BSF		T2CKPS0		    ;PRESCALER = 16
    
    BANKSEL	TRISB
    MOVLW	244
    MOVWF	PR2
    CLRF	TMR2
    BCF		TMR2IF
    
    RETURN
 
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BCF		IRCF2		    ;IRCF = 011 = 500 KHz
    BSF		IRCF1
    BSF		IRCF0
    BSF		SCS		    ;Reloj interno
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL
    CLRF	ANSEL		    ;PINES DIGITALES
    CLRF	ANSELH
    
    BANKSEL	TRISA
    CLRF	TRISA		    ;PORTA COMO SALIDA
    CLRF	TRISB		    ;PORTB COMO SALIDA
    CLRF	TRISC		    ;PORTC COMO SALIDA
    CLRF	TRISD
 
    BANKSEL	PORTA
    CLRF	PORTA
    CLRF	PORTB
    CLRF	PORTC
    CLRF	PORTD
    RETURN

    
END



