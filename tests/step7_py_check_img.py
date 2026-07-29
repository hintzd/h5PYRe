#!/usr/bin/env python3
"""Direction C, step 3: verify the R-exported PNG is pixel-identical."""
import sys

import numpy as np
from PIL import Image

tmp = sys.argv[1]
a = np.asarray(Image.open(tmp + "/c_src.png"))
b = np.asarray(Image.open(tmp + "/pic.png"))
assert a.shape == b.shape, f"shape differs: {a.shape} vs {b.shape}"
assert np.array_equal(a, b), "image round-trip is not pixel-identical"
print("\n[PASS] Direction C: image Python -> R -> disk is pixel-identical")
