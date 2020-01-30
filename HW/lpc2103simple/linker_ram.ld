/* ******************************************************************************* */
/*   demo2106_blink_ram.cmd		LINKER  SCRIPT                             */

/* specify the LPC2103 memory areas  */

MEMORY 
{
	flash	: ORIGIN = 0x00000000, LENGTH = 32K	/* free FLASH EPROM area  */
	ram   	: ORIGIN = 0x40000000, LENGTH = 8K	/* free RAM area  */
}

/* define a global symbol _stack_end  */

_stack_end = 0x40000000+8K;	/* STACK at RAM end */

/* now define the output sections  */

SECTIONS 
{
	.startup : { *(.startup)} >ram  		/* the startup code */
	
	.text :					/* collect all code related sections */ 
	{
		*(.text)			/* all .text sections (code)  */
		*(.text.startup)	/* YAGARTO screws it up without this ...*/
		*(.text.memcpy)
		*(.text.memset)
		*(.vfp11_veneer)
		*(.v4_bx)
		*(.iplt)
		*(.rel.dyn)
		*(.rel.iplt)
		*(.rodata)			/* all .rodata sections (constants, strings, etc.)  */
		*(.rodata*)			/* all .rodata* sections (constants, strings, etc.)  */
		*(.glue_7)			/* all .glue_7 sections  (no idea what these are) */
		*(.glue_7t)			/* all .glue_7t sections (no idea what these are) */
		. = ALIGN(4);
		_etext = .;			/* define a global symbol _etext just after the last code byte */
	} >ram  				/* put all the above into RAM */


	.data :					/* collect all initialized .data sections that go into RAM  */ 
	{
		/* _bdata = LOADADDR(.data); */
		_bdata = .;
		_data = .;			/* create a global symbol marking the start of the .data section  */
		*(.data)			/* all .data sections  */
		. = ALIGN(4);
		_edata = .;			/* define a global symbol marking the end of the .data section  */
	} >ram          		/* put all the above into RAM */

	.bss :					/* collect all uninitialized .bss sections that go into RAM  */
	{
		_bss_start = .;		/* define a global symbol marking the start of the .bss section */
		*(.bss)				/* all .bss sections  */
		. = ALIGN(4);			/* advance location counter to the next 32-bit boundary */
		_bss_end = . ;			/* define a global symbol marking the end of the .bss section */
	} >ram					/* put all the above in RAM (it will be cleared in the startup code) */

	_end = .;				/* define a global symbol marking the end of application RAM */
}
	
