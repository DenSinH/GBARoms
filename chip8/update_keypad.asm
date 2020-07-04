include '../lib/constants.inc'

update_keypad:
        ; read KEYINPUT and output it into r10
        stmia sp!, { r0, r1, r2 }

        set_word r0, KEYINPUT
        ldrh r0, [r0]

        mov r10, #0  ; key counter (result will be stored in here anyway)
        set_word r1, _key_mappings
        add r1, MEM_ROM

        _update_keypad_check_loop:
                ldrh r2, [r1, r10]  ; load button halfword bitmask
                ; we use that KEYINPUT is inverted so that
                ; KEYINPUT & BITMASK == 0 iff the buttons masked by BITMASK are pressed
                tst r0, r2
                addne r10, #4
                beq _update_keypad_return
                cmp r10, #0x40
                bne _update_keypad_check_loop

        _update_keypad_return:
                ; we needed to increment r10 by 4 every time because the bitmasks
                ; were 4 bytes long, so we divide by 4 to fix this again
                mov r10, r10, lsr #2

                ldmdb sp!, { r0, r1, r2 }
                bx lr

_key_mappings:
        dw BUTTON_0, BUTTON_1, BUTTON_2, BUTTON_3
        dw BUTTON_4, BUTTON_5, BUTTON_6, BUTTON_7
        dw BUTTON_8, BUTTON_9, BUTTON_A, BUTTON_B
        dw BUTTON_C, BUTTON_D, BUTTON_E, BUTTON_F