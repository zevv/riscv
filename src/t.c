
#include <stdint.h>

struct led {
	uint8_t b, g, r;
};

struct uart {
	uint8_t data;
	uint8_t status;
};

struct led volatile *led = (struct led *)0x4000;
struct uart volatile *uart0 = (struct uart *)0x5000;


void _start(void);
extern uint32_t _sp;

__attribute__ ((section(".vectors")))

void *vectors[] = {
	_start,
	&_sp,
};

//extern uint32_t _erom;
//extern uint32_t _sdata;
//extern uint32_t _edata;


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


int flop_a;;
int flop_b = 0x22222222;
const int flop_c = 0x33333333;


void begin_testcode();

void rvtest_pass(void)
{
	__asm__("fence");
}

void rvtest_fail(void)
{
	__asm__("fence");
}

void _start(void)
{
	//register uint32_t *src = &_erom;
	//register uint32_t *dst = &_sdata;
	//while(dst < &_edata) *dst++ = *src++;

	/* Fill stack with pattern */

	//src = &_sstack;
	//while(src < &_estack) *src++ = 'S';

	///* Copy .data from flash to RAM */


	/* Clear .bss */

	//dst = &_sbss;
	//while(dst < &_ebss) *dst++ = 0;

	/* Run main */

	//puthex(0x12345678);
	//putc('\n');
#if 0
	volatile uint32_t *p1 = (void *)0x8000;
	volatile uint32_t *p2 = (void *)0x8100;

	while(p1 < p2) {
		*p1 = 0x12345678;
		p1 ++;
	}

	volatile int *ram = (int *)0x8004;
	*ram = 'a';
	int d = *ram;
	putc(d);
	volatile int i;
	for(i=0; i<40000; i++);
#endif
#if 0
	begin_testcode();
#endif
#if 0
	volatile int d = 0x1234567;
	puthex(d);
#endif
#if 0

	volatile int a = 100;
	volatile int b = 100;
	puthex(a * b);
	putc('\n');
#endif
#if 1
	for(;;) {
		led->r += 1;
		led->g += 2;
		led->b += 3;
		volatile int i;
		for(i=0; i<2000; i++);
	}
#endif
#if 0
	for(;;) {
		puts("abc");
		for(volatile int i=0; i<40000; i++);
	}
#endif
#if 0
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


