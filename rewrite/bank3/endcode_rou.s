.segment "VECTORS"
.org $FFF9
irq_interrupt:
rti
.word nmi_entry
.word start
.word irq_interrupt
