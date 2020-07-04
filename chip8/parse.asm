include '../lib/constants.inc'

_instr_jump_table:
        dw _instr_0, _instr_1, _instr_2, _instr_3
        dw _instr_4, _instr_5, _instr_6, _instr_7
        dw _instr_8, _instr_9, _instr_A, _instr_B
        dw _instr_C, _instr_D, _instr_E, _instr_F

_instr_8_jump_table:
        dw _instr_8_0, _instr_8_1, _instr_8_2, _instr_8_3
        dw _instr_8_4, _instr_8_5, _instr_8_6, _instr_8_7
        dw 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
        dw 0xffffffff, 0xffffffff, _instr_8_E, 0xffffffff

; using http://devernay.free.fr/hacks/chip8/C8TECH10.HTM, as I did with my python chip-8 interpreter
set_word r3, CHIP8_MEMORY
add r3, r12
ldmia r3, { r3, r4 }
add r12, #2
add r3, r4, r3, lsl #8  ; Chip-8 ROMs are big-endian
; r3 now contains the instruction

mov r4, 0x0f
and r0, r4, r3, lsr #8  ; x
and r1, r4, r3, lsr #4  ; y

set_word r5, CHIP8_REGISTERS
; get register x value
add r0, r5
ldrb r4, [r4]

; get register y value
add r1, r5
ldrb r5, [r1]

mov r6, r3, lsl #20     ; check top nibble
set_word r7, _instr_jump_table
add r7, MEM_ROM         ; account for ROM offset
add r6, r7, r6, lsr #2  ; jump_table + 4 * instruction
ldr r6, [r6]            ; load pointer
bx r6                   ; jump to "switch case"

;       We now have:
;           r0: mem location of Vx
;           r1: mem location of Vy
;           r2: ???
;           r3: instruction
;           r4: value of Vx
;           r5: value of Vy
;           r6: ???
;           r7: ???
;           r8: ???

_instr_0:
        cmp r3, #0x00e0
        bne _instr_0_ret

        ; CLS, we do this using a CpuSet SWI
        ; We don't need the register values here either way
        set_word r0, CHIP8_ZERO
        mov r1, MEM_VRAM
        set_word r2, 0x00118000
        swi 0xc00000
        b _instr_return

        _instr_0_ret:
                ; RET, pop r12 off the Chip-8 stack
                ldmdb r11!, { r12 }
                b _instr_return

_instr_1:
        ; JP
        set_half r6, 0xfff
        and r12, r3, r6      ; jump address
        b _instr_return

_instr_2:
        ; CALL
        set_half r6, 0xfff
        stmia r11!, { r12 }  ; push PC
        and r12, r3, r6      ; call address
        b _instr_return

_instr_3:
        ; SE
        ; compare to lower byte of instruction and skip next if equal
        and r6, r3, #0xff
        cmp r4, r6
        addeq r12, #2
        b _instr_return

_instr_4:
        ; SNE
        ; compare to lower byte of instruction and skip next if equal
        and r6, r3, #0xff
        cmp r4, r6
        addne r12, #2
        b _instr_return

_instr_5:
        ; SE
        cmp r4, r5
        addeq r12, #2
        b _instr_return

_instr_6:
        ; LD
        and r4, r3, #0xff
        strb r4, [r0]

        b _instr_return

_instr_7:
        ; ADD
        add r4, r3  ; we will only store a byte anyway
        strb r4, [r0]

        b _instr_return

_instr_8:

        ; set r8 to memory location of VF
        set_word r8, CHIP8_REGISTERS
        add r8, #0xf

        and r6, r3, #0xf
        set_word r7, _instr_8_jump_table
        add r7, MEM_ROM         ; account for ROM offset
        add r6, r7, r6, lsr #2  ; set r6 to jump_table + 4 * r6

        ldr r6, [r6]
        bx r6

        _instr_8_0:
                ; LD

                strb r4, [r1]   ; store Vy in the memory location for Vx

                b _instr_return

        _instr_8_1:
                ; OR
                orr r4, r5
                strb r4, [r0]

                b _instr_return

        _instr_8_2:
                ; AND
                and r4, r5
                strb r4, [r0]

                b _instr_return

        _instr_8_3:
                ; XOR
                eor r4, r5
                strb r4, [r0]

                b _instr_return

        _instr_8_4:
                ; ADD
                add r4, r5
                strb r4, [r0]

                ; VF = (result > 0xff) ? 1 : 0
                cmp r4, #0xff
                mov r4, #0
                movgt r4, #1
                strb r4, [r8]

                b _instr_return

        _instr_8_5:
                ; SUB
                subs r4, r5
                strb r4, [r0]

                ; VF = (Vx > Vy) ? 1 : 0  (NOT borrow)
                mov r4, #0
                movgt r4, #1
                strb r4, [r8]

                b _instr_return

        _instr_8_6:
                ; SHR
                movs r4, r4, lsr #1
                strb r4, [r0]

                ; VF = carry ? 1 : 0
                mov r4, #0
                movcs r4, #1
                strb r4, [r8]

                b _instr_return

        _instr_8_7:
                ; SUBN
                subs r4, r5, r4
                strb r4, [r0]

                ; VF = (Vy > Vx) ? 1 : 0  (NOT borrow)
                mov r4, #0
                movgt r4, #1
                strb r4, [r8]

                b _instr_return

        _instr_8_E:
                ; SHL
                movs r4, r4, lsl #1
                strb r4, [r0]

                ; VF = carry ? 1 : 0
                mov r4, #0
                movcs r4, #1
                strb r4, [r8]

                b _instr_return

_instr_9:
        ; SNE
        cmp r4, r5
        addne r12, #2
        b _instr_return

_instr_A:
        ; LD I
        set_half r6, 0xfff
        and r10, r3, r6

        b _instr_return

_instr_B:
        ; JP V0
        set_word r8, CHIP8_REGISTERS
        ldrb r8, [r8]
        set_half r6, 0xfff

        and r12, r3, r6
        add r12, r8

        b _instr_return

_instr_C:
        ; RND (todo)
        set_word r4, VCOUNT
        ldrb r4, [r4]
        and r4, r3
        strb r4, [r0]

        b _instr_return

_instr_D:
        ; DRW (todo)
        b _instr_return

_instr_E:
        b _instr_return

_instr_F:
        b _instr_return

_instr_return:
