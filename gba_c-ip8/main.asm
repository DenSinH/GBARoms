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
;    We store the Chip-8 dt register in r9
;    We store the Chip-8 st register in r8
;
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
        ; disable interrupts
        set_word r0, REG_IME
        mov r1, #0
        strh r1, [r0]

        bl init_menu
        bl menu

        ; r10 now holds the selected game (from menu::games)
        ; we convert the game selected into an address
        mov r10, r10, lsl #2           ; address length
        set_word r9, MEM_ROM + games
        ldr r10, [r9, r10]
        add r10, MEM_ROM

        bl load_rom
        bl init_chip8

        ; initialize instruction counter
        mov r0, #10
        gameloop:
                stmdb sp!, { r0 }
                bl parse_instr
                ldmia sp!, { r0 }
                subs r0, #1
                bgt gameloop

                ; subtract 1 from dt every 10 instructions
                mov r0, #10
                cmp r9, #0
                subsgt r9, #1
                bl VBlankIntrWait

                ; check if start + select pressed
                set_word r1, KEYINPUT
                ldrh r1, [r1]
                tst r1, GBA_START or GBA_SELECT
                beq main

                b gameloop

VBlankIntrWait:
        ; manually wait for VBlank by polling DISPSTAT
        stmdb sp!, { r0, r1 }
        set_word r1, DISPSTAT
        _VBlankIntrWait_loop:
                ldrh r0, [r1]
                tst r0, #1  ; VBlank flag
                beq _VBlankIntrWait_loop

        ldmia sp!, { r0, r1 }
        bx lr


include './chip8/init.asm'
include './chip8/menu.asm'
include './chip8/pixels.asm'
include './chip8/update_keypad.asm'
include './chip8/load_rom.asm'
include './chip8/parse.asm'

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

test:
        include './chip8/roms/test_opcode.ch8'

