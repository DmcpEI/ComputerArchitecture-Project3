#include <reg51.h>

// Tempo inicial de 5.0 segundos
#define TempoInicial 50
// Valor da variavel 'conta' para 1 segundo
#define segundo 4000

/* 
O valor maximo da contagem de tempo e "FF + 1" = 256 microsegundos (Timer no modo 2 tem 8 bits)
Um cilo maquina tem 6 estados e cada estado tem 2 periodos do oscilador, logo 12 periodos
Periodo = 1/12*(10^6) = 1/12 microsegundos , 1 ciclo maquina = 12*Periodo = 12*(1/12) = 1 microsegundo
250 microsegundos : 256-250 = 6 = 6 microsegundos (Sendo 06 -> TH0 e 06 -> TL0)
*/
#define TempoH 0x06
#define TempoL 0x06

/*
Da inicio a contagem decrescente para o participante responder (Caso o tempo para a contagem esteja a ser mostrado nos displays com o tempo inicial de 5.0 segundos)
Repoe a visualizacao do tempo inicial de 5.0 segundos nos displays (Caso a informacao com o tempo/resposta do participante esteja a ser mostrada nos displays)
*/
sbit B1 = P3^2;

/*
Ao ser pressionado qualquer um dos botoes de opcao de resposta ha uma transicao logica de 1 para 0
Enquanto qualquer um dos botoes de opcao de resposta continuar pressionado, e colocado o valor logico 0
*/
sbit Pressionado = P3^3;

// Opcoes de resposta
sbit BA = P3^4;
sbit BB = P3^5;
sbit BC = P3^6;
sbit BD = P3^7;

// Display D1
sbit D1A = P1^0;
sbit D1B = P1^1;
sbit D1C = P1^2;
sbit D1D = P1^3;
sbit D1E = P1^4;
sbit D1F = P1^5;
sbit D1G = P1^6;
sbit D1DF = P1^7;

// Display D2
sbit D2A = P2^0;
sbit D2B = P2^1;
sbit D2C = P2^2;
sbit D2D = P2^3;
sbit D2E = P2^4;
sbit D2F = P2^5;
sbit D2G = P2^6;
sbit D2DF = P2^7;

// conta = 1 -> 250 microsegundos
// conta = 400 -> 0.1 segundo
// Conta interrupcoes do timer 0
unsigned int conta = 0;

// Tempo inicial de 5.0 segundos
int segundosIniciais = TempoInicial;

// Resposta do participante (1->A, 2->B, 3->C ou 4->D)
int resposta = 0;

// Variavel de controlo que se mudar de valor o botão B1 foi clicado
bit clicouB1 = 0;

/*
Variavel de controlo para o botao B1 para escolher a acao a ser tomada
Esta a '0' se esta a ser mostrado o tempo inicial nos displays (Nao foi clicado no botao B1)
Esta a '1' se informacao com o tempo/resposta do participante esteja a ser mostrada nos displays (Ja foi clicado no botao B1)
*/
bit opcaoB1 = 0;

/*
Variavel de controlo para o botao B1 para escolher a acao a ser tomada
Esta a '0' se o participante ainda nao respondeu (Não clicou numa das opcoes de resposta durante os 5.0 segundos)
Esta a '1' se o participante ja respondeu (Clicou numa das opcoes de resposta durante os 5.0 segundos)
*/
bit respondeu = 0;

// Segmentos dos displays com todos os numeros, simbolos e letras
code unsigned segments[22][8] = {
	{1, 1, 1, 1, 1, 1, 0, 0}, // -.
	{0, 0, 0, 0, 0, 0, 1, 0}, // 0.
	{1, 0, 0, 1, 1, 1, 1, 0}, // 1.
	{0, 0, 1, 0, 0, 1, 0, 0}, // 2.
	{0, 0, 0, 0, 1, 1, 0, 0}, // 3.
	{1, 0, 0, 1, 1, 0, 0, 0}, // 4.
	{0, 1, 0, 0, 1, 0, 0, 0}, // 5.
	{1, 1, 1, 1, 1, 1, 0, 1}, // -
	{0, 0, 0, 0, 0, 0, 1, 1}, // 0
	{1, 0, 0, 1, 1, 1, 1, 1}, // 1
	{0, 0, 1, 0, 0, 1, 0, 1}, // 2
	{0, 0, 0, 0, 1, 1, 0, 1}, // 3
	{1, 0, 0, 1, 1, 0, 0, 1}, // 4
	{0, 1, 0, 0, 1, 0, 0, 1}, // 5
	{0, 1, 0, 0, 0, 0, 0, 1}, // 6
	{0, 0, 0, 1, 1, 1, 1, 1}, // 7
	{0, 0, 0, 0, 0, 0, 0, 1}, // 8
	{0, 0, 0, 0, 1, 0, 0, 1}, // 9
	{0, 0, 0, 1, 0, 0, 0, 1}, // A
	{1, 1, 0, 0, 0, 0, 0, 1}, // B
	{0, 1, 1, 0, 0, 0, 1, 1}, // C
	{1, 0, 0, 0, 0, 1, 0, 1}, // D
};

