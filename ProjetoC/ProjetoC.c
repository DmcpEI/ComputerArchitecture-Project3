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

//conta = 1 -> 250 microsegundos
//conta = 400 -> 0.1 segundo
unsigned int conta = 0;
// Tempo inicial de 5.0 segundos
int segundosIniciais = TempoInicial;
// Resposta do participante (1->A, 2->B, 3->C ou 4->D)
int resposta = 0;

// Esta a '0' se esta a ser mostrado o tempo inicial nos displays (Nao foi clicado no botao B1)
// Esta a '1' se informa��o com o tempo/resposta do participante esteja a ser mostrada nos displays (Ja foi clicado no botao B1)
bit clicouB1 = 0;
// Esta a '0' se o participante ainda nao respondeu (Não clicou numa das opcoes de resposta durante os 5.0 segundos)
// Esta a '1' se o participante ja respondeu (Clicou numa das opcoes de resposta durante os 5.0 segundos)
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
	EX1 = 1; // Ativa a interrupcao externa 1
	
	// Timer no modo 2, de 8 bits com auto-reload
	TMOD &= 0xF0; // Limpa os bits menos significativos
	TMOD |= 0x02; // Timer 0 no modo 2
	
	TH0 = TempoH;
	TL0 = TempoL;
	
	IT0 = 1; // Interrupcao externa 0 activa a falling edge
	IT1 = 1; // Interrupcao externa 1 activa a falling edge
	TR0 = 0; // Timer 0 nao comeca
}

// Interrupcao externa 0
void External0 (void) interrupt 0 
{
	// Se o botao B1 foi clicado
	if(clicouB1){
		TR0 = 0; // Timer0 para de contar o tempo
		segundosIniciais = TempoInicial;
		conta = 0;
		clicouB1 = 0;
	} 
	else {
		TR0 = 1; // Timer0 comeca a contar tempo
		clicouB1 = 1;
	}
}

// Interrupcao externa 1
void External1 (void) interrupt 2
{
	while(!Pressionado){
		if (segundosIniciais != TempoInicial){
			if (!BA){
				respondeu = 1;
				resposta = 1;
			} else if (!BB){
				respondeu = 1;
				resposta = 2;
			} else if (!BC){
				respondeu = 1;
				resposta = 3;
			} else if (!BD){
				respondeu = 1;
				resposta = 4;
			}
		}
	}
}

void Timer0_ISR (void) interrupt 1 
{
	conta++;

	if (!respondeu){
		if (conta == 400){
			segundosIniciais--;
			conta=0;
		}
	}
}

void display (int num1, int num2)
{
	D1A = segments[num1][0];
	D1B = segments[num1][1];
	D1C = segments[num1][2];
	D1D = segments[num1][3];
	D1E = segments[num1][4];
	D1F = segments[num1][5];
	D1G = segments[num1][6];
	D1DF = segments[num1][7];

	D2A = segments[num2][0];
	D2B = segments[num2][1];
	D2C = segments[num2][2];
	D2D = segments[num2][3];
	D2E = segments[num2][4];
	D2F = segments[num2][5];
	D2G = segments[num2][6];
	D2DF = segments[num2][7];
}

void displaySegundos (int num)
{
    int dezenas = num / 10;
    int unidades = num % 10;

		display(dezenas+1, unidades+8);
}

void semResposta (void)
{
	conta = 0;
	respondeu = 1;
	display(1, 8);
	TR0 = 1;
	
	do {

		// Verifica se o tempo excedeu o limite
		if (conta == segundo) {
				display(0, 7); // Exibir algo indicando que o tempo acabou (ou sem resposta)
				TR0 = 0; // Parar o timer
		}
	} while (B1); // Continua no loop enquanto B1 est� em n�vel alto (n�o pressionado)
	
	conta = 0;
	respondeu = 0;
}

void mostraInformacao(void)
{
	bit opcao = 0;
	conta = 0;
	TR0 = 1;
	
	while (B1){
		if (conta == segundo){
			if (opcao == 0){
				displaySegundos(segundosIniciais);
				opcao = 1;
			} else {
				display(0, resposta+17);
				opcao = 0;
			}
			conta = 0;
		}
	}
	
	TR0 = 0;
	conta = 0;
	respondeu = 0;
}

void main (void)
{
	Init();
	
	while(1){
		
		displaySegundos(segundosIniciais);
		
		if (segundosIniciais <= 0){
			semResposta();
		}

		if (respondeu && segundosIniciais < TempoInicial){
			mostraInformacao();
		}
	}
}