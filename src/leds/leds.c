

#include <stdint.h>
#include <stdlib.h>

#include "arch/io.h"


void main(void)
{
	uint8_t r = 0, g = 0, b = 0;

	for(;;) {
		led_set(r, g, b);
		r += 1;
		g += 2;
		b += 3;

		for(volatile int i=0; i<4000; i++);
	}
}
