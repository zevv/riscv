

CFLAGS += -Wall -Werror
CFLAGS += -Os
CFLAGS += -g
CFLAGS += --target=riscv32
CFLAGS += -march=rv32i

all: t.mem t.S

t.o: t.c
	clang $(CFLAGS) -c t.c -o t.o

t.elf: t.o
	ld.lld -o t.elf t.o -T script.lds

t.bin: t.elf
	llvm-objcopy-16 -O binary t.elf t.bin

t.mem: t.bin genmem
	./genmem < t.bin 

t.S: t.elf
	llvm-objdump-16 -S t.elf > t.S

clean:
	rm -f t.o t.bin t.mem

#&& llvm-objdump-16 -S t.o

