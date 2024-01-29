NAME := riscv

PCF := io.pcf
ASC := $(NAME).asc
BIN := $(NAME).bin

FREQ := 16

SRCS += top.v
SRCS += cpu.v
SRCS += alu.v adder.v
SRCS += machine.v
SRCS += uart.v
SRCS += bram.v
SRCS += pll.v

YOSYSFLAGS := -Q -T
NEXTPNRFLAGS := --freq 48 --package sg48 --up5k 
NEXTPNRFLAGS += --ignore-loops --timing-allow-fail

all: sim

../src/t.mem: ../src/t.c ../src/script.lds

../src/t.mem:
	$(MAKE) -C ../src

sim: test.vcd

pll.v: Makefile
	icepll -i 12 -o $(FREQ) -m -f pll.v


%.json: %.v $(SRCS) ../src/t.mem
	yosys $(YOSYSFLAGS) -p "synth_ice40 -top $* -json $@" $<

%.asc: %.json
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $< --pcf $(PCF) --asc $@ -l $(NAME).log

%.bin: %.asc
	icepack $< $@

%.vp: %.v $(SRCS) ../src/t.mem
	iverilog -g2005-sv -Wall -Winfloop -o $@ $<

%.vcd: %.vp $(SRCS)
	vvp $<

lint: $(SRCS)
	verilator --lint-only -Wall --timing --top test test.v

prog: top.bin
	iceprog -S $<

prog_flash: $(BIN)
	iceprog $(BIN)

report: top.asc
	#@./timing.pl < $(NAME).log
	@grep % $(NAME).log
	@grep "Max freq" $(NAME).log

clean:
	rm -rf *.json *.asc *.bin *.vp *.vcd pll.v
	make -C ../src clean
