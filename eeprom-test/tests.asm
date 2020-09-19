;       NOTE: In the initialization (init.asm), we set DMA3DAD to EEPROM start,
;             We reload this every DMA to EEPROM with the DMA setting
;
;       We are going to use 8kb EEPROM
;
;       r0, r1, r2, r3: GP
;       r5: ??? (command)
;       r6: ??? (command)
;       r7: ??? (command)
;       r8: ??? (command)
;       r9: EEPROM start (0x0DFFFFF00)
;       r10: DMA3CNT_H setting (0x8060) (immediate, 16 bit, incr. src, incr/reload dest)
;       r11: DMA3SAD address (0x040000D4, +4 for DAD, +8 for DMA3CNT_L, +10 for DMA3CNT_H)
;       r12: test number

macro send_read_address address {
        local store_loop

        set_half r5, \#((address) or (0xc000)) ; set (to address << 2) | c000 (read mode bits)
        mov r6, MEM_EWRAM
        add r6, \#30     ; 16 bits to be stored, 2 bytes per bit, last bit is 0

        store_loop:
                strh r5, [r6], \#-2
                lsr r5, \#1
                cmp r6, \#MEM_EWRAM
                bne store_loop

        strh r5, [r6]         ; last bit wasn't stored yet
        str r6, [r11]         ; store SAD
        str r9, [r11, \#4]    ; store DAD

        mov r6, \#17          ; 17 halfwords
        strh r6, [r11, \#8]   ; set CNT_L
        strh r10, [r11, \#10] ; set CNT_H

        ; wait for potential DMA delay
        nop
        nop
        nop
}

macro read_data {
        local load_loop

        ; read data and push to r0, r1 (8 bytes (stored as 2 words), 64 bits)
        str r9, [r11]         ; SAD
        mov r5, MEM_EWRAM
        str r5, [r11, \#4]    ; DAD
        mov r5, \#68          ; 4 ignored bits, 64 data bits
        strh r5, [r11, \#8]   ; CNT_L
        strh r10, [r11, \#10] ; CNT_H

        ; wait for potential DMA delay (this should be long enough)
        mov r5, MEM_EWRAM
        add r5, \#8           ; skip first 4 bits (halfwords)
        mov r6, \#64
        mov r8, \#0

        load_loop:
                ldrh r7, [r5], \#2      ; load halfword (bit)
                orr r8, r7, r8, lsl \#1 ; buffer bit
                sub r6, \#1
                tst r6, \#31
                stmfdeq sp!, \{ r8 \}   ; store to stack
                cmp r6, \#0
                bne load_loop

        ldmia sp!, \{ r0, r1 \}
}

macro write_data address {
        ; write data in r0, r1 to address
        local addr_store_loop
        local data_store_loop

        ; store address + mode bits
        set_half r5, \#((address) or (0x8000)) ; set (to address << 2) | 8000 (write mode bits)
        mov r6, MEM_EWRAM
        add r6, \#30     ; 16 bits to be stored, 2 bytes per bit, last bit is 0

        addr_store_loop:
                strh r5, [r6], \#-2
                lsr r5, \#1
                cmp r6, \#MEM_EWRAM
                bne addr_store_loop

        strh r5, [r6]           ; last bit wasn't stored yet

        mov r7, #64             ; bit counter
        add r6, \#32 + 128      ; store data past address (counted in half words!)
        stmfd sp!, \{ r0, r1 \} ; store data to stack
        ldmfd sp!, \{ r5 \}

        ; store data
        data_store_loop:
                strh r5, [r6], \#-2
                lsr r5, \#1
                sub r7, \#1
                cmp r7, #32      ; 32 bits stored
                ldmfdeq sp!, \{ r5 \}
                cmp r7, #0
                bne data_store_loop

        mov r6, MEM_EWRAM
        str r6, [r11]         ; store SAD
        str r9, [r11, \#4]    ; store DAD

        mov r6, \#81          ; 81 halfwords
        strh r6, [r11, \#8]   ; set CNT_L
        strh r10, [r11, \#10] ; set CNT_H

        ; wait for potential DMA delay
        nop
        nop
        nop
}

test_setup:
        set_word r9, 0x0DFFFFF00
        set_half r10, 0x8060
        set_word r11, 0x040000D4

test_0:
        ; read from unused area (initialized to 0xff)
        mov r12, #0

        send_read_address 0x3fff  ; read top 8 bytes
        read_data

        cmp r0, #0xffffffff
        cmpeq r1, #0xffffffff
        bne fail_test

test_1:
        ; basic read/write test
        mov r12, #1

        set_word r0, #0x69696969
        set_word r1, #0x04200420

        mov r2, r0
        mov r3, r1

        write_data 0x0000         ; write to first entry

        send_read_address 0x0000  ; read it back
        read_data

        cmp r0, r2
        cmpeq r1, r3
        bne fail_test

        b pass_test

fail_test:
        ; store data from registers so it can be viewed on freeze
        stmfd sp!, { r0-r12 }

        mov r0, #30
        mov r1, #70
        set_word r2, MEM_ROM + _fail_text
        mov r3, #_fail_text_end - _fail_text

        bl draw_word                                ; draw failed text
        add r0, #(_fail_text_end - _fail_text) * 8  ; move past failed text
        mov r2, r12
        bl draw_hex_value                           ; draw test number

        ldmfd sp!, { r0-r12 }
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
