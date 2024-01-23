

CFLAGS += -Wall -Werror
CFLAGS += -Os
CFLAGS += -g
CFLAGS += --target=riscv32
CFLAGS += -march=rv32i
CFLAGS += -fno-builtin

LDFLAGS += -T script.lds 
LDFLAGS += -L/usr/lib/gcc/riscv64-unknown-elf/12.2.0/rv32i/ilp32/
LDFLAGS += -lgcc

all: t.mem t.S

t.o: t.c
	clang $(CFLAGS) -c t.c -o t.o

t.elf: t.o script.lds
	ld.lld -o t.elf t.o $(LDFLAGS)
	

t.bin: t.elf
	llvm-objcopy-16 -j .text -j .data -O binary t.elf t.bin

t.mem: t.bin genmem
	./genmem < t.bin 

t.S: t.elf
	llvm-objdump-16 -S t.elf > t.S

clean:
	rm -f t.o t.bin t.mem

#&& llvm-objdump-16 -S t.o

