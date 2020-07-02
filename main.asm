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

macro fill_pixel reg_x, reg_y {

}

header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        ; set DISPCNT to 0x0100: enable BG0
        set_word r0, DISPCNT
        set_half r1, 0x0100
        strh r1, [r0]

        add r0, r0, #8       ; BG0CNT
        mov r1, 0x04         ; set_half r1, 0x0040
        strh r1, [r0]        ; set CharBaseBlock = 1, ScreenBaseBlock = 0, 4bpp mode

        set_word r0, MEM_PALETTE or 0x2 ; second palette entry
        set_half r1, FILL_COLOR         ; set palette entry to FILL_COLOR defined above
        strh r1, [r0]

        mov r2, 0                       ; tile counter
        make_tiles:
                set_word r0, MEM_VRAM or 0x4000 ; start of second CharBlock
                mov r3, 0                       ; keeps track of top or bottom for us
                add r0, r0, r2, lsl 5           ; tile r2 * 32

                make_tile:
                        mov r1, 0               ; tile data
                        tst r0, 0x10            ; eq if top half, ne if bottom
                        moveq r3, 0x01
                        movne r3, 0x04          ; 1 if top half else 4

                        tst r2, r3              ; left part of tile
                        orrne r1, 0x11
                        orrne r1, 0x1100

                        mov r3, r3, lsl #0x01   ; 2 if top half else 8

                        tst r2, r3              ; right part of tile
                        orrne r1, 0x110000
                        orrne r1, 0x11000000
                        stmia r0!, { r1 }

                        tst r0, 0x1f            ; check if we have reached the next tile
                        bne make_tile           ; jump back if we have not yet reached the next tile
                add r2, r2, 0x1
                cmp r2, 0x10
                bne make_tiles

        and r0, 0xff000000 ; start of VRAM
        mov r1, 0x01
        strh r1, [r0]

        wait:
                b wait
