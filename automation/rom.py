#!/usr/bin/python3
import sys

# Set to True for big-endian, False for little-endian
IS_BIG_ENDIAN = False


def main(argv):
    if len(argv) < 2:
        print(f"Usage: python3 {argv[0]} [filename]")
        exit(-1)

    filename = argv[1]
    try:
        with open(filename, "rb") as f:
            bytes_read = f.read()
    except FileNotFoundError:
        print(f"Error: File {filename} not found.")
        exit(-1)

    rom = {i: byte for i, byte in enumerate(bytes_read)}

    for addr in range(0, len(rom), 4):  # stride of 4
        byte0 = rom.get(addr)
        byte1 = rom.get(addr + 1)
        byte2 = rom.get(addr + 2)
        byte3 = rom.get(addr + 3)

        if IS_BIG_ENDIAN:
            word = (
                (byte0 << 24 if byte0 is not None else 0)
                | (byte1 << 16 if byte1 is not None else 0)
                | (byte2 << 8 if byte2 is not None else 0)
                | (byte3 if byte3 is not None else 0)
            )
        else:
            word = (
                (byte3 << 24 if byte3 is not None else 0)
                | (byte2 << 16 if byte2 is not None else 0)
                | (byte1 << 8 if byte1 is not None else 0)
                | (byte0 if byte0 is not None else 0)
            )

        print(f"32'd{addr}: o_read_data = 32'd{word};")

    print("default: o_read_data = 32'bX; // Default value")


if __name__ == "__main__":
    main(sys.argv)
