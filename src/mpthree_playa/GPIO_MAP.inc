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
