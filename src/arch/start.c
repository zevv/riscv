#include <stdint.h>
#include <stddef.h>
#include <string.h>

void _start(void);
void main(void);

extern char _sp;
extern char _sbss;
extern char _ebss;
extern char _sheap;
extern char _eheap;
static char *brk = &_sheap;

__attribute__ ((section(".vectors")))
__attribute__ ((used))

void *vectors[] = {
	_start,
	&_sp,
};

void _start(void)
{
	memset(&_sbss, 0, &_ebss - &_sbss);
	main();
	for(;;);
}

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
