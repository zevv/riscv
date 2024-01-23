
MEMORY
{
   ram (rwxa)      : ORIGIN = 0x80, LENGTH = 32K
}

SECTIONS
{

   .text : { 
      *(.vectors);
      .stext = .;
      *(.text) 
   } > ram

   .sdata = .;
   .data : { 
      *(.data) 
   } > ram
   .edata = .;

   .sstack = .;
   . = ALIGN(4);
   . = . + 32;
   .estack = .;
}

# vi: ts=3 sw=3 et
