 LIST P=16F628A
#INCLUDE <P16F628A.INC>

    __CONFIG _BODEN_ON & _CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON & _XT_OSC

TIQUES EQU 0x20 ; Contador do LED
TIQUES_T EQU 0x21 ; Valor de tiques atual
AUX EQU 0x22 ; Auxiliar para verificação do byte recebido
BAUD_9600   EQU 25      ; SPBRG value for 9600 baud @ 4MHz

; Reset vector
    ORG 0x0000
    GOTO INICIO

; Dummy interrupt vector (no interrupts used)
    ORG 0x0004
        BCF INTCON, T0IF ; Apaga o bit de flag de interrupção do INTCON

        MOVLW D'131'
        MOVWF TMR0 ; TMR0 = 131 

        DECFSZ TIQUES,1 ; Decrementa TIQUES e se o resultado for 0 ele pula a próxima linha
        GOTO FIM_INTERR

        BANKSEL PORTB
        MOVLW B'10000000'
        XORWF PORTB,1 ; Altera o estado do RB7
        MOVF TIQUES_T,W
        MOVWF TIQUES ; Redefine a variável TIQUES

FIM_INTERR:
        RETFIE ; Retorna da interrupção   

; Main program
INICIO:
    ;-------------------------
    ; Configure ports
    ;-------------------------
    BANKSEL TRISB       
    MOVLW B'00000110'     ; RB2 = RX input, RB1 = TX output
    MOVWF TRISB
    MOVLW BAUD_9600
    MOVWF SPBRG           ; Set baud rate

    ;-------------------------
    ; USART setup
    ;-------------------------
	MOVLW B'00100110'
	MOVWF TXSTA
	
	BANKSEL RCSTA
	MOVLW B'10010000'
	MOVWF RCSTA
    
    ; INTERRUPÇÃO
    BANKSEL OPTION_REG
    MOVLW B'10000101'   
    MOVWF OPTION_REG ; Define os bits de OPITON_REG para configurar o clock do próprio PIC como fonte da interrupção além de definir o divisor(PRESCALER) como sendo 64

    BANKSEL TMR0
    MOVLW D'131'
    MOVWF TMR0 ; TMR0 = 131

    BANKSEL INTCON
    MOVLW B'10100000'
    MOVWF INTCON; Define os bits de INTCON para definir corretamente as interrupções 

    MOVLW D'15'
    MOVWF TIQUES_T
    MOVWF TIQUES 

    ; Wait for a byte to be received
RECEBER_BYTE:
    BTFSS PIR1, RCIF      ; RX flag
    GOTO RECEBER_BYTE
    MOVF RCREG, W         ; Read received byte

    MOVWF AUX

    ; Verificar qual byte foi recebido
    MOVLW D'1'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 1?
    GOTO DEU_UM ; SIM
    ;NÃO
    MOVLW D'2'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 2?
    GOTO DEU_DOIS;SIM
    ;NÃO
    MOVLW D'3'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 3?
    GOTO DEU_TRES;SIM
    ;NÃO
    MOVLW D'4'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 4?
    GOTO DEU_QUATRO;SIM
    GOTO RECEBER_BYTE;NÃO

DEU_UM:
    MOVLW D'15'
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_DOIS:
    MOVLW D'31'
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_TRES:
    MOVLW D'62'
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_QUATRO:
    MOVLW D'125'
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE


    ; Wait until transmitter is ready
TRANSMITIR_BYTE:
    BTFSS PIR1, TXIF      ; TX flag
    GOTO TRANSMITIR_BYTE
    MOVF TIQUES_T,W
    MOVWF TXREG           ; Echo byte
    GOTO RECEBER_BYTE

    END