
MEMORY
{
   bram (rwxa)       : ORIGIN = 0x0000, LENGTH = 0x2000
   spram (rwxa)      : ORIGIN = 0x8000, LENGTH = 0x8000
}
      
_sp = 0x2000;

SECTIONS
{
   .text : { 
      . = 0x80;
      KEEP(*(.vectors));
      *(.text*) 
      *(.srodata*)
      *(.rodata*)
      *(.data*)
      *(.sdata*)
   } > bram

   .bss : { 
      _sheap = .;
      *(.sbss) 
      . = 0x4000;
      _eheap = .;
   } > spram

}

# vi: ts=3 sw=3 et
   
# .data : AT (ADDR(.text) + SIZEOF(.text)) {
