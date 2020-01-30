# tools
# para YAGARTO
TOOL = arm-none-eabi

CC      = $(TOOL)-gcc
LD      = $(TOOL)-ld -v
AR      = $(TOOL)-ar
AS      = $(TOOL)-as
CP      = $(TOOL)-objcopy
OD		= $(TOOL)-objdump

BT2=../bootloader/bt2 
ISP=../lpc21isp/lpc21isp

# compilado en modo thumb
#CFLAGS  = -I./ -fno-common -Os -g -gdwarf-2 -mcpu=arm7tdmi -mthumb -mthumb-interwork -nostartfiles -static
# compilado en modo ARM
CFLAGS  = -I./ -fno-common -Os -g -gdwarf-2 -mcpu=arm7tdmi -nostartfiles -static

all:	code.bin coderom.elf
	$(BT2) -l code.bin

clean:
	-rm -f *~ crt.lst *.lst crt.o main.o code.elf code.bin code.hex coderom.elf coderom.hex \
	*.pdsbak *.workspace 

code.bin:	code.elf
	$(CP) -O binary $< $@

code.hex:	code.elf
	$(CP) -O ihex $< $@

code.elf: crt.S main.c minilib.h linker_ram.ld Makefile
	$(CC) $(CFLAGS) -Wl,-Tlinker_ram.ld -o $@ -DCRLF crt.S main.c

dis:	code.elf
	$(OD) -d $< >code.lst

burn:	coderom.hex
	$(ISP) -control $< /dev/ttyUSB0 115200 14746

coderom.hex:	coderom.elf
	$(CP) -O ihex $< $@

coderom.elf:	crt.S main.c minilib.h linker_flash.ld Makefile
	$(CC) $(CFLAGS) -Wl,-Tlinker_flash.ld -o $@ -DCRLF crt.S main.c

