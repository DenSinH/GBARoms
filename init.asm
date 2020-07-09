include './lib/constants.inc'
include './lib/macros.inc'

init_menu:        \
        stmdb sp!, { r0, r1, lr }
        ; clear VRAM
        mov r0, 0x08            ; VRAM bit
        swi 0x010000            ; RegisterRamReset

        set_word r0, DMA3SAD

        ; load glyphs start address in the GBA rom
        set_word r1, glyphs
        add r1, MEM_ROM  ; account for ROM offset
        str r1, [r0]

        add r0, #4  ; DMA3DAD
        ; load charblock 1 address into r1
        mov r1, MEM_VRAM
        add r1, #0x4000
        str r1, [r0]

        add r0, #4  ; DMA3CNT_L
        ; load glyphs memory length into DMA3CNT_L
        mov r1, 24 * 8
        strh r1, [r0]

        add r0, #2  ; DMA3CNT_H
        ; start the DMA transfer
        set_word r1, DMACNT_H_32BIT_IMM
        strh r1, [r0]

        set_word r1, FILL_COLOR
        mov r0, MEM_PALETTE

        add r0, #2
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

        bx lr

include '../../lib/glyphs.inc'
