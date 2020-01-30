#ifdef __arm__
/**********************************************************
                    	  Prototypes
 **********************************************************/
void _puts(char *);
void _printf(char *,...);
void _sprintf(char *, char *,...);
extern void (*_vputch)(int);
extern int (*_vgetch)();
//#define _putch(d) ((*_vputch)(d))
//#define _getch() ((*_vgetch)())
void _putch(char);
char _getch();
int	_gets(unsigned char *,int);
void _U0putch(unsigned char);
unsigned char _U0getch();

///////////////////////////// delays /////////////////////////////////
// macros para usar sólo con argumentos constantes
// el retardo siempre es mayor que el indicado (redondeo hacia arriba)
void _delay_loop(int);

#endif

#ifdef __thumb__
/**********************************************************
                    	  Prototypes
 **********************************************************/
/* ARM functions */
void a_puts(char *);
void a_printf(char *,...);
void a_sprintf(char *, char *,...);
void a_putch(char);
char a_getch();
int	a_gets(unsigned char *,int);

/* Thumb functions */
void t_puts(char *);
void t_printf(char *,...);
void t_sprintf(char *, char *,...);
extern void (*_vputch)(int);
extern int (*_vgetch)();
void t_putch(char);
char t_getch();
int	t_gets(unsigned char *,int);
void t_IRQenable(int);
void t_IRQdisable(int);
void t_delay_loop(int);

#define _puts t_puts
#define _printf t_printf
#define _sprintf t_sprintf
#define _putch t_putch
#define _getch t_getch
#define _gets t_gets
#define _IRQenable t_IRQenable
#define _IRQdisable t_IRQdisable
#define _delay_loop t_delay_loop

#endif

/**********************************************************
                 			Clocks
**********************************************************/

#define FOSC    14745600        // Crystal frequency
#define MSEL    4               // PLL multiplier
#define CCLK    (FOSC*MSEL)	    // CPU clock
#define PCKDIV  1               // APB divider
#define PCLK    (CCLK/PCKDIV)   // Peripheral clock

///////////////////////////// delays /////////////////////////////////
// macros para usar sólo con argumentos constantes
// el retardo siempre es mayor que el indicado (redondeo hacia arriba)
// retardo en ns
#define LOOPNS(n) ((unsigned int)(((CCLK/1000.0)*n-4000000+3999999)/4000000))
#define _delay_ns(n) _delay_loop((LOOPNS(n)>=1)?LOOPNS(n):1)
// retardo en us
#define LOOPUS(n)  ((unsigned int)(((CCLK/1000.0)*n-4000+3999)/4000))
#define _delay_us(n) _delay_loop((LOOPUS(n)>=1)?LOOPUS(n):1)
// retardo en ms
#define LOOPMS(n)  ((unsigned int)(((CCLK/1000.0)*n-4+3)/4))
#define _delay_ms(n) _delay_loop((LOOPMS(n)>=1)?LOOPMS(n):1)

