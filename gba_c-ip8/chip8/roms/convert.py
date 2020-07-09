import os


def convert(filepath: str):
    with open(filepath, "rb") as f:
        binary = bytearray(f.read())

    converted = ""
    for i in range(0x1000 - 0x200):  # Chip8 memory length
        if i % 16 == 0:
            converted += "db "

        if i < len(binary):
            converted += "{0:#04x}, ".format(binary[i])
        else:
            converted += "0x00, "

        if i % 16 == 15:
            converted = converted[:-2]  # remove trailing comma
            converted += "\n"

    with open(f"./{os.path.basename(filepath)}", "w+") as f:
        f.write(converted)



for fil in os.listdir("./bin"):
    convert(f"./bin/{fil}")
