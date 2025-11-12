; Arthur Portella (RA: 241025419) 
; Pedro Sorge (RA: 251020193)
; 12/11/2025
; Trabalho Timer-Serial-ADC
; Programa que oscila um LED no pino RB7 com frequência variável, de acordo com um valor recebido via comunicação 
; serial ou conforme a leitura analógica feita no canal AN0 do conversor ADC.

#INCLUDE   <P16F877A.INC>
__CONFIG  _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _LVP_OFF & _CP_OFF

TIQUES EQU 0x20 ; Contador do LED que decrementa cada vez que entra na interrupção
TIQUES_T EQU 0x21 ; Valor fixo de tiques para o valor recebido
AUX EQU 0x22 ; Auxiliar para verificação do valor do byte recebido
DELAY EQU 0x23 ; Auxiliar para fazer delays
VALOR_SINAL_H EQU 0x24 ; Armazena os 2 bits mais significativos do sinal
VALOR_SINAL_L EQU 0x25  ; Armazena os 8 bits menos significativos do sinal
BUFFER_ENVIO EQU 0x26 ; Variàvel onde se armazena um valor que será enviado via comunicação serial

    ORG 0x0000
    	GOTO INICIO

	;-----------------------
	; Rotina da interrupção
	;-----------------------
    ORG 0x0004		
        BCF INTCON, T0IF ; Apaga o bit de flag de interrupção do INTCON

        MOVLW D'131' ; Recarrega TMR0 para gerar 125 interrupções/seg
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
	MOVLW b'00100100' ; bit 6: TX9 = 0desabilita o uso do nono bit
					  ; bit 5: TXEN = 1 habilita a trinsmissão
				      ; bit 4: SYNC = 0 modo assíncrono
					  ; bit 2: BRGH = 1 alta velocidade de transmissão
					  ; bit 1: TRMT = 0 define o registrador TSR como cheio inicialmente(só funcionou assim)
	MOVWF TXSTA
	
	BANKSEL RCSTA
	MOVLW b'10010000' ; bit 7: SPEN = 1 ativa a porta serial
					  ; bit 6: RX9 = 0 habilita a recebção de 8 bits
					  ; bit 4: CREN = 1 habilita o recebimento contínuo dos bytes
					  ; bit 3: ADDEN = 0 desativa a detecção de endereço
					  ; bit 2: FERR = 0 sem erro de enquadramento
   					  ; bit 1: OERR = 0 indica que não há erro de Overrun
	MOVWF RCSTA
    
	;-----------------------------------------------
    ; Configuração dos registradores da interrupção 
    ;-----------------------------------------------
    BANKSEL OPTION_REG
    MOVLW B'10000101' ; bit 5: TOCs = 0, o clock é 4Mhz
					  ; bit 3: PSA = 0, o prescaler é associado ao Timer
					  ; bits 2,1,0: Prescaler = 64   
    MOVWF OPTION_REG 

    BANKSEL TMR0
    MOVLW D'131' ; Valor escolhido para que sejam geradas 125 interrupções por segundo
    MOVWF TMR0 

    BANKSEL INTCON
    MOVLW B'10100000' ; bit 7: GIE = 1, habilita individualmente todas as interrupções
					  ; bit 5: T0IE = 1, habilita a interrupção do Timer
					  ; bit 2: T0IF = 0, flag de interrupção do Timer (desativar por software).
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
	MOVLW B'01000001' ; bit 7,6: selecionam o clock do AD (01 = FOSC/8)
					  ; bit 5,4,3: selecionam o canal ou entrada de conversão (000 = canal 0, (RA0/AN0))
                      ; bit 2: GO/DONE = 0, o AD não está efetuando conversões
					  ; bit 1: ADON = 1, o AD é ativado
	MOVWF ADCON0
	
	BANKSEL ADCON1 
	MOVLW B'10000000' ; bit 7: ADFM = 1, determina o formato de ajuste do dado numérico dos 10 bits saída para a direita
					  ; bit 3,2,1,0: definem todas as portas RA como analógica e VDD e VSS como os valores de referência
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
	;NÃO
	MOVLW D'5'
    SUBWF AUX,0;
    BTFSC STATUS,Z; AUX == 5?
    GOTO DEU_CINCO;SIM
    GOTO RECEBER_BYTE;NÃO

DEU_UM:
    MOVLW D'15' ; Valor equivalente à 0.125 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

