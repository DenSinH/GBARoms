;
;       r0, r1, r2, r3: GP
;       r5: ??? (command)
;       r6: flash start (#0x0E000000)
;       r7: some address in FLASH memory
;       r8: 0xAA
;       r9: 0x55
;       r10: command address   (0xE005555)
;       r11: command address 2 (0xE002AAA)
;       r12: test number

macro prep_command {
      strb r8, [r10]    ; 0xAA to 0xE005555
      strb r9, [r11]    ; 0x55 to 0xE002AAA
}

macro send_command command {
      prep_command
      mov r5, command
      strb r5, [r10]
}

test_setup:
        mov r6, 0xE000000
        set_word r7, 0xE000200
        mov r8, #0xAA
        mov r9, #0x55
        set_word r10, 0xE005555
        set_word r11, 0xE002AAA

test_0:
        mov r12, #0
        ; clear entire chip
        send_command 0x80    ; prep erase
        send_command 0x10    ; erase entire chip

        mov r0, #0
        mov r1, #0           ; used for drawing wrong address
        mov r2, #0
        set_word lr, MEM_ROM + fail_test ; in case of fail
        test_0_loop:
                ldrb r3, [r6, r2]   ; read byte from flash
                cmp r3, #0xff       ; should be cleared with 0xff
                bne draw_hex_value  ; branch without link (lr was set manually)

                ; todo: failing this gives weird code
                add r2, #1
                cmp r2, #0x10000
                blt test_0_loop

        cmp r0, #0
        bne test_1_return

test_1:
        ; check other bank
        mov r12, #1
        send_command 0xb0
        mov r0, #1
        strb r0, [r6]                ; bank switch
        mov r2, #0
        b test_0_loop                ; check other bank
test_1_return:
        mov r0, #0
        send_command 0xb0
        strb r0, [r6]                ; bank switch back to bank 0

; now our "playground" is nice and cleared
test_2:
        ; test single byte write/read (not in bottom 2 bytes, manufacturer info is there)
        mov r12, #2

        send_command #0xA0   ; write command
        mov r1, #0x69        ; byte to write
        mov r2, #0           ; clear

        strb r1, [r7]        ; write byte

        ldrb r2, [r7]        ; read same address
        cmp r1, r2
        bne fail_test

test_3:
        ; test device Identification mode
        mov r12, #3

        send_command #0x90    ; enter ID mode
        ldrb r1, [r6]         ; -> r1 = ID
        add r3, r1, #1        ; -> r3 = written value

        send_command #0xA0    ; prepare write
        strb r3, [r6]         ; store ID + 1 back to flash at start of flash

        ldrb r2, [r6]         ; read back value from flash start (still in ID mode)
                              ; -> r2 = read back value

        cmp r2, r1
        bne fail_test         ; read value was not the ID again

test_4:
        ; check if switching out of ID mode gives us our written value back
        mov r12, #4

        send_command #0xF0    ; exit ID mode
        ldrb r2, [r6]         ; load value
        cmp r2, r3            ; compare to initial written value
        bne fail_test         ; not equal

; no longer in ID mode
test_5:
        ; check if we can clear a section of a chip without clearing another
        mov r12, #5

        mov r2, #0x69
        send_command 0xA0     ; write single byte
        strb r2, [r6]         ; write to start of flash

        add r2, #0x1000
        send_command 0xA0     ; write single byte
        strb r2, [r6, r2]     ; now both byte at 0x0000 and 0x1069 are not 0xff

        send_command 0x80     ; prepare erase
        prep_command          ; prepare sending command
        mov r3, #0x30
        strb r3, [r6]         ; clear 1kB section at 0x0000

        ldrb r3, [r6, r2]     ; load uncleared byte write
        sub r2, #0x1000
        cmp r3, r2
        bne fail_test

test_6:
        ; second half of test 5: is sector actually cleared
        mov r12, #6
        ldrb r3, [r6, r2]
        cmp r3, 0xff
        bne fail_test

test_7:
        ; write > bankswitch > clear sector > bankswitch > read
        ; should yield original written value
        mov r12, #7

        ; write
        mov r2, #0x42
        send_command 0xA0       ; prepare write
        strb r2, [r6]

        ; bank switch
        mov r0, #1
        send_command 0xB0       ; bank switch
        strb r0, [r6]

        ; clear (first) sector
        send_command 0x80
        prep_command
        mov r5, #0x30
        strb r5, [r6]

        ; bank switch
        mov r0, #0
        send_command 0xB0       ; bank switch back
        strb r0, [r6]

        ; read
        ldrb r3, [r6]
        cmp r3, r2
        bne fail_test

test_stress:
        ; stress test, idea:
        ;        start at flash start
        ;        write bytes in incrementing order (0x00, 0x01, 0x02...)
        ;        bank switch inbetween every write
        ;        in bank 0, clear every other sector

        ; r0: byte read
        ; r1: intermediate result
        ; r2: address read/written to (LSB =

        set_word r12, 0xDEADDEAD

        mov r0, #1
        mov r2, #0
        stress_test_set_loop:

                send_command 0xA0       ; write byte
                strb r2, [r6, r2]

                send_command 0xB0       ; bank switch (to bank 1)
                strb r0, [r6]
                eor r0, #1

                send_command 0xA0       ; write byte
                strb r2, [r6, r2]

                send_command 0xB0       ; bank switch (to bank 0)
                strb r0, [r6]
                eor r0, #1

                add r2, #1
                movs r3, r2, lsl #19    ; check bottom 13 bits
                bne stress_test_set_loop

                ; clear 4kb sector
                add r3, r6, r2
                sub r3, #0x1000
                send_command 0x80       ; prepare erase
                prep_command
                mov r5, #0x30
                strb r5, [r3]           ; clear sector

                cmp r2, #0x10000
                blt stress_test_set_loop

        ; read results
        mov r0, #0
        send_command 0xB0       ; bank switch to bank 0 (with cleared data)
        strb r0, [r6]
        mov r2, #0

        set_word lr, MEM_ROM + fail_test ; in case of fail (same idea as for test 1)

        stress_test_check_b0_loop:
                ldrb r1, [r6, r2]
                and r3, r2, #0xff

                tst r2, #0x1000
                add r2, #1
                bne cleared_data

                        cmp r1, r3
                        movne r1, #0
                        bne draw_hex_value      ; will return to fail_test now
                        b _stress_test_check_b0_loop_end

                cleared_data:
                        cmp r1, #0xff
                        movne r1, #0
                        bne draw_hex_value

                _stress_test_check_b0_loop_end:
                        cmp r2, #0x10000
                        blt stress_test_check_b0_loop

        mov r0, #1
        send_command 0xB0       ; bank switch to bank 0 (without cleared data)
        strb r0, [r6]
        mov r2, #0

        stress_test_check_b1_loop:
                ldrb r1, [r6, r2]
                and r3, r2, #0xff
                add r2, #1

                cmp r1, r3
                movne r1, #0
                bne draw_hex_value            ; will return to fail_test now

                cmp r2, #0x10000
                blt stress_test_check_b1_loop

        b pass_test

fail_test:
        mov r0, #30
        mov r1, #70
        set_word r2, MEM_ROM + _fail_text
        mov r3, #_fail_text_end - _fail_text

        bl draw_word                                ; draw failed text
        add r0, #(_fail_text_end - _fail_text) * 8  ; move past failed text
        mov r2, r12
        bl draw_hex_value                           ; draw test number

        b exit

pass_test:
        mov r0, #50
        mov r1, #70
        set_word r2, MEM_ROM + _pass_text
        mov r3, #_pass_text_end - _pass_text

        bl draw_word                                ; draw failed text
        add r0, #(_pass_text_end - _pass_text) * 8  ; move past failed text

        b exit

_pass_text:
        dw 'Pass', 'ed a', 'll t', 'ests'
_pass_text_end:

_fail_text:
        dw 'Fail', 'ed t', 'est '
_fail_text_end:


exit:
