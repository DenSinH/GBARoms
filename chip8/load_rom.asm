include '../lib/constants.inc'

load_rom:
        ; load rom from address in r10
        do_dma MEM_ROM + digits, CHIP8_MEMORY, 5 * 4
        do_dma r10, CHIP8_MEMORY + 0x200, (0x1000 - 0x200) / 4
        bx lr


