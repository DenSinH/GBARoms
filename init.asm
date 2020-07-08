include './lib/constants.inc'

PALETTE_LENGTH = 26

code16
align 2
init:
        ; set palette
        ; load SAD
        mov r7, #24
        mov r6, #8

        mov r0, #04
        lsl r0, r7
        add r0, #0xD4 ; DMA3SAD

        mov r1, #8
        lsl r1, r7    ; ROM
        mov r2, ((palette + (2 * PALETTE_LENGTH)) and 0xff00) shr 8
        lsl r2, r6
        add r2, ((palette + (2 * PALETTE_LENGTH)) and 0x00ff)
        add r1, r2
        str r1, [r0]

        add r0, #4  ; DMA3DAD
        ; load to address into r1
        mov r1, #5
        lsl r1, r7  ; palette
        str r1, [r0]

        add r0, #4  ; DMA3CNT_L
        ; load dma length into DMA3CNT_L
        mov r1, #26
        strh r1, [r0]

        add r0, #2  ; DMA3CNT_H
        ; start the DMA transfer
        mov r1, #0x80
        lsl r1, r6
        add r1, #0x80 ; DMA immediate, 16 bit, decrement source
        strh r1, [r0]

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

        bx lr

palette:
     dh 0x0000   ; bd: black
     dh 0x7fff   ;  0 white
     dh 0x631f   ;  1 light red 1
     dh 0x421f   ;  2 light red 2
     dh 0x211f   ;  3 light red 3
     dh 0x001f   ;  4 red
     dh 0x011f   ;  5 red~orange
     dh 0x021f   ;  6 red~orange
     dh 0x031f   ;  7 orange~yellow
     dh 0x03ff   ;  8 yellow
     dh 0x03f8   ;  9 yellow~green
     dh 0x03f0   ; 10 yellow~green
     dh 0x03e8   ; 11 yellow~green
     dh 0x03e0   ; 12 green
     dh 0x23e0   ; 13 green~cyan
     dh 0x43e0   ; 14 green~cyan
     dh 0x63e0   ; 15 green~cyan
     dh 0x7fe0   ; 16 cyan
     dh 0x7f00   ; 17 cyan~blue
     dh 0x7e00   ; 18 cyan~blue
     dh 0x7d00   ; 19 cyan~blue
     dh 0x7c00   ; 20 blue
     dh 0x7c08   ; 21 blue~purple
     dh 0x7c10   ; 22 blue~purple
     dh 0x7c18   ; 23 purple~magenta
     dh 0x7c1f   ; 24 pink
     dh 0x0000   ; 25 overflow (black)



