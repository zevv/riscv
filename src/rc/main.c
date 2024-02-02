
void begin_testcode();

void main(void)
{
	begin_testcode();
}

void rvtest_pass(void)
{
	__asm__("fence");
}

void rvtest_fail(void)
{
	__asm__("fence");
}
