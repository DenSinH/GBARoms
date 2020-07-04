format binary as 'gba'

include './lib/constants.inc'
include './lib/macros.inc'

;           _____ ____          _____      _     _        ___
;          / ____|  _ \   /\   / ____|    | |   (_)      / _ \
;         | |  __| |_) | /  \ | |   ______| |__  _ _ __ | (_) |
;         | | |_ |  _ < / /\ \| |  |______| '_ \| | '_ \ > _ <
;         | |__| | |_) / ____ \ |____     | | | | | |_) | (_) |
;          \_____|____/_/    \_\_____|    |_| |_|_| .__/ \___/
;                                                 | |
;                                                 |_|
;
;    We store Chip-8 RAM in iWRAM, starting at CHIP8_MEMORY
;    We store the 16 general purpose registers in iWRAM, starting at CHIP8_REGISTERS
;    We store the Chip-8 PC in r12, the highest GBA general purpose register that
;       is not a "special" register
;    In the PC, we store the address relative to CHIP8_MEMORY, not the actual address
;    We store the Chip-8 SP in r11, the second highest GBA "non-special" register


header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        include './init.asm'

        mov r3, 0x20
        mov r1, 0x0
        _main_y_loop:
                and r0, r3, #1
                mov r2, 0x20
                _main_x_loop:
                        bl set_pixel
                        add r0,  #2
                        subs r2, #1
                        bne _main_x_loop
                add r1, #1
                subs r3, #1
                bne _main_y_loop

        wait:
                b wait

pixels:
        include './pixels.asm'

astro_dodge:
        include './chip8/roms/AstroDodge.ch8'

pong:
        include './chip8/roms/Pong.ch8'

puzzle:
        include './chip8/roms/Puzzle.ch8'

rush_hour:
        include './chip8/roms/RushHour.ch8'

space_invaders:
        include './chip8/roms/SpaceInvaders.ch8'

tetris:
        include './chip8/roms/Tetris.ch8'

tic_tac_toe:
        include './chip8/roms/TicTacToe.ch8'

