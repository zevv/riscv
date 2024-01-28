
CROSS := /opt/toolchains/xpack-riscv-none-elf-gcc-13.2.0-2/bin/riscv-none-elf-
CC := $(CROSS)gcc
LD := $(CROSS)gcc

CFLAGS += -Wall -Werror
CFLAGS += -Os
CFLAGS += -g
CFLAGS += -march=rv32i
CFLAGS += -fno-builtin
CFLAGS += -ffreestanding
CFLAGS += -Itest

LDFLAGS += -T script.lds 
LDFLAGS += -nostartfiles
LDFLAGS += -march=rv32i
LDFLAGS += --specs=nano.specs

CSRC += t.c

OBJS := $(subst .c,.o, $(CSRC)) $(subst .S,.o, $(SSRC))
DEPS := $(subst .c,.d, $(CSRC))

all: t.mem t.asm

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

%.elf: $(OBJS) script.lds
	$(LD) -o $@ $(OBJS) $(LDFLAGS)

%.bin: %.elf
	llvm-objcopy-16 -j .text -j .data -O binary $< $@

t.mem: t.bin genmem
	./genmem < t.bin 

t.asm: t.elf
	llvm-objdump-16 -S t.elf > t.asm

clean:
	rm -f *.elf *.o *.asm *.bin *.mem

#&& llvm-objdump-16 -S t.o

