from PIL import Image
import numpy as np
import sys

np.set_printoptions(threshold=sys.maxsize)

# convert to bitmap
glyphs = Image.open("./glyphs.png")
bm = (np.array(glyphs) == 1).astype(int)

print(bm.shape)
asm = "align 4\nglyphs:\n"
for y in range(bm.shape[0] // 8):
    for x in range(bm.shape[1] // 8):
        glyph = "db "
        tile = bm[8 * y: 8 * y + 8, 8 * x:8 * x + 8]
        print(tile)
        for line in tile:
            for dx in range(4):
                glyph += f"0x{line[2 * dx + 1]}{line[2 * dx]}, "
        glyph = glyph[:-2] + "\n"
        asm += f"   {glyph}"

with open("./glyphs.inc", "w+") as f:
    f.write(asm)
