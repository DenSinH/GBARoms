include './lib/constants.inc'
include './lib/macros.inc'

BASE_FREQ = 0x348000
BASE_MK   = 0x05
BASE_FP   = 0x0c

DFREQ     = 0x10
DMK       = 0x10
DFP       = 0x10

;       r4: hold WRAM address with wave data
;       r5: input freq in wavedata
;       r6: u8 mk
;       r7: u8 fp
;       r8: counter

mov r0, #0  ; x coord
mov r1, #0  ; y coord

mov r4, #MEM_IWRAM
add r4, #0x100

mov r5, #BASE_FREQ
mov r6, #BASE_MK
mov r7, #BASE_FP

mov r8, #0

test_loop:
        ; setup test inputs
        mov r0, r4
        str r5, [r0, #4]
        mov r1, r6
        mov r2, r7

        swi #0x1f0000
        mov r2, r0      ; return val

        ; load coords
        mov r0, #0
        mov r1, r8, lsl #3

        bl draw_hex_value

        ; update test inputs
        add r5, #DFREQ
        add r6, #DMK
        add r7, #DFP

        add r8, #1
        cmp r8, #0x10
        blt test_loop
