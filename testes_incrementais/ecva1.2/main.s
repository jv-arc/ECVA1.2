.section .text
.global _start

// --- Constantes de Hardware ---
.equ GPIO_BASE,        0x3F200000
.equ GPFSEL1,          0x04
.equ GPSET0,           0x1C
.equ GPCLR0,           0x28

.equ SYS_TIMER_BASE,   0x3F003000
.equ SYS_TIMER_CS,     0x00
.equ SYS_TIMER_CLO,    0x04
.equ SYS_TIMER_C1,     0x10

.equ IRQ_CONTROLLER,   0x3F00B000
.equ ENABLE_IRQS_1,    0x210

// --- Referências Externas (Geradas pelo Python) ---
// O nome do label é o nome do arquivo de áudio sem a extensão.
// Se seu arquivo for 'daft_punk.mp3', os labels serão 'daft_punk' e 'daft_punk_len'.
.extern daft_punk
.extern daft_punk_len

// --- Tabela de Vetores de Exceção ---
_start:
    b       start_code
    b       .
    b       .
    b       .
    b       .
    b       .
    b       irq_handler
    b       .

// --- Código Principal de Inicialização ---
start_code:
    // 1. Configurar Stack Pointer (para salvar registradores)
    mov     sp, #0x8000

    // 2. Carregar informações da música em registradores permanentes
    ldr     r8, =daft_punk        // r8 -> Ponteiro para o início dos dados da música
    ldr     r9, =daft_punk_len    // r9 -> Ponteiro para a variável de tamanho
    ldr     r9, [r9]              // r9 = Valor do tamanho (número de amostras)
    mov     r10, #0               // r10 = Índice atual da música (começa em 0)

    // 3. Configurar GPIO 18 como saída
    ldr     r0, =GPIO_BASE
    ldr     r1, [r0, #GPFSEL1]
    mov     r2, #0b111; lsl r2, r2, #24; bic r1, r1, r2
    mov     r2, #0b1; lsl r2, r2, #24; orr r1, r1, r2
    str     r1, [r0, #GPFSEL1]

    // 4. Configurar a primeira interrupção do Timer (para daqui a 22 microssegundos)
    // 1 / 44100 Hz (nossa taxa de amostragem) ~= 22.6 microssegundos.
    ldr     r0, =SYS_TIMER_BASE
    ldr     r1, [r0, #SYS_TIMER_CLO]
    add     r1, r1, #22
    str     r1, [r0, #SYS_TIMER_C1]

    // 5. Habilitar a interrupção do Timer no controlador de IRQs
    ldr     r0, =IRQ_CONTROLLER
    mov     r1, #1 << 1
    str     r1, [r0, #ENABLE_IRQS_1]

    // 6. Habilitar interrupções IRQ no processador
    mrs     r0, cpsr
    bic     r0, r0, #0x80
    msr     cpsr_c, r0

    // 7. Entrar em loop infinito. O trabalho real será feito pelo tratador de interrupções.
main_loop:
    b       main_loop

// --- Tratador de Interrupções (ISR) ---
// Este código é executado a cada ~22 microssegundos
irq_handler:
    // Salva os registradores que vamos modificar no stack
    push    {r0-r7, lr}

    // --- Lógica da Música ---
    // Carrega o byte PWM da posição atual da música
    // r8 (base) + r10 (índice)
    ldrb    r3, [r8, r10]         // r3 = daft_punk[índice]

    // --- Lógica do PWM por tempo ---
    // A ideia é simples: o pino GPIO fica LIGADO por um tempo
    // proporcional ao valor PWM.
    ldr     r0, =GPIO_BASE

    // LIGA o pino
    mov     r1, #1
    lsl     r1, r1, #18
    str     r1, [r0, #GPSET0]

    // Espera um tempo muito curto, proporcional à amplitude (r3)
    mov     r2, r3
pwm_delay_loop:
    subs    r2, r2, #1
    bne     pwm_delay_loop

    // DESLIGA o pino
    str     r1, [r0, #GPCLR0]

    // --- Avança para a próxima amostra da música ---
    add     r10, r10, #1          // Incrementa o índice
    cmp     r10, r9               // Compara o índice com o tamanho total
    movlo   pc, pc                // Se for menor, continua
    mov     r10, #0               // Se for maior ou igual, reinicia a música

    // --- Reagenda a próxima interrupção ---
    // Limpa a flag de interrupção do timer
    ldr     r0, =SYS_TIMER_BASE
    mov     r1, #1 << 1
    str     r1, [r0, #SYS_TIMER_CS]

    // Agenda a próxima interrupção para daqui a 22 microssegundos
    ldr     r1, [r0, #SYS_TIMER_CLO]
    add     r1, r1, #22
    str     r1, [r0, #SYS_TIMER_C1]

    // Restaura os registradores do stack
    pop     {r0-r7, lr}
    // Retorna da interrupção
    subs    pc, lr, #4