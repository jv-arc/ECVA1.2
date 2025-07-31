.section .text
.global _start

.equ GPIO_BASE,         0x3F200000
.equ GPFSEL1,           0x04
.equ GPSET0,            0x1C
.equ GPCLR0,            0x28

.equ SYS_TIMER_BASE,    0x3F003000
.equ SYS_TIMER_CLO,     0x04
.equ SYS_TIMER_CHI,     0x08


_start:
    @ Configura o GPIO 18
    ldr r0, =GPIO_BASE
    ldr r1, [r0, #GPFSEL1]

    mov r2, #0b111
    lsl r2, r2, #24
    bic r1, r1, r2

    mov r2, #0b1
    lsl r2, r2, #24
    orr r1, r1, r2

    str r1, [r0, #GPFSEL1]

    @ escolhe GPIO 18
    mov r2, #1
    lsl r2, r2, #18

    @ Seta tempo em microsegundos
    mov r3, #1
    lsl r3, r3, #19 @ aproximadamente meio segundo

main_loop:
    bl set_high
    bl wait
    bl set_low
    bl wait
    b main_loop

set_high:
    str r2, [r0, #GPSET0]
    bx lr

set_low:
    str r2, [r0, #GPCLR0]
    bx lr

wait:
    ldr r4, =SYS_TIMER_BASE
    ldr r5, [r4, #SYS_TIMER_CLO]
    add r5, r5, r3

wait_loop:
    ldr r6, [r4, #SYS_TIMER_CLO]
    cmp r6, r5
    blo wait_loop
    bx lr

