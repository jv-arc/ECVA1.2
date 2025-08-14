/*
 * Assembly para Interrupção Periódica via ARM Local Timer e LIC
 * Plataforma: Raspberry Pi 2B (BCM2836)
 * Objetivo: Piscar um LED (GPIO 18) a cada interrupção do timer local.
 * Será utilizado o ARM Local Timer como ferramenta para contagem de tempo, no futuro, será responsável pela 
 * amostragem do range do arquivo de música
 */

.section .init
.globl _start

// Endereços de Periféricos
.equ PERIPH_BASE,   0x3F000000 // ERA PRA SER O ZUADO DO BCM 2835 (0x20000000) MAS ELES MUDARAM E NAO AVISARAM NINGUEM
.equ GPIO_BASE,     PERIPH_BASE + 0x200000
.equ LIC_BASE,      0x40000000 // Base dos periféricos locais (Core 0)

// Registradores do Timer Local e LIC
.equ LOCAL_TIMER_CONTROL, LIC_BASE + 0x34
.equ LOCAL_TIMER_CLEAR,   LIC_BASE + 0x38
.equ CORE0_TIMER_IRQ_CTL, LIC_BASE + 0x40

// Nosso valor de recarga do timer. Um valor maior = delay maior.
// Este valor dará um pisca-pisca de aproximadamente 2Hz.
.equ TIMER_RELOAD_VALUE, 0x01000000 

// Pino do LED
.equ LED_PIN, 18

_start:
    // --- 1. Configurar o Stack Pointer ---
    mov sp, #0x8000

    // --- 2. Configurar o GPIO para o LED ---
    ldr r0, =GPIO_BASE
    // Configurar LED_PIN (18) como SAÍDA
    ldr r1, [r0, #0x04] // Ler GPFSEL1
    mov r2, #1
    lsl r2, #24         // Criar máscara 001 para pino 18
    str r2, [r0, #0x04] // Escrever em GPFSEL1

    // --- 3. Configurar o ARM Local Timer e o LIC ---
    // Carregar o valor do contador que define o período
    ldr r0, =LOCAL_TIMER_CONTROL
    ldr r1, =TIMER_RELOAD_VALUE
    str r1, [r0] // Escreve o valor de recarga no registrador de controle

    // Habilitar o timer e a geração de interrupções
    // Valor = reload_value | enable_interrupt (bit 28) | enable_timer (bit 29)
    // Nota: O datasheet indica que habilitar o timer e a interrupção
    // é feito no registrador de controle, mas a prática comum que funciona
    // em muitos exemplos é setar o reload aqui e habilitar no passo seguinte.
    // Para simplificar, vamos seguir o fluxo de configurar o reload, depois habilitar.

    // Escrever no registrador de controle para habilitar
    mov r2, #(1 << 28)  // Habilita a interrupção (bit 28)
    orr r2, r2, #(1 << 29) // Habilita o timer (bit 29)
    orr r1, r1, r2      // Combina com o valor de reload
    str r1, [r0]        // Ativa tudo!

    // Habilitar o roteamento da interrupção do Timer no LIC para o Core 0
    ldr r0, =CORE0_TIMER_IRQ_CTL
    mov r1, #(1 << 1) // Bit 1 para habilitar o timer local como IRQ
    str r1, [r0]

    // --- 4. Instalar o Vetor de Interrupções ---
    ldr r0, =_vector_table_start
    ldr r1, =0x0
    mov r2, #8*4 // Copiar 8 palavras (32 bytes)
    copy_loop:
        ldr r3, [r0], #4
        str r3, [r1], #4
        subs r2, r2, #4
        bne copy_loop

    // --- 5. Habilitar Interrupções na CPU ---
    cpsie i

    // --- 6. Loop Principal ---
    // O programa fica aqui, ocioso. Todo o trabalho é feito na interrupção.
    main_loop:
        b main_loop

// --- Tabela de Vetores de Interrupção ---
_vector_table_start:
    b _start           // Reset
    b .                // Undefined Instruction
    b .                // Software Interrupt (SWI)
    b .                // Prefetch Abort
    b .                // Data Abort
    b .                // Reserved
    b irq_handler      // IRQ (Hardware Interrupt)
    b .                // FIQ (Fast Interrupt)

// --- Rotina de Tratamento de Interrupção (ISR) ---
irq_handler:
    // Salvar o contexto na pilha
    push {r0-r2, lr}

    // AÇÃO PRINCIPAL: Inverter o estado do LED
    ldr r0, =GPIO_BASE
    ldr r1, [r0, #0x34]     // Ler o nível atual dos pinos (GPLEV0)
    mov r2, #(1 << LED_PIN) // Criar máscara para o pino do LED
    eor r1, r1, r2          // EOR inverte o bit do LED (toggle)
    // Separar o estado do pino (ligado/desligado) para usar GPSET/GPCLR
    tst r1, r2              // O LED deve ser ligado ou desligado?
    strne r2, [r0, #0x1C]   // Se não for zero (NE), liga o LED (GPSET0)
    streq r2, [r0, #0x28]   // Se for zero (EQ), desliga o LED (GPCLR0)

    // LIMPEZA DA INTERRUPÇÃO: Crucial!
    // Limpar o flag de interrupção e recarregar o timer para o próximo ciclo
    ldr r0, =LOCAL_TIMER_CLEAR
    mov r1, #(1 << 31) | (1 << 30) // Bit 31 (clear) e Bit 30 (reload)
    str r1, [r0]

    // Restaurar o contexto da pilha
    pop {r0-r2, lr}
    // Retornar da interrupção
    subs pc, lr, #4