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

