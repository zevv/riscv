
MEMORY
{
   registers (rwxa)  : ORIGIN = 0x0000, LENGTH = 0x0080
   bram (rwxa)       : ORIGIN = 0x0080, LENGTH = 0x1f80
   spram (rwxa)      : ORIGIN = 0x8000, LENGTH = 0x8000
}

SECTIONS
{
   .text : { 
      *(.vectors);
      *(.text*) 
      *(.srodata*)
      *(.rodata*)
      *(.data*)
      *(.sdata*)
      _sp = 0x2000;
   } > bram

   .bss : { 
      *(.sbss) 
   } > spram

}

# vi: ts=3 sw=3 et
   
# .data : AT (ADDR(.text) + SIZEOF(.text)) {
