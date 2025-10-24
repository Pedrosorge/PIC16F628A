; ======================================================
;  Programa: Eco Serial (USART) - PIC16F873A
;  Autor: ChatGPT
;  Descrição: Recebe um byte via UART e devolve o mesmo
;  Data: 2025
; ======================================================

        LIST      P=16F873A
        INCLUDE   <P16F873A.INC>
        __CONFIG  _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF & _BODEN_ON

; ------------------------------------------------------
; Definições
; ------------------------------------------------------
#define _XTAL_FREQ 4000000

        CBLOCK 0x20
temp        ; variável temporária
        ENDC

; ------------------------------------------------------
; Inicialização
; ------------------------------------------------------
        ORG 0x00
        GOTO INICIO

; ------------------------------------------------------
; Rotina Principal
; ------------------------------------------------------
INICIO:
        ; Configura pinos RC6 (TX) e RC7 (RX)
        BSF     STATUS, RP0        ; Banco 1
        MOVLW   b'10000000'        ; RC7 = entrada, RC6 = saída
        MOVWF   TRISC
        BCF     STATUS, RP0        ; Banco 0

; ------------------------------------------------------
; Inicializa USART
; ------------------------------------------------------
        ; Baud rate = 9600 @ 4MHz => SPBRG = 25, BRGH=1
        MOVLW   .25
        MOVWF   SPBRG

        BSF     TXSTA, BRGH        ; Alta velocidade
        BCF     TXSTA, SYNC        ; Modo assíncrono
        BSF     RCSTA, SPEN        ; Habilita serial (RC7/RX, RC6/TX)
        BSF     RCSTA, CREN        ; Habilita recepção contínua
        BSF     TXSTA, TXEN        ; Habilita transmissão

; ------------------------------------------------------
; Loop principal: eco serial
; ------------------------------------------------------
MAIN_LOOP:
        CALL    RX_BYTE            ; Lê byte recebido
        MOVWF   temp               ; Guarda byte em temp
        MOVF    temp, W
        CALL    TX_BYTE            ; Envia byte de volta
        GOTO    MAIN_LOOP

; ------------------------------------------------------
; Sub-rotina RX_BYTE - Lê um byte recebido
; Saída: W = dado recebido
; ------------------------------------------------------
RX_BYTE:
        BTFSS   PIR1, RCIF         ; Dado recebido?
        GOTO    RX_BYTE            ; Espera até RCIF=1
        MOVF    RCREG, W           ; Lê byte recebido
        RETURN

; ------------------------------------------------------
; Sub-rotina TX_BYTE - Envia byte (W contém dado)
; ------------------------------------------------------
TX_BYTE:
        BTFSS   PIR1, TXIF         ; Pronto p/ transmitir?
        GOTO    TX_BYTE            ; Espera até TXIF=1
        MOVWF   TXREG              ; Envia dado
        RETURN

; ------------------------------------------------------
; Fim do programa
; ------------------------------------------------------
        END
