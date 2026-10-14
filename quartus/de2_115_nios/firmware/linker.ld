ENTRY(_start)
MEMORY { RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K }
SECTIONS {
 .text : { KEEP(*(.text.start)) *(.text*) *(.rodata*) } > RAM
 .data : { *(.data*) *(.sdata*) } > RAM
 . = ALIGN(4);
 PROVIDE(__global_pointer$ = . + 0x800);
 .bss (NOLOAD) : { _bss_start = .; *(.bss*) *(.sbss*) *(COMMON) . = ALIGN(4); _bss_end = .; } > RAM
 _stack_top = ORIGIN(RAM)+LENGTH(RAM);
 ASSERT(_bss_end < _stack_top-4096, "Firmware leaves less than 4KB stack")
}
