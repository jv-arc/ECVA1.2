.section .text
.global _start

.include "posicoes.inc"

_start:
    @ ======== I.Configuracao dos stack pointers ===============
    @ Configuracao do sp_svc e sp_irq manipulando o cpsr
    @ ==========================================================

    @ Configura sp_svc diretamente
    ldr sp, =stack_svc_top

    @ Troca para irq com seguranca
    mrs r0, cpsr
    cpsid i
    bic r1, r0, #1F
    orr r1, r0, #0b10010     @ numero do modo IRQ (0x12)
    msr cpsr, r1

    @ configura sp_irq
    ldr sp, =stack_irq_top

    @ volta para o estado original armazenado em r0
    msr cpsr, r0
    
    @ liga interrupcoes
    cpsie i


    @ ============== II. Configuracao do VBAR =================
    @ Escreve no VBAR no CP15
    @ =========================================================

    @ Faz a escrita
    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0
    
    @ Garante sincronicidade
    dsb       
    isb


    @ ============= III. Configura GPIO(s) ====================
    @ GPIO 19 e o LED alvo, 17/18 de debug, 7/8 de botao
    @ =========================================================

    ldr r0, =GPIO_BASE

    @------- Configura GPFSEL0 -----------
    ldr r1, [r0, #GPFSEL0]

    @ Limpa GPIOs 7 e 8
    mov r2, #0b111111
    lsl r2, r2, #18
    bic r1, r1, r2

    @ Nao precisa gerar valores, input e '000'

    @ Escreve em GPFSEL0
    str r1, [r0, #GPFSEL0]


    @------- Configura GPFSEL1 -----------
    ldr r1, [r0, #GPFSEL1]

    @ Limpa GPIOs 17, 18 e 19
    mov r2, #0b111111111
    lsl r2, r2, #21
    bic r1, r1, r2

    @ Gera valor para GPIO 17, 18 e 19 (saida)
    mov r2, #0b001001001 @ '001' para cada
    lsl r2, r2, #21
    orr r1, r1, r2

    @ Escreve em GPFSEL1
    str r1, [r0, #GPFSEL1]


    @-------- Prepara 7/8 pra botoes -------
    @ Cria palavra pro 7 e pro 8
    mov r2, #0b11
    lsl r2, r2, #7

    @ Configura GPIO 7 e 8 como falling edge
    ldr r1, [r0, #GPFEN0]
    orr r1, r1, #0b110000000
    str r1, [r0, #GPFEN0]
    
    @ Limpa interrupcoes se houver
    ldr r1, [r0, #GPEDS0]
    orr r1, r1, r2
    str r1, [r0, #GPEDS0]


    @ ============== IV. Configura GIC-400 ====================

    @----------------- 3. Loop infinito ----------------
    mov r8, #0          @ Contador (estado inicial)

    @ Acende GPIO17 para debug
    ldr r0, =GPIO_BASE
    mov r1, #1
    lsl r1, r1, #17
    str r1, [r0, #GPSET0]


loop:
    b loop


.align 5
vector_table:
    b   dummy_handler           @ Reset
    b   dummy_handler           @ Undefined
    b   dummy_handler           @ SVC
    b   dummy_handler           @ Prefetch Abort
    b   dummy_handler           @ Data Abort
    nop                         @ Reserved
    b   irq_trampoline          @ IRQ (nosso handler :p)
    b   dummy_handler           @ FIQ

dummy_handler:
    @ Acender GPIO17 + GPIO18 = algo inesperado aconteceu
    ldr r0, =GPIO_BASE
    mov r1, #1
    lsl r1, r1, #17
    orr r1, r1, #0b100000000000000000
    str r1, [r0, #GPSET0]
    b dummy_handler

irq_trampoline:
    @ Salva o contexto do processador
    sub sp, sp, #4*13
    stmfd sp!, {r0-r12}

    @ Chama a rotina de interrupcao
    bl irq_handler

    @ Restaura o contexto
    ldmfd sp!, {r0-r12}
    add sp, sp, #4*13
    
    @ Retorna da interrupcao
    subs pc, lr, #4

irq_handler:
    @ Acessa o GICC para saber qual interrupcao ocorreu
    ldr r0, =GICC_BASE
    ldr r1, [r0, #GICC_IAR]
    
    @ Checa se a interrupcao e do GPIO (ID 49)
    cmp r1, #49
    bne irq_final

    @ Se a interrupcao e do GPIO, checa se e o 7 ou o 8
    ldr r0, =GPIO_BASE
    ldr r2, [r0, #GPEDS0]
    
    mov r3, #1
    lsl r3, r3, #7
    and r3, r3, r2
    cmp r3, #0
    bne gpio7_pressed

    mov r3, #1
    lsl r3, r3, #8
    and r3, r3, r2
    cmp r3, #0
    bne gpio8_pressed


gpio7_pressed:
    @ Acende o LED (GPIO 19)
    ldr r0, =GPIO_BASE
    mov r1, #1
    lsl r1, r1, #19
    str r1, [r0, #GPSET0]
    b clear_irq_gpio

gpio8_pressed:
    @ Apaga o LED (GPIO 19)
    ldr r0, =GPIO_BASE
    mov r1, #1
    lsl r1, r1, #19
    str r1, [r0, #GPCLR0]
    b clear_irq_gpio

clear_irq_gpio:
    @ Limpa a interrupcao no GPIO (necessario para a proxima interrupcao)
    ldr r0, =GPIO_BASE
    ldr r2, [r0, #GPEDS0]
    str r2, [r0, #GPEDS0]
    
irq_final:
    @ Fim da interrupcao
    mov r2, #1023 @ EOF, end of file
    str r2, [r0, #GICC_EOIR]
    bx lr

.section .bss
.align 4

stack_irq: .space 1024
stack_irq_top:

stack_svc: .space 1024
stack_svc_top:
