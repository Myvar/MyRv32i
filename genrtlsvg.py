#!/usr/bin/python

import subprocess

import glob
import os

rtl_directory = "rtl"

search_pattern = os.path.join(rtl_directory, "**", "*.sv")
sv_files = glob.glob(search_pattern, recursive=True)

file_list_str = " ".join(sv_files)

yosys_script = "read -sv {files}; ls".format(files=file_list_str)
print(yosys_script)

command = ["/usr/bin/yosys", "-p", yosys_script, "-Q", "-T"]

res = subprocess.check_output(command)
lines = str(res).split("modules:\\n")[1].split("$abstract\\\\")
lines = [l.strip().strip('"').strip("\\n") for l in lines[1:]]
print(lines)

mods = "["
for x in lines:
    try:
        print(
            subprocess.check_output(
                [
                    "/usr/bin/yosys",
                    "-DTESTING",
                    "-p",
                    f"read -sv {file_list_str}; prep -top {x}; write_json ./tmp/{x}.json",
                ]
            )
        )
        print(
            subprocess.check_output(
                ["/usr/bin/netlistsvg", f"./tmp/{x}.json", "-o", f"./docs/{x}.svg"]
            )
        )
        pass
    except:
        pass
    mods += f'"{x}",'
mods.strip(",")
mods += "]"

datajs = f"function getModules() {{ return {mods};}}"
with open("./docs/data.js", "r+") as f:
    data = f.read()
    f.seek(0)
    f.write(datajs)
    f.truncate()

