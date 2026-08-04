#!/usr/bin/env python3
"""Direction D, step 1: Python params -> YAML -> params round-trip.

Writes a torture set of params (including YAML-1.1 ambiguous string tokens),
exports to YAML, re-imports into a fresh file and asserts equality, then leaves
the exported YAML on disk for R to consume in step 9.
"""
import os
import sys

import numpy as np

import h5PYRe as h5c

src = sys.argv[1]
out_dir = sys.argv[2]
yaml_path = os.path.join(out_dir, "fromPy_params.yaml")

params = {
    "flag_no": "no",          # must stay a string, not boolean False
    "single_n": "n",          # single-letter YAML-1.1 bool token
    "code": "007",            # leading zero must stay a string
    "tf_threshold": 0.31,
    "seed": 7,
    "bins": [1, 2, 3],
    "cuts": [0.1, 0.2, 0.5],
    "palette_hex": ["#00857C", "#6ECEB2"],
    "labels": ["a", "no", "on"],
}
h5c.write_params(src, params)
h5c.export_params(src, yaml_path)

dst = os.path.join(out_dir, "fromPy_reimport.h5")
if os.path.exists(dst):
    os.remove(dst)
h5c.import_params(dst, yaml_path)
rt = h5c.read_params(dst)


def norm(v):
    return v.tolist() if isinstance(v, np.ndarray) else v


for k, v in params.items():
    got, exp = norm(rt[k]), v
    if isinstance(exp, list):
        assert list(got) == list(exp), (k, got, exp)
    else:
        assert got == exp and type(got) == type(exp), (k, repr(got), repr(exp))

print("Python params YAML round-trip OK ->", yaml_path)
print("[PASS] Direction D step 1: Python params <-> YAML")
