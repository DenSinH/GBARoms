include '../lib/constants.inc'

load_rom:
        ; load rom (todo: rom selection)
        stmia sp, { r0, r1 }
        set_word r0, DMA3SAD

        ; load rom start addres in the GBA rom
        set_word r1, digits
        add r1, MEM_ROM  ; account for ROM offset
        str r1, [r0]

        add r0, #4  ; DMA3DAD
        ; load rom start address in GBA iWRAM
        set_word r1, CHIP8_MEMORY
        ; todo: clear bottom 0x200 bytes?
        str r1, [r0]

        add r0, #4  ; DMA3CNT_L
        ; load digits memory length into DMA3CNT_L
        mov r1, 5 * 4
        strh r1, [r0]

        add r0, #2  ; DMA3CNT_H
        ; start the DMA transfer
        set_word r1, DMACNT_H_32BIT_IMM
        strh r1, [r0]

        sub r0, #10 ; return to DMA3SAD
        set_word r1, tetris
        add r1, MEM_ROM  ; account for ROM offset
        str r1, [r0]

        add r0, #4  ; DMA3DAD
        set_word r1, CHIP8_MEMORY
        add r1, #0x200
        str r1, [r0]

        add r0, #4  ; DMA3CNT_L
        mov r1, (0x1000 - 0x200) / 4   ; Chip-8 rom length in words
        strh r1, [r0]

        add r0, #2  ; DMA3CNT_H
        ; start the DMA transfer
        set_word r1, DMACNT_H_32BIT_IMM
        strh r1, [r0]

        ; return
        ldmdb sp, { r0, r1 }
        bx lr


