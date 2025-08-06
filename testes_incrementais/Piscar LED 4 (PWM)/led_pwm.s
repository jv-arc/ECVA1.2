.section .text
.global _start

@ Valores GPIO
.equ GPIO_BASE,     0x3F200000 
.equ GPFSEL1,       0x04
.equ GPSET0,        0x1C
.equ GPCLR0,        0x28

@ Valores PWM
.equ PWM_BASE,      0x3F20C000
.equ PWM_CTL,       0x00
.equ PWM_STA,       0x04
.equ PWM_RNG1,      0x10
.equ PWM_DAT1,      0x14

@ Valores Clock
.equ CLK_BASE,      0x3F101000
.equ PWMCLK_CNTL,   0xA0
.equ PWMCLK_DIV,    0xA4

@ Tem uma trava do processador para nao modificarem o PWM por acidente
.equ PWM_PASSWORD,  0x5A000000 

_start:
    @======Configurando os GPIO=========

    ldr r0, =GPIO_BASE

    @ Pega valor
    ldr r1, [r0, #GPFSEL1]

    @ Limpa GPIO17 em 21-23
    mov r2, #0b111
    lsl r2, r2, #21     
    bic r1, r1, r2

    @ Limpa GPIO18 em 24-26
    mov r2, #0b111
    lsl r2, r2, #24
    bic r1, r1, r2

    @ Limpa GPIO19 em 27-29
    mov r2, #0b111
    lsl r2, r2, #27
    bic r1, r1, r2

    @ Gera valor de GPIO17
    mov r2, #0b001
    lsl r2, r2, #21
    mov r3, r2

    @ Gera valor de GPIO18
    mov r2, #0b010
    lsl r2, r2, #24
    orr r3, r3, r2

    @ Gera valor de GPIO19
    mov r2, #0b001
    lsl r2, r2, #27
    orr r3, r3, r2

    @ Escreve valor de configuracao
    orr r1, r1, r3
    str r1, [r0, #GPFSEL1]


    @=========Configurando o PWM===========
    @ 1. Precisa primeiro resetar todos os valores do PWM
    @ 2. Depois configurar os valores desjados
    @ 3. So depois ligar de novo


    ldr r0, =PWM_BASE

    @------(1) Matando PWM-------

    @ Desliga controle do PWM
    mov r1, #0
    str r1, [r0, #PWM_CTL]
    str r1, [r0, #PWM_RNG1]
    str r1, [r0, #PWM_DAT1]

    @ Limpa Flags
    mov r1, #0xFF
    str r1, [r0, #PWM_STA]

    @-----------------------

    ldr r0, =CLK_BASE

    @ Zera CNTL e DIV usando PASSWORD
    ldr r1, =PWM_PASSWORD
    mov r2, #1
    lsl r2, r2, #5
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_CNTL]

    @ Aguarda o kill terminar
wait_kill: 
    ldr r2, [r0, #PWMCLK_CNTL]
    mov r3, #1
    lsl r3, r3, #7          @ Busy bit
    tst r2, r3
    bne wait_kill           @ Loop estiver ocupado

    @ Testa desligamento
    ldr r2, [r0, #PWMCLK_CNTL]
    tst r2, #(1<<4) 
    bne fail_kill

    @ Zera Div
    ldr r1, =PWM_PASSWORD
    str r1, [r0, #PWMCLK_DIV]
    bl delay

    @------(2) Configuracao--------

    @ Escreve divisor
    ldr r1, =PWM_PASSWORD
    ldr r2, =32
    lsl r2, r2, #12
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_DIV]

    bl delay

    @ Habilita clock
    ldr r1, =PWM_PASSWORD
    mov r2, #0b00010001
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_CNTL]

    @ Aguarda config terminar
wait_config: 
    ldr r2, [r0, #PWMCLK_CNTL]
    mov r3, #1
    lsl r3, r3, #7          @ Busy bit
    tst r2, r3
    bne wait_config         @ Loop estiver ocupado

    @ Testa config
    ldr r2, [r0, #PWMCLK_CNTL]
    tst r2, #(1<<4)
    beq fail_config

    bl delay

    @-------(3) Ligar PWM-----------

    ldr r0, =PWM_BASE

    @ Limpa status
    mov r1, #0xFF
    str r1, [r0, #PWM_STA]

    @ Seta range para 1000
    ldr r1, =1000
    str r1, [r0, #PWM_RNG1]

    @ Seta data para 500
    ldr r1, =300
    str r1, [r0, #PWM_DAT1]

    @ Habilita PWM0
    mov r1, #0x81
    str r1, [r0, #PWM_CTL]

    b controle

controle:

    @ Liga os dois para garantir que chegou no fim 
    mov r2, #0b101
    lsl r2, r2, #17

    ldr r0, =GPIO_BASE
    str r2, [r0, #GPSET0]

    b end

fail_kill: 

    @ Liga GPIO17
    mov r2, #1
    lsl r2, r2, #17

    ldr r0, =GPIO_BASE
    str r2, [r0, #GPSET0]

    b end


fail_config: 

    @ Liga GPIO19
    mov r2, #1
    lsl r2, r2, #19

    ldr r0, =GPIO_BASE
    str r2, [r0, #GPSET0]

    b end


end:
    b end

delay:
    ldr r4, =500
delay_loop:
    subs r4, r4, #1
    bne delay_loop
    bx lr 
