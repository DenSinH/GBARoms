include './lib/constants.inc'
include './lib/macros.inc'

code16
align 2
init:
        push { r0, r1, r2 }

        ; set palette
        mov r0, #5
        mov r1, #24
        lsl r0, r1
        add r0, #2
        mov r1, #0

        _init_pal_loop:
                ; 8 colors per shade of red
                repeat 8
                       strh r1, [r0]
                       add r0, #2
                end repeat
                add r1, #1
                cmp r1, #0x20
                blt _init_pal_loop

        ; set r0 to DISPCNT
        mov r0, #4
        mov r1, #24
        lsl r0, r1

        ; set r1 to 0x0404
        mov r1, #4
        mov r2, #8
        lsl r1, r2
        add r1, #4

        ; BG mode 4, enable BG2
        strh r1, [r0]

        pop { r0, r1, r2 }
        bx lr



