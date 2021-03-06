include './lib/constants.inc'

;       The interesting range for the mandelbrot set is [-2, 1] x [-1, 1] apparently
;       conveniently, the screen ratio for the GBA is 3 x 2
;
;       store the registers with sign bits, 2 integer bits and 13 decimal bits
;       the max positive value that comes from the multiplication is then
;                         0x7fff * 0x7fff ~ 0x4000_0000
;       which won't overflow
;       we can then ASR and add the values together to check the next iteration's value
;       then we can add the squares and check if it lsr'ed right < 4

;       then 1 = 0x2000
;       such that 1 / 80 = 0x66.6666666... in hex


;       We use
;            r0 = x coordinate / Re(c)
;            r1 = y coordinate / Im(c)
;            r2 = Re(z_n)
;            r3 = Im(z_n)
;            r4 = ???
;            r5 = ???
;            r6 = ???
;            r7 = loop counter
;            r8 = VRAM draw address
;            r9 = 00 : byte[y pixel counter] byte[x pixel counter]
;            r10 = 4 (0x8000)
;            r11 = initial x coordinate
;

code16
mandelbrot:
        push { lr }

        ; load VRAM start
        mov r7, #6
        mov r0, #24
        lsl r7, r0
        mov r8, r7

        ; 4
        mov r0, #0x80
        mov r1, #8
        lsl r0, r1
        mov r10, r0

        ; init x pixel counter
        mov r0, #0
        mov r9, r0

        ; initial x coordinate (-2)
        mov r3, #0x40
        mov r2, #8
        lsl r3, r2
        mov r0, #0
        sub r0, r3
        mov r11, r0

        ; initial y coordinate (1)
        mov r1, #0x20
        lsl r1, r2

        _mandelbrot_loop_y:
                mov r0, r11
                _mandelbrot_loop_x:
                        ; initial value for c = x + iy = (r2 + r3 i)
                        mov r2, r0
                        mov r3, r1

                        ; check for main/secondary bulb
                        ; from https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#
                        ; we reset r7 after this, so we can use it as an extra aritmetic register!
                        ; since we only multiply once, we do not always have to account for
                        ; finite precision by shifting back

                        ; bounding boxes (rectangles):
                        ;     smaller bulb: [-1 1/4, -3/4] x [-1/4, 1/4]
                        ;
                        ;     bigger bulb: [-3/4,  3/8] x [-3sqrt(3) / 8, 3sqrt(3) / 8]
                        ;                                  -0x14C9        0x14C9
                        mov r6, #0x20
                        mov r7, #8
                        lsl r6, r7     ; r6 == 1
                        ; we want to keep r6 == 1 throughout the bounding box checkign
                        ; for the bulb checking

                        mov r5, r6
                        mov r7, #2
                        lsr r5, r7     ; r5 = 1 / 4

                        mov r4, r6
                        add r4, r5     ; 1 1/4
                        cmn r0, r4     ; x < -1 1/4
                        blt _mandelbrot_loop_init

                        sub r4, r5
                        sub r4, r5
                        cmn r0, r4     ; x > -3/4
                        bge _big_bulb_bounding_box

                        cmp r1, r5     ; y > 1/4
                        bge _mandelbrot_loop_init

                        cmn r1, r5     ; y > - 1/4
                        bgt _bulb_checking
                        b _mandelbrot_loop_init

                        _big_bulb_bounding_box:
                                mov r4, r5
                                mov r7, #1
                                lsr r5, r7      ; r4 = 1/4, r5 = 1/8
                                add r4, r5
                                cmp r0, r4      ; x > 3/8
                                bgt _mandelbrot_loop_init

                                mov r7, #8
                                mov r4, #0x14
                                lsl r4, r7
                                add r4, #0xc9   ; r4 = 0x14c9 ~3sqrt(3) / 8

                                cmp r1, r4      ; y > 3sqrt(3) / 8
                                bgt _mandelbrot_loop_init

                                cmn r1, r4      ; y < 3sqrt(3) / 8
                                blt _mandelbrot_loop_init

                        _bulb_checking:
                                ; r6 is still 1
                                ; secondary bulb:
                                mov r4, r2
                                add r4, r6
                                mul r4, r4     ; (x + 1)^2  << 13

                                mov r5, r3
                                mul r5, r3     ; y^2 << 13
                                add r4, r5     ; (x + 1)^2 + y^2 << 13
                                mov r7, #9
                                lsl r6, r7     ; 1 / 16 << 13
                                cmp r4, r6     ; (x + 1)^2 + y^2 <= 1 / 16
                                ble _mandelbrot_fast_converge

                                ; main lobe
                                mov r4, r2
                                mov r7, #11
                                lsr r6, r7      ; 1 / 4
                                sub r4, r6
                                mov r7, r4      ; store (x - 1/4) for later
                                mul r4, r4      ; (x - 1 /4)^2 << 13

                                ; q = (x - 1 /4)^2 + y^2 ( r5 still contained y^2 << 13)
                                add r4, r5      ; q << 13
                                mov r6, #13
                                lsr r4, r6
                                add r7, r4      ; q + (x - 1 / 4)

                                mul r7, r4      ; q(q + (x - 1 / 4)) << 13
                                mov r6, #2
                                lsr r5, r6      ; y^2 / 4  << 13
                                cmp r7, r5
                        ble _mandelbrot_fast_converge

                        _mandelbrot_loop_init:
                                mov r7, #0
                                sub r7, #1  ; reset counter

                        _mandelbrot_loop:
                                add r7, #1      ; increment loop counter
                                cmp r7, #25     ; check for divergence
                                bgt _mandelbrot_draw

                                mov r6, #13
                                mov r4, r2
                                mul r4, r2
                                asr r4, r6      ; x**2

                                mov r5, r2
                                mul r5, r3      ; xy << 13
                                mov r6, #12     ; NOT 13 because we need to multiply by 2
                                asr r5, r6      ; 2xy

                                mov r6, r3
                                mul r6, r3
                                mov r3, #13
                                asr r6, r3      ; y**2

                                mov r2, r4
                                sub r2, r6      ; x**2 - y**2
                                mov r3, r5      ; 2xy
                                add r2, r0      ; Re(z_n^2 + c)
                                add r3, r1      ; Im(z_n^2 + c)

                                mov r6, #13
                                mov r4, r2
                                mul r4, r4
                                asr r4, r6      ; x'^2

                                mov r5, r3
                                mul r5, r5
                                asr r5, r6      ; y'^2

                                add r4, r5      ; x'^2 + y'^2
                                cmp r4, r10     ; < 4 ?

                                bge _mandelbrot_draw
                                b _mandelbrot_loop

                        _mandelbrot_fast_converge:
                                mov r7, #25

                        _mandelbrot_draw:
                                mov r4, r8      ; load VRAM drawing address
                                strb r7, [r4]
                                mov r5, #1
                                add r8, r5      ; increment draw address

                                add r9, r5      ; add to pixel counter
                                add r0, #0x66   ; add dx

                                mov r4, r9
                                mov r5, #0xff
                                and r4, r5
                                cmp r4, #240    ; check if we have reached the end of a scanline
                                beq _mandelbrot_next_y

                                and r4, #0x3
                                bne _mandelbrot_loop_x

                                ; add 1 if x == 0 (mod 4) to account for finite precision
                                add r0, #1
                                b _mandelbrot_loop_x

                        _mandelbrot_next_y:
                                mov r5, #8
                                mov r4, r9
                                lsr r4, r5
                                add r4, #1
                                cmp r4, #160     ; check if we have reached the end of the screen

                                beq _mandelbrot_return
                                ; if we have not, set r9 to [y + 1] [ 0 ]
                                lsl r4, r5
                                mov r9, r4
                                sub r1, #0x66

                                lsr r4, r5
                                and r4, #3
                                bne _mandelbrot_loop_y

                                ; move down 1 if more y == 0 (mod 4) to account for finite precision
                                sub r1, #1
                                b _mandelbrot_loop_y

                        _mandelbrot_return:
                                pop { r0 }
                                bx r0
end_mandelbrot:
        dw ':-) '














