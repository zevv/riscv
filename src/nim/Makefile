
NAME = nim

NSRCS += nim.nim
CSRCS += $(wildcard nimcache/*.c)

CFLAGS += -I/home/ico/external/Nim/lib

NIMFLAGS += --mm:none
NIMFLAGS += --cpu:riscv32
NIMFLAGS += --os:any
NIMFLAGS += --opt:size
NIMFLAGS += --exceptions:goto
NIMFLAGS += --nimcache:./nimcache

NIMFLAGS += -d:danger
NIMFLAGS += -d:noSignalHandler
NIMFLAGS += -d:nimPreviewSlimSystem
NIMFLAGS += -d:danger
NIMFLAGS += -d:usemalloc

all-nim: ./nimcache/@mnim.nim.c all

include ../Rules.mak

./nimcache/@mnim.nim.c: ${NSRCS}
	nim c -c ${NIMFLAGS} -o:$@ $<

clean::
	rm -rf nimcache



