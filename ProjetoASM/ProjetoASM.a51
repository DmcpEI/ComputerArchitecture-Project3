D1 EQU P1
D2 EQU P2

TempoInicial EQU 50
TempoConta EQU 400
segundo EQU 4000

TempoH0 EQU 0x06
TempoL0 EQU 0x06

; Definições de bits
B1 EQU P3.2
Pressionado EQU P3.3
BA EQU P3.4
BB EQU P3.5
BC EQU P3.6
BD EQU P3.7

CSEG AT 0300H
; Tabela de segmentos para mostrar no display (-., 0., 1., 2., 3., 4., 5., -, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D)
segmentos:            
    DB  0x3F, 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0xBF, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1

CSEG AT 0000H
    JMP main

; interrupcao externa 0
CSEG AT 0003H
	JMP External0_Handler

; interrupcao timer 0 (5ms)
CSEG AT 000BH
	JMP Timer0_Handler

; interrupcao externa 1
CSEG AT 0013H
	JMP External1_Handler

CSEG AT 0050H
	
; Main program
; Initialize system and enter infinite loop	

main:
    ACALL Init                       ; Initialize the system

main_loop:
    ACALL displaySegundos            ; Display the current seconds
	
    MOV A, R2                        ; Check if segundosIniciais <= 0
    CJNE A, #0, CheckResposta
	
    ACALL semResposta                ; Call semResposta if segundosIniciais <= 0
    SJMP main_loop                   ; Continue the loop

CheckResposta:
    MOV A, R4                        ; Check if respondeu == 1
    JZ main_loop                     ; If respondeu == 0, continue the loop
	
    MOV A, R2                        ; Check if segundosIniciais < TempoInicial
    CJNE A, #TempoInicial, CallMostraInformacao
	
    SJMP main_loop                   ; Continue the loop

CallMostraInformacao:
    ACALL mostraInformacao           ; Call mostraInformacao if respondeu and segundosIniciais < TempoInicial
    
	SJMP main_loop                   ; Continue the loop
		
Init:
	; Inicialização do sistema aqui
    MOV R0, #0                     ; Inicializa registrador clicouB1 com 0
    MOV R1, #0                     ; Inicializa registrador conta com 0
    MOV R2, #TempoInicial          ; Inicializa segundosIniciais com TempoInicial
    MOV R3, #0                     ; Inicializa registrador respondeu com 0
    MOV R4, #0                     ; Inicializa registrador resposta com 0

	; Configurações iniciais e habilitação das interrupções
    SETB EA                        ; Habilita interrupções globais
    SETB EX0                       ; Habilita interrupção externa 0
    SETB EX1                       ; Habilita interrupção externa 1
    SETB ET0                       ; Habilita interrupção do timer 0
    MOV TMOD, #0x02                ; Timer 0 em modo 2 (8-bit auto-reload)
    MOV TL0, #TempoL0              ; Inicializa TL0
    MOV TH0, #TempoH0              ; Inicializa TH0
    CLR TR0
	RETI
		
External0_Handler:
    ; Verifica se clicouB1 (R0) está setado
    MOV A, R0
    JZ External0_NotClicked
    ; Se clicouB1 (R0) está setado
    CLR TR0                        ; Timer0 para de contar o tempo
    MOV R2, #TempoInicial          ; Reinicia segundosIniciais (R2)
    MOV R1, #0                     ; Reinicia conta (R1)
    MOV R0, #0
    RETI
External0_NotClicked:
    ; Se clicouB1 (R0) não está setado
    SETB TR0                       ; Timer0 começa a contar o tempo
    MOV R0, #1                     ; Seta clicouB1 (R0)
    RETI

Timer0_Handler:
    INC R1                        ; Incrementa conta (R1)
    MOV A, R3                     ; Verifica se respondeu (R3) é zero
    JNZ Respondeu_True            ; Se respondeu for diferente de zero, pula para Respondeu_True
    CJNE R1, #TempoConta, Timer0_Skip    ; Se conta (R1) não for igual a 400, pula para Timer0_Skip
    DEC R2                        ; Decrementa segundosIniciais (R2)
    MOV R1, #0                    ; Reinicia conta (R1)
Timer0_Skip:
    RETI
Respondeu_True:
    RETI
	
External1_Handler:
    JNB Pressionado, External1_End        ; Pula para External1_End se Pressionado for 0 (não pressionado)
    MOV A, R2                        ; Carrega segundosIniciais (R2) em A
    CJNE A, #TempoInicial, External1_End ; Pula para External1_End se segundosIniciais for diferente de TempoInicial
    MOV A, R2                        ; Carrega segundosIniciais (R2) em A novamente
    JZ External1_End                 ; Se segundosIniciais for zero, pula para External1_End
    ; Se chegou aqui, verifica as opções de resposta
    JNB BA, AnswerA                  ; Se BA for pressionado (0), define resposta como 1
    JNB BB, AnswerB                  ; Se BB for pressionado (0), define resposta como 2
    JNB BC, AnswerC                  ; Se BC for pressionado (0), define resposta como 3
    JNB BD, AnswerD                  ; Se BD for pressionado (0), define resposta como 4
    JMP External1_Handler                    ; Se nenhum botão foi pressionado, volta para o início do loop
AnswerA:
    MOV R4, #1                       ; Define respondeu (R4) como 1
    MOV R5, #1                       ; Define resposta (R5) como 1
    SJMP External1_End              ; Salta para External1_End
AnswerB:
    MOV R4, #1                       ; Define respondeu (R4) como 1
    MOV R5, #2                       ; Define resposta (R5) como 2
    SJMP External1_End              ; Salta para External1_End
AnswerC:
    MOV R4, #1                       ; Define respondeu (R4) como 1
    MOV R5, #3                       ; Define resposta (R5) como 3
    SJMP External1_End              ; Salta para External1_End
AnswerD:
    MOV R4, #1                       ; Define respondeu (R4) como 1
    MOV R5, #4                       ; Define resposta (R5) como 4
    SJMP External1_End              ; Salta para External1_End
External1_End:
    RETI                             ; Retorna da interrupção externa 1
	
; Function to display numbers on two 7-segment displays
; Arguments: num1 in R5, num2 in R6
; Assumes segmentos array starts at label `segmentos`

display:
    MOV DPTR, #segmentos            ; Load address of segmentos array

    MOV A, R5                       ; Get num1
    MOVC A, @A+DPTR                 ; Load segmentos[num1]
    MOV P1, A                       ; Set D1

    MOV A, R6                       ; Get num2
    ADD A, #8                       ; Offset for the second digit (segmentos array continues)
    MOVC A, @A+DPTR
    MOV P2, A                       ; Set D2

    RET
	
; Function to display seconds on two 7-segment displays
; Argument: num in R2

displaySegundos:
    MOV A, R2
    MOV B, #10
    DIV AB                          ; A = dezenas, B = unidades

    INC A                           ; dezenas + 1
    MOV R5, A                       ; Pass num1 to display

    MOV A, B
    ADD A, #8                       ; unidades + 8
    MOV R6, A                       ; Pass num2 to display

    ACALL display
    RET
	
; Function to indicate no response
; No arguments

semResposta:
    MOV R3, #0                      ; Reset conta (R3)
    MOV R4, #1                      ; Set respondeu (R4) to 1

    MOV R5, #1                      ; Display (1, 8)
    MOV R6, #8
    ACALL display

    SETB TR0                        ; Start Timer0

semResposta_Loop:
    MOV A, R3
    CJNE A, #segundo, NoTimeout     ; Check if conta == segundo
    MOV R5, #0                      ; Display (0, 7)
    MOV R6, #7
    ACALL display
    CLR TR0                         ; Stop Timer0

NoTimeout:
    JB B1, semResposta_Loop       ; Loop while B1 (P3.2) is high (not pressed)

    MOV R3, #0                      ; Reset conta (R3)
    MOV R4, #0                      ; Reset respondeu (R4)
    RET

; Function to show information on the display
; No arguments

mostraInformacao:
    MOV R7, #0                          ; Reset opcao (R7) to 0
    MOV R3, #0                          ; Reset conta (R3)
    SETB TR0                        ; Start Timer0

mostraInformacao_Loop:
    JB B1, mostraInformacao_Check ; Loop while B1 (P3.2) is high (not pressed)

mostraInformacao_Check:
    MOV A, R3
    CJNE A, #segundo, mostraInformacao_Loop ; Check if conta == segundo

    MOV A, R7
    JZ DisplaySeconds               ; If opcao == 0, display seconds

    MOV R5, #0
    MOV A, R5
    ADD A, #17
    MOV R6, A
    ACALL display                   ; Display (0, resposta + 17)
    MOV R7, #0                          ; Set opcao to 0
    SJMP mostraInformacao_Loop

DisplaySeconds:
    MOV A, R2
    ACALL displaySegundos           ; Display seconds
    MOV R7, #1                         ; Set opcao to 1

    MOV R3, #0                          ; Reset conta (R3)
    SJMP mostraInformacao_Loop

    CLR TR0                         ; Stop Timer0
    MOV R3, #0                          ; Reset conta (R3)
    MOV R4, #0                          ; Reset respondeu (R4)
    RET

END