// Inicializacao do sistema
void Init (void)
{
	// Configuracao do registo
	EA = 1; // Ativa as interrupcoes globais
	ET0 = 1; // Ativa a interrupcao timer 0
	EX0 = 1; // Ativa a interrupcao externa 0
	EX1 = 0; // Desativa a interrupcao externa 1
	
	// Timer no modo 2, de 8 bits com auto-reload
	TMOD &= 0xF0; // Limpa os bits menos significativos
	TMOD |= 0x02; // Timer 0 no modo 2
	
	TH0 = TempoH; // Inicializa o valor de TH0
	TL0 = TempoL; // Inicializa o valor de TL0 (6 microsegundos)
	
	IT0 = 1; // Interrupcao externa 0 activa a falling edge
	IT1 = 1; // Interrupcao externa 1 activa a falling edge
	TR0 = 0; // Timer 0 nao comeca
}

// Interrupcao externa 0
void External0 (void) interrupt 0 
{
	// Inverte o valor da variavel de controlo 'clicouB1'
	clicouB1 = ~clicouB1;

	// Se a variavel de controlo 'opcao1' estiver a 1
	if(opcaoB1){
		IE0 = 0; // Limpa a flag da interrupcao externa 0
		EX1 = 0; // Desativa a interrupcao externa 1
		TR0 = 0; // Timer0 para de contar o tempo
		segundosIniciais = TempoInicial; // Repoe o tempo inicial de 5.0 segundos
		conta = 0; // Repoe a contagem de interrupcoes do timer 0
	} 
	else {
		EX0 = 0; // Desativa a interrupcao externa 0
		IE1 = 0; // Limpa a flag da interrupcao externa 1
		EX1 = 1; // Ativa a interrupcao externa 1
		TR0 = 1; // Timer0 comeca a contar tempo
	}
}

// Interrupcao externa 1
void External1 (void) interrupt 2
{
	EX1 = 0; // Desativa a interrupcao externa 1
	// Enquanto o botao de opcao de resposta estiver pressionado, o tempo tiver comecado a contar e nao tiver terminado
	while(!Pressionado && segundosIniciais != TempoInicial && segundosIniciais != 0){
		// Se a opcao de resposta A for pressionada
		if (!BA){
			respondeu = 1; // A variavel de controlo 'respondeu' passa a 1
			resposta = 1; // A resposta do participante e a opcao A

		} else if (!BB){ // Se a opcao de resposta B for pressionada
			respondeu = 1;
			resposta = 2;

		} else if (!BC){ // Se a opcao de resposta C for pressionada
			respondeu = 1;
			resposta = 3;

		} else if (!BD){ // Se a opcao de resposta D for pressionadaß

			respondeu = 1;
			resposta = 4;
		}
	}
}

// Interrupcao do timer 0
void Timer0_ISR (void) interrupt 1 
{
	conta++; // Incrementa a variavel 'conta' a cada interrupcao do timer 0

	// Se a variavel de controlo 'respondeu' estiver a 0
	if (!respondeu){
		// Se a contagem de interrupcoes do timer 0 for igual a 400 (0.1 segundo)
		if (conta == 400){
			segundosIniciais--; // Decrementa o tempo atual
			conta=0; // Recomeca a contagem de interrupcoes do timer 0
		}
	}
}

// Mostra o caracter correspondente ao lugar do segmento no display
void display (int num1, int num2)
{
	// Segmentos do display D1
	D1A = segments[num1][0];
	D1B = segments[num1][1];
	D1C = segments[num1][2];
	D1D = segments[num1][3];
	D1E = segments[num1][4];
	D1F = segments[num1][5];
	D1G = segments[num1][6];
	D1DF = segments[num1][7];

	// Segmentos do display D2
	D2A = segments[num2][0];
	D2B = segments[num2][1];
	D2C = segments[num2][2];
	D2D = segments[num2][3];
	D2E = segments[num2][4];
	D2F = segments[num2][5];
	D2G = segments[num2][6];
	D2DF = segments[num2][7];
}

