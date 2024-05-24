; Displays
D1 EQU P1
D2 EQU P2

TempoInicial EQU 50                 ; Tempo inicial em segundos
TempoConta EQU 20                   ; Conta ate 20 interrupcoes para decrementar 0.1 segundos
segundo EQU 200                     ; Conta ate 200 interrupcoes para decrementar 1 segundo

TempoH0 EQU 0x06                    ; Tempo inicial do timer 0
TempoL0 EQU 0x06                    ; Tempo inicial do timer 0 (6 microsegundos)
	
ClicouB1 EQU 40H                    ; Bit de controlo para indicar se o botao B1 foi clicado
OpcaoB1 EQU 42H                     ; Bit de controlo para indicar a opcao a fazer quando clicar no botao B1
Respondeu EQU 44H                   ; Bit de controlo para indicar se o utilizador clicou num botao de resposta

; Definicoes de portas
B1 EQU P3.2
Pressionado EQU P3.3
BA EQU P3.4
BB EQU P3.5
BC EQU P3.6
BD EQU P3.7
	
CSEG AT 0300H
; Tabela de segmentos para mostrar no display (-., 0., 1., 2., 3., 4., 5., -, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D)
Segmentos:            
    DB  0x3F, 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0xBF, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1

; Rotina Principal
CSEG AT 0000H
    JMP main

; Interrupcao externa 0
CSEG AT 0003H
	JMP External0_Handler

; Interrupcao timer 0
CSEG AT 000BH
	JMP Timer0_Handler

; Interrupcao externa 1
CSEG AT 0013H
	JMP External1_Handler

CSEG AT 0050H
	
; Rotina Principal
main:
    CALL Init                                               ; Inicializa o sistema
main_loop:
	CLR OpcaoB1                                             ; Reset OpcaoB1
    CALL displaySegundos                                    ; Mostra os segundos atuais nos displays
	
    CJNE R2, #0, CheckResposta                              ; Se segundosIniciais for diferente de 0, salta para CheckResposta
	
    CALL semResposta                                        ; Se segundosIniciais for 0, mostra o tempo final (0.0) e a resposta indefinida
    JMP main_loop                                           ; Repete o loop
CheckResposta:
    JNB Respondeu, main_loop                                ; Se não respondeu, salta para main_loop
	
    CJNE R2, #TempoInicial, CheckMostraInformacao           ; Se respondeu e segundosIniciais != TempoInicial, salta para CheckMostraInformacao 
	
    JMP main_loop                                           ; Se respondeu e segundosIniciais == TempoInicial, repete o loop
CheckMostraInformacao:
    CALL mostraInformacao                                   ; Mostra a resposta e o tempo de resposta nos displays
	JMP main_loop                                           ; Repete o loop
	
; Inicializa o sistema
Init:
    MOV R1, #0                                              ; Inicializa registrador para a conta de interrupcoes do timer0
    MOV R2, #TempoInicial                                   ; Inicializa registrador para os segundos iniciais que irao decrementar
    MOV R4, #0                                              ; Inicializa registrador resposta dada pelo utilizador
	
	CLR ClicouB1                                            ; Inicializa ClicouB1                
	CLR OpcaoB1                                             ; Inicializa OpcaoB1
	CLR Respondeu                                           ; Inicializa Respondeu

	; Configuracoes iniciais e habilitacao das interrupcoes
    MOV IE, #83H					                        ;EA=1, ET1=0, EX1=0, ET0=1 e EX0=1 -> IE=10000011
	MOV IP, #00H					                        ;IP = 0
	
	;Configuracao Registo TMOD
	MOV TMOD, #00000010b                                    ;Timer 0 no modo 2 (8 bit - auto reload) 
	
    MOV TL0, #TempoL0                                       ; Inicializa TL0 (6 microsegundos)
    MOV TH0, #TempoH0                                       ; Inicializa TH0
	
    CLR TR0                                                 ; Comeca o timer0 desligado
	SETB IT0                                                ; Habilita interrupcao externa 0
	SETB IT1                                                ; Habilita interrupcao externa 1
	RET
		
; Interrupcao externa 0
External0_Handler:
    CPL ClicouB1                                            ; Inverte ClicouB1
	JB OpcaoB1, External0_Clicked                           ; Se OpcaoB1 for 1, salta para External0_Clicked
	JMP External0_NotClicked                                ; Se OpcaoB1 for 0, salta para External0_NotClicked
External0_Clicked:
	CLR IE0                                                 ; Limpa a flag de interrupcao externa 0
	CLR EX1                                                 ; Desabilita interrupcao externa 1
    CLR TR0                                                 ; Timer0 para de contar o tempo
    MOV R2, #TempoInicial                                   ; Reinicia segundosIniciais
    MOV R1, #0                                              ; Reinicia conta
    RETI                                                    ; Retorna da interrupcao externa 0
External0_NotClicked:
	CLR EX0                                                 ; Desabilita interrupcao externa 0
	CLR IE1                                                 ; Limpa a flag de interrupcao externa 1
	SETB EX1                                                ; Habilita interrupcao externa 1
    SETB TR0                                                ; Timer0 comeca a contar o tempo
    RETI                                                    ; Retorna da interrupcao externa 0

; Interrupcao do timer 0
Timer0_Handler:
    INC R7                                                  ; Incrementa o contador de 20 interrupcoes
    CJNE R7, #20, Timer0_End                                ; Se R7 for difrente de 20, salta para Timer0_End

    INC R1                                                  ; Incrementa a conta 
    MOV R7, #0                                              ; Reinicia o contador de 20 interrupcoes

    JB Respondeu, Timer0_End                                ; Se respondeu, salta para Timer0_End
    CJNE R1, #TempoConta, Timer0_End                        ; Se conta for diferente de TempoConta, salta para Timer0_End

    DEC R2                                                  ; Decrementa os segundos iniciais
    MOV R1, #0                                              ; Reinicia a conta
Timer0_End:
    RETI                                                    ; Retorna da interrupcao do timer 0
	
	
External1_Handler:
	CLR EX1                                                 ; Desabilita interrupcao externa 1
    CJNE R2, #TempoInicial, SecondsNotZero                  ; Pula para SecondsNotZero se segundosIniciais for diferente de TempoInicial
    CJNE R2, #0, SecondsNotZero                             ; Pula para SecondsNotZero se segundosIniciais for diferente de 0
	JMP External1_End                                       ; Se segundosIniciais for 0, salta para External1_End
SecondsNotZero:
	JNB BA, AnswerA                                         ; Se BA for pressionado (0), define resposta como 1
	JNB BB, AnswerB                                         ; Se BB for pressionado (0), define resposta como 2
	JNB BC, AnswerC                                         ; Se BC for pressionado (0), define resposta como 3
	JNB BD, AnswerD                                         ; Se BD for pressionado (0), define resposta como 4
	JMP External1_Handler                                   ; Se nenhum botao foi pressionado, volta para o inicio da interrupcao
AnswerA:
    SETB Respondeu                                          ; Define Respondeu como 1
    MOV R4, #1                                              ; Define resposta (R4) como 1 (A)
    JMP External1_End                                       ; Salta para External1_End
AnswerB:
    SETB Respondeu                                          ; Define Respondeu como 1
    MOV R4, #2                                              ; Define resposta (R4) como 2 (B)
    JMP External1_End                                       ; Salta para External1_End
AnswerC:
    SETB Respondeu                                          ; Define Respondeu como 1
    MOV R4, #3                                              ; Define resposta (R4) como 3 (C)
    JMP External1_End                                       ; Salta para External1_End
AnswerD:
    SETB Respondeu                                          ; Define Respondeu como 1
    MOV R4, #4                                              ; Define resposta (R4) como 4 (D)
    JMP External1_End                                       ; Salta para External1_End
External1_End:
    RETI                                                    ; Retorna da interrupcao externa 1
	
	
; Funcao para mostrar um caracter nos displays, entre numeros de segundos e letras de resposta
; Argumentos: 
;R5 (lugar da tabela de segmetos do valor a carregar no display 1)
;R6 (lugar da tabela de segmentos do valor a carregar no display 2)
display:
    MOV DPTR, #Segmentos                                    ; Carrega o endereco da tabela de segmentos

    MOV A, R5                                               ; Obtem R5
    MOVC A, @A+DPTR                                         ; Carrega Segmentos[R5]
    MOV P1, A                                               ; Define D1

    MOV A, R6                                               ; Obtem R6
    MOVC A, @A+DPTR                                         ; Carrega Segmentos[R6]
    MOV P2, A                                               ; Define D2

    RET
	
	
; Funcao para mostrar os segundos nos displays
; Argumento:
; R2 (segundos atuais)
displaySegundos:
    MOV A, R2                                               ; Obtem R2
    MOV B, #10                                              ; Obtem o valor 10
    DIV AB                                                  ; Divide R2 por 10 (Em A fica o quociente que é as dezenas e em B o resto que é as unidades)

    INC A                                                   ; Dezenas + 1 para obter o lugar na tabela de segmentos com o valor das dezenas
    MOV R5, A                                               ; Passa o valor das dezenas para R5

	MOV A, B                                                ; Obtem B que é as unidades
    ADD A, #8                                               ; Unidades + 8 para obter o lugar na tabela de segmentos com o valor das unidades
    MOV R6, A                                               ; Passa o valor das unidades para R6

    CALL display                                            ; Mostra os segundos nos displays
    RET


