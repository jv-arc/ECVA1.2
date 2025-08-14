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