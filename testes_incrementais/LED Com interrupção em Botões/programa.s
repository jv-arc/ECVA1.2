.section .text
.global _start

@ Posicao base para GPIO e offsets
.equ GPIO_BASE,         0x3F200000
.equ GPFSEL0,           0x00
.equ GPFSEL1,           0x04
.equ GPSET0,            0x1C
.equ GPCLR0,            0x28
.equ GPEDS0,            0x40
.equ GPFEN0,            0x58


@ Posicao base e offsets do GIC Distributor
.equ GICD_BASE,         0x40001000


@ Posicao base e offsets do GIC CPU Interface
.equ GICC_BASE,         0x40002000
.equ GICC_CTRL,         0x00
.equ GICC_PMR,          0x04
.equ GICC_IAR,          0x0C
.equ GICC_EOIR,         0x10

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
    orr r1, r0, #0b10010    @ numero do modo IRQ (0x12)
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

    @ Configura como falling edge
    ldr r1, [r0, #GPFEN0]
    orr r1, r1, r2
    str r1, [r0, #GPFEN0]

    @ Limpa interrupcoes se houver
    ldr r1, [r0, #GPEDS0]
    orr r1, r1, r2
    str r1, [r0, #GPEDS0]



    @ ============== IV. Configura GIC-400 ====================
    @ =========================================================

    @------------------- Desabilita GIC -----------------------
    ldr r0, =GICD_BASE
    

    @ 4. Configurar GIC-400
    @ 5. r8 = 0 (estado inicial)
    @ 6. GPIO17 = 1 (debug: chegou no loop)
    @ 7. Loop infinito

.align 5
vector_table:
    b   dummy_handler       ; Reset (nunca deve acontecer)
    b   dummy_handler       ; Undefined
    b   dummy_handler       ; SVC
    b   dummy_handler       ; Prefetch Abort
    b   dummy_handler       ; Data Abort
    nop                     ; Reserved
    b   irq_trampoline     ; IRQ (nosso handler real)
    b   dummy_handler       ; FIQ

dummy_handler:
    ; Acender GPIO17 + GPIO18 = algo inesperado aconteceu
    
irq_trampoline:
    ; Salvar contexto + chamar handler real

.section .bss
.align 4

stack_irq: .space 1024
stack_irq_top:

stack_svc: .space 1024
stack_svc_top: