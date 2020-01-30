/**********************************************************
                  		Header files
 **********************************************************/
#include "lpc21xx.h"
#include "minilib.h"



#define LCD_RS (1<<11)
#define LCD_RW (1<<12)
#define LCD_EN (1<<13)

#define LCD_CLEAR        0x01
#define CURSOR_OFF     0x0C
#define FIRST_ROW        0x80
#define SECOND_ROW    0xC0
#define DELETE_CHAR    0x10

#define SBIT_WordLenght    0x00
#define SBIT_DLAB          0x07
#define SBIT_FIFO          0x00
#define SBIT_RxFIFO        0x01
#define SBIT_TxFIFO        0x02
#define SBIT_RDR           0x00
#define SBIT_THRE          0x05



#define TX1         		16
#define RX1          		18

void lcd_cmd (unsigned char val);
void lcd_data (unsigned char val);
void delay (unsigned int);
void gpio_init(void);
void borrarTecla(void);
void mostrarListado(void);
char uart_RxChar(void);
void uart_TxChar(char c);
void uart_init(unsigned int c);
 //teclado en (* 0 #) devuelve, (: ; <)

unsigned char cmd_lcd[5] = {0x38,0x0e,0x06,0x01,0x80};
unsigned char tester_cmd[8] = {0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07};
unsigned char pics_dir [2] = {0x81,0x82};
unsigned char menu0[] = "Inicio";
unsigned char menu1[] = "Seleccion";
unsigned char estado0[] = "B:0 D:0 U:0";
unsigned char estado1[] = "B:0 D:0 U:1";
unsigned char estado2[] = "B:0 D:1 U:0";
unsigned char estado3[] = "B:0 D:1 U:1";
unsigned char estado4[] = "B:1 D:0 U:0";
unsigned char estado5[] = "B:1 D:0 U:1";
unsigned char estado6[] = "B:1 D:1 U:0";
unsigned char estado7[] = "B:1 D:1 U:1";




char msg1, msg2, respuesta;

int main()
{	
    unsigned int i,cont=0;
	gpio_init();				// Inicializamos GPIO
	uart_init(38400);  			// Inicializamos UART
	
	for (i=0; i<5; i++)			// Cargamos comandos configuración LCD
	 lcd_cmd(cmd_lcd[i]);

	while (1) {	
		for (i=0; i<7; i++)		// Mensaje: Inicio	
			lcd_data(menu0[i]);	// Bucle en espera de una tecla pulsada*/
		lcd_cmd(SECOND_ROW);	// Cursor LCD en 2º linea
		i=wait_key();			// Capturamos la tecla pulsada en la variable 'i'
		
		if(i!=-1){					// Si 'i' es un valor válido, continuamos
			
			if((i+49)=='1'){		// Comprobamos si la tecla pulsada es 1
				lcd_data (i+49);	// Mostramos el valor de la tecla por LCD
				while (1) {					// Bucle en espera de una tecla pulsada
				i=wait_key();				// Capturamos la tecla pulsada en la variable 'i'
				if(i!=-1){					// Si 'i' es un valor válido, continuamos
					if((i+49)==':'){		// Si 'i' es un ASTERISCO, continuamos 
						lcd_data ('*');		// y entramos al menu del PIC en cuestion
						msg1 = pics_dir[0];	// Cargo en msg, la direccion del PIC seleccionado
						uart_TxChar(msg1);	// Transmito el primer Byte hacia el PIC, con su direccion	
						lcd_cmd(LCD_CLEAR); // Limpiamos la LCD
						lcd_cmd(SECOND_ROW);// Cursor en segunda fila LCD 
						while (1) {					// Bucle en espera de una tecla pulsada
							i=wait_key();			// Capturamos en 'i' que opcion del menu elige
							if(i!=-1){				// En función de la opción, msg2 es un comando u otro
								if((i+49)=='1') msg2 = tester_cmd[1]; // Encender D
								if((i+49)=='2') msg2 = tester_cmd[2]; // Encender U	
								if((i+49)=='3') msg2 = tester_cmd[3]; // Encender ambos LEDS
								if((i+49)=='4') msg2 = tester_cmd[5]; // Apagar D
								if((i+49)=='5') msg2 = tester_cmd[6]; // Apagar U
								if((i+49)=='6') msg2 = tester_cmd[7]; // Apagar ambos LEDS
								if((i+49)=='7') msg2 = tester_cmd[0]; // Consulta el estado_boton
								if((i+49)=='8') msg2 = tester_cmd[4]; // Borrar memoria boton
								if((i+49)==';') break;		// Tecla 0, retorna al menu principal
								lcd_data(i+49);		// Mostramos que opción eligió en LCD													
								uart_TxChar(msg2);  		// Enviamos el 2º byte con el comando adecuado
								respuesta=uart_RxChar();	// Recibimos la respuesta del exclavo							
								lcd_cmd(LCD_CLEAR);			// Limpiamos LCD
								/*
								En función de la opción seleccionada, el mensaje de respuesta
								será diferente. En función de la respuesta recibida,
								mostramos por pantalla el resultado 
								*/
								if(((i+49)=='1') || ((i+49)=='6') || ((i+49)=='7'))
								{
								if (respuesta == 0x00) 
									for (i=0; i<12; i++)			
										lcd_data(estado0[i]);
								if (respuesta == 0x01) 
									for (i=0; i<12; i++)			
										lcd_data(estado1[i]);
								if (respuesta == 0x02) 
									for (i=0; i<12; i++)			
										lcd_data(estado2[i]);
								if (respuesta == 0x03) 
									for (i=0; i<12; i++)			
										lcd_data(estado3[i]);
								if (respuesta == 0x04) 
									for (i=0; i<12; i++)			
										lcd_data(estado4[i]);
								if (respuesta == 0x05) 
									for (i=0; i<12; i++)			
										lcd_data(estado5[i]);
								if (respuesta == 0x06) 
									for (i=0; i<12; i++)			
										lcd_data(estado6[i]);
								if (respuesta == 0x07) 
									for (i=0; i<12; i++)			
										lcd_data(estado7[i]);
								}
								
							}
							break; // Salimos del bucle while interno
						}
					}
				}
				break;			// Salimos del bucle while externo
				}//fin while
			}
			if((i+49)=='2'){		// Comprobamos si la tecla pulsada es 1
				lcd_data (i+49);	// Mostramos el valor de la tecla por LCD
				while (1) {					// Bucle en espera de una tecla pulsada
				i=wait_key();				// Capturamos la tecla pulsada en la variable 'i'
				if(i!=-1){					// Si 'i' es un valor válido, continuamos
					if((i+49)==':'){		// Si 'i' es un ASTERISCO, continuamos 
						lcd_data ('*');		// y entramos al menu del PIC en cuestion
						msg1 = pics_dir[1];	// Cargo en msg, la direccion del PIC seleccionado
						uart_TxChar(msg1);	// Transmito el primer Byte hacia el PIC, con su direccion
						/*uart_off();
						_delay_ms(10);
						uart_init(38400);*/
						lcd_cmd(LCD_CLEAR); // Limpiamos la LCD
						/*for (i=0; i<9; i++)		//seleccion:	
							lcd_data(menu1[i]);*/
						lcd_cmd(SECOND_ROW);// Cursor en segunda fila LCD 
						while (1) {					// Bucle en espera de una tecla pulsada
							i=wait_key();			// Capturamos en 'i' que opcion del menu elige
							if(i!=-1){				// En función de la opción, msg2 es un comando u otro
								if((i+49)=='1') msg2 = tester_cmd[1]; // Encender D
								if((i+49)=='2') msg2 = tester_cmd[2]; // Encender U	
								if((i+49)=='3') msg2 = tester_cmd[3]; // Encender ambos LEDS
								if((i+49)=='4') msg2 = tester_cmd[5]; // Apagar D
								if((i+49)=='5') msg2 = tester_cmd[6]; // Apagar U
								if((i+49)=='6') msg2 = tester_cmd[7]; // Apagar ambos LEDS
								if((i+49)=='7') msg2 = tester_cmd[0]; // Consulta el estado_boton
								if((i+49)=='8') msg2 = tester_cmd[4]; // Borrar memoria boton
								if((i+49)==';') break;		// Tecla 0, retorna al menu principal
								
								lcd_data(i+49);		// Mostramos que opción eligió en LCD
								
								
								uart_TxChar(msg2);  		// Enviamos el 2º byte con el comando adecuado
								respuesta=uart_RxChar();	// Recibimos la respuesta del exclavo
								
								lcd_cmd(LCD_CLEAR);			// Limpiamos LCD
								/*
								En función de la opción seleccionada, el mensaje de respuesta
								será diferente. En función de la respuesta recibida,
								mostramos por pantalla el resultado 
								*/
								if (respuesta == 0x00) 
									for (i=0; i<12; i++)			
										lcd_data(estado0[i]);
								if (respuesta == 0x01) 
									for (i=0; i<12; i++)			
										lcd_data(estado1[i]);
								if (respuesta == 0x02) 
									for (i=0; i<12; i++)			
										lcd_data(estado2[i]);
								if (respuesta == 0x03) 
									for (i=0; i<12; i++)			
										lcd_data(estado3[i]);
								if (respuesta == 0x04) 
									for (i=0; i<12; i++)			
										lcd_data(estado4[i]);
								if (respuesta == 0x05) 
									for (i=0; i<12; i++)			
										lcd_data(estado5[i]);
								if (respuesta == 0x06) 
									for (i=0; i<12; i++)			
										lcd_data(estado6[i]);
								if (respuesta == 0x07) 
									for (i=0; i<12; i++)			
										lcd_data(estado7[i]);
								
							}
							break; // Salimos del bucle while interno
						}
					}
				}
				break;			// Salimos del bucle while externo
				}//fin while
			}
			
			if((i+49)=='<') borrarTecla();			// Si pulsa un #, lanzamos método correspondiente
			else if((i+49)==':') mostrarListado();	// Si pulsa un #, lanzamos método correspondiente
			else{ 
			
			lcd_cmd(LCD_CLEAR);	 // Limpiamos pantalla
			}
			
		}
		
		
	}	
}

/*
METODO PARA BORRAR LA ULTIMA TECLA PULSADA
RETROCESO DE CURSOR + INSERTAR ESPACIO
*/
void borrarTecla()
{
	char comando = 0x10;
	lcd_cmd(comando);
	lcd_data(32);
	lcd_cmd(comando);
	
}
/*
METODO PARA MOSTRAR EL LISTADO DE DIRECCIONES
DISPONIBLES (No implementado)
*/
void mostrarListado()
{
	lcd_cmd(LCD_CLEAR);
	int i,j;

}
/*
METODO PARA INICIAR LA INTERFAZ GPIO
*/
void gpio_init()
{
	PINSEL0 = 0x00000000;
	IO0DIR = 0x003FF83C;
	IO0CLR = 0x003FF83C;
	
}
/*
METODO PARA ENVIAR UN COMANDO A LA LCD
*/
void lcd_cmd(unsigned char val)
{
	IO0PIN = (val<<14);
	IO0CLR = LCD_RS;
	IO0CLR = LCD_RW;
	IO0SET = LCD_EN;
	_delay_ms(50);
	IO0CLR = LCD_EN;
	_delay_ms(100);

}
/*
METODO PARA ENVIAR UN CARACTER A LA LCD
*/
void lcd_data(unsigned char val)
{
	
	IO0PIN = (val<<14);
	IO0SET = LCD_RS;
	IO0CLR = LCD_RW;
	IO0SET = LCD_EN;
	_delay_ms(50);
	IO0CLR = LCD_EN;
	_delay_ms(100);

}

/***********************************************************
Teclado. Conexionado:
Filas: P0.2 a P0.5 Columnas: P0.6 + P0.7 + P0.10
Se retorna -1 si no hay ninguna tecla pulsada
***********************************************************/
int scan_key()
{
int fila,col,d;
IO0CLR=0x3C; 		// latches de filas en cero

for (fila=0;fila<4;fila++) {
// simulamos colector abierto actuando sobre la
// dirección de los pines de fila
IO0DIR=(IO0DIR&0xFFFFFFC3)|(1<<(fila+2));

_delay_ms(5); // espera
d=((~IO0PIN)>>6)&0x3; // estado de las columnas
	if (d) { // búsqueda de columna activa
		for (col=0;col<3;col++) {
			if (d&1) return fila*3+col;d>>=1;
			
			}
		}
d=((~IO0PIN)>>10)&0x1; // estado de las columnas
	if (d) { // búsqueda de columna activa
		if (d&1) return fila*3+2;	
	}		

}

return -1;
}

/*************************************************
Teclado. Espera por pulsación
**************************************************/
int wait_key()
{
int key;
// esperamos que se suelten las teclas pulsadas
while (scan_key()>=0) _delay_ms(20);
// esperamos que se pulse una tecla
while ((key=scan_key())<0) _delay_ms(20);
return key;
}
/*
METODO PARA INICIAR LA INTERFAZ UART
*/
void uart_init(unsigned int baudrate)
{
    unsigned int var_RegValue_u32;

    PINSEL0 |= (1<<RX1) | (1<<TX1);   								// Configuramos P0.8/P0.9 como RX1 y TX1 
    U1FCR = (1<<SBIT_FIFO) | (1<<SBIT_RxFIFO) | (1<<SBIT_TxFIFO); 	// Activados: FIFO & reset Rx/Tx FIFO buffers    
    U1LCR = (0x03<<SBIT_WordLenght) | (1<<SBIT_DLAB);             	// 8bit datos, 1Stop bit, No paridad

    var_RegValue_u32 = ( PCLK / (16 * baudrate )); 
    U1DLL =  var_RegValue_u32 & 0xFF;
    U1DLM = (var_RegValue_u32 >> 0x08) & 0xFF;

	U1LCR= 0x03;
}

/*
METODO PARA TRANSMITIR 1 CARACTER
*/
void uart_TxChar(char ch)
{
	U1THR = ch;
	while( (U1LSR & 0x40) == 0 );
}


/*
METODO PARA RECIBIR 1 CARACTER
*/
char uart_RxChar()
{
 char ch; 
	while( (U1LSR & 0x01) == 0);
    ch = U1RBR;                                 
 return ch;
}
	
	
