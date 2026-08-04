#!/usr/bin/env python3
"""Direction D, step 3: Python imports the R-exported params YAML and asserts
the values survived the full Python -> YAML -> R -> YAML -> Python trip."""
import os
import sys

import numpy as np

import h5PYRe as h5c

out_dir = sys.argv[1]
r_yaml = os.path.join(out_dir, "fromR_params.yaml")
dst = os.path.join(out_dir, "fromR_reimport.h5")
if os.path.exists(dst):
    os.remove(dst)

h5c.import_params(dst, r_yaml)
p = h5c.read_params(dst)


def norm(v):
    return v.tolist() if isinstance(v, np.ndarray) else v


assert p["flag_no"] == "no", p["flag_no"]
assert p["single_n"] == "n", p["single_n"]
assert p["code"] == "007", p["code"]
assert abs(p["tf_threshold"] - 0.31) < 1e-9
assert p["seed"] == 7
assert list(norm(p["bins"])) == [1, 2, 3]
assert list(p["palette_hex"]) == ["#00857C", "#6ECEB2"]
assert list(p["labels"]) == ["a", "no", "on"]

print("[PASS] Direction D step 3: full Python <-> R params YAML round-trip")
