D1 EQU P1
D2 EQU P2

TempoInicial EQU 50

TempoH0 EQU 0x06
TempoL0 EQU 0x06

; Definições de bits
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
    JMP Inicio

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
Inicio:

    JMP Init

    SJMP $                         ; Loop infinito
		
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
    CJNE R1, #400, Timer0_Skip   ; Se conta (R1) não for igual a 400, pula para Timer0_Skip
    DEC R2                        ; Decrementa segundosIniciais (R2)
    MOV R1, #0                     ; Reinicia conta (R1)
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

END
