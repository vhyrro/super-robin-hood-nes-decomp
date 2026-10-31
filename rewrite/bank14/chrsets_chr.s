COLLISIONCHR:
.byte $0E,$00,$80
SOLIDCOLLISIONCHR:
.byte $0F,$FF
ALPHACHRS:
HISCORECHRS:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/HISCORE.PP1"
TITLETOPCHRS:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/TOPCHRS.PP1"
TITLEBOTCHRS:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BOTCHRS.PP1"
ROBINCHRS:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ROBINCHR.PP1"
BASECHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BASECHR.PP1"
BEADCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BEADCHR.PP1"
BOXCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BOXCHR.PP1"
ARCHCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ARCHCHR.PP1"
ROCKCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/ROCKCHR.PP1"
BEDCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/BEDCHR.PP1"
DOORCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/DOORCHR.PP1"
OKCHR:
.incbin "/home/vhyrro/dev/side-projects/SuperRobinHoodNESSource/pds_src/src/OKCHR.PP1"
ED14:
B14 = 49151 - ED14
BANK14:
.byte >(B14)
.byte <(B14)
