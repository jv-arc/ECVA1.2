.extern irq_handler
.global _start

.include "PWM_MAP.inc"
.include "GPIO_MAP.inc"

.section .text

_start:
    @ Configura pilha
    ldr sp, =stack_svc_top
    mrs r0, cpsr
    cpsid i
    bic r1, r0, #1F
    orr r1, r0, #0b10010
    msr cpsr, r1
    ldr sp, =stack_irq_top
    msr cpsr, r0
    cpsie i

    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0

    dsb
    isb

    ldr r0, =GPIO_BASE

    ldr r1, [r0, #GPFSEL0]
    mov r2, #0b111111
    lsl r2, r2, #18
    bic r1, r1, r2
    str r1, [r0, #GPFSEL0]

    ldr r1, [r0, #GPFSEL1]
    mov r2, #0b111111111
    lsl r2, r2, #21
    bic r1, r1, r2
    mov r2, #0b001001001
    lsl r2, r2, #21
    orr r1, r1, r2
    str r1, [r0, #GPFSEL1]

.align 5
vector_table:
    b   dummy_handler   @ Reset
    b   dummy_handler   @ Undefined
    b   dummy_handler   @ SVC
    b   dummy_handler   @ Prefetch Abort
    b   dummy_handler   @ Prefetch Abort
    nop                 @ Reserved
    b   irq_handler     @ IRQ
    b   dummy_handler   @ FIQ

.section .bss
.align 4

stack_irq: .space 1024
stack_irq_top:

stack_svc: .space 1024
stack_svc_top:
