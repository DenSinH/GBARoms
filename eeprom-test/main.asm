format binary as 'gba'

include './lib/constants.inc'
include './lib/macros.inc'


header:
        include './lib/header.inc'

main:
        include './init.asm'

        include './tests.asm'

        mainloop:
                b mainloop

include './lib/text.asm'

; fake flash memory
dw 'EEPR', 'OM_V', '123 '
