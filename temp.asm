;Pedro da Costa Sorge
;RA: 251020193
;Turma: BCC 024
;Data: 01/10/2025

#INCLUDE <P16F628A.INC> 
__CONFIG _BODEN_ON & _CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON & _XT_OSC

;Declaração de varáveis
TIQUES EQU 0x20 ; Contador do LED

;Inicio do código
    ORG 0x0
        GOTO INICIO

;Rotina da Interrupção
    ORG 0x4 
        BCF INTCON, T0IF ; Apaga o bit de flag de interrupção do INTCON

        MOVLW D'131'
        MOVWF TMR0 ; TMR0 = 131 

		DECFSZ TIQUES,1 ; Decrementa TIQUES e se o resultado for 0 ele pula a próxima linha
        GOTO FIM_INTERR

		BANKSEL PORTB
        MOVLW B'1000000'
        XORWF PORTB,1 ; Altera o estado do RB7
        MOVLW D'1000'
        MOVWF TIQUES ; Redefine a variável TIQUES

FIM_INTERR:
        RETFIE ; Retorna da interrupção   

INICIO:
        BANKSEL OPTION_REG
        MOVLW B'10000010'   
        MOVWF OPTION_REG ; Define os bits de OPITON_REG para configurar o clock do próprio PIC como fonte da interrupção além de definir o divisor(PRESCALER) como sendo 64

        BANKSEL TMR0
        MOVLW D'131'
        MOVWF TMR0 ; TMR0 = 131

        BANKSEL INTCON
        MOVLW B'10100000'
        MOVWF INTCON; Define os bits de INTCON para definir corretamente as interrupções 

		MOVLW D'1000'
        MOVWF TIQUES

        BANKSEL TRISB
 		CLRF TRISB; Define todas as portas RB como de output
       
        BANKSEL PORTB
        CLRF PORTB; Define o estado incializa ds LEDs como apagados

        GOTO $; Loop infinito

    END
