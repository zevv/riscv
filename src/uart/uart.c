
#include "arch/io.h"


void putc(uint8_t c)
{
	uart0->data = c;
	while(uart0->status);
}

char hexdigit[] = "0123456789abcdef";

void puthex(uint32_t v)
{
	for(int i=0; i<8; i++) {
		putc(hexdigit[v >> 28]);
		v <<= 4;
	}
}

void puts(char *s)
{
	while(*s) {
		putc(*s);
		s++;
	}
}
void main(void)
{
	puts("Hullo\n");
}

