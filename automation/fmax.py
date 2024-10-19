#!/usr/bin/python

import subprocess
import os
import json
from types import SimpleNamespace

res = subprocess.run(
    [os.path.abspath("./rtlmeta/build/rtlmeta"), "../rtl/"],
    stdout=subprocess.PIPE,
)
json_str = res.stdout
meta = json.loads(json_str, object_hook=lambda d: SimpleNamespace(**d))

if not os.path.isdir("tmp"):
    os.mkdir("tmp")

for m in meta:
    with open(f"tmp/{m.name}.sv", "w") as f:
        f.write(f"module {m.name}_wrapper (\n")
        for pi in range(0, len(m.ports)):
            p = m.ports[pi]
            f.write(f"\t{'input' if p.input else 'output'} ")
            f.write(f"p_{p.name}")
            if pi + 1 >= len(m.ports):
                f.write("\n")
            else:
                f.write(",\n")
        f.write(");\n")

        f.write("reg [31:0] counter;\n")
        f.write(f"always @(posedge p_{m.ports[0].name}) begin\n")
        f.write("if (p_rst)\n")
        f.write("counter <= 0;\n")
        f.write("else\n")
        f.write("counter <= counter + 1;\n")
        f.write("end\n")

        for p in m.ports:
            f.write("\twire ")
            if p.width > 1:
                f.write(f"[{p.width-1}:0] ")
            f.write(f"m_{p.name}/* synthesis keep */;\n")

        f.write(f"\t{m.name} inst_{m.name}(\n")
        for pi in range(0, len(m.ports)):
            p = m.ports[pi]
            f.write(f"\t\t.{p.name}(m_{p.name})")
            if pi + 1 >= len(m.ports):
                f.write("\n")
            else:
                f.write(",\n")

        f.write("\t)/* synthesis keep */;\n")

        for p in m.ports:
            if p.input:
                f.write(f"\tassign m_{p.name} = ")
                if p.width > 1:
                    f.write("counter[")
                    f.write(f"{p.width-1}")
                    f.write(":0]")
                else:
                    f.write(f"p_{p.name}")

                f.write(";\n")
            else:
                f.write(f"\tassign p_{p.name} = ")

                if p.width > 1:
                    f.write(f"|m_{p.name}")
                else:
                    f.write(f"m_{p.name}")

                f.write(";\n")
        f.write("endmodule\n")
