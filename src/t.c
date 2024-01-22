
#include <stdint.h>

volatile int *led = (volatile int *)0x4000;

volatile int *uart_data = (volatile int *)0x8000;
volatile int *uart_ctrl = (volatile int *)0x8001;

extern uint8_t _sdata;
extern uint8_t _edata;
extern uint8_t _estack;
extern uint8_t _sstack;


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

	if(0) {
		volatile int a = 1000;
		volatile int b = 1000;
		*led = a * b;
	}

	if(1) {
		for(;;) {
			char *s = "ABCDEFGH\n";
			while(*s) {
				*uart_data = *s++;
				while(*uart_ctrl);
			}
			volatile int i;
			for(i=0; i<40000; i++);
		}
	}

	if(0) {
		for(;;) {
			volatile int i;
			for(i=0; i<40000; i++);
			(*led)++;
		}
	}

	for(;;);

}


