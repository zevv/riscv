#include <stdint.h>

void _start(void);
void main(void);

extern uint32_t _sp;

__attribute__ ((section(".vectors")))
__attribute__ ((used))

void *vectors[] = {
	_start,
	&_sp,
};

void _start(void)
{
	main();
	for(;;);
}

