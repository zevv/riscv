
#include "arch/io.h"


struct led {
	uint32_t b;
	uint32_t g;
	uint32_t r;
};

__attribute__((used))
static struct led volatile *led = (struct led *)0x4000;


struct uart {
	uint32_t data;
	uint32_t status;
};

#define UART_STATUS_TX_BUSY 0x01
#define UART_STATUS_RX_AVAIL 0x02

__attribute__((used))
static struct uart volatile *uart0 = (struct uart *)0x5000;


void uart_tx(uint8_t c)
{
	uart0->data = c;
	while(uart0->status & UART_STATUS_TX_BUSY);
}


char uart_rx(void)
{
	while(!(uart0->status & UART_STATUS_RX_AVAIL));
	return uart0->data;
}


void led_set(uint8_t r, uint8_t g, uint8_t b)
{
	led->r = r;
	led->g = g;
	led->b = b;
}
