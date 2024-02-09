
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "zforth.h"
#include "arch/io.h"



void puthex(uint16_t v)
{
	static char hexdigit[] = "0123456789abcdef";
	for(int i=0; i<4; i++) {                    
		uart_tx(hexdigit[v >> 12]);
		v <<= 4;
	}
}


int main(void)
{
	static char buf[32];

	/* Initialize zforth */
	zf_init(0);
	zf_bootstrap();
	zf_eval(": . 1 sys ;");

	/* Main loop: read words and eval */
	uint8_t l = 0;
	for(;;) {
		char c = uart_rx();
		uart_tx(c);
		if(c == 10 || c == 13 || c == 32) {
			zf_result r = zf_eval(buf);
			if(r != ZF_OK) {
				uart_tx('E');
				puthex(r);
			}
			l = 0;
		} else if(l < sizeof(buf)-1) {
			buf[l++] = c;
		}

		buf[l] = '\0';
	}
}


zf_input_state zf_host_sys(zf_syscall_id id, const char *input)
{
	char b[8];
	char *p;

	switch((int)id) {

		case ZF_SYSCALL_EMIT:
			uart_tx((char)zf_pop());
			break;

		case ZF_SYSCALL_PRINT:
			itoa(zf_pop(), b, 10);
			for(p=b; *p; p++) uart_tx(*p);
			break;
	}

	return 0;
}


zf_cell zf_host_parse_num(const char *buf)
{
	return atoi(buf);
}

