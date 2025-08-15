@ ========================================================
@ Define funções que acendem pinos especificos para debug
@ Faz uso dos GPIO 16, 20 e 21
@ ========================================================

.include "GPIO_MAP.inc"

.section .text

.global error_config

.global error_000 
.global error_001 
.global error_010
.global error_011 
.global error_100 
.global error_101
.global error_110 
.global error_111 


@ Bits para os Leds
.equ LEDs_111,     0b1100010000000000000000
.equ LEDs_110,     0b1100000000000000000000
.equ LEDs_101,     0b1000010000000000000000
.equ LEDs_100,     0b1000000000000000000000  
.equ LEDs_011,     0b0100010000000000000000
.equ LEDs_010,     0b0100000000000000000000
.equ LEDs_001,     0b0000010000000000000000


@ Configura os GPIO como Saída
error_config:
    push {r0, r1, r2}

    ldr r0, =GPIO_BASE


    @ Configura GPIO 16
    ldr r1, [r0, #GPFSEL1]         
    mov r2, #0x1C0000    
    bic r1, r1, r2
    mov r2, #0x40000
    orr r1, r1, r2     
    str r1, [r0, #GPFSEL1]

    @ Configura GPIOs 20 e 21
    ldr r1, [r0, #GPFSEL2]
    mov r2, #0x3F
    bic r1, r1, r2
    mov r2, #0x9
    orr r1, r1, r2
    str r1, [r0, #GPFSEL2]


    pop {r0, r1, r2}
    bx lr

error_000:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ desligar GPIOs
    ldr r1, =LEDs_111
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_001:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_001
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_110
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_010:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_010
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_101
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_011:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_011
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_100
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_100:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_100
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_011
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_101:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_101
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_010
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_110:
    push {r0, r1}

    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_110
    str r1, [r0, #GPSET0]
    
    @ desligar GPIOs
    ldr r1, =LEDs_001
    str r1, [r0, #GPCLR0]

    pop {r0, r1}
    bx lr

error_111:
    push {r0, r1}
    ldr r0, =GPIO_BASE

    @ ligar GPIOs
    ldr r1, =LEDs_111
    str r1, [r0, #GPSET0]

    pop {r0, r1}
    bx lr 


