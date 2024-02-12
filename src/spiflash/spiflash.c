
#include "arch/io.h"

volatile uint32_t *spiflash = (uint32_t *)0x6000;


char hexdigit[] = "0123456789abcdef";

void puthex(uint32_t v)
{
	for(int i=0; i<8; i++) {
		uart_tx(hexdigit[v >> 28]);
		v <<= 4;
	}
}

void puts(char *s)
{
	while(*s) {
		uart_tx(*s);
		s++;
	}
}


void main(void)
{
	for(;;) {
		puts("SPI: ");
		volatile uint32_t v = *spiflash;
		puthex(v);
		puts("\n");
		volatile int i;
		for(i=0; i<100000; i++);
	}
}

