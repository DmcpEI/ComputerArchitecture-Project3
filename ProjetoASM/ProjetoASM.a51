D1 EQU P1
D2 EQU P2

TempoInicial EQU 50
TempoConta EQU 20
segundo EQU 200

TempoH0 EQU 0x06
TempoL0 EQU 0x06
	
ClicouB1 EQU 40H
OpcaoB1 EQU 42H
Respondeu EQU 44H

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
    CALL Init                       ; Initialize the system
main_loop:
	CLR OpcaoB1
    CALL displaySegundos            ; Display the current seconds
	
    CJNE R2, #0, CheckResposta
	
    CALL semResposta                ; Call semResposta if segundosIniciais <= 0
    JMP main_loop                   ; Continue the loop
CheckResposta:
    JNB Respondeu, main_loop
	
	; Check if segundosIniciais < TempoInicial
    CJNE R2, #TempoInicial, CheckMostraInformacao
	
    JMP main_loop                   ; Continue the loop
CheckMostraInformacao:
    CALL mostraInformacao           ; Call mostraInformacao if respondeu and segundosIniciais < TempoInicial
	JMP main_loop                   ; Continue the loop
	
	
Init:
	; Inicialização do sistema
    MOV R1, #0                     ; Inicializa registrador conta com 0
    MOV R2, #TempoInicial          ; Inicializa segundosIniciais com TempoInicial
    MOV R4, #0                     ; Inicializa registrador resposta com 0
	
	CLR ClicouB1
	CLR OpcaoB1
	CLR Respondeu

	; Configurações iniciais e habilitação das interrupções
    MOV IE, #83H					;EA=1, ET1=0, EX1=0, ET0=1 e EX0=1 -> IE=10000011
	MOV IP, #00H					;IP = 0
	
	;Configuracao Registo TMOD
	MOV TMOD, #00000010b ;definir o timer 0 no modo 2 (8 bit - auto reload) 
	
    MOV TL0, #TempoL0              ; Inicializa TL0
    MOV TH0, #TempoH0              ; Inicializa TH0
	
    CLR TR0
	SETB IT0
	SETB IT1
	RET
		
		
External0_Handler:
    CPL ClicouB1
	JB OpcaoB1, External0_Clicked
	JMP External0_NotClicked
External0_Clicked:
	CLR IE0
	CLR EX1
    CLR TR0                        ; Timer0 para de contar o tempo
    MOV R2, #TempoInicial          ; Reinicia segundosIniciais (R2)
    MOV R1, #0                     ; Reinicia conta (R1)
    RETI
External0_NotClicked:
	CLR EX0
	CLR IE1
	SETB EX1
    SETB TR0                       ; Timer0 começa a contar o tempo
    RETI


Timer0_Handler:
    INC R7                               ; Increment the counter for 20 interruptions
    CJNE R7, #20, Timer0_End

    INC R1                               ; Increment R1 every 20 interruptions
    MOV R7, #0                           ; Reset the counter

    JB Respondeu, Timer0_End
    CJNE R1, #TempoConta, Timer0_End     ; If conta (R1) is not equal to TempoConta, jump to Timer0_End

    DEC R2                               ; Decrement segundosIniciais (R2)
    MOV R1, #0                           ; Reset conta (R1)
Timer0_End:
    RETI
	
	
External1_Handler:
    ;JNB Pressionado, External1_End        ; Pula para External1_End se Pressionado for 0 (não pressionado)
	CLR EX1
    CJNE R2, #TempoInicial, SecondsNotZero ; Pula para External1_End se segundosIniciais for diferente de TempoInicial
    CJNE R2, #0, SecondsNotZero
	JMP External1_End
SecondsNotZero:
	; Se chegou aqui, verifica as opções de resposta
	JNB BA, AnswerA                  ; Se BA for pressionado (0), define resposta como 1
	JNB BB, AnswerB                  ; Se BB for pressionado (0), define resposta como 2
	JNB BC, AnswerC                  ; Se BC for pressionado (0), define resposta como 3
	JNB BD, AnswerD                  ; Se BD for pressionado (0), define resposta como 4
	JMP External1_Handler                    ; Se nenhum botão foi pressionado, volta para o início do loop
