
CROSS := /opt/toolchains/xpack-riscv-none-elf-gcc-13.2.0-2/bin/riscv-none-elf-
CC := $(CROSS)gcc
LD := $(CROSS)gcc

CFLAGS += -Wall -Werror
CFLAGS += -Os
CFLAGS += -g
CFLAGS += -march=rv32i
CFLAGS += -fno-builtin
CFLAGS += -ffreestanding

LDFLAGS += -T script.lds 
LDFLAGS += -nostartfiles
LDFLAGS += -march=rv32i

all: t.mem t.S

t.o: t.c
	$(CC) $(CFLAGS) -c t.c -o t.o

t.elf: t.o script.lds
	$(LD) -o t.elf t.o $(LDFLAGS)
	

t.bin: t.elf
	llvm-objcopy-16 -j .text -j .data -O binary t.elf t.bin

t.mem: t.bin genmem
	./genmem < t.bin 

t.S: t.elf
	llvm-objdump-16 -S t.elf > t.S

clean:
	rm -f t.o t.bin t.mem

#&& llvm-objdump-16 -S t.o

