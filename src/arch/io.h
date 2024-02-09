#ifndef io_h
#define io_h

#include <stdint.h>

void uart_tx(uint8_t c);
char uart_rx(void);

void led_set(uint8_t r, uint8_t g, uint8_t b);

#endif
