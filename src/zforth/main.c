
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "zforth.h"
#include "arch/io.h"


static char buf[32];

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
				uart_tx('\n');
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
	switch((int)id) {

		case ZF_SYSCALL_EMIT:
			uart_tx((char)zf_pop());
			break;

		case ZF_SYSCALL_PRINT:
			puthex(zf_pop());
			uart_tx('\n');
			break;
	}

	return 0;
}


zf_cell zf_host_parse_num(const char *buf)
{
	char *end;
	zf_cell v = strtol(buf, &end, 0);
	if(*end != '\0') {
		zf_abort(ZF_ABORT_NOT_A_WORD);
	}
	return v;
}


/*
 * End
 */

