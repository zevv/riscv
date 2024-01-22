MEMORY
{
   ram (rwxa)  : ORIGIN = 0x80, LENGTH = 32K
}

SECTIONS
{

   .text : { *(.text) } > ram
   .sdata = .;
   .data : { *(.data) } > ram
   .edata = .;

   .sstack = .;
   . = ALIGN(4);
   . = . + 32;
   .estack = .;
}
