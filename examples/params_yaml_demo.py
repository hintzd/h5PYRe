#!/usr/bin/env python3
"""Demo: the export_params / import_params YAML workflow in h5PYRe.

Run from anywhere with the package importable, e.g.:
    PYTHONPATH=../python python params_yaml_demo.py

Shows the full loop:
    write_params -> export_params -> (edit YAML) -> import_params -> read_params
plus subset export and replace-on-import.
"""
import os
import tempfile

import pandas as pd

import h5PYRe as h5c

work = tempfile.mkdtemp(prefix="h5pyre_demo_")
h5_path = os.path.join(work, "study.h5")
yaml_path = os.path.join(work, "params.yaml")

# --- 1. Seed a file with a cohort and some analysis params -----------------
cohort = pd.DataFrame({
    "patient_id": ["PATIENT_001", "PATIENT_002", "PATIENT_003"],
    "tumor_fraction": [0.05, 0.62, 0.33],
})
h5c.write_cohorts(h5_path, {"Tissue": cohort}, title="params YAML demo")

h5c.write_params(h5_path, {
    "tf_threshold": 0.33,
    "min_coverage": 500,
    "call_status": "no",              # a STRING "no" (not a boolean)
    "bin_edges": [0.0, 0.1, 0.25, 1.0],
    "palette_hex": ["#00857C", "#6ECEB2"],
})
print("1. initial params in file:")
print("  ", h5c.read_params(h5_path))

# --- 2. Export /params to an editable YAML file ----------------------------
h5c.export_params(h5_path, yaml_path)
print(f"\n2. exported -> {yaml_path}\n")
print(open(yaml_path).read())

# --- 3. A human (here: a couple of edits) tweaks the YAML ------------------
text = open(yaml_path).read()
text = text.replace("'tf_threshold': 0.33", "'tf_threshold': 0.4")   # bump
text += "'analyst': 'jdoe'\n"                                        # add one
open(yaml_path, "w").write(text)
print("3. edited YAML (bumped tf_threshold, added 'analyst').")

# --- 4. Import edits back into /params (merges by default) -----------------
h5c.import_params(h5_path, yaml_path)
p = h5c.read_params(h5_path)
print("\n4. params after import (merged):")
for k, v in p.items():
    print(f"   {k:14} = {v!r}")
assert p["tf_threshold"] == 0.4
assert p["analyst"] == "jdoe"
assert p["call_status"] == "no"          # stayed a string, not False
assert p["min_coverage"] == 500          # untouched key preserved

# --- 5. Subset export + replace-on-import ----------------------------------
subset_yaml = os.path.join(work, "subset.yaml")
h5c.export_params(h5_path, subset_yaml, params=["tf_threshold", "palette_hex"])

fresh = os.path.join(work, "fresh.h5")
h5c.import_params(fresh, subset_yaml, replace=True)   # only these two land
print("\n5. fresh file seeded from subset (replace=True):")
print("  ", h5c.read_params(fresh))
assert set(h5c.read_params(fresh)) == {"tf_threshold", "palette_hex"}

print("\nOK - demo complete. Files in:", work)
