
#include "arch/io.h"


void putc(uint8_t c)
{
	uart0->data = c;
	while(uart0->status);
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

