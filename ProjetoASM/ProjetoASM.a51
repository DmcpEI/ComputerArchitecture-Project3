; Displays de 7 segmentos
D1 EQU P1
D2 EQU P2

; Variaveis
TempoInicial EQU 50 ; Tempo inicial em segundos
TempoConta EQU 20   ; Conjunto de 20 interrupcoes para contar 0,1 segundo
segundo EQU 200     ; Conjunto de 200 interrupcoes para contar 1 segundo

; O valor máximo da contagem de tempo é "FF + 1" = 256 microsegundos (Timer no modo 2 tem 8 bits)
; Um ciclo máquina tem 6 estados e cada estado tem 2 períodos do oscilador, logo 12 períodos
; Período = 1/12*(10^6) = 1/12 microsegundos, 1 ciclo máquina = 12*Período = 12*(1/12) = 1 microsegundo
; 250 microsegundos : 256-250 = 6 = 6 microsegundos (Sendo 06 -> TH0 e 06 -> TL0)
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
Segmentos:            
    DB  0x3F, 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0xBF, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1

; Funcao principal
CSEG AT 0000H
    JMP main

; Interrupção externa 0
CSEG AT 0003H
    JMP External0_Handler

; Interrupção timer 0
CSEG AT 000BH
    JMP Timer0_Handler

; Interrupção externa 1
CSEG AT 0013H
    JMP External1_Handler

CSEG AT 0050H

; Programa principal
; Inicializa o sistema e entra no loop infinito
main:
    CALL Init                           ; Inicializa o sistema
main_loop:
    CALL displaySegundos                ; Mostra os segundos atuais no display
	
    CJNE R2, #0, CheckResposta          ; Verifica se R2 (segundos iniciais) é diferente de 0
	
    CALL semResposta                    ; Chama semResposta se segundosIniciais <= 0
    JMP main_loop                       ; Continua o loop
CheckResposta:
    MOV A, R3                           ; Verifica se respondeu == 1
    JZ main_loop                        ; Se respondeu == 0, continua o loop
	
    CJNE R2, #TempoInicial, CheckMostraInformacao      ; Verifica se segundosIniciais < TempoInicial
	
    JMP main_loop                       ; Continua o loop
CheckMostraInformacao:
    CALL mostraInformacao               ; Chama mostraInformacao se respondeu e segundosIniciais < TempoInicial
    JMP main_loop                       ; Continua o loop

Init:
    ; Inicialização do sistema
    MOV R0, #0                          ; Inicializa registrador clicouB1 com 0
    MOV R1, #0                          ; Inicializa registrador conta com 0
    MOV R2, #TempoInicial               ; Inicializa segundosIniciais com TempoInicial
    MOV R3, #0                          ; Inicializa registrador respondeu com 0
    MOV R4, #0                          ; Inicializa registrador resposta com 0

    ; Configurações iniciais e habilitação das interrupções
    MOV IE, #87H                        ; EA=1, ET1=0, EX1=1, ET0=1 e EX0=1 -> IE=10000111
    MOV IP, #00H                        ; IP = 0
	
    ; Configuração Registro TMOD
    MOV TMOD, #00000010b                ; Define o timer 0 no modo 2 (8 bits - auto reload) 
	
    MOV TL0, #TempoL0                   ; Inicializa TL0
    MOV TH0, #TempoH0                   ; Inicializa TH0
	
    CLR TR0                             ; Inicializa TR0 desligado
    SETB IT0                            ; Habilita interrupção externa 0
    SETB IT1                            ; Habilita interrupção externa 1
    RET
		
; Tratamento de interrupcao externa 0
External0_Handler:
    CJNE R0, #0, External0_Clicked      ; Verifica se clicouB1 (R0) está setado
    JMP External0_NotClicked            ; Se clicouB1 (R0) não está setado, salta para External0_NotClicked
External0_Clicked:
    CLR TR0                             ; Timer0 para de contar o tempo
    MOV R2, #TempoInicial               ; Reinicia segundosIniciais (R2)
    MOV R1, #0                          ; Reinicia conta (R1)
    MOV R0, #0                          ; Reinicia clicouB1 (R0)
    RETI
External0_NotClicked:
    SETB TR0                            ; Timer0 começa a contar o tempo
    MOV R0, #1                          ; Seta clicouB1 (R0)
    RETI

; Tratamento de interrupcao do timer 0
Timer0_Handler:
    INC R7                              ; Incrementa o contador para 20 interrupções
    CJNE R7, #20, Timer0_End            ; Se R7 não for igual a 20, salta para Timer0_End

    INC R1                              ; Incrementa R1 a cada 20 interrupções
    MOV R7, #0                          ; Reinicia o contador

    CJNE R3, #0, Timer0_End             ; Se respondeu for diferente de zero, salta para Timer0_End
    CJNE R1, #TempoConta, Timer0_End    ; Se conta (R1) for diferente de TempoConta, salta para Timer0_End

    DEC R2                              ; Decrementa segundosIniciais (R2)
    MOV R1, #0                          ; Reinicia conta (R1)
Timer0_End:
    RETI

; Tratamento de interrupcao externa 1
External1_Handler:
    CJNE R2, #TempoInicial, SecondsNotZero  ; Verifica se segundosIniciais (R2) é diferente de TempoInicial
    CJNE R2, #0, SecondsNotZero         ; Verifica se segundosIniciais (R2) é diferente de 0
    JMP External1_End                   ; Se segundosIniciais (R2) for igual a 0 e difrente do TempoInicial, salta para External1_End
SecondsNotZero:
    JNB BA, AnswerA                     ; Se BA for pressionado (0), define resposta como 1
    JNB BB, AnswerB                     ; Se BB for pressionado (0), define resposta como 2
    JNB BC, AnswerC                     ; Se BC for pressionado (0), define resposta como 3
    JNB BD, AnswerD                     ; Se BD for pressionado (0), define resposta como 4
    JMP External1_Handler               ; Se nenhum botão foi pressionado, volta para o início do loop
AnswerA:
    MOV R3, #1                          ; Define respondeu (R3) como 1
    MOV R4, #1                          ; Define resposta (R4) como 1
    JMP External1_End                   ; Salta para External1_End
AnswerB:
    MOV R3, #1                          ; Define respondeu (R3) como 1
    MOV R4, #2                          ; Define resposta (R4) como 2
    JMP External1_End                   ; Salta para External1_End
AnswerC:
    MOV R3, #1                          ; Define respondeu (R3) como 1
    MOV R4, #3                          ; Define resposta (R4) como 3
    JMP External1_End                   ; Salta para External1_End
AnswerD:
    MOV R3, #1                          ; Define respondeu (R3) como 1
    MOV R4, #4                          ; Define resposta (R4) como 4
    JMP External1_End                   ; Salta para External1_End
External1_End:
    RETI                                ; Retorna da interrupção externa 1

; Função para mostrar números nos dois displays de 7 segmentos
; Argumentos: Caracter do display 1 em R5, Caracter do display 2 em R6
display:
    MOV DPTR, #Segmentos                ; Carrega o endereço do array Segmentos

    MOV A, R5                           ; Pega num1
    MOVC A, @A+DPTR                     ; Carrega Segmentos[num1]
    MOV P1, A                           ; Define D1

    MOV A, R6                           ; Pega num2
    MOVC A, @A+DPTR                     ; Carrega Segmentos[num2]
    MOV P2, A                           ; Define D2

    RET

; Função para mostrar segundos nos dois displays de 7 segmentos
; Argumento: Segundos em R2
displaySegundos:
    MOV A, R2                           ; Pega segundos
    MOV B, #10                          ; Divide por 10
    DIV AB                              ; A = segundos / 10, B = segundos % 10

    INC A                               ; dezenas + 1
    MOV R5, A                           ; Passa num1 para o display

    MOV A, B                            ; unidades
    ADD A, #8                           ; unidades + 8
    MOV R6, A                           ; Passa num2 para o display

    CALL display                        ; Mostra nos displays   
    RET

; Função para indicar ausência de resposta e tempo final
semResposta:
    MOV R1, #0                          ; Reinicia conta (R1)
    MOV R3, #1                          ; Define respondeu (R3) como 1

    MOV R5, #1                          ; Atribui a R5 o valor para 0.
    MOV R6, #8                          ; Atribui a R6 o valor para 0
    CALL display                        ; Mostra o 0.0      

    SETB TR0                            ; Inicia Timer0
semResposta_Loop:
    CJNE R1, #segundo, NoTimeout        ; Verifica se conta == segundo
    MOV R5, #0                          ; Atribui a R5 o valor para -.
    MOV R6, #7                          ; Atribui a R6 o valor para -         
    CALL display                        ; Mostra o -.-
    CLR TR0                             ; Para Timer0
NoTimeout:
    JB B1, semResposta_Loop             ; Loop enquanto B1 (P3.2) está alto (não pressionado)

    MOV R1, #0                          ; Reinicia conta (R1)         
    MOV R3, #0                          ; Define respondeu (R3) como 0
    RET

; Função para mostrar informação no display, que neste caso e a opção escolhida e os segundos restantes
mostraInformacao:
    CLR TR0                             ; Para Timer0
    MOV B, #0                           ; Define opcao (B) para 0
    MOV R1, #0                          ; Reinicia conta (R1)
    SETB TR0                            ; Inicia Timer0
mostraInformacao_Loop:
    JNB B1, mostraInformacao_Fim        ; Sai do loop se B1 (P3.2) for pressionado
    
    CJNE R1, #segundo, mostraInformacao_Loop    ; Verifica se conta == segundo

    MOV A, B                            ; Pega opcao         
    CJNE A, #0, DisplayOption           ; Se opcao não é 0, mostra a opção senao mostra os segundos
DisplaySeconds:
    CALL displaySegundos                ; Mostra os segundos

    MOV B, #1                           ; Define opcao para 1
    MOV R1, #0                          ; Reinicia conta (R1)
    JMP mostraInformacao_Loop           ; Continua o loop
DisplayOption:
    MOV R5, #0                          ; Atribui a R5 o valor para -.
    MOV A, R4                           ; Pega resposta
    ADD A, #17                          ; A = resposta + 17
    MOV R6, A                           ; Atribui a R6 o valor para a resposta

    CALL display                        ; Mostra a opção escolhida

    MOV B, #0                           ; Define opcao para 0
    MOV R1, #0                          ; Reinicia conta (R1)
    JMP mostraInformacao_Loop           ; Continua o loop
mostraInformacao_Fim:
    CLR TR0                             ; Para Timer0
    MOV R1, #0                          ; Reinicia conta (R1)
    MOV R3, #0                          ; Reinicia respondeu (R3)
    RET

END                                     ; Fim do programa
