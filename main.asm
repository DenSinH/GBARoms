format binary as 'gba'

include './lib/constants.inc'
include './lib/macros.inc'

;           _____ ____          _____      _        ___
;          / ____|  _ \   /\   / ____|    (_)      / _ \
;         | |  __| |_) | /  \ | |   ________ _ __ | (_) |
;         | | |_ |  _ < / /\ \| |  |______| | '_ \ > _ <
;         | |__| | |_) / ____ \ |____     | | |_) | (_) |
;          \_____|____/_/    \_\_____|    |_| .__/ \___/
;                                           | |
;                                           |_|
;
;    We store Chip-8 RAM in iWRAM, starting at CHIP8_MEMORY
;    We store the 16 general purpose registers in iWRAM, starting at CHIP8_REGISTERS
;    We store the Chip-8 PC in r12, the highest GBA general purpose register that
;       is not a "special" register
;    In the PC, we store the address relative to CHIP8_MEMORY, not the actual address
;    We store the Chip-8 SP in r11, the second highest GBA "non-special" register
;       the stack we use will be an upwards building stack
;    We store the Chip-8 I register in r10
;    We store the Chip-8 keypad status in r9 (lowest 9 bits), 0x0010 if no key is pressed
;       otherwise, the number of the pressed key
;
;    For the keypad, we want to emulate 16 buttons with only the GBA buttons
;    We map them as follows:
;            A     = 0           L + A     = 6
;            B     = 1           L + B     = 7
;            RIGHT = 2           L + RIGHT = 8         START      = c
;            LEFT  = 3           L + LEFT  = 9         SELECT     = d
;            UP    = 4           L + UP    = a         L + START  = e
;            DOWN  = 5           L + DOWN  = b         L + SELECT = f
;

header:
        include './lib/header.inc'; I just borrowed this from JSMolka, thanks for that!

main:
        include './init.asm'
        set_word r11, CHIP8_STACK
        set_word r0, CHIP8_ZERO
        mov r1, 0
        str r1, [r0]

        bl load_rom

        mainloop:
                bl update_keypad
                include './chip8/parse.asm'
                b mainloop

include './pixels.asm'
include './chip8/update_keypad.asm'
include './chip8/load_rom.asm'

digits:
        include './chip8/digits.asm'

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

