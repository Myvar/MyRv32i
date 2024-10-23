#!/usr/bin/python3
import sys

def main(argv):
    if len(argv) < 2:
        print('Usage: python3 ' + argv[0] + ' [filename]')
        exit(-1)

    filename = argv[1]
    with open(filename, "rb") as f:
        bytes_read = f.read()

    rom = {}
    for i in range(len(bytes_read)):
        rom[i] = bytes_read[i]

    for addr in range(0, len(rom), 4):  # stride of 4
        byte = rom.get(addr)
        if byte is not None:
            word = byte << 24
            word |= ((rom.get(addr+1) & 0xFF) << 16) if rom.get(addr+1) is not None else 0
            word |= ((rom.get(addr+2) & 0xFF) <<  8) if rom.get(addr+2) is not None else 0
            word |= (rom.get(addr+3) & 0xFF)         if rom.get(addr+3) is not None else 0
            print('32\'d{}: o_read_data = 32\'d{};'.format(addr, word))
    print('default: o_read_data = 32\'bX; // Default value')

if __name__ == "__main__":
   main(sys.argv)
