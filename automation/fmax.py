#!/usr/bin/python

import subprocess
import os
import json

res = subprocess.run(
    [os.path.abspath("./rtlmeta/build/rtlmeta"), "../rtl/"],
    stdout=subprocess.PIPE,
)
json_str = str(res.stdout)

meta = json.loads(json_str)
print(meta)
