include '../lib/constants.inc'

get_key:
        ; read KEYINPUT and output it into r2
        stmdb sp!, { r0, r1, r3 }

        set_word r0, KEYINPUT
        ldrh r0, [r0]

        mov r2, #0x3c  ; key counter (result will be stored in here anyway)
        set_word r1, _key_mappings
        add r1, MEM_ROM

        _update_keypad_check_loop:
                ldrh r3, [r1, r2]  ; load button halfword bitmask
                ; we use that KEYINPUT is inverted so that
                ; KEYINPUT & BITMASK == 0 iff the buttons masked by BITMASK are pressed
                tst r0, r3
                subne r2, #4
                beq _update_keypad_return
                cmp r2, #0x0
                bge _update_keypad_check_loop

        _update_keypad_return:
                ; we needed to increment r8 by 4 every time because the bitmasks
                ; were 4 bytes long, so we divide by 4 to fix this again
                movs r2, r2, asr #2
                movlt r2, 0x10

                ldmia sp!, { r0, r1 }
                bx lr

keypad_is_pressed:
        ; check if key with value r0 is pressed, output into r2
        stmdb sp!, { r0, r1 }

        mov r0, r0, lsl #2         ; set r0 to array offset

        set_word r2, KEYINPUT
        ldrh r2, [r2]              ; load current KEYINPUT value

        set_word r1, _key_mappings
        add r1, MEM_ROM
        ldrh r1, [r1, r0]          ; load key bitmask
        tst r2, r1

        ; r2 = 0 if not pressed else r1
        mov r2, #0
        moveq r2, #1

        ldmia sp!, { r0, r1 }
        bx lr

_key_mappings:
        dw BUTTON_0, BUTTON_1, BUTTON_2, BUTTON_3
        dw BUTTON_4, BUTTON_5, BUTTON_6, BUTTON_7
        dw BUTTON_8, BUTTON_9, BUTTON_A, BUTTON_B
        dw BUTTON_C, BUTTON_D, BUTTON_E, BUTTON_F