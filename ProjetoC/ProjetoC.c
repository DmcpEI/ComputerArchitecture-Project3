#include <reg51.h>

#define TempoInicial 50

// O valor máximo da contagem de tempo é "FF + 1" = 256 microsegundos (Timer no modo 2 tem 8 bits)
// Um cilo máquina tem 6 estados e cada estado tem 2 períodos do oscilador, logo 12 períodos
// Período = 1/12*(10^6) = 1/12 microsegundos , 1 ciclo máquina = 12*Período = 12*(1/12) = 1 microsegundo
// 250 microsegundos : 256-250 = 6 = 6 microsegundos (Sendo 06 -> TH0 e 06 -> TL0)
#define TempoH 0x06
#define TempoL 0x06

/*
Da inicio a contagem decrescente para o participante responder (Caso o tempo para a contagem esteja a ser mostrado nos displays com o tempo inicial de 5.0 segundos)
Repoe a visualizacao do tempo inicial de 5.0 segundos nos displays (Caso a informacao com o tempo/resposta do participante esteja a ser mostrada nos displays)
*/
sbit B1 = P3^2;

/*
Ao ser pressionado qualquer um dos botoes de opcao de resposta ha uma transicao logica de ‘1’ para ‘0’
Enquanto qualquer um dos botoes de opcao de resposta continuar pressionado, e colocado o valor logico ‘0’
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
//conta = 20000 -> 5 segundos
int conta = 0;
int segundos = 0;


void Init (void)
{
	EA = 1;
	ET0 = 1;
	EX0 = 1;
	
	TMOD &= 0xF0;
	TMOD |= 0x02;
	
	TH0 = TempoH;
	TL0 = TempoL;
	
	TR0 = 1;
}

void Timer0_ISR (void) interrupt 1 
{
	conta++;
	
	if (conta == 400){
		segundos++;
		conta=0;
	}
	
	if (segundos == 50){
		TR0=0;
	}
}

void main (void)
{
	Init();
	
	while(TR0){
		P0 = segundos;
	}
}
