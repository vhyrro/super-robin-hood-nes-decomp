.macro ZP_VAR name, size
name = ZERO_PAGE_ALLOCATION
.ifblank size
ZERO_PAGE_ALLOCATION .set ZERO_PAGE_ALLOCATION + 1
.else
ZERO_PAGE_ALLOCATION .set ZERO_PAGE_ALLOCATION + (size)
.endif
.endmacro

.macro RAM_VAR name, size
name = RAM_ALLOCATION
.ifblank size
RAM_ALLOCATION .set RAM_ALLOCATION + 1
.else
RAM_ALLOCATION .set RAM_ALLOCATION + (size)
.endif
.endmacro
