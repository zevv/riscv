#include <stdint.h>

struct led {
	uint32_t b;
	uint32_t g;
	uint32_t r;
};

struct led volatile *led = (struct led *)0x4000;


struct uart {
	uint32_t data;
	uint32_t status;
};

struct uart volatile *uart0 = (struct uart *)0x5000;


