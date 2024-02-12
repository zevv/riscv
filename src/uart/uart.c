
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
	for(;;) {
		puts("Hullo\n");
		volatile int i;
		for(i=0; i<10000; i++);
	}
}

