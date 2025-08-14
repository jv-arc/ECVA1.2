@ Posicao base e offsets do GIC Distributor
.equ GICD_BASE,            0x40001000
.equ GICD_CTLR,            0x000
.equ GICD_ISENABLER1,      0x104
.equ GICD_ICENABLER1,      0x184
.equ GICD_ICFGR4,          0xC10
.equ GICD_IPRIORITY13,     0x434
.equ GICD_ITARGETS13,      0x834


@ Posicao base e offsets do GIC CPU Interface
.equ GICC_BASE,            0x40002000
.equ GICC_CTRL,            0x00
.equ GICC_PMR,             0x04
.equ GICC_IAR,             0x0C
.equ GICC_EOIR,            0x10
