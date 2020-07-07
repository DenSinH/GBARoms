include '../lib/constants.inc'
include '../lib/macros.inc'

titles:
        dw 'Astr', 'o Do', 'dge ', '    '
        dw 'Pong', '    ', '    ', '    '
        dw 'Puzz', 'le  ', '    ', '    '
        dw 'Rush', ' Hou', 'r   ', '    '
        dw 'Spac', 'e In', 'vade', 'rs  '
        dw 'Tetr', 'is  ', '    ', '    '
        dw 'Tic ', 'Tac ', 'Toe ', '    '
        dw 'SRAM', '    ', '    ', '    '

games:
        dw astro_dodge
        dw pong
        dw puzzle
        dw rush_hour
        dw space_invaders
        dw tetris
        dw tic_tac_toe
        dw test

TOP_NAME_Y  = 3
NAME_X      = 10
NO_OF_NAMES = 8

;       in the menu we map the registers somewhat differently:
;            r12: scroll direction (can be 0)
;            r11: previous scroll direction (can be 0)
;            r10: scroll position
;            r9 : start game

macro get_scroll_direction {
      ; poll keys pressed
      set_word r0, KEYINPUT
      ldrh r1, [r0]

      mov r3, \#0

      ; check for scroll
      tst r1, GBA_UP
      moveq r3, \#-1

      tst r1, GBA_DOWN
      moveq r3, \#1

      ; check for game start
      tst r1, GBA_A
      moveq r9, \#1

      ; if scroll direction has changed, update the current scroll direction
      cmp r3, r11
      movne r12, r3
      mov r11, r3
}

menu:
        stmdb sp!, { lr }
        ; reset values
        mov r12, #0
        mov r11, #0
        mov r10, #0
        mov r9, #0
        _menu_loop:
                set_word r7, MEM_ROM + titles
                mov r1, TOP_NAME_Y

                _menu_name_loop:
                        mov r0, NAME_X

                        _menu_char_loop:
                                ldrb r4, [r7]           ; load character

                                draw_char r0, r1, r4
                                add r0, #1
                                add r7, #1              ; increment position and character position
                                cmp r0, NAME_X + 16     ; compare to name length
                                bne _menu_char_loop

                        add r1, #1                      ; increment y position
                        cmp r1, TOP_NAME_Y + NO_OF_NAMES
                        bne _menu_name_loop

                get_scroll_direction
                mov r0, NAME_X - 2
                add r1, r10, TOP_NAME_Y
                draw_char r0, r1, ' '      ; erase old selector

                add r10, r12
                cmp r10, #0
                movlt r10, #0
                cmp r10, NO_OF_NAMES
                movge r10, NO_OF_NAMES - 1 ; determine y for new selector

                add r1, r10, TOP_NAME_Y
                draw_char r0, r1, '*'      ; draw new selector
                mov r12, #0                ; set scroll direction back to 0

                bl VBlankIntrWait

                cmp r9, #0
                beq _menu_loop

                ; r10 now contains the selected game
                ldmia sp!, { lr }
                bx lr





