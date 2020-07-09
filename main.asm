format binary as 'gba'

include './lib/constants.inc'
macro set_word reg, value {
        mov reg, (value) and 0xff
        orr reg, (value) and 0xff00
        orr reg, (value) and 0xff0000
        orr reg, (value) and 0xff000000
}

macro set_half reg, value {
        mov reg, (value) and 0xff
        orr reg, (value) and 0xff00
}

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

        ; copy program to iWRAM
        set_word r0, DMA3SAD
        set_word r1, MEM_ROM + mandelbrot
        str r1, [r0]

        ; DMA3DAD
        add r0, #4
        mov r1, MEM_IWRAM
        str r1, [r0]

        ; DMA3CNT_L
        add r0, #4
        set_half r1, (end_mandelbrot - mandelbrot) shr 1
        strh r1, [r0]

        ; DMA3CNT_H
        add r0, #2
        mov r1, DMACNT_H_16BIT_IMM
        strh r1, [r0]

        mov r0, MEM_IWRAM
        add r0, #1
        mov lr, pc
        bx r0

        wait:
                b wait

include './init.asm'
include './mandelbrot.asm'