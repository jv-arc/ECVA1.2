@ ====================================================================
@ GIC Distributor (GICD)
@ Para Raspberry Pi 2B (BCM2836)
@ ====================================================================

.equ GICD_BASE,             0x40001000
.equ GICD_CTLR,             0x000

@ GICD_ISENABLERx
.equ GICD_ISENABLER0,       0x100
.equ GICD_ISENABLER1,       0x104
.equ GICD_ISENABLER2,       0x108
.equ GICD_ISENABLER3,       0x10C
.equ GICD_ISENABLER4,       0x110
.equ GICD_ISENABLER5,       0x114
.equ GICD_ISENABLER6,       0x118
.equ GICD_ISENABLER7,       0x11C


@ GICD_ICENABLERx
.equ GICD_ICENABLER1,       0x180
.equ GICD_ICENABLER2,       0x108


@ GICD_ICFGR
.equ GICD_ICFGR0,           0xC00
.equ GICD_ICFGR1,           0xC04
.equ GICD_ICFGR2,           0xC08
.equ GICD_ICFGR3,           0xC0C
.equ GICD_ICFGR4,           0xC10
.equ GICD_ICFGR5,           0xC14


@ GICD_IPRIORITYR
.equ GICD_IPRIORITYR0,      0x400      
.equ GICD_IPRIORITYR1,      0x404      
.equ GICD_IPRIORITYR2,      0x408      
.equ GICD_IPRIORITYR3,      0x40C      
.equ GICD_IPRIORITYR4,      0x410      
.equ GICD_IPRIORITYR5,      0x414      
.equ GICD_IPRIORITYR6,      0x418      
.equ GICD_IPRIORITYR7,      0x41C      
.equ GICD_IPRIORITYR8,      0x420      
.equ GICD_IPRIORITYR9,      0x424      
.equ GICD_IPRIORITYR10,     0x428      
.equ GICD_IPRIORITYR11,     0x42C      
.equ GICD_IPRIORITYR12,     0x430      
.equ GICD_IPRIORITYR13,     0x434
.equ GICD_IPRIORITYR14,     0x438
.equ GICD_IPRIORITYR15,     0x43C
.equ GICD_IPRIORITYR16,     0x440
.equ GICD_IPRIORITYR17,     0x444
.equ GICD_IPRIORITYR18,     0x448
.equ GICD_IPRIORITYR19,     0x44C
.equ GICD_IPRIORITYR20,     0x450
.equ GICD_IPRIORITYR21,     0x454
.equ GICD_IPRIORITYR22,     0x458
.equ GICD_IPRIORITYR23,     0x45C


@ GICD_ITARGETS
.equ GICD_ITARGETS0,        0x800
.equ GICD_ITARGETS1,        0x804
.equ GICD_ITARGETS2,        0x808
.equ GICD_ITARGETS3,        0x80C
.equ GICD_ITARGETS4,        0x810
.equ GICD_ITARGETS5,        0x814
.equ GICD_ITARGETS6,        0x818
.equ GICD_ITARGETS7,        0x81C
.equ GICD_ITARGETS8,        0x820
.equ GICD_ITARGETS9,        0x824
.equ GICD_ITARGETS10,       0x828
.equ GICD_ITARGETS11,       0x82C
.equ GICD_ITARGETS12,       0x830
.equ GICD_ITARGETS13,       0x834
.equ GICD_ITARGETS14,       0x838
.equ GICD_ITARGETS15,       0x83C
.equ GICD_ITARGETS16,       0x840
.equ GICD_ITARGETS17,       0x844
.equ GICD_ITARGETS18,       0x848
.equ GICD_ITARGETS19,       0x84C
.equ GICD_ITARGETS20,       0x850
.equ GICD_ITARGETS21,       0x854
.equ GICD_ITARGETS22,       0x858
.equ GICD_ITARGETS23,       0x85C