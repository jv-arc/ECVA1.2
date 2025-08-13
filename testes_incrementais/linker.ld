/*
  Linker script para o Raspberry Pi (ARMv7-A)
  Assume que o código será carregado no endereço 0x8000
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

/* Memória do sistema */
MEMORY
{
    RAM (rwx) : ORIGIN = 0x8000, LENGTH = 128M
}

/* Seções de saída */
SECTIONS
{
    .text :
    {
        *(.text)
    } > RAM

    .rodata :
    {
        *(.rodata)
    } > RAM

    .data :
    {
        *(.data)
    } > RAM

    .bss :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    . = ALIGN(4);
    .stack_svc :
    {
        stack_svc_top = .;
        . += 1024;
    } > RAM

    .stack_irq :
    {
        stack_irq_top = .;
        . += 1024;
    } > RAM

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame)
    }
}
