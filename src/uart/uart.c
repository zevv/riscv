
#include "arch/io.h"


void puts(char *s)
{
	while(*s) {
		uart_tx(*s);
		s++;
	}
}


void main(void)
{
	puts("Hullo\n");
	for(;;) {
		uart_tx(uart_rx());
	}
}

