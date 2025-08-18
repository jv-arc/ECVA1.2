@=============================================
@ Mapa de Memoria dos GPIO
@ Para Raspberry 2B (BCM2836)
@=============================================

@ Base dos GPIO
.equ GPIO_BASE,     0x3F200000

@------------------Principais------------------

@ GPFSELx
.equ GPFSEL0,       0x00
.equ GPFSEL1,       0x04
.equ GPFSEL2,       0x08
.equ GPFSEL3,       0x0C
.equ GPFSEL4,       0x10
.equ GPFSEL5,       0x14

@ GPSETx
.equ GPSET0,        0x1C
.equ GPSET1,        0x20

@ GPCLRx
.equ GPCLR0,        0x28
.equ GPCLR1,        0x2C

@-------------------Leitura--------------------

@ Pin Level
.equ GPLEV0,        0x34
.equ GPLEV1,        0x38

@ Event Detect
.equ GPEDS0,        0x40
.equ GPEDS1,        0x44

@ Rising Edge Detect
.equ GPREN0,        0x4C
.equ GPREN1,        0x50

@ Faling Edge Detect
.equ GPFEN0,        0x58
.equ GPFEN1,        0x5C
@=============================================
@ Mapa de Memoria do PWM 
@ Para Raspberry 2B (BCM2836)
@=============================================

@---------------------PWM----------------------

@ Base do PWM
.equ PWM_BASE,      0x3F20C000

@ Controle
.equ PWM_CTL,       0x00
.equ PWM_STA,       0x08

@ Canal 1
.equ PWM_RNG1,      0x10
.equ PWM_DAT1,      0x14

@ Canal 2
.equ PWM_RNG2,      0x20
.equ PWM_DAT2,      0x24


@-------------------PWMCLK--------------------

@ Base do PWMCLK
.equ PWMCLK_BASE,   0x3F1010A0

@ Clock Control
.equ PWMCLK_CNTL,   0x00
.equ PWMCLK_DIV,    0x04

@ Senha
.equ PWM_PASSWD,    0x5A000000

@==================================================
@ Mapa de Memoria dos controles de Interupcao
@ Para Raspberry 2B - BCM2836 com BCM2835 (legado)
@==================================================

@---------------Enderecos do BCM2835---------------

@ Endereco base
.equ BCM2835_INT_BASE,  0x3F00B200

@ Offset dos controladores de interrupcao
.equ IRQs_ENABLE1,  0x10
.equ IRQs_ENABLE2,  0x14



@---------------Enderecos do BCM2836---------------

@ Endereco base
.equ BCM2836_INT_BASE,  0x40000000

@ Offset dos controles dos cores
.equ IRQCNTL_CORE0, 0x60
.equ IRQCNTL_CORE1, 0x64
.equ IRQCNTL_CORE2, 0x68
.equ IRQCNTL_CORE3, 0x6C

@ Offset do roteamento de GPU IRQ
.equ GPUIRQ_ROUT,   0x0C

@ OPCODE
.equ branch_instruction, 0b11101010


@ importa handler
@.extern irq_handler


.section .text
.global _start


