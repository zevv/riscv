

BIN := $(NAME).bin
ELF := $(NAME).elf
MEM := $(NAME).mem
ASM := $(NAME).asm

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
CFLAGS += -MMD
CFLAGS += -I.
CFLAGS += -I..
CFLAGS += -flto

LDFLAGS += $(CFLAGS)
LDFLAGS += -T ../arch/script.lds 
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs

CSRCS += start.c io.c

VPATH = ../arch

SRCS := $(CSRCS) $(SSRCS)
OBJS := $(subst .c,.o, $(CSRCS)) $(subst .S,.o, $(SSRCS))
DEPS := $(subst .c,.d, $(CSRCS)) $(subst .S,.d, $(SSRCS))   

all: $(MEM) $(ASM)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJS)
	$(LD) -o $@ $(OBJS) $(LDFLAGS)

$(BIN): $(ELF)
	llvm-objcopy-16 -j .text -j .data -O binary $< $@

$(MEM): $(BIN) ../genmem
	../genmem < $(BIN) > $(MEM)

%.asm: %.elf
	llvm-objdump-16 -S $< > $@

clean::
	rm -f $(OBJS) $(DEPS) *.elf *.o *.asm *.bin *.mem

-include $(DEPS)