AnswerA:
    SETB Respondeu
    MOV R4, #1                       ; Define resposta (R4) como 1
    JMP External1_End                ; Salta para External1_End
AnswerB:
    SETB Respondeu
    MOV R4, #2                       ; Define resposta (R4) como 2
    JMP External1_End                ; Salta para External1_End
AnswerC:
    SETB Respondeu
    MOV R4, #3                       ; Define resposta (R4) como 3
    JMP External1_End                ; Salta para External1_End
AnswerD:
    SETB Respondeu
    MOV R4, #4                       ; Define resposta (R4) como 4
    JMP External1_End                ; Salta para External1_End
External1_End:
    RETI                             ; Retorna da interrupção externa 1
	
	
; Function to display numbers on two 7-segment displays
; Arguments: num1 in R5, num2 in R6
; Assumes segmentos array starts at label `Segmentos`
display:
    MOV DPTR, #Segmentos            ; Load address of Segmentos array

    MOV A, R5                       ; Get num1
    MOVC A, @A+DPTR                 ; Load Segmentos[num1]
    MOV P1, A                       ; Set D1

    MOV A, R6                       ; Get num2
    MOVC A, @A+DPTR
    MOV P2, A                       ; Set D2

    RET
	
	
; Function to display seconds on two 7-segment displays
; Argument: num in R2 (seconds)
displaySegundos:
    MOV A, R2
    MOV B, #10
    DIV AB

    INC A                           ; dezenas + 1
    MOV R5, A                       ; Pass num1 to display

	MOV A, B
    ADD A, #8                       ; unidades + 8
    MOV R6, A                       ; Pass num2 to display

    CALL display
    RET


; Function to indicate no response
; No arguments
semResposta:

	CLR TR0
	MOV B, #0
    MOV R1, #0
    SETB Respondeu

	SETB ClicouB1
	
	CLR IE0
	SETB EX0
	CLR EX1

    SETB TR0                        ; Start Timer0
	
	MOV R5, #1                      ; Display (1, 8)
    MOV R6, #8
    CALL display
	
semResposta_Loop:
	SETB OpcaoB1
    JNB ClicouB1, semResposta_Fim

    CJNE R1, #segundo, semResposta_Loop

	MOV A, B
    CJNE A, #0, DisplayZero

DisplayIndefinido:
	MOV R5, #0                      ; Display (0, 7)
    MOV R6, #7
    CALL display
    MOV B, #1                         ; Set opcao to 1
    MOV R1, #0                        ; Reset conta (R1)
    JMP semResposta_Loop

DisplayZero:
	MOV R5, #1                      ; Display (1, 8)
    MOV R6, #8
    CALL display
	MOV B, #0
	MOV R1, #0
	JMP semResposta_Loop
	
semResposta_Fim:
	CLR TR0
	MOV R1, #0
	CLR Respondeu
	RET


; Function to show information on the display
; No arguments
mostraInformacao:
	
	CLR TR0
    MOV B, #0                        ; Reset opcao (R7) to 0
    MOV R1, #0                        ; Reset conta (R1)
	
	SETB ClicouB1	
	
	CLR IE0
	SETB EX0
	CLR EX1
	
    SETB TR0                          ; Start Timer0

mostraInformacao_Loop:
	SETB OpcaoB1
    JNB ClicouB1, mostraInformacao_Fim

    CJNE R1, #segundo, mostraInformacao_Loop ; Check if conta == segundo
	
	MOV A, B
    CJNE A, #0, DisplayOption         ; If opcao is not 0, display option
DisplaySeconds:
    CALL displaySegundos              ; Display seconds
    MOV B, #1                         ; Set opcao to 1
    MOV R1, #0                        ; Reset conta (R1)
    JMP mostraInformacao_Loop

DisplayOption:
    MOV R5, #0
    MOV A, R4
    ADD A, #17
    MOV R6, A
    CALL display                      ; Display the chosen option
    MOV B, #0                        ; Set opcao to 0
    MOV R1, #0                        ; Reset conta (R1)
    JMP mostraInformacao_Loop

mostraInformacao_Fim:
    CLR TR0                           ; Stop Timer0
    MOV R1, #0                        ; Reset conta (R1)
    CLR Respondeu

    RET


END
