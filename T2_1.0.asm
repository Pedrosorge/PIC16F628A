;#INCLUDE <P16F873A.INC>    
;__CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#INCLUDE   <P16F877A.INC>
__CONFIG  _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _LVP_OFF & _CP_OFF

TIQUES EQU 0x20 ; Contador do LED que decrementa cada vez que entra na interrupção
TIQUES_T EQU 0x21 ; Valor fixo de tiques para o valor recebido
AUX EQU 0x22 ; Auxiliar para verificação do valor do byte recebido
DELAY EQU 0x23 ; Auxiliar para fazer delays
VALOR_SINAL EQU 0x24 ; Armazena os 2 bits mais significativos do sinal


    ORG 0x0000
    	GOTO INICIO

	;-----------------------
	; Rotina da interrupção
	;-----------------------
    ORG 0x0004		
        BCF INTCON, T0IF ; Apaga o bit de flag de interrupção do INTCON

        MOVLW D'131'
        MOVWF TMR0

        DECFSZ TIQUES,1 ; Decrementa TIQUES e se o resultado for 0 ele pula a próxima linha
        GOTO FIM_INTERR

        BANKSEL PORTB
        MOVLW B'10000000'
        XORWF PORTB,1 ; Altera o estado do RB7
        MOVF TIQUES_T,W
        MOVWF TIQUES ; Redefine a variável TIQUES

FIM_INTERR:
        RETFIE ; Retorna da interrupção   


INICIO:
    ;------------------------------------
    ; Configuração dos registradores I/O
    ;------------------------------------
    BANKSEL TRISB       
    CLRF TRISB    ; Todas as portas RB são setadas como saída
 	
	BANKSEL PORTB 
	CLRF PORTB	; Todas as portas RB iniciam desligadas

	BANKSEL TRISC       
    MOVLW B'10000000'	; RC7 = RX input, RC6 = TX output
    MOVWF TRISC

	;--------------------------------------
    ; Configuração dos registradores USART 
    ;--------------------------------------
	BANKSEL SPBRG
    MOVLW d'25' ; Define que serão transmitidos 9600 bytes/segundo
    MOVWF SPBRG           

	BANKSEL TXSTA
	MOVLW b'00100100'
	MOVWF TXSTA
	
	BANKSEL RCSTA
	MOVLW b'10010000'
	MOVWF RCSTA
    
	;-----------------------------------------------
    ; Configuração dos registradores da interrupção 
    ;-----------------------------------------------
    BANKSEL OPTION_REG
    MOVLW B'10000101'   
    MOVWF OPTION_REG 

    BANKSEL TMR0
    MOVLW D'131' ; Valor escolhido para que sejam geradas 125 interrupções por segundo
    MOVWF TMR0 

    BANKSEL INTCON
    MOVLW B'10100000'
    MOVWF INTCON 
	
	;--------------------------------------------------------
	; Inicializando para o LED poiscar a cada 0.125 segundos 
	;--------------------------------------------------------
    MOVLW D'15'
    MOVWF TIQUES_T
    MOVWF TIQUES 
    
    ;---------------------
	; Configuração do ADC
	;---------------------
    BANKSEL ADCON0 
	MOVLW B'01000001'
	MOVWF ADCON0
	
	BANKSEL ADCON1 
	MOVLW B'10000000'
	MOVWF ADCON1
	    

;------------------------------------------------------------
; Rotina para esperar um byte e verificar o valor recebido
;------------------------------------------------------------
RECEBER_BYTE:
	BANKSEL PIR1
    BTFSS PIR1, RCIF      ; Verifica a flag RCIF para verificar se chegou algum byte
    GOTO RECEBER_BYTE	

	BANKSEL RCREG
    MOVF RCREG, W         ; Lê o byte recebido
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

	MOVLW D'5'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 5?
    GOTO DEU_CINCO;SIM
    GOTO RECEBER_BYTE;NÃO

DEU_UM:
    MOVLW D'15' ; Valor equivalente à 0.125 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_DOIS:
    MOVLW D'31' ; Valor equivalente à 0.25 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_TRES:
    MOVLW D'62' ; Valor equivalente à 0.5 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

DEU_QUATRO:
    MOVLW D'125' ; Valor equivalente à 1 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE
    
DEU_CINCO:
    GOTO CONVERTER_SINAL
ANALISAR_SINAL:
	; Verificar valor lido no ADC
	MOVLW 0X11
	XORWF VALOR_SINAL, 0
	BTFSS STATUS, Z ; Os bits mais significantes são 11? 
	GOTO UU; SIM
	; NÃO
	MOVLW 0X10
	XORWF VALOR_SINAL, 0
	BTFSS STATUS, Z ; Os bits mais significantes são 10? 
	GOTO UZ; SIM
	; NÃO
	MOVLW 0X01
	XORWF VALOR_SINAL, 0
	BTFSS STATUS, Z ; Os bits mais significantes são 01? 
	GOTO ZU; SIM
	GOTO ZZ; NÃO (ENTÃO É 00)
	
UU:
	MOVLW D'12' ; Valor equivalente à 0.1 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

UZ:
	MOVLW D'20' ; Valor equivalente à 0.16 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

ZU:
	MOVLW D'30' ; Valor equivalente à 0.24 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE

ZZ:
	MOVLW D'40' ; Valor equivalente à 0.32 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
    GOTO TRANSMITIR_BYTE




;--------------------------------------
; Rotina para enviar o byte recebido 
;--------------------------------------
TRANSMITIR_BYTE:
	BANKSEL PIR1
    BTFSS PIR1, TXIF      ; Verifica se a flag TXIF está setada para saber se o buffer de transmissão está livre
    GOTO TRANSMITIR_BYTE
    MOVF TIQUES_T,W		

	BANKSEL TXREG
    MOVWF TXREG           ; Envia byte
    GOTO RECEBER_BYTE
    
    
;--------------------------------
; Rotina para converter um sinal
;--------------------------------
CONVERTER_SINAL:
	;Delay de N uS / Delay deve ser >= 2*Tad / ;Tad = 8*Tosc = 8*250ns (P/ osc de 4MHz) = 2uS
	MOVLW D'200'
	MOVWF DELAY
DLY1: 
	NOP
	DECFSZ DELAY,1
	GOTO DLY1
	NOP 

	BANKSEL ADCON0
	BSF ADCON0,2 ;GoDone=1 start conversion
WAD1: 
	BTFSC ADCON0,2 ;IS THE CONVERSION DONE (bit=1) ?
	GOTO WAD1 ;NO (The bit is 0), THEN TESTE AGAIN
	MOVF ADRESH,W ;READ UPPER 2 BITS
	MOVWF VALOR_SINAL 
	
	MOVLW D'200'
	MOVWF DELAY
DLY: 
	NOP
	DECFSZ DELAY,1
	GOTO DLY
	GOTO ANALISAR_SINAL


END
