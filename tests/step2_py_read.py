#!/usr/bin/env python3
"""Direction A, step 2: Python reads the R-written file and asserts."""
import sys

import h5PYRe as h5c

path = sys.argv[1]

cohorts = h5c.read_cohorts(path)
params = h5c.read_params(path)

print("Python read cohorts:", {k: list(v.columns) for k, v in cohorts.items()})
print("Python read params :", params)

assert set(cohorts) == {"Tissue", "Liquid"}, "cohort names mismatch"
assert list(cohorts["Tissue"].columns) == ["patient_id", "age", "tumor_fraction"]
assert list(cohorts["Liquid"].columns) == ["sample_id", "ctdna_fraction", "msi_status"]
assert cohorts["Tissue"].shape == (3, 3)
assert cohorts["Liquid"].shape == (2, 3)
assert cohorts["Tissue"]["patient_id"].tolist() == ["PATIENT_001", "PATIENT_002", "PATIENT_003"]
assert cohorts["Liquid"]["msi_status"].tolist() == ["MSS", "MSI-H"]
assert abs(params["tf_threshold"] - 0.33) < 1e-9
assert list(params["palette_hex"]) == ["#00857C", "#6ECEB2"]
assert params["seed"] == 42

print("\n[PASS] Direction A: R -> Python round-trip")
