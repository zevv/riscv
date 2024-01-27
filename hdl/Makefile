NAME := riscv

PCF := io.pcf
ASC := $(NAME).asc
BIN := $(NAME).bin
JSON := $(NAME).json
VP := $(NAME).vp
VCD := $(NAME).vcd

SRCS += top.v
SRCS += cpu.v
SRCS += alu.v
SRCS += machine.v
SRCS += uart.v

YOSYSFLAGS := -Q -T
NEXTPNRFLAGS := --freq 48 --package sg48 --up5k 
NEXTPNRFLAGS += --ignore-loops

all: sim

../src/t.mem: ../src/t.c

../src/t.mem:
	$(MAKE) -C ../src

sim: test.vcd

%.json: %.v ../src/t.mem
	yosys $(YOSYSFLAGS) -p "synth_ice40 -top $* -json $@" $<

%.asc: %.json
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $< --pcf $(PCF) --asc $@ -l $(NAME).log

%.bin: %.asc
	icepack $< $@

%.vp: %.v $(SRCS) ../src/t.mem
	iverilog -Wall -Winfloop -o $@ $<

%.vcd: %.vp $(SRCS)
	vvp $<

gui: $(ASC) $(PCF)
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $(JSON) --pcf $(PCF) --gui

lint: $(SRCS)
	verilator --lint-only -Wall --timing --top test test.v

prog: top.bin
	iceprog -S $<

prog_flash: $(BIN)
	iceprog $(BIN)

report: $(JSON)
	./timing.pl < $(NAME).log

clean:
	rm -rf *.json *.asc *.bin *.vp *.vcd
