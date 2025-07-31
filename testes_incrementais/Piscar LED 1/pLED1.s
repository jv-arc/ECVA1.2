.global _start

.equ GPIO_BASE,     0x3F200000
.equ GPFSEL1,       0x04
.equ GPSET0,        0x1C
.equ GPCLR0,        0x28

_start:

    @ Configura GPFSEL
    ldr r0, =GPIO_BASE
    ldr r7, =GPFSEL1
    ldr r6, =GPSET0
    ldr r5, =GPCLR0
    ldr r1, [r0, r7]

    mov r2, #0b111
    lsl r2, r2, #24
    bic r1, r1, r2

    mov r2, #0b1
    lsl r2, r2, #24
    orr r1, r1, r2

    str r1, [r0, r7]

    @ Prepara r2 com a posicao tanto para set quanto para clear
    mov r2, #0b1
    lsl r2, r2, #18

main_loop:

    str r2, [r0, r6] @ Liga LED

    bl delay @ Espera

    str r2, [r0, r5] @ Desliga LED

    bl delay

    b main_loop

delay:
    @ prepara contador com o numero 10.000.000
    mov r3, #0b10011000
    lsl r3, r3, #16

    mov r4, #0b10010110
    lsl r4, r4, #8
    add r3, r3, r4

    mov r4, #0b10000000
    add r3, r3, r4

    b delay_loop @ pula para o loop do delay

delay_loop:

    subs r3, r3, #1  @ decrementa valor e seta flag
    
    bxeq lr @ branch se a flag deu igual

    b delay_loop  @ se nao volta pro comeco do loop

    


