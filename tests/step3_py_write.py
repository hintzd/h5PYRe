#!/usr/bin/env python3
"""Direction B, step 1: Python writes an h5cohort file that R will read."""
import sys

import pandas as pd

import h5cohort as h5c

path = sys.argv[1]

tissue = pd.DataFrame({
    "patient_id": ["PATIENT_010", "PATIENT_011"],
    "age": [55, 60],
    "tumor_fraction": [0.05, 0.62],
})
liquid = pd.DataFrame({  # different schema
    "sample_id": ["SAMPLE_010", "SAMPLE_011", "SAMPLE_012"],
    "ctdna_fraction": [0.10, 0.20, 0.30],
    "msi_status": ["MSI-H", "MSS", "MSS"],
})

h5c.write_cohorts(path, {"Tissue": tissue, "Liquid": liquid},
                  title="roundtrip B (Python -> R)")
h5c.write_params(path, {
    "tf_threshold": 0.31,
    "palette_hex": ["#00857C", "#6ECEB2"],
    "seed": 7,
})

print("Python wrote:", path)
h5c.tree(path)  # already prints
