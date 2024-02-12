NAME := riscv

PCF := io.pcf
ASC := $(NAME).asc
BIN := $(NAME).bin

FREQ := 16

SRCS += top.v
SRCS += cpu.v
SRCS += regs.v
SRCS += alu.v adder.v
SRCS += machine.v
SRCS += uart.v
SRCS += bram.v
SRCS += spram.v
SRCS += led.v
SRCS += pll.v
SRCS += common.v
SRCS += spiflash.v

YOSYSFLAGS := -Q -T
NEXTPNRFLAGS := --freq $(FREQ) --package sg48 --up5k 
NEXTPNRFLAGS += --timing-allow-fail

YOSYSFLAGS += -q
NEXTPNRFLAGS += -q

LAST_PROJ := $(strip $(shell cat .proj 2>/dev/null))
ifeq ($(strip $(PROJ)),)
PROJ=$(LAST_PROJ)
endif


SBY := PATH=$$PATH:/home/ico/external/yices2/build/x86_64-pc-linux-gnu-release/dist/bin python ~/external/sby/sbysrc/sby.py

all: sim sby report

sim: test.vcd

pll.v: Makefile
	icepll -q -i 48 -o $(FREQ) -m -f pll.v

bram.mem: ../src/$(PROJ)/$(PROJ).mem
	ln -sf ../src/$(PROJ)/$(PROJ).mem bram.mem
	echo $(PROJ) > .proj

.PHONY: ../src/$(PROJ)/$(PROJ).mem
../src/$(PROJ)/$(PROJ).mem:
	make -C ../src/$(PROJ)

bram.v: bram.mem
	touch $@

%.json: %.v $(SRCS)
	yosys $(YOSYSFLAGS) -p "synth_ice40 -top $* -noflatten -json $@" -l yosys.log $<

%.asc: %.json
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $< --pcf $(PCF) --asc $@ -l nextpnr.log

%.bin: %.asc
	icepack $< $@

%.vp: %.v $(SRCS) 
	iverilog -g2005-sv -Wall -Winfloop -o $@ $<

%.vcd: %.vp $(SRCS)
	test -r bram.mem && vvp $<

sby:
	$(SBY) -f cpu.sby

lint: $(SRCS)
	verilator --lint-only -Wall --timing --top cpu cpu.v

prog: top.bin
	iceprog -S $<

prog_flash: top.bin
	iceprog $<

report: top.asc
	#@./timing.pl < $(NAME).log
	@grep % nextpnr.log
	@grep "Max freq" nextpnr.log

clean:
	rm -rf *.json *.asc *.bin *.vp *.vcd pll.v *.log *_cover/ *_basic/ bram.mem
