
#include <stdint.h>

volatile int *led = (volatile int *)0x1000;

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

	(*led) = 0x1234;
	for(;;) {
		(*led) ++;
		if((*led ) == 0x1238) {
			//(*led) = 0x1234;
		}
	}
	for(;;);

}


