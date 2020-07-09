include '../lib/constants.inc'

parse_instr:
        ; using http://devernay.free.fr/hacks/chip8/C8TECH10.HTM, as I did with my python chip-8 interpreter
        set_word r4, CHIP8_MEMORY
        add r4, r12
        ldrb r3, [r4]
        ldrb r4, [r4, #1]
        add r12, #2
        add r3, r4, r3, lsl #8  ; Chip-8 ROMs are big-endian
        ; r3 now contains the instruction

        mov r4, 0x0f
        and r0, r4, r3, lsr #8  ; x
        and r1, r4, r3, lsr #4  ; y

        set_word r5, CHIP8_REGISTERS
        ; get register x value
        add r0, r5
        ldrb r4, [r0]

        ; get register y value
        add r1, r5
        ldrb r5, [r1]

        mov r6, r3, lsr #12     ; check top nibble
        set_word r7, MEM_ROM + _instr_jump_table
        add r6, r7, r6, lsl #2  ; jump_table + 4 * instruction
        ldr r6, [r6]            ; load pointer
        add r6, MEM_ROM         ; account for ROM offset again
        bx r6                   ; jump to "switch case"

_instr_jump_table:
        dw _instr_0, _instr_1, _instr_2, _instr_3
        dw _instr_4, _instr_5, _instr_6, _instr_7
        dw _instr_8, _instr_9, _instr_A, _instr_B
        dw _instr_C, _instr_D, _instr_E, _instr_F

;       We now have:
;           r0: mem location of Vx
;           r1: mem location of Vy
;           r2: ???
;           r3: instruction
;           r4: value of Vx
;           r5: value of Vy
;           r6: ???
;           r7: ???

_instr_0:
        cmp r3, #0x00e0
        bne _instr_0_ret

        ; CLS
        stmdb sp!, { lr }

        bl init_chip8

        ldmia sp!, { lr }
        bx lr

        _instr_0_ret:
                ; RET, pop r12 off the Chip-8 stack
                ldmdb r11!, { r12 }
                bx lr

_instr_1:
        ; JP
        set_half r6, 0xfff
        and r12, r3, r6      ; jump address
        bx lr

_instr_2:
        ; CALL
        set_half r6, 0xfff
        stmia r11!, { r12 }  ; push PC
        and r12, r3, r6      ; call address
        bx lr

_instr_3:
        ; SE
        ; compare to lower byte of instruction and skip next if equal
        and r6, r3, #0xff
        cmp r4, r6
        addeq r12, #2
        bx lr

_instr_4:
        ; SNE
        ; compare to lower byte of instruction and skip next if equal
        and r6, r3, #0xff
        cmp r4, r6
        addne r12, #2
        bx lr

_instr_5:
        ; SE
        cmp r4, r5
        addeq r12, #2
        bx lr

_instr_6:
        ; LD
        and r4, r3, #0xff
        strb r4, [r0]

        bx lr

_instr_7:
        ; ADD
        add r4, r3  ; we will only store a byte anyway
        strb r4, [r0]

        bx lr

_instr_8:

        and r6, r3, #0xf
        set_word r7, MEM_ROM +_instr_8_jump_table
        add r6, r7, r6, lsl #2  ; set r6 to jump_table + 4 * r6

        ; set r7 to memory location of VF
        set_word r7, CHIP8_REGISTERS + 0xf

        ldr r6, [r6]
        add r6, MEM_ROM         ; account for ROM offset again
        bx r6


        _instr_8_jump_table:
                dw _instr_8_0, _instr_8_1, _instr_8_2, _instr_8_3
                dw _instr_8_4, _instr_8_5, _instr_8_6, _instr_8_7
                dw 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
                dw 0xffffffff, 0xffffffff, _instr_8_E, 0xffffffff

        _instr_8_0:
                ; LD

                strb r5, [r0]   ; store Vy in the memory location for Vx

                bx lr

        _instr_8_1:
                ; OR
                orr r4, r5
                strb r4, [r0]

                bx lr

        _instr_8_2:
                ; AND
                and r4, r5
                strb r4, [r0]

                bx lr

        _instr_8_3:
                ; XOR
                eor r4, r5
                strb r4, [r0]

                bx lr

        _instr_8_4:
                ; ADD
                add r4, r5
                strb r4, [r0]

                ; VF = (result > 0xff) ? 1 : 0
                cmp r4, #0xff
                mov r4, #0
                movgt r4, #1
                strb r4, [r7]

                bx lr

        _instr_8_5:
                ; SUB
                subs r4, r5
                strb r4, [r0]

                ; VF = (Vx > Vy) ? 1 : 0  (NOT borrow)
                mov r4, #0
                movgt r4, #1
                strb r4, [r7]

                bx lr

        _instr_8_6:
                ; SHR
                movs r4, r4, lsr #1
                strb r4, [r0]

                ; VF = carry ? 1 : 0
                mov r4, #0
                movcs r4, #1
                strb r4, [r7]

                bx lr

        _instr_8_7:
                ; SUBN
                subs r4, r5, r4
                strb r4, [r0]

                ; VF = (Vy > Vx) ? 1 : 0  (NOT borrow)
                mov r4, #0
                movgt r4, #1
                strb r4, [r7]

                bx lr

        _instr_8_E:
                ; SHL
                mov r4, r4, lsl #1
                strb r4, [r0]

                ; VF = carry ? 1 : 0
                cmp r4, 0xff     ; cs wont work because GBA registers are 32 bits
                mov r4, #0
                movgt r4, #1
                strb r4, [r7]

                bx lr

_instr_9:
        ; SNE
        cmp r4, r5
        addne r12, #2
        bx lr

_instr_A:
        ; LD I
        set_half r6, 0xfff
        and r10, r3, r6

        bx lr

_instr_B:
        ; JP V0
        set_word r7, CHIP8_REGISTERS
        ldrb r7, [r7]
        set_half r6, 0xfff

        and r12, r3, r6
        add r12, r7

        bx lr

_instr_C:
        ; RND (todo)
        set_word r4, VCOUNT
        ldrb r4, [r4]
        and r4, r3
        strb r4, [r0]

        bx lr

_instr_D:
        ; DRW (todo)
        ; The interpreter reads n bytes from memory, starting at the address stored in I.
        ; These bytes are then displayed as sprites on screen at coordinates (Vx, Vy).
        ; Sprites are XORed onto the existing screen. If this causes any pixels to be erased,
        ;   VF is set to 1, otherwise it is set to 0.
        ; If the sprite is positioned so part of it is outside the coordinates of the display,
        ;   it wraps around to the opposite side of the screen.

        ;       r0: x coord           r3: colission           r6: sprite address
        ;       r1: y coord           r4: bit counter         r7: byte counter
        ;       r2: pixel on/off      r5: sprite byte         r8: stored, then temp
        ;                                                     r9, r10, r11, r12, sp, lr taken
        ands r7, r3, 0xf           ; number of bytes
        bxeq lr                    ; if we draw 0 bytes return immediately
        stmdb sp!, { r8, lr }

        mov r3, #0

        set_word r6, CHIP8_MEMORY
        add r6, r10                ; load sprite left memory location
        mov r0, r4                 ; set r0 = Vx
        mov r1, r5                 ; set r1 = Vy

        _instr_D_draw_byte_loop:
                mov r4, #7         ; bit counter
                ldrb r5, [r6]      ; read byte to be drawn
                add r6, #1         ; increment sprite address

                _instr_D_draw_bit_loop:
                        bl get_pixel       ; get pixel value
                        cmp r2, #0
                        mov r2, #0
                        movne r2, #1       ; set r2 to 0 if empty else 1

                        mov r8, r5, lsr r4
                        and r8, #1         ; get bit we are checking in r8
                        add r2, r8
                        cmp r2, #2         ; check if there is colission
                        orreq r3, #1
                        and r2, #1         ; finish the XOR operation

                        bl set_pixel       ; set pixel at (r0, r1) to off if r2 == 0 else on
                        add r0, #1
                        and r0, #63        ; x = (x + 1) % 64
                        subs r4, #1
                        bge _instr_D_draw_bit_loop

                subs r7, #1
                add r1, #1
                and r1, #0x1f
                sub r0, #8
                and r0, #0x3f
                bne _instr_D_draw_byte_loop

        ; store colission
        set_word r6, CHIP8_REGISTERS + 0xf
        strb r3, [r6]

        ldmia sp!, { r8, lr }
        bx lr

_instr_E:

        mov r0, r4              ; set r0 = Vx
        stmdb sp!, { lr }
        bl keypad_is_pressed    ; poll if Vx is pressed
        ldmia sp!, { lr }

        and r7, r3, #0xff
        cmp r7, #0xa1
        beq _instr_E_SKNP       ; check if SKNP or SKP instruction

        ; SKP
        cmp r2, #0
        addne r12, #2
        bx lr

        _instr_E_SKNP:
                ; SKNP
                cmp r2, #0
                addeq r12, #2  ; skip if not pressed
                bx lr

_instr_F:
        and r7, r3, 0xff   ; lower byte
        cmp r7, #0x65
        beq _instr_F_65
        cmp r7, #0x55
        beq _instr_F_55
        cmp r7, #0x33
        beq _instr_F_33
        cmp r7, #0x29
        beq _instr_F_29
        cmp r7, #0x1e
        beq _instr_F_1E
        cmp r7, #0x18
        beq _instr_F_18
        cmp r7, #0x15
        beq _instr_F_15
        cmp r7, #0x0a
        beq _instr_F_0A

        _instr_F_07:
                ; Vx = dt
                mov r4, r9
                strb r4, [r0]

                bx lr
        _instr_F_0A:
                ; wait for keypress and store it in Vx
                stmdb sp!, { lr }
                _instr_F_0A_get_key_loop:
                        bl get_key
                        cmp r2, #0x10
                        beq _instr_F_0A_get_key_loop

                strb r2, [r0]

                ldmia sp!, { lr }
                bx lr
        _instr_F_15:
                ; set dt = Vx
                mov r9, r4
                bx lr
        _instr_F_18:
                ; set st = Vx
                mov r8, r4
                bx lr
        _instr_F_1E:
                ; I += Vx
                add r10, r4

                bx lr
        _instr_F_29:
                ; set I = location of sprite Vx
                mov r10, r4
                ; sprites are 4 bytes long
                add r10, r10, lsl #2  ; I += 4 * I
                bx lr
        _instr_F_33:
                ; BCD representations
                mov r0, r4
                mov r1, #10
                swi 0x060000  ; divide r0 / r1
                mov r7, r1    ; r7 = Vx % 10
                mov r1, #10
                swi 0x060000  ; divide r0 / r1 / r1
                mov r6, r1    ; r6 = Vx tens
                mov r5, r0    ; r7 = Vx hundreds
                set_word r0, CHIP8_MEMORY
                add r0, r10   ; start address for storing

                ; store decimal
                strb r5, [r0]
                add r0, #1
                strb r6, [r0]
                add r0, #1
                strb r7, [r0]

                bx lr
        _instr_F_55:
                set_word r7, CHIP8_REGISTERS
                mov r3, #0   ; register counter
                sub r0, r7   ; revert back to register number instread of memory location
                set_word r6, CHIP8_MEMORY
                add r6, r10  ; location to store the registers

                _instr_F_55_loop:
                        ldrb r4, [r7, r3]  ; load register Vr3
                        strb r4, [r6, r3]  ; store at I + r3
                        add r3, #1
                        cmp r3, r0
                        ble _instr_F_55_loop

                bx lr
        _instr_F_65:
                set_word r7, CHIP8_REGISTERS
                mov r3, #0   ; register counter
                sub r0, r7   ; revert back to register number instread of memory location
                set_word r6, CHIP8_MEMORY
                add r6, r10  ; location to store the registers

                _instr_F_65_loop:
                        ldrb r4, [r6, r3]  ; load register I + r3
                        strb r4, [r7, r3]  ; store at Vr3
                        add r3, #1
                        cmp r3, r0
                        ble _instr_F_65_loop

                bx lr

