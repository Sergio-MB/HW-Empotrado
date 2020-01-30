/****************************************************************************************************
	crt.s						STARTUP  ASSEMBLY  CODE 
								-----------------------
	Module includes the interrupt vectors and start-up code.
	Mostly written by Jesus Arias

 ****************************************************************************************************/

/* Stack Sizes */
.set  UND_STACK_SIZE, 0		/* stack size for "undef" exceptions is 64 bytes (16 registers) 	*/
.set  ABT_STACK_SIZE, 0		/* stack size for "abort" exceptions is 64 bytes (16 registers)		*/
.set  FIQ_STACK_SIZE, 0		/* stack size for "FIQ" interrupts  is 32 bytes (8 registers) 		*/
.set  IRQ_STACK_SIZE, 64	/* stack size for "IRQ" normal interrupts is 64 bytes (16 registers)*/
.set  SVC_STACK_SIZE, 0		/* stack size for "SVC" supervisor (SWI) is 64 bytes (16 registers) */
.set  USR_STACK_SIZE, 64	/* stack size for "user/sys" is 64 bytes (16 registers) */

/* Standard definitions of Mode bits and Interrupt (I & F) flags in PSRs (program status registers) */
.set  MODE_USR, 0x10		/* Normal User Mode 											*/
.set  MODE_FIQ, 0x11		/* FIQ Processing Fast Interrupts Mode 							*/
.set  MODE_IRQ, 0x12		/* IRQ Processing Standard Interrupts Mode						*/
.set  MODE_SVC, 0x13		/* Supervisor Processing Software Interrupts Mode 				*/
.set  MODE_ABT, 0x17		/* Abort Processing memory Faults Mode							*/
.set  MODE_UND, 0x1B		/* Undefined Processing Undefined Instructions Mode 			*/
.set  MODE_SYS, 0x1F		/* System Running Priviledged Operating System Tasks  Mode		*/
.set  I_BIT, 0x80			/* when I bit is set, IRQ is disabled (program status registers)*/
.set  F_BIT, 0x40			/* when F bit is set, FIQ is disabled (program status registers)*/

.text
.arm

/**********************************************************************/
/***************    Vector Table & related constants     **************/
/**********************************************************************/

