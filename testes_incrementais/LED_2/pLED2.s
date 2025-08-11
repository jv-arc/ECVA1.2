
.section .text
.global _start

.equ GPIO_BASE,     0x3F200000
.equ GPFSEL1,       0x04
.equ GPSET0,        0x1C
.equ GPCLR0,        0x28


_start:
    @ cria stack pointer
    @ ldr sp, =0x80000

    @ Configura pinos
    bl gpio_init

    @ Seleciona GPIO 18 para uso
    mov r0, #0b1
    lsl r0, r0, #18

    ldr r4, =GPIO_BASE
    ldr r5, =GPSET0
    ldr r6, =GPCLR0

    b main_loop

main_loop:
    bl set_HIGH

    bl delay_10MILHOES

    bl set_LOW

    bl delay_10MILHOES

    b main_loop

gpio_init:
    ldr r0, =GPIO_BASE
    ldr r1, [r0, #GPFSEL1]
    
    mov r2, #0b111
    lsl r2, r2, #24
    bic r1, r1, r2

    mov r2, #0b1
    lsl r2, r2, #24
    orr r1, r1, r2

    str r1, [r0, #GPFSEL1]
    
    bx lr

set_HIGH:
    @ Seta os pinos em r0 para 1 (HIGH)
    @push {r4}

    @ldr r4, =GPIO_BASE
    str r0, [r4, r5]

    @pop {r4}
    bx lr


set_LOW:
    @ Seta os pinos em r0 para 0 (LOW)
    @push {r4}

    @ldr r4, =GPIO_BASE
    str r0, [r4, r6]

    @pop {r4}
    bx lr


delay_10MILHOES:
    @push {r0, r1}
    
    @ Prepara 10.000.000 para o contador
    mov r2, #0b10011000
    lsl r2, r2, #16

    mov r3, #0b10010110
    lsl r3, r3, #8
    add r2, r2, r3

    mov r3, #0b10000000
    add r2, r2, r3

delay_loop:
    subs r2, r2, #1 @ decrementa contador
    beq delay_exit  @ se o resultado for 0 sai
    b delay_loop    @ se nao, continua decrementando

delay_exit:
    @pop {r0, r1}
    bx lr
    