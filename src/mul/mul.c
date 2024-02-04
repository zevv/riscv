
#include "arch/io.h"

char hexdigit[] = "0123456789abcdef";

void putc(uint8_t c) __attribute__((noinline));
void putc(uint8_t c)
{
	uart0->data = c;
	while(uart0->status);
}

void puthex(uint32_t v)
{
	for(int i=0; i<4; i++) {
		putc(hexdigit[v >> 12]);
		v <<= 4;
	}
}


void main(void)
{
	volatile int a = 100;
	volatile int b = 100;
	puthex(a * b);
	putc('\n');
}