_start:
    @ ========== CONFIGURACAO INICIAL DO SISTEMA ==========

    @ Configura pilha do svc
    ldr sp, =stack_svc_top
    mrs r0, cpsr
    cpsid i

    @ Muda com seguranca para o modo IRQ e configura a pilha
    bic r1, r0, #0x1F
    orr r1, r1, #0b10010
    msr cpsr, r1
    ldr sp, =stack_irq_top

    @ Volta para o svc
    msr cpsr, r0
    cpsie i

    ldr r0, =vector_stub
    ldr r1, [r0]
    mov r0, #0x18
    str r1, [r0]

    ldr r0, =0x3F00B000
    ldr r1, =5000000
    str r1, [r0, #0x400]
    ldr r1, =0xA2
    str r1, [r0, #0x408]
    ldr r0, =0x3F00B000
    ldr r1, =0x1
    str r1, [r0, #0x218]


    @ Configura VBAR com vector_table
    @ldr r0, =vector_table
    @mcr p15, 0, r0, c12, c0, 0
    
    @ Barreiras de sincronismo
    @dsb
    @isb

    @ Configura sinais de erro
    bl error_config

    @ Sinaliza fim da configuracao basica
    bl error_101
    bl long_delay
    bl error_000
    bl long_delay
    bl long_delay
    bl long_delay

    @ ========== CONFIGURACAO DOS PINOS GPIO ==========

    ldr r0, =GPIO_BASE

    @ Configura pinos 3 e 4 como entrada (para botoes)
    ldr r1, [r0, #GPFSEL0]
    mov r2, #0b111111
    lsl r2, r2, #9
    bic r1, r1, r2
    str r1, [r0, #GPFSEL0]

    @ Configura pinos 18 e 15 como saida (para LED e PWM)
    ldr r1, [r0, #GPFSEL1]

    mov r2, #0b111000000111
    lsl r2, r2, #15
    bic r1, r1, r2

    mov r2, #0b010000000001
    lsl r2, r2, #15
    orr r1, r1, r2

    str r1, [r0, #GPFSEL1]

    @ ------- Teste de Botoes ------------

    ldr r1, [r0, #GPLEV0]

    @ Testa botão 3
    tst r1, #(1<<3)
    beq button3_pressed    @ Se LOW, botão está pressionado
    
fim_teste_botao3:
    nop

    @ Testa botão 4
    tst r1, #(1<<4) 
    beq button4_pressed

    b end_button_test

button3_pressed:
    bl error_001           @ LED padrão 001 quando botão 3
    bl long_delay
    bl error_000
    bl long_delay
    bl error_001
    bl long_delay
    bl error_000
    bl long_delay
    b  fim_teste_botao3
    
button4_pressed:
    bl error_010           @ LED padrão 010 quando botão 4
    bl long_delay
    bl error_000
    bl long_delay
    bl error_010
    bl long_delay
    bl error_000
    bl long_delay
    b end_button_test

end_button_test:
    bl long_delay
    bl long_delay
    bl long_delay


    @ ========== CONFIGURAÇÃO DE INTERRUPÇÕES GPIO ==========

    @ Pinos 3 e 4 (botoes)
    mov r2, #0b11
    lsl r2, r2, #3
    str r2, [r0, #GPEDS0]

    ldr r1, [r0, #GPFEN0]
    orr r1, r1, r2
    str r1, [r0, #GPFEN0]
    



    @ ====== CONFIGURACAO DE INTERRUPCAO NO BCM2835 ========
    @ 3 e 4 ficam na IRQ 49

    ldr r0, =BCM2835_INT_BASE
    mov r1, #1
    lsl r1, r1, #17
    str r1, [r0, #IRQs_ENABLE2]         






    @ ====== CONFIGURACAO DE INTERRUPCAO NO BCM2836 ========

    ldr r0, =BCM2836_INT_BASE

    @ Habilita interrupcao 8
    mov r1, #1
    lsl r1, r1, #8
    str r1, [r0, #IRQCNTL_CORE0]

    @ Roteia para core 0
    mov r1, #0
    str r1, [r0, #GPUIRQ_ROUT]
    
    @ Garante que interrupções estão habilitadas
    cpsie i


    @ Sinaliza fim da configuracao de interrupcao
    bl error_010
    bl long_delay
    bl error_000
    bl long_delay
    bl long_delay
    bl long_delay

    
    
    @ ========== CONFIGURACAO COMPLETA DO PWM ==========
    @ Processo em 3 etapas: Reset -> Configuracao -> Ativacao

    ldr r0, =PWM_BASE

    @ -------- ETAPA 1: RESETAR PWM --------
    
    @ Desliga completamente o controle PWM
    mov r1, #0
    str r1, [r0, #PWM_CTL]
    str r1, [r0, #PWM_RNG1]
    str r1, [r0, #PWM_DAT1]

    @ Limpa todas as flags de status
    mov r1, #0xFF
    str r1, [r0, #PWM_STA]

    @ -------- CONFIGURACAO DO CLOCK PWM --------

    ldr r0, =PWMCLK_BASE

    @ Para o clock PWM com senha de proteção
    ldr r1, =PWM_PASSWD
    mov r2, #1
    lsl r2, r2, #5
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_CNTL]

    @ Aguarda ate o clock parar completamente
wait_kill: 
    ldr r2, [r0, #PWMCLK_CNTL]
    mov r3, #1
    lsl r3, r3, #7          @ Busy bit
    tst r2, r3
    bne wait_kill           @ Loop estiver ocupado

    @ Zera o divisor de clock
    ldr r1, =PWM_PASSWD
    str r1, [r0, #PWMCLK_DIV]
    bl delay

    @ -------- ETAPA 2: CONFIGURAR CLOCK --------

    @ Define divisor de clock (32 = clock original / 32)
    ldr r1, =PWM_PASSWD
    ldr r2, =32
    lsl r2, r2, #12
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_DIV]

    bl delay

    @ Habilita clock PWM
    ldr r1, =PWM_PASSWD
    mov r2, #0b00010001
    orr r1, r1, r2
    str r1, [r0, #PWMCLK_CNTL]

    @ Aguarda configuracao do clock terminar
wait_config: 
    ldr r2, [r0, #PWMCLK_CNTL]
    mov r3, #1
    lsl r3, r3, #7          @ Busy bit
    tst r2, r3
    bne wait_config         @ Loop estiver ocupado

    bl delay

    @ -------- ETAPA 3: CONFIGURAR E ATIVAR PWM --------

    ldr r0, =PWM_BASE

    @ Limpa flags de status novamente
    mov r1, #0xFF
    str r1, [r0, #PWM_STA]

    @ Define periodo PWM (valor maximo do contador)
    ldr r1, =1000
    str r1, [r0, #PWM_RNG1]

    @ Define duty cycle inicial (30% = 300/1000)
    ldr r1, =300
    str r1, [r0, #PWM_DAT1]

    @ Ativa PWM no canal 1
    mov r1, #0x81
    str r1, [r0, #PWM_CTL]

    
    @ Sinaliza fim da configuracao de PWM
    bl error_100
    bl long_delay
    bl error_000
    bl long_delay
    bl long_delay
    bl long_delay



    @ ========== PROGRAMA PRINCIPAL ==========

    @ Inicializa variavel de controle
    mov r8, #0

    @ Sinaliza fim da configuracao
    bl error_111

    @ Loop Principal
loop_infinito:
    cmp r8, #0
    beq loop_infinito

liga:
    bl error_011
    b loop_infinito

    @ ========== FUNÇÕES AUXILIARES ==========

delay:
    ldr r4, =500
delay_loop:
    subs r4, r4, #1
    bne delay_loop
    bx lr 


long_delay:
    ldr r4, =2000000
long_delay_loop:
    subs r4, r4, #1
    bne long_delay_loop
    bx lr 

dummy_handler:
    bl error_001
    bl long_delay
    bl error_010
    bl long_delay
    bl error_100
    bl long_delay
    b dummy_handler

reset_handler:
    bl error_111
    bl long_delay
    bl error_000
    bl error_111
    bl long_delay
    bl error_000
    bl error_111
    bl long_delay
    bl error_000
    b _start

vector_stub:
    b irq_handler

irq_handler:
    sub lr, lr, #4
    stmfd sp!, {r0-r2, lr}
    
    @ Apenas incrementa contador e limpa
    add r8, r8, #1
    
    ldr r0, =GPIO_BASE
    mov r1, #0b11000        @ Limpa GPIO 3 e 4
    str r1, [r0, #GPEDS0]
    
    ldmfd sp!, {r0-r2, pc}^

@ ========================================================
@ Define funções que acendem pinos especificos para debug
@ Faz uso dos GPIO 16, 20 e 21
@ ========================================================


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





@ ========== TABELA DE VETORES DE EXCEÇÃO ==========

@.section .vectors
@.align 5
@vector_table:
@    b   reset_handler   @ Reset
@    b   dummy_handler   @ Undefined
@    b   dummy_handler   @ SVC
@    b   dummy_handler   @ Prefetch Abort
@    b   dummy_handler   @ Data Abort
@    nop                 @ Reserved
@    b   irq_handler     @ IRQ
@    b   dummy_handler   @ FIQ


@ ========== ÁREA DE DADOS (BSS) ==========
.section .bss
.align 4

stack_irq: .space 1024
stack_irq_top:

stack_svc: .space 1024
stack_svc_top:

