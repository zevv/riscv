
#include <stdint.h>

volatile int *led = (volatile int *)0x4000;

volatile int *uart_data = (volatile int *)0x8000;
volatile int *uart_ctrl = (volatile int *)0x8001;


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
	*uart_data = c;
	while(*uart_ctrl);
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
	volatile int c = 'a';

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


