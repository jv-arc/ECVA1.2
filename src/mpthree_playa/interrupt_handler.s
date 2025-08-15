.include "GPIO_MAP.inc"
.include "PWM_MAP.inc"

.extern error_111

.section .text
.global irq_handler

irq_handler:
    push {r0-r3, lr}

    ldr r0, =GPIO_BASE
    ldr r1, [r0, #GPLEV0]
    
    tst r1, #0b1000
    beq gpio3_pressed

    tst r1, #0b10000
    beq gpio4_pressed

    bl error_111
    b irq_handler_end
    
gpio3_pressed:
    @ Checa/Modifica Estado
    tst r8, #1
    bne irq_handler_end
    mov r8, #1

    @ Seta PWM para valor alto
    ldr r2, =PWM_BASE
    mov r3, #1000
    str r3, [r2, #PWM_DAT1]

    b irq_handler_end

gpio4_pressed:
    @ Checa/Modifica Estado
    cmp r8, #0
    beq irq_handler_end
    mov r8, #0

    @ Seta PWM para valor baixo
    ldr r2, =PWM_BASE
    mov r3, #300
    str r3, [r2, #PWM_DAT1]

    b irq_handler_end

irq_handler_end:

    @ Limpa Interrupcao
    ldr r0, =GPIO_BASE
    mov r2, #0b11
    lsl r2, r2, #3
    str r2, [r0, #GPEDS0]

    @ Sai
    pop {r0-r3, lr}
    subs pc, lr, #4