DEU_DOIS:
    MOVLW D'31' ; Valor equivalente à 0.25 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

DEU_TRES:
    MOVLW D'62' ; Valor equivalente à 0.5 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

DEU_QUATRO:
    MOVLW D'125' ; Valor equivalente à 1 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE
    
DEU_CINCO:
    CALL CONVERTER_SINAL

ANALISAR_SINAL:
	; Verificar valor lido no ADC
	MOVLW D'0'
	XORWF VALOR_SINAL_H, 0
	BTFSS STATUS, Z ; Os bits mais significativos são 0(00)? 
	GOTO UM; NÃO
	; SIM
	MOVF VALOR_SINAL_H,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits mais significativos do sinal que estão no BUFFER_ENVIO
	
	MOVF VALOR_SINAL_L,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits menos significativos do sinal que estão no BUFFER_ENVIO

	MOVLW D'12' ; Valor equivalente à 0.10 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE
	
UM:
	MOVLW D'1'
	XORWF VALOR_SINAL_H, 0
	BTFSS STATUS, Z ; Os bits mais significativos são 1(01)?  
	GOTO DOIS; NÃO
	;SIM
	MOVF VALOR_SINAL_H,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits mais significativos do sinal que estão no BUFFER_ENVIO
	
	MOVF VALOR_SINAL_L,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits menos significativos do sinal que estão no BUFFER_ENVIO

	MOVLW D'20' ; Valor equivalente à 0.16 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

DOIS:
	MOVLW D'2'
	XORWF VALOR_SINAL_H, 0
	BTFSS STATUS, Z ; Os bits mais significativos são 2(10)? 
	GOTO TRES; NÃO
	;SIM
	MOVF VALOR_SINAL_H,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits mais significativos do sinal que estão no BUFFER_ENVIO
	
	MOVF VALOR_SINAL_L,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits menos significativos do sinal que estão no BUFFER_ENVIO

	MOVLW D'30' ; Valor equivalente à 0.24 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

TRES:
	MOVF VALOR_SINAL_H,W
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE ; Imprime os bits mais significativos do sinal que estão no BUFFER_ENVIO
	
	MOVF VALOR_SINAL_L,W ; Imprime os bits menos significativos do sinal que estão no BUFFER_ENVIO
	MOVWF BUFFER_ENVIO
	CALL TRANSMITIR_BYTE

	MOVLW D'40' ; Valor equivalente à 0.32 segundo
    MOVWF TIQUES
    MOVWF TIQUES_T
	MOVWF BUFFER_ENVIO
    CALL TRANSMITIR_BYTE
	GOTO RECEBER_BYTE

;--------------------------------------
; Rotina para enviar o byte recebido 
;--------------------------------------
TRANSMITIR_BYTE:
	BANKSEL PIR1
    BTFSS PIR1, TXIF      ; Verifica se a flag TXIF está setada para saber se o buffer de transmissão está livre
    GOTO TRANSMITIR_BYTE
    MOVF BUFFER_ENVIO,W		

	BANKSEL TXREG
    MOVWF TXREG           ; Envia byte
    RETURN
    
    
;--------------------------------
; Rotina para converter um sinal
;--------------------------------
CONVERTER_SINAL:
	;Delay de N uS / Delay deve ser >= 2*Tad / ;Tad = 8*osc = 8*250ns (P/ osc de 4MHz) = 2uTS
	BANKSEL ADCON0
	MOVLW D'200'
	MOVWF DELAY
DLY1:
	NOP
	DECFSZ DELAY,1
	GOTO DLY1
	NOP ;--------- BANK0
	BSF ADCON0,2 ;GoDone=1 start conversion
WAD1: 
	BTFSC ADCON0,2 ;IS THE CONVERSION DONE (bit=1) ?
	GOTO WAD1 ;NO (The bit is 0), THEN TESTE AGAIN

	BANKSEL ADRESH
	MOVF ADRESH,W ;READ UPPER 2 BITS
	MOVWF VALOR_SINAL_H 

	BANKSEL ADRESL
	MOVF ADRESL,W ;READ LOWER 8 BITS

	BANKSEL VALOR_SINAL_L
	MOVWF VALOR_SINAL_L

	MOVLW D'200'
	MOVWF DELAY
DLY: 
	NOP
	DECFSZ DELAY,1
	GOTO DLY
	RETURN


END
