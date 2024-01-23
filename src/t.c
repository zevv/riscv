
#include <stdint.h>

volatile int *led = (volatile int *)0x4000;


struct uart {
	uint8_t data;
	uint8_t status;
};

struct uart volatile *uart0 = (struct uart *)0x8000;


void _start(void);

__attribute__ ((section(".vectors")))

void *vectors[] = {
	_start,
};

extern uint8_t _sdata;
extern uint8_t _edata;
extern uint8_t _estack;
extern uint8_t _sstack;


void putc(uint8_t c)
{
	*led = c;
	uart0->data = c;
	while(uart0->status);
}

void puts(char *c)
{
	while(*c) {
		putc(*c);
		c++;
	}
}


void _start(void)
{
	//register uint8_t *src, *dst;

	/* Fill stack with pattern */

	//src = &_sstack;
	//while(src < &_estack) *src++ = 'S';

	///* Copy .data from flash to RAM */

	//src = &_erom;
	//dst = &_sdata;
	//while(dst < &_edata) *dst++ = *src++;

	/* Clear .bss */

	//dst = &_sbss;
	//while(dst < &_ebss) *dst++ = 0;

	/* Run main */

#if 0
	volatile int a = 100;
	volatile int b = 100;
	*led = a * b;
#endif

#if 1
	int c = 'a';

	puts("1234");

	for(;;) {
		putc(c);
		c++;
		if(c > 'z') c = 'a';
		//volatile int i;
		//for(i=0; i<40000; i++);
	}
#endif

#if 0
	for(;;) {
		volatile int i;
		for(i=0; i<40000; i++);
		(*led)++;
	}
#endif

	for(;;);

}


