format binary as 'gba'

include './lib/constants.inc'
include './lib/macros.inc'

header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        ; set DISPCNT to 0x0100: enable BG0
        set_word r0, DISPCNT
        set_half r1, 0x0403
        strh r1, [r0]        ; set BGMode to mode 3, display BG2

        mov r3, 0x20
        mov r1, 0x0
        y_loop:
                and r0, r3, #1
                mov r2, 0x20
                x_loop:
                        bl set_pixel
                        add r0,  #2
                        subs r2, #1
                        bne x_loop
                add r1, #1
                subs r3, #1
                bne y_loop

        mov r2, 0
        mov r0, 2
        mov r1, 0
        bl get_pixel

        wait:
                b wait

pixels:
        include './pixels.asm'

