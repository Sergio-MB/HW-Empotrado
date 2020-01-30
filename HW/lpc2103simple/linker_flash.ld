
/* specify the LPC2103 memory areas  */

MEMORY 
{
	flash   : ORIGIN = 0,          LENGTH = 32K	/* FLASH ROM*/	
	ram   	: ORIGIN = 0x40000040, LENGTH = 8k-64	/* free RAM area	*/
}


/* define a global symbol _stack_end  */

_stack_end = 0x40000000+8k;

/* now define the output sections  */

SECTIONS 
{
	. = 0;						/* set location counter to address zero  */
	
	_startup : { *(.startup)} >flash	/* the startup code goes into FLASH */
	
	.text :						/* collect all sections that should go into FLASH after startup  */ 
	{
		*(.text)				/* all .text sections (code)  */
		*(.text.startup)		/* YAGARTO screws it up without this ...*/
		*(.text.memcpy)
		*(.text.memset)
		*(.vfp11_veneer)
		*(.v4_bx)
		*(.iplt)
		*(.rel.dyn)
		*(.rel.iplt)

		*(.rodata)				/* all .rodata sections (constants, strings, etc.)  */
		*(.rodata*)				/* all .rodata* sections (constants, strings, etc.)  */
		*(.glue_7)				/* all .glue_7 sections  (no idea what these are) */
		*(.glue_7t)				/* all .glue_7t sections (no idea what these are) */
		. = ALIGN(4);			/* advance location counter to the next 32-bit boundary */
		_etext = .;				/* define a global symbol _etext just after the last code byte */
	} >flash					/* put all the above into FLASH */
	
	.data :						/* collect all initialized .data sections that go into RAM  */ 
	{
		_bdata = LOADADDR(.data);
		_data = .;				/* create a global symbol marking the start of the .data section  */
		*(.data)				/* all .data sections  */
		. = ALIGN(4);			/* advance location counter to the next 32-bit boundary */
		_edata = .;				/* define a global symbol marking the end of the .data section  */
	} >ram AT >flash			/* put all the above into RAM (but load the LMA copy into FLASH) */

	.bss :						/* collect all uninitialized .bss sections that go into RAM  */
	{
		_bss_start = .;			/* define a global symbol marking the start of the .bss section */
		*(.bss)					/* all .bss sections  */
		. = ALIGN(4);			/* advance location counter to the next 32-bit boundary */
		_bss_end = . ;			/* define a global symbol marking the end of the .bss section */
	} >ram						/* put all the above in RAM (it will be cleared in the startup code */

}
	_end = .;					/* define a global symbol marking the end of application RAM */
	
