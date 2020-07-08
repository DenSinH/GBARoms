format binary as 'gba'

include './lib/constants.inc'
include './lib/macros.inc'


header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        ; disable interrupts
        set_word r0, REG_IME
        mov r1, #0
        strh r1, [r0]

        set_word r0, MEM_ROM + init + 1
        mov lr, pc
        bx r0

        set_word r0, MEM_ROM + mandelbrot + 1
        mov lr, pc
        bx r0

        wait:
                b wait

include './init.asm'
include './mandelbrot.asm'