// Mostra os segundos nos displays
void displaySegundos (int num)
{
	// Calcula as dezenas e unidades do numero
    int dezenas = num / 10;
    int unidades = num % 10;

	// Mostra o numero nos displays
	display(dezenas+1, unidades+8);
}

// Mostra a resposta nos displays
void semResposta (void)
{
	bit opcao = 0; // Variavel de controlo para a opcao a ser mostrada
	conta = 0; // Reseta a contagem de interrupcoes do timer 0
	respondeu = 1; // A variavel de controlo 'respondeu' passa a 1
	
	clicouB1 = 1; // A variavel de controlo 'clicouB1' passa a 1
	IE0 = 0; // Limpa a flag da interrupcao externa 0
	EX0 = 1; // Ativa a interrupcao externa 0
	EX1 = 0; // Desativa a interrupcao externa 1
	
	TR0 = 1; // Timer0 comeca a contar tempo
	
	// Mostra o valor final do tempo nos displays (0.0)
	display(1,8);
	
	// Enquanto o botao B1 nao for clicado
	while(clicouB1){
		// Se a contagem de interrupcoes do timer 0 for igual a 4000 (1 segundo)
		if (conta == segundo){
			// Se a opcao for 0
			if (opcao == 0){
				// Mostra a resposta indefinida nos displays
				display(0, 7);
				opcao = 1; // A opcao passa a 1
			} else { // Se a opcao for 1
				// Mostra o valor final do tempo nos displays (0.0)
				display(1, 8);
				opcao = 0; // A opcao passa a 0
			}
			conta = 0; // Reseta a contagem de interrupcoes do timer 0
		}
		opcaoB1 = 1; // A variavel de controlo 'opcaoB1' passa a 1
	}
	
	TR0 = 0; // Timer0 para de contar tempo
	conta = 0; // Reseta a contagem de interrupcoes do timer 0
	respondeu = 0; // A variavel de controlo 'respondeu' passa a 0
}

// Mostra a informacao nos displays
void mostraInformacao(void)
{
	bit opcao = 0; // Variavel de controlo para a opcao a ser mostrada
	conta = 0; // Reseta a contagem de interrupcoes do timer 0
	
	clicouB1 = 1; // A variavel de controlo 'clicouB1' passa a 1
	IE0 = 0; // Limpa a flag da interrupcao externa 0
	EX0 = 1; // Ativa a interrupcao externa 0
	EX1 = 0; // Desativa a interrupcao externa 1
	
	TR0 = 1; // Timer0 comeca a contar tempo
	
	// Enquanto o botao B1 nao for clicado
	while (clicouB1){
		// Se a contagem de interrupcoes do timer 0 for igual a 4000 (1 segundo)
		if (conta == segundo){
			// Se a opcao for 0
			if (opcao == 0){
				// Mostra o tempo em que clicou na resposta nos displays
				displaySegundos(segundosIniciais);
				opcao = 1;
			} else { // Se a opcao for 1
				// Mostra a resposta do participante nos displays
				display(0, resposta+17);
				opcao = 0;
			}
			conta = 0; // Reseta a contagem de interrupcoes do timer 0
		}
		opcaoB1 = 1; // A variavel de controlo 'opcaoB1' passa a 1
	}
	
	TR0 = 0; // Timer0 para de contar tempo
	conta = 0; // Reseta a contagem de interrupcoes do timer 0
	respondeu = 0; // A variavel de controlo 'respondeu' passa a 0
}

// Funcao principal
void main (void)
{
	// Inicializacao do sistema
	Init();
	
	// Ciclo infinito
	while(1){
		
		// Mostra o tempo atual nos displays
		displaySegundos(segundosIniciais);
		
		// Se o tempo chegar ao fim
		if (segundosIniciais <= 0){
			// Funcao que mostra a resposta indefinida e o tempo final nos displays
			semResposta();
		}

		// Se clicou em algum dos botoes de opcao de resposta e o tempo ainda nao chegou ao fim
		if (respondeu && segundosIniciais < TempoInicial){
			// Funcao que mostra a resposta e o tempo de resposta nos displays
			mostraInformacao();
		}
		
		opcaoB1 = 0; // A variavel de controlo 'opcaoB1' passa a 0
	}
}