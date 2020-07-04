include './lib/constants.inc'
include './lib/macros.inc'

; constants used to center the CHIP-8 screen
SCREEN_OFFSET_H = 24
SCREEN_OFFSET_V = 32

coords_to_vram_coord:
        ; turn coord (r0, r1) into vram memory coordinate and store output in r0
        add r0, r0, lsl #1       ; r0 *= 3
        add r1, r1, lsl #1       ; r1 *= 3
        mov r0, r0, lsl #1       ; r0 *= 2
        mov r1, r1, lsl #9
        sub r1, r1, lsr #4       ; r1 *= 480
        add r0, r1
        add r0, MEM_VRAM         ; add VRAM start location to get start value of pixel
        add r0, SCREEN_OFFSET_H * 2
        add r0, SCREEN_OFFSET_V * 480   ; offset to center screen
        bx lr

set_pixel:
        ; fill pixel at coord (r0, r1)
        stmdb sp!, { r0, r1, r2, r3, lr }   ; save old values
        bl coords_to_vram_coord

        set_half r2, FILL_COLOR  ; color to fill with
        mov r3, 0x3              ; vertical counter

        fill_sliver:             ; fill sliver with pixel
                strh r2, [r0]
                add r0, #2
                strh r2, [r0]
                add r0, #2
                strh r2, [r0]
                add r0, #480
                sub r0, #4         ; add 480 (1 row horizontally), subtract 4 for proper x alignment
                subs r3, 0x1
                bne fill_sliver
        ldmia sp!, { r0, r1, r2, r3, lr }
        bx lr

get_pixel:
        ; get pixel value at coord (r0, r1), return in r2
        stmdb sp!, { r0, r1, lr }  ; save old values
        bl coords_to_vram_coord

        ldrh r2, [r0]
        ldmia sp!, { r0, r1, lr }
        bx lr

