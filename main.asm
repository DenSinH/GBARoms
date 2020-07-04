format binary as 'gba'

include './lib/sections.inc'
include './lib/IO.inc'

FILL_COLOR = 0x7c1f  ; purple

macro set_word reg, value {
        mov reg, value and 0xff
        orr reg, value and 0xff00
        orr reg, value and 0xff0000
        orr reg, value and 0xff000000
}

macro set_half reg, value {
        mov reg, value and 0xff
        orr reg, value and 0xff00
}

header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        ; set DISPCNT to 0x0100: enable BG0
        set_word r0, DISPCNT
        set_half r1, 0x0403
        strh r1, [r0]        ; set BGMode to mode 3, display BG2

        add r0, 0x02000000 ; start of VRAM

        mov r2, 0x40;
        mov r0, 0x0
        mov r1, 0x0
        loop:
                bl fill_pixel
                add r0,  #1
                add r1,  #1
                subs r2, #1
                bne loop

        wait:
                b wait

fill_pixel:
    ; fill pixel at coord [r0, r1]
    stmdb sp!, { r0, r1, r2, r3 }   ; save old values
    add r0, r0, lsl #1       ; r0 *= 3
    add r1, r1, lsl #1       ; r1 *= 3
    mov r0, r0, lsl #1       ; r0 *= 2
    mov r3, #480
    mul r1, r1, r3           ; multiply y by screen width times 2
    add r0, r1
    add r0, MEM_VRAM         ; add VRAM start location to get start value of pixel
    set_half r2, FILL_COLOR  ; color to fill with
    mov r3, 0x3              ; vertical counter

    fill_sliver:             ; fill sliver with pixel
        strh r2, [r0]
        add r0, #0x1
        strh r2, [r0]
        add r0, #0x1
        strh r2, [r0]
        add r0, #0x1
        subs r3, 0x1
        add r0, #480
        sub r0, #3         ; add 128 (1 row horizontally), subtract 3
        bne fill_sliver
    ldmia sp!, { r0, r1, r2, r3 }
    bx lr

