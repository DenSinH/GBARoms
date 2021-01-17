include './lib/constants.inc'
include './lib/macros.inc'

; SoundInfo**
set_word r0, 0x03007ff0
; mov r1, MEM_IWRAM
; str r1, [r0]

; fake identifier
; set_word r0, 0x68736d53
; str r0, [r1]

mov r0, MEM_IWRAM
swi 0x1a0000
loop:
        swi 0x1d0000    ; SoundDriverVSync
        swi 0x280000    ; SoundDriverVSyncOff
        swi 0x290000    ; SoundDriverVSyncOn

        b loop
