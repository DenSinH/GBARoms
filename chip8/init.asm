include '../lib/constants.inc'
include '../lib/macros.inc'

init_menu:
        stmdb sp!, { r0, r1, lr }
        ; clear VRAM
        mov r0, 0x08            ; VRAM bit
        swi 0x010000            ; RegisterRamReset

        ; transfer the glyphs
        do_dma MEM_ROM + glyphs, MEM_VRAM + 0x4000, 6 * 16 * 8

        ; enable BG0
        set_word r0, BG0CNT
        mov r1, #0x0004          ; CharBaseBlock 1
        strh r1, [r0]

        ; write fill color to palette
        set_half r1, FILL_COLOR
        mov r0, MEM_PALETTE
        add r0, #2
        strh r1, [r0]

        ; set BG mode to 0
        mov r0, DISPCNT
        set_half r1, DISPCNT_BGMODE0
        strh r1, [r0]

        ldmia sp!, { r0, r1, lr }
        bx lr


init_chip8:
        ; clear VRAM
        mov r0, 0x08            ; VRAM bit
        swi 0x010000            ; RegisterRamReset

        ; set DISPCNT to 0x0100: enable BG2
        mov r0, DISPCNT
        set_half r1, DISPCNT_BGMODE3
        strh r1, [r0]        ; set BGMode to mode 3, display BG2

        ; top left address of screen
        mov r0, MEM_VRAM
        add r0, SCREEN_OFFSET_H * 2
        add r0, SCREEN_OFFSET_V * VRAM_OFFSET_PER_SCANLINE
        sub r0, VRAM_OFFSET_PER_SCANLINE

        set_word r2, EDGE_COLOR * 0x00010001

        ; draw horizontal line of length SCREEN_WIDTH + 1
        mov r3, SCREEN_WIDTH
        _init_top_line:
                stmia r0!, { r2 }
                subs r3, #2
                bne _init_top_line

        ; we undershoot the line, but we start storing from the current position right away
        mov r3, SCREEN_HEIGHT + 2
        _init_right_line:
                strh r2, [r0]
                add r0, VRAM_OFFSET_PER_SCANLINE
                subs r3, #1
                bne _init_right_line
         sub r0, VRAM_OFFSET_PER_SCANLINE ; overshot the line

        mov r3, SCREEN_WIDTH
        _init_bottom_line:
                stmdb r0!, { r2 }
                subs r3, #2
                bne _init_bottom_line
                sub r0, #2  ; undershot the line because of pre-indexed stmdb

        mov r3, SCREEN_HEIGHT + 2
        _init_left_line:
                strh r2, [r0]
                sub r0, VRAM_OFFSET_PER_SCANLINE
                subs r3, #1
                bne _init_left_line

        ; initialize register values
        set_word r11, CHIP8_STACK
        mov r12, 0x200   ; initial value for CHIP-8 PC
        set_word r0, CHIP8_ZERO
        mov r1, 0
        str r1, [r0]

        bx lr

include '../lib/glyphs.inc'