_vectors:       ldr     PC, Reset_Addr         
                ldr     PC, Undef_Addr
                ldr     PC, SWI_Addr
                ldr     PC, PAbt_Addr
                ldr     PC, DAbt_Addr
                nop							/* Reserved Vector (changed to Philips ISP checksum)    */
                ldr     PC, [PC,#-0xFF0]	/* LPC21xx vectored interrupt (see VIC in users manual) */
                ldr     PC, FIQ_Addr
/*---------------------------------------------------------------------------*/
Reset_Addr:     .word   Reset_Code		
Undef_Addr:     .word   UNDEF_Routine		
SWI_Addr:       .word   SWI_Routine			
PAbt_Addr:      .word   PABORT_Routine		
DAbt_Addr:      .word   DABORT_Routine		
FIQ_Addr:       .word   FIQ_Routine		


        .align 6	// skip the rest of the vector block (64 bytes total)
/****************************************/
/*			Exception handling			*/
/****************************************/
_U0prthex:			@ 32 bits
		mov		r2,#8
		ldr     r1,=0xE000C000  @ UART0 THR
1:		ldrb    r3,[r1,#0x14]   @ UART0 LSR, wait until THRE is one
		tst		r3,#0x20
		beq		1b
		mov		r0,r0, ror #28	@ ...rol #4
		and		r3,r0,#0x0f
		cmp		r3,#9		@ 0..9 or A..F ?
		addgt	r3,r3,#7	@ offset from '9'+1 to 'A' in the ASCII code
		add		r3,r3,#'0'	@ convert to ASCII
		strb	r3,[r1]		@ send through UART0 THR
		subs	r2,r2,#1	@ repeat until no more digits pending
		bne		1b
		mov		pc,lr
_U0puts:
		ldr     r1,=0xE000C000  @ UART0 THR
1:		ldrb	r2,[r1,#0x14]	@ UART0 LSR, wait until THRE is one
		tst		r2,#0x20
		beq		1b
		ldrb	r2,[r0],#1	@ get char
		tst		r2,#0xff
		moveq	pc,lr		@ return if 0
		strb	r2,[r1]		@ send through UART0 THR
		b		1b

#ifndef FIQ
FIQtxt: .asciz "\r\n#--- FIQ interrupt"
#endif
SWItxt: .asciz "\r\n#--- SWI call"
UNDtxt: .asciz "\r\n#--- UNDEF exception"
PABtxt: .asciz "\r\n#--- Prefetch Abort exception"
DABtxt: .asciz "\r\n#--- Data Abort exception"
		.align 2

UNDEF_Routine:
		stmfd	sp!,{lr}		@ LR is the PC before TRAP
		stmfd	sp,{r0-r14}^	@ save USER/SYS registers
		adr		r0,UNDtxt
		b		exception

SWI_Routine:
		stmfd	sp!,{lr}		@ LR is the PC before TRAP
		stmfd	sp,{r0-r14}^	@ save USER/SYS registers
		adr		r0,SWItxt
		b		exception

PABORT_Routine:
		stmfd	sp!,{lr}		@ LR is the PC before TRAP
		stmfd	sp,{r0-r14}^	@ save USER/SYS registers
		adr		r0,PABtxt
		b		exception

DABORT_Routine:
		stmfd	sp!,{lr}		@ LR is the PC before TRAP
		stmfd	sp,{r0-r14}^	@ save USER/SYS registers
		adr		r0,DABtxt
		b		exception
#ifndef FIQ
FIQ_Routine:
		stmfd	sp!,{lr}		@ LR is the PC before TRAP
		stmfd	sp,{r0-r14}^	@ save USER/SYS registers
		adr		r0,FIQtxt
#endif
exception:
		sub		sp,sp,#60			@ SP: pointer to registers
		bl		_U0puts				@ Exception name
		adr		r0,regs				@ regs msg
		bl		_U0puts
		mov		r4,#16
		adr		r5,txtr0
2:		tst		r4,#3
		bne		3f
		adr		r0,crlf
		bl		_U0puts
		mov		r0,r5				@ register name
		add		r5,r5,#10			@ add string lenght
		bl		_U0puts
3:		ldr		r0,[sp],#4
		bl		_U0prthex			@ register values
		mov		r0,#' '
		bl		_U0putch
		subs	r4,r4,#1
		bne		2b
		mov		r0,r5
		bl		_U0puts				@ SPSR value
		mrs		r0,spsr
		bl		_U0prthex
		mov		r0,#' '
		bl		_U0putch
		mrs		r7,spsr				@ SPSR FLAGS
		orr		r6,r7,r7,lsl #20
		adr		r5,flags
		add		r4,r5,#7
4:		ldrb	r0,[r5],#1
		movs	r6,r6,lsl #1
		movcc	r0,#'_'
		bl		_U0putch
		cmp		r5,r4
		bne		4b
		mov		r0,#' '
		bl		_U0putch
		and		r7,r7,#0x1F			@ SPSR mode
		adr		r6,modes
		mov		r5,#7
5:		ldrb	r0,[r6],#1
		cmp		r0,r7
		moveq	r0,r6
		bleq	_U0puts
		add		r6,r6,#4
		subs	r5,r5,#1
		bne		5b
		adr		r0,crlf				@ New line 
		bl		_U0puts
		b		_Halt

crlf:	.asciz "\r\n"
regs:	.asciz "\r\n     User/Sys regs:"
txtr0:	.asciz "R0 - R3: "
txtr4:	.asciz "R4 - R7: "
txtr8:	.asciz "R8 -R11: "
txtr12:	.asciz "R12-R15: "
status:	.asciz "\r\nSPSR   : "
flags:	.ascii "NZCVIFT"
modes:	.byte  0x10 
		.asciz "USR"
		.byte  0x11 
		.asciz "FIQ"
		.byte  0x12 
		.asciz "IRQ"
		.byte  0x13 
		.asciz "SVC"
		.byte  0x17 
		.asciz "ABT"
		.byte  0x1B 
		.asciz "UND"
		.byte  0x1F 
		.asciz "SYS"
        .align 2  /* following code has to be word aligned */

/**********************************************************************/
/************************    Reset Handler     ************************/
/**********************************************************************/
Reset_Code:  

	/* Setup a stack for each mode */

    	ldr   r0, =_stack_end
    	msr   CPSR_c, #MODE_UND|I_BIT|F_BIT 	/* Undefined Instruction Mode  */
    	mov   sp, r0
    	sub   r0, r0, #UND_STACK_SIZE
    	msr   CPSR_c, #MODE_ABT|I_BIT|F_BIT 	/* Abort Mode */
    	mov   sp, r0
    	sub   r0, r0, #ABT_STACK_SIZE
    	msr   CPSR_c, #MODE_FIQ|I_BIT|F_BIT 	/* FIQ Mode */
    	mov   sp, r0	
        sub   r0, r0, #FIQ_STACK_SIZE
    	msr   CPSR_c, #MODE_IRQ|I_BIT|F_BIT 	/* IRQ Mode */
    	mov   sp, r0
    	sub   r0, r0, #IRQ_STACK_SIZE
    	msr   CPSR_c, #MODE_SVC|I_BIT|F_BIT 	/* Supervisor Mode */
    	mov   sp, r0
    	sub   r0, r0, #SVC_STACK_SIZE
    	msr   CPSR_c, #MODE_SYS 	/* System and User Modes, IRQs ON */
    	mov   sp, r0

		/**********************************************************/	
		/* System init											  */
		/* PLL x 4, PCLK = CCLK					  				  */
		/* CCLK=58.9824MHz, PCLK=58.9824MHz		  				  */
		/* UART0 at 115200 bps, 8-bit, 1-stop, no parity, FIFO on */
		/**********************************************************/

		ldr		r1,=0xE01FC000
		mov		r2,#0xaa
		mov		r3,#0x55
		mov		r0,#0x23		@ PLL x 4
		strb	r0,[r1,#0x84]	@ PLLCFG
		strb	r2,[r1,#0x8c]
		strb	r3,[r1,#0x8c]
		mov		r0,#1			@ PLL on
		strb	r0,[r1,#0x80]	@ PLLCON
		strb	r2,[r1,#0x8c]
		strb	r3,[r1,#0x8c]
1:		ldrh	r0,[r1,#0x88]	@ PLLSTAT
		tst		r0,#0x400		@ PLOCK on ?
		beq		1b
		mov		r0,#3			@ PLL connected
		strb	r0,[r1,#0x80]	@ PLLCON
		strb	r2,[r1,#0x8c]
		strb	r3,[r1,#0x8c]
		mov		r0,#1
		str		r0,[r1,#0x100]	@ APBDIV: PCLK=CCLK/1

        mov     r0,#2			@ MAM init
        str     r0,[r1]     	@ MAMCR=2 (Fully enabled)
        mov     r0,#3
        str     r0,[r1,#4]  	@ MAMTIM=3 (3 cycles/flash read)

		sub		r1,r1,#(0xE01FC000-0xE002C000)	@ PINSEL0
		mov		r0,#5			@ P0.0, P0.1 as UART
		str		r0,[r1]
		sub		r1,r1,#(0xE002C000-0xE000C000)	@ UART0
		mov		r0,#0x83
		strb	r0,[r1,#12]		@ LCR=0x83
		mov		r0,#32			@ divider for 115200 baud (PCLK=58.9824MHz)
		strb	r0,[r1]			@ DLL
		mov		r0,#0
		strb	r0,[r1,#4]		@ DLH
		mov		r0,#3
		strb	r0,[r1,#12]		@ LCR=3 (8 bit, 1 stop, no parity)
		mov		r0,#7
		strb	r0,[r1,#8]		@ FCR=7 (FIFOs on)

	/* copy .data section (Copy from ROM to RAM) */
        ldr     R1, =_etext
        ldr     R2, =_data
        ldr     R3, =_edata
1:      cmp     R2, R3
        ldrlo   R0, [R1], #4
        strlo   R0, [R2], #4
        blo     1b

	/* Clear .bss section (Zero init)  */
        mov     R0, #0
        ldr     R1, =_bss_start
        ldr     R2, =_bss_end
2:		cmp     R1, R2
        strlo   R0, [R1], #4
        blo     2b

	/* pass RAM TOP to appropriate var */

		sub	  r0,sp, #USR_STACK_SIZE
		ldr	  r1, =_ramtop
		str	  r0, [r1]

	/* Enter the C code */

		ldr		r12,=main
		mov		lr,pc
		bx		r12			@ should not return, but...

		.global _Halt
_Halt:	mov		r0,#(16<<20)	@ delay to allow for UART flush
		bl		_delay_loop
1:		ldr		r1,=0xE01FC0C0 	@ PCON=2 (power down)
		mov		r0,#2
		strb	r0,[R1]
		b		1b


	/********************************************************/	
	/* Active delay loop 					*/
	/* 4 Clock Cycles per loop, R0 = number of loops	*/
	/* Total delay (including call & return) = 4*(N+1)	*/
	/********************************************************/
		.global _delay_loop
_delay_loop:
		subs	r0,r0,#1
		bne		_delay_loop
		bx		lr

	/****************************************/	
	/* print decimal number					*/
	/****************************************/
	@ R0: value to print
	@ R1: number of digits (0 means minimun number possible)
	@ R2: pad character for left digits ('0' or ' ', typically).
	@ 	  R2 negative means to print R0 as a signed value

		.global _prtnum

_prtnum:
		stmfd	sp!,{r4,r5,lr}
		mov 	r4,#0		@ digit counter
		movs	r2,r2		@ check if negative mode
		bpl		1f
		movs	r0,r0		@ check value when in negative mode
		rsbmi	r0,r0,#0	@ change sign if negative
		bicpl	r2,r2,#0x80000000	@ do not print dashes on positive values
1:		mov 	lr,#32		@ R0/=10, R3=remainder
		mov		r3,#0
2:		adds	r0,r0,r0
		adc		r3,r3,r3
		cmp		r3,#10
		subge	r3,r3,#10
		addge	r0,r0,#1
		subs	lr,lr,#1
		bne		2b
		add		r3,r3,#'0'	@ convert to ASCII
3:		strb	r3,[sp,#-1]!	@ store digit in the STACK
		add		r4,r4,#1	@ increment digit counter
		cmp		r0,#0		@ repeat until number is zero
		bne		1b
		mov		r3,#'-'
		movs	r2,r2		@ check if negative mode
		bicmi	r2,r2,#0x80000000	@ clear the negative mode for next iterations
		bmi		3b			@ print the dash if negative mode
		cmp		r1,#0
		beq		dmpstk
		mov		r3,r2		@ pad character
		cmp		r1,r4		@ keep printing until the specified number of digits
		bhi		3b
dmpstk:		@ print the digits from the stack
		ldr		r5,=_vputch
		ldr		r5,[r5]		@ pointer to putch
4:		ldrb	r0,[sp],#1	@ get digit from stack
		adr		lr,5f
		bx		r5			@ call to *(_vputch)
5:		subs	r4,r4,#1	@ repeat until all digits are printed
		bne		4b
		ldmfd	sp!,{r4,r5,pc}


	/*********************************/
	/* print hexadecimal numbers	 */
	/*********************************/
	@ R0: value to print
	@ R1: number of digits (0 means minimun number possible)
	@ R2: pad character for left digits ('0' or ' ', typically)
		.global _prthex

_prthex:
		stmfd	sp!,{r4,r5,lr}
		mov 	r4,#0		@ digit counter
1:		and		r3,r0,#0xf
		mov		r0,r0,lsr #4
		add		r3,r3,#'0'	@ convert to ASCII
		cmp		r3,#'9'		@ adjust for letters (A-F)
		addhi	r3,r3,#7
2:		strb	r3,[sp,#-1]!	@ store digit in the STACK
		add		r4,r4,#1	@ increment digit counter
		cmp		r0,#0		@ repeat until number is zero
		bne		1b
		cmp		r1,#0
		beq		dmpstk
		mov		r3,r2
		cmp		r1,r4
		bhi		2b
		b		dmpstk

	/******************************************/	
	/* print string	(no new line added)		  */
	/******************************************/
	@ R0: pointer to string
		.global _puts, a_puts, t_puts
		.thumb
t_puts:
		bx	pc
		nop
		.arm
a_puts:
_puts:	stmfd	sp!,{r4,r5,lr}
		mov		r4,r0
		ldr		r5,=_vputch
		ldr		r5,[r5]		@ pointer to putch
1:		ldrb	r0,[r4],#1	@ get char
		cmp		r0,#0
		ldmeqfd	sp!,{r4,r5,lr}
		bxeq	lr
		adr		lr,1b
		bx		r5			@ call to (*_vputch)(r0)
		
	/******************************************/	
	/* printf (more or less)	  			  */
	/******************************************/
	@ R0: pointer to format string
	@ 	%u %d %x %c %s %% supported.
	@ 	example: %05u means unsigned decimal, 5 digits (if possible), pad with zeroes
	@ R1,R2,R3:	parameters (rest of the parameters in the stack)
		.global _printf, a_printf, t_printf
		.thumb
t_printf:
		bx		pc
		nop
		.arm
a_printf:
_printf:
		stmfd	sp!,{r1-r3}	@ put first 3 parameters into the stack, alongside the rest of them
_tprintf:
11:		stmfd	sp!,{r4-r6,lr}
		mov		r4,r0		@ pointer to format string
		ldr		r5,=_vputch
		ldr		r5,[r5]		@ pointer to putch
		add		r6,sp,#16	@ pointer to parameters
1:		ldrb	r0,[r4],#1	@ get char
		cmp		r0,#0		@ end of string?
		beq		9f
		cmp		r0,#'%'		@ parameter printing?
		beq		25f
3:		adr		lr,1b		@ return to label 1:
		bx		r5			@ call to (*_vputch)(r0)

25:		mov		r1,#0		@ default digit counter
		mov		r2,#' '		@ default pad char 
2:		ldrb	r0,[r4],#1	@ get char
		cmp		r0,#'%'		@ double %: just print it
		beq		3b
		cmp		r0,#'0'		@ 0 means pad with '0'
		moveq	r2,r0
		beq		2b
		cmp		r0,#'9'		@ decimal digit means number of digits (9 max)
		suble	r1,r0,#'0'
		ble		2b
		mov		r3,r0
		ldr		r0,[r6],#4	@ get parameter
		cmp		r3,#'c'		@ parameter is a character
		beq		3b
		adr		lr,1b		@ return address for all routines
		cmp		r3,#'s'		@ parameter is a string
		beq		_puts
		cmp		r3,#'u'		@ parameter is a unsigned decimal value
		beq		_prtnum
		cmp		r3,#'d'		@ parameter is a signed decimal value
		orreq	r2,r2,#0x80000000
		beq		_prtnum
		cmp		r3,#'x'		@ parameter is a hexadecimal value
		beq		_prthex
		b		1b
9:		ldmfd	sp!,{r4-r6,lr}
		add		sp,sp,#12
		bx		lr

	/******************************************/	
	/*		 		 sprintf				  */
	/******************************************/

		.globl _sprintf, a_sprintf, t_sprintf
__sputch:
		ldr		r2,=_sputchp
		ldr		r1,[r2]
		strb	r0,[r1],#1
		mov		r0,#0
		strb	r0,[r1]
		str		r1,[r2]
		bx		lr

		.thumb
t_sprintf:
		bx		pc
		nop
		.arm
a_sprintf:
_sprintf:
		stmfd	sp!,{r2,r3}
_tsprintf:
		ldr		r3,=_vputch
		ldr		r2,[r3]
		str		r2,[r3,#4]		@ save a copy of _vputch
		ldr		r2,=__sputch
		str		r2,[r3]
		str		r0,[r3,#(_sputchp-_vputch)]	@change string pointer
		str		lr,[r3,#8]		@ save return addr (wo changing stack)
		mov		r0,r1
		bl		_tprintf
		sub		sp,sp,#4
		ldr		r3,=_vputch
		ldr		r2,[r3,#4]		@restore _vputch copy
		str		r2,[r3]
		ldr		lr,[r3,#8]		@return
		bx		lr

	/******************************************/	
	/* 			gets with line editing		  */
	/******************************************/
	@ R0: pointer to buffer
	@ R1: buffer size
	@ returns: # of bytes in buffer
		.global _gets, a_gets, t_gets
		.thumb
t_gets:	bx	pc
		nop
		.arm
a_gets:
_gets:	stmfd	sp!,{r4-r6,lr}
		mov		r4,r0			@ pointer to buffer
		add		r5,r4,r1		@ compute top pointer
		sub		r5,r5,#1		@ space for zero ending
		mov		r6,r0			@ base pointer
1:		ldr		r1,=_vgetch		@ get character
		adr		lr,2f
		ldr		r0,[r1]
		bx		r0
2:		cmp		r0,#'\r'		@ CR
#ifndef	ISIS	// Proteus Isis virtual terminal with CR only
		beq		1b				@ ignore CR
		cmp		r0,#'\n'		@ NL: end of line
#endif
		bne		3f
		mov		r1,#0			@ terminate string
		strb	r1,[r4],#1
		sub		r0,r4,r6		@ return # bytes
		sub		r0,r0,#1		@ do not include zero ending in count
		ldmfd	sp!,{r4-r6,lr}	@ 
		bx		lr
3:		cmp		r0,#127			@ backspace
		beq		35f
		cmp		r0,#8
		bne		4f
35:		cmp		r4,r6			@ erase only if there is some data in buffer
		beq		1b
		sub		r4,r4,#1
		adr		r0,10f			@ print erase string
		adr		lr,1b			@ _puts returns to label 1:
		b		_puts
4:		cmp		r4,r5			@ check for buffer full
		beq		1b
		strb	r0,[r4],#1		@ store byte
		ldr		r1,=_vputch		@ echo
		adr		lr,1b			@ *_vputch returns to label 1:
		ldr		r1,[r1]
		bx		r1
10:		.asciz	"\b \b"			@ erase string
		.align	2				@ not really required, included just to be sure...

	/******************************************/	
	/* UART0 print character routine		  */
	/* - Try to make use of the 16-byte FIFO  */
	/* - Byte count stored in Scratch reg.    */
	/******************************************/
		.global _U0putch,a_U0putch

a_U0putch:
_U0putch:
		ldr     r1,=0xE000C000  @ UART0 THR

1:		@ wait for FIFO empty
		ldrb	r3,[r1,#0x14]	@ UART0 LSR, wait until THRE is one
		tst		r3,#0x20
		beq		1b

#ifdef CRLF
		cmp		r0,#'\n'
		bne		3f
		mov		r3,#'\r'
		strb	r3,[r1]
		add		r0,r0,#256		@ make R0!=\n, but keep byte value
		beq		1b
#endif
3:		strb	r0,[r1]
		bx		lr

	/******************************************/	
	/* UART 0 read character routine		  */
	/******************************************/
		.global _U0getch, a_U0getch
a_U0getch:
_U0getch:
		ldr     r1,=0xE000C000  @ UART0 THR
1:		ldrb	r0,[r1,#0x14]	@ UART0 LSR, wait until THRE is one
		tst		r0,#1
		beq		1b
		ldrb	r0,[r1]
		bx		lr

		.global	_putch,_getch,a_putch,a_getch,t_putch,t_getch
		.thumb
t_putch:
		ldr		r3,=_vputch
		ldr		r3,[r3]
		bx		r3
t_getch:
		ldr		r3,=_vgetch
		ldr		r3,[r3]
		bx		r3
		.arm
a_putch:
_putch:	ldr		r3,=_vputch
		ldr		r3,[r3]
		bx		r3
a_getch:
_getch:	ldr		r3,=_vgetch
		ldr		r3,[r3]
		bx		r3

	/******************************************/	
	/* IRQ enable & disable					  */
	/******************************************/
		.globl _IRQenable,_IRQdisable,t_IRQenable,t_IRQdisable
		.thumb
t_IRQenable:
		bx	pc
		nop
		.arm
_IRQenable:
		mrs	r1,cpsr
		and	r0,r0,#0xC0
		bic	r1,r1,r0
		msr cpsr,r1
		bx	lr
		.thumb
t_IRQdisable:
		bx	pc
		nop
		.arm
_IRQdisable:
		mrs	r1,cpsr
		and	r0,r0,#0xC0
		orr	r1,r1,r0
		msr cpsr,r1
		bx	lr

	/****************************************/	
	/* THUMB delay							*/
	/****************************************/

		.thumb
		.globl	t_delay_loop

t_delay_loop:
1:		sub		r0,#1
		bne		1b
		bx		lr

	/******************************************/	
	/* 				DATA area				  */
	/******************************************/
		.data
	@ I/O vectors defaulting to UART character routines
	@ can be changed to any character printing/reading routines
	@ the user like
		.global _vputch,_vgetch
_vputch: .word	_U0putch
		 .word  0			@ _vputch copy
		 .word  0			@ space for LR
_sputchp:	.word 0			@ string pointer for sprintf
_vgetch: .word	_U0getch

	/******************************************/	
	/* 				BSS area				  */
	/******************************************/
		.bss
		.global _ramtop
_ramtop: .space 4	@ top of free ram
.end

