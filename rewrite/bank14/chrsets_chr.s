collisionchr:
.byte $0E,$00,$80
solidcollisionchr:
.byte $0F,$FF
alphachrs:
hiscorechrs:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/HISCORE.PP1"
titletopchrs:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/TOPCHRS.PP1"
titlebotchrs:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BOTCHRS.PP1"
robinchrs:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ROBINCHR.PP1"
basechr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BASECHR.PP1"
beadchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BEADCHR.PP1"
boxchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BOXCHR.PP1"
archchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ARCHCHR.PP1"
rockchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ROCKCHR.PP1"
bedchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BEDCHR.PP1"
doorchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/DOORCHR.PP1"
okchr:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/OKCHR.PP1"
end_of_bank14_data:
BANK_14_SIZE = $BFFF - end_of_bank14_data
bank14_size_word:
.byte >(BANK_14_SIZE)
.byte <(BANK_14_SIZE)
