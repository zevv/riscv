#include <stdint.h>
#include <stddef.h>

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

extern char _sheap;
extern char _eheap;
static char *brk = &_sheap;

void *_sbrk(ptrdiff_t incr)
{
	char *old_brk = brk;

	if ((brk += incr) < &_eheap) {
		brk += incr;
	} else {
		brk = &_eheap;
	}
	return old_brk;
}
