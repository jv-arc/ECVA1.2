.extern irq_handler
.global _start

@ Importa mapeamentos de memoria
.include "PWM_MAP.inc"
.include "GPIO_MAP.inc"

.section .text

_start:
    @ ========== CONFIGURACAO INICIAL DO SISTEMA ==========

    @ Configura pilha do svc
    ldr sp, =stack_svc_top
    mrs r0, cpsr
    cpsid i

    @ Muda com seguranca para o modo IRQ e configura a pilha
    bic r1, r0, #0x1F
    orr r1, r0, #0b10010
    msr cpsr, r1
    ldr sp, =stack_irq_top

    @ Volta para o svc
    msr cpsr, r0
    cpsie i

    @ Configura VFBAR com vector_table
    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0
    
    @ Barreiras de sincronismo
    dsb
    isb


    @ ========== CONFIGURACAO DOS PINOS GPIO ==========

    ldr r0, =GPIO_BASE

    @ Configura pinos 7-8 como entrada (para botoes)
    ldr r1, [r0, #GPFSEL0]
    mov r2, #0b111111
    lsl r2, r2, #18
    bic r1, r1, r2
    str r1, [r0, #GPFSEL0]

    @ Configura pinos 17, 18 e 19 como saida (para LEDs de debug e PWM)
    ldr r1, [r0, #GPFSEL1]

    mov r2, #0b111111111
    lsl r2, r2, #21
    bic r1, r1, r2

    mov r2, #0b001001001
    lsl r2, r2, #21
    orr r1, r1, r2

    str r1, [r0, #GPFSEL1]


    @ ========== CONFIGURAÇÃO DE INTERRUPÇÕES GPIO ==========


    @ Habilita deteccao de borda de descida nos pinos 7 e 8 (botoes)
    ldr r1, [r0, #GPFEN0]
    mov r2, #(1 << 7)
    orr r2, r2, #(1 << 8)
    orr r1, r1, r2
    str r1, [r0, #GPFEN0]

    @ Limpa eventos pendentes nos pinos 7 e 8
    mov r2, #(1 << 7)
    orr r2, r2, #(1 << 8)
    str r2, [r0, #GPEDS0]



    @ ========== CONFIGURAÇÃO DO CONTROLADOR DE INTERRUPÇÕES ==========

    ldr r0, =0x3F00B000           
    mov r1, #(1 << 19)           
    str r1, [r0, #0x214]         

    ldr r0, =0x40000000
    mov r1, #1
    str r1, [r0, #0x00C]

    mov r1, #(1 << 8)
    str r1, [r0, #0x210]

    @ Garante que interrupções estão habilitadas
    cpsie i

    
    
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

    
    @ ========== LOOP PRINCIPAL ==========

    mov r8, #0

    b .

    @ ========== FUNÇÕES AUXILIARES ==========

delay:
    ldr r4, =500
delay_loop:
    subs r4, r4, #1
    bne delay_loop
    bx lr 

dummy_handler:
    b dummy_handler


@ ========== TABELA DE VETORES DE EXCEÇÃO ==========

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


@ ========== ÁREA DE DADOS (BSS) ==========
.section .bss
.align 4

stack_irq: .space 1024
stack_irq_top:

stack_svc: .space 1024
stack_svc_top:
