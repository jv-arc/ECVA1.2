.include "GPIO_MAP.inc"
.include "PWM_MAP.inc"

.equ ON,        #1000
.equ OFF,       #0
.equ ERRO,      #500

.section .text
.global irq_handler

irq_handler:
    push {r0-r3, lr}

    ldr r0, =GPIO_BASE
    mov r1, [r0, #GPLEV0]
    
    tst r1, #0b100000000
    bne gpio7_pressed

    tst r1, #0b1000000000
    bne gpio8_pressed

    b error_detected
    
gpio8_pressed:
    tst r8, #1
    bne irq_handler_end
    mov r8, #1

    mov r2, =PWM_BASE
    mov r3, ON
    str r3, [r2, #PWM_DAT1]

    b irq_handler_end

gpio7_pressed:
    tst r8, #0
    bne irq_handler_end
    mov r8, #0

    mov r2, =PWM_BASE
    mov r3, OFF
    str r3, [r2, #PWM_DAT1]

    b irq_handler_end

error_detected:
    mov r2, =PWM_BASE
    mov r3, ERRO
    str r3, [r2, #PWM_DAT1]

irq_handler_end:
    pop {r0-r3, lr}
    bx lr
