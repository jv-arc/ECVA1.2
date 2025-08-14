@ ====================================================================
@ GIC CPU Interface (GICC)
@ Para Raspberry Pi 2B (BCM2836)
@ ====================================================================

.equ GICC_BASE,              0x40002000

@ Basicos
.equ GICC_CTLR,              0x00        
.equ GICC_PMR,               0x04        
.equ GICC_BPR,               0x08        
.equ GICC_IAR,               0x0C        
.equ GICC_EOIR,              0x10        
.equ GICC_RPR,               0x14        
.equ GICC_HPPIR,             0x18        

@ Prioridade
.equ GICC_APR0,              0xD0
.equ GICC_APR1,              0xD4
.equ GICC_APR2,              0xD8
.equ GICC_APR3,              0xDC

.equ GICC_IIDR,              0xFC        @ CPU Interface Identification Register
.equ GICC_DIR,               0x1000      @ Deactivate Interrupt Register

@ GICC_CTLR
.equ GICC_CTLR_ENABLE,          0x01        
.equ GICC_CTLR_DISABLE,         0x00        
.equ GICC_CTLR_ENABLEGRP0,      0x01        
.equ GICC_CTLR_ENABLEGRP1,      0x02        
.equ GICC_CTLR_FIQEN,           0x08        
.equ GICC_CTLR_CBPR,            0x10        
.equ GICC_CTLR_FIQBYPDISGRP0,   0x20       
.equ GICC_CTLR_IRQBYPDISGRP0,   0x40       
.equ GICC_CTLR_FIQBYPDISGRP1,   0x80       
.equ GICC_CTLR_IRQBYPDISGRP1,   0x100      
.equ GICC_CTLR_EOIMODE,         0x200       
