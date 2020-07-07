
macro set_word reg, value {
        mov reg, value and 0xff
        orr reg, value and 0xff00
        orr reg, value and 0xff0000
        orr reg, value and 0xff000000
}

macro set_half reg, value {
        mov reg, value and 0xff
        orr reg, value and 0xff00
}
