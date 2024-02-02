

#include <stdint.h>
#include <stdlib.h>

#include <arch/io.h>


void main(void)
{
	for(;;) {
		led->r += 1;
		led->g += 2;
		led->b += 3;
		volatile int i;
		for(i=0; i<4000; i++);
	}
}
