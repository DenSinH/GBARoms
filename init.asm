include './lib/constants.inc'
include './lib/macros.inc'

; clear VRAM
_init_zero:
        dw 0x00000000
mov r0, MEM_ROM    ; account for ROM offset
add r0, _init_zero
mov r1, MEM_VRAM
mov r2, 0x00118000
swi 0x0c0000  ; CpuSet

; set DISPCNT to 0x0100: enable BG2
mov r0, DISPCNT
set_half r1, 0x0403
strh r1, [r0]        ; set BGMode to mode 3, display BG2

mov r0, MEM_VRAM
add r0, SCREEN_OFFSET_H * 2 - 4
add r0, SCREEN_OFFSET_V * VRAM_OFFSET_PER_SCANLINE
sub r0, VRAM_OFFSET_PER_SCANLINE

set_word r2, EDGE_COLOR * 0x00010001

; draw horizontal line of length SCREEN_WIDTH + 1
mov r3, SCREEN_WIDTH + 2
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


