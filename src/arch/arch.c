
#include "arch/io.h"

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

