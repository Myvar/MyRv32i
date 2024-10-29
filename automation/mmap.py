#!/usr/bin/python3
import sys
import yaml

import subprocess
import os
import json
from types import SimpleNamespace

import math

def read_field(yaml, name):
    if(name in yaml):
        return yaml[name]
    print("Filed '" + name + "' missing");
    sys.exit(1)

def main(argv):
    if len(argv) < 3:
        print('Usage: python3 ' + argv[0] + ' [filename] [outdir]')
        exit(-1)

    filename = argv[1]
    outdir = argv[2]
    mmap_ports_path = f"{outdir}/mmap_ports.svh"
    mmap_path = f"{outdir}/mmap.svh"
    mmap_modules_path = f"{outdir}/mmap_modules.svh"


    with open(filename, 'r') as file:
        with open(mmap_ports_path, 'w+') as ports:
            with open(mmap_path, 'w+') as mmap_logic:
                with open(mmap_modules_path, 'w+') as modules:
                    mmap = yaml.safe_load(file)
                    maps = read_field(mmap, "memmory_map")
                    x = math.ceil(math.sqrt(len(maps)))
                    ports.write(f"typedef enum reg [{x}:0] {{ \n");
                    for map in maps:
                        module_lines = []
                        enum = read_field(map, "enum")
                        parms = read_field(map, "parms")
                        module = read_field(map, "module")
                        local = bool(read_field(map, "local"))
                        read = bool(read_field(map, "read"))
                        write = bool(read_field(map, "write"))
                        start = int(read_field(map, "start"))
                        end = int(read_field(map, "end"))
                        #print(f'Enum: {enum}\nModule: {module}\nLocal: {local}\nRead: {read}\nWrite: {write}\nStart: {start}\nEnd: {end}')
                        modules.write(f"{module}");
                        if (len(parms) > 0):
                            modules.write(" #(\n");
                            for k in parms:
                                modules.write(f".{k}({parms[k]}),\n");
                            modules.seek(modules.tell()-2)
                            modules.write(f"\n)\n");
                        modules.write(f" u_{module} (\n")
                        modules.write(f".i_clk(i_clk),\n")
                        modules.write(f".i_clk_en(i_clk_en),\n")
                        modules.write(f".i_rst(i_rst),\n\n")
                        if (read):
                            modules.write(f".i_read_addr({module}_read_addr),\n")
                            modules.write(f".o_read_data({module}_read_data),\n\n")
                            
                            module_lines.append(f"wire [AW-1:0] {module}_read_addr;\n")
                            module_lines.append(f"wire [DW-1:0] {module}_read_data;\n\n")
                        
                        if (write):
                            modules.write(f".i_write_en({module}_write_en),\n")
                            modules.write(f".i_byte_en({module}_byte_en),\n")
                            modules.write(f".i_write_addr({module}_write_addr),\n")
                            modules.write(f".i_write_data({module}_write_data),\n")

                            module_lines.append(f"wire {module}_write_en;\n")
                            module_lines.append(f"wire [3:0] {module}_byte_en;\n")
                            module_lines.append(f"wire [AW-1:0]{module}_write_addr;\n")
                            module_lines.append(f"wire [DW-1:0]{module}_write_data;\n")

                        modules.seek(modules.tell()-2)
                        modules.write(f"\n");
                        modules.write(");\n\n")
                        modules.writelines(module_lines)

                        ports.write(f"{enum.upper()},\n");

                    ports.seek(ports.tell()-2)
                    ports.write(f"\n");
                    ports.write("} TargetPort;\n");

                            


if __name__ == "__main__":
   main(sys.argv)