; Funcao para mostrar a resposta indefinida e o tempo final nos displays
semResposta:

	CLR TR0                                                 ; Para de contar o tempo
	MOV B, #0                                               ; Reseta opcao (B) para 0
    MOV R1, #0                                              ; Reseta conta (R1) para 0
    SETB Respondeu                                          ; Define Respondeu como 1

	SETB ClicouB1                                           ; Define ClicouB1 como 1
	
	CLR IE0                                                 ; Limpa a flag de interrupcao externa 0
	SETB EX0                                                ; Habilita interrupcao externa 0
	CLR EX1                                                 ; Desabilita interrupcao externa 1

    SETB TR0                                                ; Comeca a contar o tempo
	
	MOV R5, #1                                              ; Dá o valor do lugar na tabela de segmentos para mostrar 0.
    MOV R6, #8                                              ; Dá o valor do lugar na tabela de segmentos para mostrar 0
    CALL display                                            ; Mostra 0.0 nos displays
	
semResposta_Loop:
	SETB OpcaoB1                                            ; Define OpcaoB1 como 1
    JNB ClicouB1, semResposta_Fim                           ; Se ClicouB1 for 0, salta para semResposta_Fim

    CJNE R1, #segundo, semResposta_Loop                     ; Se conta for diferente de segundo, repete o loop

	MOV A, B                                                ; Obtem a opcao
    CJNE A, #0, DisplayZero                                 ; Se opcao for diferente de 0, salta para DisplayZero

DisplayIndefinido:
	MOV R5, #0                                              ; Dá o valor do lugar na tabela de segmentos para mostrar -.
    MOV R6, #7                                              ; Dá o valor do lugar na tabela de segmentos para mostrar -
    CALL display                                            ; Mostra -.- nos displays
    MOV B, #1                                               ; Define opcao (B) como 1
    MOV R1, #0                                              ; Reseta conta (R1)
    JMP semResposta_Loop                                    ; Repete o loop

DisplayZero:
	MOV R5, #1                                              ; Dá o valor do lugar na tabela de segmentos para mostrar 0.
    MOV R6, #8                                              ; Dá o valor do lugar na tabela de segmentos para mostrar 0
    CALL display                                            ; Mostra 0.0 nos displays
	MOV B, #0                                               ; Define opcao (B) como 0
	MOV R1, #0                                              ; Reseta conta (R1)
	JMP semResposta_Loop                                    ; Repete o loop
	
semResposta_Fim:
	CLR TR0                                                 ; Para de contar o tempo
	MOV R1, #0                                              ; Reseta conta (R1)
	CLR Respondeu                                           ; Define Respondeu como 0
	RET


; Funcao para mostrar a resposta e o tempo de resposta nos displays
mostraInformacao:
	
	CLR TR0                                                 ; Para de contar o tempo
    MOV B, #0                                               ; Reseta opcao (B) para 0
    MOV R1, #0                                              ; Reseta conta (R1) para 0
	
	SETB ClicouB1	                                        ; Define ClicouB1 como 1
	
	CLR IE0                                                 ; Limpa a flag de interrupcao externa 0
	SETB EX0                                                ; Habilita interrupcao externa 0
	CLR EX1                                                 ; Desabilita interrupcao externa 1
	
    SETB TR0                                                ; Comeca a contar o tempo

mostraInformacao_Loop:
	SETB OpcaoB1                                            ; Define OpcaoB1 como 1
    JNB ClicouB1, mostraInformacao_Fim                      ; Se ClicouB1 for 0, salta para mostraInformacao_Fim

    CJNE R1, #segundo, mostraInformacao_Loop                ; Se conta for diferente de segundo, repete o loop
	
	MOV A, B                                                ; Obtem a opcao
    CJNE A, #0, DisplayOption                               ; Se opcao for diferente de 0, salta para DisplayOption
DisplaySeconds:
    CALL displaySegundos                                    ; Mostra os segundos restantes nos displays
    MOV B, #1                                               ; Define opcao (B) como 1
    MOV R1, #0                                              ; Reseta conta (R1)
    JMP mostraInformacao_Loop                               ; Repete o loop

DisplayOption:
    MOV R5, #0                                              ; Dá o valor do lugar na tabela de segmentos para mostrar -.
    MOV A, R4                                               ; Obtem a resposta
    ADD A, #17                                              ; Adiciona 17 para obter o lugar na tabela de segmentos com o valor da resposta
    MOV R6, A                                               ; Passa o valor da resposta para R6
    CALL display                                            ; Mostra a resposta nos displays
    MOV B, #0                                               ; Define opcao (B) como 0
    MOV R1, #0                                              ; Reseta conta (R1)
    JMP mostraInformacao_Loop                               ; Repete o loop

mostraInformacao_Fim:
    CLR TR0                                                 ; Para de contar o tempo
    MOV R1, #0                                              ; Reseta conta (R1)
    CLR Respondeu                                           ; Define Respondeu como 0

    RET

END
